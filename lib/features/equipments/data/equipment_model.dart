class Equipment {
  final int? id;
  final String name;
  final String? description;

  Equipment({this.id, required this.name, this.description});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory Equipment.fromMap(Map<String, dynamic> map) => Equipment(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
      );

  Map<String, dynamic> toSupabaseMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
      };
}


