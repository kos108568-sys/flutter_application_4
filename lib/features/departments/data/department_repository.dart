import 'package:supabase_flutter/supabase_flutter.dart';
import 'department_model.dart';
import 'departments_repository.dart';
import 'departments_remote_repository.dart';

/// Основной репозиторий для работы с отделами
/// Обеспечивает двустороннюю синхронизацию между SQLite и Supabase
class DepartmentRepository {
  final _localRepo = DepartmentsRepository();
  final _remoteRepo = DepartmentsRemoteRepository();
  
  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('Supabase не инициализирован: $e');
      return null;
    }
  }

  /// Получение всех отделов (локально)
  Future<List<Department>> getAllDepartments({String? search, String? orderBy}) async {
    return await _localRepo.getAllDepartments(search: search, orderBy: orderBy);
  }

  /// Получение отдела по ID (локально)
  Future<Department?> getById(int id) async {
    return await _localRepo.getById(id);
  }

  /// Вставка отдела с синхронизацией
  /// Сначала сохраняет локально, затем синхронизирует с Supabase
  Future<int> insertDepartment(Department department) async {
    try {
      // Сохранение локально
      final localId = await _localRepo.insertDepartment(department);
      
      // Синхронизация с Supabase (в фоне, не блокирует UI)
      _syncToSupabase(localId, department);
      
      return localId;
    } catch (e) {
      print('Ошибка при вставке отдела: $e');
      rethrow;
    }
  }

  /// Обновление отдела с синхронизацией
  Future<int> updateDepartment(Department department) async {
    try {
      // Обновление локально
      final result = await _localRepo.updateDepartment(department);
      
      // Синхронизация с Supabase (в фоне)
      if (result > 0 && department.remoteId != null) {
        _syncUpdateToSupabase(department);
      }
      
      return result;
    } catch (e) {
      print('Ошибка при обновлении отдела: $e');
      rethrow;
    }
  }

  /// Удаление отдела с синхронизацией
  Future<int> deleteDepartment(int id) async {
    try {
      // Получаем отдел для синхронизации
      final department = await _localRepo.getById(id);
      
      // Мягкое удаление локально
      final result = await _localRepo.deleteDepartment(id);
      
      // Синхронизация удаления с Supabase (в фоне)
      if (result > 0 && department?.remoteId != null) {
        _syncDeleteToSupabase(department!.remoteId!);
      }
      
      return result;
    } catch (e) {
      print('Ошибка при удалении отдела: $e');
      rethrow;
    }
  }

  /// Двусторонняя синхронизация отделов
  /// Сравнивает данные SQLite и Supabase, синхронизирует недостающие записи
  Future<void> syncDepartments() async {
    try {
      print('Начинаем синхронизацию отделов...');
      
      // 1. Отправляем локальные изменения в Supabase
      await _pushLocalChanges();
      
      // 2. Получаем изменения из Supabase
      await _pullRemoteChanges();
      
      print('Синхронизация отделов завершена');
    } catch (e) {
      print('Ошибка при синхронизации отделов: $e');
      // Не пробрасываем ошибку, чтобы не ломать работу приложения
    }
  }

  /// Отправка локальных изменений в Supabase
  Future<void> _pushLocalChanges() async {
    try {
      final pending = await _localRepo.getPendingMaps();
      print('Найдено ${pending.length} записей для отправки в Supabase');
      
      for (final row in pending) {
        try {
          final localId = row['id'] as int;
          final remoteId = row['remote_id'] as String?;
          final deleted = (row['deleted'] as int?) ?? 0;
          final name = row['name'] as String;
          
          print('Обрабатываем отдел: $name (local_id: $localId, remote_id: $remoteId)');
          
          if (remoteId == null) {
            // Новая запись - создаем в Supabase
            if (deleted == 1) {
              print('Пропускаем удаленную локальную запись без remote_id');
              await _localRepo.markSyncedByLocalId(localId);
              continue;
            }
            
            print('Создаем новую запись в Supabase');
            final newRemoteId = await _remoteRepo.insert({'name': name});
            
            if (newRemoteId != null) {
              print('Успешно создано в Supabase, remote_id: $newRemoteId');
              await _localRepo.setRemoteId(localId, newRemoteId);
            } else {
              print('Не удалось получить remote_id после создания');
            }
          } else {
            // Существующая запись - обновляем или удаляем в Supabase
            if (deleted == 1) {
              print('Удаляем запись из Supabase: $remoteId');
              final success = await _remoteRepo.delete(remoteId);
              if (success) {
                await _localRepo.markSyncedByLocalId(localId);
              }
            } else {
              print('Обновляем запись в Supabase: $remoteId');
              final success = await _remoteRepo.update(remoteId, {'name': name});
              if (success) {
                await _localRepo.markSyncedByLocalId(localId);
              }
            }
          }
        } catch (e) {
          print('Ошибка при обработке записи: $e');
          // Продолжаем обработку других записей
        }
      }
    } catch (e) {
      print('Ошибка при отправке локальных изменений: $e');
    }
  }

  /// Получение изменений из Supabase
  Future<void> _pullRemoteChanges() async {
    try {
      // Получаем все записи из Supabase (для простоты)
      // В реальном приложении можно использовать временные метки
      final remoteData = await _remoteRepo.fetchAll();
      print('Получено ${remoteData.length} записей из Supabase');
      
      for (final remote in remoteData) {
        try {
          await _localRepo.applyRemoteToLocal(remote);
        } catch (e) {
          print('Ошибка при применении удаленной записи: $e');
        }
      }
    } catch (e) {
      print('Ошибка при получении изменений из Supabase: $e');
    }
  }

  /// Асинхронная синхронизация новой записи в Supabase
  Future<void> _syncToSupabase(int localId, Department department) async {
    try {
      final remoteId = await _remoteRepo.insert(department.toSupabaseMap());
      if (remoteId != null) {
        await _localRepo.setRemoteId(localId, remoteId);
        print('Отдел успешно синхронизирован с Supabase: $remoteId');
      }
    } catch (e) {
      print('Ошибка при синхронизации нового отдела с Supabase: $e');
      // Обработка офлайн-режима - запись остается в состоянии pending
    }
  }

  /// Асинхронная синхронизация обновления в Supabase
  Future<void> _syncUpdateToSupabase(Department department) async {
    try {
      final success = await _remoteRepo.update(
        department.remoteId!, 
        department.toSupabaseMap()
      );
      if (success) {
        await _localRepo.markSyncedByLocalId(department.id!);
        print('Обновление отдела синхронизировано с Supabase');
      }
    } catch (e) {
      print('Ошибка при синхронизации обновления отдела с Supabase: $e');
    }
  }

  /// Асинхронная синхронизация удаления в Supabase
  Future<void> _syncDeleteToSupabase(String remoteId) async {
    try {
      final success = await _remoteRepo.delete(remoteId);
      if (success) {
        print('Удаление отдела синхронизировано с Supabase');
      }
    } catch (e) {
      print('Ошибка при синхронизации удаления отдела с Supabase: $e');
    }
  }

  /// Инициализация тестовыми данными
  Future<void> seedIfEmpty() async {
    await _localRepo.seedIfEmpty();
  }
}
