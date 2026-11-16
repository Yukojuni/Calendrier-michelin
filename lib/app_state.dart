/// État de l'application : qui je suis, le mois affiché, la sélection, les absences.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'planning.dart';
import 'store.dart';

class AppState extends ChangeNotifier {
  AppState(this.store, this._prefs) {
    final saved = _prefs.getString(_meKey);
    if (saved != null && kPeople.any((p) => p.name == saved)) me = saved;
    final current = today.substring(0, 7);
    month = kMonths.contains(current)
        ? current
        : (today.compareTo(kDates.first) < 0 ? kMonths.first : kMonths.last);
    _sub = store.watch().listen((data) {
      overrides = data;
      offline = false;
      notifyListeners();
    }, onError: (Object _) {
      offline = true;
      notifyListeners();
    });
  }

  static const _meKey = 'gdc-me';
  final AbsenceStore store;
  final SharedPreferences _prefs;
  late final StreamSubscription<Map<String, Absence>> _sub;

  /// Prénom de la personne qui utilise l'app (null tant qu'elle n'a pas choisi).
  String? me;
  late String month;
  Map<String, Absence> overrides = {};
  final Set<String> selection = {};

  /// Vrai quand le stockage partagé ne répond pas (pas de réseau…).
  bool offline = false;

  /// Incrémenté pour demander à l'app de demander un recentrage sur aujourd'hui.
  int recenter = 0;

  /// Incrémenté à chaque pluie de confettis demandée.
  final ValueNotifier<int> confetti = ValueNotifier(0);

  String get today => isoDate(DateTime.now());

  int get meIndex => me == null ? -1 : kPeople.indexWhere((p) => p.name == me);

  void setMe(String name) {
    me = name;
    selection.clear();
    _prefs.setString(_meKey, name);
    notifyListeners();
  }

  void goToMonth(String m) {
    if (!kMonths.contains(m)) return;
    month = m;
    selection.clear();
    recenter++;
    notifyListeners();
  }

  void goToday() => goToMonth(referenceDay(today).substring(0, 7));

  void shiftMonth(int delta) {
    final i = kMonths.indexOf(month) + delta;
    if (i >= 0 && i < kMonths.length) goToMonth(kMonths[i]);
  }

  bool canSelect(String date) => meIndex >= 0 && isEditable(date, meIndex);

  void toggle(String date) {
    if (!canSelect(date)) return;
    if (!selection.remove(date)) selection.add(date);
    notifyListeners();
  }

  void setSelection(Iterable<String> dates) {
    selection
      ..clear()
      ..addAll(dates.where(canSelect));
    notifyListeners();
  }

  void clearSelection() {
    if (selection.isEmpty) return;
    selection.clear();
    notifyListeners();
  }

  /// Pose [kind] (ou revient au planning d'origine si [kind] est null) sur [dates].
  /// Renvoie le nombre de jours concernés.
  Future<int> apply(Iterable<String> dates, AbsenceKind? kind, {String note = ''}) async {
    final i = meIndex;
    if (i < 0) return 0;
    var n = 0;
    for (final d in dates) {
      final base = baseCode(d, i);
      if (kLocked.contains(base)) continue;
      n++;
      final id = absenceId(d, me!);
      if (kind == null || isNatural(kind, base)) {
        if (overrides.containsKey(id)) await store.remove(id);
      } else {
        await store.put(Absence(date: d, person: me!, kind: kind, note: note.trim(), updatedAt: DateTime.now()));
      }
    }
    if (kind == AbsenceKind.conge && n > 0) confetti.value++;
    return n;
  }

  Future<void> removeAll(Iterable<Absence> items) async {
    for (final a in items) {
      await store.remove(a.id);
    }
  }

  /// Journées que j'ai modifiées par rapport au planning d'origine, triées.
  List<Absence> get myAbsences {
    final i = meIndex;
    if (i < 0) return const [];
    return overrides.values
        .where((a) => a.person == me && !kLocked.contains(baseCode(a.date, i)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  void dispose() {
    _sub.cancel();
    confetti.dispose();
    super.dispose();
  }
}
