import 'package:supabase_flutter/supabase_flutter.dart';

/// Удаленный репозиторий для работы с отделами в Supabase
class DepartmentsRemoteRepository {
  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('Supabase не инициализирован: $e');
      return null;
    }
  }

  /// Вставка отдела в Supabase
  Future<String?> insert(Map<String, dynamic> data) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, пропускаем вставку');
      return null;
    }
    
    try {
      final response = await client
          .from('departments')
          .insert(data)
          .select('id')
          .single();
      
      return response['id']?.toString();
    } catch (e) {
      print('Ошибка при вставке отдела в Supabase: $e');
      return null;
    }
  }

  /// Обновление отдела в Supabase
  Future<bool> update(String id, Map<String, dynamic> data) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, пропускаем обновление');
      return false;
    }
    
    try {
      await client
          .from('departments')
          .update(data)
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Ошибка при обновлении отдела в Supabase: $e');
      return false;
    }
  }

  /// Удаление отдела из Supabase
  Future<bool> delete(String id) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, пропускаем удаление');
      return false;
    }
    
    try {
      await client
          .from('departments')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Ошибка при удалении отдела из Supabase: $e');
      return false;
    }
  }

  /// Получение всех отделов из Supabase
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем пустой список');
      return [];
    }
    
    try {
      final response = await client
          .from('departments')
          .select('*')
          .order('id', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Ошибка при получении отделов из Supabase: $e');
      return [];
    }
  }

  /// Получение отделов, измененных после указанной даты
  Future<List<Map<String, dynamic>>> fetchSince(DateTime since) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем пустой список');
      return [];
    }
    
    try {
      final response = await client
          .from('departments')
          .select('*')
          .gte('updated_at', since.toIso8601String())
          .order('updated_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Ошибка при получении измененных отделов из Supabase: $e');
      return [];
    }
  }

  /// Получение отдела по ID
  Future<Map<String, dynamic>?> fetchById(String id) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем null');
      return null;
    }
    
    try {
      final response = await client
          .from('departments')
          .select('*')
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      print('Ошибка при получении отдела по ID из Supabase: $e');
      return null;
    }
  }

  /// Проверка существования отдела по имени
  Future<bool> existsByName(String name) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем false');
      return false;
    }
    
    try {
      final response = await client
          .from('departments')
          .select('id')
          .eq('name', name)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Ошибка при проверке существования отдела в Supabase: $e');
      return false;
    }
  }
}
