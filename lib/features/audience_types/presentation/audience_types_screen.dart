import 'package:flutter/material.dart';
import '../data/audience_type_repository.dart';
import '../data/audience_type_model.dart';
import 'audience_type_form_dialog.dart';

/// Экран для управления типами аудиторий
class AudienceTypesScreen extends StatefulWidget {
  const AudienceTypesScreen({super.key});

  @override
  State<AudienceTypesScreen> createState() => _AudienceTypesScreenState();
}

class _AudienceTypesScreenState extends State<AudienceTypesScreen> {
  final _repository = AudienceTypeRepository();
  final _searchController = TextEditingController();
  List<AudienceType> _audienceTypes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAudienceTypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Загрузка списка типов аудиторий
  Future<void> _loadAudienceTypes() async {
    setState(() => _isLoading = true);
    try {
      final audienceTypes = await _repository.getAllAudienceTypes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _audienceTypes = audienceTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при загрузке типов аудиторий: $e');
    }
  }

  /// Поиск типов аудиторий
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadAudienceTypes();
  }

  /// Добавление нового типа аудитории
  Future<void> _addAudienceType() async {
    final result = await showDialog<AudienceType>(
      context: context,
      builder: (context) => const AudienceTypeFormDialog(),
    );

    if (result != null) {
      try {
        await _repository.insertAudienceType(result);
        _loadAudienceTypes();
        _showSuccessSnackBar('Тип аудитории успешно добавлен');
      } catch (e) {
        _showErrorSnackBar('Ошибка при добавлении типа аудитории: $e');
      }
    }
  }

  /// Редактирование типа аудитории
  Future<void> _editAudienceType(AudienceType audienceType) async {
    final result = await showDialog<AudienceType>(
      context: context,
      builder: (context) => AudienceTypeFormDialog(audienceType: audienceType),
    );

    if (result != null) {
      try {
        await _repository.updateAudienceType(result);
        _loadAudienceTypes();
        _showSuccessSnackBar('Тип аудитории успешно обновлен');
      } catch (e) {
        _showErrorSnackBar('Ошибка при обновлении типа аудитории: $e');
      }
    }
  }

  /// Удаление типа аудитории
  Future<void> _deleteAudienceType(AudienceType audienceType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить тип аудитории "${audienceType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteAudienceType(audienceType.id!);
        _loadAudienceTypes();
        _showSuccessSnackBar('Тип аудитории успешно удален');
      } catch (e) {
        _showErrorSnackBar('Ошибка при удалении типа аудитории: $e');
      }
    }
  }

  /// Синхронизация с Supabase
  Future<void> _syncAudienceTypes() async {
    try {
      await _repository.syncAudienceTypes();
      _loadAudienceTypes();
      _showSuccessSnackBar('Синхронизация завершена');
    } catch (e) {
      _showErrorSnackBar('Ошибка при синхронизации: $e');
    }
  }

  /// Показать уведомление об успехе
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Показать уведомление об ошибке
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Типы аудиторий'),
        actions: [
          IconButton(
            onPressed: _syncAudienceTypes,
            icon: const Icon(Icons.sync),
            tooltip: 'Синхронизировать с Supabase',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск типов аудиторий...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Список типов аудиторий
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _audienceTypes.isEmpty
                    ? const Center(
                        child: Text(
                          'Типы аудиторий не найдены',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _audienceTypes.length,
                        itemBuilder: (context, index) {
                          final audienceType = _audienceTypes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editAudienceType(audienceType);
                                      break;
                                    case 'delete':
                                      _deleteAudienceType(audienceType);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Редактировать'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete),
                                        SizedBox(width: 8),
                                        Text('Удалить'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAudienceType,
        child: const Icon(Icons.add),
        tooltip: 'Добавить тип аудитории',
      ),
    );
  }
}
