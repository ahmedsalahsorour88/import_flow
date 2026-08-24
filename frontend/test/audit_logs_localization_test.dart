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
    });
  });
}
