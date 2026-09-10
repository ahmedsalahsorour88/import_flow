import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../models/step_config_model.dart';

/// Dedicated Export & Dossier Service for Screen 67:
/// Lifecycle Steps Risk Classification & Skip Policy Governance Hub.
class StepConfigExportService {
  static String _cleanTsv(String val) {
    return val
        .replaceAll('\t', ' ')
        .replaceAll('\r', '')
        .replaceAll('\n', ' ')
        .trim();
  }

  static String _csvQuote(String val) {
    final cleaned = val.replaceAll('\r', '').trim();
    if (cleaned.contains(',') ||
        cleaned.contains('"') ||
        cleaned.contains('\n')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    return cleaned;
  }

  static String _localizedPolicy(String policy, AppLocalizations l) {
    switch (policy.toLowerCase()) {
      case 'blocked':
        return l.stepConfigPolicyBlocked;
      case 'single_approval':
        return l.stepConfigPolicySingleApproval;
      case 'dual_approval':
        return l.stepConfigPolicyDualApproval;
      default:
        return policy;
    }
  }

  static String _localizedStepName(StepConfigModel cfg, bool isArabic) {
    return isArabic ? cfg.stepNameAr : cfg.stepNameEn;
  }

  static String _localizedPendingRef(bool supported, AppLocalizations l) {
    return supported
        ? l.stepConfigPendingRefAllowed
        : l.stepConfigPendingRefBlocked;
  }

  /// Converts single step configuration to a single-line summary string for clipboard copy
  static String toRowSummary(StepConfigModel cfg, AppLocalizations l,
      {required bool isArabic}) {
    final name = _localizedStepName(cfg, isArabic);
    final policy = _localizedPolicy(cfg.skipPolicy, l);
    final pending = _localizedPendingRef(cfg.supportsPendingReference, l);
    final roles = cfg.approverRoles.join(', ');
    final modified = cfg.lastModifiedBy ?? '-';

    return [
      '${l.stepConfigColPhaseCode}: P${cfg.phaseId}-${cfg.stepCode}',
      '${l.stepConfigColStepName}: $name',
      '${l.stepConfigColSkipPolicy}: $policy',
      '${l.stepConfigColApproverRoles}: $roles',
      '${l.stepConfigColPendingRef}: $pending',
      '${l.stepConfigColReasonCategories}: ${cfg.reasonCategories.length}',
      '${l.stepConfigColLastModified}: $modified',
    ].join(' | ');
  }

  /// Exports step configurations to TSV format with UTF-8 BOM
  static String exportToTsv(List<StepConfigModel> configs, AppLocalizations l,
      {required bool isArabic}) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Headers
    final headers = [
      '#',
      _cleanTsv(l.stepConfigColPhaseCode),
      _cleanTsv(l.stepConfigColStepName),
      _cleanTsv(l.stepConfigColSkipPolicy),
      _cleanTsv(l.stepConfigColApproverRoles),
      _cleanTsv(l.stepConfigColPendingRef),
      _cleanTsv(l.stepConfigColReasonCategories),
      _cleanTsv(l.stepConfigColLastModified),
    ];
    buffer.writeln(headers.join('\t'));

    // Rows
    for (int i = 0; i < configs.length; i++) {
      final c = configs[i];
      final row = [
        '${i + 1}',
        _cleanTsv('P${c.phaseId}-${c.stepCode}'),
        _cleanTsv(_localizedStepName(c, isArabic)),
        _cleanTsv(_localizedPolicy(c.skipPolicy, l)),
        _cleanTsv(c.approverRoles.join(', ')),
        _cleanTsv(_localizedPendingRef(c.supportsPendingReference, l)),
        '${c.reasonCategories.length}',
        _cleanTsv(c.lastModifiedBy ?? '-'),
      ];
      buffer.writeln(row.join('\t'));
    }

    return buffer.toString();
  }

