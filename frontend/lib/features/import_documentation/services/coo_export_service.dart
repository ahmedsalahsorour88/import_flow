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
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: fontCairo, bold: fontCairoBold),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1.5)),
            child: isChina
                ? _buildChinaCcpitPdf(
                    certNo: certNo,
                    exporter: exporter,
                    consignee: consignee,
                    transport: transport,
                    destination: destination,
                    goodsDesc: goodsDesc,
                    hsCodes: hsCodes,
                    weight: weight,
                    invoiceData: invoiceData,
                    acidNumber: acidNumber,
                  )
                : _buildEur1Pdf(
                    certNo: certNo,
                    exporter: exporter,
                    consignee: consignee,
                    transport: transport,
                    destination: destination,
                    origin: origin,
                    goodsDesc: goodsDesc,
                    hsCodes: hsCodes,
                    weight: weight,
                    invoiceData: invoiceData,
                    remarks: remarks,
                    acidNumber: acidNumber,
                    exemptionNotes: exemptionNotes,
                    isEur1: isEur1,
                  ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildChinaCcpitPdf({
    required String certNo,
    required String exporter,
    required String consignee,
    required String transport,
    required String destination,
    required String goodsDesc,
    required String hsCodes,
    required String weight,
    required String invoiceData,
    required String acidNumber,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Top Center ORIGINAL
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          alignment: pw.Alignment.center,
          child: pw.Text('ORIGINAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, letterSpacing: 2)),
        ),
        pw.Divider(height: 1, color: PdfColors.black),

        // Row 1: Box 1 (Left 50%) vs Title / Certificate No. (Right 50%)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: _buildPdfBoxCell('1. Exporter', exporter, minHeight: 90, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Serial No.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.Text('Certificate No. $certNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('CERTIFICATE OF ORIGIN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('OF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    pw.Text("THE PEOPLE'S REPUBLIC OF CHINA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Row 2: Box 2 (Consignee)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: _buildPdfBoxCell('2. Consignee', consignee, minHeight: 70, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Country / Region of Origin: CHINA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text('ACID Reference: $acidNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.green900)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Row 3 & 4: Transport & Destination vs Box 5 (CCPIT Authority)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                children: [
                  _buildPdfBoxCell('3. Means of transport and route', transport, minHeight: 45, hasRightBorder: true, hasBottomBorder: true),
                  _buildPdfBoxCell('4. Country / region of destination', destination, minHeight: 35, hasRightBorder: true, hasBottomBorder: true),
                ],
              ),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('5. For certifying authority use only', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue900, width: 1),
                        color: PdfColors.blue50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'CHINA COUNCIL FOR THE PROMOTION OF INTERNATIONAL TRADE IS CHINA CHAMBER OF INTERNATIONAL COMMERCE',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.blue900),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text('VERIFY URL: HTTP://CHECK.ECOCCPIT.NET/', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Middle Table (Boxes 6, 7, 8, 9, 10)
        pw.Container(
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1))),
          child: pw.Column(
            children: [
              pw.Container(
                color: PdfColors.grey200,
                child: pw.Row(
                  children: [
                    _buildPdfTableHeadCell('6. Marks and\nnumbers', flex: 2),
                    _buildPdfTableHeadCell('7. Number and kind of packages; description of goods', flex: 4),
                    _buildPdfTableHeadCell('8. H.S. Code', flex: 2),
                    _buildPdfTableHeadCell('9. Quantity', flex: 2),
                    _buildPdfTableHeadCell('10. Number\nand date of\ninvoices', flex: 2, hasRightBorder: false),
                  ],
                ),
              ),
              pw.Divider(height: 1, color: PdfColors.black),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfTableBodyCell('Acoustic Panel\nN/M', flex: 2),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(goodsDesc, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                          pw.SizedBox(height: 4),
                          pw.Text('ACID: $acidNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.green900)),
                          pw.Text('***', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                  _buildPdfTableBodyCell(hsCodes, flex: 2),
                  _buildPdfTableBodyCell(weight, flex: 2),
                  _buildPdfTableBodyCell(invoiceData, flex: 2, hasRightBorder: false),
                ],
              ),
            ],
          ),
        ),

        // Bottom Row: Box 11 (Declaration) vs Box 12 (Certification)
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('11. Declaration by the exporter', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'The undersigned hereby declares that the above details and statements are correct, that all the goods were produced in China and that they comply with the Rules of Origin of the People\'s Republic of China.',
                        style: const pw.TextStyle(fontSize: 7.5, height: 1.2),
                      ),
                      pw.Spacer(),
                      pw.Text('SUZHOU, CHINA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Divider(height: 1, color: PdfColors.black),
                      pw.Text('Place and date, signature and stamp of authorized signatory', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('12. Certification', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('It is hereby certified that the declaration by the exporter is correct.', style: const pw.TextStyle(fontSize: 7.5)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ADDRESS: DONGWU NORTH ROAD GUOYU BUILDING 15A FLOOR WUZHONG DISTRICT SUZHOU CITY\nFAX: 0512-65252957 TEL: 0512-65252453',
                        style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
                      ),
                      pw.Spacer(),
                      pw.Text('SUZHOU, CHINA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Divider(height: 1, color: PdfColors.black),
                      pw.Text('Place and date, signature and stamp of certifying authority', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Page Footer
        pw.Container(
          padding: const pw.EdgeInsets.all(2),
          alignment: pw.Alignment.center,
          color: PdfColors.grey100,
          child: pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        ),
      ],
    );
  }

  static pw.Widget _buildEur1Pdf({
    required String certNo,
    required String exporter,
    required String consignee,
    required String transport,
    required String destination,
    required String origin,
    required String goodsDesc,
    required String hsCodes,
    required String weight,
    required String invoiceData,
    required String remarks,
    required String acidNumber,
    String? exemptionNotes,
    required bool isEur1,
  }) {
    return pw.Column(
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
                    isEur1 ? 'MOVEMENT CERTIFICATE (EUR.1)' : 'CERTIFICATE OF ORIGIN',
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
        _buildPdfBoxCell('1. Exporter (Name, full address, country, reg no.):', exporter, hasBottomBorder: true),

        // Row 2: Preferential Trade & Consignee
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildPdfBoxCell('2. Consignee (Name, full address, country):', consignee, minHeight: 65, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                height: 65,
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('3. Country / Countries of Origin:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
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
              child: _buildPdfBoxCell('4. Transport Details & Route:', transport, minHeight: 45, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              child: _buildPdfBoxCell('5. Remarks / Preferential Rule:', remarks, minHeight: 45, hasBottomBorder: true),
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
                pw.Text('6. Description of Goods, Marks & Numbers, H.S. Tariff Codes:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(goodsDesc, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                  child: pw.Text('H.S. Codes: $hsCodes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Quantity & Gross Mass: $weight', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Invoice & ACID Verification: $invoiceData | ACID: $acidNumber', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
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
    );
  }

  static pw.Widget _buildPdfBoxCell(
    String label,
    String value, {
    bool hasRightBorder = false,
    bool hasBottomBorder = false,
    double? minHeight,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      height: minHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: hasBottomBorder ? const pw.BorderSide(color: PdfColors.black, width: 0.8) : pw.BorderSide.none,
          right: hasRightBorder ? const pw.BorderSide(color: PdfColors.black, width: 0.8) : pw.BorderSide.none,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTableHeadCell(String title, {required int flex, bool hasRightBorder = true}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border(right: hasRightBorder ? const pw.BorderSide(color: PdfColors.black, width: 0.8) : pw.BorderSide.none),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableBodyCell(String content, {required int flex, bool hasRightBorder = true}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border(right: hasRightBorder ? const pw.BorderSide(color: PdfColors.black, width: 0.8) : pw.BorderSide.none),
        ),
        child: pw.Text(
          content,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
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
