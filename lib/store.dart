/// Stockage des congés posés.
///
/// [AbsenceStore] est l'interface utilisée par l'app :
/// - [HttpAbsenceStore] (remote.dart) : partagé avec toute l'équipe via l'API Netlify ;
/// - [LocalAbsenceStore] : sur l'appareil, quand l'API n'est pas disponible (développement).
library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
