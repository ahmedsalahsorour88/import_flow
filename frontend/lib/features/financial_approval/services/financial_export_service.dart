import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/financial_approval_model.dart';

class FinancialExportService {
  /// Generates printable & saveable PDF for Import Budget Approval (BP-013)
  static Future<void> printOrSaveBudgetPdf({
    required ImportBudgetModel budget,
    BudgetPrefillModel? prefill,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    final invForeign = budget.invoiceAmountForeign > 0 ? budget.invoiceAmountForeign : (prefill?.totalInvoiceAmount ?? 0.0);
    final invCurr = budget.invoiceCurrency.isNotEmpty ? budget.invoiceCurrency : (prefill?.invoiceCurrency ?? 'USD');
    final freightForeign = budget.freightCostForeign > 0 ? budget.freightCostForeign : (prefill?.estimatedFreightCost ?? 0.0);
    final freightCurr = budget.freightCurrency.isNotEmpty ? budget.freightCurrency : (prefill?.freightCurrency ?? 'USD');
    final rate = budget.exchangeRate > 0 ? budget.exchangeRate : 50.0;

    final invEgp = budget.invoiceAmountEgp > 0 ? budget.invoiceAmountEgp : (invForeign * rate);
    final freightEgp = budget.freightCostEgp > 0 ? budget.freightCostEgp : (freightForeign * rate);
    final customsEgp = budget.customsDutiesEgp > 0 ? budget.customsDutiesEgp : (prefill?.estimatedCustomsDutiesEgp ?? 0.0);
    final clearanceEgp = budget.clearanceInlandEgp > 0 ? budget.clearanceInlandEgp : (prefill?.estimatedClearanceFeesEgp ?? 0.0);
    final grandTotalEgp = invEgp + freightEgp + customsEgp + clearanceEgp;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#2C3E50'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Sorour Logistics ERP — تقرير اعتماد الميزانية الاستيرادية الشاملة',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'وثيقة رسمية لاعتماد مخصصات الشحنة المالية',
                            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('كود الميزانية: ${budget.budgetCode}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('ملف الشحنة: ${budget.importFileCode ?? (prefill?.importFileCode ?? "-")}', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Info Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8F9F9'),
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('عنوان الميزانية: ${budget.title}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.SizedBox(height: 3),
                          pw.Text('المورد الأجنبي: ${prefill?.supplierName ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('الشرط التجاري: ${prefill?.incoterm ?? "FOB"}', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 3),
                          pw.Text('سعر الصرف التقديري: $rate EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Group 1: Foreign Currency Table
                pw.Text('1. بنود التكلفة بالعملة الأجنبية (Foreign Currency Costs):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#3498DB')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('البند المالي', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('المبلغ بالعملة الأجنبية', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('سعر الصرف', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('المعادل بالجنيه المصري (EGP)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('قيمة الفاتورة التجارية المبدئية (FOB / Invoice)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${invForeign.toStringAsFixed(2)} $invCurr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$rate EGP', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${invEgp.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#27AE60')))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('تكلفة نولون الشحن المقدرة (Freight Cost)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${freightForeign.toStringAsFixed(2)} $freightCurr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$rate EGP', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${freightEgp.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#27AE60')))),
                      ],
                    ),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECF0F1')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('إجمالي مخصصات العملة الأجنبية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${(invForeign + freightForeign).toStringAsFixed(2)} $invCurr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('-', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${(invEgp + freightEgp).toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#27AE60')))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Group 2: Local EGP Table
                pw.Text('2. بنود التكلفة بالعملة المحلية (Local Currency EGP Costs):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E67E22')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('البند المالي', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('جهة التحصيل / المرجع', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('القيمة المعتمدة بالجنيه المصري (EGP)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('الضرائب والرسوم الجمركية و VAT (منصة نافذة)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('مصلحة الجمارك المصرية', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${customsEgp.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#C0392B')))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('أتعاب التخليص الجمركي والنقل والموانئ', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('المستخلص الجمركي والناقل الداخلي', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${clearanceEgp.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#27AE60')))),
                      ],
                    ),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECF0F1')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('إجمالي مخصصات العملة المحلية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('-', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${(customsEgp + clearanceEgp).toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#27AE60')))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // Grand Total Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#27AE60'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'إجمالي الميزانية الاستيرادية الكلية المعتمدة (Total Approved Budget):',
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.Text(
                        '${grandTotalEgp.toStringAsFixed(2)} EGP',
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Sign-off section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('إعداد / مسؤول الاستيراد:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 25),
                        pw.Text('التوقيع: ................................', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('اعتماد / الإدارة المالية:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 25),
                        pw.Text('المدير المالي: ${budget.approvedBy ?? "المعتمد"}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Budget_Approval_${budget.budgetCode}',
    );
  }

  /// Exports Budget Approval to UTF-8 BOM CSV / Excel
  static Future<String?> exportBudgetToExcel({
    required BuildContext context,
    required ImportBudgetModel budget,
    BudgetPrefillModel? prefill,
  }) async {
    final invForeign = budget.invoiceAmountForeign > 0 ? budget.invoiceAmountForeign : (prefill?.totalInvoiceAmount ?? 0.0);
    final invCurr = budget.invoiceCurrency.isNotEmpty ? budget.invoiceCurrency : (prefill?.invoiceCurrency ?? 'USD');
    final freightForeign = budget.freightCostForeign > 0 ? budget.freightCostForeign : (prefill?.estimatedFreightCost ?? 0.0);
    final freightCurr = budget.freightCurrency.isNotEmpty ? budget.freightCurrency : (prefill?.freightCurrency ?? 'USD');
    final rate = budget.exchangeRate > 0 ? budget.exchangeRate : 50.0;

    final invEgp = budget.invoiceAmountEgp > 0 ? budget.invoiceAmountEgp : (invForeign * rate);
    final freightEgp = budget.freightCostEgp > 0 ? budget.freightCostEgp : (freightForeign * rate);
    final customsEgp = budget.customsDutiesEgp > 0 ? budget.customsDutiesEgp : (prefill?.estimatedCustomsDutiesEgp ?? 0.0);
    final clearanceEgp = budget.clearanceInlandEgp > 0 ? budget.clearanceInlandEgp : (prefill?.estimatedClearanceFeesEgp ?? 0.0);
    final grandTotalEgp = invEgp + freightEgp + customsEgp + clearanceEgp;

    final buffer = StringBuffer();
    // UTF-8 BOM for Excel Arabic compatibility
    buffer.write('\uFEFF');

    buffer.writeln('Sorour Logistics ERP — بيان تقرير اعتماد الميزانية الاستيرادية الشاملة');
    buffer.writeln('كود الميزانية,${budget.budgetCode}');
    buffer.writeln('عنوان الميزانية,${budget.title}');
    buffer.writeln('كود ملف الشحنة,${budget.importFileCode ?? (prefill?.importFileCode ?? "-")}');
    buffer.writeln('المورد الأجنبي,${prefill?.supplierName ?? "-"}');
    buffer.writeln('الشرط التجاري,${prefill?.incoterm ?? "FOB"}');
    buffer.writeln('سعر الصرف التقديري,$rate EGP');
    buffer.writeln('حالة الميزانية,${budget.budgetStatus}');
    buffer.writeln('');

    buffer.writeln('--- جدول بنود التكلفة بالعملة الأجنبية ---');
    buffer.writeln('البند المالي,المبلغ بالعملة الأجنبية,العملة,سعر الصرف,المعادل بالجنيه المصري');
    buffer.writeln('قيمة الفواتير المبدئية FOB,$invForeign,$invCurr,$rate,$invEgp');
    buffer.writeln('تكلفة نولون الشحن المقدرة,$freightForeign,$freightCurr,$rate,$freightEgp');
    buffer.writeln('إجمالي العملة الأجنبية,${invForeign + freightForeign},$invCurr,-,${invEgp + freightEgp}');
    buffer.writeln('');

    buffer.writeln('--- جدول بنود التكلفة بالعملة المحلية (الجنيه المصري) ---');
    buffer.writeln('البند المالي,جهة التحصيل,القيمة بالجنيه المصري');
    buffer.writeln('الضرائب والرسوم الجمركية و VAT,مصلحة الجمارك المصرية,$customsEgp');
    buffer.writeln('أتعاب ومصاريف التخليص والنقل والموانئ,المستخلص الجمركي والناقل,$clearanceEgp');
    buffer.writeln('إجمالي العملة المحلية,-,${customsEgp + clearanceEgp}');
    buffer.writeln('');

    buffer.writeln('إجمالي الميزانية الكلية المعتمدة (EGP),,$grandTotalEgp');

    final filename = 'Budget_Approval_${budget.budgetCode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ تقرير اعتماد الميزانية بصيغة Excel / CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (savePath != null && savePath.isNotEmpty) {
      final file = File(savePath.endsWith('.csv') || savePath.endsWith('.xlsx') ? savePath : '$savePath.csv');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      return file.path;
    }
    return null;
  }

  /// Generates printable PDF for a Single Payment Request (BP-012)
  static Future<void> printPaymentRequestPdf({
    required PaymentRequestModel payment,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#2C3E50'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Sorour Logistics ERP — إذن وطلب سداد مالي للمورد الأجنبي',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'مستند رسمي لإصدار التحويلات البنكية والسويفت',
                            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#3498DB'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          payment.paymentCode,
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Main Info Cards
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('عنوان الطلب: ${payment.title}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('ملف الشحنة: ${payment.importFileCode ?? "-"}', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(child: pw.Text('المورد المستفيد: ${payment.beneficiaryName ?? payment.supplierName}', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('طريقة السداد: ${payment.paymentType}', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(child: pw.Text('تاريخ تقديم الطلب: ${payment.requestDate.isNotEmpty ? payment.requestDate : "-"}', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(child: pw.Text('تاريخ الاستحقاق: ${payment.dueDate}', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Financial Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('المبلغ المطلوب بالعملة الأجنبية:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('${payment.requestedAmount.toStringAsFixed(2)} ${payment.currencyCode}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromHex('#2980B9'))),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('سعر الصرف التقديري:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('${payment.exchangeRate.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('المعادل بالجنيه المصري:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('${payment.requestedAmountEgp.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromHex('#27AE60'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Bank Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('بيانات التحويل البنكي للمورد الأجنبي (Beneficiary Bank Details):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                      pw.SizedBox(height: 6),
                      pw.Text('اسم البنك: ${payment.bankName ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('كود السويفت (SWIFT Code): ${payment.swiftCode ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('رقم الحساب / IBAN: ${payment.ibanAccountNo ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                      if (payment.swiftReferenceNo != null && payment.swiftReferenceNo!.isNotEmpty)
                        pw.Text('رقم السويفت المنفذ: ${payment.swiftReferenceNo}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#27AE60'))),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Sign-offs
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('إعداد / مسؤول الاستيراد:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 25),
                        pw.Text('التوقيع: ................................', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('اعتماد / الإدارة المالية والمراجعة:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 25),
                        pw.Text('التوقيع: ................................', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Payment_Request_${payment.paymentCode}',
    );
  }

  /// Exports full Payment Requests List to UTF-8 BOM CSV / Excel
  static Future<String?> exportPaymentRequestsListToExcel({
    required BuildContext context,
    required List<PaymentRequestModel> list,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Sorour Logistics ERP — سجل العمليات المالي وطلبات السداد');
    buffer.writeln('كود الطلب,ملف الشحنة,عنوان الطلب,المورد المستفيد,البنك,السويفت,الحساب/IBAN,طريقة السداد,المبلغ المطلوب,العملة,سعر الصرف,المعادل EGP,تاريخ الطلب,تاريخ الاستحقاق,الحالة,رقم إشعار السويفت');

    for (final p in list) {
      buffer.writeln(
        '${p.paymentCode},'
        '${p.importFileCode ?? (p.importFileId != null ? "IMP-${p.importFileId}" : "-")},'
        '"${p.title.replaceAll('"', '""')}",'
        '"${p.supplierName.replaceAll('"', '""')}",'
        '"${(p.bankName ?? "").replaceAll('"', '""')}",'
        '${p.swiftCode ?? ""},'
        '${p.ibanAccountNo ?? ""},'
        '${p.paymentType},'
        '${p.requestedAmount},'
        '${p.currencyCode},'
        '${p.exchangeRate},'
        '${p.requestedAmountEgp},'
        '${p.requestDate},'
        '${p.dueDate},'
        '${p.status},'
        '${p.swiftReferenceNo ?? ""}',
      );
    }

    final filename = 'Financial_History_Registry_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ سجل العمليات المالي بصيغة Excel / CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (savePath != null && savePath.isNotEmpty) {
      final file = File(savePath.endsWith('.csv') || savePath.endsWith('.xlsx') ? savePath : '$savePath.csv');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      return file.path;
    }
    return null;
  }

  /// Exports full Import Budgets List to UTF-8 BOM CSV / Excel
  static Future<String?> exportBudgetsListToExcel({
    required BuildContext context,
    required List<ImportBudgetModel> list,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Sorour Logistics ERP — سجل اعتمادات الميزانية الاستيرادية');
    buffer.writeln('كود الميزانية,ملف الشحنة,عنوان الميزانية,فاتورة البضاعة (أجنبي),عملة الفاتورة,فاتورة البضاعة (EGP),تكلفة النولون (أجنبي),عملة النولون,تكلفة النولون (EGP),الضرائب والجمارك (EGP),أتعاب التخليص والنقل (EGP),سعر الصرف,إجمالي الميزانية الكلية (EGP),الحالة,المعتمد من,تاريخ الاعتماد');

    for (final b in list) {
      buffer.writeln(
        '${b.budgetCode},'
        '${b.importFileCode ?? (b.importFileId != null ? "IMP-${b.importFileId}" : "-")},'
        '"${b.title.replaceAll('"', '""')}",'
        '${b.invoiceAmountForeign},'
        '${b.invoiceCurrency},'
        '${b.invoiceAmountEgp},'
        '${b.freightCostForeign},'
        '${b.freightCurrency},'
        '${b.freightCostEgp},'
        '${b.customsDutiesEgp},'
        '${b.clearanceInlandEgp},'
        '${b.exchangeRate},'
        '${b.totalBudgetEgp},'
        '${b.budgetStatus},'
        '"${(b.approvedBy ?? "-").replaceAll('"', '""')}",'
        '${b.createdAt}',
      );
    }

    final filename = 'Import_Budgets_Registry_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ سجل الميزانيات الاستيرادية بصيغة Excel / CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (savePath != null && savePath.isNotEmpty) {
      final file = File(savePath.endsWith('.csv') || savePath.endsWith('.xlsx') ? savePath : '$savePath.csv');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      return file.path;
    }
    return null;
  }

  /// Exports a Single Payment Request (BP-012) to UTF-8 BOM CSV / Excel
  static Future<String?> exportSinglePaymentRequestToExcel({
    required BuildContext context,
    required PaymentRequestModel payment,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Sorour Logistics ERP — إذن وطلب سداد مالي للمورد الأجنبي');
    buffer.writeln('كود الطلب,${payment.paymentCode}');
    buffer.writeln('عنوان الطلب,"${payment.title.replaceAll('"', '""')}"');
    buffer.writeln('ملف الشحنة,${payment.importFileCode ?? (payment.importFileId != null ? "IMP-${payment.importFileId}" : "-")}');
    buffer.writeln('المورد المستفيد,"${(payment.beneficiaryName ?? payment.supplierName).replaceAll('"', '""')}"');
    buffer.writeln('طريقة السداد,${payment.paymentType}');
    buffer.writeln('تاريخ تقديم الطلب,${payment.requestDate}');
    buffer.writeln('تاريخ الاستحقاق,${payment.dueDate}');
    buffer.writeln('حالة الطلب,${payment.status}');
    buffer.writeln('');

    buffer.writeln('--- التفاصيل المالية ---');
    buffer.writeln('المبلغ بالعملة الأجنبية,العملة,سعر الصرف,المعادل بالجنيه المصري (EGP)');
    buffer.writeln('${payment.requestedAmount},${payment.currencyCode},${payment.exchangeRate},${payment.requestedAmountEgp}');
    buffer.writeln('');

    buffer.writeln('--- بيانات البنك المستفيد (Beneficiary Bank Details) ---');
    buffer.writeln('اسم البنك,"${(payment.bankName ?? "-").replaceAll('"', '""')}"');
    buffer.writeln('كود السويفت (SWIFT),${payment.swiftCode ?? "-"}');
    buffer.writeln('رقم الحساب / IBAN,${payment.ibanAccountNo ?? "-"}');
    if (payment.swiftReferenceNo != null && payment.swiftReferenceNo!.isNotEmpty) {
      buffer.writeln('رقم السويفت المنفذ,${payment.swiftReferenceNo}');
    }

    final filename = 'Payment_Request_${payment.paymentCode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ إذن طلب السداد بصيغة Excel / CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (savePath != null && savePath.isNotEmpty) {
      final file = File(savePath.endsWith('.csv') || savePath.endsWith('.xlsx') ? savePath : '$savePath.csv');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      return file.path;
    }
    return null;
  }

  static String generatePaymentWhatsAppText(PaymentRequestModel pay) {
    return '''
*Sorour Logistics ERP — إذن وطلب سداد مالي*
📄 *كود الطلب:* ${pay.paymentCode}
🏢 *المورد المستفيد:* ${pay.beneficiaryName ?? pay.supplierName}
📁 *ملف الشحنة:* ${pay.importFileCode ?? (pay.importFileId != null ? "IMP-${pay.importFileId}" : "-")}
📅 *تاريخ الاستحقاق:* ${pay.dueDate}
💵 *المبلغ المطلوب:* ${pay.requestedAmount} ${pay.currencyCode}
💱 *سعر الصرف:* ${pay.exchangeRate} EGP
🇪🇬 *المعادل بالجنيه:* ${pay.requestedAmountEgp.toStringAsFixed(2)} EGP

*🏦 بيانات التحويل البنكي (Bank Details):*
• *اسم البنك:* ${pay.bankName ?? "-"}
• *كود السويفت:* ${pay.swiftCode ?? "-"}
• *رقم الحساب / IBAN:* ${pay.ibanAccountNo ?? "-"}
${pay.swiftReferenceNo != null && pay.swiftReferenceNo!.isNotEmpty ? "• *رقم السويفت:* ${pay.swiftReferenceNo}\n" : ""}
_تم الإنشاء عبر Sorour Logistics ERP_
'''.trim();
  }

  static String generatePaymentEmailSubject(PaymentRequestModel pay) {
    return 'إذن وطلب سداد مالي [${pay.paymentCode}] - ${pay.beneficiaryName ?? pay.supplierName}';
  }

  static String generatePaymentEmailBody(PaymentRequestModel pay) {
    return '''
السادة الإدارة المالية / المحترمين،

تحية طيبة وبعد،،،

نرجو التكرم بالموافقة وتنفيذ التحويل المالي التالي وفقاً لبيانات الشحنة المعتمدة:

- كود طلب السداد: ${pay.paymentCode}
- موضوع الطلب: ${pay.title}
- ملف الشحنة: ${pay.importFileCode ?? (pay.importFileId != null ? "IMP-${pay.importFileId}" : "-")}
- المورد المستفيد: ${pay.beneficiaryName ?? pay.supplierName}
- طريقة السداد: ${pay.paymentType}
- تاريخ الاستحقاق: ${pay.dueDate}

المبالغ المالية:
- المبلغ بالعملة الأجنبية: ${pay.requestedAmount} ${pay.currencyCode}
- سعر الصرف التقديري: ${pay.exchangeRate} EGP
- المعادل بالجنيه المصري: ${pay.requestedAmountEgp.toStringAsFixed(2)} EGP

بيانات البنك المستفيد (Beneficiary Bank Details):
- اسم البنك: ${pay.bankName ?? "-"}
- كود السويفت (SWIFT): ${pay.swiftCode ?? "-"}
- رقم الحساب / IBAN: ${pay.ibanAccountNo ?? "-"}

شاكرين حسن تعاونكم،،،
فريق العمليات والاستيراد
Sorour Logistics ERP
'''.trim();
  }

  static String generateBudgetWhatsAppText(ImportBudgetModel bgt, [BudgetPrefillModel? prefill]) {
    final invForeign = bgt.invoiceAmountForeign > 0 ? bgt.invoiceAmountForeign : (prefill?.totalInvoiceAmount ?? 0.0);
    final invCurr = bgt.invoiceCurrency.isNotEmpty ? bgt.invoiceCurrency : (prefill?.invoiceCurrency ?? 'USD');
    final freightForeign = bgt.freightCostForeign > 0 ? bgt.freightCostForeign : (prefill?.estimatedFreightCost ?? 0.0);
    final freightCurr = bgt.freightCurrency.isNotEmpty ? bgt.freightCurrency : (prefill?.freightCurrency ?? 'USD');
    final rate = bgt.exchangeRate > 0 ? bgt.exchangeRate : 50.0;

    final invEgp = bgt.invoiceAmountEgp > 0 ? bgt.invoiceAmountEgp : (invForeign * rate);
    final freightEgp = bgt.freightCostEgp > 0 ? bgt.freightCostEgp : (freightForeign * rate);
    final customsEgp = bgt.customsDutiesEgp > 0 ? bgt.customsDutiesEgp : (prefill?.estimatedCustomsDutiesEgp ?? 0.0);
    final clearanceEgp = bgt.clearanceInlandEgp > 0 ? bgt.clearanceInlandEgp : (prefill?.estimatedClearanceFeesEgp ?? 0.0);
    final grandTotalEgp = invEgp + freightEgp + customsEgp + clearanceEgp;

    return '''
*Sorour Logistics ERP — تقرير اعتماد الميزانية الاستيرادية الشاملة*
📊 *كود الميزانية:* ${bgt.budgetCode}
📁 *ملف الشحنة:* ${bgt.importFileCode ?? (prefill?.importFileCode ?? "-")}
🏢 *المورد الأجنبي:* ${prefill?.supplierName ?? "-"}
💼 *الشرط التجاري:* ${prefill?.incoterm ?? "FOB"}
💱 *سعر الصرف التقديري:* $rate EGP

*💵 بنود التكلفة بالعملة الأجنبية:*
• الفاتورة FOB: ${invForeign.toStringAsFixed(2)} $invCurr (${invEgp.toStringAsFixed(2)} EGP)
• نولون الشحن: ${freightForeign.toStringAsFixed(2)} $freightCurr (${freightEgp.toStringAsFixed(2)} EGP)

*🇪🇬 بنود التكلفة بالعملة المحلية:*
• الجمارك و VAT (نافذة): ${customsEgp.toStringAsFixed(2)} EGP
• التخليص والنقل الداخلي: ${clearanceEgp.toStringAsFixed(2)} EGP

*🏆 إجمالي الميزانية المعتمدة الشاملة:*
${grandTotalEgp.toStringAsFixed(2)} EGP

_تم الإنشاء عبر Sorour Logistics ERP_
'''.trim();
  }

  static String generateBudgetEmailSubject(ImportBudgetModel bgt) {
    return 'اعتماد الميزانية الاستيرادية الشاملة [${bgt.budgetCode}] - ${bgt.title}';
  }

  static String generateBudgetEmailBody(ImportBudgetModel bgt, BudgetPrefillModel? prefill) {
    final invForeign = bgt.invoiceAmountForeign > 0 ? bgt.invoiceAmountForeign : (prefill?.totalInvoiceAmount ?? 0.0);
    final invCurr = bgt.invoiceCurrency.isNotEmpty ? bgt.invoiceCurrency : (prefill?.invoiceCurrency ?? 'USD');
    final freightForeign = bgt.freightCostForeign > 0 ? bgt.freightCostForeign : (prefill?.estimatedFreightCost ?? 0.0);
    final freightCurr = bgt.freightCurrency.isNotEmpty ? bgt.freightCurrency : (prefill?.freightCurrency ?? 'USD');
    final rate = bgt.exchangeRate > 0 ? bgt.exchangeRate : 50.0;

    final invEgp = bgt.invoiceAmountEgp > 0 ? bgt.invoiceAmountEgp : (invForeign * rate);
    final freightEgp = bgt.freightCostEgp > 0 ? bgt.freightCostEgp : (freightForeign * rate);
    final customsEgp = bgt.customsDutiesEgp > 0 ? bgt.customsDutiesEgp : (prefill?.estimatedCustomsDutiesEgp ?? 0.0);
    final clearanceEgp = bgt.clearanceInlandEgp > 0 ? bgt.clearanceInlandEgp : (prefill?.estimatedClearanceFeesEgp ?? 0.0);
    final grandTotalEgp = invEgp + freightEgp + customsEgp + clearanceEgp;

    return '''
السادة الإدارة العليا والمالية / المحترمين،

تحية طيبة وبعد،،،

نرفع لسيادتكم بيان تقرير اعتماد الميزانية التقديرية الشاملة لملف الشحنة الاستيرادية:

بيانات الشحنة والميزانية:
- كود الميزانية: ${bgt.budgetCode}
- موضوع الميزانية: ${bgt.title}
- كود ملف الشحنة: ${bgt.importFileCode ?? (prefill?.importFileCode ?? "-")}
- المورد الأجنبي: ${prefill?.supplierName ?? "-"}
- الشرط التجاري (Incoterms): ${prefill?.incoterm ?? "FOB"}
- سعر الصرف التقديري: $rate EGP

أولاً: مخصصات العملة الأجنبية:
- قيمة الفاتورة التجارية (FOB): ${invForeign.toStringAsFixed(2)} $invCurr (المعادل: ${invEgp.toStringAsFixed(2)} EGP)
- تكلفة النولون والشحن البحري/الجوي: ${freightForeign.toStringAsFixed(2)} $freightCurr (المعادل: ${freightEgp.toStringAsFixed(2)} EGP)

ثانياً: مخصصات العملة المحلية (الجنيه المصري):
- الرسوم الجمركية والضرائب و VAT: ${customsEgp.toStringAsFixed(2)} EGP
- أتعاب التخليص الجمركي والنقل والموانئ: ${clearanceEgp.toStringAsFixed(2)} EGP

الإجمالي الكلي للميزانية المعتمدة: ${grandTotalEgp.toStringAsFixed(2)} EGP

شاكرين حسن تعاونكم،،،
فريق العمليات وإدارة الاستيراد
Sorour Logistics ERP
'''.trim();
  }

  static Future<void> launchUrlNative(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url.replaceAll('&', '^&')], runInShell: true);
      }
    } catch (e) {
      debugPrint('Error launching native URL: $e');
    }
  }
}
