import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../providers/users_provider.dart';

/// Dedicated Export & Dossier Service for Screen 66:
/// Users Management & RBAC Security Hub.
class UsersManagementExportService {
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

  static String _localizedRole(String role, AppLocalizations l) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return l.usersMgmtRoleAdminLabel;
      case 'MANAGER':
        return l.usersMgmtRoleManagerLabel;
      default:
        return l.usersMgmtRoleOperatorLabel;
    }
  }

  static String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;
    }
  }

  /// Converts single user to a clean single-line summary string for clipboard copy
  static String toRowSummary(UserDetail user, AppLocalizations l) {
    final role = _localizedRole(user.role, l);
    final status = user.isActive ? l.usersMgmtStatusActive : l.usersMgmtStatusInactive;
    final created = _formatDate(user.createdAt);
    return [
      '${l.usersMgmtColFullName}: ${user.fullName}',
      '${l.usersMgmtColUsername}: @${user.username}',
      '${l.usersMgmtColEmail}: ${user.email}',
      '${l.usersMgmtColRole}: $role',
      '${l.usersMgmtColStatus}: $status',
      '${l.usersMgmtColCreatedAt}: $created',
    ].join(' | ');
  }

  /// Exports users list to TSV format with UTF-8 BOM
  static String exportUsersToTsv(List<UserDetail> users, AppLocalizations l) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Headers
    final headers = [
      '#',
      _cleanTsv(l.usersMgmtColFullName),
      _cleanTsv(l.usersMgmtColUsername),
      _cleanTsv(l.usersMgmtColEmail),
      _cleanTsv(l.usersMgmtColRole),
      _cleanTsv(l.usersMgmtColStatus),
      _cleanTsv(l.usersMgmtColCreatedAt),
    ];
    buffer.writeln(headers.join('\t'));

    // Rows
    for (int i = 0; i < users.length; i++) {
      final u = users[i];
      final row = [
        '${i + 1}',
        _cleanTsv(u.fullName),
        _cleanTsv('@${u.username}'),
        _cleanTsv(u.email),
        _cleanTsv(_localizedRole(u.role, l)),
        _cleanTsv(u.isActive ? l.usersMgmtStatusActive : l.usersMgmtStatusInactive),
        _cleanTsv(_formatDate(u.createdAt)),
      ];
      buffer.writeln(row.join('\t'));
    }

    return buffer.toString();
  }

  /// Exports users list to CSV format with UTF-8 BOM and RFC 4180 escaping
  static String exportUsersToCsv(List<UserDetail> users, AppLocalizations l) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Headers
    final headers = [
      '#',
      _csvQuote(l.usersMgmtColFullName),
      _csvQuote(l.usersMgmtColUsername),
      _csvQuote(l.usersMgmtColEmail),
      _csvQuote(l.usersMgmtColRole),
      _csvQuote(l.usersMgmtColStatus),
      _csvQuote(l.usersMgmtColCreatedAt),
    ];
    buffer.writeln(headers.join(','));

    // Rows
    for (int i = 0; i < users.length; i++) {
      final u = users[i];
      final row = [
        '${i + 1}',
        _csvQuote(u.fullName),
        _csvQuote('@${u.username}'),
        _csvQuote(u.email),
        _csvQuote(_localizedRole(u.role, l)),
        _csvQuote(u.isActive ? l.usersMgmtStatusActive : l.usersMgmtStatusInactive),
        _csvQuote(_formatDate(u.createdAt)),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Saves TSV file and copies TSV to clipboard
  static Future<void> saveUsersTsvToFile(BuildContext context, List<UserDetail> users) async {
    final l = context.l10n;
    final tsvData = exportUsersToTsv(users, l);
    await CopyHelper.copy(context, tsvData, customMessage: l.usersMgmtCopiedTsvSuccess);
    if (!context.mounted) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final filename = 'users_management_export_$timestamp.tsv';

    await FileSaveHelper.saveText(
      context: context,
      textContent: tsvData,
      defaultFileName: filename,
      dialogTitle: l.usersMgmtExportTsvBtn,
      allowedExtensions: ['tsv', 'txt'],
      addUtf8Bom: false,
    );
  }

  /// Saves CSV file and copies CSV to clipboard
  static Future<void> saveUsersCsvToFile(BuildContext context, List<UserDetail> users) async {
    final l = context.l10n;
    final csvData = exportUsersToCsv(users, l);
    await CopyHelper.copy(context, csvData, customMessage: l.usersMgmtCopiedExcelSuccess);
    if (!context.mounted) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final filename = 'users_management_export_$timestamp.csv';

    await FileSaveHelper.saveText(
      context: context,
      textContent: csvData,
      defaultFileName: filename,
      dialogTitle: l.usersMgmtExportExcelBtn,
      allowedExtensions: ['csv'],
      addUtf8Bom: false,
    );
  }

  /// Generates a structured multi-line operational dossier text
  static String buildUsersDossier(List<UserDetail> users, AppLocalizations l) {
    final buffer = StringBuffer();
    final totalCount = users.length;
    final activeCount = users.where((u) => u.isActive).length;
    final inactiveCount = totalCount - activeCount;
    final adminsCount = users.where((u) => u.role.toUpperCase() == 'ADMIN').length;
    final managersCount = users.where((u) => u.role.toUpperCase() == 'MANAGER').length;
    final operatorsCount = users.where((u) => u.role.toUpperCase() == 'OPERATOR').length;

    buffer.writeln(l.usersMgmtDossierHeader);
    buffer.writeln('Generated: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll("T", " ")}');
    buffer.writeln();

    buffer.writeln(l.usersMgmtDossierKpiSummary);
    buffer.writeln('• ${l.usersMgmtStatAll}: $totalCount');
    buffer.writeln('• ${l.usersMgmtStatActive}: $activeCount');
    buffer.writeln('• ${l.usersMgmtStatusInactive}: $inactiveCount');
    buffer.writeln('• ${l.usersMgmtStatAdmin}: $adminsCount');
    buffer.writeln('• ${l.usersMgmtStatManager}: $managersCount');
    buffer.writeln('• ${l.usersMgmtStatOperator}: $operatorsCount');
    buffer.writeln();

    buffer.writeln(l.usersMgmtDossierRecordsDetails);
    for (int i = 0; i < users.length; i++) {
      final u = users[i];
      final summary = toRowSummary(u, l);
      buffer.writeln('${i + 1}. $summary');
    }
    buffer.writeln();
    buffer.writeln(l.usersMgmtDossierFooter);

    return buffer.toString();
  }

  /// Copies formatted dossier directly to system clipboard
  static Future<void> copyDossierToClipboard(BuildContext context, List<UserDetail> users) async {
    final l = context.l10n;
    final dossier = buildUsersDossier(users, l);
    await CopyHelper.copy(context, dossier, customMessage: l.usersMgmtCopiedDossierSuccess);
  }

  /// Prints or saves a vector A4 PDF using Cairo font with official layout
  static Future<void> printOrSaveUsersPdf(BuildContext context, List<UserDetail> users) async {
    final l = context.l10n;
    final pdf = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoRegular();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final totalCount = users.length;
    final activeCount = users.where((u) => u.isActive).length;
    final adminsCount = users.where((u) => u.role.toUpperCase() == 'ADMIN').length;
    final managersCount = users.where((u) => u.role.toUpperCase() == 'MANAGER').length;
    final operatorsCount = users.where((u) => u.role.toUpperCase() == 'OPERATOR').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        textDirection: pw.TextDirection.rtl,
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
                    l.usersMgmtPdfTitle,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    l.usersMgmtPdfSubtitle,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'ImportFlow ERP — RBAC',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  pw.Text(
                    DateTime.now().toIso8601String().substring(0, 10),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 6),

          // KPI Summary Cards
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfKpiItem(l.usersMgmtStatAll, '$totalCount', PdfColors.blueGrey800),
                _buildPdfKpiItem(l.usersMgmtStatActive, '$activeCount', PdfColors.teal700),
                _buildPdfKpiItem(l.usersMgmtStatAdmin, '$adminsCount', PdfColors.red800),
                _buildPdfKpiItem(l.usersMgmtStatManager, '$managersCount', PdfColors.indigo700),
                _buildPdfKpiItem(l.usersMgmtStatOperator, '$operatorsCount', PdfColors.green800),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // Vector Table
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              l.usersMgmtColFullName,
              l.usersMgmtColUsername,
              l.usersMgmtColEmail,
              l.usersMgmtColRole,
              l.usersMgmtColStatus,
              l.usersMgmtColCreatedAt,
            ],
            data: users.asMap().entries.map((e) {
              final idx = e.key + 1;
              final u = e.value;
              return [
                '$idx',
                u.fullName,
                '@${u.username}',
                u.email,
                _localizedRole(u.role, l),
                u.isActive ? l.usersMgmtStatusActive : l.usersMgmtStatusInactive,
                _formatDate(u.createdAt),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerRight,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          pw.SizedBox(height: 10),

          // Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ImportFlow ERP System • Automated RBAC Export',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Confidential & Proprietary',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );

    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'users_management_report_$timestamp.pdf',
    );
  }

  static pw.Widget _buildPdfKpiItem(String title, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
