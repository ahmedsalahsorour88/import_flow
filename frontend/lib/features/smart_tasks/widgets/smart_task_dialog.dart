import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/smart_tasks_provider.dart';
import '../models/smart_task_model.dart';

class SmartTaskDialog extends ConsumerStatefulWidget {
  final SmartTaskModel? taskToEdit;

  const SmartTaskDialog({super.key, this.taskToEdit});

  static Future<void> show(BuildContext context, {SmartTaskModel? taskToEdit}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmartTaskDialog(taskToEdit: taskToEdit),
    );
  }

  @override
  ConsumerState<SmartTaskDialog> createState() => _SmartTaskDialogState();
}

class _SmartTaskDialogState extends ConsumerState<SmartTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _notesController;
  late TextEditingController _dueDateController;
  late TextEditingController _reminderDateController;

  String _taskType = 'Manual To-Do';
  String _priority = 'Medium';
  String _reminderType = 'General Reminder';
  String _assignedUser = 'Kamal';
  int? _selectedFileId;
  String? _selectedFileCode;
  bool _isSubmitting = false;

  static const List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  static const List<String> _reminderTypes = [
    'General Reminder',
    'Supplier Follow-up',
    'Bank Form 4',
    'Shipping Line',
    'Customs Broker',
    'Document Review',
    'ETA Arrival',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _dueDateController = TextEditingController(text: t?.dueDate ?? DateTime.now().add(const Duration(days: 2)).toString().split(' ')[0]);
    _reminderDateController = TextEditingController(text: t?.reminderDate ?? DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0]);

    if (t != null) {
      _taskType = t.taskType;
      _priority = t.priority;
      _reminderType = t.reminderType;
      _assignedUser = t.assignedUser;
      _selectedFileId = t.importFileId;
      _selectedFileCode = t.importFileCode;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    _reminderDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'task_type': _taskType,
        'import_file_id': _selectedFileId,
        'import_file_code': _selectedFileCode,
        'assigned_user': _assignedUser,
        'priority': _priority,
        'reminder_type': _reminderType,
        'due_date': _dueDateController.text,
        'reminder_date': _reminderDateController.text,
        'notes': _notesController.text.trim(),
      };

      if (widget.taskToEdit != null) {
        await ref.read(smartTasksProvider.notifier).updateTask(widget.taskToEdit!.taskId, payload);
      } else {
        await ref.read(smartTasksProvider.notifier).createTask(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.taskToEdit != null ? 'تم تحديث المهمة بنجاح' : 'تم إضافة المهمة والتذكير بنجاح'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تقديم المهمة: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFilesState = ref.watch(importFilesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_task, color: AppTheme.cobalt, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    widget.taskToEdit != null ? 'تعديل المهمة والتذكير' : 'إضافة مهمة جديدة وتذكير (2.4 / 2.5)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان المهمة / التذكير *',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'عنوان المهمة مطلوب' : null,
                      ),
                      const SizedBox(height: 14),

                      // Related Import File Searchable Dropdown
                      importFilesState.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (files) {
                          return SearchableDropdownField<int>(
                            value: _selectedFileId,
                            labelText: 'ربط بملف الاستيراد / الشحنة (اختياري)',
                            items: files.map((f) => SearchableDropdownItem<int>(
                              value: f.importFileId,
                              label: '${f.customFileNumber ?? f.importFileCode} - ${f.supplierName}',
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFileId = val;
                                if (val != null) {
                                  final selectedFile = files.firstWhere((f) => f.importFileId == val);
                                  _selectedFileCode = selectedFile.customFileNumber ?? selectedFile.importFileCode;
                                } else {
                                  _selectedFileCode = null;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Priority & Reminder Type Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _priority,
                              decoration: const InputDecoration(labelText: 'الأولوية (Priority)', border: OutlineInputBorder()),
                              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) => setState(() => _priority = v!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _reminderType,
                              decoration: const InputDecoration(labelText: 'نوع التذكير (Reminder Engine)', border: OutlineInputBorder()),
                              items: _reminderTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _reminderType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Due Date & Reminder Date Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dueDateController,
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الإنجاز المطلوب (Due Date)',
                                prefixIcon: Icon(Icons.event),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _reminderDateController,
                              decoration: const InputDecoration(
                                labelText: 'تاريخ التذكير (Reminder Date)',
                                prefixIcon: Icon(Icons.notifications_active),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'وصف المهمة والمتطلبات',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات إضافية',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(widget.taskToEdit != null ? 'تحديث المهمة' : 'حفظ المهمة والتذكير', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
