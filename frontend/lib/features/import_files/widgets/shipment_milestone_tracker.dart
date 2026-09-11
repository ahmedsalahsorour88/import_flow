import 'package:flutter/material.dart';
import '../../../core/services/display_name_resolver.dart';
import '../../../core/theme/app_theme.dart';
import '../models/import_file_model.dart';

class ShipmentMilestoneTracker extends StatelessWidget {
  final ImportFileModel importFile;

  const ShipmentMilestoneTracker({
    super.key,
    required this.importFile,
  });

  static const List<Map<String, dynamic>> _allPhases = [
    {'code': 'Phase 1', 'num': 1, 'name_ar': 'الجدوى والنولون', 'name_en': 'Feasibility & Freight', 'icon': Icons.architecture},
    {'code': 'Phase 2', 'num': 2, 'name_ar': 'الموافقة المالية', 'name_en': 'Financial Approval', 'icon': Icons.attach_money},
    {'code': 'Phase 3', 'num': 3, 'name_ar': 'المستندات و ACID', 'name_en': 'Docs & ACID', 'icon': Icons.description},
    {'code': 'Phase 4', 'num': 4, 'name_ar': 'حجز الشحنة', 'name_en': 'Shipment Booking', 'icon': Icons.directions_boat},
    {'code': 'Phase 5', 'num': 5, 'name_ar': 'الشحن و CargoX', 'name_en': 'CargoX & Shipping', 'icon': Icons.local_shipping},
    {'code': 'Phase 6', 'num': 6, 'name_ar': 'إقرار 46 جمرك', 'name_en': 'Customs Form 46', 'icon': Icons.assignment},
    {'code': 'Phase 7', 'num': 7, 'name_ar': 'التخليص والسداد', 'name_en': 'Clearance & Duties', 'icon': Icons.gavel},
    {'code': 'Phase 8', 'num': 8, 'name_ar': 'استلام المخازن', 'name_en': 'Warehouse GRN', 'icon': Icons.store},
    {'code': 'Phase 9', 'num': 9, 'name_ar': 'التسوية الشاملة', 'name_en': 'Landed Cost', 'icon': Icons.account_balance_wallet},
    {'code': 'Phase 10', 'num': 10, 'name_ar': 'إغلاق والأرشفة', 'name_en': 'Archive & Close', 'icon': Icons.archive},
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final activeIndex = _getCurrentPhaseIndex();
    final isClosed = importFile.status == 'Closed';
    final shipmentTitle = DisplayNameResolver.resolveShipmentTitle(importFile, isArabic: isArabic);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'مخطط تتبع التقدم التشغيلي للشحنة: $shipmentTitle'
                            : 'Operational Progress Milestone: $shipmentTitle',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isArabic
                            ? 'الشركة المستوردة: ${importFile.companyName} | المورد: ${importFile.supplierName}'
                            : 'Importing Company: ${importFile.companyName} | Supplier: ${importFile.supplierName}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isClosed ? Colors.grey.shade200 : AppTheme.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isClosed ? Colors.grey : AppTheme.emerald),
                  ),
                  child: Text(
                    isClosed
                        ? (isArabic ? 'مغلقة ومؤرشفة' : 'Closed & Archived')
                        : (isArabic ? 'نسبة الإنجاز: ${importFile.progressPercent.toInt()}%' : 'Progress: ${importFile.progressPercent.toInt()}%'),
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
                  final phaseName = isArabic ? (phase['name_ar'] as String) : (phase['name_en'] as String);

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
                            isArabic ? 'م${phase['num']}' : 'P${phase['num']}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? AppTheme.cobalt : (isDone ? AppTheme.emerald : Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 78,
                            child: Text(
                              phaseName,
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
