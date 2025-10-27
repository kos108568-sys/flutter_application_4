import 'package:supabase_flutter/supabase_flutter.dart';
import 'lesson_type_model.dart';
import 'lesson_types_repository.dart';
import 'lesson_types_remote_repository.dart';

/// Основной репозиторий для работы с типами занятий
/// Обеспечивает двустороннюю синхронизацию между SQLite и Supabase
class LessonTypeRepository {
  final _localRepo = LessonTypesRepository();
  final _remoteRepo = LessonTypesRemoteRepository();
  
  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('Supabase не инициализирован: $e');
      return null;
    }
  }

  /// Получение всех типов занятий (локально)
  Future<List<LessonType>> getAllLessonTypes({String? search, String? orderBy}) async {
    return await _localRepo.getAllLessonTypes(search: search, orderBy: orderBy);
  }

  /// Получение типа занятия по ID (локально)
  Future<LessonType?> getById(int id) async {
    return await _localRepo.getById(id);
  }

  /// Вставка типа занятия с синхронизацией
  /// Сначала сохраняет локально, затем синхронизирует с Supabase
  Future<int> insertLessonType(LessonType lessonType) async {
    try {
      // Сохранение локально
      final localId = await _localRepo.insertLessonType(lessonType);
      
      // Синхронизация с Supabase (в фоне, не блокирует UI)
      _syncToSupabase(localId, lessonType);
      
      return localId;
    } catch (e) {
      print('Ошибка при вставке типа занятия: $e');
      rethrow;
    }
  }

  /// Обновление типа занятия с синхронизацией
  Future<int> updateLessonType(LessonType lessonType) async {
    try {
      // Обновление локально
      final result = await _localRepo.updateLessonType(lessonType);
      
      // Синхронизация с Supabase (в фоне)
      if (result > 0 && lessonType.remoteId != null) {
        _syncUpdateToSupabase(lessonType);
      }
      
      return result;
    } catch (e) {
      print('Ошибка при обновлении типа занятия: $e');
      rethrow;
    }
  }

  /// Удаление типа занятия с синхронизацией
  Future<int> deleteLessonType(int id) async {
    try {
      // Получаем тип занятия для синхронизации
      final lessonType = await _localRepo.getById(id);
      
      // Мягкое удаление локально
      final result = await _localRepo.deleteLessonType(id);
      
      // Синхронизация удаления с Supabase (в фоне)
      if (result > 0 && lessonType?.remoteId != null) {
        _syncDeleteToSupabase(lessonType!.remoteId!);
      }
      
      return result;
    } catch (e) {
      print('Ошибка при удалении типа занятия: $e');
      rethrow;
    }
  }

  /// Двусторонняя синхронизация типов занятий
  /// Сравнивает данные SQLite и Supabase, синхронизирует недостающие записи
  Future<void> syncLessonTypes() async {
    try {
      print('Начинаем синхронизацию типов занятий...');
      
      // 1. Отправляем локальные изменения в Supabase
      await _pushLocalChanges();
      
      // 2. Получаем изменения из Supabase
      await _pullRemoteChanges();
      
      print('Синхронизация типов занятий завершена');
    } catch (e) {
      print('Ошибка при синхронизации типов занятий: $e');
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
          final description = row['description'] as String?;
          
          print('Обрабатываем тип занятия: $name (local_id: $localId, remote_id: $remoteId)');
          
          if (remoteId == null) {
            // Новая запись - создаем в Supabase
            if (deleted == 1) {
              print('Пропускаем удаленную локальную запись без remote_id');
              await _localRepo.markSyncedByLocalId(localId);
              continue;
            }
            
            print('Создаем новую запись в Supabase');
            final newRemoteId = await _remoteRepo.insert({
              'name': name,
              'description': description,
            });
            
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
              final success = await _remoteRepo.update(remoteId, {
                'name': name,
                'description': description,
              });
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
  Future<void> _syncToSupabase(int localId, LessonType lessonType) async {
    try {
      final remoteId = await _remoteRepo.insert(lessonType.toSupabaseMap());
      if (remoteId != null) {
        await _localRepo.setRemoteId(localId, remoteId);
        print('Тип занятия успешно синхронизирован с Supabase: $remoteId');
      }
    } catch (e) {
      print('Ошибка при синхронизации нового типа занятия с Supabase: $e');
      // Обработка офлайн-режима - запись остается в состоянии pending
    }
  }

  /// Асинхронная синхронизация обновления в Supabase
  Future<void> _syncUpdateToSupabase(LessonType lessonType) async {
    try {
      final success = await _remoteRepo.update(
        lessonType.remoteId!, 
        lessonType.toSupabaseMap()
      );
      if (success) {
        await _localRepo.markSyncedByLocalId(lessonType.id!);
        print('Обновление типа занятия синхронизировано с Supabase');
      }
    } catch (e) {
      print('Ошибка при синхронизации обновления типа занятия с Supabase: $e');
    }
  }

  /// Асинхронная синхронизация удаления в Supabase
  Future<void> _syncDeleteToSupabase(String remoteId) async {
    try {
      final success = await _remoteRepo.delete(remoteId);
      if (success) {
        print('Удаление типа занятия синхронизировано с Supabase');
      }
    } catch (e) {
      print('Ошибка при синхронизации удаления типа занятия с Supabase: $e');
    }
  }

  /// Инициализация тестовыми данными
  Future<void> seedIfEmpty() async {
    await _localRepo.seedIfEmpty();
  }
}