  /// Exports step configurations to CSV format with UTF-8 BOM and RFC 4180 escaping
  static String exportToCsv(List<StepConfigModel> configs, AppLocalizations l,
      {required bool isArabic}) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Headers
    final headers = [
      '#',
      _csvQuote(l.stepConfigColPhaseCode),
      _csvQuote(l.stepConfigColStepName),
      _csvQuote(l.stepConfigColSkipPolicy),
      _csvQuote(l.stepConfigColApproverRoles),
      _csvQuote(l.stepConfigColPendingRef),
      _csvQuote(l.stepConfigColReasonCategories),
      _csvQuote(l.stepConfigColLastModified),
    ];
    buffer.writeln(headers.join(','));

    // Rows
    for (int i = 0; i < configs.length; i++) {
      final c = configs[i];
      final row = [
        '${i + 1}',
        _csvQuote('P${c.phaseId}-${c.stepCode}'),
        _csvQuote(_localizedStepName(c, isArabic)),
        _csvQuote(_localizedPolicy(c.skipPolicy, l)),
        _csvQuote(c.approverRoles.join('; ')),
        _csvQuote(_localizedPendingRef(c.supportsPendingReference, l)),
        '${c.reasonCategories.length}',
        _csvQuote(c.lastModifiedBy ?? '-'),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Saves TSV file and copies TSV to clipboard
  static Future<void> saveTsvToFile(
      BuildContext context, List<StepConfigModel> configs,
      {required bool isArabic}) async {
    final l = context.l10n;
    final tsvData = exportToTsv(configs, l, isArabic: isArabic);
    await CopyHelper.copy(context, tsvData,
        customMessage: l.stepConfigCopiedTsvSuccess);
    if (!context.mounted) return;

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final filename = 'step_configs_export_$timestamp.tsv';

    await FileSaveHelper.saveText(
      context: context,
      textContent: tsvData,
      defaultFileName: filename,
      dialogTitle: l.stepConfigExportTsvBtn,
      allowedExtensions: ['tsv'],
      addUtf8Bom: false,
    );
  }

  /// Saves CSV file and copies CSV to clipboard
  static Future<void> saveCsvToFile(
      BuildContext context, List<StepConfigModel> configs,
      {required bool isArabic}) async {
    final l = context.l10n;
    final csvData = exportToCsv(configs, l, isArabic: isArabic);
    await CopyHelper.copy(context, csvData,
        customMessage: l.stepConfigCopiedExcelSuccess);
    if (!context.mounted) return;

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final filename = 'step_configs_export_$timestamp.csv';

    await FileSaveHelper.saveText(
      context: context,
      textContent: csvData,
      defaultFileName: filename,
      dialogTitle: l.stepConfigExportExcelBtn,
      allowedExtensions: ['csv'],
      addUtf8Bom: false,
    );
  }

  /// Generates a structured multi-line operational dossier text
  static String buildDossier(List<StepConfigModel> configs, AppLocalizations l,
      {required bool isArabic}) {
    final buffer = StringBuffer();
    final totalCount = configs.length;
    final blockedCount = configs.where((c) => c.isBlocked).length;
    final singleCount = configs.where((c) => c.isSingleApproval).length;
    final dualCount = configs.where((c) => c.isDualApproval).length;
    final pendingCount =
        configs.where((c) => c.supportsPendingReference).length;

    buffer.writeln(l.stepConfigDossierHeader);
    buffer.writeln(
        'Generated: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll("T", " ")}');
    buffer.writeln();

    buffer.writeln(l.stepConfigDossierKpiSummary);
    buffer.writeln('• ${l.stepConfigPhaseAll}: $totalCount');
    buffer.writeln('• ${l.stepConfigPolicyBlocked}: $blockedCount');
    buffer.writeln('• ${l.stepConfigPolicySingleApproval}: $singleCount');
    buffer.writeln('• ${l.stepConfigPolicyDualApproval}: $dualCount');
    buffer.writeln('• ${l.stepConfigPendingRefAllowed}: $pendingCount');
    buffer.writeln();

    buffer.writeln(l.stepConfigDossierRecordsDetails);
    for (int i = 0; i < configs.length; i++) {
      final c = configs[i];
      final summary = toRowSummary(c, l, isArabic: isArabic);
      buffer.writeln('${i + 1}. $summary');
    }
    buffer.writeln();
    buffer.writeln(l.stepConfigDossierFooter);

    return buffer.toString();
  }

  /// Copies formatted dossier directly to system clipboard
  static Future<void> copyDossierToClipboard(
      BuildContext context, List<StepConfigModel> configs,
      {required bool isArabic}) async {
    final l = context.l10n;
    final dossier = buildDossier(configs, l, isArabic: isArabic);
    await CopyHelper.copy(context, dossier,
        customMessage: l.stepConfigCopiedDossierSuccess);
  }

  /// Prints or saves a vector A4 PDF using Cairo font with official layout
  static Future<void> printOrSavePdf(
      BuildContext context, List<StepConfigModel> configs,
      {required bool isArabic}) async {
    final l = context.l10n;
    final pdf = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final totalCount = configs.length;
    final blockedCount = configs.where((c) => c.isBlocked).length;
    final singleCount = configs.where((c) => c.isSingleApproval).length;
    final dualCount = configs.where((c) => c.isDualApproval).length;
    final pendingCount =
        configs.where((c) => c.supportsPendingReference).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l.stepConfigPdfTitle,
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    l.stepConfigPdfSubtitle,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.blueGrey600),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                ),
                child: pw.Text(
                  'ImportFlow ERP — Section 10',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // KPI Summary Cards
          pw.Row(
            children: [
              _buildPdfKpiCard(
                label: l.stepConfigPhaseAll,
                value: '$totalCount',
                bgColor: PdfColors.blueGrey50,
                textColor: PdfColors.blueGrey800,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpiCard(
                label: l.stepConfigPolicyBlocked,
                value: '$blockedCount',
                bgColor: PdfColors.red50,
                textColor: PdfColors.red800,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpiCard(
                label: l.stepConfigPolicySingleApproval,
                value: '$singleCount',
                bgColor: PdfColors.orange50,
                textColor: PdfColors.orange800,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpiCard(
                label: l.stepConfigPolicyDualApproval,
                value: '$dualCount',
                bgColor: PdfColors.purple50,
                textColor: PdfColors.purple800,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpiCard(
                label: l.stepConfigPendingRefAllowed,
                value: '$pendingCount',
                bgColor: PdfColors.green50,
                textColor: PdfColors.green800,
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Steps Configuration Table
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              l.stepConfigColPhaseCode,
              l.stepConfigColStepName,
              l.stepConfigColSkipPolicy,
              l.stepConfigColApproverRoles,
              l.stepConfigColPendingRef,
              l.stepConfigColReasonCategories,
              l.stepConfigColLastModified,
            ],
            data: List<List<dynamic>>.generate(configs.length, (idx) {
              final c = configs[idx];
              return [
                '${idx + 1}',
                'P${c.phaseId}-${c.stepCode}',
                _localizedStepName(c, isArabic),
                _localizedPolicy(c.skipPolicy, l),
                c.approverRoles.join(', '),
                _localizedPendingRef(c.supportsPendingReference, l),
                '${c.reasonCategories.length}',
                c.lastModifiedBy ?? '-',
              ];
            }),
            headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2C3E50)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
            },
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          pw.SizedBox(height: 14),

          // Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${l.stepConfigDossierFooter} — ${DateTime.now().toIso8601String().substring(0, 10)}',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.blueGrey400),
              ),
              pw.Text(
                'ImportFlow ERP System',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.blueGrey400),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'step_configs_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildPdfKpiCard({
    required String label,
    required String value,
    required PdfColor bgColor,
    required PdfColor textColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor.shade(0.3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
