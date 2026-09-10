import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/financial_approval/models/financial_approval_model.dart';

void main() {
  group('Screen 46: SWIFT Message Reconciliation Localization & Export Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 46 getters and methods return non-empty strings in Arabic and English', () {
      // Screen title, metrics & buttons
      expect(ar.swiftScreenTitle, isNotEmpty);
      expect(en.swiftScreenTitle, isNotEmpty);
      expect(ar.swiftRefreshBtn, isNotEmpty);
      expect(en.swiftRefreshBtn, isNotEmpty);
      expect(ar.swiftTotalRequestsMetric, isNotEmpty);
      expect(en.swiftTotalRequestsMetric, isNotEmpty);
      expect(ar.swiftPendingSwiftMetric, isNotEmpty);
      expect(en.swiftPendingSwiftMetric, isNotEmpty);
      expect(ar.swiftMatchedSwiftMetric, isNotEmpty);
      expect(en.swiftMatchedSwiftMetric, isNotEmpty);
      expect(ar.swiftVariancesMetric, isNotEmpty);
      expect(en.swiftVariancesMetric, isNotEmpty);
      expect(ar.swiftAvgProcessingTimeMetric, isNotEmpty);
      expect(en.swiftAvgProcessingTimeMetric, isNotEmpty);
      expect(ar.swiftDaysCount(5), isNotEmpty);
      expect(en.swiftDaysCount(5), isNotEmpty);

      // Extractor tool & cards
      expect(ar.swiftExtractorHeader, isNotEmpty);
      expect(en.swiftExtractorHeader, isNotEmpty);
      expect(ar.swiftExpandToolTooltip, isNotEmpty);
      expect(en.swiftExpandToolTooltip, isNotEmpty);
      expect(ar.swiftExtractedDocLabel, isNotEmpty);
      expect(en.swiftExtractedDocLabel, isNotEmpty);
      expect(ar.swiftDocTypePrefix, isNotEmpty);
      expect(en.swiftDocTypePrefix, isNotEmpty);
      expect(ar.swiftDocSizePrefix, isNotEmpty);
      expect(en.swiftDocSizePrefix, isNotEmpty);
      expect(ar.swiftDocumentDefaultType, isNotEmpty);
      expect(en.swiftDocumentDefaultType, isNotEmpty);
      expect(ar.swiftRawTextPlaceholder, isNotEmpty);
      expect(en.swiftRawTextPlaceholder, isNotEmpty);
      expect(ar.swiftExtractFromTextBtn, isNotEmpty);
      expect(en.swiftExtractFromTextBtn, isNotEmpty);
      expect(ar.swiftUploadFileBtn, isNotEmpty);
      expect(en.swiftUploadFileBtn, isNotEmpty);
      expect(ar.swiftExtractingState, isNotEmpty);
      expect(en.swiftExtractingState, isNotEmpty);
      expect(ar.swiftMatchingMatrixTitle, isNotEmpty);
      expect(en.swiftMatchingMatrixTitle, isNotEmpty);
      expect(ar.swiftConfidenceScoreTag(95), isNotEmpty);
      expect(en.swiftConfidenceScoreTag(95), isNotEmpty);
      expect(ar.swiftExecuteReconcileBtn, isNotEmpty);
      expect(en.swiftExecuteReconcileBtn, isNotEmpty);
      expect(ar.swiftTargetPaymentLabel, isNotEmpty);
      expect(en.swiftTargetPaymentLabel, isNotEmpty);
      expect(ar.swiftExtractedRefPrefix, isNotEmpty);
      expect(en.swiftExtractedRefPrefix, isNotEmpty);
      expect(ar.swiftExtractedAmountPrefix, isNotEmpty);
      expect(en.swiftExtractedAmountPrefix, isNotEmpty);
      expect(ar.swiftExtractedDatePrefix, isNotEmpty);
      expect(en.swiftExtractedDatePrefix, isNotEmpty);
      expect(ar.swiftExtractedSenderPrefix, isNotEmpty);
      expect(en.swiftExtractedSenderPrefix, isNotEmpty);
      expect(ar.swiftExtractedReceiverPrefix, isNotEmpty);
      expect(en.swiftExtractedReceiverPrefix, isNotEmpty);

      // Filters & Search
      expect(ar.swiftSearchPlaceholder, isNotEmpty);
      expect(en.swiftSearchPlaceholder, isNotEmpty);
      expect(ar.swiftFilterAll(10), isNotEmpty);
      expect(en.swiftFilterAll(10), isNotEmpty);
      expect(ar.swiftFilterPending(4), isNotEmpty);
      expect(en.swiftFilterPending(4), isNotEmpty);
      expect(ar.swiftFilterMatched(6), isNotEmpty);
      expect(en.swiftFilterMatched(6), isNotEmpty);
      expect(ar.swiftFilterVariances(1), isNotEmpty);
      expect(en.swiftFilterVariances(1), isNotEmpty);

      // Table Headers
      expect(ar.swiftTableTitle(10), isNotEmpty);
      expect(en.swiftTableTitle(10), isNotEmpty);
      expect(ar.swiftColPaymentCode, isNotEmpty);
      expect(en.swiftColBeneficiaryBank, isNotEmpty);
      expect(ar.swiftColRequestDate, isNotEmpty);
      expect(en.swiftColSwiftDate, isNotEmpty);
      expect(en.swiftColProcessingTime, isNotEmpty);
      expect(ar.swiftColRequestedAmount, isNotEmpty);
      expect(en.swiftColTransferredAmount, isNotEmpty);
      expect(ar.swiftColVarianceStatus, isNotEmpty);
      expect(en.swiftColSwiftRef, isNotEmpty);
      expect(ar.swiftColActions, isNotEmpty);

      // Status Badges & Chips
      expect(ar.swiftBadgeMatchedFull, isNotEmpty);
      expect(en.swiftBadgeMatchedFull, isNotEmpty);
      expect(ar.swiftBadgeDeficit('150.00', 'USD'), isNotEmpty);
      expect(ar.swiftBadgeDeficit('150.00', 'USD'), contains('150.00'));
      expect(ar.swiftBadgeSurplus('200.00', 'EUR'), isNotEmpty);
      expect(en.swiftBadgeSurplus('200.00', 'EUR'), contains('200.00'));
      expect(ar.swiftBadgePending, isNotEmpty);
      expect(en.swiftBadgePending, isNotEmpty);
      expect(ar.swiftStatusUnregistered, isNotEmpty);
      expect(en.swiftStatusUnregistered, isNotEmpty);
      expect(ar.swiftStatusPendingWait, isNotEmpty);
      expect(en.swiftStatusPendingWait, isNotEmpty);
      expect(ar.swiftWaitingAmountEntry, isNotEmpty);
      expect(en.swiftWaitingAmountEntry, isNotEmpty);
      expect(ar.swiftExecutionDaysTag(3), isNotEmpty);
      expect(ar.swiftExecutionInstantTag(2), isNotEmpty);
      expect(ar.swiftExecutionReasonableTag(5), isNotEmpty);
      expect(ar.swiftExecutionDelayedTag(10), isNotEmpty);

      // Action buttons
      expect(ar.swiftRegisterBtn, isNotEmpty);
      expect(en.swiftRegisterBtn, isNotEmpty);
      expect(ar.swiftEditBtn, isNotEmpty);
      expect(en.swiftEditBtn, isNotEmpty);
      expect(ar.swiftDetailsBtn, isNotEmpty);
      expect(en.swiftDetailsBtn, isNotEmpty);
      expect(ar.swiftCloseBtn, isNotEmpty);
      expect(en.swiftCloseBtn, isNotEmpty);
      expect(ar.swiftCancelBtn, isNotEmpty);
      expect(en.swiftCancelBtn, isNotEmpty);
      expect(ar.swiftSaveAndSyncBtn, isNotEmpty);
      expect(en.swiftSaveAndSyncBtn, isNotEmpty);
      expect(ar.swiftPrintSlipBtn, isNotEmpty);
      expect(en.swiftPrintSlipBtn, isNotEmpty);

      // Dialog labels
      expect(ar.swiftReconcileDialogTitle('PAY-001'), contains('PAY-001'));
      expect(en.swiftReconcileDialogTitle('PAY-001'), contains('PAY-001'));
      expect(ar.swiftDetailsDialogTitle('PAY-001'), contains('PAY-001'));
      expect(en.swiftDetailsDialogTitle('PAY-001'), contains('PAY-001'));
      expect(ar.swiftRequestTitleLabel, isNotEmpty);
      expect(ar.swiftBeneficiaryLabel, isNotEmpty);
      expect(ar.swiftBankLabel, isNotEmpty);
      expect(ar.swiftAccountLabel, isNotEmpty);
      expect(ar.swiftRequestDateLabel, isNotEmpty);
      expect(ar.swiftRequestedAmountLabel, isNotEmpty);
      expect(ar.swiftTransferredAmountLabel, isNotEmpty);
      expect(ar.swiftVarianceLabel, isNotEmpty);
      expect(ar.swiftReceiptDateLabel, isNotEmpty);
      expect(ar.swiftCurrencyLabel, isNotEmpty);
      expect(ar.swiftReconciliationNotesLabel, isNotEmpty);
      expect(ar.swiftSyncShipmentNotice, isNotEmpty);
      expect(ar.swiftProcessingTimeLabel, isNotEmpty);

      // Chips & Samples
      expect(ar.swiftSampleMT103Chip, isNotEmpty);
      expect(ar.swiftPasteAndExtractChip, isNotEmpty);
      expect(ar.swiftUploadDocChip, isNotEmpty);

      // Errors & Snacks
      expect(ar.swiftEnterSwiftRefError, isNotEmpty);
      expect(ar.swiftEnterAmountError, isNotEmpty);
      expect(ar.swiftAmountGreaterThanZeroError, isNotEmpty);
      expect(ar.swiftFileReadErrorSnack, isNotEmpty);
      expect(ar.swiftEmptyInputErrorSnack, isNotEmpty);
      expect(ar.swiftParseSuccessSnack, isNotEmpty);
      expect(ar.swiftExtractSuccessSnack('file.pdf', 'PDF'), contains('file.pdf'));
      expect(ar.swiftReconcileSuccessSnack('SWIFT123', 'PAY-001'), contains('SWIFT123'));

      // Export & Copy Getters
      expect(ar.swiftExportTsvBtn, isNotEmpty);
      expect(en.swiftExportTsvBtn, isNotEmpty);
      expect(ar.swiftExportTsvSuccess, isNotEmpty);
      expect(en.swiftExportTsvSuccess, isNotEmpty);
      expect(ar.swiftExportExcelBtn, isNotEmpty);
      expect(en.swiftExportExcelBtn, isNotEmpty);
      expect(ar.swiftExportPdfBtn, isNotEmpty);
      expect(en.swiftExportPdfBtn, isNotEmpty);
      expect(ar.swiftCopySummaryBtn, isNotEmpty);
      expect(en.swiftCopySummarySuccess, isNotEmpty);
      expect(ar.swiftCopyFieldTooltip, isNotEmpty);
      expect(en.swiftCopyFieldTooltip, isNotEmpty);
      expect(ar.swiftCopyBtn, isNotEmpty);
      expect(en.swiftCopyBtn, isNotEmpty);
      expect(ar.swiftAutoSyncNotice, isNotEmpty);
      expect(en.swiftAutoSyncNotice, isNotEmpty);
      expect(ar.swiftNoMatchingPayments, isNotEmpty);
      expect(en.swiftNoMatchingPayments, isNotEmpty);
      expect(ar.swiftPendingSwiftBadge, isNotEmpty);
      expect(en.swiftPendingSwiftBadge, isNotEmpty);
      expect(ar.swiftUnspecifiedBank, isNotEmpty);
      expect(en.swiftUnspecifiedBank, isNotEmpty);
      expect(ar.swiftProcessingPending, isNotEmpty);
      expect(en.swiftProcessingPending, isNotEmpty);
      expect(ar.swiftUnregistered, isNotEmpty);
      expect(en.swiftUnregistered, isNotEmpty);
      expect(ar.swiftCopyDossierBtn, isNotEmpty);
      expect(en.swiftCopyDossierBtn, isNotEmpty);
    });

    test('Zero Latin characters in all Arabic strings for Screen 46', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      // Metrics & titles
      expect(latinPattern.hasMatch(ar.swiftScreenTitle), isFalse);
      expect(latinPattern.hasMatch(ar.swiftRefreshBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTotalRequestsMetric), isFalse);
      expect(latinPattern.hasMatch(ar.swiftPendingSwiftMetric), isFalse);
      expect(latinPattern.hasMatch(ar.swiftMatchedSwiftMetric), isFalse);
      expect(latinPattern.hasMatch(ar.swiftVariancesMetric), isFalse);
      expect(latinPattern.hasMatch(ar.swiftAvgProcessingTimeMetric), isFalse);
      expect(latinPattern.hasMatch(ar.swiftDaysCount(5)), isFalse);

      // Extractor tool
      expect(latinPattern.hasMatch(ar.swiftExtractorHeader), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExpandToolTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractedDocLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftDocTypePrefix), isFalse);
      expect(latinPattern.hasMatch(ar.swiftDocSizePrefix), isFalse);
      expect(latinPattern.hasMatch(ar.swiftDocumentDefaultType), isFalse);
      expect(latinPattern.hasMatch(ar.swiftRawTextPlaceholder), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractFromTextBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftUploadFileBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractingState), isFalse);
      expect(latinPattern.hasMatch(ar.swiftMatchingMatrixTitle), isFalse);
      expect(latinPattern.hasMatch(ar.swiftConfidenceScoreTag(90)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExecuteReconcileBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTargetPaymentLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractedRefPrefix), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractedAmountPrefix), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractedDatePrefix), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractedSenderPrefix), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExtractedReceiverPrefix), isFalse);

      // Toolbar & filter chips
      expect(latinPattern.hasMatch(ar.swiftSearchPlaceholder), isFalse);
      expect(latinPattern.hasMatch(ar.swiftFilterAll(10)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftFilterPending(4)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftFilterMatched(6)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftFilterVariances(1)), isFalse);

      // Table headers & notices
      expect(latinPattern.hasMatch(ar.swiftTableTitle(5)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColPaymentCode), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColBeneficiaryBank), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColRequestDate), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColSwiftDate), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColProcessingTime), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColRequestedAmount), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColTransferredAmount), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColVarianceStatus), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColSwiftRef), isFalse);
      expect(latinPattern.hasMatch(ar.swiftColActions), isFalse);
      expect(latinPattern.hasMatch(ar.swiftAutoSyncNotice), isFalse);

      // Status badges
      expect(latinPattern.hasMatch(ar.swiftBadgeMatchedFull), isFalse);
      expect(latinPattern.hasMatch(ar.swiftBadgePending), isFalse);
      expect(latinPattern.hasMatch(ar.swiftStatusUnregistered), isFalse);
      expect(latinPattern.hasMatch(ar.swiftStatusPendingWait), isFalse);
      expect(latinPattern.hasMatch(ar.swiftWaitingAmountEntry), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExecutionDaysTag(4)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExecutionInstantTag(1)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExecutionReasonableTag(5)), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExecutionDelayedTag(9)), isFalse);

      // Action buttons
      expect(latinPattern.hasMatch(ar.swiftRegisterBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftEditBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftDetailsBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCloseBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCancelBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftSaveAndSyncBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftPrintSlipBtn), isFalse);

      // Dialog labels
      expect(latinPattern.hasMatch(ar.swiftRequestTitleLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftBeneficiaryLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftBankLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftAccountLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftRequestDateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftRequestedAmountLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTransferredAmountLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftVarianceLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftReceiptDateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCurrencyLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftReconciliationNotesLabel), isFalse);
      expect(latinPattern.hasMatch(ar.swiftSyncShipmentNotice), isFalse);
      expect(latinPattern.hasMatch(ar.swiftProcessingTimeLabel), isFalse);

      // Export & Copy
      expect(latinPattern.hasMatch(ar.swiftExportTsvBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExportTsvSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExportExcelBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftExportPdfBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCopySummaryBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCopySummarySuccess), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCopyFieldTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCopyBtn), isFalse);
      expect(latinPattern.hasMatch(ar.swiftNoMatchingPayments), isFalse);
      expect(latinPattern.hasMatch(ar.swiftPendingSwiftBadge), isFalse);
      expect(latinPattern.hasMatch(ar.swiftUnspecifiedBank), isFalse);
      expect(latinPattern.hasMatch(ar.swiftProcessingPending), isFalse);
      expect(latinPattern.hasMatch(ar.swiftUnregistered), isFalse);
      expect(latinPattern.hasMatch(ar.swiftCopyDossierBtn), isFalse);

      // TSV Headers
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderPaymentCode), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderImportFile), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderBeneficiary), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderBank), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderRequestDate), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderSwiftReceiptDate), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderProcessingDays), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderRequestedAmount), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderTransferredAmount), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderVariance), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderSwiftRef), isFalse);
      expect(latinPattern.hasMatch(ar.swiftTsvHeaderStatus), isFalse);
    });

    test('TSV headers count equals 12 in both Arabic and English', () {
      final arHeaders = [
        ar.swiftTsvHeaderPaymentCode,
        ar.swiftTsvHeaderImportFile,
        ar.swiftTsvHeaderBeneficiary,
        ar.swiftTsvHeaderBank,
        ar.swiftTsvHeaderRequestDate,
        ar.swiftTsvHeaderSwiftReceiptDate,
        ar.swiftTsvHeaderProcessingDays,
        ar.swiftTsvHeaderRequestedAmount,
        ar.swiftTsvHeaderTransferredAmount,
        ar.swiftTsvHeaderVariance,
        ar.swiftTsvHeaderSwiftRef,
        ar.swiftTsvHeaderStatus,
      ];

      final enHeaders = [
        en.swiftTsvHeaderPaymentCode,
        en.swiftTsvHeaderImportFile,
        en.swiftTsvHeaderBeneficiary,
        en.swiftTsvHeaderBank,
        en.swiftTsvHeaderRequestDate,
        en.swiftTsvHeaderSwiftReceiptDate,
        en.swiftTsvHeaderProcessingDays,
        en.swiftTsvHeaderRequestedAmount,
        en.swiftTsvHeaderTransferredAmount,
        en.swiftTsvHeaderVariance,
        en.swiftTsvHeaderSwiftRef,
        en.swiftTsvHeaderStatus,
      ];

      expect(arHeaders.length, equals(12));
      expect(enHeaders.length, equals(12));

      for (int i = 0; i < 12; i++) {
        expect(arHeaders[i].trim().isNotEmpty, isTrue);
        expect(enHeaders[i].trim().isNotEmpty, isTrue);
      }
    });

    test('PaymentRequestModel SWIFT properties map and format correctly', () {
      final pay = PaymentRequestModel(
        paymentId: 101,
        paymentCode: 'PAY-2026-001',
        title: 'Advance Payment',
        paymentType: 'SupplierPayment',
        requestedAmount: 25000.0,
        requestedAmountEgp: 1250000.0,
        dueDate: '2026-09-10',
        currencyCode: 'USD',
        status: 'Paid',
        importFileId: 5,
        importFileCode: 'IMP-2026-088',
        supplierName: 'Global Tech Co.',
        beneficiaryName: 'Global Tech Co.',
        bankName: 'National Bank of Egypt',
        swiftCode: 'NBEGEGCX',
        ibanAccountNo: 'EG1234567890123456789012345',
        requestDate: '2026-09-01',
        swiftReferenceNo: 'MT103-99887766',
        swiftReceiptDate: '2026-09-03',
        swiftTransferredAmount: 25000.0,
        swiftTransferredCurrency: 'USD',
        swiftVarianceAmount: 0.0,
        swiftVarianceStatus: 'Matched',
        swiftProcessingDays: 2,
        swiftReconciliationNotes: 'Fully matched automatically via AI extractor',
        createdAt: '2026-09-01T10:00:00Z',
        updatedAt: '2026-09-03T12:00:00Z',
      );

      expect(pay.paymentCode, equals('PAY-2026-001'));
      expect(pay.swiftReferenceNo, equals('MT103-99887766'));
      expect(pay.swiftVarianceStatus, equals('Matched'));
      expect(pay.swiftProcessingDays, equals(2));
      expect(pay.requestedAmount, equals(25000.0));
      expect(pay.swiftTransferredAmount, equals(25000.0));
    });
  });
}
