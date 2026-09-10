import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../models/cargox_model.dart';

class CargoXExportService {
  // ── 1. ENVELOPES TSV EXPORT ───────────────────────────────────────────────
  static String exportEnvelopesToTsv({
    required List<CargoXEnvelopeModel> envelopes,
    required BuildContext context,
  }) {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    // Prepend UTF-8 BOM
    buffer.write('\uFEFF');

    // Column Headers
    final headers = [
      '#',
      l10n.cargoxTsvHeaderEnvelopeCode,
      l10n.cargoxTsvHeaderImportFile,
      l10n.cargoxTsvHeaderAcid,
      l10n.cargoxTsvHeaderSupplier,
      l10n.cargoxTsvHeaderSupplierCargoxId,
      l10n.cargoxTsvHeaderBlNumber,
      l10n.cargoxTsvHeaderStatus,
      l10n.cargoxTsvHeaderDocsCount,
      l10n.cargoxTsvHeaderTxHash,
      l10n.cargoxTsvHeaderCustomsReceipt,
      l10n.cargoxTsvHeaderTransferredAt,
    ];
    buffer.writeln(headers.join('\t'));

    for (int i = 0; i < envelopes.length; i++) {
      final env = envelopes[i];
      final row = [
        '${i + 1}',
        env.envelopeCode,
        env.importFileCode ?? '—',
        env.acidNumber,
        env.supplierName,
        env.supplierCargoxId,
        env.blNumber ?? '—',
        env.status,
        '${env.documents.length}',
        env.blockchainTxHash ?? '—',
        env.customsConfirmationReceipt ?? '—',
        env.transferredToCustomsAt != null
            ? env.transferredToCustomsAt!.toIso8601String().substring(0, 10)
            : '—',
      ];
      buffer.writeln(row.join('\t'));
    }

    return buffer.toString();
  }

