import '../../../core/models/syncable_model.dart';

/// Модель типа аудитории с поддержкой синхронизации
class AudienceType extends SyncableModel {
  final int? id;
  final String name;
  final String? description;

  AudienceType({
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
  factory AudienceType.fromMap(Map<String, dynamic> map) {
    final audienceType = AudienceType(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
    audienceType.fromSyncMap(map);
    return audienceType;
  }

  /// Преобразование в Map для Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  /// Создание из Map (Supabase)
  factory AudienceType.fromSupabaseMap(Map<String, dynamic> map) {
    return AudienceType(
      name: map['name'] as String,
      description: map['description'] as String?,
      remoteId: map['id']?.toString(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String).millisecondsSinceEpoch
          : null,
    );
  }

  /// Копирование с изменениями
  AudienceType copyWith({
    int? id,
    String? name,
    String? description,
    String? remoteId,
    int? updatedAt,
    int? deleted,
    String? syncState,
  }) {
    return AudienceType(
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
    return 'AudienceType(id: $id, name: $name, description: $description, remoteId: $remoteId, syncState: $syncState)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudienceType &&
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
