import 'dart:convert';

import 'package:calendrier_alternant/models.dart';
import 'package:calendrier_alternant/remote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

/// Faux serveur qui imite netlify/functions/api.mts.
MockClient fakeServer(Map<String, Map<String, dynamic>> db, {List<String>? log}) {
  var version = 0;
  return MockClient((req) async {
    log?.add('${req.method} ${req.url.path}');
    final path = req.url.path.replaceFirst('/api/', '');
    if (path == 'absences' && req.method == 'GET') {
      if (req.headers['if-none-match'] == 'v$version') return http.Response('', 304);
      return http.Response(jsonEncode({'version': 'v$version', 'items': db.values.toList()}), 200, headers: _json);
    }
    if (path.startsWith('absences/')) {
      final id = Uri.decodeComponent(path.substring('absences/'.length));
      version++;
      if (req.method == 'PUT') db[id] = {...jsonDecode(req.body) as Map<String, dynamic>, 'id': id};
      if (req.method == 'DELETE') db.remove(id);
      return http.Response('{"ok":true}', 200);
    }
    return http.Response('{"error":"Route inconnue."}', 404);
  });
}

void main() {
  test('le planning partagé se lit, se modifie et se relit', () async {
    final db = <String, Map<String, dynamic>>{};
    final log = <String>[];
    final store = HttpAbsenceStore(ApiClient(Uri.parse('https://exemple.netlify.app/api'), client: fakeServer(db, log: log)));
    final seen = <Map<String, Absence>>[];
    final sub = store.watch().listen(seen.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(seen.last, isEmpty);

    await store.put(Absence(date: '2026-12-21', person: 'Jenny', kind: AbsenceKind.conge, note: 'Noël', updatedAt: DateTime(2026)));
    expect(db.keys, ['2026-12-21_Jenny']);
    expect(seen.last['2026-12-21_Jenny']?.note, 'Noël');

    await store.remove('2026-12-21_Jenny');
    expect(db, isEmpty);
    expect(seen.last, isEmpty);
    expect(log, contains('PUT /api/absences/2026-12-21_Jenny'));
    await sub.cancel();
  });

  test('une erreur du serveur est remontée', () async {
    final api = ApiClient(Uri.parse('https://exemple.netlify.app/api/'), client: MockClient((_) async => http.Response('{"error":"Personne inconnue."}', 400)));
    expect(() => api.send('PUT', 'absences/x', {}), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Personne inconnue.')));
  });
}
