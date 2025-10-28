import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'audience_equipment_model.dart';

class AudienceEquipmentsRepository {
  final _table = 'audience_equipments';
  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  // Получить все
  Future<List<AudienceEquipment>> getAll() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'audience_id ASC, equipment_id ASC');
    return rows.map((e) => AudienceEquipment.fromMap(e)).toList();
  }

  // Получить по аудитории
  Future<List<AudienceEquipment>> getByAudience(int audienceId) async {
    final db = await _db;
    final rows = await db.query(_table, where: 'audience_id = ?', whereArgs: [audienceId], orderBy: 'equipment_id ASC');
    return rows.map((e) => AudienceEquipment.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(AudienceEquipment e) async {
    final db = await _db;
    return await db.insert(_table, e.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _db;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Удалить по аудитории локально
  Future<int> deleteByAudience(int audienceId) async {
    final db = await _db;
    return await db.delete(_table, where: 'audience_id = ?', whereArgs: [audienceId]);
  }

  // Отправка данных в Supabase
  Future<int?> _insertRemote(AudienceEquipment e) async {
    final res = await _supabase.from(_table).insert(e.toMap()).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка данных в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insert(AudienceEquipment e) async {
    // Сохранение локально
    final localId = await _insertLocal(e);
    // Отправка данных в Supabase
    try {
      final remoteId = await _insertRemote(e);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update(_table, {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> delete(int id) async {
    // Сохранение локально
    final deleted = await _deleteLocal(id);
    // Отправка данных в Supabase
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncAudienceEquipments() async {
    try {
      final db = await _db;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from(_table).insert(entry.value);
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавить локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert(_table, entry.value, conflictAlgorithm: ConflictAlgorithm.ignore);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
    }
  }
}


