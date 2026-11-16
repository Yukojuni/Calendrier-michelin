/// Modèles de données de l'application.
library;

/// Ce qu'une personne peut poser sur une de ses journées.
enum AbsenceKind {
  conge('Congé', 'K'),
  tt('Télétravail', 't'),
  bureau('Au bureau', 'E'),
  ecole('École', 'S');

  const AbsenceKind(this.label, this.code);

  /// Libellé affiché.
  final String label;

  /// Code de statut correspondant dans le planning.
  final String code;

  static AbsenceKind? parse(String? id) {
    for (final k in values) {
      if (k.name == id) return k;
    }
    return null;
  }
}

/// Un membre de l'équipe.
class Person {
  const Person({required this.name, required this.school, required this.hue, this.photo});

  final String name;
  final String school;

  /// Teinte de l'avatar quand il n'y a pas de photo.
  final double hue;

  /// Chemin de l'asset de la photo de profil, s'il y en a une.
  final String? photo;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}

/// Identifiant stable d'une modification (une personne, un jour).
String absenceId(String date, String person) =>
    '${date}_${person.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '')}';

/// Une journée modifiée par quelqu'un (congé, télétravail ou retour au bureau).
class Absence {
  const Absence({
    required this.date,
    required this.person,
    required this.kind,
    this.note = '',
    required this.updatedAt,
  });

  /// Date au format AAAA-MM-JJ.
  final String date;
  final String person;
  final AbsenceKind kind;
  final String note;
  final DateTime updatedAt;

  String get id => absenceId(date, person);

  Map<String, Object?> toJson() => {
        'date': date,
        'person': person,
        'kind': kind.name,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Absence? fromJson(Map<String, Object?> json) {
    final date = json['date'], person = json['person'];
    final kind = AbsenceKind.parse(json['kind'] as String?);
    if (date is! String || person is! String || kind == null) return null;
    return Absence(
      date: date,
      person: person,
      kind: kind,
      note: (json['note'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
