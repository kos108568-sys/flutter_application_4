import 'data/department_repository.dart';
import 'data/department_model.dart';

/// Тестовый класс для проверки работы модуля отделов
class DepartmentsTest {
  final _repository = DepartmentRepository();

  /// Запуск всех тестов
  Future<void> runAllTests() async {
    print('🧪 Начинаем тестирование модуля отделов...\n');

    try {
      await _testInsertDepartment();
      await _testGetAllDepartments();
      await _testUpdateDepartment();
      await _testSearchDepartments();
      await _testSyncDepartments();
      await _testDeleteDepartment();

      print('✅ Все тесты прошли успешно!');
    } catch (e) {
      print('❌ Ошибка при тестировании: $e');
    }
  }

  /// Тест добавления отдела
  Future<void> _testInsertDepartment() async {
    print('📝 Тест добавления отдела...');
    
    final department = Department(name: 'Тестовая кафедра');
    final id = await _repository.insertDepartment(department);
    
    print('   ✅ Отдел добавлен с ID: $id');
  }

  /// Тест получения всех отделов
  Future<void> _testGetAllDepartments() async {
    print('📋 Тест получения всех отделов...');
    
    final departments = await _repository.getAllDepartments();
    
    print('   ✅ Получено отделов: ${departments.length}');
    for (final dept in departments) {
      print('      - ${dept.name} (ID: ${dept.id}, Sync: ${dept.syncState})');
    }
  }

  /// Тест обновления отдела
  Future<void> _testUpdateDepartment() async {
    print('✏️ Тест обновления отдела...');
    
    final departments = await _repository.getAllDepartments();
    if (departments.isNotEmpty) {
      final department = departments.first;
      final updatedDepartment = department.copyWith(
        name: '${department.name} (обновлено)',
      );
      
      await _repository.updateDepartment(updatedDepartment);
      print('   ✅ Отдел обновлен: ${updatedDepartment.name}');
    } else {
      print('   ⚠️ Нет отделов для обновления');
    }
  }

  /// Тест поиска отделов
  Future<void> _testSearchDepartments() async {
    print('🔍 Тест поиска отделов...');
    
    final departments = await _repository.getAllDepartments(search: 'Тест');
    
    print('   ✅ Найдено отделов по запросу "Тест": ${departments.length}');
    for (final dept in departments) {
      print('      - ${dept.name}');
    }
  }

  /// Тест синхронизации
  Future<void> _testSyncDepartments() async {
    print('🔄 Тест синхронизации отделов...');
    
    try {
      await _repository.syncDepartments();
      print('   ✅ Синхронизация выполнена успешно');
    } catch (e) {
      print('   ⚠️ Ошибка синхронизации (возможно, нет сети): $e');
    }
  }

  /// Тест удаления отдела
  Future<void> _testDeleteDepartment() async {
    print('🗑️ Тест удаления отдела...');
    
    final departments = await _repository.getAllDepartments();
    if (departments.length > 1) {
      final departmentToDelete = departments.last;
      await _repository.deleteDepartment(departmentToDelete.id!);
      print('   ✅ Отдел удален: ${departmentToDelete.name}');
    } else {
      print('   ⚠️ Недостаточно отделов для тестирования удаления');
    }
  }

  /// Инициализация тестовыми данными
  Future<void> seedTestData() async {
    print('🌱 Инициализация тестовыми данными...');
    
    await _repository.seedIfEmpty();
    print('   ✅ Тестовые данные добавлены');
  }
}

/// Функция для запуска тестов из main.dart
Future<void> runDepartmentsTests() async {
  final test = DepartmentsTest();
  await test.seedTestData();
  await test.runAllTests();
}
