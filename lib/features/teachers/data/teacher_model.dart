class Teacher {
  final int? id;
  final String fullName;
  final int? departmentId;
  final String? email;
  final String? phone;
  final String? notes;

  Teacher({
    this.id,
    required this.fullName,
    this.departmentId,
    this.email,
    this.phone,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'department_id': departmentId,
        'email': email,
        'phone': phone,
        'notes': notes,
      };

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
        id: map['id'] as int?,
        fullName: map['full_name'] as String,
        departmentId: map['department_id'] as int?,
        email: _asNullableString(map['email']),
        phone: _asNullableString(map['phone']),
        notes: _asNullableString(map['notes']),
      );

  Map<String, dynamic> toSupabaseMap() => {
        if (id != null) 'id': id,
        'full_name': fullName,
        'department_id': departmentId,
        'email': email,
        'phone': phone,
        'notes': notes,
      };
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

