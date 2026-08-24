import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../models/audit_log_model.dart';
import '../providers/audit_logs_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedEntityType = 'All';
  String _selectedAction = 'All';

  final List<String> _entityTypes = [
    'All',
    'ImportCompany',
    'Supplier',
    'ExternalServiceProvider',
    'User',
  ];

  final List<String> _actions = [
    'All',
    'CREATE',
    'UPDATE',
    'DELETE',
    'RESTORE',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(systemAuditLogsProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logsAsync = ref.watch(systemAuditLogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header & Refresh Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.auditLogsScreenTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.auditLogsScreenSubtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.liveRefreshBtn),
                      onPressed: () => ref.invalidate(systemAuditLogsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Entity Type Filter Chips
            Row(
              children: [
                Text(l10n.filterEntityLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _entityTypes.map((type) {
                        final isSelected = _selectedEntityType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              l10n.auditEntityLabel(type),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.charcoal,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.cobalt,
                            backgroundColor: Colors.white,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedEntityType = type;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Filter Chips
            Row(
              children: [
                Text(l10n.filterActionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _actions.map((act) {
                        final isSelected = _selectedAction == act;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              l10n.auditActionLabel(act),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.charcoal,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: _getActionColor(act),
                            backgroundColor: Colors.white,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedAction = act;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Input Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.charcoal),
                  hintText: l10n.searchAuditLogsHint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.cobalt, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Data Table Content
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Text(l10n.auditLogsFetchError(err.toString()), style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (logs) {
                  final filtered = logs.where((log) {
                    final matchesEntity = _selectedEntityType == 'All' || log.entityType == _selectedEntityType;
                    final matchesAction = _selectedAction == 'All' || log.action.toUpperCase() == _selectedAction.toUpperCase();
                    final matchesSearch = _searchQuery.isEmpty ||
                        (log.entityCode ?? '').toLowerCase().contains(_searchQuery) ||
                        log.performedBy.toLowerCase().contains(_searchQuery) ||
                        (log.changesSummary ?? '').toLowerCase().contains(_searchQuery);

                    return matchesEntity && matchesAction && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(l10n.noAuditLogsFound, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = filtered[index];
                        return _buildAuditLogCard(log);
                      },
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

  Widget _buildAuditLogCard(AuditLogModel log) {
    final l10n = context.l10n;
    final actionColor = _getActionColor(log.action);
    final formattedDate = log.performedAt.toLocal().toString().split('.').first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Icon Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getActionIcon(log.action), color: actionColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Log Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Action Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.auditActionLabel(log.action),
                        style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Entity Type & Code
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.auditEntityWithCode(
                          l10n.auditEntityLabel(log.entityType),
                          log.entityCode ?? log.entityId.toString(),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                      ),
                    ),
                    const Spacer(),

                    // Timestamp
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Changes Summary
                Text(
                  log.changesSummary ?? l10n.systemMutationFallback,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 4),

                // User Info
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(l10n.performedByUser(log.performedBy), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return AppTheme.emerald;
      case 'UPDATE':
        return AppTheme.cobalt;
      case 'DELETE':
        return AppTheme.crimson;
      case 'RESTORE':
        return AppTheme.orange;
      default:
        return AppTheme.charcoal;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit_note;
      case 'DELETE':
        return Icons.remove_circle;
      case 'RESTORE':
        return Icons.settings_backup_restore;
      default:
        return Icons.history;
    }
  }
}
