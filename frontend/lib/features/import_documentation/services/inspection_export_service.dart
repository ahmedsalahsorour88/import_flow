import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InspectionExportService {
  /// Generates the pdf.Document instance for Inspection / COC / VOC Certificate
  static Future<pw.Document> generateInspectionPdf({
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
  }) async {
    final pdf = pw.Document();
    final fontCairo = await PdfGoogleFonts.cairoRegular();
    final fontCairoBold = await PdfGoogleFonts.cairoBold();

    final cocNo = templateData['coc_number'] ?? 'DRAFT-COC';
    final importer = templateData['importer_name_and_address'] ?? 'IMPORTER INFO';
    final exporter = templateData['exporter_name_and_address'] ?? 'EXPORTER INFO';
    final origin = templateData['country_of_origin'] ?? 'UNKNOWN';
    final hsCodes = templateData['hs_code'] ?? '560229';
    final totalValue = templateData['total_value'] ?? 'N/A';
    final portOfEntry = templateData['port_of_entry'] ?? 'Alexandria';
    final dateInsp = templateData['date_of_inspection'] ?? DateTime.now().toString().split(' ')[0];

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
                // Top Header
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
                            '${agency.toUpperCase()} — CERTIFICATE OF CONFORMITY (COC / VOC)',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                          ),
                          pw.Text(
                            'EGYPT MANDATORY VERIFICATION OF CONFORMITY PROGRAM',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.blue900),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('COC NO: $cocNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                          pw.Text('ACID NO: $acidNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.green900)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Notice Banner
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: PdfColors.amber50,
                  child: pw.Text(
                    'DRAFT VERIFICATION — CONFIRM WITHIN 48 HOURS FOR FINAL CUSTOMS ATTESTATION',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                  ),
                ),

                // Parties Grid
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
                            pw.Text('Importer (Name, Address & Tax ID):', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Text(importer, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
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
                            pw.Text('Exporter & Producer (Name & Address):', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Text(exporter, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Meta Row
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Country of Origin: $origin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                      pw.Text('H.S. Codes: $hsCodes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blue900)),
                      pw.Text('Total Value: $totalValue', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Port of Entry: $portOfEntry', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),

                // Standards List
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Egyptian Mandatory Standards & Test Protocols (ES Standards):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.SizedBox(height: 6),
                        ...standards.map((s) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text('• $s', style: const pw.TextStyle(fontSize: 8)),
                            )),
                        pw.Spacer(),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(color: PdfColors.green50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)), border: pw.Border.all(color: PdfColors.green800)),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('CONFORMITY ASSESSMENT RESULT: CONFORMING & COMPLIANT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.green900)),
                              pw.Text('Inspection Date: $dateInsp', style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.grey100,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Issued by Accredited Inspection Agency ($agency)', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Approved for Egyptian Customs Clearance (GOEIC / NFSA)', style: const pw.TextStyle(fontSize: 8)),
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
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
  }) async {
    final pdf = await generateInspectionPdf(
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Draft_Inspection_Certificate_${agency}_${acidNumber.replaceAll(RegExp(r'[^0-9]'), '')}.pdf',
    );
  }

  /// Export CSV / Excel data string
  static String exportInspectionCsv({
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
  }) {
    final cocNo = templateData['coc_number'] ?? 'DRAFT-COC';
    final origin = templateData['country_of_origin'] ?? 'UNKNOWN';
    final hsCodes = templateData['hs_code'] ?? '560229';
    final totalVal = templateData['total_value'] ?? 'N/A';

    final sb = StringBuffer();
    sb.writeln('Field,Value');
    sb.writeln('Inspection Agency,"$agency"');
    sb.writeln('Certificate Type,"$certType"');
    sb.writeln('CoC Number,"$cocNo"');
    sb.writeln('ACID Number,"$acidNumber"');
    sb.writeln('Country of Origin,"$origin"');
    sb.writeln('H.S. Codes,"$hsCodes"');
    sb.writeln('Total Invoice Value,"$totalVal"');
    sb.writeln('Port of Entry,"${templateData['port_of_entry'] ?? 'Alexandria'}"');
    sb.writeln('Egyptian Standards Tested,"${standards.join(' | ')}"');
    sb.writeln('Result,"CONFORMING"');

    return sb.toString();
  }
}
