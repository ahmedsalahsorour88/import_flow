import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';

  void showConsultationDetailsDialog(CustomsConsultationModel session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تفاصيل الاستشارة الجمركية: ${session.consultationCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildStatusBadge(session.overallStatus),
            ],
          ),
          content: SizedBox(
            width: 750,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العنوان: ${session.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('المستخلص الجمركي: ${session.brokerName} ${session.brokerContactPerson != null ? "(${session.brokerContactPerson})" : ""}'),
                        const SizedBox(height: 6),
                        Text('الرسوم الجمركية والضرائب التقديرية: ${session.estimatedDutiesEgp.toStringAsFixed(2)} EGP'),
                        if (session.notes != null && session.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('ملاحظات: ${session.notes}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricBadge('نسبة الجاهزية الجمركية', '${session.readinessPercentage}%', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMetricBadge('إجمالي المستندات', '${session.totalDocumentsCount}', Colors.grey),
                      const SizedBox(width: 8),
                      _buildMetricBadge('المستندات المعتمدة', '${session.approvedDocumentsCount}', Colors.green),
                      const SizedBox(width: 8),
                      _buildMetricBadge('عوائق شحن (Blocking)', '${session.blockingIssuesCount}', session.blockingIssuesCount > 0 ? Colors.red : Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (session.brokerQuoteItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('💰 تفاصيل عرض أسعار التخليص الجمركي والنقل للمستخلص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('إجمالي مصاريف المخلص: ${session.totalBrokerFeesEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(2.8),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(0.8),
                        4: FlexColumnWidth(1.4),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.08)),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('نوع المصروف / الخدمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('سعر البند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...session.brokerQuoteItems.where((q) => q.isApplicable).map((quote) {
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text(quote.expenseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(quote.category.split('(').first.trim(), style: const TextStyle(fontSize: 10))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${quote.unitPrice.toStringAsFixed(2)} ${quote.currency}', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${quote.qty}', style: const TextStyle(fontSize: 11))),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text('${quote.totalAmount.toStringAsFixed(2)} ${quote.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],

                  const Text('قائمة فحص المستندات والاشتراطات الجمركية (Checklist):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8), child: Text('نوع المستند', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('الجهة المسؤولة', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...session.checklistItems.map((doc) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  if (doc.isBlockingShipment) const Icon(Icons.block, color: Colors.red, size: 14),
                                  if (doc.isBlockingShipment) const SizedBox(width: 4),
                                  Expanded(child: Text(doc.documentType, style: const TextStyle(fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(8), child: Text(doc.responsibleParty)),
                            Padding(padding: const EdgeInsets.all(8), child: _buildDocItemStatusBadge(doc.status)),
                            Padding(padding: const EdgeInsets.all(8), child: Text(doc.remarks ?? '-')),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal),
              onPressed: () async {
                await Printing.layoutPdf(
                  onLayout: (format) => CustomsConsultationPdfService.generateConsultationPdf(session),
                  name: 'Customs_Consultation_${session.consultationCode}',
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
              label: const Text('📄 طباعة / حفظ PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              onPressed: () async {
                final nafezaRes = CustomsExportService.computeNafezaFeeBreakdown(
                  totalDutyEgp: session.estimatedDutiesEgp * 0.45,
                  totalVatEgp: session.estimatedDutiesEgp * 0.45,
                  totalServiceFeeEgp: session.estimatedDutiesEgp * 0.10,
                  totalScheduleTaxEgp: 0.0,
                );
                try {
                  final saved = await CustomsExportService.exportCustomsStudyToExcel(
                    context: context,
                    title: session.title,
                    importFileCode: session.importFileCode,
                    brokerName: session.brokerName,
                    currency: 'EGP',
                    exchangeRate: 1.0,
                    totalFreightEgp: 0.0,
                    totalInsuranceEgp: 0.0,
                    calcLines: [],
                    nafezaResult: nafezaRes,
                    brokerQuoteItems: session.brokerQuoteItems,
                  );
                  if (saved != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ تم تصدير دراسة الاستشارة بنجاح: $saved'), backgroundColor: AppTheme.emerald),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.table_chart, color: Colors.white, size: 14),
              label: const Text('📊 تصدير EXCEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
