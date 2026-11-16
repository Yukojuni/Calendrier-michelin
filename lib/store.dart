/// Stockage des congés posés.
///
/// [AbsenceStore] est l'interface utilisée par l'app :
/// - [SupabaseAbsenceStore] : partagé avec toute l'équipe, en temps réel ;
/// - [LocalAbsenceStore] : sur l'appareil, utilisé quand Supabase n'est pas configuré.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

abstract class AbsenceStore {
  /// Texte court affiché dans l'app pour dire où sont les données.
  String get description;

  /// Vrai si les données sont partagées avec toute l'équipe.
  bool get isShared;

  /// Toutes les absences, puis à chaque changement.
  Stream<Map<String, Absence>> watch();

  Future<void> put(Absence absence);

  Future<void> remove(String id);
}

class LocalAbsenceStore implements AbsenceStore {
  LocalAbsenceStore(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final a = Absence.fromJson(Map<String, Object?>.from(item as Map));
        if (a != null) _data[a.id] = a;
      }
    } catch (_) {
      // Données illisibles : on repart de zéro plutôt que de planter.
    }
  }

  static const _key = 'gdc-absences';
  final SharedPreferences _prefs;
  final Map<String, Absence> _data = {};
  final StreamController<Map<String, Absence>> _changes = StreamController.broadcast();

  @override
  String get description => 'Enregistré sur cet appareil';

  @override
  bool get isShared => false;

  @override
  Stream<Map<String, Absence>> watch() async* {
    yield Map.of(_data);
    yield* _changes.stream;
  }

  @override
  Future<void> put(Absence absence) async {
    _data[absence.id] = absence;
    await _save();
  }

  @override
  Future<void> remove(String id) async {
    if (_data.remove(id) != null) await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(_data.values.map((a) => a.toJson()).toList()));
    _changes.add(Map.of(_data));
  }
}

/// Congés partagés avec toute l'équipe, dans la table `absences` de Supabase
/// (voir supabase/schema.sql). Les changements des autres arrivent en temps réel.
class SupabaseAbsenceStore implements AbsenceStore {
  SupabaseAbsenceStore(this._db);

  static const _table = 'absences';
  final SupabaseClient _db;

  @override
  String get description => "Synchronisé avec l'équipe";

  @override
  bool get isShared => true;

  @override
  Stream<Map<String, Absence>> watch() => _db.from(_table).stream(primaryKey: ['id']).map((rows) => {
        for (final a in rows.map(fromRow).nonNulls) a.id: a,
      });

  @override
  Future<void> put(Absence absence) => _db.from(_table).upsert(toRow(absence));

  @override
  Future<void> remove(String id) => _db.from(_table).delete().eq('id', id);

  /// Ligne de la table → [Absence].
  static Absence? fromRow(Map<String, dynamic> row) => Absence.fromJson({
        'date': (row['date'] as String?)?.substring(0, 10),
        'person': row['person'],
        'kind': row['kind'],
        'note': row['note'],
        'updatedAt': row['updated_at'],
      });

  /// [Absence] → ligne de la table.
  static Map<String, Object?> toRow(Absence a) => {
        'id': a.id,
        'date': a.date,
        'person': a.person,
        'kind': a.kind.name,
        'note': a.note,
        'updated_at': a.updatedAt.toUtc().toIso8601String(),
      };
}
