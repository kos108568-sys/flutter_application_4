import 'package:flutter/material.dart';
import 'features/lesson_types/data/lesson_type_repository.dart';
import 'features/lesson_types/data/lesson_type_model.dart';

/// Простой тест модуля типов занятий
class LessonTypesTestScreen extends StatefulWidget {
  const LessonTypesTestScreen({super.key});

  @override
  State<LessonTypesTestScreen> createState() => _LessonTypesTestScreenState();
}

class _LessonTypesTestScreenState extends State<LessonTypesTestScreen> {
  final _repository = LessonTypeRepository();
  List<LessonType> _lessonTypes = [];
  bool _isLoading = false;
  String _status = 'Готов к тестированию';

  @override
  void initState() {
    super.initState();
    _loadLessonTypes();
  }

  Future<void> _loadLessonTypes() async {
    setState(() {
      _isLoading = true;
      _status = 'Загрузка типов занятий...';
    });

    try {
      final lessonTypes = await _repository.getAllLessonTypes();
      setState(() {
        _lessonTypes = lessonTypes;
        _isLoading = false;
        _status = 'Загружено типов занятий: ${lessonTypes.length}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Ошибка: $e';
      });
    }
  }

  Future<void> _addTestLessonType() async {
    setState(() {
      _status = 'Добавление тестового типа занятия...';
    });

    try {
      final lessonType = LessonType(
        name: 'Тестовый тип ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Описание тестового типа занятия',
      );
      await _repository.insertLessonType(lessonType);
      await _loadLessonTypes();
      setState(() {
        _status = 'Тип занятия добавлен успешно';
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
      await _repository.syncLessonTypes();
      await _loadLessonTypes();
      setState(() {
        _status = 'Синхронизация завершена';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка синхронизации: $e';
      });
    }
  }

  Future<void> _seedData() async {
    setState(() {
      _status = 'Добавление тестовых данных...';
    });

    try {
      await _repository.seedIfEmpty();
      await _loadLessonTypes();
      setState(() {
        _status = 'Тестовые данные добавлены';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка при добавлении тестовых данных: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест типов занятий'),
        backgroundColor: Colors.green,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadLessonTypes,
                  child: const Text('Обновить'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addTestLessonType,
                  child: const Text('Добавить тест'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSync,
                  child: const Text('Синхронизация'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _seedData,
                  child: const Text('Тестовые данные'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Список типов занятий
            const Text(
              'Типы занятий:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lessonTypes.isEmpty
                      ? const Center(
                          child: Text(
                            'Типы занятий не найдены',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _lessonTypes.length,
                          itemBuilder: (context, index) {
                            final lessonType = _lessonTypes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(lessonType.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lessonType.description != null)
                                      Text(
                                        lessonType.description!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${lessonType.id} | Sync: ${lessonType.syncState}',
                                      style: TextStyle(
                                        color: lessonType.syncState == 'synced'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: lessonType.remoteId != null
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
