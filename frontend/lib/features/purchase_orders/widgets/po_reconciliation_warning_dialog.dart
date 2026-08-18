import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../models/purchase_order_model.dart';

class POReconciliationItem {
  final String hsCode;
  final double invoiceQty;
  final double packingQty;
  final double difference; // packingQty - invoiceQty
  final bool isMatched;
  final bool isMissingInPacking;
  final bool isMissingInInvoice;

  POReconciliationItem({
    required this.hsCode,
    required this.invoiceQty,
    required this.packingQty,
    required this.difference,
    required this.isMatched,
    this.isMissingInPacking = false,
    this.isMissingInInvoice = false,
  });
}

class POReconciliationReport {
  final bool hasDiscrepancy;
  final double totalInvoiceQty;
  final double totalPackingQty;
  final double totalDifference;
  final List<POReconciliationItem> items;
  final List<String> discrepancySummaryList;

  POReconciliationReport({
    required this.hasDiscrepancy,
    required this.totalInvoiceQty,
    required this.totalPackingQty,
    required this.totalDifference,
    required this.items,
    required this.discrepancySummaryList,
  });
}

POReconciliationReport evaluatePOReconciliation({
  required List<POLineItemModel> invoiceItems,
  required List<PackingListItemModel> packingItems,
  required List<CustomsTariffModel> tariffs,
}) {
  if (packingItems.isEmpty) {
    return POReconciliationReport(
      hasDiscrepancy: false,
      totalInvoiceQty: invoiceItems.fold(0.0, (s, i) => s + i.quantity),
      totalPackingQty: 0.0,
      totalDifference: 0.0,
      items: [],
      discrepancySummaryList: [],
    );
  }

  final Map<String, double> invoiceHsMap = {};
  double totalInv = 0.0;
  for (final item in invoiceItems) {
    totalInv += item.quantity;
    String hs = 'بدون بند جمركي (Unassigned)';
    if (item.tariffId != null) {
      final match = tariffs.cast<CustomsTariffModel?>().firstWhere(
        (t) => t?.tariffId == item.tariffId,
        orElse: () => null,
      );
      if (match != null && match.hsCode.isNotEmpty) {
        hs = match.hsCode;
      }
    } else if (item.hsCode != null && item.hsCode!.isNotEmpty) {
      hs = item.hsCode!;
    }
    invoiceHsMap[hs] = (invoiceHsMap[hs] ?? 0.0) + item.quantity;
  }

  final Map<String, double> packingHsMap = {};
  double totalPkg = 0.0;
  for (final p in packingItems) {
    totalPkg += p.qtyPcs;
    final hs = p.hsCode.isNotEmpty ? p.hsCode : 'بدون بند جمركي (Unassigned)';
    packingHsMap[hs] = (packingHsMap[hs] ?? 0.0) + p.qtyPcs;
  }

  final Set<String> allHs = {...invoiceHsMap.keys, ...packingHsMap.keys};
  final List<POReconciliationItem> items = [];
  final List<String> warnings = [];
  bool hasDiscrepancy = false;

  for (final hs in allHs) {
    final invQty = invoiceHsMap[hs] ?? 0.0;
    final pkgQty = packingHsMap[hs] ?? 0.0;
    final diff = pkgQty - invQty;
    final matched = (diff.abs() < 0.001);

    final isMissingInPkg = (invQty > 0 && pkgQty == 0);
    final isMissingInInv = (pkgQty > 0 && invQty == 0);

    if (isMissingInPkg) {
      hasDiscrepancy = true;
      warnings.add('البند الجمركي $hs موجود بالفاتورة (كمية: $invQty) وغير موجود ببيان التعبئة');
    } else if (isMissingInInv) {
      hasDiscrepancy = true;
      warnings.add('البند الجمركي $hs موجود ببيان التعبئة (كمية: $pkgQty) وغير موجود بالفاتورة');
    } else if (!matched) {
      hasDiscrepancy = true;
      warnings.add('البند الجمركي $hs: كمية الفاتورة ($invQty) تختلف عن كمية الباكينج ($pkgQty) بفارق ($diff)');
    }

    items.add(
      POReconciliationItem(
        hsCode: hs,
        invoiceQty: invQty,
        packingQty: pkgQty,
        difference: diff,
        isMatched: matched,
        isMissingInPacking: isMissingInPkg,
        isMissingInInvoice: isMissingInInv,
      ),
    );
  }

  final totalDiff = totalPkg - totalInv;
  if (totalDiff.abs() > 0.001) {
    hasDiscrepancy = true;
    warnings.add('إجمالي عدد القطع: الفاتورة ($totalInv) والباكينج ($totalPkg) بفارق ($totalDiff)');
  }

  return POReconciliationReport(
    hasDiscrepancy: hasDiscrepancy,
    totalInvoiceQty: totalInv,
    totalPackingQty: totalPkg,
    totalDifference: totalDiff,
    items: items,
    discrepancySummaryList: warnings,
  );
}

