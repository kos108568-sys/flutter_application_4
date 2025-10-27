import 'package:flutter/material.dart';
import 'features/departments/data/department_repository.dart';
import 'features/departments/data/department_model.dart';

/// Простой тест модуля отделов
class DepartmentsTestScreen extends StatefulWidget {
  const DepartmentsTestScreen({super.key});

  @override
  State<DepartmentsTestScreen> createState() => _DepartmentsTestScreenState();
}

class _DepartmentsTestScreenState extends State<DepartmentsTestScreen> {
  final _repository = DepartmentRepository();
  List<Department> _departments = [];
  bool _isLoading = false;
  String _status = 'Готов к тестированию';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _status = 'Загрузка отделов...';
    });

    try {
      final departments = await _repository.getAllDepartments();
      setState(() {
        _departments = departments;
        _isLoading = false;
        _status = 'Загружено отделов: ${departments.length}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Ошибка: $e';
      });
    }
  }

  Future<void> _addTestDepartment() async {
    setState(() {
      _status = 'Добавление тестового отдела...';
    });

    try {
      final department = Department(name: 'Тестовая кафедра ${DateTime.now().millisecondsSinceEpoch}');
      await _repository.insertDepartment(department);
      await _loadDepartments();
      setState(() {
        _status = 'Отдел добавлен успешно';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка при добавлении: $e';
      });
    }
  }

  Future<void> _testSync() async {
    setState(() {
      _status = 'Тестирование синхронизации...';
    });

    try {
      await _repository.syncDepartments();
      await _loadDepartments();
      setState(() {
        _status = 'Синхронизация завершена';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка синхронизации: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест модуля отделов'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Статус: $_status',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // Кнопки
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadDepartments,
                  child: const Text('Обновить'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addTestDepartment,
                  child: const Text('Добавить тест'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSync,
                  child: const Text('Синхронизация'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Список отделов
            const Text(
              'Отделы:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _departments.isEmpty
                      ? const Center(
                          child: Text(
                            'Отделы не найдены',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _departments.length,
                          itemBuilder: (context, index) {
                            final department = _departments[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(department.name),
                                subtitle: Text(
                                  'ID: ${department.id} | Sync: ${department.syncState}',
                                  style: TextStyle(
                                    color: department.syncState == 'synced'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: department.remoteId != null
                                    ? const Icon(Icons.cloud_done, color: Colors.green)
                                    : const Icon(Icons.cloud_off, color: Colors.orange),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
