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
        // Top Center Title
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1))),
          child: pw.Text(
            'MOVEMENT CERTIFICATE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
          ),
        ),

        // Row 1: Box 1 (Exporter) vs EUR.1 Header & Box 2 (Preferential Trade)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: _buildPdfBoxCell('1. Exporter (Name, full address, country)', exporter, minHeight: 90, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                children: [
                  // EUR.1 Header Box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('EUR.1', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                            pw.Text('No A $certNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('See notes overleaf before completing this form.', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ),

                  // Box 2: Preferential Trade
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text('2. Certificate used in preferential trade between', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(origin.contains('EU') ? 'EU' : origin.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                        pw.Text('and', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text(destination.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                        pw.Text('(Insert appropriate countries, groups of countries or territories)', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Row 2: Box 3 (Consignee) vs Box 4 (Origin) & Box 5 (Destination)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: _buildPdfBoxCell('3. Consignee (Name, full address, country) (Optional)', consignee, minHeight: 70, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildPdfBoxCell('4. Country of Origin', origin, minHeight: 70, hasRightBorder: true, hasBottomBorder: true),
                  ),
                  pw.Expanded(
                    child: _buildPdfBoxCell('5. Country of Destination', destination, minHeight: 70, hasBottomBorder: true),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Row 3: Box 6 (Transport) vs Box 7 (Remarks)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: _buildPdfBoxCell('6. Transport details (Optional)', transport.isNotEmpty ? transport : 'BY SEA / CONTAINERIZED CARGO', minHeight: 40, hasRightBorder: true, hasBottomBorder: true),
            ),
            pw.Expanded(
              flex: 5,
              child: _buildPdfBoxCell('7. Remarks', remarks.isNotEmpty ? remarks : 'REVISED RULES', minHeight: 40, hasBottomBorder: true),
            ),
          ],
        ),

        // Middle Table (Boxes 8, 9, 10)
        pw.Container(
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1))),
          child: pw.Column(
            children: [
              pw.Container(
                color: PdfColors.grey200,
                child: pw.Row(
                  children: [
                    _buildPdfTableHeadCell('8. Item number; Marks and numbers; Number and kind of packages (1); Description of goods', flex: 5),
                    _buildPdfTableHeadCell('9. Gross mass (kg)\nor other measure', flex: 2),
                    _buildPdfTableHeadCell('10. Invoices\n(Optional)', flex: 2, hasRightBorder: false),
                  ],
                ),
              ),
              pw.Divider(height: 1, color: PdfColors.black),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Box 8
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(goodsDesc, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                          pw.SizedBox(height: 4),
                          pw.Text('HS CODES: $hsCodes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.purple900)),
                          pw.SizedBox(height: 10),
                          pw.Text('----------------------------------------------------', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 6)),
                        ],
                      ),
                    ),
                  ),

                  // Box 9: Gross Mass
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(weight.isNotEmpty ? weight : '1774,514 KG', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                        ],
                      ),
                    ),
                  ),

                  // Box 10: Invoices & ACID
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ACID: $acidNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.green900)),
                          if (invoiceData.isNotEmpty && invoiceData != 'INVOICE INFO')
                            pw.Text(invoiceData, style: const pw.TextStyle(fontSize: 7.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom Section: Box 11 (Customs Endorsement) vs Box 12 (Declaration by Exporter)
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Box 11: Customs Endorsement
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('11. CUSTOMS ENDORSEMENT', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Declaration certified | Export document (2)', style: const pw.TextStyle(fontSize: 6.5)),
                      pw.Text('Customs office: Vilnius regional customs office', style: const pw.TextStyle(fontSize: 6.5)),
                      pw.Text('Issuing country: Lithuania', style: const pw.TextStyle(fontSize: 6.5)),
                      pw.Spacer(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Date: 2026-08-11', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                          pw.Text('Stamp: A-004 • LT VM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.blue900)),
                        ],
                      ),
                      pw.Divider(height: 1, color: PdfColors.black),
                      pw.Center(child: pw.Text('(Signature)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700))),
                    ],
                  ),
                ),
              ),

              // Box 12: Declaration by Exporter
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('12. DECLARATION BY THE EXPORTER', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('I, the undersigned, declare that the goods described above meet the conditions required for the issue of this certificate.', style: const pw.TextStyle(fontSize: 6.5, height: 1.15)),
                      pw.Spacer(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Place/Date: VILNIUS 2026-08-11', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                          pw.Text('NARBUTAS DOKUMENTAI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.indigo900)),
                        ],
                      ),
                      pw.Divider(height: 1, color: PdfColors.black),
                      pw.Center(child: pw.Text('(Signature)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Footnotes
        pw.Container(
          padding: const pw.EdgeInsets.all(2),
          color: PdfColors.grey100,
          child: pw.Text('(1) If goods not packed, state in bulk. (2) Complete only where regulations require.', style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700)),
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
