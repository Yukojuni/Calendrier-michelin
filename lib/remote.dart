/// Stockage partagé via l'API Netlify (netlify/functions/api.mts).
///
/// Netlify n'a pas de temps réel : l'app redemande les données régulièrement
/// (toutes les 20 s pour le planning) et tout de suite après chaque modification.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'games/score_store.dart';
import 'models.dart';
import 'store.dart';

class ApiException implements Exception {
  ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'ApiException($status): $message';
}

class ApiClient {
  ApiClient(Uri base, {http.Client? client})
      : base = base.path.endsWith('/') ? base : base.replace(path: '${base.path}/'),
        _http = client ?? http.Client();

  final Uri base;
  final http.Client _http;
  static const _timeout = Duration(seconds: 15);

  Uri _url(String path, [Map<String, String>? query]) {
    final u = base.resolve(path);
    return query == null ? u : u.replace(queryParameters: query);
  }

  Future<http.Response> get(String path, {Map<String, String>? query, Map<String, String>? headers}) =>
      _http.get(_url(path, query), headers: headers).timeout(_timeout);

  Future<Map<String, dynamic>> send(String method, String path, [Object? body]) async {
    final req = http.Request(method, _url(path))..headers['content-type'] = 'application/json';
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(await _http.send(req).timeout(_timeout));
    final data = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, data is Map && data['error'] is String ? data['error'] as String : 'Erreur ${res.statusCode}');
    }
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}

/// Flux qui interroge le serveur à intervalle régulier tant que quelqu'un l'écoute.
class _Poll<T> {
  _Poll(this.period, this.fetch) {
    _ctrl = StreamController<T>.broadcast(onListen: _start, onCancel: _stop);
  }

  final Duration period;

  /// Renvoie la nouvelle valeur, ou null si rien n'a changé.
  final Future<T?> Function() fetch;
  late final StreamController<T> _ctrl;
  Timer? _timer;
  T? last;
  bool _busy = false;

  Stream<T> watch() async* {
    final cached = last;
    if (cached != null) yield cached;
    yield* _ctrl.stream;
  }

  void emit(T value) {
    last = value;
    _ctrl.add(value);
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      final v = await fetch();
      if (v != null) emit(v);
    } catch (e) {
      _ctrl.addError(e);
    } finally {
      _busy = false;
    }
  }

  void _start() {
    refresh();
    _timer ??= Timer.periodic(period, (_) => refresh());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class HttpAbsenceStore implements AbsenceStore {
  HttpAbsenceStore(this._api) {
    _poll = _Poll(const Duration(seconds: 20), _fetch);
  }

  final ApiClient _api;
  late final _Poll<Map<String, Absence>> _poll;
  String? _version;

  @override
  String get description => "Synchronisé avec l'équipe";

  @override
  bool get isShared => true;

  Future<Map<String, Absence>?> _fetch() async {
    final res = await _api.get('absences', headers: {'if-none-match': ?_version});
    if (res.statusCode == 304) return null;
    if (res.statusCode != 200) throw ApiException(res.statusCode, 'Lecture du planning impossible');
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    _version = body['version'] as String?;
    return {
      for (final a in (body['items'] as List? ?? const []).map((item) => Absence.fromJson(Map<String, Object?>.from(item as Map))).nonNulls)
        a.id: a,
    };
  }

  @override
  Stream<Map<String, Absence>> watch() => _poll.watch();

  Future<void> _change(void Function(Map<String, Absence>) local, Future<void> Function() remote) async {
    // Affiche le changement tout de suite, puis le confirme auprès du serveur.
    final next = Map.of(_poll.last ?? const <String, Absence>{});
    local(next);
    _poll.emit(next);
    try {
      await remote();
    } finally {
      _version = null;
      await _poll.refresh();
    }
  }

  @override
  Future<void> put(Absence absence) => _change(
        (m) => m[absence.id] = absence,
        () => _api.send('PUT', 'absences/${Uri.encodeComponent(absence.id)}', absence.toJson()),
      );

  @override
  Future<void> remove(String id) => _change(
        (m) => m.remove(id),
        () => _api.send('DELETE', 'absences/${Uri.encodeComponent(id)}'),
      );
}

class HttpScoreStore implements ScoreStore {
  HttpScoreStore(this._api);

  final ApiClient _api;
  final Map<String, _Poll<Map<String, int>>> _polls = {};

  _Poll<Map<String, int>> _poll(String game) => _polls.putIfAbsent(
        game,
        () => _Poll(const Duration(seconds: 30), () async {
          final res = await _api.get('scores', query: {'game': game});
          if (res.statusCode != 200) throw ApiException(res.statusCode, 'Lecture des scores impossible');
          final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          return {
            for (final e in (body['scores'] as Map? ?? const {}).entries)
              if (e.key is String && e.value is int) e.key as String: e.value as int,
          };
        }),
      );

  @override
  Stream<Map<String, int>> watch(String game) => _poll(game).watch();

  @override
  Future<bool> submit(String game, String person, int score) async {
    final res = await _api.send('POST', 'scores', {'game': game, 'person': person, 'score': score});
    await _poll(game).refresh();
    return res['record'] == true;
  }
}
