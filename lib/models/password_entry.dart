class PasswordEntry {
  final int? id;
  final String intitule;
  final String identifiant;
  final String motDePasse;
  final String type;
  final String? note;
  final int? categoryId; // Nouveau champ
  final DateTime dateCreation;
  final DateTime dateModification;

  PasswordEntry({
    this.id,
    required this.intitule,
    required this.identifiant,
    required this.motDePasse,
    required this.type,
    this.note,
    this.categoryId, // Nouveau champ
    required this.dateCreation,
    required this.dateModification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'intitule': intitule,
      'identifiant': identifiant,
      'motDePasse': motDePasse,
      'type': type,
      'note': note,
      'categoryId': categoryId, // Nouveau champ
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'],
      intitule: map['intitule'] ?? '',
      identifiant: map['identifiant'] ?? '',
      motDePasse: map['motDePasse'] ?? '',
      type: map['type'] ?? '',
      note: map['note'],
      categoryId: map['categoryId'], // Nouveau champ
      dateCreation: DateTime.parse(map['dateCreation']),
      dateModification: DateTime.parse(map['dateModification']),
    );
  }

  PasswordEntry copyWith({
    int? id,
    String? intitule,
    String? identifiant,
    String? motDePasse,
    String? type,
    String? note,
    int? categoryId, // Nouveau champ
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      intitule: intitule ?? this.intitule,
      identifiant: identifiant ?? this.identifiant,
      motDePasse: motDePasse ?? this.motDePasse,
      type: type ?? this.type,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId, // Nouveau champ
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}