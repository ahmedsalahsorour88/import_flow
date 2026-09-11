import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../import_files/models/import_file_model.dart';

/// Item Model for Shipment Inquiry & Historical Cost Ledger
class ShipmentInquiryReportRow {
  final String shipmentName;
  final String importFileCode;
  final String supplierName;
  final String companyName;
  final String itemAndHs;
  final String route;
  final String shippingMode;
  final String incoterm;
  final double freightCost;
  final String currency;
  final String fileDate;

  const ShipmentInquiryReportRow({
    required this.shipmentName,
    required this.importFileCode,
    required this.supplierName,
    required this.companyName,
    required this.itemAndHs,
    required this.route,
    required this.shippingMode,
    required this.incoterm,
    required this.freightCost,
    required this.currency,
    required this.fileDate,
  });

  static ShipmentInquiryReportRow fromImportFile(ImportFileModel file, [AppLocalizations? l]) {
    final hs = file.hsCode?.trim() ?? '';
    final prod = file.productCategory?.trim() ?? '';
    final itemHs = (hs.isNotEmpty && prod.isNotEmpty)
        ? '$prod ($hs)'
        : (hs.isNotEmpty ? hs : (prod.isNotEmpty ? prod : '-'));

    final pol = file.portOfLoading?.trim() ?? '';
    final pod = file.portOfDischarge?.trim() ?? '';
    final polText = pol.isNotEmpty ? pol : '-';
    final podText = pod.isNotEmpty ? pod : '-';
    final routeStr = (pol.isNotEmpty || pod.isNotEmpty) ? '$polText → $podText' : '-';

    final name = file.notes != null && file.notes!.isNotEmpty
        ? (file.notes!.split('\n').first)
        : (file.customFileNumber ?? file.importFileCode);

    return ShipmentInquiryReportRow(
      shipmentName: name,
      importFileCode: file.importFileCode,
      supplierName: file.supplierName,
      companyName: file.companyName,
      itemAndHs: itemHs,
      route: routeStr,
      shippingMode: file.shipmentMode,
      incoterm: file.incotermCode,
      freightCost: file.estimatedCost,
      currency: file.estimatedCostCurrency,
      fileDate: file.fileOpeningDate ?? '',
    );
  }

  String toRowSummary(AppLocalizations l) {
    return [
      '${l.inqColShipmentName}: $shipmentName ($importFileCode)',
      '${l.inqColSupplier}: $supplierName',
      '${l.inqColImporter}: $companyName',
      '${l.inqColItemAndHs}: $itemAndHs',
      '${l.inqColRoute}: $route',
      '${l.inqColShippingMode}: $shippingMode',
      '${l.inqColIncoterm}: $incoterm',
      '${l.inqColFreightCost}: ${freightCost.toStringAsFixed(0)} $currency',
    ].join(' | ');
  }
}

/// Unified Export & Dossier Service for Smart Shipment Inquiry (KB-INQ-013)
class ShipmentInquiryExportService {
  static String _clean(String val) {
    return val.replaceAll('\t', ' ').replaceAll('\r', '').replaceAll('\n', ' ').trim();
  }

  /// 1. Export as TSV with UTF-8 BOM
  static Future<void> exportTsv({
    required BuildContext context,
    required List<ImportFileModel> files,
  }) async {
    final l = context.l10n;
    final buffer = StringBuffer();

    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Header
    buffer.writeln([
      _clean(l.inqColShipmentName),
      _clean(l.inqTsvHeaderFileCode),
      _clean(l.inqColSupplier),
      _clean(l.inqColImporter),
      _clean(l.inqColItemAndHs),
      _clean(l.inqColRoute),
      _clean(l.inqColShippingMode),
      _clean(l.inqColIncoterm),
      _clean(l.inqColFreightCost),
      _clean(l.inqTsvHeaderCurrency),
      _clean(l.inqTsvHeaderDate),
    ].join('\t'));

    // Rows
    for (final f in files) {
      final row = ShipmentInquiryReportRow.fromImportFile(f);
      buffer.writeln([
        _clean(row.shipmentName),
        _clean(row.importFileCode),
        _clean(row.supplierName),
        _clean(row.companyName),
        _clean(row.itemAndHs),
        _clean(row.route),
        _clean(row.shippingMode),
        _clean(row.incoterm),
        row.freightCost.toStringAsFixed(2),
        _clean(row.currency),
        _clean(row.fileDate),
      ].join('\t'));
    }

    final bytes = utf8.encode(buffer.toString());
    await FileSaveHelper.saveBytes(
      context: context,
      bytes: bytes,
      defaultFileName: 'shipment_history_inquiry_${DateTime.now().millisecondsSinceEpoch}.tsv',
      dialogTitle: l.inqExportTsvDialogTitle,
      allowedExtensions: ['tsv', 'txt'],
    );
  }

