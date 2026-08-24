import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 53: Draft Inspection COC Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('Stepper steps are properly localized without bilingual stacking', () {
      expect(ar.inspStepRequirements, contains('متطلبات شهادة الفحص'));
      expect(en.inspStepRequirements, contains('Requirements'));

      expect(ar.inspStepDraftInput, contains('إدخال واستخراج الدرافت'));
      expect(en.inspStepDraftInput, contains('Draft Input'));

      expect(ar.inspStepDiscrepancyMatrix, contains('مصفوفة المقارنة والفروق'));
      expect(en.inspStepDiscrepancyMatrix, contains('Discrepancy'));

      expect(ar.inspStepRegistry, contains('سجل شهادات الفحص المعتمدة'));
      expect(en.inspStepRegistry, contains('Registry'));
    });

    test('Step 1 (Requirements) getters return accurate text', () {
      expect(ar.inspRequirementsHeader, contains('توليد متطلبات شهادة الفحص'));
      expect(en.inspRequirementsHeader, contains('Pre-Shipment Inspection'));

      expect(ar.selectInspectionFileLabel, contains('اختر ملف الشحنة'));
      expect(en.selectInspectionFileLabel, contains('Select Import File'));

      expect(ar.inspectionCertTypeLabel, contains('نوع شهادة الفحص'));
      expect(en.inspectionCertTypeLabel, contains('Inspection Certificate Type'));

      expect(ar.optInspectionCoc, contains('شهادة المطابقة النوعية'));
      expect(en.optInspectionCoc, contains('COC'));
      expect(ar.optInspectionCoa, contains('شهادة التحليل المخبري'));
      expect(en.optInspectionCoa, contains('COA'));
      expect(ar.optInspectionVoc, contains('التحقق من المطابقة'));
      expect(en.optInspectionVoc, contains('VOC'));
      expect(ar.optInspectionPsi, contains('تقرير المعاينة قبل الشحن'));
      expect(en.optInspectionPsi, contains('PSI'));

      expect(ar.inspectionAgencyLabel, contains('جهة الفحص'));
      expect(en.inspectionAgencyLabel, contains('Inspection Agency'));

      expect(ar.openInspectionPreviewBtn, contains('فتح المعاينة والتصدير'));
      expect(en.openInspectionPreviewBtn, contains('Preview'));

      expect(ar.nextInspectionInputBtn, contains('التالي'));
      expect(en.nextInspectionInputBtn, contains('Next'));
    });

    test('Step 2 (Smart Input) getters return accurate text', () {
      expect(ar.inspDraftInputHeader, contains('إدخال واستخراج بيانات درافت شهادة الفحص'));
      expect(en.inspDraftInputHeader, contains('Draft Data Input'));

      expect(ar.runInspectionComparisonBtn, contains('تشغيل المطابقة'));
      expect(en.runInspectionComparisonBtn, contains('Run Matching'));

      expect(ar.linkedInspectionFileLabel, contains('اختر ملف الشحنة المربوط'));
      expect(en.linkedInspectionFileLabel, contains('Linked Import File'));

      expect(ar.certNumberFieldLabel, contains('رقم درافت الشهادة'));
      expect(en.certNumberFieldLabel, contains('Draft Certificate Number'));

      expect(ar.regulatoryAuthorityFieldLabel, contains('الجهة الرقابية المصرية المختصة'));
      expect(en.regulatoryAuthorityFieldLabel, contains('Regulatory Authority'));

      expect(ar.inspectedInvoiceNumberFieldLabel, contains('رقم الفاتورة الخاضعة للفحص'));
      expect(en.inspectedInvoiceNumberFieldLabel, contains('Inspected Invoice Number'));

      expect(ar.exporterShipperFieldLabel, contains('اسم المصدر'));
      expect(en.exporterShipperFieldLabel, contains('Exporter'));

      expect(ar.importerApplicantFieldLabel, contains('اسم المستورد'));
      expect(en.importerApplicantFieldLabel, contains('Importer'));

      expect(ar.standardSpecFieldLabel, contains('المواصفة القياسية المعتمدة'));
      expect(en.standardSpecFieldLabel, contains('Standard Specification'));

      expect(ar.acidNumberFieldLabel, contains('رقم القيد الجمركي المسبق'));
      expect(en.acidNumberFieldLabel, contains('ACID'));

      expect(ar.countryOfOriginFieldLabel, contains('بلد المنشأ'));
      expect(en.countryOfOriginFieldLabel, contains('Country of Origin'));

      expect(ar.smartUploadInspectionBtn, contains('رفع واستخراج شهادة الفحص الذكي'));
      expect(en.smartUploadInspectionBtn, contains('Upload'));

      expect(ar.rawTextInspectionHeader, contains('النص الخام لدرافت شهادة الفحص'));
      expect(en.rawTextInspectionHeader, contains('Raw Text'));

      expect(ar.smartExtractFromTextBtn, contains('استخراج ومطابقة ذكية من النص'));
      expect(en.smartExtractFromTextBtn, contains('Smart Extract'));
    });

    test('Step 3 (Discrepancy Matrix) getters and matching statuses return accurate text', () {
      expect(ar.hasCriticalMismatchStatus, contains('توجد اختلافات حرجة'));
      expect(en.hasCriticalMismatchStatus, contains('Critical discrepancies'));

      expect(ar.hasMinorDiscrepanciesStatus, contains('توجد فروق طفيفة'));
      expect(en.hasMinorDiscrepanciesStatus, contains('Minor discrepancies'));

      expect(ar.inspectionConforms100Status, contains('شهادة الفحص مطابقة'));
      expect(en.inspectionConforms100Status, contains('100% conforming'));

      expect(ar.colInspField, contains('الحقل'));
      expect(en.colInspField, contains('Field'));

      expect(ar.colInspSystemValue, contains('القيمة بالنظام'));
      expect(en.colInspSystemValue, contains('System Value'));

      expect(ar.colInspDraftValue, contains('القيمة بالدرافت'));
      expect(en.colInspDraftValue, contains('Draft Value'));

      expect(ar.colInspMatchStatus, contains('حالة التطابق'));
      expect(en.colInspMatchStatus, contains('Match Status'));

      expect(ar.colInspDetails, contains('التفاصيل'));
      expect(en.colInspDetails, contains('Details'));

      expect(ar.inspOverrideReasonBoxTitle, contains('سبب ومبررات الموافقة'));
      expect(en.inspOverrideReasonBoxTitle, contains('Justification'));

      expect(ar.approveAndSaveWithReasonBtn, contains('اعتماد وحفظ مع ذكر سبب الموافقة'));
      expect(en.approveAndSaveWithReasonBtn, contains('Approve'));

      expect(ar.returnToEditAndContactSupplierBtn, contains('العودة لتعديل المسودة ومخاطبة المورد'));
      expect(en.returnToEditAndContactSupplierBtn, contains('Return to Edit'));
    });

    test('Step 4 (Registry) table headers and actions return accurate text', () {
      expect(ar.inspReviewsRegistryTitle(3), contains('سجل مراجعات واعتماد شهادات الفحص والتفتيش (3 جلسة)'));
      expect(en.inspReviewsRegistryTitle(3), contains('Reviews Registry (3 sessions)'));

      expect(ar.startNewInspReviewBtn, contains('بدء مراجعة جديدة'));
      expect(en.startNewInspReviewBtn, contains('New Review'));

      expect(ar.colInspSessionCode, contains('كود الجلسة'));
      expect(en.colInspSessionCode, contains('Session Code'));

      expect(ar.colInspCertType, contains('نوع الفحص'));
      expect(en.colInspCertType, contains('Inspection Type'));

      expect(ar.colInspAgency, contains('جهة الفحص'));
      expect(en.colInspAgency, contains('Agency'));

      expect(ar.colInspCertNo, contains('رقم الشهادة'));
      expect(en.colInspCertNo, contains('Certificate No.'));

      expect(ar.colInspStatus, contains('الحالة'));
      expect(en.colInspStatus, contains('Status'));

      expect(ar.colInspCreatedAt, contains('تاريخ الإنشاء'));
      expect(en.colInspCreatedAt, contains('Created At'));

      expect(ar.colInspActions, contains('الإجراءات'));
      expect(en.colInspActions, contains('Actions'));
    });

    test('Visual Draft Inspection Sheet labels return pure Arabic without English stacking', () {
      expect(ar.egyptVerificationOfConformityHeader, contains('التحقق الإلزامي من المطابقة في مصر'));
      expect(en.egyptVerificationOfConformityHeader, contains('EGYPT MANDATORY VERIFICATION'));

      expect(ar.importerCellLabel, contains('المستورد'));
      expect(en.importerCellLabel, contains('Importer'));

      expect(ar.exporterCellLabel, contains('المصدر'));
      expect(en.exporterCellLabel, contains('Exporter'));

      expect(ar.countryOfOriginHeader, contains('بلاد المنشأ المستدعاة'));
      expect(en.countryOfOriginHeader, contains('Countries of Origin'));

      expect(ar.hsCodesHeader, contains('بنود التعريفة الجمركية'));
      expect(en.hsCodesHeader, contains('H.S. Codes'));

      expect(ar.commercialInvoicesHeader, contains('الفواتير التجارية المرفقة الخاضعة للفحص'));
      expect(en.commercialInvoicesHeader, contains('Commercial Invoices'));

      expect(ar.egyptianMandatoryStandardsHeader, contains('المواصفات القياسية المصرية'));
      expect(en.egyptianMandatoryStandardsHeader, contains('Egyptian Mandatory Standards'));

      expect(ar.conformityAssessmentResultConforming, contains('نتيجة تقييم المطابقة: مطابق وصالح للإفراج الجمركي'));
      expect(en.conformityAssessmentResultConforming, contains('CONFORMITY ASSESSMENT RESULT'));

      expect(ar.egyptianCustomsComplianceHeader, contains('الامتثال الجمركي والرقابي المصري'));
      expect(en.egyptianCustomsComplianceHeader, contains('Egyptian Customs & Regulatory Compliance'));
    });

    test('Parameterized inspection methods format strings correctly in Arabic and English', () {
      expect(ar.methodOfShipmentLabel('Sea'), contains('طريقة الشحن: Sea'));
      expect(en.methodOfShipmentLabel('Sea'), contains('Method of Shipment: Sea'));

      expect(ar.countryOfShipmentLabel('Italy'), contains('بلد الشحن: Italy'));
      expect(en.countryOfShipmentLabel('Italy'), contains('Country of Shipment: Italy'));

      expect(ar.pointOfEntryLabel('Alexandria'), contains('ميناء الوصول: Alexandria'));
      expect(en.pointOfEntryLabel('Alexandria'), contains('Point of Entry: Alexandria'));

      expect(ar.totalDeclaredValueLabel('50,000 EUR'), contains('القيمة الإجمالية المصرح عنها: 50,000 EUR'));
      expect(en.totalDeclaredValueLabel('50,000 EUR'), contains('Total Declared Value: 50,000 EUR'));

      expect(ar.placeOfInspectionLabel('Milan'), contains('مكان الفحص: Milan'));
      expect(en.placeOfInspectionLabel('Milan'), contains('Place of Inspection: Milan'));

      expect(ar.dateOfInspectionLabel('2026-08-24'), contains('تاريخ الفحص: 2026-08-24'));
      expect(en.dateOfInspectionLabel('2026-08-24'), contains('Date of Inspection: 2026-08-24'));

      expect(ar.issuingOfficeLabel('SGS Milan'), contains('المكتب المصدر: SGS Milan'));
      expect(en.issuingOfficeLabel('SGS Milan'), contains('Issuing Office: SGS Milan'));

      expect(ar.authorizedAgencyLabel('SGS'), contains('الجهة المعتمدة: SGS'));
      expect(en.authorizedAgencyLabel('SGS'), contains('Authorized Agency: SGS'));

      expect(ar.confirmDeleteInspSessionContent('INSP-01', 'CERT-99'), contains('INSP-01'));
      expect(ar.confirmDeleteInspSessionContent('INSP-01', 'CERT-99'), contains('CERT-99'));
    });
  });
}
