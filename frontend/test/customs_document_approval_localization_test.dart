import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 20: Draft Docs Customs Approval Hub Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 20 getters return non-empty strings and differ between AR and EN', () {
      expect(ar.customsApprovalImportFileLabel, isNotEmpty);
      expect(en.customsApprovalImportFileLabel, isNotEmpty);
      expect(ar.customsApprovalImportFileLabel, isNot(equals(en.customsApprovalImportFileLabel)));

      expect(ar.customsApprovalSearchFileHint, isNotEmpty);
      expect(en.customsApprovalSearchFileHint, isNotEmpty);

      expect(ar.customsApprovalRunAiMatrixButton, isNotEmpty);
      expect(en.customsApprovalRunAiMatrixButton, isNotEmpty);

      expect(ar.customsApprovalAutoGenerateStandardListButton, isNotEmpty);
      expect(en.customsApprovalAutoGenerateStandardListButton, isNotEmpty);

      expect(ar.customsApprovalRaiseTicketButton, isNotEmpty);
      expect(en.customsApprovalRaiseTicketButton, isNotEmpty);

      expect(ar.customsApprovalFilterAll, isNotEmpty);
      expect(en.customsApprovalFilterAll, isNotEmpty);

      expect(ar.customsApprovalFilterPending, isNotEmpty);
      expect(en.customsApprovalFilterPending, isNotEmpty);

      expect(ar.customsApprovalFilterApproved, isNotEmpty);
      expect(en.customsApprovalFilterApproved, isNotEmpty);

      expect(ar.customsApprovalFilterRejected, isNotEmpty);
      expect(en.customsApprovalFilterRejected, isNotEmpty);

      expect(ar.customsApprovalFilterDiscrepancy, isNotEmpty);
      expect(en.customsApprovalFilterDiscrepancy, isNotEmpty);

      expect(ar.customsApprovalTabDualSignoff, isNotEmpty);
      expect(en.customsApprovalTabDualSignoff, isNotEmpty);

      expect(ar.customsApprovalTabCentralArchive, isNotEmpty);
      expect(en.customsApprovalTabCentralArchive, isNotEmpty);

      expect(ar.customsApprovalDualTierHeader, isNotEmpty);
      expect(en.customsApprovalDualTierHeader, isNotEmpty);

      expect(ar.customsApprovalNoDocuments, isNotEmpty);
      expect(en.customsApprovalNoDocuments, isNotEmpty);

      expect(ar.customsApprovalTicketsHeader, isNotEmpty);
      expect(en.customsApprovalTicketsHeader, isNotEmpty);

      expect(ar.customsApprovalNewTicketButton, isNotEmpty);
      expect(en.customsApprovalNewTicketButton, isNotEmpty);

      expect(ar.customsApprovalNoTickets, isNotEmpty);
      expect(en.customsApprovalNoTickets, isNotEmpty);

      expect(ar.customsApprovalResolveTicketButton, isNotEmpty);
      expect(en.customsApprovalResolveTicketButton, isNotEmpty);

      expect(ar.customsApprovalCommercialReviewerLabel, isNotEmpty);
      expect(en.customsApprovalCommercialReviewerLabel, isNotEmpty);

      expect(ar.customsApprovalCommercialDecisionLabel, isNotEmpty);
      expect(en.customsApprovalCommercialDecisionLabel, isNotEmpty);

      expect(ar.customsApprovalBrokerOfficeLabel, isNotEmpty);
      expect(en.customsApprovalBrokerOfficeLabel, isNotEmpty);

      expect(ar.customsApprovalBrokerReviewerNameLabel, isNotEmpty);
      expect(en.customsApprovalBrokerReviewerNameLabel, isNotEmpty);

      expect(ar.customsApprovalBrokerDecisionLabel, isNotEmpty);
      expect(en.customsApprovalBrokerDecisionLabel, isNotEmpty);

      expect(ar.customsApprovalRaiseTicketDialogTitle, isNotEmpty);
      expect(en.customsApprovalRaiseTicketDialogTitle, isNotEmpty);

      expect(ar.customsApprovalIssueCategoryLabel, isNotEmpty);
      expect(en.customsApprovalIssueCategoryLabel, isNotEmpty);

      expect(ar.customsApprovalCatHsMismatch, isNotEmpty);
      expect(en.customsApprovalCatHsMismatch, isNotEmpty);

      expect(ar.customsApprovalCatWeightDiscrepancy, isNotEmpty);
      expect(en.customsApprovalCatWeightDiscrepancy, isNotEmpty);

      expect(ar.customsApprovalCatCbmDiscrepancy, isNotEmpty);
      expect(en.customsApprovalCatCbmDiscrepancy, isNotEmpty);

      expect(ar.customsApprovalCatValueMismatch, isNotEmpty);
      expect(en.customsApprovalCatValueMismatch, isNotEmpty);

      expect(ar.customsApprovalCatMissingAcid, isNotEmpty);
      expect(en.customsApprovalCatMissingAcid, isNotEmpty);

      expect(ar.customsApprovalCatIncotermConflict, isNotEmpty);
      expect(en.customsApprovalCatIncotermConflict, isNotEmpty);

      expect(ar.customsApprovalCatOther, isNotEmpty);
      expect(en.customsApprovalCatOther, isNotEmpty);

      expect(ar.customsApprovalSeverityLabel, isNotEmpty);
      expect(en.customsApprovalSelectSeverityHint, isNotEmpty);

      expect(ar.customsApprovalSevCritical, isNotEmpty);
      expect(en.customsApprovalSevMajor, isNotEmpty);
      expect(en.customsApprovalSevMinor, isNotEmpty);

      expect(ar.customsApprovalIssueDescLabel, isNotEmpty);
      expect(ar.customsApprovalExpectedValueLabel, isNotEmpty);
      expect(ar.customsApprovalFoundValueLabel, isNotEmpty);
      expect(ar.customsApprovalSupplierActionLabel, isNotEmpty);
      expect(ar.customsApprovalCreateTicketSubmitButton, isNotEmpty);

      expect(ar.customsApprovalSupplierResponseLabel, isNotEmpty);
      expect(ar.customsApprovalResolverNameLabel, isNotEmpty);
      expect(ar.customsApprovalFinalStatusLabel, isNotEmpty);
      expect(ar.customsApprovalConfirmResolveTicketButton, isNotEmpty);
    });

    test('Screen 20 Document Type getters resolve cleanly in AR and EN', () {
      expect(ar.customsApprovalDocCommercialInvoice, equals('الفاتورة التجارية'));
      expect(en.customsApprovalDocCommercialInvoice, equals('Commercial Invoice'));

      expect(ar.customsApprovalDocPackingList, equals('بيان التعبئة والتغليف'));
      expect(en.customsApprovalDocPackingList, equals('Packing List'));

      expect(ar.customsApprovalDocBillOfLading, equals('بوليصة الشحن'));
      expect(en.customsApprovalDocBillOfLading, equals('Bill of Lading'));

      expect(ar.customsApprovalDocCertificateOfOrigin, equals('شهادة المنشأ'));
      expect(en.customsApprovalDocCertificateOfOrigin, equals('Certificate of Origin'));

      expect(ar.customsApprovalDocEur1, equals('شهادة الحركة يورو 1'));
      expect(en.customsApprovalDocEur1, equals('EUR.1 Movement Certificate'));

      expect(ar.customsApprovalDocInspectionCertificate, equals('شهادة الفحص والتفتيش'));
      expect(en.customsApprovalDocInspectionCertificate, equals('Inspection Certificate'));

      expect(ar.customsApprovalDocBankForm4, equals('نموذج 4 البنكي'));
      expect(en.customsApprovalDocBankForm4, equals('Bank Form 4'));

      expect(ar.customsApprovalDocProformaInvoice, equals('الفاتورة المبدئية'));
      expect(en.customsApprovalDocProformaInvoice, equals('Proforma Invoice'));
    });

    test('Screen 20 Status and Compliance resolvers return pure single-language values', () {
      // Overall Statuses
      expect(ar.customsApprovalStatusApprovedForClearance, equals('معتمد للإفراج الجمركي'));
      expect(en.customsApprovalStatusApprovedForClearance, equals('Approved for Clearance'));

      expect(ar.customsApprovalStatusRectificationRequired, equals('مطلوب استدراك وتعديل'));
      expect(en.customsApprovalStatusRectificationRequired, equals('Rectification Required'));

      expect(ar.customsApprovalStatusConditionallyApproved, equals('معتمد بشرط'));
      expect(en.customsApprovalStatusConditionallyApproved, equals('Conditionally Approved'));

      expect(ar.customsApprovalStatusUnderReview, equals('قيد المراجعة'));
      expect(en.customsApprovalStatusUnderReview, equals('Under Review'));

      expect(ar.customsApprovalStatusDraft, equals('مسودة'));
      expect(en.customsApprovalStatusDraft, equals('Draft'));

      expect(ar.customsApprovalStatusRejected, equals('مرفوض'));
      expect(en.customsApprovalStatusRejected, equals('Rejected'));

      // Compliance
      expect(ar.customsApprovalComplianceFullyCompliant, equals('مطابق بالكامل'));
      expect(en.customsApprovalComplianceFullyCompliant, equals('Fully Compliant'));

      expect(ar.customsApprovalComplianceNonCompliant, equals('غير مطابق'));
      expect(en.customsApprovalComplianceNonCompliant, equals('Non-Compliant'));

      expect(ar.customsApprovalComplianceDiscrepancies, equals('توجد فروق وتناقضات'));
      expect(en.customsApprovalComplianceDiscrepancies, equals('Discrepancies Found'));

      expect(ar.customsApprovalComplianceCriticalBlocker, equals('مانع حرج للشحن'));
      expect(en.customsApprovalComplianceCriticalBlocker, equals('Critical Blocker'));

      // Ticket Severities
      expect(ar.customsApprovalSevCriticalBadge, equals('حرج'));
      expect(en.customsApprovalSevCriticalBadge, equals('Critical'));

      expect(ar.customsApprovalSevMajorBadge, equals('رئيسي'));
      expect(en.customsApprovalSevMajorBadge, equals('Major'));

      expect(ar.customsApprovalSevMinorBadge, equals('بسيط'));
      expect(en.customsApprovalSevMinorBadge, equals('Minor'));

      // Ticket Statuses
      expect(ar.customsApprovalTicketStatusOpen, equals('مفتوحة'));
      expect(en.customsApprovalTicketStatusOpen, equals('Open'));

      expect(ar.customsApprovalStatusResolved, equals('تم تصحيح المسودة'));
      expect(en.customsApprovalStatusResolved, equals('Resolved (Draft Corrected)'));

      expect(ar.customsApprovalStatusWaived, equals('تم التنازل مع تعهد'));
      expect(en.customsApprovalStatusWaived, equals('Waived with Undertaking'));

      expect(ar.customsApprovalStatusClosed, equals('مغلقة'));
      expect(en.customsApprovalStatusClosed, equals('Closed'));
    });

    test('Screen 20 Default Reviewer titles are localized in AR and EN without hardcoded English', () {
      expect(ar.customsApprovalDefaultCommercialReviewer, equals('المراجع التجاري المختص'));
      expect(en.customsApprovalDefaultCommercialReviewer, equals('Commercial Specialist'));

      expect(ar.customsApprovalDefaultBrokerOffice, equals('مكتب التخليص الجمركي المعتمد'));
      expect(en.customsApprovalDefaultBrokerOffice, equals('Licensed Customs Broker'));

      expect(ar.customsApprovalDefaultLegalOfficer, equals('المراجع القانوني'));
      expect(en.customsApprovalDefaultLegalOfficer, equals('Legal Officer'));

      expect(ar.customsApprovalDefaultComplianceOfficer, equals('مسؤول المطابقة'));
      expect(en.customsApprovalDefaultComplianceOfficer, equals('Compliance Specialist'));
    });

    test('Screen 20 Arabic keys are free from slashes and stacked abbreviations', () {
      final arabicKeys = [
        ar.customsApprovalBrokerOfficeLabel,
        ar.customsApprovalBrokerReviewerNameLabel,
        ar.customsApprovalRaiseTicketDialogTitle,
        ar.customsApprovalIssueCategoryLabel,
        ar.customsApprovalCatHsMismatch,
        ar.customsApprovalCatWeightDiscrepancy,
        ar.customsApprovalCatCbmDiscrepancy,
        ar.customsApprovalCatValueMismatch,
        ar.customsApprovalCatMissingAcid,
        ar.customsApprovalCatIncotermConflict,
        ar.customsApprovalSevCritical,
        ar.customsApprovalSevMajor,
        ar.customsApprovalSevMinor,
        ar.customsApprovalResolveTicketButton,
        ar.customsApprovalSupplierResponseLabel,
      ];

      for (final key in arabicKeys) {
        expect(key.contains('/'), isFalse, reason: 'Arabic key "$key" contains slash "/"');
        expect(key.contains('HS Code'), isFalse, reason: 'Arabic key "$key" contains English "HS Code"');
        expect(key.contains('CBM'), isFalse, reason: 'Arabic key "$key" contains English "CBM"');
        expect(key.contains('ACID'), isFalse, reason: 'Arabic key "$key" contains English "ACID"');
        expect(key.contains('Incoterms'), isFalse, reason: 'Arabic key "$key" contains English "Incoterms"');
      }
    });

    test('Parameterized methods format without raw English fragments in Arabic', () {
      final matrixResultAr = ar.customsApprovalMatrixComplianceResult('مطابق بالكامل', 7, 7);
      expect(matrixResultAr, contains('نتيجة المطابقة المتقاطعة: مطابق بالكامل (7 من 7 مطابق)'));
      expect(matrixResultAr.contains('/'), isFalse);

      final matrixResultEn = en.customsApprovalMatrixComplianceResult('Fully Compliant', 7, 7);
      expect(matrixResultEn, contains('Cross-Check Compliance Result: Fully Compliant (7 of 7 matched)'));

      final commReviewAr = ar.customsApprovalCommercialReviewStatus('معتمد');
      expect(commReviewAr, equals('المراجعة التجارية: معتمد'));

      final commReviewEn = en.customsApprovalCommercialReviewStatus('Approved');
      expect(commReviewEn, equals('Commercial Review: Approved'));

      final brokerReviewAr = ar.customsApprovalBrokerReviewStatus('معتمد');
      expect(brokerReviewAr, equals('اعتماد المخلص الجمركي: معتمد'));

      final brokerReviewEn = en.customsApprovalBrokerReviewStatus('Approved');
      expect(brokerReviewEn, equals('Customs Broker Sign-off: Approved'));

      final ticketVsFoundAr = ar.customsApprovalTicketExpectedVsFound('8415.10', '8415.20');
      expect(ticketVsFoundAr, equals('المتوقع: 8415.10 ➔ الوارد بالمسودة: 8415.20'));

      final ticketVsFoundEn = en.customsApprovalTicketExpectedVsFound('8415.10', '8415.20');
      expect(ticketVsFoundEn, equals('Expected: 8415.10 ➔ Found in Draft: 8415.20'));
    });
  });
}