  static Future<void> saveEnvelopesTsvToFile({
    required BuildContext context,
    required List<CargoXEnvelopeModel> envelopes,
  }) async {
    final tsvContent = exportEnvelopesToTsv(envelopes: envelopes, context: context);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: tsvContent,
      defaultFileName: 'cargox_envelopes_$timestamp.tsv',
      dialogTitle: context.l10n.cargoxExportTsvDialogTitle,
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: true,
    );
  }

  // ── 2. ENVELOPES CSV / EXCEL EXPORT ───────────────────────────────────────
  static String exportEnvelopesToCsv({
    required List<CargoXEnvelopeModel> envelopes,
    required BuildContext context,
  }) {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    // Prepend UTF-8 BOM
    buffer.write('\uFEFF');

    String escapeCsv(String value) {
      if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
        return '"${value.replaceAll('"', '""')}"';
      }
      return value;
    }

    final headers = [
      '#',
      l10n.cargoxTsvHeaderEnvelopeCode,
      l10n.cargoxTsvHeaderImportFile,
      l10n.cargoxTsvHeaderAcid,
      l10n.cargoxTsvHeaderSupplier,
      l10n.cargoxTsvHeaderSupplierCargoxId,
      l10n.cargoxTsvHeaderBlNumber,
      l10n.cargoxTsvHeaderStatus,
      l10n.cargoxTsvHeaderDocsCount,
      l10n.cargoxTsvHeaderTxHash,
      l10n.cargoxTsvHeaderCustomsReceipt,
      l10n.cargoxTsvHeaderTransferredAt,
    ];
    buffer.writeln(headers.map(escapeCsv).join(','));

    for (int i = 0; i < envelopes.length; i++) {
      final env = envelopes[i];
      final row = [
        '${i + 1}',
        env.envelopeCode,
        env.importFileCode ?? '—',
        env.acidNumber,
        env.supplierName,
        env.supplierCargoxId,
        env.blNumber ?? '—',
        env.status,
        '${env.documents.length}',
        env.blockchainTxHash ?? '—',
        env.customsConfirmationReceipt ?? '—',
        env.transferredToCustomsAt != null
            ? env.transferredToCustomsAt!.toIso8601String().substring(0, 10)
            : '—',
      ];
      buffer.writeln(row.map(escapeCsv).join(','));
    }

    return buffer.toString();
  }

  static Future<void> saveEnvelopesCsvToFile({
    required BuildContext context,
    required List<CargoXEnvelopeModel> envelopes,
  }) async {
    final csvContent = exportEnvelopesToCsv(envelopes: envelopes, context: context);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: csvContent,
      defaultFileName: 'cargox_envelopes_$timestamp.csv',
      dialogTitle: context.l10n.cargoxExportExcelDialogTitle,
      allowedExtensions: ['csv'],
      addUtf8Bom: true,
    );
  }

  // ── 3. VECTOR LANDSCAPE PDF ───────────────────────────────────────────────
  static Future<void> printOrSaveEnvelopesPdf({
    required BuildContext context,
    required List<CargoXEnvelopeModel> envelopes,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = context.l10n;
    final pdf = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final totalCount = envelopes.length;
    final acceptedCount = envelopes.where((e) => e.status == 'ACCEPTED_BY_CUSTOMS').length;
    final inProgressCount = envelopes.where((e) => e.status != 'ACCEPTED_BY_CUSTOMS').length;
    final acidVerifiedCount = envelopes.where((e) => e.isAcidVerified).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        header: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey700, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l10n.cargoxDossierHeader,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2C3E50')),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${l10n.cargoxMetricTotalEnvelopes}: $totalCount | ${l10n.cargoxMetricAcceptedCustoms}: $acceptedCount',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#3498DB'),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'IMPORTFLOW ERP',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        footer: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          margin: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CargoX & ACI Blockchain Dispatch Verification Report',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                '${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (pw.Context ctx) => [
          // KPI Metric Cards
          pw.Row(
            children: [
              _buildPdfMetricBox(l10n.cargoxMetricTotalEnvelopes, '$totalCount', PdfColor.fromHex('#3498DB')),
              pw.SizedBox(width: 8),
              _buildPdfMetricBox(l10n.cargoxMetricAcceptedCustoms, '$acceptedCount', PdfColor.fromHex('#27AE60')),
              pw.SizedBox(width: 8),
              _buildPdfMetricBox(l10n.cargoxMetricInProgress, '$inProgressCount', PdfColor.fromHex('#E67E22')),
              pw.SizedBox(width: 8),
              _buildPdfMetricBox(l10n.cargoxMetricAcidVerified, '$acidVerifiedCount', PdfColor.fromHex('#8E44AD')),
            ],
          ),
          pw.SizedBox(height: 14),

          // Envelopes Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2C3E50')),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 22,
            headers: [
              '#',
              l10n.cargoxTsvHeaderEnvelopeCode,
              l10n.cargoxTsvHeaderImportFile,
              l10n.cargoxTsvHeaderAcid,
              l10n.cargoxTsvHeaderSupplier,
              l10n.cargoxTsvHeaderSupplierCargoxId,
              l10n.cargoxTsvHeaderBlNumber,
              l10n.cargoxTsvHeaderStatus,
              l10n.cargoxTsvHeaderDocsCount,
              l10n.cargoxTsvHeaderTxHash,
              l10n.cargoxTsvHeaderCustomsReceipt,
            ],
            data: envelopes.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final env = entry.value;
              return [
                '$idx',
                env.envelopeCode,
                env.importFileCode ?? '—',
                env.acidNumber,
                env.supplierName,
                env.supplierCargoxId,
                env.blNumber ?? '—',
                env.status,
                '${env.documents.length}',
                env.blockchainTxHash != null && env.blockchainTxHash!.length > 12
                    ? '${env.blockchainTxHash!.substring(0, 12)}...'
                    : (env.blockchainTxHash ?? '—'),
                env.customsConfirmationReceipt ?? '—',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'cargox_envelopes_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildPdfMetricBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: color, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, color: color, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── 4. CLIPBOARD DOSSIER COPY ─────────────────────────────────────────────
  static void copyEnvelopesDossier({
    required BuildContext context,
    required List<CargoXEnvelopeModel> envelopes,
  }) {
    final l10n = context.l10n;
    final buffer = StringBuffer();

    buffer.writeln('================================================================');
    buffer.writeln(l10n.cargoxDossierHeader);
    buffer.writeln('================================================================');
    buffer.writeln('${l10n.cargoxMetricTotalEnvelopes}: ${envelopes.length}');
    buffer.writeln('${l10n.cargoxMetricAcceptedCustoms}: ${envelopes.where((e) => e.status == 'ACCEPTED_BY_CUSTOMS').length}');
    buffer.writeln('${l10n.cargoxMetricAcidVerified}: ${envelopes.where((e) => e.isAcidVerified).length}');
    buffer.writeln('----------------------------------------------------------------');
    buffer.writeln(l10n.cargoxDossierEnvelopesTitle);
    buffer.writeln('----------------------------------------------------------------');

    for (int i = 0; i < envelopes.length; i++) {
      final env = envelopes[i];
      buffer.writeln('[${i + 1}] ${env.envelopeCode} | ${l10n.cargoxTsvHeaderImportFile}: ${env.importFileCode ?? "N/A"}');
      buffer.writeln('     ${l10n.cargoxTsvHeaderAcid}: ${env.acidNumber}');
      buffer.writeln('     ${l10n.cargoxTsvHeaderSupplier}: ${env.supplierName} (${env.supplierCargoxId})');
      buffer.writeln('     ${l10n.cargoxTsvHeaderBlNumber}: ${env.blNumber ?? "N/A"}');
      buffer.writeln('     ${l10n.cargoxTsvHeaderStatus}: ${env.status}');
      if (env.blockchainTxHash != null) {
        buffer.writeln('     ${l10n.cargoxTsvHeaderTxHash}: ${env.blockchainTxHash}');
      }
      if (env.customsConfirmationReceipt != null) {
        buffer.writeln('     ${l10n.cargoxTsvHeaderCustomsReceipt}: ${env.customsConfirmationReceipt}');
      }
      if (env.documents.isNotEmpty) {
        buffer.writeln('     ${l10n.cargoxTsvHeaderDocsCount}: ${env.documents.length} (${env.documents.map((d) => d.docType).join(", ")})');
      }
      buffer.writeln();
    }

    buffer.writeln('================================================================');
    buffer.writeln('Generated via ImportFlow ERP — Compliance Engine');

    CopyHelper.copy(context, buffer.toString(), customMessage: l10n.cargoxCopiedDossierSuccess);
  }

  // ── 5. STANDARD INVOICE SESSIONS EXPORT ───────────────────────────────────
  static String exportSessionsToTsv({
    required List<StandardInvoiceSessionModel> sessions,
    required BuildContext context,
  }) {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    final headers = [
      '#',
      l10n.standardInvoiceColSessionCode,
      l10n.standardInvoiceColFileCode,
      l10n.standardInvoiceColAcid,
      l10n.standardInvoiceColInvoiceNum,
      l10n.standardInvoiceColSupplier,
      l10n.standardInvoiceColTotal,
      l10n.standardInvoiceColItemsCount,
      l10n.standardInvoiceColStatus,
      l10n.standardInvoiceColUpdatedAt,
    ];
    buffer.writeln(headers.join('\t'));

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final row = [
        '${i + 1}',
        s.sessionCode,
        s.importFileCode,
        s.acidNumber ?? '—',
        s.invoiceNumber ?? '—',
        s.exporterName ?? '—',
        '${s.totalAmount.toStringAsFixed(2)} ${s.currencyCode}',
        '${s.lineItemsCount}',
        s.status,
        s.updatedAt.toIso8601String().substring(0, 10),
      ];
      buffer.writeln(row.join('\t'));
    }

    return buffer.toString();
  }

  static Future<void> saveSessionsTsvToFile({
    required BuildContext context,
    required List<StandardInvoiceSessionModel> sessions,
  }) async {
    final tsvContent = exportSessionsToTsv(sessions: sessions, context: context);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: tsvContent,
      defaultFileName: 'standard_invoice_sessions_$timestamp.tsv',
      dialogTitle: context.l10n.cargoxExportTsvDialogTitle,
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: true,
    );
  }

  static String exportSessionsToCsv({
    required List<StandardInvoiceSessionModel> sessions,
    required BuildContext context,
  }) {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    String escapeCsv(String value) {
      if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
        return '"${value.replaceAll('"', '""')}"';
      }
      return value;
    }

    final headers = [
      '#',
      l10n.standardInvoiceColSessionCode,
      l10n.standardInvoiceColFileCode,
      l10n.standardInvoiceColAcid,
      l10n.standardInvoiceColInvoiceNum,
      l10n.standardInvoiceColSupplier,
      l10n.standardInvoiceColTotal,
      l10n.standardInvoiceColItemsCount,
      l10n.standardInvoiceColStatus,
      l10n.standardInvoiceColUpdatedAt,
    ];
    buffer.writeln(headers.map(escapeCsv).join(','));

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final row = [
        '${i + 1}',
        s.sessionCode,
        s.importFileCode,
        s.acidNumber ?? '—',
        s.invoiceNumber ?? '—',
        s.exporterName ?? '—',
        '${s.totalAmount.toStringAsFixed(2)} ${s.currencyCode}',
        '${s.lineItemsCount}',
        s.status,
        s.updatedAt.toIso8601String().substring(0, 10),
      ];
      buffer.writeln(row.map(escapeCsv).join(','));
    }

    return buffer.toString();
  }

  static Future<void> saveSessionsCsvToFile({
    required BuildContext context,
    required List<StandardInvoiceSessionModel> sessions,
  }) async {
    final csvContent = exportSessionsToCsv(sessions: sessions, context: context);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: csvContent,
      defaultFileName: 'standard_invoice_sessions_$timestamp.csv',
      dialogTitle: context.l10n.cargoxExportExcelDialogTitle,
      allowedExtensions: ['csv'],
      addUtf8Bom: true,
    );
  }

  static Future<void> printOrSaveSessionsPdf({
    required BuildContext context,
    required List<StandardInvoiceSessionModel> sessions,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = context.l10n;
    final pdf = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final totalCount = sessions.length;
    final approvedCount = sessions.where((s) => s.status == 'APPROVED').length;
    final underReviewCount = sessions.where((s) => s.status == 'UNDER_REVIEW').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        header: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey700, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l10n.standardInvoiceSessionsDossierHeader,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2C3E50')),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Total: $totalCount | Approved: $approvedCount | Under Review: $underReviewCount',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#3498DB'),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'IMPORTFLOW ERP',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
            ],
          ),
        ),
        build: (pw.Context ctx) => [
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2C3E50')),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 22,
            headers: [
              '#',
              l10n.standardInvoiceColSessionCode,
              l10n.standardInvoiceColFileCode,
              l10n.standardInvoiceColAcid,
              l10n.standardInvoiceColInvoiceNum,
              l10n.standardInvoiceColSupplier,
              l10n.standardInvoiceColTotal,
              l10n.standardInvoiceColItemsCount,
              l10n.standardInvoiceColStatus,
              l10n.standardInvoiceColUpdatedAt,
            ],
            data: sessions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final s = entry.value;
              return [
                '$idx',
                s.sessionCode,
                s.importFileCode,
                s.acidNumber ?? '—',
                s.invoiceNumber ?? '—',
                s.exporterName ?? '—',
                '${s.totalAmount.toStringAsFixed(2)} ${s.currencyCode}',
                '${s.lineItemsCount}',
                s.status,
                s.updatedAt.toIso8601String().substring(0, 10),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'standard_invoice_sessions_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static void copySessionsDossier({
    required BuildContext context,
    required List<StandardInvoiceSessionModel> sessions,
  }) {
    final l10n = context.l10n;
    final buffer = StringBuffer();

    buffer.writeln('================================================================');
    buffer.writeln(l10n.standardInvoiceSessionsDossierHeader);
    buffer.writeln('================================================================');
    buffer.writeln('Total Sessions: ${sessions.length}');
    buffer.writeln('Approved: ${sessions.where((s) => s.status == 'APPROVED').length}');
    buffer.writeln('Under Review: ${sessions.where((s) => s.status == 'UNDER_REVIEW').length}');
    buffer.writeln('Rejected: ${sessions.where((s) => s.status.contains('REJECTED')).length}');
    buffer.writeln('----------------------------------------------------------------');

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      buffer.writeln('[${i + 1}] ${s.sessionCode} | File: ${s.importFileCode} | ACID: ${s.acidNumber ?? "N/A"}');
      buffer.writeln('     Invoice: ${s.invoiceNumber ?? "N/A"} | Supplier: ${s.exporterName ?? "N/A"}');
      buffer.writeln('     Total: ${s.totalAmount.toStringAsFixed(2)} ${s.currencyCode} | Items: ${s.lineItemsCount}');
      buffer.writeln('     Status: ${s.status} | Updated: ${s.updatedAt.toIso8601String().substring(0, 10)}');
      buffer.writeln();
    }

    buffer.writeln('================================================================');
    buffer.writeln('Generated via ImportFlow ERP — Compliance Engine');

    CopyHelper.copy(context, buffer.toString(), customMessage: l10n.standardInvoiceCopiedToClipboard(l10n.standardInvoiceSessionsDossierHeader));
  }
}
