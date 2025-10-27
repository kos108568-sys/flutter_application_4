import 'package:supabase_flutter/supabase_flutter.dart';

/// Удаленный репозиторий для работы с типами аудиторий в Supabase
class AudienceTypesRemoteRepository {
  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('Supabase не инициализирован: $e');
      return null;
    }
  }

  /// Вставка типа аудитории в Supabase
  Future<String?> insert(Map<String, dynamic> data) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, пропускаем вставку');
      return null;
    }
    
    try {
      final response = await client
          .from('audience_types')
          .insert(data)
          .select('id')
          .single();
      
      return response['id']?.toString();
    } catch (e) {
      print('Ошибка при вставке типа аудитории в Supabase: $e');
      return null;
    }
  }

  /// Обновление типа аудитории в Supabase
  Future<bool> update(String id, Map<String, dynamic> data) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, пропускаем обновление');
      return false;
    }
    
    try {
      await client
          .from('audience_types')
          .update(data)
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Ошибка при обновлении типа аудитории в Supabase: $e');
      return false;
    }
  }

  /// Удаление типа аудитории из Supabase
  Future<bool> delete(String id) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, пропускаем удаление');
      return false;
    }
    
    try {
      await client
          .from('audience_types')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Ошибка при удалении типа аудитории из Supabase: $e');
      return false;
    }
  }

  /// Получение всех типов аудиторий из Supabase
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем пустой список');
      return [];
    }
    
    try {
      final response = await client
          .from('audience_types')
          .select('*')
          .order('id', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Ошибка при получении типов аудиторий из Supabase: $e');
      return [];
    }
  }

  /// Получение типов аудиторий, измененных после указанной даты
  Future<List<Map<String, dynamic>>> fetchSince(DateTime since) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем пустой список');
      return [];
    }
    
    try {
      final response = await client
          .from('audience_types')
          .select('*')
          .gte('updated_at', since.toIso8601String())
          .order('updated_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Ошибка при получении измененных типов аудиторий из Supabase: $e');
      return [];
    }
  }

  /// Получение типа аудитории по ID
  Future<Map<String, dynamic>?> fetchById(String id) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем null');
      return null;
    }
    
    try {
      final response = await client
          .from('audience_types')
          .select('*')
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      print('Ошибка при получении типа аудитории по ID из Supabase: $e');
      return null;
    }
  }

  /// Проверка существования типа аудитории по имени
  Future<bool> existsByName(String name) async {
    final client = supabase;
    if (client == null) {
      print('Supabase не инициализирован, возвращаем false');
      return false;
    }
    
    try {
      final response = await client
          .from('audience_types')
          .select('id')
          .eq('name', name)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Ошибка при проверке существования типа аудитории в Supabase: $e');
      return false;
    }
  }
}
