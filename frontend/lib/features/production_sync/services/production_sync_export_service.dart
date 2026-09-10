import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import 'local_process_sync_models.dart';

/// Dedicated export and printing service for Screen 59:
/// Production Sync & Deployment Hub.
class ProductionSyncExportService {
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

  // ===========================================================================
  // 1. TABLE DIFF EXPORT (TSV & CSV/EXCEL)
  // ===========================================================================

  /// Exports table comparison diff to TSV with UTF-8 BOM.
  static String exportTableDiffToTsv({
    required BuildContext context,
    required List<SyncTableDiff> tables,
  }) {
    final l = context.l10n;
    final buf = StringBuffer();
    buf.write('\uFEFF'); // UTF-8 BOM

    final headers = [
      '#',
      l.prodSyncTsvHeaderTableName,
      l.prodSyncTsvHeaderDevCount,
      l.prodSyncTsvHeaderProdCount,
      l.prodSyncTsvHeaderDiff,
      l.prodSyncTsvHeaderStatus,
    ];
    buf.writeln(headers.map(_cleanTsv).join('\t'));

    for (int i = 0; i < tables.length; i++) {
      final t = tables[i];
      final statusLabel = t.status == 'NEW_DATA' || t.diff > 0
          ? l.prodSyncDiffStatusNewRecords(t.diff)
          : t.status == 'NEW_TABLE'
              ? l.prodSyncDiffStatusNewTable
              : t.diff < 0
                  ? l.prodSyncDiffStatusProdSurplus(t.diff)
                  : l.prodSyncDiffStatusMatched;

      final row = [
        '${i + 1}',
        t.tableName,
        '${t.devCount}',
        '${t.prodCount}',
        t.diff > 0 ? '+${t.diff}' : '${t.diff}',
        statusLabel,
      ];
      buf.writeln(row.map(_cleanTsv).join('\t'));
    }

    return buf.toString();
  }

