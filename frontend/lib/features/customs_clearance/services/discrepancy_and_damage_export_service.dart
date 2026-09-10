import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';

/// Dedicated Export & Dossier Service for Screen 61:
/// Customs Clearance - Discrepancy & Damage Registry.
class DiscrepancyAndDamageExportService {
  static String _cleanTsv(String val) {
    return val.replaceAll('\t', ' ').replaceAll('\r', '').replaceAll('\n', ' ').trim();
  }

  static String _csvQuote(String val) {
    final cleaned = val.replaceAll('\r', '').trim();
    if (cleaned.contains(',') || cleaned.contains('"') || cleaned.contains('\n')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    return cleaned;
  }

  static String getClaimStatusLabel(BuildContext context, String? status) {
    final l = context.l10n;
    if (status == 'APPROVED') {
      return l.discrepancyDamageClaimApproved;
    } else if (status == 'UNDER_REVIEW') {
      return l.discrepancyDamageClaimUnderReview;
    }
    return l.discrepancyDamageClaimSubmitted;
  }

  /// Exports discrepancy & damage protocols as TSV string with UTF-8 BOM
  static String exportDiscrepanciesToTsv(BuildContext context, List<Map<String, dynamic>> protocols) {
    final l = context.l10n;
    final buf = StringBuffer();
    buf.write('\uFEFF'); // UTF-8 BOM

    buf.writeln([
      l.discrepancyDamageColProtocolNo,
      l.discrepancyDamageColDeclarationNo,
      l.discrepancyDamageColContainerNo,
      l.discrepancyDamageColDamageType,
      l.discrepancyDamageColDamagedQty,
      l.discrepancyDamageColEstimatedLoss,
      l.discrepancyDamageColResponsibleParty,
      l.discrepancyDamageColClaimStatus,
      l.discrepancyDamageColDate,
      l.discrepancyDamageColNotes,
    ].join('\t'));

    for (final p in protocols) {
      final statusStr = getClaimStatusLabel(context, p['insurance_claim_status'] as String?);
      final loss = (p['estimated_loss_egp'] as num?)?.toStringAsFixed(2) ?? '0.00';
      buf.writeln([
        _cleanTsv((p['protocol_no'] ?? '').toString()),
        _cleanTsv((p['declaration_no'] ?? '').toString()),
        _cleanTsv((p['container_no'] ?? '').toString()),
        _cleanTsv((p['damage_type'] ?? '').toString()),
        _cleanTsv((p['damaged_qty'] ?? '').toString()),
        _cleanTsv('$loss ${l.discrepancyDamageCurrencyEgp}'),
        _cleanTsv((p['responsible_party'] ?? '').toString()),
        _cleanTsv(statusStr),
        _cleanTsv((p['date'] ?? '').toString()),
        _cleanTsv((p['notes'] ?? '-').toString()),
      ].join('\t'));
    }

    return buf.toString();
  }

  /// Exports discrepancy & damage protocols as CSV string with UTF-8 BOM
  static String exportDiscrepanciesToCsv(BuildContext context, List<Map<String, dynamic>> protocols) {
    final l = context.l10n;
    final buf = StringBuffer();
    buf.write('\uFEFF'); // UTF-8 BOM

    buf.writeln([
      _csvQuote(l.discrepancyDamageColProtocolNo),
      _csvQuote(l.discrepancyDamageColDeclarationNo),
      _csvQuote(l.discrepancyDamageColContainerNo),
      _csvQuote(l.discrepancyDamageColDamageType),
      _csvQuote(l.discrepancyDamageColDamagedQty),
      _csvQuote(l.discrepancyDamageColEstimatedLoss),
      _csvQuote(l.discrepancyDamageColResponsibleParty),
      _csvQuote(l.discrepancyDamageColClaimStatus),
      _csvQuote(l.discrepancyDamageColDate),
      _csvQuote(l.discrepancyDamageColNotes),
    ].join(','));

    for (final p in protocols) {
      final statusStr = getClaimStatusLabel(context, p['insurance_claim_status'] as String?);
      final loss = (p['estimated_loss_egp'] as num?)?.toStringAsFixed(2) ?? '0.00';
      buf.writeln([
        _csvQuote((p['protocol_no'] ?? '').toString()),
        _csvQuote((p['declaration_no'] ?? '').toString()),
        _csvQuote((p['container_no'] ?? '').toString()),
        _csvQuote((p['damage_type'] ?? '').toString()),
        _csvQuote((p['damaged_qty'] ?? '').toString()),
        _csvQuote('$loss ${l.discrepancyDamageCurrencyEgp}'),
        _csvQuote((p['responsible_party'] ?? '').toString()),
        _csvQuote(statusStr),
        _csvQuote((p['date'] ?? '').toString()),
        _csvQuote((p['notes'] ?? '-').toString()),
      ].join(','));
    }

    return buf.toString();
  }

  /// Saves protocols TSV to file
  static Future<void> saveDiscrepanciesTsvToFile(BuildContext context, List<Map<String, dynamic>> protocols) async {
    final l = context.l10n;
    final tsvContent = exportDiscrepanciesToTsv(context, protocols);
    await CopyHelper.copy(context, tsvContent, customMessage: l.discrepancyDamageCopiedTsvSuccess);
    if (!context.mounted) return;

    final filename = 'Discrepancy_Damage_Protocols_${DateTime.now().millisecondsSinceEpoch}.tsv';
    await FileSaveHelper.saveText(
      context: context,
      textContent: tsvContent,
      defaultFileName: filename,
      dialogTitle: l.discrepancyDamageExportTsvBtn,
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: true,
    );
  }

  /// Saves protocols CSV to file
  static Future<void> saveDiscrepanciesCsvToFile(BuildContext context, List<Map<String, dynamic>> protocols) async {
    final l = context.l10n;
    final csvContent = exportDiscrepanciesToCsv(context, protocols);
    await CopyHelper.copy(context, csvContent, customMessage: l.discrepancyDamageCopiedExcelSuccess);
    if (!context.mounted) return;

    final filename = 'Discrepancy_Damage_Protocols_${DateTime.now().millisecondsSinceEpoch}.csv';
    await FileSaveHelper.saveText(
      context: context,
      textContent: csvContent,
      defaultFileName: filename,
      dialogTitle: l.discrepancyDamageExportExcelBtn,
      allowedExtensions: ['csv', 'txt'],
      addUtf8Bom: true,
    );
  }

  /// Builds a complete formatted text dossier for quick copying
  static String buildDiscrepancyDossier({
    required BuildContext context,
    required List<Map<String, dynamic>> protocols,
  }) {
    final l = context.l10n;
    final buf = StringBuffer();

    buf.writeln('================================================================');
    buf.writeln('IMPORTFLOW ERP — ${l.discrepancyDamageScreenTitle}');
    buf.writeln('================================================================');
    buf.writeln(l.discrepancyDamageScreenSubtitle);
    buf.writeln('Timestamp: ${DateTime.now().toString().substring(0, 19)}');
    buf.writeln('----------------------------------------------------------------');

    final totalProtocols = protocols.length;
    final totalLoss = protocols.fold<double>(
      0.0,
      (sum, p) => sum + ((p['estimated_loss_egp'] as num?)?.toDouble() ?? 0.0),
    );
    final submittedClaims = protocols.where((p) => p['insurance_claim_status'] == 'CLAIM_SUBMITTED').length;
    final approvedClaims = protocols.where((p) => p['insurance_claim_status'] == 'APPROVED').length;

    buf.writeln('SUMMARY KPI METRICS:');
    buf.writeln('• ${l.discrepancyDamageKpiTotalProtocols}: $totalProtocols');
    buf.writeln('• ${l.discrepancyDamageKpiTotalLoss}: ${totalLoss.toStringAsFixed(2)} ${l.discrepancyDamageCurrencyEgp}');
    buf.writeln('• ${l.discrepancyDamageKpiClaimsSubmitted}: $submittedClaims');
    buf.writeln('• ${l.discrepancyDamageKpiClaimsApproved}: $approvedClaims');
    buf.writeln('----------------------------------------------------------------');
    buf.writeln('JOINT INSPECTION & DAMAGE PROTOCOLS LEDGER:');
    buf.writeln('----------------------------------------------------------------');

    if (protocols.isEmpty) {
      buf.writeln(l.discrepancyDamageEmptyRecords);
    } else {
      for (int i = 0; i < protocols.length; i++) {
        final p = protocols[i];
        final statusStr = getClaimStatusLabel(context, p['insurance_claim_status'] as String?);
        final loss = (p['estimated_loss_egp'] as num?)?.toStringAsFixed(2) ?? '0.00';

        buf.writeln('[${i + 1}] ${l.discrepancyDamageColProtocolNo}: ${p['protocol_no']}');
        buf.writeln('    • ${l.discrepancyDamageColDeclarationNo}: ${p['declaration_no'] ?? '-'}');
        buf.writeln('    • ${l.discrepancyDamageColContainerNo}: ${p['container_no'] ?? '-'}');
        buf.writeln('    • ${l.discrepancyDamageColDamageType}: ${p['damage_type'] ?? '-'}');
        buf.writeln('    • ${l.discrepancyDamageColDamagedQty}: ${p['damaged_qty'] ?? '-'}');
        buf.writeln('    • ${l.discrepancyDamageColEstimatedLoss}: $loss ${l.discrepancyDamageCurrencyEgp}');
        buf.writeln('    • ${l.discrepancyDamageColResponsibleParty}: ${p['responsible_party'] ?? '-'}');
        buf.writeln('    • ${l.discrepancyDamageColClaimStatus}: $statusStr');
        buf.writeln('    • ${l.discrepancyDamageColDate}: ${p['date'] ?? '-'}');
        if (p['notes'] != null && (p['notes'] as String).trim().isNotEmpty) {
          buf.writeln('    • ${l.discrepancyDamageColNotes}: ${p['notes']}');
        }
        buf.writeln();
      }
    }

    buf.writeln('================================================================');
    buf.writeln('End of Protocol Dossier — Verified by ImportFlow Customs System');
    buf.writeln('================================================================');

    return buf.toString();
  }

  /// Copies full plain text dossier to system clipboard
  static Future<void> copyDossierToClipboard(
    BuildContext context,
    List<Map<String, dynamic>> protocols,
  ) async {
    final l = context.l10n;
    final dossier = buildDiscrepancyDossier(context: context, protocols: protocols);
    await CopyHelper.copy(context, dossier, customMessage: l.discrepancyDamageCopiedDossierSuccess);
  }

  /// Generates and previews a Vector A4 Landscape PDF using Cairo font
  static Future<void> printOrSaveDiscrepancyPdf(
    BuildContext context,
    List<Map<String, dynamic>> protocols,
  ) async {
    final l = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final doc = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4.landscape,
      textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData.withFont(
        base: cairoRegular,
        bold: cairoBold,
      ),
      margin: const pw.EdgeInsets.all(24),
    );

    final totalProtocols = protocols.length;
    final totalLoss = protocols.fold<double>(
      0.0,
      (sum, p) => sum + ((p['estimated_loss_egp'] as num?)?.toDouble() ?? 0.0),
    );
    final submittedClaims = protocols.where((p) => p['insurance_claim_status'] == 'CLAIM_SUBMITTED').length;
    final approvedClaims = protocols.where((p) => p['insurance_claim_status'] == 'APPROVED').length;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey700, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'IMPORTFLOW ERP — Customs Clearance Management',
                style: pw.TextStyle(color: PdfColors.blueGrey800, fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
              ),
            ],
          ),
        ),
        build: (pw.Context ctx) => [
          // Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.red900,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: isAr ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l.discrepancyDamageScreenTitle,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        l.discrepancyDamageScreenSubtitle,
                        style: const pw.TextStyle(color: PdfColors.grey200, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: isAr ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateTime.now().toString().substring(0, 16),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                    pw.Text(
                      'Stage 7: Customs Clearance',
                      style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // KPI Cards Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Text(l.discrepancyDamageKpiTotalProtocols, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('$totalProtocols', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                ]),
                pw.Column(children: [
                  pw.Text(l.discrepancyDamageKpiTotalLoss, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('${totalLoss.toStringAsFixed(2)} ${l.discrepancyDamageCurrencyEgp}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                ]),
                pw.Column(children: [
                  pw.Text(l.discrepancyDamageKpiClaimsSubmitted, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('$submittedClaims', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                ]),
                pw.Column(children: [
                  pw.Text(l.discrepancyDamageKpiClaimsApproved, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('$approvedClaims', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Table Section
          pw.Text(
            l.discrepancyDamageScreenTitle,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(3.0),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(3.0),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(2.8),
              6: const pw.FlexColumnWidth(3.0),
              7: const pw.FlexColumnWidth(2.5),
              8: const pw.FlexColumnWidth(2.0),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                children: [
                  _pdfCell(l.discrepancyDamageColProtocolNo, isHeader: true),
                  _pdfCell(l.discrepancyDamageColDeclarationNo, isHeader: true),
                  _pdfCell(l.discrepancyDamageColContainerNo, isHeader: true),
                  _pdfCell(l.discrepancyDamageColDamageType, isHeader: true),
                  _pdfCell(l.discrepancyDamageColDamagedQty, isHeader: true),
                  _pdfCell(l.discrepancyDamageColEstimatedLoss, isHeader: true),
                  _pdfCell(l.discrepancyDamageColResponsibleParty, isHeader: true),
                  _pdfCell(l.discrepancyDamageColClaimStatus, isHeader: true),
                  _pdfCell(l.discrepancyDamageColDate, isHeader: true),
                ],
              ),
              if (protocols.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(l.discrepancyDamageEmptyRecords, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell(''),
                    _pdfCell(''),
                  ],
                )
              else
                ...protocols.map((p) {
                  final isApproved = p['insurance_claim_status'] == 'APPROVED';
                  final statusStr = getClaimStatusLabel(context, p['insurance_claim_status'] as String?);
                  final loss = (p['estimated_loss_egp'] as num?)?.toStringAsFixed(2) ?? '0.00';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isApproved ? PdfColors.green50 : PdfColors.white,
                    ),
                    children: [
                      _pdfCell((p['protocol_no'] ?? '').toString(), isBold: true, color: PdfColors.red900),
                      _pdfCell((p['declaration_no'] ?? '').toString()),
                      _pdfCell((p['container_no'] ?? '').toString()),
                      _pdfCell((p['damage_type'] ?? '').toString()),
                      _pdfCell((p['damaged_qty'] ?? '').toString()),
                      _pdfCell('$loss ${l.discrepancyDamageCurrencyEgp}', isBold: true, color: PdfColors.red900),
                      _pdfCell((p['responsible_party'] ?? '').toString()),
                      _pdfCell(statusStr, color: isApproved ? PdfColors.green900 : PdfColors.blue800, isBold: true),
                      _pdfCell((p['date'] ?? '').toString()),
                    ],
                  );
                }),
            ],
          ),
          pw.SizedBox(height: 20),

          // Signatures Committee Block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l.discrepancyDamageFieldCommittee,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _signatureBox('ممثل مصلحة الجمارك'),
                    _signatureBox('ممثل التوكيل الملاحي'),
                    _signatureBox('خبير المعاينة والتأمين'),
                    _signatureBox('مسؤول المستودع الجمركي'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Discrepancy_Damage_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _signatureBox(String title) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        color: PdfColors.white,
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 20),
          pw.Container(height: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 2),
          pw.Text('التوقيع والخاتم', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (color ?? PdfColors.black),
        ),
      ),
    );
  }
}
