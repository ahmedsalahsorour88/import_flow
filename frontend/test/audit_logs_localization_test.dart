import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 47: Audit Logs Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 47 getters should return non-empty strings in Arabic and English', () {
      // Screen title & Subtitle
      expect(ar.auditLogsScreenTitle, isNotEmpty);
      expect(en.auditLogsScreenTitle, isNotEmpty);
      expect(ar.auditLogsScreenSubtitle, isNotEmpty);
      expect(en.auditLogsScreenSubtitle, isNotEmpty);
      expect(ar.liveRefreshBtn, isNotEmpty);
      expect(en.liveRefreshBtn, isNotEmpty);

      // Filters
      expect(ar.filterEntityLabel, isNotEmpty);
      expect(en.filterEntityLabel, isNotEmpty);
      expect(ar.filterActionLabel, isNotEmpty);
      expect(en.filterActionLabel, isNotEmpty);
      expect(ar.filterAllOption, isNotEmpty);
      expect(en.filterAllOption, isNotEmpty);
      expect(ar.auditEntityImportCompany, isNotEmpty);
      expect(en.auditEntityImportCompany, isNotEmpty);
      expect(ar.auditEntitySupplier, isNotEmpty);
      expect(en.auditEntitySupplier, isNotEmpty);
      expect(ar.auditEntityExternalServiceProvider, isNotEmpty);
      expect(en.auditEntityExternalServiceProvider, isNotEmpty);
      expect(ar.auditEntityUser, isNotEmpty);
      expect(en.auditEntityUser, isNotEmpty);

      // Entity mappings
      expect(ar.auditEntityLabel('ImportCompany'), isNotEmpty);
      expect(en.auditEntityLabel('ImportCompany'), equals('Importer'));
      expect(ar.auditEntityLabel('Supplier'), isNotEmpty);
      expect(en.auditEntityLabel('Supplier'), equals('Supplier'));
      expect(ar.auditEntityLabel('ExternalServiceProvider'), isNotEmpty);
      expect(en.auditEntityLabel('ExternalServiceProvider'), equals('Partner/Bank'));
      expect(ar.auditEntityLabel('User'), isNotEmpty);
      expect(en.auditEntityLabel('User'), equals('User'));
      expect(ar.auditEntityLabel('All'), isNotEmpty);
      expect(en.auditEntityLabel('All'), equals('All'));

      // Action labels
      expect(ar.auditActionCreate, isNotEmpty);
      expect(en.auditActionCreate, isNotEmpty);
      expect(ar.auditActionUpdate, isNotEmpty);
      expect(en.auditActionUpdate, isNotEmpty);
      expect(ar.auditActionDelete, isNotEmpty);
      expect(en.auditActionDelete, isNotEmpty);
      expect(ar.auditActionRestore, isNotEmpty);
      expect(en.auditActionRestore, isNotEmpty);

      expect(ar.auditActionLabel('CREATE'), isNotEmpty);
      expect(en.auditActionLabel('CREATE'), equals('CREATE'));
      expect(ar.auditActionLabel('UPDATE'), isNotEmpty);
      expect(en.auditActionLabel('UPDATE'), equals('UPDATE'));
      expect(ar.auditActionLabel('DELETE'), isNotEmpty);
      expect(en.auditActionLabel('DELETE'), equals('DELETE'));
      expect(ar.auditActionLabel('RESTORE'), isNotEmpty);
      expect(en.auditActionLabel('RESTORE'), equals('RESTORE'));

      // Search, Error & Empty
      expect(ar.searchAuditLogsHint, isNotEmpty);
      expect(en.searchAuditLogsHint, isNotEmpty);
      expect(ar.auditLogsFetchError('timeout'), contains('timeout'));
      expect(en.auditLogsFetchError('timeout'), contains('timeout'));
      expect(ar.noAuditLogsFound, isNotEmpty);
      expect(en.noAuditLogsFound, isNotEmpty);

      // Cards & user info
      expect(ar.auditEntityWithCode('Supplier', 'SUP-001'), contains('SUP-001'));
      expect(en.auditEntityWithCode('Supplier', 'SUP-001'), contains('SUP-001'));
      expect(ar.systemMutationFallback, isNotEmpty);
      expect(en.systemMutationFallback, isNotEmpty);
      expect(ar.performedByUser('admin@importflow.eg'), contains('admin@importflow.eg'));
      expect(en.performedByUser('admin@importflow.eg'), contains('admin@importflow.eg'));

      // New Screen 39 export & copy getters
      expect(ar.auditLogsExportTsvBtn, isNotEmpty);
      expect(en.auditLogsExportTsvBtn, isNotEmpty);
      expect(ar.auditLogsExportTsvSuccess, isNotEmpty);
      expect(en.auditLogsExportTsvSuccess, isNotEmpty);
      expect(ar.auditLogCopySummaryBtn, isNotEmpty);
      expect(en.auditLogCopySummarySuccess, isNotEmpty);
      expect(ar.auditLogEntityCodeBadgeLabel, isNotEmpty);
      expect(en.auditLogCopyFieldTooltip, isNotEmpty);
      expect(ar.exportAuditLogPdfBtn, isNotEmpty);
      expect(en.exportAuditLogPdfBtn, isNotEmpty);
      expect(ar.exportAuditLogExcelBtn, isNotEmpty);
      expect(en.exportAuditLogExcelBtn, isNotEmpty);
      expect(ar.viewEntityHistoryBtn, isNotEmpty);
      expect(en.viewEntityHistoryBtn, isNotEmpty);

      // TSV headers
      expect(ar.auditLogsTsvHeaderLogId, isNotEmpty);
      expect(en.auditLogsTsvHeaderLogId, isNotEmpty);
      expect(ar.auditLogsTsvHeaderAction, isNotEmpty);
      expect(en.auditLogsTsvHeaderAction, isNotEmpty);
      expect(ar.auditLogsTsvHeaderEntityType, isNotEmpty);
      expect(en.auditLogsTsvHeaderEntityType, isNotEmpty);
      expect(ar.auditLogsTsvHeaderEntityCode, isNotEmpty);
      expect(en.auditLogsTsvHeaderEntityCode, isNotEmpty);
      expect(ar.auditLogsTsvHeaderSummary, isNotEmpty);
      expect(en.auditLogsTsvHeaderSummary, isNotEmpty);
      expect(ar.auditLogsTsvHeaderPerformedBy, isNotEmpty);
      expect(en.auditLogsTsvHeaderPerformedBy, isNotEmpty);
      expect(ar.auditLogsTsvHeaderTimestamp, isNotEmpty);
      expect(en.auditLogsTsvHeaderTimestamp, isNotEmpty);

      // Row History Dialog
      expect(ar.rowHistoryDialogTitle, isNotEmpty);
      expect(en.rowHistoryDialogTitle, isNotEmpty);
      expect(ar.rowHistoryDialogSubtitle('Supplier', 'SUP-001'), contains('SUP-001'));
      expect(en.rowHistoryDialogSubtitle('Supplier', 'SUP-001'), contains('SUP-001'));
      expect(ar.rowHistoryRefreshTooltip, isNotEmpty);
      expect(en.rowHistoryRefreshTooltip, isNotEmpty);
      expect(ar.rowHistoryLoading, isNotEmpty);
      expect(en.rowHistoryLoading, isNotEmpty);
      expect(ar.rowHistoryEmpty, isNotEmpty);
      expect(en.rowHistoryEmpty, isNotEmpty);
      expect(ar.rowHistoryCloseBtn, isNotEmpty);
      expect(en.rowHistoryCloseBtn, isNotEmpty);
      expect(ar.rowHistoryExportTsvBtn, isNotEmpty);
      expect(en.rowHistoryExportTsvBtn, isNotEmpty);
      expect(ar.rowHistoryExportTsvSuccess, isNotEmpty);
      expect(en.rowHistoryExportTsvSuccess, isNotEmpty);
      expect(ar.rowHistoryExportPdfBtn, isNotEmpty);
      expect(en.rowHistoryExportPdfBtn, isNotEmpty);
      expect(ar.rowHistoryCopySummaryBtn, isNotEmpty);
      expect(en.rowHistoryCopySummarySuccess, isNotEmpty);
    });

    test('Arabic static strings should not contain English or Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');
      expect(latinPattern.hasMatch(ar.auditLogsScreenTitle), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsScreenSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.liveRefreshBtn), isFalse);
      expect(latinPattern.hasMatch(ar.filterEntityLabel), isFalse);
      expect(latinPattern.hasMatch(ar.filterActionLabel), isFalse);
      expect(latinPattern.hasMatch(ar.filterAllOption), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityImportCompany), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntitySupplier), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityExternalServiceProvider), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityUser), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityLabel('ImportCompany')), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityLabel('Supplier')), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityLabel('ExternalServiceProvider')), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityLabel('User')), isFalse);
      expect(latinPattern.hasMatch(ar.auditEntityLabel('All')), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionCreate), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionUpdate), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionDelete), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionRestore), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionLabel('CREATE')), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionLabel('UPDATE')), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionLabel('DELETE')), isFalse);
      expect(latinPattern.hasMatch(ar.auditActionLabel('RESTORE')), isFalse);
      expect(latinPattern.hasMatch(ar.searchAuditLogsHint), isFalse);
      expect(latinPattern.hasMatch(ar.noAuditLogsFound), isFalse);
      expect(latinPattern.hasMatch(ar.systemMutationFallback), isFalse);

      // New Screen 39 getters Latin check
      expect(latinPattern.hasMatch(ar.auditLogsExportTsvBtn), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsExportTsvSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogCopySummaryBtn), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogCopySummarySuccess), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogEntityCodeBadgeLabel), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogCopyFieldTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.exportAuditLogPdfBtn), isFalse);
      expect(latinPattern.hasMatch(ar.exportAuditLogExcelBtn), isFalse);
      expect(latinPattern.hasMatch(ar.viewEntityHistoryBtn), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderLogId), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderAction), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderEntityType), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderEntityCode), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderSummary), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderPerformedBy), isFalse);
      expect(latinPattern.hasMatch(ar.auditLogsTsvHeaderTimestamp), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryRefreshTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryLoading), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryEmpty), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryCloseBtn), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryExportTsvBtn), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryExportTsvSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryExportPdfBtn), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryCopySummaryBtn), isFalse);
      expect(latinPattern.hasMatch(ar.rowHistoryCopySummarySuccess), isFalse);
    });
  });
}
