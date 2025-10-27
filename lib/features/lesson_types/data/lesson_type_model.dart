import '../../../core/models/syncable_model.dart';

/// Модель типа занятия с поддержкой синхронизации
class LessonType extends SyncableModel {
  final int? id;
  final String name;
  final String? description;

  LessonType({
    this.id,
    required this.name,
    this.description,
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
      'description': description,
    };
    map.addAll(toSyncMap());
    return map;
  }

  /// Создание из Map (SQLite)
  factory LessonType.fromMap(Map<String, dynamic> map) {
    final lessonType = LessonType(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
    lessonType.fromSyncMap(map);
    return lessonType;
  }

  /// Преобразование в Map для Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  /// Создание из Map (Supabase)
  factory LessonType.fromSupabaseMap(Map<String, dynamic> map) {
    return LessonType(
      name: map['name'] as String,
      description: map['description'] as String?,
      remoteId: map['id']?.toString(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String).millisecondsSinceEpoch
          : null,
    );
  }

  /// Копирование с изменениями
  LessonType copyWith({
    int? id,
    String? name,
    String? description,
    String? remoteId,
    int? updatedAt,
    int? deleted,
    String? syncState,
  }) {
    return LessonType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      remoteId: remoteId ?? this.remoteId,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      syncState: syncState ?? this.syncState,
    );
  }

  @override
  String toString() {
    return 'LessonType(id: $id, name: $name, description: $description, remoteId: $remoteId, syncState: $syncState)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonType &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.remoteId == remoteId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ description.hashCode ^ remoteId.hashCode;
  }
}
