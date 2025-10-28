class Building {
  final int? id;
  final String name;
  final String? address;
  final String? description;

  Building({
    this.id,
    required this.name,
    this.address,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'description': description,
      };

  factory Building.fromMap(Map<String, dynamic> map) => Building(
        id: map['id'] as int?,
        name: map['name'] as String,
        address: map['address'] as String?,
        description: map['description'] as String?,
      );

  Map<String, dynamic> toSupabaseMap() => {
        if (id != null) 'id': id,
        'name': name,
        'address': address,
        'description': description,
      };
}


