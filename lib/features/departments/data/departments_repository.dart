import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'department_model.dart';

/// Локальный репозиторий для работы с отделами в SQLite
class DepartmentsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  /// Получение всех отделов
  Future<List<Department>> getAllDepartments({String? search, String? orderBy}) async {
    final db = await _db;
    String where = '';
    List<Object?> whereArgs = [];
    
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE name LIKE ? AND deleted = 0';
      final q = '%${search.trim()}%';
      whereArgs = [q];
    } else {
      where = 'WHERE deleted = 0';
    }
    
    final order = orderBy ?? 'id DESC';
    final maps = await db.rawQuery(
      'SELECT * FROM departments $where ORDER BY $order', 
      whereArgs
    );
    return maps.map((m) => Department.fromMap(m)).toList();
  }

  /// Получение отдела по ID
  Future<Department?> getById(int id) async {
    final db = await _db;
    final maps = await db.rawQuery(
      'SELECT * FROM departments WHERE id = ? AND deleted = 0 LIMIT 1', 
      [id]
    );
    if (maps.isEmpty) return null;
    return Department.fromMap(maps.first);
  }

  /// Вставка нового отдела (локально)
  Future<int> insertDepartment(Department department) async {
    final db = await _db;
    final map = department.toMap()..remove('id');
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    map['sync_state'] = 'pending';
    return await db.insert('departments', map);
  }

  /// Обновление отдела (локально)
  Future<int> updateDepartment(Department department) async {
    if (department.id == null) return 0;
    final db = await _db;
    final map = department.toMap()..remove('id');
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    map['sync_state'] = 'pending';
    return await db.update(
      'departments', 
      map, 
      where: 'id = ?', 
      whereArgs: [department.id]
    );
  }

  /// Удаление отдела (мягкое удаление для синхронизации)
  Future<int> deleteDepartment(int id) async {
    final db = await _db;
    // Мягкое удаление для возможности синхронизации
    await db.update(
      'departments', 
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
      "SELECT * FROM departments WHERE sync_state != 'synced' OR (remote_id IS NULL AND deleted = 0)"
    );
    return rows;
  }

  /// Поиск по remote_id
  Future<Map<String, Object?>?> findByRemoteId(String remoteId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT * FROM departments WHERE remote_id = ? LIMIT 1', 
      [remoteId]
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Установка remote_id после успешной синхронизации
  Future<void> setRemoteId(int localId, String remoteId) async {
    final db = await _db;
    await db.update(
      'departments', 
      {'remote_id': remoteId, 'sync_state': 'synced'}, 
      where: 'id = ?', 
      whereArgs: [localId]
    );
  }

  /// Отметка записи как синхронизированной
  Future<void> markSyncedByLocalId(int localId) async {
    final db = await _db;
    await db.update(
      'departments', 
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
      'SELECT id, updated_at FROM departments WHERE remote_id = ? LIMIT 1', 
      [remote['id']]
    );
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'name': remote['name'],
      'remote_id': remote['id'],
      'updated_at': now,
      'sync_state': 'synced',
      'deleted': 0,
    };
    
    if (existing.isEmpty) {
      // Создание новой записи
      await db.insert('departments', row);
    } else {
      // Обновление существующей записи
      final localId = existing.first['id'] as int;
      await db.update('departments', row, where: 'id = ?', whereArgs: [localId]);
    }
  }

  /// Получение записей, измененных после указанной даты
  Future<List<Map<String, dynamic>>> getChangedSince(DateTime since) async {
    final db = await _db;
    final timestamp = since.millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT * FROM departments WHERE updated_at > ? AND deleted = 0',
      [timestamp]
    );
    return rows;
  }

  /// Инициализация тестовыми данными, если таблица пуста
  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM departments WHERE deleted = 0')
    ) ?? 0;
    
    if (count > 0) return;
    
    final samples = [
      Department(name: 'Кафедра информатики'),
      Department(name: 'Кафедра математики'),
      Department(name: 'Кафедра физики'),
      Department(name: 'Кафедра экономики'),
    ];
    
    for (final sample in samples) {
      await insertDepartment(sample);
    }
  }
}
