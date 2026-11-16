import 'package:calendrier_alternant/app_state.dart';
import 'package:calendrier_alternant/models.dart';
import 'package:calendrier_alternant/planning.dart';
import 'package:calendrier_alternant/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('le planning couvre nov. 2026 → août 2028 pour 7 personnes', () {
    expect(kPeople.map((p) => p.name), ['Opaline', 'Jenny', 'Samuel', 'Lucas', 'Tom', 'Romain', 'Quentin']);
    expect(kMonths.first, '2026-11');
    expect(kMonths.last, '2028-08');
  });

  test('le 11 novembre est férié et verrouillé', () {
    expect(baseCode('2026-11-11', 0), 'F');
    expect(isEditable('2026-11-11', 0), isFalse);
  });

  test('Quentin finit le 29 janvier 2027', () {
    final q = kPeople.indexWhere((p) => p.name == 'Quentin');
    expect(kDates.where((d) => baseCode(d, q) != '-').last, '2027-01-29');
  });

  test('poser un congé puis rétablir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(LocalAbsenceStore(prefs), prefs);
    await Future<void>.delayed(Duration.zero);
    state.setMe('Lucas');
    final lucas = state.meIndex;
    // 16/11/2026 : Lucas est en entreprise ; 02/11 il est à l'école (ignoré).
    final n = await state.apply(['2026-11-16', '2026-11-02'], AbsenceKind.conge, note: 'Ski');
    await Future<void>.delayed(Duration.zero);
    expect(n, 1);
    expect(effectiveCode('2026-11-16', lucas, state.overrides), 'K');
    expect(state.myAbsences.single.note, 'Ski');
    // Les données survivent à un redémarrage.
    final reloaded = LocalAbsenceStore(prefs);
    expect((await reloaded.watch().first).length, 1);
    await state.apply(['2026-11-16'], null);
    await Future<void>.delayed(Duration.zero);
    expect(effectiveCode('2026-11-16', lucas, state.overrides), 'E');
  });

  test('les jours consécutifs sont regroupés', () {
    Absence a(String d) => Absence(date: d, person: 'Lucas', kind: AbsenceKind.conge, updatedAt: DateTime(2026));
    final g = groupAbsences([a('2026-11-19'), a('2026-11-20'), a('2026-11-23'), a('2026-12-01')]);
    expect(g.map((x) => x.length), [3, 1]);
  });
}