  /// 2. Export as CSV with RFC-4180 Escaping & UTF-8 BOM
  static Future<void> exportCsv({
    required BuildContext context,
    required List<ImportFileModel> files,
  }) async {
    final l = context.l10n;
    final buffer = StringBuffer();

    // UTF-8 BOM
    buffer.write('\uFEFF');

    String escapeCsv(String field) {
      if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
        return '"${field.replaceAll('"', '""')}"';
      }
      return field;
    }

    // Header
    buffer.writeln([
      escapeCsv(l.inqColShipmentName),
      escapeCsv(l.inqTsvHeaderFileCode),
      escapeCsv(l.inqColSupplier),
      escapeCsv(l.inqColImporter),
      escapeCsv(l.inqColItemAndHs),
      escapeCsv(l.inqColRoute),
      escapeCsv(l.inqColShippingMode),
      escapeCsv(l.inqColIncoterm),
      escapeCsv(l.inqColFreightCost),
      escapeCsv(l.inqTsvHeaderCurrency),
      escapeCsv(l.inqTsvHeaderDate),
    ].join(','));

    // Rows
    for (final f in files) {
      final row = ShipmentInquiryReportRow.fromImportFile(f);
      buffer.writeln([
        escapeCsv(row.shipmentName),
        escapeCsv(row.importFileCode),
        escapeCsv(row.supplierName),
        escapeCsv(row.companyName),
        escapeCsv(row.itemAndHs),
        escapeCsv(row.route),
        escapeCsv(row.shippingMode),
        escapeCsv(row.incoterm),
        row.freightCost.toStringAsFixed(2),
        escapeCsv(row.currency),
        escapeCsv(row.fileDate),
      ].join(','));
    }

