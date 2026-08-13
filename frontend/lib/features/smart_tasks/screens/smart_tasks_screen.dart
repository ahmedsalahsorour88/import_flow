import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../providers/smart_tasks_provider.dart';
import '../widgets/smart_task_dialog.dart';

class SmartTasksScreen extends ConsumerStatefulWidget {
  const SmartTasksScreen({super.key});

  @override
  ConsumerState<SmartTasksScreen> createState() => _SmartTasksScreenState();
}

class _SmartTasksScreenState extends ConsumerState<SmartTasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTaskType = 'All';
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(smartTasksProvider.notifier).fetchTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    ref.read(smartTasksProvider.notifier).fetchTasks(
      taskType: _selectedTaskType,
      priority: _selectedPriority,
      status: _selectedStatus,
      search: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartTasksProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('Smart Task Management & Reminder Engine (2.4 / 2.5)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(smartTasksProvider.notifier).fetchTasks(),
          ),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar & Filters Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                      onPressed: () => SmartTaskDialog.show(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('إضافة مهمة جديدة / تذكير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),

                    // Filter Task Type
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTaskType,
                        decoration: const InputDecoration(labelText: 'نوع المهمة', isDense: true, border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('الكل')),
                          DropdownMenuItem(value: 'System Generated', child: Text('توليد آلي (System)')),
                          DropdownMenuItem(value: 'Manual To-Do', child: Text('مهمة يدوية (To-Do)')),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedTaskType = v!);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Filter Priority
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(labelText: 'الأولوية', isDense: true, border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('الكل')),
                          DropdownMenuItem(value: 'Low', child: Text('منخفضة')),
                          DropdownMenuItem(value: 'Medium', child: Text('متوسطة')),
                          DropdownMenuItem(value: 'High', child: Text('عالية')),
                          DropdownMenuItem(value: 'Critical', child: Text('حرجة (Critical)')),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedPriority = v!);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Filter Status
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'الحالة', isDense: true, border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('الكل')),
                          DropdownMenuItem(value: 'Pending', child: Text('قيد الانتظار')),
                          DropdownMenuItem(value: 'In Progress', child: Text('قيد التنفيذ')),
                          DropdownMenuItem(value: 'Completed', child: Text('مكتملة')),
                          DropdownMenuItem(value: 'Cancelled', child: Text('ملغاة')),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedStatus = v!);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const Spacer(),

                    // Search Box
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود المهمة، العنوان...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _onFilterChanged(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks List / Table
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                        ? Center(child: Text('خطأ في جلب المهام: ${state.error}', style: const TextStyle(color: AppTheme.crimson)))
                        : state.tasks.isEmpty
                            ? const Center(child: Text('لا توجد مهام أو تذكيرات مطابقة للفلاتر.'))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                    columns: const [
                                      DataColumn(label: Text('كود المهمة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('نوع المهمة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('عنوان المهمة والتفاصيل', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الشحنة المرتبطة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الأولوية', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('نوع التذكير (Reminder Engine)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('تاريخ الإنجاز (Due Date)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: state.tasks.map((t) {
                                      final isSys = t.taskType == 'System Generated';

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(t.taskCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                          DataCell(
                                            Chip(
                                              label: Text(isSys ? 'آلي (System)' : 'يدوي (To-Do)', style: TextStyle(fontSize: 10, color: isSys ? Colors.purple.shade900 : Colors.blue.shade900)),
                                              backgroundColor: isSys ? Colors.purple.shade50 : Colors.blue.shade50,
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                if (t.description != null && t.description!.isNotEmpty)
                                                  Text(t.description!, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(t.importFileCode ?? 'عام (General)')),
                                          DataCell(
                                            Chip(
                                              label: Text(t.priority, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                              backgroundColor: t.priority == 'Critical' || t.priority == 'High' ? Colors.red : (t.priority == 'Medium' ? Colors.orange : Colors.green),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                const Icon(Icons.notifications_active, size: 14, color: AppTheme.orange),
                                                const SizedBox(width: 4),
                                                Text(t.reminderType, style: const TextStyle(fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(t.dueDate ?? '-')),
                                          DataCell(
                                            Chip(
                                              label: Text(t.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                              backgroundColor: t.status == 'Completed' ? AppTheme.emerald : (t.status == 'In Progress' ? AppTheme.cobalt : Colors.grey),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                if (t.status != 'Completed')
                                                  IconButton(
                                                    icon: const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 20),
                                                    tooltip: 'إكمال المهمة',
                                                    onPressed: () {
                                                      ref.read(smartTasksProvider.notifier).updateTask(t.taskId, {'status': 'Completed'});
                                                    },
                                                  ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                                                  onPressed: () => SmartTaskDialog.show(context, taskToEdit: t),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                                  onPressed: () => ref.read(smartTasksProvider.notifier).deleteTask(t.taskId),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
