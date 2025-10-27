import 'package:supabase_flutter/supabase_flutter.dart';
import 'audience_type_model.dart';
import 'audience_types_repository.dart';
import 'audience_types_remote_repository.dart';

/// Основной репозиторий для работы с типами аудиторий
/// Обеспечивает двустороннюю синхронизацию между SQLite и Supabase
class AudienceTypeRepository {
  final _localRepo = AudienceTypesRepository();
  final _remoteRepo = AudienceTypesRemoteRepository();
  
  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('Supabase не инициализирован: $e');
      return null;
    }
  }

  /// Получение всех типов аудиторий (локально)
  Future<List<AudienceType>> getAllAudienceTypes({String? search, String? orderBy}) async {
    return await _localRepo.getAllAudienceTypes(search: search, orderBy: orderBy);
  }

  /// Получение типа аудитории по ID (локально)
  Future<AudienceType?> getById(int id) async {
    return await _localRepo.getById(id);
  }

  /// Вставка типа аудитории с синхронизацией
  /// Сначала сохраняет локально, затем синхронизирует с Supabase
  Future<int> insertAudienceType(AudienceType audienceType) async {
    try {
      // Сохранение локально
      final localId = await _localRepo.insertAudienceType(audienceType);
      
      // Синхронизация с Supabase (в фоне, не блокирует UI)
      _syncToSupabase(localId, audienceType);
      
      return localId;
    } catch (e) {
      print('Ошибка при вставке типа аудитории: $e');
      rethrow;
    }
  }

  /// Обновление типа аудитории с синхронизацией
  Future<int> updateAudienceType(AudienceType audienceType) async {
    try {
      // Обновление локально
      final result = await _localRepo.updateAudienceType(audienceType);
      
      // Синхронизация с Supabase (в фоне)
      if (result > 0 && audienceType.remoteId != null) {
        _syncUpdateToSupabase(audienceType);
      }
      
      return result;
    } catch (e) {
      print('Ошибка при обновлении типа аудитории: $e');
      rethrow;
    }
  }

  /// Удаление типа аудитории с синхронизацией
  Future<int> deleteAudienceType(int id) async {
    try {
      // Получаем тип аудитории для синхронизации
      final audienceType = await _localRepo.getById(id);
      
      // Мягкое удаление локально
      final result = await _localRepo.deleteAudienceType(id);
      
      // Синхронизация удаления с Supabase (в фоне)
      if (result > 0 && audienceType?.remoteId != null) {
        _syncDeleteToSupabase(audienceType!.remoteId!);
      }
      
      return result;
    } catch (e) {
      print('Ошибка при удалении типа аудитории: $e');
      rethrow;
    }
  }

  /// Двусторонняя синхронизация типов аудиторий
  /// Сравнивает данные SQLite и Supabase, синхронизирует недостающие записи
  Future<void> syncAudienceTypes() async {
    try {
      print('Начинаем синхронизацию типов аудиторий...');
      
      // 1. Отправляем локальные изменения в Supabase
      await _pushLocalChanges();
      
      // 2. Получаем изменения из Supabase
      await _pullRemoteChanges();
      
      print('Синхронизация типов аудиторий завершена');
    } catch (e) {
      print('Ошибка при синхронизации типов аудиторий: $e');
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
          
          print('Обрабатываем тип аудитории: $name (local_id: $localId, remote_id: $remoteId)');
          
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
  Future<void> _syncToSupabase(int localId, AudienceType audienceType) async {
    try {
      final remoteId = await _remoteRepo.insert(audienceType.toSupabaseMap());
      if (remoteId != null) {
        await _localRepo.setRemoteId(localId, remoteId);
        print('Тип аудитории успешно синхронизирован с Supabase: $remoteId');
      }
    } catch (e) {
      print('Ошибка при синхронизации нового типа аудитории с Supabase: $e');
      // Обработка офлайн-режима - запись остается в состоянии pending
    }
  }

  /// Асинхронная синхронизация обновления в Supabase
  Future<void> _syncUpdateToSupabase(AudienceType audienceType) async {
    try {
      final success = await _remoteRepo.update(
        audienceType.remoteId!, 
        audienceType.toSupabaseMap()
      );
      if (success) {
        await _localRepo.markSyncedByLocalId(audienceType.id!);
        print('Обновление типа аудитории синхронизировано с Supabase');
      }
    } catch (e) {
      print('Ошибка при синхронизации обновления типа аудитории с Supabase: $e');
    }
  }

  /// Асинхронная синхронизация удаления в Supabase
  Future<void> _syncDeleteToSupabase(String remoteId) async {
    try {
      final success = await _remoteRepo.delete(remoteId);
      if (success) {
        print('Удаление типа аудитории синхронизировано с Supabase');
      }
    } catch (e) {
      print('Ошибка при синхронизации удаления типа аудитории с Supabase: $e');
    }
  }

  /// Инициализация тестовыми данными
  Future<void> seedIfEmpty() async {
    await _localRepo.seedIfEmpty();
  }
}
