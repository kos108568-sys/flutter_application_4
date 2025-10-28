import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'equipment_model.dart';

class EquipmentRepository {
  final _table = 'equipments';
  Database? _db;
  Future<Database> get _database async => _db ??= await DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  // Получение всех записей из SQLite
  Future<List<Equipment>> getAllEquipments() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map((e) => Equipment.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(Equipment e) async {
    final db = await _database;
    return await db.insert(_table, e.toMap());
  }

  // Сохранение локально
  Future<int> _updateLocal(Equipment e) async {
    final db = await _database;
    return await db.update(_table, e.toMap(), where: 'id = ?', whereArgs: [e.id!]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Отправка данных в Supabase
  Future<int?> _insertRemote(Equipment e) async {
    final res = await _supabase.from(_table).insert(e.toSupabaseMap()).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка данных в Supabase
  Future<bool> _updateRemote(Equipment e) async {
    if (e.id == null) return false;
    await _supabase.from(_table).update(e.toSupabaseMap()).eq('id', e.id!);
    return true;
  }

  // Отправка данных в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertEquipment(Equipment e) async {
    // Работа офлайн: сначала локально
    final localId = await _insertLocal(e);
    // Отправка данных в Supabase
    try {
      final remoteId = await _insertRemote(e);
      if (remoteId != null && remoteId != localId) {
        final db = await _database;
        await db.update(_table, {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateEquipment(Equipment e) async {
    final updated = await _updateLocal(e);
    try {
      await _updateRemote(e);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteEquipment(int id) async {
    final deleted = await _deleteLocal(id);
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncEquipments() async {
    try {
      final db = await _database;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → отправка в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from(_table).insert({
              'id': entry.value['id'],
              'name': entry.value['name'],
              'description': entry.value['description'],
            });
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → добавление локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert(_table, {
              'id': entry.value['id'],
              'name': entry.value['name'],
              'description': entry.value['description'],
            });
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн: выполнится при следующем подключении
    }
  }
}


