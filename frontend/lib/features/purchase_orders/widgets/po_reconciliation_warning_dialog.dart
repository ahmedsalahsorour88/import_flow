import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
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
    String hs = 'UNASSIGNED';
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
    final hs = p.hsCode.isNotEmpty ? p.hsCode : 'UNASSIGNED';
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
    final l = context.l10n;
    final report = widget.report;

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.discrepancyWarningTitle,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
                          Text('${l.poLineItemsTab} (${l.quantityMetric})', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                          Text('${l.reviewPackingListTab} (${l.quantityMetric})', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                          Text(l.poRecDiff, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
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

              Text(
                l.summaryByHsCodeReport,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
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
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.cloudWhite),
                    children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(l.hsCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(l.poLineItemsTab, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(l.reviewPackingListTab, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(l.poRecDiff, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(l.status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  ...report.items.map((item) {
                    Color rowBg = Colors.white;
                    Color statusColor = Colors.green;
                    String statusText = l.poRecOk;

                    if (item.isMissingInPacking) {
                      rowBg = Colors.red.shade50.withOpacity(0.5);
                      statusColor = Colors.red.shade700;
                      statusText = l.poRecMissingInPacking;
                    } else if (item.isMissingInInvoice) {
                      rowBg = Colors.amber.shade50.withOpacity(0.5);
                      statusColor = Colors.amber.shade900;
                      statusText = l.poRecMissingInInvoice;
                    } else if (!item.isMatched) {
                      rowBg = Colors.orange.shade50.withOpacity(0.5);
                      statusColor = Colors.deepOrange;
                      statusText = l.poRecQtyDiff;
                    }

                    final displayHs = item.hsCode == 'UNASSIGNED' ? l.poRecUnassignedHsCode : item.hsCode;

                    return TableRow(
                      decoration: BoxDecoration(color: rowBg),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            displayHs,
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

              // Mandatory Justification Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.discrepancyJustificationLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '${l.discrepancyJustificationLabel} *',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber.shade800, width: 2)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l.requiredField;
                        }
                        if (val.trim().length < 5) {
                          return l.requiredField;
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
          label: Text(l.backToEdit),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context, null),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: Text(l.continueAndSave),
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

