/// Meilleurs scores des mini-jeux, par jeu et par personne.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Identifiants des jeux.
abstract final class Games {
  static const catchQuentin = 'attrape-quentin';
  static const race = 'route-des-conges';
}

abstract class ScoreStore {
  /// Meilleurs scores d'un jeu : prénom → score.
  Stream<Map<String, int>> watch(String game);

  /// Enregistre un score s'il bat le record de la personne. Renvoie vrai si c'est un nouveau record.
  Future<bool> submit(String game, String person, int score);
}

/// Scores gardés sur l'appareil.
class LocalScoreStore implements ScoreStore {
  LocalScoreStore(this._prefs) {
    try {
      final raw = jsonDecode(_prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
      raw.forEach((game, v) => _data[game] = Map<String, int>.from(v as Map));
    } catch (_) {
      // Données illisibles : on repart de zéro.
    }
  }

  static const _key = 'gdc-scores';
  final SharedPreferences _prefs;
  final Map<String, Map<String, int>> _data = {};
  final _changes = StreamController<String>.broadcast();

  @override
  Stream<Map<String, int>> watch(String game) async* {
    yield Map.of(_data[game] ?? {});
    yield* _changes.stream.where((g) => g == game).map((_) => Map.of(_data[game] ?? {}));
  }

  @override
  Future<bool> submit(String game, String person, int score) async {
    final scores = _data.putIfAbsent(game, () => {});
    if (score <= (scores[person] ?? -1)) return false;
    scores[person] = score;
    await _prefs.setString(_key, jsonEncode(_data));
    _changes.add(game);
    return true;
  }
}

/// Scores partagés avec l'équipe, dans la table `scores` de Supabase (voir supabase/schema.sql).
class SupabaseScoreStore implements ScoreStore {
  SupabaseScoreStore(this._db);

  static const _table = 'scores';
  final SupabaseClient _db;

  @override
  Stream<Map<String, int>> watch(String game) => _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .eq('game', game)
      .map(
        (rows) => {
          for (final r in rows)
            if (r['person'] is String && r['score'] is int) r['person'] as String: r['score'] as int,
        },
      );

  @override
  Future<bool> submit(String game, String person, int score) async {
    final id = '${game}_$person';
    final current = await _db.from(_table).select('score').eq('id', id).maybeSingle();
    if (current != null && (current['score'] as int? ?? 0) >= score) return false;
    await _db.from(_table).upsert({'id': id, 'game': game, 'person': person, 'score': score, 'updated_at': DateTime.now().toUtc().toIso8601String()});
    return true;
  }
}
