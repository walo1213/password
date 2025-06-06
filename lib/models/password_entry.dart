class PasswordEntry {
  final int? id;
  final String intitule;
  final String identifiant;
  final String motDePasse;
  final String type; // 'compte', 'banque', 'autre'
  final String note;
  final DateTime dateCreation;
  final DateTime dateModification;

  PasswordEntry({
    this.id,
    required this.intitule,
    required this.identifiant,
    required this.motDePasse,
    required this.type,
    required this.note,
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
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'dateModification': dateModification.millisecondsSinceEpoch,
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'],
      intitule: map['intitule'] ?? '',
      identifiant: map['identifiant'] ?? '',
      motDePasse: map['motDePasse'] ?? '',
      type: map['type'] ?? 'autre',
      note: map['note'] ?? '',
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation']),
      dateModification: DateTime.fromMillisecondsSinceEpoch(map['dateModification']),
    );
  }

  PasswordEntry copyWith({
    int? id,
    String? intitule,
    String? identifiant,
    String? motDePasse,
    String? type,
    String? note,
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
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}