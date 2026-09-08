import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/enterprise_data_table/enterprise_data_table.dart';
import '../models/smart_task_model.dart';
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
  Set<SmartTaskModel> _selectedTasks = {};

  @override
  void initState() {
    super.initState();
    if (!ref.read(smartTasksProvider).isLoading) {
      Future.microtask(() {
        ref.read(smartTasksProvider.notifier).fetchTasks();
      });
    }
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

  int _priorityWeight(String p) {
    switch (p.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  List<EnterpriseColumn<SmartTaskModel>> _buildColumns(BuildContext context) {
    final l = context.l10n;
    return [
      EnterpriseColumn<SmartTaskModel>(
        id: 'code',
        title: l.smartTasksColCode,
        isLocked: true,
        searchValue: (t) => t.taskCode,
        exportValue: (t) => t.taskCode,
        cellBuilder: (ctx, t, idx) => Text(
          t.taskCode,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
        ),
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'type',
        title: l.smartTasksColType,
        searchValue: (t) => t.taskType,
        exportValue: (t) => t.taskType,
        cellBuilder: (ctx, t, idx) {
          final isSys = t.taskType == 'System Generated';
          return Chip(
            visualDensity: VisualDensity.compact,
            label: Text(
              isSys ? l.smartTasksTypeSystem : l.smartTasksTypeManual,
              style: TextStyle(fontSize: 10, color: isSys ? Colors.purple.shade900 : Colors.blue.shade900),
            ),
            backgroundColor: isSys ? Colors.purple.shade50 : Colors.blue.shade50,
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'title',
        title: l.smartTasksColTitle,
        flex: 2,
        searchValue: (t) => '${t.title} ${t.description ?? ""}',
        exportValue: (t) => t.description != null ? '${t.title} - ${t.description}' : t.title,
        cellBuilder: (ctx, t, idx) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              if (t.description != null && t.description!.isNotEmpty)
                Text(
                  t.description!,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'shipment',
        title: l.smartTasksColShipment,
        searchValue: (t) => t.importFileCode ?? '',
        exportValue: (t) => t.importFileCode ?? l.smartTasksGeneralBadge,
        cellBuilder: (ctx, t, idx) => Text(
          t.importFileCode ?? l.smartTasksGeneralBadge,
          style: TextStyle(
            fontSize: 11,
            color: t.importFileCode != null ? AppTheme.cobalt : Colors.grey.shade700,
            fontWeight: t.importFileCode != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'priority',
        title: l.smartTasksColPriority,
        sortComparator: (a, b) => _priorityWeight(b.priority).compareTo(_priorityWeight(a.priority)),
        searchValue: (t) => t.priority,
        exportValue: (t) => t.priority,
        cellBuilder: (ctx, t, idx) {
          Color bg;
          switch (t.priority) {
            case 'Critical':
            case 'High':
              bg = Colors.red.shade700;
              break;
            case 'Medium':
              bg = Colors.orange.shade800;
              break;
            default:
              bg = Colors.green.shade700;
          }
          return Chip(
            visualDensity: VisualDensity.compact,
            label: Text(l.smartTaskPriorityLabel(t.priority), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: bg,
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'reminder',
        title: l.smartTasksColReminder,
        searchValue: (t) => t.reminderType,
        exportValue: (t) => t.reminderType,
        cellBuilder: (ctx, t, idx) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_active, size: 14, color: AppTheme.orange),
              const SizedBox(width: 4),
              Text(l.smartTaskReminderTypeLabel(t.reminderType), style: const TextStyle(fontSize: 11)),
            ],
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'dueDate',
        title: l.smartTasksColDueDate,
        searchValue: (t) => t.dueDate ?? '',
        exportValue: (t) => t.dueDate ?? '-',
        cellBuilder: (ctx, t, idx) => Text(t.dueDate ?? '-', style: const TextStyle(fontSize: 11)),
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'status',
        title: l.smartTasksColStatus,
        searchValue: (t) => t.status,
        exportValue: (t) => t.status,
        cellBuilder: (ctx, t, idx) {
          Color bg;
          switch (t.status) {
            case 'Completed':
              bg = AppTheme.emerald;
              break;
            case 'In Progress':
              bg = AppTheme.cobalt;
              break;
            default:
              bg = Colors.grey.shade600;
          }
          return Chip(
            visualDensity: VisualDensity.compact,
            label: Text(l.smartTaskStatusLabel(t.status), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: bg,
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'actions',
        title: l.smartTasksColActions,
        isSortable: false,
        isSearchable: false,
        isLocked: true,
        cellBuilder: (ctx, t, idx) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (t.status != 'Completed')
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 18),
                  tooltip: l.smartTasksActionCompleteTooltip,
                  onPressed: () {
                    ref.read(smartTasksProvider.notifier).updateTask(t.taskId, {'status': 'Completed'});
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 16),
                tooltip: l.smartTasksActionEditTooltip,
                onPressed: () => SmartTaskDialog.show(context, taskToEdit: t),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                tooltip: l.smartTasksActionDeleteTooltip,
                onPressed: () => ref.read(smartTasksProvider.notifier).deleteTask(t.taskId),
              ),
            ],
          );
        },
      ),
    ];
  }

  void _bulkCompleteTasks() async {
    final pendingSelected = _selectedTasks.where((t) => t.status != 'Completed').toList();
    if (pendingSelected.isEmpty) return;

    for (final t in pendingSelected) {
      await ref.read(smartTasksProvider.notifier).updateTask(t.taskId, {'status': 'Completed'});
    }

    if (mounted) {
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.smartTasksBulkCompleteSuccess(pendingSelected.length)),
          backgroundColor: AppTheme.emerald,
        ),
      );
      setState(() => _selectedTasks.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartTasksProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            const Icon(Icons.task_alt, color: AppTheme.cobalt),
            const SizedBox(width: 10),
            Text(
              l.smartTasksTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
          children: [
            // Top Filters Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => SmartTaskDialog.show(context),
                      icon: const Icon(Icons.add_task),
                      label: Text(l.smartTasksNewTaskBtn),
                    ),
                    const SizedBox(width: 16),

                    // Filter Type
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTaskType,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.smartTasksFilterType, isDense: true, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'All', child: Text(l.smartTasksTypeAll, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'System Generated', child: Text(l.smartTasksTypeSystem, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Manual To-Do', child: Text(l.smartTasksTypeManual, overflow: TextOverflow.ellipsis)),
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
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.smartTasksFilterPriority, isDense: true, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'All', child: Text(l.smartTasksPriorityAll, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Low', child: Text(l.smartTasksPriorityLow, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Medium', child: Text(l.smartTasksPriorityMedium, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'High', child: Text(l.smartTasksPriorityHigh, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Critical', child: Text(l.smartTasksPriorityCritical, overflow: TextOverflow.ellipsis)),
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
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.smartTasksFilterStatus, isDense: true, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'All', child: Text(l.smartTasksStatusAll, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Pending', child: Text(l.smartTasksStatusPending, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'In Progress', child: Text(l.smartTasksStatusInProgress, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Completed', child: Text(l.smartTasksStatusCompleted, overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Cancelled', child: Text(l.smartTasksStatusCancelled, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedStatus = v!);
                          _onFilterChanged();
                        },
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off, color: Colors.grey),
                      tooltip: l.smartTasksResetFiltersTooltip,
                      onPressed: () {
                        setState(() {
                          _selectedTaskType = 'All';
                          _selectedPriority = 'All';
                          _selectedStatus = 'All';
                        });
                        _onFilterChanged();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Unified Enterprise Data Table
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: state.error != null
                    ? Center(
                        child: Text(
                          l.smartTasksFetchError(state.error!),
                          style: const TextStyle(color: AppTheme.crimson),
                        ),
                      )
                    : EnterpriseDataTable<SmartTaskModel>(
                        storageKey: 'smart_tasks_master_table',
                        title: l.smartTasksTableTitle,
                        titleLeading: const Icon(Icons.table_chart, color: AppTheme.cobalt, size: 20),
                        data: state.tasks,
                        columns: _buildColumns(context),
                        isLoading: state.isLoading,
                        enableSelection: true,
                        selectedItems: _selectedTasks,
                        onSelectionChanged: (selected) {
                          setState(() => _selectedTasks = selected);
                        },
                        bulkActions: _selectedTasks.any((t) => t.status != 'Completed')
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onPressed: _bulkCompleteTasks,
                                icon: const Icon(Icons.done_all, size: 16),
                                label: Text(
                                  l.smartTasksBulkCompleteBtn(_selectedTasks.where((t) => t.status != "Completed").length),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                        exportFileName: 'Smart_Tasks_Report_${DateTime.now().millisecondsSinceEpoch}.csv',
                        emptyMessage: l.smartTasksEmptyMessage,
                        emptyIcon: Icons.task_outlined,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
