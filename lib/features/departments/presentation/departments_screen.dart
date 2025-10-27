import 'package:flutter/material.dart';
import '../data/department_repository.dart';
import '../data/department_model.dart';
import 'department_form_dialog.dart';

/// Экран для управления отделами
class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final _repository = DepartmentRepository();
  final _searchController = TextEditingController();
  List<Department> _departments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Загрузка списка отделов
  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _repository.getAllDepartments(
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при загрузке отделов: $e');
    }
  }

  /// Поиск отделов
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadDepartments();
  }

  /// Добавление нового отдела
  Future<void> _addDepartment() async {
    final result = await showDialog<Department>(
      context: context,
      builder: (context) => const DepartmentFormDialog(),
    );

    if (result != null) {
      try {
        await _repository.insertDepartment(result);
        _loadDepartments();
        _showSuccessSnackBar('Отдел успешно добавлен');
      } catch (e) {
        _showErrorSnackBar('Ошибка при добавлении отдела: $e');
      }
    }
  }

  /// Редактирование отдела
  Future<void> _editDepartment(Department department) async {
    final result = await showDialog<Department>(
      context: context,
      builder: (context) => DepartmentFormDialog(department: department),
    );

    if (result != null) {
      try {
        await _repository.updateDepartment(result);
        _loadDepartments();
        _showSuccessSnackBar('Отдел успешно обновлен');
      } catch (e) {
        _showErrorSnackBar('Ошибка при обновлении отдела: $e');
      }
    }
  }

  /// Удаление отдела
  Future<void> _deleteDepartment(Department department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить отдел "${department.name}"?'),
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
        await _repository.deleteDepartment(department.id!);
        _loadDepartments();
        _showSuccessSnackBar('Отдел успешно удален');
      } catch (e) {
        _showErrorSnackBar('Ошибка при удалении отдела: $e');
      }
    }
  }

  /// Синхронизация с Supabase
  Future<void> _syncDepartments() async {
    try {
      await _repository.syncDepartments();
      _loadDepartments();
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
        title: const Text('Отделы'),
        actions: [
          IconButton(
            onPressed: _syncDepartments,
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
                hintText: 'Поиск отделов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Список отделов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _departments.isEmpty
                    ? const Center(
                        child: Text(
                          'Отделы не найдены',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _departments.length,
                        itemBuilder: (context, index) {
                          final department = _departments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
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
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editDepartment(department);
                                      break;
                                    case 'delete':
                                      _deleteDepartment(department);
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
        onPressed: _addDepartment,
        child: const Icon(Icons.add),
        tooltip: 'Добавить отдел',
      ),
    );
  }
}
