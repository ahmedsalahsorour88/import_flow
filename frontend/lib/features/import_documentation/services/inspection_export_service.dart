import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/services/file_save_helper.dart';

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

    final invoices = (templateData['commercial_invoices'] as List<dynamic>?) ?? [];
    final inspectedItems = (templateData['inspected_items'] as List<dynamic>?) ?? [];
    final methodOfShipment = templateData['method_of_shipment'] ?? 'Sea';
    final placeOfInspection = templateData['place_of_inspection'] ?? origin;
    final issuingOffice = templateData['issuing_office'] ?? '$agency Office';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: fontCairo, bold: fontCairoBold),
        build: (pw.Context context) {
          return [
            pw.Container(
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
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                            ),
                            pw.Text(
                              'EGYPT MANDATORY VERIFICATION OF CONFORMITY PROGRAM (GOEIC / NFSA)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.blue900),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('COC NO: $cocNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text('ACID NO: $acidNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green900)),
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
                      'DRAFT VERIFICATION — PLEASE CONFIRM WITHIN 48 HOURS AFTER WHICH WE SHALL PROCEED TO ISSUE',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                    ),
                  ),

                  // Parties Grid
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8), bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Importer (Name, Address & Tax ID):', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                              pw.SizedBox(height: 2),
                              pw.Text(importer, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Exporter & Producer (Name & Address):', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                              pw.SizedBox(height: 2),
                              pw.Text(exporter, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
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
                        pw.Text('Origin: $origin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.Text('H.S. Codes: $hsCodes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.blue900)),
                        pw.Text('Total Value: $totalValue', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Method: $methodOfShipment', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Port of Entry: $portOfEntry', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),

                  // Commercial Invoices Table
                  if (invoices.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Commercial Invoices / الفواتير التجارية المرفقة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          pw.SizedBox(height: 4),
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                            children: [
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Invoice Amount & Currency', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Invoice No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Invoice Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Incoterm', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                ],
                              ),
                              ...invoices.map((inv) {
                                final i = inv is Map ? inv : {};
                                final amt = (i['amount'] is num) ? (i['amount'] as num).toStringAsFixed(2) : (i['amount'] ?? '').toString();
                                final curr = (i['currency'] ?? 'EUR').toString();
                                return pw.TableRow(
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('$amt $curr', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${i['invoice_number'] ?? ''}', style: const pw.TextStyle(fontSize: 7))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${i['invoice_date'] ?? ''}', style: const pw.TextStyle(fontSize: 7))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${i['incoterm'] ?? 'EXW'}', style: const pw.TextStyle(fontSize: 7))),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Inspected Items Table
                  if (inspectedItems.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Inspected Items & Adopted Standards / بنود البضائع الخاضعة للفحص:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          pw.SizedBox(height: 4),
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                            children: [
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Origin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Product Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Description (Brand/Model)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Adopted Standard', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                ],
                              ),
                              ...inspectedItems.map((itm) {
                                final item = itm is Map ? itm : {};
                                return pw.TableRow(
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('${item['item_no'] ?? ''}', style: const pw.TextStyle(fontSize: 6.5))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('${item['quantity'] ?? ''}', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('${item['country_of_origin'] ?? ''}', style: const pw.TextStyle(fontSize: 6.5))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('${item['product_type'] ?? ''}', style: const pw.TextStyle(fontSize: 6.5))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('${item['description'] ?? ''}', style: const pw.TextStyle(fontSize: 6.5))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('${item['adopted_standard'] ?? ''}', style: pw.TextStyle(fontSize: 6.5, color: PdfColors.green900, fontWeight: pw.FontWeight.bold))),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Transport & Office Details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Place of Inspection: $placeOfInspection', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('Date of Inspection: $dateInsp', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('Issuing Office: $issuingOffice', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
                      ],
                    ),
                  ),

                  // Standards List
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Egyptian Mandatory Standards & Test Protocols (ES Standards Tested):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.SizedBox(height: 3),
                        ...standards.map((s) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Text('• $s', style: const pw.TextStyle(fontSize: 7)),
                            )),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(color: PdfColors.green50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)), border: pw.Border.all(color: PdfColors.green800)),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('CONFORMITY ASSESSMENT RESULT: CONFORMING & COMPLIANT FOR RELEASE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.green900)),
                              pw.Text('Verified: GOEIC / NFSA', style: const pw.TextStyle(fontSize: 7.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    color: PdfColors.grey100,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Issued by Accredited Inspection Agency ($agency)', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('Approved for Egyptian Customs Clearance', style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
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

  /// Exports and Saves Inspection Certificate PDF directly to a file chosen by the user
  static Future<String?> saveInspectionPdfToFile({
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

    final cleanAcid = acidNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final filename = 'Draft_Inspection_Certificate_${agency}_${cleanAcid.isNotEmpty ? cleanAcid : DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await pdf.save();

    return FileSaveHelper.saveBytes(
      context: null,
      bytes: bytes,
      defaultFileName: filename,
      dialogTitle: 'حفظ مسودة شهادة الفحص والمطابقة بصيغة PDF',
      allowedExtensions: ['pdf'],
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

  /// Exports and Saves Inspection Certificate CSV / Excel directly to a file chosen by the user
  static Future<String?> saveInspectionCsvToFile({
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
  }) async {
    final csv = exportInspectionCsv(
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
    );

    final cleanAcid = acidNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final filename = 'Draft_Inspection_Certificate_${agency}_${cleanAcid.isNotEmpty ? cleanAcid : DateTime.now().millisecondsSinceEpoch}.csv';

    return FileSaveHelper.saveText(
      context: null,
      textContent: csv,
      defaultFileName: filename,
      dialogTitle: 'حفظ مسودة شهادة الفحص والمطابقة بصيغة Excel / CSV',
      allowedExtensions: ['csv', 'xlsx'],
    );
  }
}
