import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/audit_log_model.dart';
import '../providers/audit_logs_provider.dart';

class RowHistoryDialog extends ConsumerStatefulWidget {
  final String entityType;
  final int entityId;
  final String entityTitle;

  const RowHistoryDialog({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
  });

  static void show(BuildContext context, {required String entityType, required int entityId, required String entityTitle}) {
    showDialog(
      context: context,
      builder: (ctx) => RowHistoryDialog(
        entityType: entityType,
        entityId: entityId,
        entityTitle: entityTitle,
      ),
    );
  }

  @override
  ConsumerState<RowHistoryDialog> createState() => _RowHistoryDialogState();
}

class _RowHistoryDialogState extends ConsumerState<RowHistoryDialog> {
  @override
  void initState() {
    super.initState();
    // Force instant live refetch from API when dialog opens!
    Future.microtask(() {
      ref.invalidate(entityAuditTimelineProvider((entityType: widget.entityType, entityId: widget.entityId)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(entityAuditTimelineProvider((entityType: widget.entityType, entityId: widget.entityId)));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Banner Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Log & Audit History',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.entityType}: ${widget.entityTitle}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh Live History',
                    onPressed: () {
                      ref.invalidate(entityAuditTimelineProvider((entityType: widget.entityType, entityId: widget.entityId)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Timeline Body
            Expanded(
              child: timelineAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.cobalt),
                      SizedBox(height: 12),
                      Text('Fetching live audit logs from API...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text('Error loading history logs: $err', style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(
                      child: Text('No change history recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildTimelineItem(log, isLatest: index == 0);
                    },
                  );
                },
              ),
            ),

            // Bottom Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(AuditLogModel log, {required bool isLatest}) {
    Color actionColor;
    IconData actionIcon;

    switch (log.action.toUpperCase()) {
      case 'CREATE':
        actionColor = AppTheme.emerald;
        actionIcon = Icons.add_circle;
        break;
      case 'UPDATE':
        actionColor = AppTheme.cobalt;
        actionIcon = Icons.edit_note;
        break;
      case 'DELETE':
        actionColor = AppTheme.crimson;
        actionIcon = Icons.remove_circle;
        break;
      case 'RESTORE':
        actionColor = AppTheme.orange;
        actionIcon = Icons.settings_backup_restore;
        break;
      default:
        actionColor = AppTheme.charcoal;
        actionIcon = Icons.info;
    }

    final formattedDate = log.performedAt.toLocal().toString().split('.').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLatest ? actionColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLatest ? actionColor.withOpacity(0.3) : Colors.grey.shade200,
          width: isLatest ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(actionIcon, color: actionColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.action.toUpperCase(),
                        style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  log.changesSummary ?? 'No description',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  'By: ${log.performedBy}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
