import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 54: CargoX Hub & Standard Commercial Invoice Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 54 getters return non-empty strings and no missing translations', () {
      // Screen 54 Hub Getters
      expect(ar.cargoxHubTitle.isNotEmpty, true);
      expect(en.cargoxHubTitle.isNotEmpty, true);
      expect(ar.cargoxEmbeddedTitle.isNotEmpty, true);
      expect(en.cargoxEmbeddedTitle.isNotEmpty, true);
      expect(ar.cargoxLiveRefreshTooltip.isNotEmpty, true);
      expect(en.cargoxLiveRefreshTooltip.isNotEmpty, true);

      // Tabs
      expect(ar.cargoxTabStandardInvoice.isNotEmpty, true);
      expect(en.cargoxTabStandardInvoice.isNotEmpty, true);
      expect(ar.cargoxTabCreateEnvelope.isNotEmpty, true);
      expect(en.cargoxTabCreateEnvelope.isNotEmpty, true);
      expect(ar.cargoxTabTrackingHub.isNotEmpty, true);
      expect(en.cargoxTabTrackingHub.isNotEmpty, true);
      expect(ar.cargoxTabManifestViewer.isNotEmpty, true);
      expect(en.cargoxTabManifestViewer.isNotEmpty, true);

      // Standard Commercial Invoice Hub
      expect(ar.standardInvoiceHubTitle.isNotEmpty, true);
      expect(en.standardInvoiceHubTitle.isNotEmpty, true);
      expect(ar.standardInvoiceTabExtracted.isNotEmpty, true);
      expect(en.standardInvoiceTabExtracted.isNotEmpty, true);
      expect(ar.standardInvoiceTabComparison.isNotEmpty, true);
      expect(en.standardInvoiceTabComparison.isNotEmpty, true);
      expect(ar.standardInvoiceTabGovernance.isNotEmpty, true);
      expect(en.standardInvoiceTabGovernance.isNotEmpty, true);
      expect(ar.standardInvoiceTabRegistry.isNotEmpty, true);
      expect(en.standardInvoiceTabRegistry.isNotEmpty, true);

      // Form & Metrics
      expect(ar.cargoxMetricTotalEnvelopes.isNotEmpty, true);
      expect(en.cargoxMetricTotalEnvelopes.isNotEmpty, true);
      expect(ar.cargoxMetricAcceptedCustoms.isNotEmpty, true);
      expect(en.cargoxMetricAcceptedCustoms.isNotEmpty, true);
      expect(ar.cargoxMetricInProgress.isNotEmpty, true);
      expect(en.cargoxMetricInProgress.isNotEmpty, true);
      expect(ar.cargoxMetricAcidVerified.isNotEmpty, true);
      expect(en.cargoxMetricAcidVerified.isNotEmpty, true);

      // Parametrized methods
      expect(ar.cargoxEnvelopeCreatedSuccess('ENV-001'), contains('ENV-001'));
      expect(en.cargoxEnvelopeCreatedSuccess('ENV-001'), contains('ENV-001'));
      expect(ar.cargoxAcidReportDialogTitle('ENV-001'), contains('ENV-001'));
      expect(en.cargoxAcidReportDialogTitle('ENV-001'), contains('ENV-001'));
      expect(ar.cargoxTargetAcidLabel('1234567890123456789'), contains('1234567890123456789'));
      expect(en.cargoxTargetAcidLabel('1234567890123456789'), contains('1234567890123456789'));
      expect(ar.cargoxMatchRatioLabel(4, 4), contains('4'));
      expect(en.cargoxMatchRatioLabel(4, 4), contains('4'));
      expect(ar.cargoxManifestTitle('ENV-001', 'ACID-999'), contains('ENV-001'));
      expect(en.cargoxManifestTitle('ENV-001', 'ACID-999'), contains('ACID-999'));
    });

    test('Arabic translations do not contain Latin characters in static strings', () {
      final staticArabicStrings = [
        ar.cargoxHubTitle,
        ar.cargoxEmbeddedTitle,
        ar.cargoxLiveRefreshTooltip,
        ar.cargoxTabStandardInvoice,
        ar.cargoxTabCreateEnvelope,
        ar.cargoxTabTrackingHub,
        ar.cargoxTabManifestViewer,
        ar.cargoxSegStandardInvoice,
        ar.cargoxSegCreateEnvelope,
        ar.cargoxSegTrackingHub,
        ar.cargoxSegManifestViewer,
        ar.cargoxEnvelopeGenTitle,
        ar.cargoxEnvelopeGenDesc,
        ar.cargoxSection1ShipmentAcid,
        ar.cargoxImportFileField,
        ar.cargoxSearchFileHint,
        ar.cargoxUnlinkedOption,
        ar.cargoxAcidNumberField,
        ar.cargoxAcidValidationDigits,
        ar.cargoxBlNumberField,
        ar.cargoxImporterCompanyField,
        ar.cargoxForeignSupplierField,
        ar.cargoxSupplierCargoxIdField,
        ar.cargoxSection2AttachedDocs,
        ar.cargoxRestoreDefaultDocsBtn,
        ar.cargoxColDocType,
        ar.cargoxColDocNumber,
        ar.cargoxColFileName,
        ar.cargoxColFileSize,
        ar.cargoxColAcidMatch,
        ar.cargoxColActions,
        ar.cargoxDocMatchedBadge,
        ar.cargoxAddDocToEnvelopeBtn,
        ar.cargoxGenerateAndSignEnvelopeBtn,
        ar.cargoxAddDocDialogTitle,
        ar.cargoxDocTypeField,
        ar.cargoxDocNumberField,
        ar.cargoxDocFileNameField,
        ar.cargoxAddDocSubmitBtn,
        ar.cargoxAtLeastOneDocError,
        ar.cargoxEnvelopeCreateError,
        ar.cargoxMetricTotalEnvelopes,
        ar.cargoxMetricAcceptedCustoms,
        ar.cargoxMetricInProgress,
        ar.cargoxMetricAcidVerified,
        ar.cargoxSearchEnvelopesHint,
        ar.cargoxFilterAllStatuses,
        ar.cargoxFilterDraft,
        ar.cargoxFilterUploaded,
        ar.cargoxFilterAccepted,
        ar.cargoxPrepareNewEnvelopeBtn,
        ar.cargoxNoEnvelopesFound,
        ar.cargoxMetaAcidNumber,
        ar.cargoxMetaSupplier,
        ar.cargoxMetaSupplierCargoxId,
        ar.cargoxMetaBlNumber,
        ar.cargoxMetaPendingIssuance,
        ar.cargoxMetaBlockchainTxHash,
        ar.cargoxMetaCustomsReceipt,
        ar.cargoxCheckAcidBtn,
        ar.cargoxDigitalManifestBtn,
        ar.cargoxSealAndTransferBtn,
        ar.cargoxDeliveredAndAcceptedBadge,
        ar.cargoxCopiedToClipboard,
        ar.cargoxAcidCheckError,
        ar.cargoxConfirmSealTransferTitle,
        ar.cargoxConfirmTransferBtn,
        ar.cargoxTransferError,
        ar.cargoxFetchManifestError,
        ar.cargoxSelectEnvelopeForManifestPrompt,
        ar.cargoxCopyJsonBtn,
        ar.cargoxManifestCopiedToast,
        ar.standardInvoiceHubTitle,
        ar.standardInvoiceHubDesc,
        ar.standardInvoiceFileSelectorLabel,
        ar.standardInvoiceFileSelectorHint,
        ar.standardInvoiceFetchError,
        ar.standardInvoiceViewSessionBtn,
        ar.standardInvoiceTool1Title,
        ar.standardInvoiceTool1Subtitle,
        ar.standardInvoiceTool1Btn,
        ar.standardInvoiceTool2Title,
        ar.standardInvoiceTool2Subtitle,
        ar.standardInvoiceTool2Btn,
        ar.standardInvoiceTabExtracted,
        ar.standardInvoiceTabComparison,
        ar.standardInvoiceTabGovernance,
        ar.standardInvoiceTabRegistry,
        ar.standardInvoiceNoExtractedData,
        ar.standardInvoiceNoExtractedDataSub,
        ar.standardInvoiceSellerCardTitle,
        ar.standardInvoiceBuyerCardTitle,
        ar.standardInvoiceExtractedItemsHeader,
        ar.standardInvoiceNoComparisonData,
        ar.standardInvoiceNoComparisonDataSub,
        ar.standardInvoiceMatch100Banner,
        ar.standardInvoiceCompHeadersSection,
        ar.standardInvoiceCompFinancialsSection,
        ar.standardInvoiceCompItemsSection,
        ar.standardInvoiceColComparedField,
        ar.standardInvoiceColSystemValue,
        ar.standardInvoiceColSupplierValue,
        ar.standardInvoiceColMatchStatus,
        ar.standardInvoiceColDiffAndNotes,
        ar.standardInvoiceColHsSystem,
        ar.standardInvoiceColHsSupplier,
        ar.standardInvoiceColQtySystem,
        ar.standardInvoiceColQtySupplier,
        ar.standardInvoiceColPriceSystem,
        ar.standardInvoiceColPriceSupplier,
        ar.standardInvoiceRectificationSectionTitle,
        ar.standardInvoiceRectificationEnTitle,
        ar.standardInvoiceRectificationArTitle,
        ar.standardInvoiceGovernanceTitle,
        ar.standardInvoiceStatusDraft,
        ar.standardInvoiceStatusUnderReview,
        ar.standardInvoiceStatusApproved,
        ar.standardInvoiceStatusRejected,
        ar.standardInvoiceOverrideWarningBanner,
        ar.standardInvoiceOverrideReasonLabel,
        ar.standardInvoiceOverrideReasonHint,
        ar.standardInvoiceOverrideRequiredError,
        ar.standardInvoiceInternalNotesLabel,
        ar.standardInvoiceSaveSessionBtn,
        ar.standardInvoiceRegistrySearchHint,
        ar.standardInvoiceFilterAll,
        ar.standardInvoiceColSessionCode,
        ar.standardInvoiceColFileCode,
        ar.standardInvoiceColAcid,
        ar.standardInvoiceColInvoiceNum,
        ar.standardInvoiceColSupplier,
        ar.standardInvoiceColTotal,
        ar.standardInvoiceColItemsCount,
        ar.standardInvoiceColStatus,
        ar.standardInvoiceColUpdatedAt,
        ar.standardInvoiceNoSessionsFound,
        ar.standardInvoiceSelectFileFirstError,
        ar.standardInvoiceMustProvideOverrideJustification,
      ];

      final latinRegex = RegExp(r'[A-Za-z]');
      for (final str in staticArabicStrings) {
        expect(latinRegex.hasMatch(str), false, reason: 'Arabic string "$str" should not contain Latin characters');
      }
    });
  });
}
