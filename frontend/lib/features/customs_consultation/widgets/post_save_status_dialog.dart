import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';

class PostSaveStatusDialog extends StatelessWidget {
  final CustomsConsultationModel saved;

  const PostSaveStatusDialog({super.key, required this.saved});

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'تقرير حالة مستندات الاستشارة الجمركية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      title: '✅ معتمدة', value: '${approved.length} مستند', color: Colors.green),
                  ConsultationMetricBadge(
                      title: '⏳ قيد الانتظار',
                      value: '${pending.length} مستند',
                      color: Colors.orange),
                  ConsultationMetricBadge(
                      title: '🚫 عوائق التخليص',
                      value: '${blocking.length} بند',
                      color: blocking.isNotEmpty ? Colors.red : Colors.green),
                  ConsultationMetricBadge(
                      title: '📊 نسبة الجاهزية',
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
                      const Text(
                        '🚫 المستندات العائقة للتخليص الجمركي (Blocking Issues):',
                        style: TextStyle(
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
                                        'بنود: ${item.hsCode}',
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
                      const Text(
                        '⏳ المستندات قيد الانتظار:',
                        style: TextStyle(
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
                                        'بنود: ${item.hsCode}',
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
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Colors.green, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎉 الشحنة جاهزة للتخليص الجمركي!',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14),
                            ),
                            Text(
                              'جميع المستندات معتمدة ولا توجد عوائق للتخليص.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green),
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
          label: const Text('إغلاق والعودة لسجل الدراسات'),
        ),
      ],
    );
  }
}