    final bytes = utf8.encode(buffer.toString());
    await FileSaveHelper.saveBytes(
      context: context,
      bytes: bytes,
      defaultFileName: 'shipment_history_inquiry_${DateTime.now().millisecondsSinceEpoch}.csv',
      dialogTitle: l.inqExportExcelDialogTitle,
      allowedExtensions: ['csv'],
    );
  }

  /// 3. Print / PDF View: Vector A4 Landscape with Cairo Font
  static Future<void> printPdf({
    required BuildContext context,
    required List<ImportFileModel> files,
    required String filterSummary,
    required String username,
  }) async {
    final l = context.l10n;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final doc = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final totalCount = files.length;
    final totalCost = files.fold<double>(0.0, (sum, item) => sum + item.estimatedCost);
    final avgFreight = totalCount > 0 ? (totalCost / totalCount) : 0.0;
    final now = DateTime.now();
    final nowFormatted =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final rows = files.map((f) => ShipmentInquiryReportRow.fromImportFile(f)).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l.inqReportTitle,
                        style: pw.TextStyle(
                          font: cairoBold,
                          fontSize: 16,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        l.inqPdfSystemBranding,
                        style: pw.TextStyle(
                          font: cairoRegular,
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      l.inqPdfOfficialBadge,
                      style: pw.TextStyle(font: cairoBold, fontSize: 9, color: PdfColors.blue900),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              // Filter Criteria Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Text(
                  '${l.inqPdfFilterCriteria}$filterSummary',
                  style: pw.TextStyle(font: cairoRegular, fontSize: 8.5, color: PdfColors.blue900),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${l.inqReportGeneratedAt}: $nowFormatted | ${l.inqReportGeneratedBy}: $username',
                    style: pw.TextStyle(font: cairoRegular, fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    l.inqPdfPageOf(ctx.pageNumber, ctx.pagesCount),
                    style: pw.TextStyle(font: cairoRegular, fontSize: 7.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            // KPI Summary Row
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(l.inqTotalMatchingShipments, style: pw.TextStyle(font: cairoRegular, fontSize: 8)),
                      pw.Text('$totalCount', style: pw.TextStyle(font: cairoBold, fontSize: 12, color: PdfColors.blue900)),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: PdfColors.grey400),
                  pw.Column(
                    children: [
                      pw.Text(l.inqAverageFreightCost, style: pw.TextStyle(font: cairoRegular, fontSize: 8)),
                      pw.Text(
                        '${avgFreight.toStringAsFixed(0)} ${l.inqCurrencyUsd}',
                        style: pw.TextStyle(font: cairoBold, fontSize: 12, color: PdfColors.teal800),
                      ),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: PdfColors.grey400),
                  pw.Column(
                    children: [
                      pw.Text(l.inqTotalIncurredCost, style: pw.TextStyle(font: cairoRegular, fontSize: 8)),
                      pw.Text(
                        '${totalCost.toStringAsFixed(0)} ${l.inqCurrencyUsd}',
                        style: pw.TextStyle(font: cairoBold, fontSize: 12, color: PdfColors.deepOrange800),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Table of Shipments
            pw.TableHelper.fromTextArray(
              headers: [
                l.inqColShipmentName,
                l.inqColSupplier,
                l.inqColImporter,
                l.inqColItemAndHs,
                l.inqColRoute,
                l.inqColShippingMode,
                l.inqColIncoterm,
                l.inqColFreightCost,
              ],
              data: rows.map((r) {
                return [
                  '${r.shipmentName}\n(${r.importFileCode})',
                  r.supplierName,
                  r.companyName,
                  r.itemAndHs,
                  r.route,
                  r.shippingMode,
                  r.incoterm,
                  '${r.freightCost.toStringAsFixed(0)} ${r.currency}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: cairoBold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2C3E50)),
              headerHeight: 22,
              cellStyle: pw.TextStyle(font: cairoRegular, fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              cellAlignment: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9FAFB),
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'shipment_history_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// 4. Copy Dossier to Clipboard
  static void copyDossier({
    required BuildContext context,
    required List<ImportFileModel> files,
    required String filterSummary,
  }) {
    final l = context.l10n;
    final totalCount = files.length;
    final totalCost = files.fold<double>(0.0, (sum, item) => sum + item.estimatedCost);
    final avgFreight = totalCount > 0 ? (totalCost / totalCount) : 0.0;

    final buffer = StringBuffer();
    buffer.writeln('📋 ${l.inqReportTitle}');
    buffer.writeln('═══════════════════════════════════════════════');
    buffer.writeln('🔍 ${l.inqDossierCriteria}$filterSummary');
    buffer.writeln(
      '📊 ${l.inqDossierKpiSummary(totalCount, "${totalCost.toStringAsFixed(0)} ${l.inqCurrencyUsd}", "${avgFreight.toStringAsFixed(0)} ${l.inqCurrencyUsd}")}',
    );
    buffer.writeln('───────────────────────────────────────────────');

    for (int i = 0; i < files.length; i++) {
      final r = ShipmentInquiryReportRow.fromImportFile(files[i]);
      buffer.writeln('[${i + 1}] ${r.shipmentName} (${r.importFileCode})');
      buffer.writeln('    - ${l.inqDossierRowSupplier}: ${r.supplierName} | ${l.inqDossierRowImporter}: ${r.companyName}');
      buffer.writeln('    - ${l.inqDossierRowItemAndHs}: ${r.itemAndHs}');
      buffer.writeln('    - ${l.inqDossierRowRoute}: ${r.route} | ${l.inqDossierRowShippingMode}: ${r.shippingMode}');
      buffer.writeln('    - ${l.inqDossierRowIncoterm}: ${r.incoterm} | ${l.inqDossierRowFreight}: ${r.freightCost.toStringAsFixed(0)} ${r.currency}');
      buffer.writeln('');
    }

    CopyHelper.copy(context, buffer.toString());
  }
}
