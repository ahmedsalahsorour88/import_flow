import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 59: Production Sync Screen & Hub Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 59 getters return non-empty strings and no missing translations', () {
      // Titles and Subtitles
      expect(ar.prodSyncScreenTitle.isNotEmpty, true);
      expect(en.prodSyncScreenTitle.isNotEmpty, true);
      expect(ar.prodSyncScreenSubtitle.isNotEmpty, true);
      expect(en.prodSyncScreenSubtitle.isNotEmpty, true);
      expect(ar.prodSyncHubDialogTitle.isNotEmpty, true);
      expect(en.prodSyncHubDialogTitle.isNotEmpty, true);
      expect(ar.prodSyncHubDialogSubtitle.isNotEmpty, true);
      expect(en.prodSyncHubDialogSubtitle.isNotEmpty, true);

      // Tabs
      expect(ar.prodSyncTabCompareTables.isNotEmpty, true);
      expect(en.prodSyncTabCompareTables.isNotEmpty, true);
      expect(ar.prodSyncTabSchemaUpgrade.isNotEmpty, true);
      expect(en.prodSyncTabSchemaUpgrade.isNotEmpty, true);
      expect(ar.prodSyncTabSafetyBackups.isNotEmpty, true);
      expect(en.prodSyncTabSafetyBackups.isNotEmpty, true);

      // Dev & Prod DB Cards
      expect(ar.prodSyncDevDbTitle.isNotEmpty, true);
      expect(en.prodSyncDevDbTitle.isNotEmpty, true);
      expect(ar.prodSyncDevDbSubtitle.isNotEmpty, true);
      expect(en.prodSyncDevDbSubtitle.isNotEmpty, true);
      expect(ar.prodSyncDevDbUpgradeSub.isNotEmpty, true);
      expect(en.prodSyncDevDbUpgradeSub.isNotEmpty, true);
      expect(ar.prodSyncProdDbTitle.isNotEmpty, true);
      expect(en.prodSyncProdDbTitle.isNotEmpty, true);
      expect(ar.prodSyncProdDbSubtitle.isNotEmpty, true);
      expect(en.prodSyncProdDbSubtitle.isNotEmpty, true);
      expect(ar.prodSyncProdDbUpgradeSub.isNotEmpty, true);
      expect(en.prodSyncProdDbUpgradeSub.isNotEmpty, true);

      // DB Metrics
      expect(ar.prodSyncDbSize(1024), contains('1024'));
      expect(en.prodSyncDbSize(1024), contains('1024'));
      expect(ar.prodSyncDbTablesCount(25), contains('25'));
      expect(en.prodSyncDbTablesCount(25), contains('25'));
      expect(ar.prodSyncDbRecordsCount(500), contains('500'));
      expect(en.prodSyncDbRecordsCount(500), contains('500'));

      // Sync & Differences Status
      expect(ar.prodSyncFullySynchronizedTitle(25), contains('25'));
      expect(en.prodSyncFullySynchronizedTitle(25), contains('25'));
      expect(ar.prodSyncFullySynchronizedSub.isNotEmpty, true);
      expect(en.prodSyncFullySynchronizedSub.isNotEmpty, true);
      expect(ar.prodSyncDifferencesDetectedTitle(3), contains('3'));
      expect(en.prodSyncDifferencesDetectedTitle(3), contains('3'));
      expect(ar.prodSyncDifferencesDetectedSub.isNotEmpty, true);
      expect(en.prodSyncDifferencesDetectedSub.isNotEmpty, true);
      expect(ar.prodSyncUpgradeReadyTitle(2), contains('2'));
      expect(en.prodSyncUpgradeReadyTitle(2), contains('2'));
      expect(ar.prodSyncUpgradeReadySub.isNotEmpty, true);
      expect(en.prodSyncUpgradeReadySub.isNotEmpty, true);

      // Safety Banner
      expect(ar.prodSyncSafetyGuaranteeTitle.isNotEmpty, true);
      expect(en.prodSyncSafetyGuaranteeTitle.isNotEmpty, true);
      expect(ar.prodSyncSafetyGuaranteeBody.isNotEmpty, true);
      expect(en.prodSyncSafetyGuaranteeBody.isNotEmpty, true);

      // Action Buttons
      expect(ar.prodSyncSyncNowBtn.isNotEmpty, true);
      expect(en.prodSyncSyncNowBtn.isNotEmpty, true);
      expect(ar.prodSyncUpgradeBtn.isNotEmpty, true);
      expect(en.prodSyncUpgradeBtn.isNotEmpty, true);
      expect(ar.prodSyncPullFromProdBtn.isNotEmpty, true);
      expect(en.prodSyncPullFromProdBtn.isNotEmpty, true);
      expect(ar.prodSyncCreateSnapshotBtn.isNotEmpty, true);
      expect(en.prodSyncCreateSnapshotBtn.isNotEmpty, true);
      expect(ar.prodSyncCreateDevSnapshotBtn.isNotEmpty, true);
      expect(en.prodSyncCreateDevSnapshotBtn.isNotEmpty, true);

      // Tables Comparison List
      expect(ar.prodSyncTablesMatchHeader(10, 20), contains('10'));
      expect(ar.prodSyncTablesMatchHeader(10, 20), contains('20'));
      expect(en.prodSyncTablesMatchHeader(10, 20), contains('10'));
      expect(en.prodSyncTablesMatchHeader(10, 20), contains('20'));
      expect(ar.prodSyncTablesUpgradeHeader(5, 20), contains('5'));
      expect(ar.prodSyncTablesUpgradeHeader(5, 20), contains('20'));
      expect(en.prodSyncTablesUpgradeHeader(5, 20), contains('5'));
      expect(en.prodSyncTablesUpgradeHeader(5, 20), contains('20'));
      expect(ar.prodSyncSearchTablesHint.isNotEmpty, true);
      expect(en.prodSyncSearchTablesHint.isNotEmpty, true);
      expect(ar.prodSyncDevRecordsCount(150), contains('150'));
      expect(en.prodSyncDevRecordsCount(150), contains('150'));
      expect(ar.prodSyncProdRecordsCount(120), contains('120'));
      expect(en.prodSyncProdRecordsCount(120), contains('120'));
      expect(ar.prodSyncTableStatusUpdated.isNotEmpty, true);
      expect(en.prodSyncTableStatusUpdated.isNotEmpty, true);

      // Backups View
      expect(ar.prodSyncBackupsSectionHeader.isNotEmpty, true);
      expect(en.prodSyncBackupsSectionHeader.isNotEmpty, true);
      expect(ar.prodSyncBackupsSectionSub.isNotEmpty, true);
      expect(en.prodSyncBackupsSectionSub.isNotEmpty, true);
      expect(ar.prodSyncBackupsDialogSub.isNotEmpty, true);
      expect(en.prodSyncBackupsDialogSub.isNotEmpty, true);
      expect(ar.prodSyncNoBackupsFound.isNotEmpty, true);
      expect(en.prodSyncNoBackupsFound.isNotEmpty, true);
      expect(ar.prodSyncNoBackupsDialogSub.isNotEmpty, true);
      expect(en.prodSyncNoBackupsDialogSub.isNotEmpty, true);
      expect(ar.prodSyncRestoreToProdBtn.isNotEmpty, true);
      expect(en.prodSyncRestoreToProdBtn.isNotEmpty, true);
      expect(ar.prodSyncRestoreToDevBtn.isNotEmpty, true);
      expect(en.prodSyncRestoreToDevBtn.isNotEmpty, true);
      expect(ar.prodSyncBackupCreatedAt('2026-08-24'), contains('2026-08-24'));
      expect(en.prodSyncBackupCreatedAt('2026-08-24'), contains('2026-08-24'));
      expect(ar.prodSyncBackupSize(512), contains('512'));
      expect(en.prodSyncBackupSize(512), contains('512'));
      expect(ar.prodSyncBackupTag('prod'), contains('prod'));
      expect(en.prodSyncBackupTag('prod'), contains('prod'));

      // Confirmation Dialogs & Errors
      expect(ar.prodSyncConfirmUpgradeTitle.isNotEmpty, true);
      expect(en.prodSyncConfirmUpgradeTitle.isNotEmpty, true);
      expect(ar.prodSyncConfirmUpgradeWhatHappens.isNotEmpty, true);
      expect(en.prodSyncConfirmUpgradeWhatHappens.isNotEmpty, true);
      expect(ar.prodSyncConfirmUpgradeWhatWontHappen.isNotEmpty, true);
      expect(en.prodSyncConfirmUpgradeWhatWontHappen.isNotEmpty, true);
      expect(ar.prodSyncConfirmUpgradeSubmitBtn.isNotEmpty, true);
      expect(en.prodSyncConfirmUpgradeSubmitBtn.isNotEmpty, true);
      expect(ar.prodSyncConfirmRestoreTitle.isNotEmpty, true);
      expect(en.prodSyncConfirmRestoreTitle.isNotEmpty, true);
      expect(ar.prodSyncConfirmRestoreMsg('الإنتاج'), contains('الإنتاج'));
      expect(en.prodSyncConfirmRestoreMsg('Production'), contains('Production'));
      expect(ar.prodSyncConfirmRestoreWarning.isNotEmpty, true);
      expect(en.prodSyncConfirmRestoreWarning.isNotEmpty, true);
      expect(ar.prodSyncConfirmRestoreSubmitBtn.isNotEmpty, true);
      expect(en.prodSyncConfirmRestoreSubmitBtn.isNotEmpty, true);
      expect(ar.prodSyncTargetProdLabel.isNotEmpty, true);
      expect(en.prodSyncTargetProdLabel.isNotEmpty, true);
      expect(ar.prodSyncTargetDevLabel.isNotEmpty, true);
      expect(en.prodSyncTargetDevLabel.isNotEmpty, true);
      expect(ar.prodSyncBackupCreatedSuccess('backup_01.db'), contains('backup_01.db'));
      expect(en.prodSyncBackupCreatedSuccess('backup_01.db'), contains('backup_01.db'));
      expect(ar.prodSyncSyncError('NetworkErr'), contains('NetworkErr'));
      expect(en.prodSyncSyncError('NetworkErr'), contains('NetworkErr'));
      expect(ar.prodSyncPullError('IOErr'), contains('IOErr'));
      expect(en.prodSyncPullError('IOErr'), contains('IOErr'));
      expect(ar.prodSyncRestoreError('RestoreErr'), contains('RestoreErr'));
      expect(en.prodSyncRestoreError('RestoreErr'), contains('RestoreErr'));
      expect(ar.prodSyncComparingDatabasesProgress.isNotEmpty, true);
      expect(en.prodSyncComparingDatabasesProgress.isNotEmpty, true);
      expect(ar.prodSyncErrorFetchingComparison('Fail'), contains('Fail'));
      expect(en.prodSyncErrorFetchingComparison('Fail'), contains('Fail'));
    });

    test('Arabic translations contain pure Arabic text without Latin characters', () {
      final latinRegex = RegExp(r'[a-zA-Z]');

      final pureArabicStaticStrings = [
        ar.prodSyncScreenTitle,
        ar.prodSyncScreenSubtitle,
        ar.prodSyncHubDialogTitle,
        ar.prodSyncHubDialogSubtitle,
        ar.prodSyncTabCompareTables,
        ar.prodSyncTabSchemaUpgrade,
        ar.prodSyncTabSafetyBackups,
        ar.prodSyncDevDbTitle,
        ar.prodSyncDevDbSubtitle,
        ar.prodSyncDevDbUpgradeSub,
        ar.prodSyncProdDbTitle,
        ar.prodSyncProdDbSubtitle,
        ar.prodSyncProdDbUpgradeSub,
        ar.prodSyncFullySynchronizedSub,
        ar.prodSyncDifferencesDetectedSub,
        ar.prodSyncUpgradeReadySub,
        ar.prodSyncSafetyGuaranteeTitle,
        ar.prodSyncSafetyGuaranteeBody,
        ar.prodSyncSyncNowBtn,
        ar.prodSyncUpgradeBtn,
        ar.prodSyncPullFromProdBtn,
        ar.prodSyncCreateSnapshotBtn,
        ar.prodSyncCreateDevSnapshotBtn,
        ar.prodSyncSearchTablesHint,
        ar.prodSyncTableStatusUpdated,
        ar.prodSyncBackupsSectionHeader,
        ar.prodSyncBackupsSectionSub,
        ar.prodSyncBackupsDialogSub,
        ar.prodSyncNoBackupsFound,
        ar.prodSyncNoBackupsDialogSub,
        ar.prodSyncRestoreToProdBtn,
        ar.prodSyncRestoreToDevBtn,
        ar.prodSyncConfirmUpgradeTitle,
        ar.prodSyncConfirmUpgradeWhatHappens,
        ar.prodSyncConfirmUpgradeWhatWontHappen,
        ar.prodSyncConfirmUpgradeSubmitBtn,
        ar.prodSyncConfirmRestoreTitle,
        ar.prodSyncConfirmRestoreWarning,
        ar.prodSyncConfirmRestoreSubmitBtn,
        ar.prodSyncTargetProdLabel,
        ar.prodSyncTargetDevLabel,
        ar.prodSyncComparingDatabasesProgress,
      ];

      for (final text in pureArabicStaticStrings) {
        expect(
          latinRegex.hasMatch(text),
          false,
          reason: 'String "$text" contains English/Latin characters!',
        );
      }
    });

    test('No stacked bilingual text is present in static labels', () {
      expect(ar.prodSyncScreenTitle.contains('('), false);
      expect(ar.prodSyncTabCompareTables.contains('('), false);
      expect(ar.prodSyncTabSafetyBackups.contains('('), false);
      expect(ar.prodSyncDevDbTitle.contains('('), false);
      expect(ar.prodSyncProdDbTitle.contains('('), false);
      expect(ar.prodSyncCreateSnapshotBtn.contains('('), false);
      expect(ar.prodSyncPullFromProdBtn.contains('('), false);
    });
  });
}
