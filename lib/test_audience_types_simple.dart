import 'package:flutter/material.dart';
import 'features/audience_types/data/audience_type_repository.dart';
import 'features/audience_types/data/audience_type_model.dart';

/// Простой тест модуля типов аудиторий
class AudienceTypesTestScreen extends StatefulWidget {
  const AudienceTypesTestScreen({super.key});

  @override
  State<AudienceTypesTestScreen> createState() => _AudienceTypesTestScreenState();
}

class _AudienceTypesTestScreenState extends State<AudienceTypesTestScreen> {
  final _repository = AudienceTypeRepository();
  List<AudienceType> _audienceTypes = [];
  bool _isLoading = false;
  String _status = 'Готов к тестированию';

  @override
  void initState() {
    super.initState();
    _loadAudienceTypes();
  }

  Future<void> _loadAudienceTypes() async {
    setState(() {
      _isLoading = true;
      _status = 'Загрузка типов аудиторий...';
    });

    try {
      final audienceTypes = await _repository.getAllAudienceTypes();
      setState(() {
        _audienceTypes = audienceTypes;
        _isLoading = false;
        _status = 'Загружено типов аудиторий: ${audienceTypes.length}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Ошибка: $e';
      });
    }
  }

  Future<void> _addTestAudienceType() async {
    setState(() {
      _status = 'Добавление тестового типа аудитории...';
    });

    try {
      final audienceType = AudienceType(
        name: 'Тестовый тип ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Описание тестового типа',
      );
      await _repository.insertAudienceType(audienceType);
      await _loadAudienceTypes();
      setState(() {
        _status = 'Тип аудитории добавлен успешно';
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
      await _repository.syncAudienceTypes();
      await _loadAudienceTypes();
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
      await _loadAudienceTypes();
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
        title: const Text('Тест типов аудиторий'),
        backgroundColor: Colors.purple,
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
                  onPressed: _isLoading ? null : _loadAudienceTypes,
                  child: const Text('Обновить'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addTestAudienceType,
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
            
            // Список типов аудиторий
            const Text(
              'Типы аудиторий:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _audienceTypes.isEmpty
                      ? const Center(
                          child: Text(
                            'Типы аудиторий не найдены',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _audienceTypes.length,
                          itemBuilder: (context, index) {
                            final audienceType = _audienceTypes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(audienceType.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (audienceType.description != null)
                                      Text(
                                        audienceType.description!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${audienceType.id} | Sync: ${audienceType.syncState}',
                                      style: TextStyle(
                                        color: audienceType.syncState == 'synced'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: audienceType.remoteId != null
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