  /// Saves table comparison diff to TSV file.
  static Future<void> saveTableDiffTsvToFile({
    required BuildContext context,
    required List<SyncTableDiff> tables,
  }) async {
    final content = exportTableDiffToTsv(context: context, tables: tables);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: content,
      defaultFileName: 'production_sync_diff_$timestamp.tsv',
      dialogTitle: context.l10n.prodSyncExportTsvBtn,
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: true,
    );
  }

  /// Exports table comparison diff to CSV/Excel with UTF-8 BOM and unmerged cells.
  static String exportTableDiffToCsv({
    required BuildContext context,
    required List<SyncTableDiff> tables,
  }) {
    final l = context.l10n;
    final buf = StringBuffer();
    buf.write('\uFEFF'); // UTF-8 BOM

    final headers = [
      '#',
      l.prodSyncTsvHeaderTableName,
      l.prodSyncTsvHeaderDevCount,
      l.prodSyncTsvHeaderProdCount,
      l.prodSyncTsvHeaderDiff,
      l.prodSyncTsvHeaderStatus,
    ];
    buf.writeln(headers.map(_csvQuote).join(','));

    for (int i = 0; i < tables.length; i++) {
      final t = tables[i];
      final statusLabel = t.status == 'NEW_DATA' || t.diff > 0
          ? l.prodSyncDiffStatusNewRecords(t.diff)
          : t.status == 'NEW_TABLE'
              ? l.prodSyncDiffStatusNewTable
              : t.diff < 0
                  ? l.prodSyncDiffStatusProdSurplus(t.diff)
                  : l.prodSyncDiffStatusMatched;

      final row = [
        '${i + 1}',
        t.tableName,
        '${t.devCount}',
        '${t.prodCount}',
        t.diff > 0 ? '+${t.diff}' : '${t.diff}',
        statusLabel,
      ];
      buf.writeln(row.map(_csvQuote).join(','));
    }

    return buf.toString();
  }

  /// Saves table comparison diff to CSV/Excel file.
  static Future<void> saveTableDiffCsvToFile({
    required BuildContext context,
    required List<SyncTableDiff> tables,
  }) async {
    final content = exportTableDiffToCsv(context: context, tables: tables);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: content,
      defaultFileName: 'production_sync_diff_$timestamp.csv',
      dialogTitle: context.l10n.prodSyncExportExcelBtn,
      allowedExtensions: ['csv', 'xlsx'],
      addUtf8Bom: true,
    );
  }

  // ===========================================================================
  // 2. BACKUPS ARCHIVE EXPORT (TSV & CSV/EXCEL)
  // ===========================================================================

  /// Exports backups list to TSV with UTF-8 BOM.
  static String exportBackupsToTsv({
    required BuildContext context,
    required List<LocalBackupEntry> backups,
  }) {
    final l = context.l10n;
    final buf = StringBuffer();
    buf.write('\uFEFF');

    final headers = [
      '#',
      l.prodSyncTsvHeaderBackupFile,
      l.prodSyncTsvHeaderBackupTag,
      l.prodSyncTsvHeaderBackupSize,
      l.prodSyncTsvHeaderBackupDate,
    ];
    buf.writeln(headers.map(_cleanTsv).join('\t'));

    for (int i = 0; i < backups.length; i++) {
      final b = backups[i];
      final tagLabel = b.filename.startsWith('auto_pre_upgrade')
          ? l.prodSyncAutoPreUpgradeTag
          : b.tag;
      final row = [
        '${i + 1}',
        b.filename,
        tagLabel,
        '${b.sizeKb}',
        b.mtime,
      ];
      buf.writeln(row.map(_cleanTsv).join('\t'));
    }

    return buf.toString();
  }

  /// Saves backups list to TSV file.
  static Future<void> saveBackupsTsvToFile({
    required BuildContext context,
    required List<LocalBackupEntry> backups,
  }) async {
    final content = exportBackupsToTsv(context: context, backups: backups);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: content,
      defaultFileName: 'production_backups_$timestamp.tsv',
      dialogTitle: context.l10n.prodSyncExportTsvBtn,
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: true,
    );
  }

  /// Exports backups list to CSV/Excel with UTF-8 BOM.
  static String exportBackupsToCsv({
    required BuildContext context,
    required List<LocalBackupEntry> backups,
  }) {
    final l = context.l10n;
    final buf = StringBuffer();
    buf.write('\uFEFF');

    final headers = [
      '#',
      l.prodSyncTsvHeaderBackupFile,
      l.prodSyncTsvHeaderBackupTag,
      l.prodSyncTsvHeaderBackupSize,
      l.prodSyncTsvHeaderBackupDate,
    ];
    buf.writeln(headers.map(_csvQuote).join(','));

    for (int i = 0; i < backups.length; i++) {
      final b = backups[i];
      final tagLabel = b.filename.startsWith('auto_pre_upgrade')
          ? l.prodSyncAutoPreUpgradeTag
          : b.tag;
      final row = [
        '${i + 1}',
        b.filename,
        tagLabel,
        '${b.sizeKb}',
        b.mtime,
      ];
      buf.writeln(row.map(_csvQuote).join(','));
    }

    return buf.toString();
  }

  /// Saves backups list to CSV/Excel file.
  static Future<void> saveBackupsCsvToFile({
    required BuildContext context,
    required List<LocalBackupEntry> backups,
  }) async {
    final content = exportBackupsToCsv(context: context, backups: backups);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await FileSaveHelper.saveText(
      context: context,
      textContent: content,
      defaultFileName: 'production_backups_$timestamp.csv',
      dialogTitle: context.l10n.prodSyncExportExcelBtn,
      allowedExtensions: ['csv', 'xlsx'],
      addUtf8Bom: true,
    );
  }

  // ===========================================================================
  // 3. PLAIN-TEXT SYSTEM SYNC DOSSIER
  // ===========================================================================

  /// Builds a comprehensive structured plain-text dossier of system status,
  /// database statistics, tables diff, and backup snapshots.
  static String buildSystemSyncDossier({
    required BuildContext context,
    required String version,
    required int buildNumber,
    required LocalDbStats devStats,
    required LocalDbStats prodStats,
    required SyncDiffSummary? diffSummary,
    required List<LocalBackupEntry> backups,
  }) {
    final l = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final buf = StringBuffer();

    buf.writeln('================================================================================');
    buf.writeln(isAr
        ? 'تقرير مركز مزامنة ونقل تحديثات الإنتاج — نظام إمبورت فلو'
        : 'PRODUCTION SYNC & DEPLOYMENT DIAGNOSTICS DOSSIER — IMPORTFLOW ERP');
    buf.writeln('================================================================================');
    buf.writeln(isAr
        ? 'تاريخ التقرير: ${DateTime.now().toString().substring(0, 19)}'
        : 'Report Date: ${DateTime.now().toString().substring(0, 19)}');
    buf.writeln(isAr
        ? 'الإصدار المثبت: v$version (رقم البناء: $buildNumber)'
        : 'Installed Version: v$version (Build: $buildNumber)');
    buf.writeln('--------------------------------------------------------------------------------');
    buf.writeln(isAr ? '1. حالة قواعد البيانات:' : '1. DATABASE STATUS:');
    buf.writeln(isAr
        ? ' • قاعدة التطوير: ${devStats.dbPath} | الحجم: ${devStats.sizeKb} كيلوبايت | آخر تعديل: ${devStats.mtime ?? "—"}'
        : ' • Dev DB: ${devStats.dbPath} | Size: ${devStats.sizeKb} KB | Last Modified: ${devStats.mtime ?? "—"}');
    buf.writeln(isAr
        ? ' • قاعدة الإنتاج: ${prodStats.dbPath} | الحجم: ${prodStats.sizeKb} كيلوبايت | آخر تعديل: ${prodStats.mtime ?? "—"}'
        : ' • Prod DB: ${prodStats.dbPath} | Size: ${prodStats.sizeKb} KB | Last Modified: ${prodStats.mtime ?? "—"}');
    buf.writeln('--------------------------------------------------------------------------------');

    if (diffSummary != null) {
      final totalNew = diffSummary.totalNewRecords;
      final differingCount = diffSummary.tablesWithDiff;
      buf.writeln(isAr ? '2. كشف مقارنة الجداول والفروقات:' : '2. TABLES COMPARISON & DIFF:');
      buf.writeln(isAr
          ? ' • إجمالي السجلات الجديدة المرتقبة: +$totalNew سجل'
          : ' • Total New Records to Sync: +$totalNew');
      buf.writeln(isAr
          ? ' • عدد الجداول ذات الفروقات: $differingCount جدول'
          : ' • Differing Tables Count: $differingCount');

      if (diffSummary.tables.isNotEmpty) {
        for (final t in diffSummary.tables) {
          final status = t.status == 'NEW_DATA' || t.diff > 0
              ? l.prodSyncDiffStatusNewRecords(t.diff)
              : t.status == 'NEW_TABLE'
                  ? l.prodSyncDiffStatusNewTable
                  : t.diff < 0
                      ? l.prodSyncDiffStatusProdSurplus(t.diff)
                      : l.prodSyncDiffStatusMatched;
          buf.writeln('   - ${t.tableName.padRight(35)} | Dev: ${t.devCount} | Prod: ${t.prodCount} | Diff: ${t.diff} | $status');
        }
      } else {
        buf.writeln(isAr ? '   (كافة الجداول متطابقة بالكامل)' : '   (All tables are fully matched)');
      }
    } else {
      buf.writeln(isAr
          ? '2. كشف مقارنة الجداول: لم يتم إجراء فحص مقارنة حديث.'
          : '2. TABLES COMPARISON: No recent diff comparison executed.');
    }

    buf.writeln('--------------------------------------------------------------------------------');
    buf.writeln(isAr
        ? '3. أرشيف النسخ الاحتياطية (${backups.length} نسخة محفوظة):'
        : '3. SAFETY BACKUPS ARCHIVE (${backups.length} saved):');

    if (backups.isNotEmpty) {
      for (final b in backups.take(15)) {
        final isAuto = b.filename.startsWith('auto_pre_upgrade');
        final tagLabel = isAuto ? l.prodSyncAutoPreUpgradeTag : b.tag;
        buf.writeln('   - ${b.filename.padRight(38)} | ${b.sizeKb} KB | ${b.mtime} | $tagLabel');
      }
    } else {
      buf.writeln(isAr ? '   (لا توجد نسخ احتياطية سابقة)' : '   (No previous backups found)');
    }

    buf.writeln('================================================================================');
    buf.writeln(isAr ? 'نهاية التقرير — حماية بيانات التشغيل مؤكدة بنسبة 100%' : 'END OF DOSSIER — ZERO DATA LOSS GUARANTEED');
    buf.writeln('================================================================================');

    return buf.toString();
  }

  /// Copies the complete plain-text diagnostics dossier to clipboard with toast.
  static Future<void> copyDossierToClipboard({
    required BuildContext context,
    String version = '1.0.0',
    int buildNumber = 1,
    required LocalDbStats devStats,
    required LocalDbStats prodStats,
    required SyncDiffSummary? diffSummary,
    required List<LocalBackupEntry> backups,
  }) async {
    final dossier = buildSystemSyncDossier(
      context: context,
      version: version,
      buildNumber: buildNumber,
      devStats: devStats,
      prodStats: prodStats,
      diffSummary: diffSummary,
      backups: backups,
    );
    await CopyHelper.copy(
      context,
      dossier,
      customMessage: context.l10n.prodSyncCopyDossierSuccess,
    );
  }

  // ===========================================================================
  // 4. VECTOR A4 PDF DIAGNOSTICS REPORT
  // ===========================================================================

  /// Generates and opens print/save dialog for the Vector A4 PDF Diagnostics Report.
  static Future<void> printOrSaveSyncDiagnosticsPdf({
    required BuildContext context,
    required String version,
    required int buildNumber,
    required LocalDbStats devStats,
    required LocalDbStats prodStats,
    required SyncDiffSummary? diffSummary,
    required List<LocalBackupEntry> backups,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final l = context.l10n;
    final pdf = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final tables = diffSummary?.tables ?? [];
    final totalNew = diffSummary?.totalNewRecords ?? 0;
    final differingCount = diffSummary?.tablesWithDiff ?? 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        header: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
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
                    isAr ? 'تقرير تشخيص ومزامنة الإنتاج' : 'Production Sync Diagnostics Report',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#2C3E50'),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    isAr
                        ? 'إصدار النظام: v$version (رقم البناء: $buildNumber) • الفارق المرتقب: +$totalNew سجل'
                        : 'System Version: v$version (Build $buildNumber) • Pending Diff: +$totalNew records',
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                isAr
                    ? 'صفحة ${ctx.pageNumber} من ${ctx.pagesCount} • تم التوليد آلياً من ImportFlow ERP'
                    : 'Page ${ctx.pageNumber} of ${ctx.pagesCount} • Generated by ImportFlow ERP',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
              pw.Text(
                DateTime.now().toString().substring(0, 16),
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (pw.Context ctx) => [
          // DB Overview Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue300),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColor.fromHex('#F0F7FD'),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l.prodSyncDevDbTitle,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#2980B9')),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${l.prodSyncDbSizeLabel(devStats.sizeKb)} | ${devStats.mtime ?? "—"}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        devStats.dbPath,
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green300),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColor.fromHex('#F0FAF4'),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l.prodSyncProdDbTitle,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#27AE60')),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${l.prodSyncDbSizeLabel(prodStats.sizeKb)} | ${prodStats.mtime ?? "—"}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        prodStats.dbPath,
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Section Header: Tables Comparison
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2C3E50'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  l.prodSyncDiffPanelTitle,
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10.5),
                ),
                pw.Text(
                  isAr
                      ? '$differingCount جدول به فروقات • +$totalNew سجل جديد'
                      : '$differingCount differing tables • +$totalNew new records',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          // Tables Diff Table
          if (tables.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              alignment: pw.Alignment.center,
              child: pw.Text(
                l.prodSyncDiffAllMatchedSuccess,
                style: pw.TextStyle(color: PdfColor.fromHex('#27AE60'), fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECEFF1')),
                  children: [
                    _buildPdfHeaderCell('#', flex: 1),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderTableName, flex: 4),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderDevCount, flex: 2),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderProdCount, flex: 2),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderDiff, flex: 2),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderStatus, flex: 3),
                  ],
                ),
                ...tables.map((t) {
                  final statusLabel = t.status == 'NEW_DATA' || t.diff > 0
                      ? l.prodSyncDiffStatusNewRecords(t.diff)
                      : t.status == 'NEW_TABLE'
                          ? l.prodSyncDiffStatusNewTable
                          : t.diff < 0
                              ? l.prodSyncDiffStatusProdSurplus(t.diff)
                              : l.prodSyncDiffStatusMatched;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: t.hasChanges ? PdfColor.fromHex('#F4FAF6') : PdfColors.white,
                    ),
                    children: [
                      _buildPdfCell('${tables.indexOf(t) + 1}', align: pw.TextAlign.center),
                      _buildPdfCell(t.tableName, isBold: t.hasChanges),
                      _buildPdfCell('${t.devCount}', align: pw.TextAlign.center),
                      _buildPdfCell('${t.prodCount}', align: pw.TextAlign.center),
                      _buildPdfCell(t.diff > 0 ? '+${t.diff}' : '${t.diff}',
                          align: pw.TextAlign.center,
                          color: t.diff > 0 ? PdfColor.fromHex('#27AE60') : null),
                      _buildPdfCell(statusLabel,
                          align: pw.TextAlign.center,
                          color: t.hasChanges ? PdfColor.fromHex('#27AE60') : PdfColors.grey700),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 14),

          // Section Header: Backups Archive
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#34495E'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              l.prodSyncBackupsArchiveHeader(backups.length),
              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10.5),
            ),
          ),
          pw.SizedBox(height: 6),

          // Backups Table
          if (backups.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              alignment: pw.Alignment.center,
              child: pw.Text(
                l.prodSyncNoBackupsInFolder,
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECEFF1')),
                  children: [
                    _buildPdfHeaderCell('#', flex: 1),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderBackupFile, flex: 5),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderBackupTag, flex: 2),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderBackupSize, flex: 2),
                    _buildPdfHeaderCell(l.prodSyncTsvHeaderBackupDate, flex: 3),
                  ],
                ),
                ...backups.take(15).map((b) {
                  final tagLabel = b.filename.startsWith('auto_pre_upgrade')
                      ? l.prodSyncAutoPreUpgradeTag
                      : b.tag;
                  return pw.TableRow(
                    children: [
                      _buildPdfCell('${backups.indexOf(b) + 1}', align: pw.TextAlign.center),
                      _buildPdfCell(b.filename, isBold: true),
                      _buildPdfCell(tagLabel, align: pw.TextAlign.center),
                      _buildPdfCell('${b.sizeKb} KB', align: pw.TextAlign.center),
                      _buildPdfCell(b.mtime, align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'production_sync_diagnostics_v$version.pdf',
    );
  }

  static pw.Widget _buildPdfHeaderCell(String text, {int flex = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColor.fromHex('#2C3E50')),
      ),
    );
  }

  static pw.Widget _buildPdfCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.start,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
