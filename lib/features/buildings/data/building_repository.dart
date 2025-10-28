import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'building_model.dart';

class BuildingRepository {
  final _table = 'buildings';
  Database? _db;
  Future<Database> get _database async => _db ??= await DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  // Получение всех записей из SQLite
  Future<List<Building>> getAllBuildings() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map((e) => Building.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(Building b) async {
    final db = await _database;
    return await db.insert(_table, b.toMap());
  }

  // Сохранение локально
  Future<int> _updateLocal(Building b) async {
    final db = await _database;
    return await db.update(_table, b.toMap(), where: 'id = ?', whereArgs: [b.id!]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Отправка в Supabase
  Future<int?> _insertRemote(Building b) async {
    final res = await _supabase.from(_table).insert(b.toSupabaseMap()).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка в Supabase
  Future<bool> _updateRemote(Building b) async {
    if (b.id == null) return false;
    await _supabase.from(_table).update(b.toSupabaseMap()).eq('id', b.id!);
    return true;
  }

  // Отправка в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertBuilding(Building b) async {
    // Сохранение локально
    final localId = await _insertLocal(b);
    // Отправка в Supabase
    try {
      final remoteId = await _insertRemote(b);
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

  Future<int> updateBuilding(Building b) async {
    // Сохранение локально
    final updated = await _updateLocal(b);
    // Отправка в Supabase
    try {
      await _updateRemote(b);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteBuilding(int id) async {
    // Сохранение локально
    final deleted = await _deleteLocal(id);
    // Отправка в Supabase
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncBuildings() async {
    try {
      final db = await _database;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from(_table).insert({
              'id': entry.value['id'],
              'name': entry.value['name'],
              'address': entry.value['address'],
              'description': entry.value['description'],
            });
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавление локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert(_table, {
              'id': entry.value['id'],
              'name': entry.value['name'],
              'address': entry.value['address'],
              'description': entry.value['description'],
            });
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
    }
  }
}


