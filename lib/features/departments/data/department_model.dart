import '../../../core/models/syncable_model.dart';

/// Модель отдела/кафедры с поддержкой синхронизации
class Department extends SyncableModel {
  final int? id;
  final String name;

  Department({
    this.id,
    required this.name,
    String? remoteId,
    int? updatedAt,
    int deleted = 0,
    String syncState = 'synced',
  }) : super(
          remoteId: remoteId,
          updatedAt: updatedAt,
          deleted: deleted,
          syncState: syncState,
        );

  /// Преобразование в Map для SQLite
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'name': name,
    };
    map.addAll(toSyncMap());
    return map;
  }

  /// Создание из Map (SQLite)
  factory Department.fromMap(Map<String, dynamic> map) {
    final department = Department(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
    department.fromSyncMap(map);
    return department;
  }

  /// Преобразование в Map для Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'name': name,
    };
  }

  /// Создание из Map (Supabase)
  factory Department.fromSupabaseMap(Map<String, dynamic> map) {
    return Department(
      name: map['name'] as String,
      remoteId: map['id']?.toString(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String).millisecondsSinceEpoch
          : null,
    );
  }

  /// Копирование с изменениями
  Department copyWith({
    int? id,
    String? name,
    String? remoteId,
    int? updatedAt,
    int? deleted,
    String? syncState,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      remoteId: remoteId ?? this.remoteId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      syncState: syncState ?? this.syncState,
    );
  }

  @override
  String toString() {
    return 'Department(id: $id, name: $name, remoteId: $remoteId, syncState: $syncState)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Department &&
        other.id == id &&
        other.name == name &&
        other.remoteId == remoteId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ remoteId.hashCode;
  }
}
