import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'app.dart';
import 'core/app_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Запуск приложения...');
    
    final isDesktop = !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS
    );
    
    if (isDesktop) {
      print('Инициализация SQLite для десктопа...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('SQLite инициализирован');
    }
    
    // Initialize app (Supabase and sync)
    await initializeApp();
    
    print('Запуск приложения...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Ошибка при инициализации приложения: $e');
    print('Stack trace: $stackTrace');
    
    // Запускаем приложение даже при ошибке инициализации
    runApp(const MyApp());
  }
}
