import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'time_slot_model.dart';

class TimeSlotRepository {
  final _table = 'time_slots';
  Database? _db;
  Future<Database> get _database async => _db ??= await DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  // Получение всех пар из SQLite
  Future<List<TimeSlot>> getAllTimeSlots() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'order_number ASC');
    return rows.map((e) => TimeSlot.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(TimeSlot s) async {
    final db = await _database;
    return await db.insert(_table, s.toMap());
  }

  // Сохранение локально
  Future<int> _updateLocal(TimeSlot s) async {
    final db = await _database;
    return await db.update(_table, s.toMap(), where: 'id = ?', whereArgs: [s.id!]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Отправка данных в Supabase
  Future<int?> _insertRemote(TimeSlot s) async {
    final res = await _supabase.from(_table).insert(s.toSupabaseMap()).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка данных в Supabase
  Future<bool> _updateRemote(TimeSlot s) async {
    if (s.id == null) return false;
    await _supabase.from(_table).update(s.toSupabaseMap()).eq('id', s.id!);
    return true;
  }

  // Отправка данных в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertTimeSlot(TimeSlot s) async {
    // Сохранение локально
    final localId = await _insertLocal(s);
    // Отправка данных в Supabase
    try {
      final remoteId = await _insertRemote(s);
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

  Future<int> updateTimeSlot(TimeSlot s) async {
    // Сохранение локально
    final updated = await _updateLocal(s);
    // Отправка данных в Supabase
    try {
      await _updateRemote(s);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteTimeSlot(int id) async {
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
  Future<void> syncTimeSlots() async {
    try {
      final db = await _database;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка данных в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from(_table).insert({
              'id': entry.value['id'],
              'order_number': entry.value['order_number'],
              'start_time': entry.value['start_time'],
              'end_time': entry.value['end_time'],
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
              'order_number': entry.value['order_number'],
              'start_time': entry.value['start_time'],
              'end_time': entry.value['end_time'],
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


