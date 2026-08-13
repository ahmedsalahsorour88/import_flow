import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/import_file_model.dart';

class ShipmentMilestoneTracker extends StatelessWidget {
  final ImportFileModel importFile;

  const ShipmentMilestoneTracker({
    super.key,
    required this.importFile,
  });

  static const List<Map<String, dynamic>> _allPhases = [
    {'code': 'Phase 1', 'num': 1, 'name': 'الجدوى والنولون', 'icon': Icons.architecture},
    {'code': 'Phase 2', 'num': 2, 'name': 'الموافقة المالية', 'icon': Icons.attach_money},
    {'code': 'Phase 3', 'num': 3, 'name': 'المستندات و ACID', 'icon': Icons.description},
    {'code': 'Phase 4', 'num': 4, 'name': 'حجز الشحنة', 'icon': Icons.directions_boat},
    {'code': 'Phase 5', 'num': 5, 'name': 'الشحن و CargoX', 'icon': Icons.local_shipping},
    {'code': 'Phase 6', 'num': 6, 'name': 'إقرار 46 جمرك', 'icon': Icons.assignment},
    {'code': 'Phase 7', 'num': 7, 'name': 'التخليص والسداد', 'icon': Icons.gavel},
    {'code': 'Phase 8', 'num': 8, 'name': 'استلام المخازن', 'icon': Icons.store},
    {'code': 'Phase 9', 'num': 9, 'name': 'التسوية الشاملة', 'icon': Icons.account_balance_wallet},
    {'code': 'Phase 10', 'num': 10, 'name': 'إغلاق والأرشفة', 'icon': Icons.archive},
  ];

  int _getCurrentPhaseIndex() {
    final curr = importFile.currentModule;
    for (int i = 0; i < _allPhases.length; i++) {
      if (curr.contains(_allPhases[i]['code'] as String)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getCurrentPhaseIndex();
    final isClosed = importFile.status == 'Closed';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.timeline, color: AppTheme.cobalt, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مخطط تتبع التقدم التشغيلي للشحنة: ${importFile.customFileNumber ?? importFile.importFileCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                    ),
                    Text(
                      'الشركة المستوردة: ${importFile.companyName} | المورد: ${importFile.supplierName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isClosed ? Colors.grey.shade200 : AppTheme.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isClosed ? Colors.grey : AppTheme.emerald),
                  ),
                  child: Text(
                    isClosed ? 'مغلقة ومؤرشفة' : 'نسبة الإنجاز: ${importFile.progressPercent.toInt()}%',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isClosed ? Colors.grey.shade700 : AppTheme.emerald),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stepper / Horizontal Progress Line
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_allPhases.length, (idx) {
                  final phase = _allPhases[idx];
                  final isDone = idx < activeIndex || isClosed;
                  final isCurrent = idx == activeIndex && !isClosed;

                  Color circleColor = Colors.grey.shade300;
                  Color iconColor = Colors.grey.shade600;
                  if (isDone) {
                    circleColor = AppTheme.emerald;
                    iconColor = Colors.white;
                  } else if (isCurrent) {
                    circleColor = AppTheme.cobalt;
                    iconColor = Colors.white;
                  }

                  return Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                              boxShadow: isCurrent ? [BoxShadow(color: AppTheme.cobalt.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : null,
                            ),
                            child: Icon(
                              isDone ? Icons.check : (phase['icon'] as IconData),
                              color: iconColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'P${phase['num']}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? AppTheme.cobalt : (isDone ? AppTheme.emerald : Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 70,
                            child: Text(
                              phase['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? AppTheme.charcoal : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (idx < _allPhases.length - 1)
                        Container(
                          width: 40,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: isDone ? AppTheme.emerald : Colors.grey.shade300,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
