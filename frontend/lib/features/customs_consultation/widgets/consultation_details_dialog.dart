import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/customs_consultation_model.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';
import 'package:printing/printing.dart';
import '../services/customs_consultation_pdf_service.dart';
import '../services/customs_export_service.dart';
void showConsultationDetailsDialog(BuildContext context, CustomsConsultationModel session) {
  showDialog(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${l.consultationDetailsTitle}: ${session.consultationCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ConsultationStatusBadge(status: session.overallStatus),
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
                        Text('${l.titleField}: ${session.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('${l.customsBrokerLabel}: ${session.brokerName} ${session.brokerContactPerson != null ? "(${session.brokerContactPerson})" : ""}'),
                        const SizedBox(height: 6),
                        Text('${l.totalTaxesAndDutiesCol}: ${session.estimatedDutiesEgp.toStringAsFixed(2)} EGP'),
                        if (session.notes != null && session.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('${l.notes}: ${session.notes}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ConsultationMetricBadge(title: l.customsInspectionReadiness, value: '${session.readinessPercentage}%', color: Colors.blue),
                      const SizedBox(width: 8),
                      ConsultationMetricBadge(title: l.itemsAndDocsCount, value: '${session.totalDocumentsCount}', color: Colors.grey),
                      const SizedBox(width: 8),
                      ConsultationMetricBadge(title: l.clearanceReadyStatus, value: '${session.approvedDocumentsCount}', color: Colors.green),
                      const SizedBox(width: 8),
                      ConsultationMetricBadge(title: l.blockingIssuesCount, value: '${session.blockingIssuesCount}', color: session.blockingIssuesCount > 0 ? Colors.red : Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (session.brokerQuoteItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.clearanceQuotesTab, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('${l.totalExpenses}: ${session.totalBrokerFeesEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
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
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(l.expenseItemNameCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(l.categoryCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(l.itemPriceCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(l.quoteItemQuantity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(l.totalExpenses, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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

                  Text(l.customsChecklistTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(l.requiredDocCheckbox, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(l.responsiblePartyLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(l.statusCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(l.notes, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                            Padding(padding: const EdgeInsets.all(8), child: ConsultationDocStatusBadge(status: doc.status)),
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
              label: Text(l.print, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
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
                      SnackBar(content: Text('✅ $saved'), backgroundColor: AppTheme.emerald),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.table_chart, color: Colors.white, size: 14),
              label: Text(l.export, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
}
