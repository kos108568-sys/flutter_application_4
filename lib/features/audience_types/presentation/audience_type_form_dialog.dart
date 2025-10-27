import 'package:flutter/material.dart';
import '../data/audience_type_model.dart';

/// Диалог для добавления/редактирования типа аудитории
class AudienceTypeFormDialog extends StatefulWidget {
  final AudienceType? audienceType;

  const AudienceTypeFormDialog({super.key, this.audienceType});

  @override
  State<AudienceTypeFormDialog> createState() => _AudienceTypeFormDialogState();
}

class _AudienceTypeFormDialogState extends State<AudienceTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.audienceType != null) {
      _nameController.text = widget.audienceType!.name;
      _descriptionController.text = widget.audienceType!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Сохранение типа аудитории
  Future<void> _saveAudienceType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final audienceType = AudienceType(
        id: widget.audienceType?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        remoteId: widget.audienceType?.remoteId,
        updatedAt: widget.audienceType?.updatedAt,
        deleted: widget.audienceType?.deleted ?? 0,
        syncState: widget.audienceType?.syncState ?? 'synced',
      );

      Navigator.of(context).pop(audienceType);
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
      title: Text(widget.audienceType == null ? 'Добавить тип аудитории' : 'Редактировать тип аудитории'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название типа',
                hintText: 'Введите название типа аудитории',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Название типа обязательно';
                }
                if (value.trim().length < 2) {
                  return 'Название должно содержать минимум 2 символа';
                }
                return null;
              },
              enabled: !_isLoading,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                hintText: 'Введите описание типа аудитории',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isLoading,
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
          onPressed: _isLoading ? null : _saveAudienceType,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.audienceType == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }
}
