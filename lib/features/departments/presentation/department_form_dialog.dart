import 'package:flutter/material.dart';
import '../data/department_model.dart';

/// Диалог для добавления/редактирования отдела
class DepartmentFormDialog extends StatefulWidget {
  final Department? department;

  const DepartmentFormDialog({super.key, this.department});

  @override
  State<DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.department != null) {
      _nameController.text = widget.department!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Сохранение отдела
  Future<void> _saveDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final department = Department(
        id: widget.department?.id,
        name: _nameController.text.trim(),
        remoteId: widget.department?.remoteId,
        updatedAt: widget.department?.updatedAt,
        deleted: widget.department?.deleted ?? 0,
        syncState: widget.department?.syncState ?? 'synced',
      );

      Navigator.of(context).pop(department);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при сохранении: $e');
    }
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
    return AlertDialog(
      title: Text(widget.department == null ? 'Добавить отдел' : 'Редактировать отдел'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название отдела',
                hintText: 'Введите название отдела',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Название отдела обязательно';
                }
                if (value.trim().length < 2) {
                  return 'Название должно содержать минимум 2 символа';
                }
                return null;
              },
              enabled: !_isLoading,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDepartment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.department == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }
}
