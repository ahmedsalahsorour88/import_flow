import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 19: Draft COO / EUR.1 Review Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All COO getters return non-empty strings and differ between AR and EN', () {
      expect(ar.cooStage1Requirements, isNotEmpty);
      expect(en.cooStage1Requirements, isNotEmpty);
      expect(ar.cooStage1Requirements, isNot(equals(en.cooStage1Requirements)));

      expect(ar.cooStage2DraftInput, isNotEmpty);
      expect(en.cooStage2DraftInput, isNotEmpty);
      expect(ar.cooStage2DraftInput, isNot(equals(en.cooStage2DraftInput)));

      expect(ar.cooStage3DiscrepancyMatrix, isNotEmpty);
      expect(en.cooStage3DiscrepancyMatrix, isNotEmpty);
      expect(ar.cooStage3DiscrepancyMatrix, isNot(equals(en.cooStage3DiscrepancyMatrix)));

      expect(ar.cooStage4Registry, isNotEmpty);
      expect(en.cooStage4Registry, isNotEmpty);
      expect(ar.cooStage4Registry, isNot(equals(en.cooStage4Registry)));

      expect(ar.cooDecisionEngineTitle, isNotEmpty);
      expect(en.cooDecisionEngineTitle, isNotEmpty);

      expect(ar.cooDecisionEngineSub, isNotEmpty);
      expect(en.cooDecisionEngineSub, isNotEmpty);

      expect(ar.cooRecheckAgreementButton, isNotEmpty);
      expect(en.cooRecheckAgreementButton, isNotEmpty);

      expect(ar.cooManualChoiceRequiredBadge, isNotEmpty);
      expect(en.cooManualChoiceRequiredBadge, isNotEmpty);

      expect(ar.cooReviewRegistryButton, isNotEmpty);
      expect(en.cooReviewRegistryButton, isNotEmpty);

      expect(ar.cooGenerateDraftHeader, isNotEmpty);
      expect(en.cooGenerateDraftHeader, isNotEmpty);

      expect(ar.cooSelectImportFileLabel, isNotEmpty);
      expect(en.cooSelectImportFileLabel, isNotEmpty);

      expect(ar.cooSearchFileHint, isNotEmpty);
      expect(en.cooSearchFileHint, isNotEmpty);

      expect(ar.cooCertTypeLabel, isNotEmpty);
      expect(en.cooCertTypeLabel, isNotEmpty);

      expect(ar.cooCertTypeEur1, isNotEmpty);
      expect(en.cooCertTypeEur1, isNotEmpty);

      expect(ar.cooCertTypeChina, isNotEmpty);
      expect(en.cooCertTypeChina, isNotEmpty);

      expect(ar.cooCertTypeFormA, isNotEmpty);
      expect(en.cooCertTypeFormA, isNotEmpty);

      expect(ar.cooCertTypeAgadir, isNotEmpty);
      expect(en.cooCertTypeAgadir, isNotEmpty);

      expect(ar.cooCertTypeGafta, isNotEmpty);
      expect(en.cooCertTypeGafta, isNotEmpty);

      expect(ar.cooOpenVisualPreviewButton, isNotEmpty);
      expect(en.cooOpenVisualPreviewButton, isNotEmpty);

      expect(ar.cooNextDraftInputButton, isNotEmpty);
      expect(en.cooNextDraftInputButton, isNotEmpty);

      expect(ar.cooDraftInputTitle, isNotEmpty);
      expect(en.cooDraftInputTitle, isNotEmpty);

      expect(ar.cooRunComparisonButton, isNotEmpty);
      expect(en.cooRunComparisonButton, isNotEmpty);

      expect(ar.cooDraftCertNumberLabel, isNotEmpty);
      expect(en.cooDraftCertNumberLabel, isNotEmpty);

      expect(ar.cooOriginCountryLabel, isNotEmpty);
      expect(en.cooOriginCountryLabel, isNotEmpty);

      expect(ar.cooDestinationCountryLabel, isNotEmpty);
      expect(en.cooDestinationCountryLabel, isNotEmpty);

      expect(ar.cooExporterNameLabel, isNotEmpty);
      expect(en.cooExporterNameLabel, isNotEmpty);

      expect(ar.cooExporterRegIdLabel, isNotEmpty);
      expect(en.cooExporterRegIdLabel, isNotEmpty);

      expect(ar.cooImporterNameLabel, isNotEmpty);
      expect(en.cooImporterNameLabel, isNotEmpty);

      expect(ar.cooInvoiceNumberLabel, isNotEmpty);
      expect(en.cooInvoiceNumberLabel, isNotEmpty);

      expect(ar.cooSmartUploadButtonLabel, isNotEmpty);
      expect(en.cooSmartUploadButtonLabel, isNotEmpty);

      expect(ar.cooRawTextSectionTitle, isNotEmpty);
      expect(en.cooRawTextSectionTitle, isNotEmpty);

      expect(ar.cooSmartExtractFromTextButton, isNotEmpty);
      expect(en.cooSmartExtractFromTextButton, isNotEmpty);

      expect(ar.cooCriticalMismatchAlert, isNotEmpty);
      expect(en.cooCriticalMismatchAlert, isNotEmpty);

      expect(ar.cooMinorDiscrepancyAlert, isNotEmpty);
      expect(en.cooMinorDiscrepancyAlert, isNotEmpty);

      expect(ar.cooPerfectMatchSuccess, isNotEmpty);
      expect(en.cooPerfectMatchSuccess, isNotEmpty);

      expect(ar.cooExportPdfButton, isNotEmpty);
      expect(en.cooExportPdfButton, isNotEmpty);

      expect(ar.cooExportExcelButton, isNotEmpty);
      expect(en.cooExportExcelButton, isNotEmpty);

      expect(ar.cooSaveToRegistryButton, isNotEmpty);
      expect(en.cooSaveToRegistryButton, isNotEmpty);

      expect(ar.cooMatrixColField, isNotEmpty);
      expect(en.cooMatrixColField, isNotEmpty);

      expect(ar.cooMatrixColSystemValue, isNotEmpty);
      expect(en.cooMatrixColSystemValue, isNotEmpty);

      expect(ar.cooMatrixColDraftValue, isNotEmpty);
      expect(en.cooMatrixColDraftValue, isNotEmpty);

      expect(ar.cooMatrixColStatus, isNotEmpty);
      expect(en.cooMatrixColStatus, isNotEmpty);

      expect(ar.cooMatrixColDetails, isNotEmpty);
      expect(en.cooMatrixColDetails, isNotEmpty);

      expect(ar.cooOverrideReasonTitle, isNotEmpty);
      expect(en.cooOverrideReasonTitle, isNotEmpty);

      expect(ar.cooOverrideReasonSub, isNotEmpty);
      expect(en.cooOverrideReasonSub, isNotEmpty);

      expect(ar.cooRegistryTitle, isNotEmpty);
      expect(en.cooRegistryTitle, isNotEmpty);

      expect(ar.cooCustomsClearanceNote, isNotEmpty);
      expect(en.cooCustomsClearanceNote, isNotEmpty);
      expect(ar.cooCustomsClearanceNote, isNot(equals(en.cooCustomsClearanceNote)));

      expect(ar.cooDetailsExporterLabel, isNotEmpty);
      expect(en.cooDetailsExporterLabel, isNotEmpty);
      expect(ar.cooDetailsExporterLabel, equals('المصدر'));
      expect(en.cooDetailsExporterLabel, equals('Exporter'));

      expect(ar.cooDetailsImporterLabel, isNotEmpty);
      expect(en.cooDetailsImporterLabel, isNotEmpty);
      expect(ar.cooDetailsImporterLabel, equals('المستورد'));
      expect(en.cooDetailsImporterLabel, equals('Importer'));
    });

    test('Parameterized COO methods format correctly', () {
      expect(ar.cooInvoiceOriginBadge('China'), contains('China'));
      expect(en.cooInvoiceOriginBadge('China'), contains('China'));

      expect(ar.cooApprovedCertBadge('CCPIT'), contains('CCPIT'));
      expect(en.cooApprovedCertBadge('CCPIT'), contains('CCPIT'));

      expect(ar.cooExcelSavedSuccess('/path/to/file.xlsx'), contains('/path/to/file.xlsx'));
      expect(en.cooExcelSavedSuccess('/path/to/file.xlsx'), contains('/path/to/file.xlsx'));

      expect(ar.cooVisualPreviewTitle('EUR.1'), contains('EUR.1'));
      expect(en.cooVisualPreviewTitle('EUR.1'), contains('EUR.1'));

      expect(ar.cooLoadedSessionForEditSnackbar('REV-001'), contains('REV-001'));
      expect(en.cooLoadedSessionForEditSnackbar('REV-001'), contains('REV-001'));

      expect(ar.cooDetailsDialogTitle('REV-001'), contains('REV-001'));
      expect(en.cooDetailsDialogTitle('REV-001'), contains('REV-001'));

      expect(ar.cooDeleteDialogContent('REV-001', 'CERT-123'), contains('REV-001'));
      expect(en.cooDeleteDialogContent('REV-001', 'CERT-123'), contains('CERT-123'));
    });

    test('No stacked bilingual slash ( / ) in COO keys for Arabic or English', () {
      final arStrings = [
        ar.cooStage1Requirements,
        ar.cooStage2DraftInput,
        ar.cooStage3DiscrepancyMatrix,
        ar.cooStage4Registry,
        ar.cooDecisionEngineTitle,
        ar.cooDecisionEngineSub,
        ar.cooRecheckAgreementButton,
        ar.cooManualChoiceRequiredBadge,
        ar.cooReviewRegistryButton,
        ar.cooGenerateDraftHeader,
        ar.cooSelectImportFileLabel,
        ar.cooSearchFileHint,
        ar.cooCertTypeLabel,
        ar.cooCertTypeEur1,
        ar.cooCertTypeChina,
        ar.cooCertTypeFormA,
        ar.cooCertTypeAgadir,
        ar.cooCertTypeGafta,
        ar.cooOpenVisualPreviewButton,
        ar.cooNextDraftInputButton,
        ar.cooDraftInputTitle,
        ar.cooRunComparisonButton,
        ar.cooDraftCertNumberLabel,
        ar.cooOriginCountryLabel,
        ar.cooDestinationCountryLabel,
        ar.cooExporterNameLabel,
        ar.cooExporterRegIdLabel,
        ar.cooImporterNameLabel,
        ar.cooInvoiceNumberLabel,
        ar.cooSmartUploadButtonLabel,
        ar.cooRawTextSectionTitle,
        ar.cooSmartExtractFromTextButton,
        ar.cooCriticalMismatchAlert,
        ar.cooMinorDiscrepancyAlert,
        ar.cooPerfectMatchSuccess,
        ar.cooExportPdfButton,
        ar.cooExportExcelButton,
        ar.cooSaveToRegistryButton,
        ar.cooMatrixColField,
        ar.cooMatrixColSystemValue,
        ar.cooMatrixColDraftValue,
        ar.cooMatrixColStatus,
        ar.cooMatrixColDetails,
        ar.cooOverrideReasonTitle,
        ar.cooOverrideReasonSub,
        ar.cooRegistryTitle,
        ar.cooCustomsClearanceNote,
        ar.cooDetailsExporterLabel,
        ar.cooDetailsImporterLabel,
      ];

      final enStrings = [
        en.cooStage1Requirements,
        en.cooStage2DraftInput,
        en.cooStage3DiscrepancyMatrix,
        en.cooStage4Registry,
        en.cooDecisionEngineTitle,
        en.cooDecisionEngineSub,
        en.cooRecheckAgreementButton,
        en.cooManualChoiceRequiredBadge,
        en.cooReviewRegistryButton,
        en.cooGenerateDraftHeader,
        en.cooSelectImportFileLabel,
        en.cooSearchFileHint,
        en.cooCertTypeLabel,
        en.cooCertTypeEur1,
        en.cooCertTypeChina,
        en.cooCertTypeFormA,
        en.cooCertTypeAgadir,
        en.cooCertTypeGafta,
        en.cooOpenVisualPreviewButton,
        en.cooNextDraftInputButton,
        en.cooDraftInputTitle,
        en.cooRunComparisonButton,
        en.cooDraftCertNumberLabel,
        en.cooOriginCountryLabel,
        en.cooDestinationCountryLabel,
        en.cooExporterNameLabel,
        en.cooExporterRegIdLabel,
        en.cooImporterNameLabel,
        en.cooInvoiceNumberLabel,
        en.cooSmartUploadButtonLabel,
        en.cooRawTextSectionTitle,
        en.cooSmartExtractFromTextButton,
        en.cooCriticalMismatchAlert,
        en.cooMinorDiscrepancyAlert,
        en.cooPerfectMatchSuccess,
        en.cooExportPdfButton,
        en.cooExportExcelButton,
        en.cooSaveToRegistryButton,
        en.cooMatrixColField,
        en.cooMatrixColSystemValue,
        en.cooMatrixColDraftValue,
        en.cooMatrixColStatus,
        en.cooMatrixColDetails,
        en.cooOverrideReasonTitle,
        en.cooOverrideReasonSub,
        en.cooRegistryTitle,
        en.cooCustomsClearanceNote,
        en.cooDetailsExporterLabel,
        en.cooDetailsImporterLabel,
      ];

      for (final s in arStrings) {
        expect(s, isNot(contains(' / ')), reason: 'AR string contains slash: $s');
      }

      for (final s in enStrings) {
        expect(s, isNot(contains(' / ')), reason: 'EN string contains slash: $s');
      }
    });
  });
}
