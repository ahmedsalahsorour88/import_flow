import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';

class InspectionExportService {
  /// Helper to clean string for TSV (replaces tabs and newlines with space)
  static String _cleanTsv(String val) => val.replaceAll('\t', ' ').replaceAll('\r', '').replaceAll('\n', ' ').trim();

  /// Helper to quote CSV fields
  static String _csvQuote(String val) {
    final s = val.replaceAll('"', '""');
    return '"$s"';
  }

  /// Generates the pdf.Document instance for Inspection / COC / VOC Certificate.
  /// Supports single active-language rendering (Arabic or English) without bilingual stacking.
  static Future<pw.Document> generateInspectionPdf({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) async {
    final bool isAr = isArabic ?? (context != null ? Localizations.localeOf(context).languageCode == 'ar' : true);
    final pdf = pw.Document();
    final fontCairo = await PdfGoogleFonts.cairoRegular();
    final fontCairoBold = await PdfGoogleFonts.cairoBold();
    final textDir = isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final cocNo = templateData['coc_number'] ?? 'DRAFT-COC';
    final importer = templateData['importer_name_and_address'] ?? (isAr ? 'بيانات المستورد غير محددة' : 'IMPORTER INFO');
    final exporter = templateData['exporter_name_and_address'] ?? (isAr ? 'بيانات المصدر غير محددة' : 'EXPORTER INFO');
    final origin = templateData['country_of_origin'] ?? (isAr ? 'غير محدد' : 'UNKNOWN');
    final hsCodes = templateData['hs_code'] ?? '560229';
    final totalValue = templateData['total_value'] ?? (isAr ? 'غير محدد' : 'N/A');
    final portOfEntry = templateData['port_of_entry'] ?? (isAr ? 'ميناء الإسكندرية' : 'Alexandria');
    final dateInsp = templateData['date_of_inspection'] ?? DateTime.now().toString().split(' ')[0];

    final invoices = (templateData['commercial_invoices'] as List<dynamic>?) ?? [];
    final inspectedItems = (templateData['inspected_items'] as List<dynamic>?) ?? [];
    final methodOfShipment = templateData['method_of_shipment'] ?? (isAr ? 'بحري' : 'Sea');
    final placeOfInspection = templateData['place_of_inspection'] ?? origin;
    final issuingOffice = templateData['issuing_office'] ?? (isAr ? 'مكتب $agency' : '$agency Office');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        textDirection: textDir,
        theme: pw.ThemeData.withFont(base: fontCairo, bold: fontCairoBold),
        build: (pw.Context ctx) {
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
                          crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              isAr
                                  ? 'شهادة المطابقة النوعية والتفتيش الفني — $agency'
                                  : '${agency.toUpperCase()} — CERTIFICATE OF CONFORMITY (COC / VOC)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                            ),
                            pw.Text(
                              isAr
                                  ? 'التحقق الإلزامي من المطابقة في مصر (الهيئة العامة للرقابة على الصادرات والواردات وهيئة سلامة الغذاء)'
                                  : 'EGYPT MANDATORY VERIFICATION OF CONFORMITY PROGRAM (GOEIC / NFSA)',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.blue900),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: isAr ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              isAr ? 'رقم الشهادة: $cocNo' : 'COC NO: $cocNo',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                            pw.Text(
                              isAr ? 'رقم القيد الجمركي: $acidNumber' : 'ACID NO: $acidNumber',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green900),
                            ),
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
                      isAr
                          ? 'مسودة للتحقق — يرجى التأكيد خلال 48 ساعة قبل الإصدار النهائي لتفادي التعطيل الجمركي'
                          : 'DRAFT VERIFICATION — PLEASE CONFIRM WITHIN 48 HOURS AFTER WHICH WE SHALL PROCEED TO ISSUE',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                    ),
                  ),

