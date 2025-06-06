class Category {
  final int? id;
  final String nom;
  final String couleur;
  final String? description;
  final DateTime dateCreation;

  Category({
    this.id,
    required this.nom,
    required this.couleur,
    this.description,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'description': description,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      nom: map['nom'] ?? '',
      couleur: map['couleur'] ?? '#2196F3',
      description: map['description'],
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }

  Category copyWith({
    int? id,
    String? nom,
    String? couleur,
    String? description,
    DateTime? dateCreation,
  }) {
    return Category(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      couleur: couleur ?? this.couleur,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}