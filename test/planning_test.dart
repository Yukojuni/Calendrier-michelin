import 'package:calendrier_alternant/app_state.dart';
import 'package:calendrier_alternant/games/score_store.dart';
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

  test('tous les jours sont modifiables sauf hors équipe', () {
    expect(baseCode('2026-11-11', 0), 'F');
    expect(isEditable('2026-11-11', 0), isTrue);
    final q = kPeople.indexWhere((p) => p.name == 'Quentin');
    expect(isEditable('2027-02-01', q), isFalse);
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
    // 16/11/2026 : Lucas est en entreprise ; 02/11 il est à l'école : les deux changent.
    final n = await state.apply(['2026-11-16', '2026-11-02'], AbsenceKind.conge, note: 'Ski');
    await Future<void>.delayed(Duration.zero);
    expect(n, 2);
    expect(effectiveCode('2026-11-16', lucas, state.overrides), 'K');
    expect(effectiveCode('2026-11-02', lucas, state.overrides), 'K');
    expect(state.myAbsences.first.note, 'Ski');
    // Un jour d'entreprise passé en école, puis remis en école : rien à enregistrer.
    await state.apply(['2026-11-17'], AbsenceKind.ecole);
    await Future<void>.delayed(Duration.zero);
    expect(effectiveCode('2026-11-17', lucas, state.overrides), 'S');
    await state.apply(['2026-11-02'], AbsenceKind.ecole);
    await Future<void>.delayed(Duration.zero);
    expect(effectiveCode('2026-11-02', lucas, state.overrides), 'S');
    // Les données survivent à un redémarrage.
    final reloaded = LocalAbsenceStore(prefs);
    expect((await reloaded.watch().first).length, 2);
    await state.apply(['2026-11-16'], null);
    await Future<void>.delayed(Duration.zero);
    expect(effectiveCode('2026-11-16', lucas, state.overrides), 'E');
  });

  test('conversion vers et depuis une ligne Supabase', () {
    final a = Absence(date: '2027-03-01', person: 'Jenny', kind: AbsenceKind.tt, note: 'Dentiste', updatedAt: DateTime.utc(2026, 11, 16));
    final row = SupabaseAbsenceStore.toRow(a);
    expect(row['id'], '2027-03-01_Jenny');
    expect(row['kind'], 'tt');
    final back = SupabaseAbsenceStore.fromRow({...row, 'updated_at': '2026-11-16T00:00:00+00:00'})!;
    expect([back.date, back.person, back.kind, back.note], ['2027-03-01', 'Jenny', AbsenceKind.tt, 'Dentiste']);
    expect(SupabaseAbsenceStore.fromRow({'id': 'x', 'kind': 'inconnu'}), isNull);
  });

  test('les scores ne gardent que le meilleur de chacun', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final scores = LocalScoreStore(prefs);
    expect(await scores.submit(Games.race, 'Lucas', 120), isTrue);
    expect(await scores.submit(Games.race, 'Lucas', 80), isFalse);
    expect(await scores.submit(Games.race, 'Tom', 300), isTrue);
    expect(await LocalScoreStore(prefs).watch(Games.race).first, {'Lucas': 120, 'Tom': 300});
    expect(await scores.watch(Games.catchQuentin).first, isEmpty);
  });

  test('les jours consécutifs sont regroupés', () {
    Absence a(String d) => Absence(date: d, person: 'Lucas', kind: AbsenceKind.conge, updatedAt: DateTime(2026));
    final g = groupAbsences([a('2026-11-19'), a('2026-11-20'), a('2026-11-23'), a('2026-12-01')]);
    expect(g.map((x) => x.length), [3, 1]);
  });
}
