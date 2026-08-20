import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/import_companies/models/import_company_model.dart';
import '../../features/suppliers/models/supplier_model.dart';
import '../../features/external_service_providers/models/partner_model.dart';

class MasterDataExportService {
  // ═══════════════════════════════════════════════════════════════════════════
  // 1. EGYPTIAN IMPORT COMPANIES (الشركات المستوردة)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> printOrSaveImporterPdf(ImportCompanyModel company) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    final vatStatus = company.daysUntilVatExpiry > 0 ? 'سارية (${company.daysUntilVatExpiry} يوم)' : 'منتهية الصلاحية';
    final regStatus = company.daysUntilRegExpiry > 0 ? 'سارٍ (${company.daysUntilRegExpiry} يوم)' : 'منتهي الصلاحية';
    final impStatus = company.daysUntilImporterIdExpiry > 0 ? 'سارية (${company.daysUntilImporterIdExpiry} يوم)' : 'منتهية الصلاحية';

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
                            'Sorour Logistics ERP — بطاقة بيانات الشركة المستوردة',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'وثيقة رسمية ببيانات التسجيل والقيد التجاري والضريبي',
                            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: company.isActive ? PdfColor.fromHex('#27AE60') : PdfColor.fromHex('#C0392B'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          company.isActive ? 'سجل نشط (Active)' : 'غير مفعّل (Inactive)',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Main Details Card
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        company.importerName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromHex('#2C3E50')),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('الدولة: ${company.country.isNotEmpty ? company.country : "جمهورية مصر العربية"}', style: const pw.TextStyle(fontSize: 10))),
                          pw.Expanded(child: pw.Text('العنوان: ${company.address}', style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                      if (company.phone != null || company.email != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Expanded(child: pw.Text('الهاتف: ${company.phone ?? "-"}', style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(child: pw.Text('البريد الإلكتروني: ${company.email ?? "-"}', style: const pw.TextStyle(fontSize: 10))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Registration & Expiry Table
                pw.Text('بيانات القيد والتراخيص الرسمية والرقابية:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#3498DB')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('البيان / المستند الرقابي', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('رقم القيد / التسجيل', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('تاريخ الانتهاء', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('حالة السريان', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('البطاقة الاستيرادية (Importer Card)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(company.importerId, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(company.importerIdExpiry.toIso8601String().split('T')[0], style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(impStatus, style: pw.TextStyle(fontSize: 9, color: company.daysUntilImporterIdExpiry > 0 ? PdfColor.fromHex('#27AE60') : PdfColor.fromHex('#C0392B'), fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('البطاقة الضريبية (VAT / Tax ID)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(company.vatId, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(company.vatIdExpiry.toIso8601String().split('T')[0], style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(vatStatus, style: pw.TextStyle(fontSize: 9, color: company.daysUntilVatExpiry > 0 ? PdfColor.fromHex('#27AE60') : PdfColor.fromHex('#C0392B'), fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('السجل التجاري (Commercial Register)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(company.registrationNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(company.registrationExpiry.toIso8601String().split('T')[0], style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(regStatus, style: pw.TextStyle(fontSize: 9, color: company.daysUntilRegExpiry > 0 ? PdfColor.fromHex('#27AE60') : PdfColor.fromHex('#C0392B'), fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                  ],
                ),

                if (company.notes != null && company.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text('ملاحظات الشركة: ${company.notes}', style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],

                pw.Spacer(),

                // Sign-off
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تاريخ الطباعة: ${DateTime.now().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Sorour Logistics ERP Enterprise System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
      name: 'Importer_${company.importerId}',
    );
  }

  static Future<String?> exportImporterToExcel(BuildContext context, ImportCompanyModel company) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM

    buffer.writeln('Sorour Logistics ERP — بطاقة بيانات الشركة المستوردة');
    buffer.writeln('اسم الشركة المستوردة,"${company.importerName.replaceAll('"', '""')}"');
    buffer.writeln('حالة السجل,${company.isActive ? "نشط" : "غير نشط"}');
    buffer.writeln('الدولة,${company.country}');
    buffer.writeln('العنوان,"${company.address.replaceAll('"', '""')}"');
    buffer.writeln('الهاتف,${company.phone ?? "-"}');
    buffer.writeln('البريد الإلكتروني,${company.email ?? "-"}');
    buffer.writeln('');

    buffer.writeln('--- بيانات القيد والتسجيلات الرسمية ---');
    buffer.writeln('المستند,رقم القيد,تاريخ الانتهاء,الأيام المتبقية,الحالة');
    buffer.writeln('البطاقة الاستيرادية,${company.importerId},${company.importerIdExpiry.toIso8601String().split('T')[0]},${company.daysUntilImporterIdExpiry},${company.daysUntilImporterIdExpiry > 0 ? "سارية" : "منتهية"}');
    buffer.writeln('البطاقة الضريبية,${company.vatId},${company.vatIdExpiry.toIso8601String().split('T')[0]},${company.daysUntilVatExpiry},${company.daysUntilVatExpiry > 0 ? "سارية" : "منتهية"}');
    buffer.writeln('السجل التجاري,${company.registrationNumber},${company.registrationExpiry.toIso8601String().split('T')[0]},${company.daysUntilRegExpiry},${company.daysUntilRegExpiry > 0 ? "سارٍ" : "منتهٍ"}');

    if (company.notes != null && company.notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('الملاحظات,"${company.notes!.replaceAll('"', '""')}"');
    }

    final filename = 'Importer_${company.importerId}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ بيانات الشركة المستوردة بصيغة Excel / CSV',
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

  static String generateImporterWhatsAppText(ImportCompanyModel comp) {
    return '''
*Sorour Logistics ERP — بطاقة الشركة المستوردة*
🏢 *اسم الشركة:* ${comp.importerName}
📍 *العنوان:* ${comp.address}
🇪🇬 *الدولة:* ${comp.country.isNotEmpty ? comp.country : "مصر"}
📞 *الهاتف:* ${comp.phone ?? "-"}
📧 *الإيميل:* ${comp.email ?? "-"}

*📋 بيانات القيد والتراخيص:*
• *البطاقة الاستيرادية:* ${comp.importerId} (انتهاء: ${comp.importerIdExpiry.toIso8601String().split('T')[0]})
• *البطاقة الضريبية:* ${comp.vatId} (انتهاء: ${comp.vatIdExpiry.toIso8601String().split('T')[0]})
• *السجل التجاري:* ${comp.registrationNumber} (انتهاء: ${comp.registrationExpiry.toIso8601String().split('T')[0]})
• *الحالة:* ${comp.isActive ? "✅ نشط" : "❌ غير نشط"}
${comp.notes != null && comp.notes!.isNotEmpty ? "📝 *ملاحظات:* ${comp.notes}\n" : ""}
_تم الإنشاء عبر Sorour Logistics ERP_
'''.trim();
  }

  static String generateImporterEmailSubject(ImportCompanyModel comp) {
    return 'بيانات الشركة المستوردة [${comp.importerId}] - ${comp.importerName}';
  }

  static String generateImporterEmailBody(ImportCompanyModel comp) {
    return '''
تحية طيبة وبعد،،،

مرفق لسيادتكم بيان ببيانات الشركة المستوردة والتراخيص الرقابية المسجلة على النظام:

- اسم الشركة: ${comp.importerName}
- الدولة: ${comp.country.isNotEmpty ? comp.country : "مصر"}
- العنوان: ${comp.address}
- الهاتف: ${comp.phone ?? "-"}
- البريد الإلكتروني: ${comp.email ?? "-"}

بيانات التسجيل والقيد:
- رقم البطاقة الاستيرادية: ${comp.importerId} (تاريخ الانتهاء: ${comp.importerIdExpiry.toIso8601String().split('T')[0]})
- رقم البطاقة الضريبية: ${comp.vatId} (تاريخ الانتهاء: ${comp.vatIdExpiry.toIso8601String().split('T')[0]})
- رقم السجل التجاري: ${comp.registrationNumber} (تاريخ الانتهاء: ${comp.registrationExpiry.toIso8601String().split('T')[0]})
- حالة السجل: ${comp.isActive ? "نشط ومفعّل" : "غير مفعّل"}

شاكرين حسن تعاونكم،،،
فريق العمليات وإدارة الاستيراد
Sorour Logistics ERP
'''.trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. FOREIGN SUPPLIERS (الموردون الأجانب)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> printOrSaveSupplierPdf(SupplierModel supplier) async {
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
                // Header
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
                            'Sorour Logistics ERP — بطاقة تعريف المورد الأجنبي',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Foreign Exporter Profile & Nafeza/CargoX Registration',
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
                          supplier.supplierCode,
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Main Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(supplier.companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('دولة المصدر: ${supplier.foreignExporterCountry} (${supplier.foreignExporterCountryCode.toUpperCase()})', style: const pw.TextStyle(fontSize: 9))),
                          pw.Expanded(child: pw.Text('نوع المورد: ${supplier.supplierType} (${supplier.registrationType})', style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('العنوان: ${supplier.address}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Platforms & Registrations
                pw.Text('بيانات التسجيل في منصات نافذة وكارجو إكس (Nafeza & CargoX):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E67E22')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('المنصة / المعرّف الرقابي', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('القيمة / الكود المسجل', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('معرّف المصدر الأجنبي (Foreign Exporter ID)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(supplier.foreignExporterId, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('معرّف منصة كارجو إكس (CargoX Platform ID)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(supplier.cargoxPlatformId ?? "غير مسجل", style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('التسجيل بالقرار 43 / القائمة البيضاء', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${supplier.registeredDecree43 ? "مسجل بقرار 43" : "غير مسجل"} | ${supplier.whiteListRegistered ? "قائمة بيضاء" : "عادي"} | ${supplier.hasIso ? "حاصل على ISO" : "بدون ISO"}', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Bank Details
                pw.Text('بيانات التحويل البنكي والسويفت (Beneficiary Bank & SWIFT):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8F9F9'),
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('اسم البنك: ${supplier.bankName ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                          pw.Expanded(child: pw.Text('كود السويفت (SWIFT): ${supplier.swiftCode ?? "-"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromHex('#2980B9')))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('رقم الحساب: ${supplier.accountNumber ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                          pw.Expanded(child: pw.Text('IBAN: ${supplier.iban ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Contact & Brands
                pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text('الهاتف: ${supplier.phone ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(child: pw.Text('البريد الإلكتروني: ${supplier.email ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
                if (supplier.brands != null && supplier.brands!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('العلامات التجارية والمنتجات: ${supplier.brands}', style: const pw.TextStyle(fontSize: 9)),
                ],

                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تاريخ الطباعة: ${DateTime.now().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Sorour Logistics ERP Enterprise System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
      name: 'Supplier_${supplier.supplierCode}',
    );
  }

  static Future<String?> exportSupplierToExcel(BuildContext context, SupplierModel supplier) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Sorour Logistics ERP — بطاقة تعريف وبيانات المورد الأجنبي');
    buffer.writeln('كود المورد,${supplier.supplierCode}');
    buffer.writeln('اسم المورد الأجنبي,"${supplier.companyName.replaceAll('"', '""')}"');
    buffer.writeln('دولة المصدر,${supplier.foreignExporterCountry}');
    buffer.writeln('كود الدولة,${supplier.foreignExporterCountryCode}');
    buffer.writeln('نوع المورد,${supplier.supplierType}');
    buffer.writeln('نوع التسجيل,${supplier.registrationType}');
    buffer.writeln('معرّف المصدر (Foreign Exporter ID),${supplier.foreignExporterId}');
    buffer.writeln('معرّف منصة CargoX,${supplier.cargoxPlatformId ?? "-"}');
    buffer.writeln('حالة السجل,${supplier.isActive ? "نشط" : "غير نشط"}');
    buffer.writeln('العنوان,"${supplier.address.replaceAll('"', '""')}"');
    buffer.writeln('الهاتف,${supplier.phone ?? "-"}');
    buffer.writeln('الموبايل,${supplier.mobile ?? "-"}');
    buffer.writeln('البريد الإلكتروني,${supplier.email ?? "-"}');
    buffer.writeln('الموقع الإلكتروني,${supplier.website ?? "-"}');
    buffer.writeln('');

    buffer.writeln('--- بيانات التحويل البنكي والسويفت ---');
    buffer.writeln('اسم البنك,"${(supplier.bankName ?? "-").replaceAll('"', '""')}"');
    buffer.writeln('كود السويفت (SWIFT),${supplier.swiftCode ?? "-"}');
    buffer.writeln('رقم الحساب,${supplier.accountNumber ?? "-"}');
    buffer.writeln('IBAN,${supplier.iban ?? "-"}');
    buffer.writeln('');

    buffer.writeln('--- الامتثال والعلامات التجارية ---');
    buffer.writeln('شهادة ISO,${supplier.hasIso ? "نعم" : "لا"}');
    buffer.writeln('مسجل بقرار 43,${supplier.registeredDecree43 ? "نعم" : "لا"}');
    buffer.writeln('قائمة بيضاء,${supplier.whiteListRegistered ? "نعم" : "لا"}');
    buffer.writeln('العلامات والبراندات,"${(supplier.brands ?? "-").replaceAll('"', '""')}"');

    final filename = 'Supplier_${supplier.supplierCode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ بيانات المورد الأجنبي بصيغة Excel / CSV',
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

  static String generateSupplierWhatsAppText(SupplierModel sup) {
    return '''
*Sorour Logistics ERP — بطاقة المورد الأجنبي*
🏢 *كود المورد:* ${sup.supplierCode}
🌐 *اسم الشركة:* ${sup.companyName}
🌍 *الدولة:* ${sup.foreignExporterCountry} (${sup.foreignExporterCountryCode.toUpperCase()})
🔖 *النوع:* ${sup.supplierType} (${sup.registrationType})
🆔 *معرف المصدر (نافذة):* ${sup.foreignExporterId}
${sup.cargoxPlatformId != null && sup.cargoxPlatformId!.isNotEmpty ? "📦 *CargoX ID:* ${sup.cargoxPlatformId}\n" : ""}
*🏦 بيانات البنك والتحويل:*
• *البنك:* ${sup.bankName ?? "-"}
• *SWIFT:* ${sup.swiftCode ?? "-"}
• *Account / IBAN:* ${sup.iban ?? sup.accountNumber ?? "-"}

*📞 التواصل:*
• *الهاتف:* ${sup.phone ?? sup.mobile ?? "-"}
• *الإيميل:* ${sup.email ?? "-"}
${sup.brands != null && sup.brands!.isNotEmpty ? "🏷️ *البراندات:* ${sup.brands}\n" : ""}
_تم الإنشاء عبر Sorour Logistics ERP_
'''.trim();
  }

  static String generateSupplierEmailSubject(SupplierModel sup) {
    return 'بيانات المورد الأجنبي [${sup.supplierCode}] - ${sup.companyName}';
  }

  static String generateSupplierEmailBody(SupplierModel sup) {
    return '''
تحية طيبة وبعد،،،

مرفق لسيادتكم بطاقة تعريف وبيانات المورد الأجنبي المسجلة على النظام:

- كود المورد: ${sup.supplierCode}
- اسم الشركة: ${sup.companyName}
- الدولة: ${sup.foreignExporterCountry} (${sup.foreignExporterCountryCode})
- نوع المورد: ${sup.supplierType} (${sup.registrationType})
- العنوان: ${sup.address}

بيانات نافذة وكارجو إكس:
- Foreign Exporter ID: ${sup.foreignExporterId}
- CargoX ID: ${sup.cargoxPlatformId ?? "غير مسجل"}

بيانات البنك والتحويلات المالية:
- اسم البنك: ${sup.bankName ?? "-"}
- كود السويفت (SWIFT): ${sup.swiftCode ?? "-"}
- رقم الحساب / IBAN: ${sup.iban ?? sup.accountNumber ?? "-"}

بيانات الاتصال:
- الهاتف: ${sup.phone ?? sup.mobile ?? "-"}
- البريد الإلكتروني: ${sup.email ?? "-"}
- الموقع الإلكتروني: ${sup.website ?? "-"}

شاكرين حسن تعاونكم،،،
فريق العمليات وإدارة الاستيراد
Sorour Logistics ERP
'''.trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. PARTNERS & SERVICE PROVIDERS & BANKS (الشركاء والبنوك ومقدمو الخدمات)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> printOrSavePartnerPdf(PartnerModel partner) async {
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
                // Header
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
                            'Sorour Logistics ERP — بطاقة الشريك ومقدم الخدمات اللوجستية',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Partner & Service Provider Official Profile',
                            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#27AE60'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          partner.partnerCode,
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Main Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(partner.partnerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('التصنيف والخدمات: ${partner.partnerType}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2980B9'), fontSize: 9))),
                          pw.Expanded(child: pw.Text('الدولة: ${partner.country}', style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('العنوان: ${partner.address ?? "-"}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Professional Identifiers
                pw.Text('الرخص والأكواد والبيانات المهنية:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2C3E50'))),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#3498DB')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('البيان الرقابي / المهني', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('القيمة / الكود', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                    if (partner.swiftCode != null && partner.swiftCode!.isNotEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('كود السويفت البنكي (SWIFT Code)', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(partner.swiftCode!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        ],
                      ),
                    if (partner.scacCode != null && partner.scacCode!.isNotEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('كود الخط الملاحي (SCAC Code)', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(partner.scacCode!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        ],
                      ),
                    if (partner.clearanceLicenseNumber != null && partner.clearanceLicenseNumber!.isNotEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('رقم رخصة التخليص الجمركي', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(partner.clearanceLicenseNumber!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        ],
                      ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('السجل التجاري والبطاقة الضريبية', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('س.ت: ${partner.commercialRegister ?? "-"} | ضريبي: ${partner.taxId ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('شروط السداد والحد الائتماني', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('نوع السداد: ${partner.paymentType} | الحد: ${partner.creditLimit} EGP', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Contact Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('بيانات التواصل ومسؤول الحساب:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('المسؤول: ${partner.contactPerson ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                          pw.Expanded(child: pw.Text('الهاتف: ${partner.phone ?? partner.mobile ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Text('البريد الإلكتروني: ${partner.email ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                          pw.Expanded(child: pw.Text('الموقع الإلكتروني: ${partner.website ?? "-"}', style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تاريخ الطباعة: ${DateTime.now().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Sorour Logistics ERP Enterprise System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
      name: 'Partner_${partner.partnerCode}',
    );
  }

  static Future<String?> exportPartnerToExcel(BuildContext context, PartnerModel partner) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Sorour Logistics ERP — بطاقة بيانات الشريك ومقدم الخدمات');
    buffer.writeln('كود الشريك,${partner.partnerCode}');
    buffer.writeln('اسم الشريك / البنك,"${partner.partnerName.replaceAll('"', '""')}"');
    buffer.writeln('تصنيف الخدمات,"${partner.partnerType.replaceAll('"', '""')}"');
    buffer.writeln('الدولة,${partner.country}');
    buffer.writeln('كود السويفت (SWIFT),${partner.swiftCode ?? "-"}');
    buffer.writeln('كود الخط الملاحي (SCAC),${partner.scacCode ?? "-"}');
    buffer.writeln('رقم رخصة التخليص,${partner.clearanceLicenseNumber ?? "-"}');
    buffer.writeln('السجل التجاري,${partner.commercialRegister ?? "-"}');
    buffer.writeln('البطاقة الضريبية,${partner.taxId ?? "-"}');
    buffer.writeln('نوع السداد,${partner.paymentType}');
    buffer.writeln('الحد الائتماني,${partner.creditLimit}');
    buffer.writeln('المسؤول الاتصال,${partner.contactPerson ?? "-"}');
    buffer.writeln('الهاتف,${partner.phone ?? "-"}');
    buffer.writeln('الموبايل,${partner.mobile ?? "-"}');
    buffer.writeln('البريد الإلكتروني,${partner.email ?? "-"}');
    buffer.writeln('الموقع الإلكتروني,${partner.website ?? "-"}');
    buffer.writeln('العنوان,"${(partner.address ?? "-").replaceAll('"', '""')}"');
    buffer.writeln('حالة السجل,${partner.isActive ? "نشط" : "غير نشط"}');

    final filename = 'Partner_${partner.partnerCode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'حفظ بيانات الشريك بصيغة Excel / CSV',
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

  static String generatePartnerWhatsAppText(PartnerModel p) {
    return '''
*Sorour Logistics ERP — بطاقة الشريك ومقدم الخدمات*
🤝 *كود الشريك:* ${p.partnerCode}
🏢 *اسم الشريك:* ${p.partnerName}
📋 *التصنيف:* ${p.partnerType}
🌍 *الدولة:* ${p.country}
${p.swiftCode != null && p.swiftCode!.isNotEmpty ? "🏦 *SWIFT:* ${p.swiftCode}\n" : ""}${p.scacCode != null && p.scacCode!.isNotEmpty ? "🚢 *SCAC:* ${p.scacCode}\n" : ""}${p.clearanceLicenseNumber != null && p.clearanceLicenseNumber!.isNotEmpty ? "📜 *رخصة التخليص:* ${p.clearanceLicenseNumber}\n" : ""}
*📞 بيانات التواصل:*
• *المسؤول:* ${p.contactPerson ?? "-"}
• *الهاتف:* ${p.phone ?? p.mobile ?? "-"}
• *الإيميل:* ${p.email ?? "-"}
• *نوع السداد:* ${p.paymentType} (الحد: ${p.creditLimit} EGP)
• *الحالة:* ${p.isActive ? "✅ نشط" : "❌ غير نشط"}
_تم الإنشاء عبر Sorour Logistics ERP_
'''.trim();
  }

  static String generatePartnerEmailSubject(PartnerModel p) {
    return 'بيانات الشريك / البنك [${p.partnerCode}] - ${p.partnerName}';
  }

  static String generatePartnerEmailBody(PartnerModel p) {
    return '''
تحية طيبة وبعد،،،

مرفق لسيادتكم بطاقة تعريف وبيانات الشريك / مقدم الخدمة المسجل على النظام:

- كود الشريك: ${p.partnerCode}
- اسم الشريك: ${p.partnerName}
- التصنيف: ${p.partnerType}
- الدولة: ${p.country}
- العنوان: ${p.address ?? "-"}

الأكواد والتراخيص:
- كود السويفت: ${p.swiftCode ?? "-"}
- كود الخط الملاحي SCAC: ${p.scacCode ?? "-"}
- ترخيص التخليص: ${p.clearanceLicenseNumber ?? "-"}
- السجل التجاري: ${p.commercialRegister ?? "-"}
- البطاقة الضريبية: ${p.taxId ?? "-"}

بيانات التواصل والائتمان:
- مسؤول الحساب: ${p.contactPerson ?? "-"}
- الهاتف: ${p.phone ?? p.mobile ?? "-"}
- البريد الإلكتروني: ${p.email ?? "-"}
- نوع السداد: ${p.paymentType} (الحد الائتماني: ${p.creditLimit} EGP)

شاكرين حسن تعاونكم،،،
فريق العمليات وإدارة الاستيراد
Sorour Logistics ERP
'''.trim();
  }
}
