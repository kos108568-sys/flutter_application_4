import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'audience_type_model.dart';

/// Локальный репозиторий для работы с типами аудиторий в SQLite
class AudienceTypesRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  /// Получение всех типов аудиторий
  Future<List<AudienceType>> getAllAudienceTypes({String? search, String? orderBy}) async {
    final db = await _db;
    String where = '';
    List<Object?> whereArgs = [];
    
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE (name LIKE ? OR description LIKE ?) AND deleted = 0';
      final q = '%${search.trim()}%';
      whereArgs = [q, q];
    } else {
      where = 'WHERE deleted = 0';
    }
    
    final order = orderBy ?? 'id DESC';
    final maps = await db.rawQuery(
      'SELECT * FROM audience_types $where ORDER BY $order', 
      whereArgs
    );
    return maps.map((m) => AudienceType.fromMap(m)).toList();
  }

  /// Получение типа аудитории по ID
  Future<AudienceType?> getById(int id) async {
    final db = await _db;
    final maps = await db.rawQuery(
      'SELECT * FROM audience_types WHERE id = ? AND deleted = 0 LIMIT 1', 
      [id]
    );
    if (maps.isEmpty) return null;
    return AudienceType.fromMap(maps.first);
  }

  /// Вставка нового типа аудитории (локально)
  Future<int> insertAudienceType(AudienceType audienceType) async {
    final db = await _db;
    final map = audienceType.toMap()..remove('id');
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    map['sync_state'] = 'pending';
    return await db.insert('audience_types', map);
  }

  /// Обновление типа аудитории (локально)
  Future<int> updateAudienceType(AudienceType audienceType) async {
    if (audienceType.id == null) return 0;
    final db = await _db;
    final map = audienceType.toMap()..remove('id');
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    map['sync_state'] = 'pending';
    return await db.update(
      'audience_types', 
      map, 
      where: 'id = ?', 
      whereArgs: [audienceType.id]
    );
  }

  /// Удаление типа аудитории (мягкое удаление для синхронизации)
  Future<int> deleteAudienceType(int id) async {
    final db = await _db;
    // Мягкое удаление для возможности синхронизации
    await db.update(
      'audience_types', 
      {
        'deleted': 1, 
        'updated_at': DateTime.now().millisecondsSinceEpoch, 
        'sync_state': 'pending'
      }, 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return 1;
  }

  // --- Методы для синхронизации ---

  /// Получение всех записей, ожидающих синхронизации
  Future<List<Map<String, Object?>>> getPendingMaps() async {
    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT * FROM audience_types WHERE sync_state != 'synced' OR (remote_id IS NULL AND deleted = 0)"
    );
    return rows;
  }

  /// Поиск по remote_id
  Future<Map<String, Object?>?> findByRemoteId(String remoteId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT * FROM audience_types WHERE remote_id = ? LIMIT 1', 
      [remoteId]
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Установка remote_id после успешной синхронизации
  Future<void> setRemoteId(int localId, String remoteId) async {
    final db = await _db;
    await db.update(
      'audience_types', 
      {'remote_id': remoteId, 'sync_state': 'synced'}, 
      where: 'id = ?', 
      whereArgs: [localId]
    );
  }

  /// Отметка записи как синхронизированной
  Future<void> markSyncedByLocalId(int localId) async {
    final db = await _db;
    await db.update(
      'audience_types', 
      {'sync_state': 'synced'}, 
      where: 'id = ?', 
      whereArgs: [localId]
    );
  }

  /// Применение удаленных данных к локальным
  Future<void> applyRemoteToLocal(Map<String, dynamic> remote) async {
    final db = await _db;
    // Поиск по remote_id
    final existing = await db.rawQuery(
      'SELECT id, updated_at FROM audience_types WHERE remote_id = ? LIMIT 1', 
      [remote['id']]
    );
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'name': remote['name'],
      'description': remote['description'],
      'remote_id': remote['id'],
      'updated_at': now,
      'sync_state': 'synced',
      'deleted': 0,
    };
    
    if (existing.isEmpty) {
      // Создание новой записи
      await db.insert('audience_types', row);
    } else {
      // Обновление существующей записи
      final localId = existing.first['id'] as int;
      await db.update('audience_types', row, where: 'id = ?', whereArgs: [localId]);
    }
  }

  /// Получение записей, измененных после указанной даты
  Future<List<Map<String, dynamic>>> getChangedSince(DateTime since) async {
    final db = await _db;
    final timestamp = since.millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT * FROM audience_types WHERE updated_at > ? AND deleted = 0',
      [timestamp]
    );
    return rows;
  }

  /// Инициализация тестовыми данными, если таблица пуста
  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM audience_types WHERE deleted = 0')
    ) ?? 0;
    
    if (count > 0) return;
    
    final samples = [
      AudienceType(name: 'Лекционная', description: 'Аудитория для проведения лекций'),
      AudienceType(name: 'Семинарская', description: 'Аудитория для проведения семинаров'),
      AudienceType(name: 'Лабораторная', description: 'Аудитория для проведения лабораторных работ'),
      AudienceType(name: 'Компьютерная', description: 'Аудитория с компьютерами'),
      AudienceType(name: 'Спортивная', description: 'Спортивный зал'),
    ];
    
    for (final sample in samples) {
      await insertAudienceType(sample);
    }
  }
}
