import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/customs_consultation_model.dart';

class CustomsConsultationPdfService {
  /// Generates an enterprise-grade Arabic PDF for a Customs Consultation statement and checklist.
  static Future<Uint8List> generateConsultationPdf(CustomsConsultationModel session) async {
    final pdf = pw.Document();

    pw.Font arabicFont;
    pw.Font arabicBoldFont;
    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
      arabicBoldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      arabicFont = await PdfGoogleFonts.amiriRegular();
      arabicBoldFont = await PdfGoogleFonts.amiriBold();
    }

    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicBoldFont,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2C3E50'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تقرير دراسة الاستشارة الجمركية والفحص المستندي',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'ImportFlow ERP — Customs Consultation & Inspection Engine',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'كود الدراسة: ${session.consultationCode}',
                        style: pw.TextStyle(color: PdfColors.amber, fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'التاريخ: ${session.createdAt.split("T").first.split(" ").first}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Metadata Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'عنوان الدراسة: ${session.title}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5),
                        ),
                      ),
                      pw.Text(
                        'الحالة العامة: ${session.overallStatus}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColor.fromHex('#3498DB')),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ملف الشحنة: ${session.importFileCode ?? "-"}', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('المستخلص الجمركي: ${session.brokerName}', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text(
                        'الرسوم والضرائب التقديرية: ${session.estimatedDutiesEgp.toStringAsFixed(2)} EGP',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#C0392B')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Quick Metrics Summary Box
            pw.Row(
              children: [
                _buildPdfMetricBox('نسبة الجاهزية الجمركية', '${session.readinessPercentage.toStringAsFixed(0)}%', PdfColor.fromHex('#3498DB')),
                pw.SizedBox(width: 8),
                _buildPdfMetricBox('إجمالي المستندات', '${session.totalDocumentsCount}', PdfColor.fromHex('#2C3E50')),
                pw.SizedBox(width: 8),
                _buildPdfMetricBox('المستندات المعتمدة', '${session.approvedDocumentsCount}', PdfColor.fromHex('#27AE60')),
                pw.SizedBox(width: 8),
                _buildPdfMetricBox(
                  'عوائق التخليص (Blocking)',
                  '${session.blockingIssuesCount} عائق',
                  session.blockingIssuesCount > 0 ? PdfColor.fromHex('#C0392B') : PdfColor.fromHex('#27AE60'),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Checklist Table Header
            pw.Text(
              'قائمة فحص المستندات والاشتراطات الجمركية المعتمدة للشحنة:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 6),

            // Table of Checklist Items
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.0),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.0),
                3: pw.FlexColumnWidth(2.6),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECF0F1')),
                  children: [
                    _buildPdfTableHeader('نوع المستند وبنود التعريفة'),
                    _buildPdfTableHeader('الجهة المسؤولة'),
                    _buildPdfTableHeader('الحالة'),
                    _buildPdfTableHeader('الاشتراطات والملاحظات'),
                  ],
                ),
                ...session.checklistItems.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.documentType,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                            ),
                            if (item.hsCode != null && item.hsCode!.isNotEmpty)
                              pw.Text(
                                'بنود: ${item.hsCode}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey700),
                              ),
                            if (item.isBlockingShipment)
                              pw.Text(
                                '⚠️ عائق معطل للشحن/التخليص',
                                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.red900),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(item.responsibleParty, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          item.status,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: item.status == 'Approved'
                                ? PdfColor.fromHex('#27AE60')
                                : (item.status == 'Rejected' ? PdfColor.fromHex('#C0392B') : PdfColors.black),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(item.remarks ?? '-', style: const pw.TextStyle(fontSize: 7.5)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfMetricBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7, color: color, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColor.fromHex('#2C3E50')),
      ),
    );
  }
}