class POReconciliationWarningDialog extends StatefulWidget {
  final POReconciliationReport report;

  const POReconciliationWarningDialog({super.key, required this.report});

  @override
  State<POReconciliationWarningDialog> createState() => _POReconciliationWarningDialogState();
}

class _POReconciliationWarningDialogState extends State<POReconciliationWarningDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تنبيه: عدم تطابق بين الفاتورة المبدئية وبيان التعبئة',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Packing List & Commercial Invoice Discrepancy Alert',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 750,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text('إجمالي قطع الفاتورة', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${report.totalInvoiceQty.toStringAsFixed(1)} PCS', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text('إجمالي قطع الباكينج', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${report.totalPackingQty.toStringAsFixed(1)} PCS', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: report.totalDifference != 0 ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: report.totalDifference != 0 ? Colors.red.shade300 : Colors.green.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text('فارق الكمية الكلي', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '${report.totalDifference > 0 ? "+" : ""}${report.totalDifference.toStringAsFixed(1)} PCS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: report.totalDifference != 0 ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'جدول المقارنة التفصيلي حسب البند الجمركي (HS Code Breakdown):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 8),

              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(2.0),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppTheme.cloudWhite),
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('البند الجمركي (HS Code)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الفاتورة (Qty)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الباكينج (Qty)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الفارق (Diff)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الحالة (Status)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  ...report.items.map((item) {
                    Color rowBg = Colors.white;
                    Color statusColor = Colors.green;
                    String statusText = 'متطابق (Matched)';

                    if (item.isMissingInPacking) {
                      rowBg = Colors.red.shade50.withOpacity(0.5);
                      statusColor = Colors.red.shade700;
                      statusText = 'غير موجود بالباكينج';
                    } else if (item.isMissingInInvoice) {
                      rowBg = Colors.amber.shade50.withOpacity(0.5);
                      statusColor = Colors.amber.shade900;
                      statusText = 'غير موجود بالفاتورة';
                    } else if (!item.isMatched) {
                      rowBg = Colors.orange.shade50.withOpacity(0.5);
                      statusColor = Colors.deepOrange;
                      statusText = 'اختلاف بالكمية';
                    }

                    return TableRow(
                      decoration: BoxDecoration(color: rowBg),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item.hsCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${item.invoiceQty}', style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${item.packingQty}', style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${item.difference > 0 ? "+" : ""}${item.difference}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.difference != 0 ? Colors.red.shade700 : Colors.green,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Discrepancy Bullet points
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.brown, size: 16),
                        SizedBox(width: 6),
                        Text('أسباب عدم التطابق المرصودة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...report.discrepancySummaryList.map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(top: 2, left: 16),
                        child: Text('• $msg', style: const TextStyle(fontSize: 11, color: Colors.brown)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mandatory Justification Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'لإتمام الحفظ، يجب توضيح سبب الاستمرار وتبرير الفروقات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'سبب الاستمرار وتبرير الاختلاف (Discrepancy Justification Reason) *',
                        hintText: 'مثال: كل قطعة بالفاتورة تتكون من كرتونتين مكملتين في بيان التعبئة، أو شحنة مجزأة...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber.shade800, width: 2)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يجب إدخال سبب وتبرير استمرار الحفظ رغم وجود الاختلاف.';
                        }
                        if (val.trim().length < 5) {
                          return 'الرجاء إدخال تبرير واضح ومفصل (5 أحرف على الأقل).';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('الرجوع للتعديل (Back to Edit)'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context, null),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('الاستمرار وحفظ أمر الشراء (Continue & Save)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _reasonCtrl.text.trim());
            }
          },
        ),
      ],
    );
  }
}