                  // Parties Grid
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              right: isAr ? pw.BorderSide.none : const pw.BorderSide(color: PdfColors.black, width: 0.8),
                              left: isAr ? const pw.BorderSide(color: PdfColors.black, width: 0.8) : pw.BorderSide.none,
                              bottom: const pw.BorderSide(color: PdfColors.black, width: 0.8),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                isAr ? 'المستورد (الاسم، العنوان والرقم الضريبي):' : 'Importer (Name, Address & Tax ID):',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                              ),
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
                            crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                isAr ? 'المصدر والمنتج (الاسم والعنوان):' : 'Exporter & Producer (Name & Address):',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                              ),
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
                        pw.Text(isAr ? 'المنشأ: $origin' : 'Origin: $origin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.Text(isAr ? 'بنود التعريفة: $hsCodes' : 'H.S. Codes: $hsCodes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.blue900)),
                        pw.Text(isAr ? 'القيمة الإجمالية: $totalValue' : 'Total Value: $totalValue', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(isAr ? 'طريقة الشحن: $methodOfShipment' : 'Method: $methodOfShipment', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(isAr ? 'ميناء الوصول: $portOfEntry' : 'Port of Entry: $portOfEntry', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),

                  // Commercial Invoices Table
                  if (invoices.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                      child: pw.Column(
                        crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isAr ? 'الفواتير التجارية المرفقة الخاضعة للفحص:' : 'Commercial Invoices Attached:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                            children: [
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(isAr ? 'القيمة والعملة' : 'Invoice Amount & Currency', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(isAr ? 'رقم الفاتورة' : 'Invoice No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(isAr ? 'تاريخ الفاتورة' : 'Invoice Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(isAr ? 'الشرط التجاري' : 'Incoterm', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
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
                        crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isAr ? 'بنود البضائع والمواصفات المعتمدة:' : 'Inspected Goods & Adopted Standards:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                            children: [
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(isAr ? 'م' : '#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(isAr ? 'الكمية' : 'Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(isAr ? 'المنشأ' : 'Origin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(isAr ? 'نوع المنتج' : 'Product Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(isAr ? 'الوصف (الماركة والموديل)' : 'Description (Brand/Model)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(isAr ? 'المواصفة المعتمدة' : 'Adopted Standard', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
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
                        pw.Text(isAr ? 'مكان الفحص: $placeOfInspection' : 'Place of Inspection: $placeOfInspection', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text(isAr ? 'تاريخ الفحص: $dateInsp' : 'Date of Inspection: $dateInsp', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text(isAr ? 'المكتب المصدر: $issuingOffice' : 'Issuing Office: $issuingOffice', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
                      ],
                    ),
                  ),

                  // Standards List
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isAr ? 'المواصفات القياسية المصرية وبروتوكولات الفحص المعتمدة:' : 'Egyptian Mandatory Standards & Test Protocols (ES Standards Tested):',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                        ),
                        pw.SizedBox(height: 3),
                        ...standards.map((s) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Text('• $s', style: const pw.TextStyle(fontSize: 7)),
                            )),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColors.green800),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                isAr ? 'نتيجة تقييم المطابقة: مطابق وصالح للإفراج الجمركي' : 'CONFORMITY ASSESSMENT RESULT: CONFORMING & COMPLIANT FOR RELEASE',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.green900),
                              ),
                              pw.Text(
                                isAr ? 'معتمد رقابياً: الرقابة على الصادرات والواردات وسلامة الغذاء' : 'Verified: GOEIC / NFSA',
                                style: const pw.TextStyle(fontSize: 7.5),
                              ),
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
                        pw.Text(
                          isAr ? 'صادرة عن جهة فحص وتفتيش معتمدة ($agency)' : 'Issued by Accredited Inspection Agency ($agency)',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Text(
                          isAr ? 'معتمد للإفراج والتخليص الجمركي المصري' : 'Approved for Egyptian Customs Clearance',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
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
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) async {
    final pdf = await generateInspectionPdf(
      context: context,
      isArabic: isArabic,
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
      comparisonMatrix: comparisonMatrix,
    );

    final cleanAcid = acidNumber.replaceAll(RegExp(r'[^0-9]'), '');
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Inspection_Certificate_${agency}_${cleanAcid.isNotEmpty ? cleanAcid : DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Exports and Saves Inspection Certificate PDF directly to a file chosen by the user
  static Future<String?> saveInspectionPdfToFile({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) async {
    final bool isAr = isArabic ?? (context != null ? Localizations.localeOf(context).languageCode == 'ar' : true);
    final pdf = await generateInspectionPdf(
      context: context,
      isArabic: isAr,
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
      comparisonMatrix: comparisonMatrix,
    );

    final cleanAcid = acidNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final filename = 'Inspection_Certificate_${agency}_${cleanAcid.isNotEmpty ? cleanAcid : DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await pdf.save();

    if (context == null || !context.mounted) return null;
    return FileSaveHelper.saveBytes(
      context: context,
      bytes: bytes,
      defaultFileName: filename,
      dialogTitle: isAr ? 'حفظ مسودة شهادة الفحص والمطابقة' : 'Save Inspection Certificate PDF',
      allowedExtensions: ['pdf'],
    );
  }

  /// Export CSV / Excel data string (unmerged with UTF-8 BOM)
  static String exportInspectionCsv({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) {
    final bool isAr = isArabic ?? (context != null && Localizations.localeOf(context).languageCode == 'ar');
    final cocNo = templateData['coc_number'] ?? 'DRAFT-COC';
    final origin = templateData['country_of_origin'] ?? (isAr ? 'غير محدد' : 'UNKNOWN');
    final hsCodes = templateData['hs_code'] ?? '560229';
    final totalVal = templateData['total_value'] ?? (isAr ? 'غير محدد' : 'N/A');
    final importer = templateData['importer_name_and_address'] ?? '';
    final exporter = templateData['exporter_name_and_address'] ?? '';

    final sb = StringBuffer();
    // UTF-8 BOM
    sb.write('\uFEFF');

    // Summary Headers
    sb.writeln('${isAr ? 'الحقل' : 'Field'},${isAr ? 'القيمة' : 'Value'}');
    sb.writeln('${_csvQuote(isAr ? 'جهة الفحص الدولية' : 'Inspection Agency')},${_csvQuote(agency)}');
    sb.writeln('${_csvQuote(isAr ? 'نوع شهادة الفحص' : 'Certificate Type')},${_csvQuote(certType)}');
    sb.writeln('${_csvQuote(isAr ? 'رقم درافت الشهادة' : 'Certificate Number')},${_csvQuote(cocNo.toString())}');
    sb.writeln('${_csvQuote(isAr ? 'رقم القيد الجمركي المسبق' : 'ACID Number')},${_csvQuote(acidNumber)}');
    sb.writeln('${_csvQuote(isAr ? 'اسم المستورد' : 'Importer Name')},${_csvQuote(importer.toString())}');
    sb.writeln('${_csvQuote(isAr ? 'اسم المصدر' : 'Exporter Name')},${_csvQuote(exporter.toString())}');
    sb.writeln('${_csvQuote(isAr ? 'بلد المنشأ' : 'Country of Origin')},${_csvQuote(origin.toString())}');
    sb.writeln('${_csvQuote(isAr ? 'بنود التعريفة الجمركية' : 'H.S. Codes')},${_csvQuote(hsCodes.toString())}');
    sb.writeln('${_csvQuote(isAr ? 'القيمة الإجمالية المصرح عنها' : 'Total Value')},${_csvQuote(totalVal.toString())}');
    sb.writeln('${_csvQuote(isAr ? 'ميناء الوصول' : 'Port of Entry')},${_csvQuote((templateData['port_of_entry'] ?? 'Alexandria').toString())}');
    sb.writeln('${_csvQuote(isAr ? 'المواصفات القياسية المصرية' : 'Standards Tested')},${_csvQuote(standards.join(' | '))}');
    sb.writeln('${_csvQuote(isAr ? 'نتيجة تقييم المطابقة' : 'Result')},${_csvQuote(isAr ? 'مطابق وصالح للإفراج الجمركي' : 'CONFORMING')}');

    // Line items section if available
    final inspectedItems = (templateData['inspected_items'] as List<dynamic>?) ?? [];
    if (inspectedItems.isNotEmpty) {
      sb.writeln();
      sb.writeln(isAr ? 'بنود البضائع المفحوصة والمواصفات' : 'Inspected Line Items');
      sb.writeln([
        _csvQuote(isAr ? 'م' : '#'),
        _csvQuote(isAr ? 'الكمية' : 'Quantity'),
        _csvQuote(isAr ? 'المنشأ' : 'Origin'),
        _csvQuote(isAr ? 'نوع المنتج' : 'Product Type'),
        _csvQuote(isAr ? 'الوصف (الماركة والموديل)' : 'Description (Brand/Model)'),
        _csvQuote(isAr ? 'المواصفة المعتمدة' : 'Adopted Standard'),
      ].join(','));

      for (final item in inspectedItems) {
        final itm = item is Map ? item : {};
        sb.writeln([
          _csvQuote('${itm['item_no'] ?? ''}'),
          _csvQuote('${itm['quantity'] ?? ''}'),
          _csvQuote('${itm['country_of_origin'] ?? ''}'),
          _csvQuote('${itm['product_type'] ?? ''}'),
          _csvQuote('${itm['description'] ?? ''}'),
          _csvQuote('${itm['adopted_standard'] ?? ''}'),
        ].join(','));
      }
    }

    // Comparison Matrix if available
    if (comparisonMatrix != null && comparisonMatrix.isNotEmpty) {
      sb.writeln();
      sb.writeln(isAr ? 'مصفوفة المطابقة والفروق' : 'Discrepancy Matrix');
      sb.writeln([
        _csvQuote(isAr ? 'الحقل' : 'Field'),
        _csvQuote(isAr ? 'القيمة بالنظام' : 'System Value'),
        _csvQuote(isAr ? 'القيمة بالدرافت' : 'Draft Value'),
        _csvQuote(isAr ? 'حالة التطابق' : 'Match Status'),
        _csvQuote(isAr ? 'التفاصيل' : 'Details'),
      ].join(','));

      for (final row in comparisonMatrix) {
        final r = row is Map ? row : {};
        final fieldLabel = isAr ? (r['field_label_ar'] ?? r['field'] ?? '') : (r['field'] ?? '');
        sb.writeln([
          _csvQuote(fieldLabel.toString()),
          _csvQuote((r['system_value'] ?? '—').toString()),
          _csvQuote((r['draft_value'] ?? '—').toString()),
          _csvQuote((r['match_status'] ?? '').toString()),
          _csvQuote((r['details'] ?? '').toString()),
        ].join(','));
      }
    }

    return sb.toString();
  }

  /// Exports and Saves Inspection Certificate CSV / Excel directly to a file chosen by the user
  static Future<String?> saveInspectionCsvToFile({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) async {
    final csv = exportInspectionCsv(
      context: context,
      isArabic: isArabic,
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
      comparisonMatrix: comparisonMatrix,
    );

    final bool isAr = isArabic ?? (context != null && Localizations.localeOf(context).languageCode == 'ar');
    final cleanAcid = acidNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final filename = 'Inspection_Data_${agency}_${cleanAcid.isNotEmpty ? cleanAcid : DateTime.now().millisecondsSinceEpoch}.csv';

    return FileSaveHelper.saveText(
      context: context,
      textContent: csv,
      defaultFileName: filename,
      dialogTitle: isAr ? 'حفظ مسودة شهادة الفحص كجدول بيانات' : 'Save Inspection Spreadsheet',
      allowedExtensions: ['csv', 'xlsx', 'txt'],
      addUtf8Bom: true,
    );
  }

  /// Export TSV data string (tab-delimited with UTF-8 BOM)
  static String exportInspectionTsv({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) {
    final bool isAr = isArabic ?? (context != null && Localizations.localeOf(context).languageCode == 'ar');
    final cocNo = templateData['coc_number'] ?? 'DRAFT-COC';
    final origin = templateData['country_of_origin'] ?? (isAr ? 'غير محدد' : 'UNKNOWN');
    final hsCodes = templateData['hs_code'] ?? '560229';
    final totalVal = templateData['total_value'] ?? (isAr ? 'غير محدد' : 'N/A');
    final importer = templateData['importer_name_and_address'] ?? '';
    final exporter = templateData['exporter_name_and_address'] ?? '';

    final sb = StringBuffer();
    sb.write('\uFEFF');

    // Headers
    sb.writeln('${isAr ? 'الحقل' : 'Field'}\t${isAr ? 'القيمة' : 'Value'}');
    sb.writeln('${isAr ? 'جهة الفحص الدولية' : 'Inspection Agency'}\t${_cleanTsv(agency)}');
    sb.writeln('${isAr ? 'نوع شهادة الفحص' : 'Certificate Type'}\t${_cleanTsv(certType)}');
    sb.writeln('${isAr ? 'رقم درافت الشهادة' : 'Certificate Number'}\t${_cleanTsv(cocNo.toString())}');
    sb.writeln('${isAr ? 'رقم القيد الجمركي المسبق' : 'ACID Number'}\t${_cleanTsv(acidNumber)}');
    sb.writeln('${isAr ? 'اسم المستورد' : 'Importer'}\t${_cleanTsv(importer.toString())}');
    sb.writeln('${isAr ? 'اسم المصدر' : 'Exporter'}\t${_cleanTsv(exporter.toString())}');
    sb.writeln('${isAr ? 'بلد المنشأ' : 'Country of Origin'}\t${_cleanTsv(origin.toString())}');
    sb.writeln('${isAr ? 'بنود التعريفة الجمركية' : 'H.S. Codes'}\t${_cleanTsv(hsCodes.toString())}');
    sb.writeln('${isAr ? 'القيمة الإجمالية المصرح عنها' : 'Total Declared Value'}\t${_cleanTsv(totalVal.toString())}');
    sb.writeln('${isAr ? 'ميناء الوصول' : 'Port of Entry'}\t${_cleanTsv((templateData['port_of_entry'] ?? 'Alexandria').toString())}');
    sb.writeln('${isAr ? 'المواصفات القياسية المصرية' : 'Egyptian Standards Tested'}\t${_cleanTsv(standards.join(' | '))}');
    sb.writeln('${isAr ? 'نتيجة تقييم المطابقة' : 'Conformity Result'}\t${_cleanTsv(isAr ? 'مطابق وصالح للإفراج الجمركي' : 'CONFORMING')}');

    // Line items section if available
    final inspectedItems = (templateData['inspected_items'] as List<dynamic>?) ?? [];
    if (inspectedItems.isNotEmpty) {
      sb.writeln();
      sb.writeln([
        isAr ? 'م' : '#',
        isAr ? 'نوع المنتج' : 'Product Type',
        isAr ? 'بلد المنشأ' : 'Origin',
        isAr ? 'الوصف والماركة والموديل' : 'Description',
        isAr ? 'الكمية' : 'Quantity',
        isAr ? 'المواصفة القياسية المعتمدة' : 'Adopted Standard',
      ].join('\t'));

      for (final item in inspectedItems) {
        final itm = item is Map ? item : {};
        sb.writeln([
          _cleanTsv('${itm['item_no'] ?? ''}'),
          _cleanTsv('${itm['product_type'] ?? ''}'),
          _cleanTsv('${itm['country_of_origin'] ?? ''}'),
          _cleanTsv('${itm['description'] ?? ''}'),
          _cleanTsv('${itm['quantity'] ?? ''}'),
          _cleanTsv('${itm['adopted_standard'] ?? ''}'),
        ].join('\t'));
      }
    }

    // Comparison Matrix if available
    if (comparisonMatrix != null && comparisonMatrix.isNotEmpty) {
      sb.writeln();
      sb.writeln([
        isAr ? 'الحقل' : 'Field',
        isAr ? 'القيمة بالنظام' : 'System Value',
        isAr ? 'القيمة بالدرافت' : 'Draft Value',
        isAr ? 'حالة التطابق' : 'Match Status',
        isAr ? 'التفاصيل' : 'Details',
      ].join('\t'));

      for (final row in comparisonMatrix) {
        final r = row is Map ? row : {};
        final fieldLabel = isAr ? (r['field_label_ar'] ?? r['field'] ?? '') : (r['field'] ?? '');
        sb.writeln([
          _cleanTsv(fieldLabel.toString()),
          _cleanTsv((r['system_value'] ?? '—').toString()),
          _cleanTsv((r['draft_value'] ?? '—').toString()),
          _cleanTsv((r['match_status'] ?? '').toString()),
          _cleanTsv((r['details'] ?? '').toString()),
        ].join('\t'));
      }
    }

    return sb.toString();
  }

  /// Exports and Saves Inspection Certificate TSV directly to a file chosen by the user
  static Future<String?> saveInspectionTsvToFile({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
  }) async {
    final tsv = exportInspectionTsv(
      context: context,
      isArabic: isArabic,
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
      comparisonMatrix: comparisonMatrix,
    );

    final bool isAr = isArabic ?? (context != null && Localizations.localeOf(context).languageCode == 'ar');
    final cleanAcid = acidNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final filename = 'Inspection_TSV_${agency}_${cleanAcid.isNotEmpty ? cleanAcid : DateTime.now().millisecondsSinceEpoch}.tsv';

    return FileSaveHelper.saveText(
      context: context,
      textContent: tsv,
      defaultFileName: filename,
      dialogTitle: isAr ? 'حفظ جدول نصوص فحص الشحنة' : 'Save Inspection TSV File',
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: true,
    );
  }

  /// Builds a comprehensive, human-readable plain-text dossier for clipboard and reporting.
  static String buildDossierText({
    BuildContext? context,
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
    String? overrideReason,
  }) {
    final bool isAr = isArabic ?? (context != null && Localizations.localeOf(context).languageCode == 'ar');
    final cocNo = templateData['coc_number'] ?? 'DRAFT-COC';
    final origin = templateData['country_of_origin'] ?? (isAr ? 'غير محدد' : 'UNKNOWN');
    final hsCodes = templateData['hs_code'] ?? '560229';
    final totalVal = templateData['total_value'] ?? (isAr ? 'غير محدد' : 'N/A');
    final importer = templateData['importer_name_and_address'] ?? '';
    final exporter = templateData['exporter_name_and_address'] ?? '';
    final portOfEntry = templateData['port_of_entry'] ?? (isAr ? 'ميناء الإسكندرية' : 'Alexandria');
    final dateInsp = templateData['date_of_inspection'] ?? DateTime.now().toString().split(' ')[0];

    final sb = StringBuffer();
    sb.writeln('================================================================');
    sb.writeln(isAr ? 'ملف ودوسيه مراجعة واعتماد شهادة الفحص والمطابقة' : 'INSPECTION & CONFORMITY REVIEW DOSSIER');
    sb.writeln('================================================================');
    sb.writeln('${isAr ? 'جهة الفحص الدولية' : 'Inspection Agency'}: $agency');
    sb.writeln('${isAr ? 'نوع الشهادة' : 'Certificate Type'}: $certType');
    sb.writeln('${isAr ? 'رقم الشهادة' : 'Certificate No.'}: $cocNo');
    sb.writeln('${isAr ? 'رقم القيد الجمركي المسبق' : 'ACID Number'}: $acidNumber');
    sb.writeln('${isAr ? 'تاريخ الفحص' : 'Date of Inspection'}: $dateInsp');
    sb.writeln('${isAr ? 'ميناء الوصول' : 'Port of Entry'}: $portOfEntry');
    sb.writeln('${isAr ? 'بلد المنشأ' : 'Country of Origin'}: $origin');
    sb.writeln('${isAr ? 'بنود التعريفة الجمركية' : 'H.S. Codes'}: $hsCodes');
    sb.writeln('${isAr ? 'القيمة الإجمالية المصرح عنها' : 'Total Declared Value'}: $totalVal');
    sb.writeln('----------------------------------------------------------------');
    sb.writeln('${isAr ? 'بيانات المستورد' : 'Importer'}: $importer');
    sb.writeln('${isAr ? 'بيانات المصدر والمنتج' : 'Exporter'}: $exporter');
    sb.writeln('----------------------------------------------------------------');

    // Invoices
    final invoices = (templateData['commercial_invoices'] as List<dynamic>?) ?? [];
    if (invoices.isNotEmpty) {
      sb.writeln(isAr ? 'الفواتير التجارية المرفقة الخاضعة للفحص:' : 'Commercial Invoices Attached:');
      for (final inv in invoices) {
        final i = inv is Map ? inv : {};
        final amt = (i['amount'] is num) ? (i['amount'] as num).toStringAsFixed(2) : (i['amount'] ?? '').toString();
        final curr = (i['currency'] ?? 'EUR').toString();
        final invNum = (i['invoice_number'] ?? '').toString();
        final invDt = (i['invoice_date'] ?? '').toString();
        final inco = (i['incoterm'] ?? 'EXW').toString();
        sb.writeln('  • ${isAr ? 'فاتورة' : 'Invoice'} #$invNum | $amt $curr | $invDt | $inco');
      }
      sb.writeln('----------------------------------------------------------------');
    }

    // Inspected Items
    final inspectedItems = (templateData['inspected_items'] as List<dynamic>?) ?? [];
    if (inspectedItems.isNotEmpty) {
      sb.writeln(isAr ? 'بنود البضائع المفحوصة والمواصفات المعتمدة:' : 'Inspected Line Items:');
      for (final itm in inspectedItems) {
        final item = itm is Map ? itm : {};
        final no = item['item_no'] ?? '';
        final pType = item['product_type'] ?? '';
        final desc = item['description'] ?? '';
        final qty = item['quantity'] ?? '';
        final std = item['adopted_standard'] ?? '';
        sb.writeln('  [$no] $pType - $desc ($qty) -> $std');
      }
      sb.writeln('----------------------------------------------------------------');
    }

    // Standards Tested
    if (standards.isNotEmpty) {
      sb.writeln(isAr ? 'المواصفات القياسية المصرية وبروتوكولات الفحص المعتمدة:' : 'Egyptian Mandatory Standards Tested:');
      for (final std in standards) {
        sb.writeln('  ✔ $std');
      }
      sb.writeln('----------------------------------------------------------------');
    }

    // Discrepancy Matrix
    if (comparisonMatrix != null && comparisonMatrix.isNotEmpty) {
      sb.writeln(isAr ? 'نتائج مصفوفة المقارنة والمطابقة والفروق:' : 'Discrepancy Matrix & Verification Results:');
      for (final row in comparisonMatrix) {
        final r = row is Map ? row : {};
        final label = isAr ? (r['field_label_ar'] ?? r['field'] ?? '') : (r['field'] ?? '');
        final sysVal = r['system_value'] ?? '—';
        final dftVal = r['draft_value'] ?? '—';
        final status = r['match_status'] ?? '';
        final det = r['details'] ?? '';
        sb.writeln('  • $label: [$dftVal] vs [$sysVal] -> $status ($det)');
      }
      sb.writeln('----------------------------------------------------------------');
    }

    // Override Reason
    if (overrideReason != null && overrideReason.trim().isNotEmpty) {
      sb.writeln('${isAr ? 'سبب ومبرر قبول الفروق والاعتماد' : 'Override Justification'}: $overrideReason');
      sb.writeln('----------------------------------------------------------------');
    }

    sb.writeln('${isAr ? 'نتيجة تقييم المطابقة' : 'Assessment Result'}: ${isAr ? 'مطابق وصالح للإفراج الجمركي' : 'CONFORMING & COMPLIANT FOR RELEASE'}');
    sb.writeln(isAr ? 'معتمد رقابياً: الرقابة على الصادرات والواردات وهيئة سلامة الغذاء' : 'Verified: GOEIC / NFSA Egypt');
    sb.writeln('================================================================');

    return sb.toString();
  }

  /// Copies comprehensive dossier to clipboard with feedback
  static Future<void> copyDossierToClipboard(
    BuildContext context, {
    bool? isArabic,
    required Map<String, dynamic> templateData,
    required String agency,
    required String certType,
    required String acidNumber,
    required List<String> standards,
    List<dynamic>? comparisonMatrix,
    String? overrideReason,
  }) async {
    final text = buildDossierText(
      context: context,
      isArabic: isArabic,
      templateData: templateData,
      agency: agency,
      certType: certType,
      acidNumber: acidNumber,
      standards: standards,
      comparisonMatrix: comparisonMatrix,
      overrideReason: overrideReason,
    );

    final l10n = context.l10n;
    await CopyHelper.copy(
      context,
      text,
      customMessage: l10n.copiedDossierSuccess,
    );
  }
}

