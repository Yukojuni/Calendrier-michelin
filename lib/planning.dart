/// Lecture du planning d'origine et règles métier (qui est où, ce qu'on peut modifier).
library;

import 'data/planning_data.dart';
import 'models.dart';

/// Photos de profil (dans assets/photos). Sans photo, on affiche l'initiale.
const Map<String, String> kPhotos = {
  'Tom': 'assets/photos/tom.jpg',
  'Quentin': 'assets/photos/quentin.jpg',
  'Romain': 'assets/photos/romain.jpg',
  'Jenny': 'assets/photos/jenny.jpg',
  'Lucas': 'assets/photos/lucas.jpg',
  'Opaline': 'assets/photos/opaline.jpg',
  'Samuel': 'assets/photos/samuel.jpg',
};

const List<double> _hues = [340, 200, 30, 150, 265, 15, 180];

final List<Person> kPeople = [
  for (var i = 0; i < kPeopleRaw.length; i++) _parsePerson(kPeopleRaw[i], i),
];

Person _parsePerson(String raw, int i) {
  final m = RegExp(r'^(.*?)\s*\((.*)\)$').firstMatch(raw);
  final name = m?.group(1) ?? raw;
  return Person(
    name: name,
    school: m?.group(2) ?? '',
    hue: _hues[i % _hues.length],
    photo: kPhotos[name],
  );
}

/// Toutes les journées du planning, triées.
final List<String> kDates = kDays.keys.toList()..sort();

/// Les mois couverts (AAAA-MM), dans l'ordre.
final List<String> kMonths = kDates.map((d) => d.substring(0, 7)).toSet().toList();

/// Statuts sur lesquels on ne peut rien poser.
const Set<String> kLocked = {'S', 'X', 'C', 'F', '-'};
const Set<String> kAtWork = {'E'};
const Set<String> kAtSchool = {'S', 'X', 'C'};
const Set<String> kAway = {'K', 't', 'T'};

const Map<String, String> kStatusLabel = {
  'E': 'Entreprise',
  'S': 'École',
  'X': 'École · examen',
  'C': 'École · cours',
  'F': 'Férié',
  'T': 'TT / congé',
  'K': 'Congé',
  't': 'Télétravail',
  '-': "Pas dans l'équipe",
};

String pad2(int n) => n.toString().padLeft(2, '0');
String isoDate(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';
DateTime parseIso(String s) => DateTime(int.parse(s.substring(0, 4)), int.parse(s.substring(5, 7)), int.parse(s.substring(8, 10)));

/// Statut d'origine (document partagé) d'une personne un jour donné.
String baseCode(String date, int person) {
  final row = kDays[date];
  if (row == null || person >= row.length) return '-';
  return row[person];
}

bool isEditable(String date, int person) => !kLocked.contains(baseCode(date, person));

/// Statut effectif, en tenant compte de ce qui a été posé sur l'app.
String effectiveCode(String date, int person, Map<String, Absence> overrides) {
  final base = baseCode(date, person);
  final o = overrides[absenceId(date, kPeople[person].name)];
  if (o != null && !kLocked.contains(base)) return o.kind.code;
  return base;
}

/// Vrai si poser [kind] ce jour-là revient au planning d'origine (rien à enregistrer).
bool isNatural(AbsenceKind kind, String base) =>
    (kind == AbsenceKind.bureau && kAtWork.contains(base)) ||
    (kind == AbsenceKind.conge && base == 'K') ||
    (kind == AbsenceKind.tt && base == 't');

/// Premier jour du planning à partir d'aujourd'hui (ou le dernier si tout est passé).
String referenceDay(String today) => kDates.firstWhere((d) => d.compareTo(today) >= 0, orElse: () => kDates.last);

/// Jour ouvré suivant dans le planning.
String? nextPlanningDay(String date) {
  final i = kDates.indexOf(date);
  return i >= 0 && i + 1 < kDates.length ? kDates[i + 1] : null;
}

/// Regroupe des absences consécutives de même type et même mot.
List<List<Absence>> groupAbsences(List<Absence> sorted) {
  final out = <List<Absence>>[];
  for (final a in sorted) {
    if (out.isNotEmpty) {
      final last = out.last.last;
      if (last.kind == a.kind && last.note == a.note && nextPlanningDay(last.date) == a.date) {
        out.last.add(a);
        continue;
      }
    }
    out.add([a]);
  }
  return out;
}
