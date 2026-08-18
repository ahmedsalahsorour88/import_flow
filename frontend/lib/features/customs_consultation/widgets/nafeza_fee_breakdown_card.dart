import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../services/customs_export_service.dart';
import 'package:printing/printing.dart';
import '../services/customs_consultation_pdf_service.dart';
import '../screens/customs_consultation_screen.dart';

class NafezaFeeBreakdownCard extends StatelessWidget {
  final List<CustomsItemCalcRow> calcLines;
  final double totalDutyEgp;
  final double totalVatEgp;
  final double totalServiceFeeEgp;
  final double totalScheduleTaxEgp;
  final double totalFreightEgp;
  final double totalInsuranceEgp;
  final double exchangeRate;
  
  // State variables passed in
  final int? editingConsultationId;
  final String? editingConsultationCode;
  final int? selectedBrokerId;
  final String selectedBrokerName;
  final String title;
  final List<CustomsChecklistItemModel> checklist;
  final List<CustomsBrokerQuoteItemModel> brokerQuoteItems;
  final int? selectedImportFileId;
  final String customsCurrency;

  const NafezaFeeBreakdownCard({
    super.key,
    required this.calcLines,
    required this.totalDutyEgp,
    required this.totalVatEgp,
    required this.totalServiceFeeEgp,
    required this.totalScheduleTaxEgp,
    required this.totalFreightEgp,
    required this.totalInsuranceEgp,
    required this.exchangeRate,
    this.editingConsultationId,
    this.editingConsultationCode,
    this.selectedBrokerId,
    required this.selectedBrokerName,
    required this.title,
    required this.checklist,
    required this.brokerQuoteItems,
    this.selectedImportFileId,
    required this.customsCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final nafezaResult = CustomsExportService.computeNafezaFeeBreakdown(
      totalDutyEgp: totalDutyEgp,
      totalVatEgp: totalVatEgp,
      totalServiceFeeEgp: totalServiceFeeEgp,
      totalScheduleTaxEgp: totalScheduleTaxEgp,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cobalt.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar matching Image 2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: AppTheme.cobalt.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.cobalt, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'تفاصيل بنود التحصيل والإقرارات الرسمية (Nafeza Statement Fee Breakdown)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                  ),
                ),
                Text(
                  '${nafezaResult.grandTotal.toStringAsFixed(2)} EGP إجمالي البيان:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                ),
                const SizedBox(width: 12),
                // PDF Export Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () async {
                    final session = CustomsConsultationModel(
                      consultationId: editingConsultationId ?? 0,
                      consultationCode: editingConsultationCode ?? 'DRAFT-STMT',
                      brokerId: selectedBrokerId ?? 0,
                      brokerName: selectedBrokerName.isNotEmpty ? selectedBrokerName : 'مستخلص جمركي معتمد',
                      title: title.isNotEmpty ? title : 'دراسة استشارة جمركية',
                      overallStatus: 'Pending Review',
                      estimatedDutiesEgp: nafezaResult.grandTotal,
                      totalBrokerFeesEgp: brokerQuoteItems.fold(0.0, (s, i) => s + (i.isApplicable ? i.totalAmount : 0.0)),
                      checklistItems: checklist,
                      brokerQuoteItems: brokerQuoteItems,
                      createdAt: DateTime.now().toIso8601String(),
                      updatedAt: DateTime.now().toIso8601String(),
                    );
                    await Printing.layoutPdf(
                      onLayout: (format) => CustomsConsultationPdfService.generateConsultationPdf(session),
                      name: 'Nafeza_Statement_${DateTime.now().millisecondsSinceEpoch}',
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                  label: const Text('📄 حفظ PDF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                // Excel Export Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () async {
                    try {
                      final savedFile = await CustomsExportService.exportCustomsStudyToExcel(
                        context: context,
                        title: title.isNotEmpty ? title : 'دراسة استشارة جمركية',
                        importFileCode: selectedImportFileId != null ? 'IMP-$selectedImportFileId' : null,
                        brokerName: selectedBrokerName.isNotEmpty ? selectedBrokerName : 'غير محدد',
                        currency: customsCurrency,
                        exchangeRate: exchangeRate,
                        totalFreightEgp: totalFreightEgp,
                        totalInsuranceEgp: totalInsuranceEgp,
                        calcLines: calcLines,
                        nafezaResult: nafezaResult,
                        brokerQuoteItems: brokerQuoteItems,
                      );
                      if (savedFile != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ تم تصدير وحفظ شيت الإكسيل بنجاح: $savedFile'), backgroundColor: AppTheme.emerald),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ خطأ أثناء التصدير: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.table_chart, color: Colors.white, size: 14),
                  label: const Text('📊 تصدير EXCEL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Grouped Fee Items Matching Image 2
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: nafezaResult.groups.map((group) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Group Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تحصيل ${group.groupName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                            ),
                            Text(
                              '${group.totalAmount.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                            ),
                          ],
                        ),
                      ),
                      // Items inside group
                      ...group.items.map((item) {
                        final typeLabel = item.calculationType == 'flat'
                            ? 'قطعي'
                            : (item.calculationType == 'reference' ? 'مرجعي' : 'مشتق');
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              // Code Badge
                              Container(
                                width: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  '[${item.code}]',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Item Name
                              Expanded(
                                child: Text(
                                  item.nameAr,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Calculation Type
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.calculationType == 'flat' ? Colors.blue.shade50 : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: item.calculationType == 'flat' ? Colors.blue.shade800 : Colors.teal.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Amount
                              SizedBox(
                                width: 110,
                                child: Text(
                                  '${item.calculatedAmount.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
