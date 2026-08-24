import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/customs_consultation_model.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';

class PostSaveStatusDialog extends StatelessWidget {
  final CustomsConsultationModel saved;

  const PostSaveStatusDialog({super.key, required this.saved});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final approved =
        saved.checklistItems.where((i) => i.status == 'Approved').toList();
    final pending =
        saved.checklistItems.where((i) => i.status == 'Pending').toList();
    final blocking = saved.checklistItems
        .where((i) => i.isBlockingShipment && i.status != 'Approved')
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            blocking.isNotEmpty
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            color: blocking.isNotEmpty ? Colors.orange : AppTheme.emerald,
            size: 26,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.customsDutyReviewTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  saved.consultationCode,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.cobalt,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Metrics
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ConsultationMetricBadge(
                      title: l.clearanceReadyStatus, value: '${approved.length}', color: Colors.green),
                  ConsultationMetricBadge(
                      title: l.statusPending,
                      value: '${pending.length}',
                      color: Colors.orange),
                  ConsultationMetricBadge(
                      title: l.openBlockingIssues,
                      value: '${blocking.length}',
                      color: blocking.isNotEmpty ? Colors.red : Colors.green),
                  ConsultationMetricBadge(
                      title: l.avgReadinessMetric,
                      value: '${saved.readinessPercentage.toStringAsFixed(0)}%',
                      color: Colors.blue),
                ],
              ),
              const SizedBox(height: 16),

              if (blocking.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.blockingIssuesTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ...blocking.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.block,
                                  color: Colors.red, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.documentType,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                    ),
                                    if (item.hsCode != null &&
                                        item.hsCode!.isNotEmpty)
                                      Text(
                                        item.hsCode!,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.cobalt),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConsultationDocStatusBadge(status: item.status),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (pending.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.statusPending,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      ...pending.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty,
                                  color: Colors.orange.shade700, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.documentType,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                    ),
                                    if (item.hsCode != null &&
                                        item.hsCode!.isNotEmpty)
                                      Text(
                                        item.hsCode!,
                                        style: const TextStyle(
                                            fontSize: 10, color: AppTheme.cobalt),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConsultationDocStatusBadge(status: item.status),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (blocking.isEmpty && pending.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.green, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.clearanceReadyStatus,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          label: Text(l.close),
        ),
      ],
    );
  }
}

