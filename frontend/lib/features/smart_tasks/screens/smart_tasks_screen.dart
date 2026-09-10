import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/master_data_export_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/enterprise_data_table/enterprise_data_table.dart';
import '../models/smart_task_model.dart';
import '../providers/smart_tasks_provider.dart';
import '../widgets/smart_task_dialog.dart';
import '../widgets/smart_email_listener_dialog.dart';

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

  String _buildSmartTaskRowSummary(SmartTaskModel task) {
    final l = context.l10n;
    final b = StringBuffer();
    b.writeln('📋 ${task.taskCode} — ${task.title}');
    b.writeln('🏷️ ${l.smartTasksColType}: ${task.taskType == "System Generated" ? l.smartTasksTypeSystem : l.smartTasksTypeManual}');
    if (task.description != null && task.description!.isNotEmpty) {
      b.writeln('📝 ${l.smartTaskFieldDescription}: ${task.description}');
    }
    if (task.importFileCode != null) {
      b.writeln('📦 ${l.smartTasksColShipment}: ${task.importFileCode}');
    }
    b.writeln('⚡ ${l.smartTasksColPriority}: ${l.smartTaskPriorityLabel(task.priority)}');
    b.writeln('🔔 ${l.smartTasksColReminder}: ${l.smartTaskReminderTypeLabel(task.reminderType)}');
    if (task.dueDate != null) {
      b.writeln('📅 ${l.smartTasksColDueDate}: ${task.dueDate}');
    }
    b.writeln('🚦 ${l.smartTasksColStatus}: ${l.smartTaskStatusLabel(task.status)}');
    b.writeln('👤 ${l.smartTasksTsvHeaderAssignedUser}: ${task.assignedUser}');
    if (task.notes != null && task.notes!.isNotEmpty) {
      b.writeln('🗒️ ${l.smartTaskFieldNotes}: ${task.notes}');
    }
    return b.toString().trim();
  }

  void _copySmartTasksTsv(List<SmartTaskModel> tasks) {
    final l = context.l10n;
    final buffer = StringBuffer();
    buffer.writeln(
      '${l.smartTasksTsvHeaderCode}\t'
      '${l.smartTasksTsvHeaderType}\t'
      '${l.smartTasksTsvHeaderTitle}\t'
      '${l.smartTasksTsvHeaderShipment}\t'
      '${l.smartTasksTsvHeaderPriority}\t'
      '${l.smartTasksTsvHeaderReminder}\t'
      '${l.smartTasksTsvHeaderDueDate}\t'
      '${l.smartTasksTsvHeaderStatus}\t'
      '${l.smartTasksTsvHeaderAssignedUser}\t'
      '${l.smartTasksTsvHeaderDescription}',
    );

    for (final t in tasks) {
      final isSys = t.taskType == 'System Generated';
      final typeLabel = isSys ? l.smartTasksTypeSystem : l.smartTasksTypeManual;
      final shipment = t.importFileCode ?? l.smartTasksGeneralBadge;
      final priority = l.smartTaskPriorityLabel(t.priority);
      final reminder = l.smartTaskReminderTypeLabel(t.reminderType);
      final status = l.smartTaskStatusLabel(t.status);
      final desc = (t.description ?? '').replaceAll('\t', ' ').replaceAll('\n', ' ');

      buffer.writeln(
        '${t.taskCode}\t'
        '$typeLabel\t'
        '${t.title.replaceAll('\t', ' ')}\t'
        '$shipment\t'
        '$priority\t'
        '$reminder\t'
        '${t.dueDate ?? "-"}\t'
        '$status\t'
        '${t.assignedUser}\t'
        '$desc',
      );
    }

    CopyHelper.copy(
      context,
      buffer.toString().trimRight(),
      customMessage: l.smartTasksExportTsvSuccess,
    );
  }

  Widget _wrapCell({
    required Widget child,
    required String value,
    String? rowSummary,
  }) =>
      CopyableTableCell(
        value: value,
        rowSummary: rowSummary,
        child: child,
      );

  List<EnterpriseColumn<SmartTaskModel>> _buildColumns(BuildContext context) {
    final l = context.l10n;
    return [
      EnterpriseColumn<SmartTaskModel>(
        id: 'code',
        title: l.smartTasksColCode,
        isLocked: true,
        searchValue: (t) => t.taskCode,
        exportValue: (t) => t.taskCode,
        cellBuilder: (ctx, t, idx) {
          final rowSummary = _buildSmartTaskRowSummary(t);
          return _wrapCell(
            value: t.taskCode,
            rowSummary: rowSummary,
            child: InkWell(
              onTap: () => CopyHelper.copy(
                context,
                t.taskCode,
                customMessage: l.smartTaskCodeBadgeLabel,
              ),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded, size: 12, color: AppTheme.cobalt),
                    const SizedBox(width: 4),
                    Text(
                      t.taskCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'type',
        title: l.smartTasksColType,
        searchValue: (t) => t.taskType,
        exportValue: (t) => t.taskType,
        cellBuilder: (ctx, t, idx) {
          final isSys = t.taskType == 'System Generated';
          final typeLabel = isSys ? l.smartTasksTypeSystem : l.smartTasksTypeManual;
          final rowSummary = _buildSmartTaskRowSummary(t);
          return _wrapCell(
            value: typeLabel,
            rowSummary: rowSummary,
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                typeLabel,
                style: TextStyle(fontSize: 10, color: isSys ? Colors.purple.shade900 : Colors.blue.shade900),
              ),
              backgroundColor: isSys ? Colors.purple.shade50 : Colors.blue.shade50,
            ),
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
          final rowSummary = _buildSmartTaskRowSummary(t);
          return _wrapCell(
            value: '${t.title} ${t.description ?? ""}'.trim(),
            rowSummary: rowSummary,
            child: Column(
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
            ),
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'shipment',
        title: l.smartTasksColShipment,
        searchValue: (t) => t.importFileCode ?? '',
        exportValue: (t) => t.importFileCode ?? l.smartTasksGeneralBadge,
        cellBuilder: (ctx, t, idx) {
          final rowSummary = _buildSmartTaskRowSummary(t);
          return _wrapCell(
            value: t.importFileCode ?? l.smartTasksGeneralBadge,
            rowSummary: rowSummary,
            child: t.importFileCode != null
                ? InkWell(
                    onTap: () => CopyHelper.copy(
                      context,
                      t.importFileCode!,
                      customMessage: l.smartTaskImportFileBadgeLabel,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 11, color: AppTheme.cobalt),
                          const SizedBox(width: 4),
                          Text(
                            t.importFileCode!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.cobalt,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    l.smartTasksGeneralBadge,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'priority',
        title: l.smartTasksColPriority,
        sortComparator: (a, b) => _priorityWeight(b.priority).compareTo(_priorityWeight(a.priority)),
        searchValue: (t) => t.priority,
        exportValue: (t) => t.priority,
        cellBuilder: (ctx, t, idx) {
          final rowSummary = _buildSmartTaskRowSummary(t);
          Color bg;
          switch (t.priority.toLowerCase()) {
            case 'critical':
            case 'high':
              bg = Colors.red.shade700;
              break;
            case 'medium':
              bg = Colors.orange.shade800;
              break;
            default:
              bg = Colors.green.shade700;
          }
          final priorityLabel = l.smartTaskPriorityLabel(t.priority);
          return _wrapCell(
            value: priorityLabel,
            rowSummary: rowSummary,
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: Text(priorityLabel, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: bg,
            ),
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'reminder',
        title: l.smartTasksColReminder,
        searchValue: (t) => t.reminderType,
        exportValue: (t) => t.reminderType,
        cellBuilder: (ctx, t, idx) {
          final rowSummary = _buildSmartTaskRowSummary(t);
          final reminderLabel = l.smartTaskReminderTypeLabel(t.reminderType);
          return _wrapCell(
            value: reminderLabel,
            rowSummary: rowSummary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active, size: 14, color: AppTheme.orange),
                const SizedBox(width: 4),
                Text(reminderLabel, style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'dueDate',
        title: l.smartTasksColDueDate,
        searchValue: (t) => t.dueDate ?? '',
        exportValue: (t) => t.dueDate ?? '-',
        cellBuilder: (ctx, t, idx) {
          final rowSummary = _buildSmartTaskRowSummary(t);
          return _wrapCell(
            value: t.dueDate ?? '-',
            rowSummary: rowSummary,
            child: Text(t.dueDate ?? '-', style: const TextStyle(fontSize: 11)),
          );
        },
      ),
      EnterpriseColumn<SmartTaskModel>(
        id: 'status',
        title: l.smartTasksColStatus,
        searchValue: (t) => t.status,
        exportValue: (t) => t.status,
        cellBuilder: (ctx, t, idx) {
          final rowSummary = _buildSmartTaskRowSummary(t);
          Color bg;
          switch (t.status.toLowerCase()) {
            case 'completed':
              bg = AppTheme.emerald;
              break;
            case 'in progress':
              bg = AppTheme.cobalt;
              break;
            default:
              bg = Colors.grey.shade600;
          }
          final statusLabel = l.smartTaskStatusLabel(t.status);
          return _wrapCell(
            value: statusLabel,
            rowSummary: rowSummary,
            child: Chip(
              visualDensity: VisualDensity.compact,
              label: Text(statusLabel, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: bg,
            ),
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
          final rowSummary = _buildSmartTaskRowSummary(t);
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
                icon: const Icon(Icons.copy_rounded, color: AppTheme.charcoal, size: 16),
                tooltip: l.smartTaskCopySummaryBtn,
                onPressed: () {
                  CopyHelper.copy(
                    context,
                    rowSummary,
                    customMessage: l.smartTaskCopySummarySuccess,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined, color: AppTheme.charcoal, size: 16),
                tooltip: l.smartTaskPrintPdfTooltip,
                onPressed: () => MasterDataExportService.printOrSaveSmartTaskPdf(t),
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
      body: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top Filters & Actions Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Action Buttons Row
                      Row(
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
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.charcoal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: () => SmartEmailListenerDialog.show(context),
                            icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                            label: Text(l.smartEmailListenerDialogTitle),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.charcoal,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: () => _copySmartTasksTsv(state.tasks),
                            icon: const Icon(Icons.copy_all, size: 16, color: AppTheme.cobalt),
                            label: Text(l.smartTasksExportTsvBtn),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.charcoal,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: () => MasterDataExportService.exportSmartTasksToExcel(context, state.tasks),
                            icon: const Icon(Icons.table_view, size: 16, color: AppTheme.emerald),
                            label: Text(l.smartTasksExportExcelBtn),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.charcoal,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onPressed: () => MasterDataExportService.printOrSaveSmartTasksListPdf(state.tasks),
                            icon: const Icon(Icons.print, size: 16, color: AppTheme.charcoal),
                            label: Text(l.smartTasksExportPdfBtn),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Filters Row
                      Row(
                        children: [
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
      ),
    );
  }
}
