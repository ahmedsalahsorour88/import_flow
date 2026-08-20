import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CooExportService {
  /// Generates the pdf.Document instance for Certificate of Origin (EUR.1 / China CCPIT / Generic)
  static Future<pw.Document> generateCOOPdf({
    required Map<String, dynamic> templateData,
    required String certificateType,
    required String acidNumber,
    String? exemptionNotes,
  }) async {
    final pdf = pw.Document();
    final fontCairo = await PdfGoogleFonts.cairoRegular();
    final fontCairoBold = await PdfGoogleFonts.cairoBold();

    final certNo = templateData['certificate_number'] ?? 'DRAFT-COO';
    final isChina = certificateType.toUpperCase().contains('CHINA') || certificateType.toUpperCase().contains('CCPIT');
    final isEur1 = certificateType.toUpperCase().contains('EUR.1') || certificateType.toUpperCase().contains('EUR1');

    final exporter = templateData['box_1_exporter'] ?? 'EXPORTER / PRODUCER';
    final consignee = templateData['box_2_consignee'] ?? templateData['box_3_consignee'] ?? 'IMPORTER / CONSIGNEE';
    final transport = templateData['box_3_means_of_transport'] ?? templateData['box_6_transport_details'] ?? 'BY SEA';
    final destination = templateData['box_4_country_of_destination'] ?? templateData['box_5_country_destination'] ?? 'EGYPT';
    final origin = templateData['country_of_origin'] ?? templateData['box_4_country_origin'] ?? 'EUROPEAN UNION';
    final hsCodes = templateData['box_8_hs_code'] ?? templateData['hs_code'] ?? templateData['hs_codes'] ?? '560229';
    final goodsDesc = templateData['box_6_marks_and_numbers'] ?? templateData['box_8_description_packages'] ?? 'COMMERCIAL CARGO';
    final weight = templateData['box_9_quantity_and_weight'] ?? templateData['box_9_gross_mass'] ?? 'GROSS WEIGHT';
    final invoiceData = templateData['box_10_invoice_number_and_date'] ?? templateData['box_10_invoices_and_acid'] ?? 'INVOICE INFO';
    final remarks = templateData['box_7_remarks'] ?? (isEur1 ? 'REVISED RULES' : 'N/A');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontCairo, bold: fontCairoBold),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1.5)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header Top Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isEur1
                                ? 'MOVEMENT CERTIFICATE (EUR.1)'
                                : (isChina ? 'CERTIFICATE OF ORIGIN (CHINA CCPIT)' : 'CERTIFICATE OF ORIGIN'),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                          ),
                          pw.Text(
                            'OFFICIAL DRAFT VERIFICATION — ACI NAFEZA EGYPT',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blue900),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('CERTIFICATE NO: $certNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.Text('ACID NO: $acidNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.green900)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Exemption Banner if any
                if (exemptionNotes != null && exemptionNotes.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green50,
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green900, width: 0.8)),
                    ),
                    child: pw.Text(
                      'STATUS: $exemptionNotes',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                  ),

                // Box 1: Exporter
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('1. Exporter (Name, full address, country, reg no.):', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(exporter, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    ],
                  ),
                ),

                // Row 2: Preferential Trade & Consignee
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        height: 65,
                        decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8), bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('2. Consignee (Name, full address, country):', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Text(consignee, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        height: 65,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('3. Country / Countries of Origin:', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Text(origin, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                            pw.SizedBox(height: 4),
                            pw.Text('Country of Destination: $destination', style: const pw.TextStyle(fontSize: 8.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Row 3: Transport & Remarks
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        height: 45,
                        decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8), bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('4. Transport Details & Route:', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.Text(transport, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        height: 45,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('5. Remarks / Preferential Rule:', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.Text(remarks, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.red900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Row 4: Goods Description & HS Codes Table
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('6. Description of Goods, Marks & Numbers, H.S. Tariff Codes:', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(goodsDesc, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                          child: pw.Text('H.S. Codes: $hsCodes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Quantity & Gross Mass: $weight', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Invoice & ACID Verification: $invoiceData | ACID: $acidNumber', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ),

                // Footer Endorsement
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.grey100,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('7. Declaration by Exporter: Certified Correct', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('8. Customs / Chamber Endorsement: Approved', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Print or Save PDF
  static Future<void> printOrSavePdf({
    required Map<String, dynamic> templateData,
    required String certificateType,
    required String acidNumber,
    String? exemptionNotes,
  }) async {
    final pdf = await generateCOOPdf(
      templateData: templateData,
      certificateType: certificateType,
      acidNumber: acidNumber,
      exemptionNotes: exemptionNotes,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Draft_Certificate_of_Origin_${acidNumber.replaceAll(RegExp(r'[^0-9]'), '')}.pdf',
    );
  }

  /// Export CSV / Excel data string
  static String exportCOOCsv({
    required Map<String, dynamic> templateData,
    required String certificateType,
    required String acidNumber,
  }) {
    final certNo = templateData['certificate_number'] ?? 'DRAFT-COO';
    final origin = templateData['country_of_origin'] ?? 'EUROPEAN UNION';
    final hsCodes = templateData['box_8_hs_code'] ?? templateData['hs_codes'] ?? '560229';
    final exporter = (templateData['box_1_exporter'] ?? '').toString().replaceAll('\n', ' ');
    final consignee = (templateData['box_2_consignee'] ?? templateData['box_3_consignee'] ?? '').toString().replaceAll('\n', ' ');

    final sb = StringBuffer();
    sb.writeln('Field,Value');
    sb.writeln('Certificate Type,"$certificateType"');
    sb.writeln('Certificate Number,"$certNo"');
    sb.writeln('ACID Number,"$acidNumber"');
    sb.writeln('Exporter,"$exporter"');
    sb.writeln('Consignee,"$consignee"');
    sb.writeln('Country of Origin,"$origin"');
    sb.writeln('H.S. Codes,"$hsCodes"');
    sb.writeln('Destination,"EGYPT"');
    sb.writeln('Generated Date,"${DateTime.now().toIso8601String()}"');

    return sb.toString();
  }
}
