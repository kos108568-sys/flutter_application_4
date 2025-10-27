class SyncableModel {
  String? remoteId;
  int? updatedAt;
  int deleted;
  String syncState;

  SyncableModel({
    this.remoteId,
    this.updatedAt,
    this.deleted = 0,
    this.syncState = 'synced',
  });

  Map<String, dynamic> toSyncMap() {
    return {
      'remote_id': remoteId,
      'updated_at': updatedAt,
      'deleted': deleted,
      'sync_state': syncState,
    };
  }

  void fromSyncMap(Map<String, dynamic> map) {
    remoteId = map['remote_id'] as String?;
    updatedAt = map['updated_at'] as int?;
    deleted = (map['deleted'] as int?) ?? 0;
    syncState = (map['sync_state'] as String?) ?? 'synced';
  }
}