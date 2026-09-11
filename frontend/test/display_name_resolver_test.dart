import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/display_name_resolver.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('DisplayNameResolver Unit Tests (Task D)', () {
    // ── 1. Step / Operation Code Resolution Tests ─────────────────────────────
    test('All 21 step codes (STEP_01 to STEP_21) resolve to clean names in Arabic and English', () {
      final stepKeys = List.generate(21, (i) => 'STEP_${(i + 1).toString().padLeft(2, '0')}');

      for (final stepKey in stepKeys) {
        final arName = DisplayNameResolver.resolveStepName(stepKey, isArabic: true);
        final enName = DisplayNameResolver.resolveStepName(stepKey, isArabic: false);

        expect(arName, isNotEmpty, reason: '$stepKey Arabic name should not be empty');
        expect(enName, isNotEmpty, reason: '$stepKey English name should not be empty');
        expect(arName, isNot(contains('STEP_')), reason: '$stepKey Arabic name must not contain STEP_');
        expect(enName, isNot(contains('STEP_')), reason: '$stepKey English name must not contain STEP_');
      }

      // Explicit spot-checks
      expect(DisplayNameResolver.resolveStepName('STEP_01', isArabic: true), 'دراسات ومفاضلة النولون');
      expect(DisplayNameResolver.resolveStepName('STEP_01', isArabic: false), 'Freight Studies');
      expect(DisplayNameResolver.resolveStepName('STEP_05', isArabic: true), 'إصدار رقم التسجيل المسبق نافذة');
      expect(DisplayNameResolver.resolveStepName('STEP_05', isArabic: false), 'Nafeza ACID Issue');
      expect(DisplayNameResolver.resolveStepName('STEP_07', isArabic: true), 'تخصيص وتوزيع الحاويات والبضائع');
      expect(DisplayNameResolver.resolveStepName('STEP_07', isArabic: false), 'Container Allocation');
      expect(DisplayNameResolver.resolveStepName('STEP_10', isArabic: true), 'رفع التوثيق الإلكتروني للشاحن');
      expect(DisplayNameResolver.resolveStepName('STEP_10', isArabic: false), 'CargoX Upload');
      expect(DisplayNameResolver.resolveStepName('STEP_13', isArabic: true), 'قيد إقرار 46 ك.م جمركي');
      expect(DisplayNameResolver.resolveStepName('STEP_13', isArabic: false), 'Form 46 KM');
      expect(DisplayNameResolver.resolveStepName('STEP_17', isArabic: true), 'سداد الضرائب والرسوم الجمركية');
      expect(DisplayNameResolver.resolveStepName('STEP_17', isArabic: false), 'Duty Payment');
      expect(DisplayNameResolver.resolveStepName('STEP_21', isArabic: true), 'إغلاق وأرشفة الملف نهائياً');
      expect(DisplayNameResolver.resolveStepName('STEP_21', isArabic: false), 'File Archive & Close');
    });

    test('Case-insensitivity and formatting variations for step codes', () {
      expect(DisplayNameResolver.resolveStepName('step_07', isArabic: true), 'تخصيص وتوزيع الحاويات والبضائع');
      expect(DisplayNameResolver.resolveStepName('step_7', isArabic: false), 'Container Allocation');
      expect(DisplayNameResolver.resolveStepName('STEP_14', isArabic: true), 'الكشف والمعاينة والتثمين');
    });

    test('Resolves operational stage phrases to canonical operation names', () {
      expect(DisplayNameResolver.resolveStepName('Freight Studies', isArabic: true), 'دراسات ومفاضلة النولون');
      expect(DisplayNameResolver.resolveStepName('Customs Studies', isArabic: true), 'الدراسات والاستشارات الجمركية');
      expect(DisplayNameResolver.resolveStepName('Duty Payment', isArabic: true), 'سداد الضرائب والرسوم الجمركية');
      expect(DisplayNameResolver.resolveStepName('CargoX Upload', isArabic: true), 'رفع التوثيق الإلكتروني للشاحن');
      expect(DisplayNameResolver.resolveStepName('Demurrage & Storage', isArabic: true), 'تسوية الأرضيات والحراسات');
    });

    test('Strips numeric prefixes if no mapping matches', () {
      expect(DisplayNameResolver.resolveStepName('01. Custom Operation', isArabic: false), 'Custom Operation');
    });

    // ── 2. Phase Name Resolution Tests ─────────────────────────────────────────
    test('Phases 1 to 10 resolve to clean, localized phase titles', () {
      expect(DisplayNameResolver.resolvePhaseName('Phase 1', isArabic: true), 'المرحلة الأولى: التخطيط والدراسات المسبقة');
      expect(DisplayNameResolver.resolvePhaseName('Phase 1', isArabic: false), 'Phase 1: Planning & Studies');
      expect(DisplayNameResolver.resolvePhaseName('Phase 2', isArabic: true), 'المرحلة الثانية: الاعتمادات ورقم التسجيل المسبق');
      expect(DisplayNameResolver.resolvePhaseName('Phase 2', isArabic: false), 'Phase 2: Approvals & ACID');
      expect(DisplayNameResolver.resolvePhaseName('Phase 3', isArabic: true), 'المرحلة الثالثة: الحجز وتدقيق المستندات');
      expect(DisplayNameResolver.resolvePhaseName('Phase 5', isArabic: true), 'المرحلة الخامسة: التخليص الجمركي والإفراج');
      expect(DisplayNameResolver.resolvePhaseName('Phase 5', isArabic: false), 'Phase 5: Clearance & Release');
      expect(DisplayNameResolver.resolvePhaseName('Phase 6', isArabic: true), 'المرحلة السادسة: المخازن والتسوية النهائية');
      expect(DisplayNameResolver.resolvePhaseName('Phase 10', isArabic: true), 'المرحلة العاشرة: إغلاق وأرشفة الملف');
    });

    test('Phase keyword resolution for legacy stage descriptions', () {
      expect(DisplayNameResolver.resolvePhaseName('Customs Clearance', isArabic: true), 'المرحلة الخامسة: التخليص الجمركي والإفراج');
      expect(DisplayNameResolver.resolvePhaseName('Customs Clearance', isArabic: false), 'Phase 5: Clearance & Release');
      expect(DisplayNameResolver.resolvePhaseName('Planning & Inception', isArabic: true), 'المرحلة الأولى: التخطيط والدراسات المسبقة');
    });

    // ── 3. Shipment Name & Title Resolution Tests ─────────────────────────────
    test('resolveShipmentName returns commercial name if present, otherwise importFileCode', () {
      final withCustom = ImportFileModel(
        importFileId: 1,
        importFileCode: 'IMP-2026-0001',
        customFileNumber: 'شحنة خط إنتاج قطع غيار',
        companyName: 'Test Importer',
        supplierName: 'Test Supplier',
        priority: 'High',
        currentModule: 'Customs Clearance',
        currentStage: 'Duty Payment',
        progressPercent: 50.0,
        nextAction: '',
        status: 'Open',
        isActive: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      );

      final withoutCustom = ImportFileModel(
        importFileId: 2,
        importFileCode: 'IMP-2026-0002',
        customFileNumber: null,
        companyName: 'Test Importer',
        supplierName: 'Test Supplier',
        priority: 'Medium',
        currentModule: 'Customs Clearance',
        currentStage: 'Duty Payment',
        progressPercent: 50.0,
        nextAction: '',
        status: 'Open',
        isActive: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      );

      final withIdenticalCode = ImportFileModel(
        importFileId: 3,
        importFileCode: 'IMP-2026-0003',
        customFileNumber: 'IMP-2026-0003',
        companyName: 'Test Importer',
        supplierName: 'Test Supplier',
        priority: 'Low',
        currentModule: 'Customs Clearance',
        currentStage: 'Duty Payment',
        progressPercent: 50.0,
        nextAction: '',
        status: 'Open',
        isActive: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      );

      expect(DisplayNameResolver.resolveShipmentName(withCustom), 'شحنة خط إنتاج قطع غيار');
      expect(DisplayNameResolver.resolveShipmentName(withoutCustom), 'IMP-2026-0002');
      expect(DisplayNameResolver.resolveShipmentName(withIdenticalCode), 'IMP-2026-0003');

      // Title formatting with secondary code
      expect(
        DisplayNameResolver.resolveShipmentTitle(withCustom, includeCodeSecondary: true),
        'شحنة خط إنتاج قطع غيار (IMP-2026-0001)',
      );
      expect(
        DisplayNameResolver.resolveShipmentTitle(withoutCustom, includeCodeSecondary: true),
        'IMP-2026-0002',
      );
    });

    test('resolveShipmentTitleByCode resolves code via shipments collection', () {
      final shipments = [
        ImportFileModel(
          importFileId: 10,
          importFileCode: 'IMP-2026-0010',
          customFileNumber: 'شحنة ألواح طاقة شمسية',
          companyName: 'Solar Egypt',
          supplierName: 'Solar Global',
          priority: 'High',
          currentModule: 'Phase 1',
          currentStage: 'STEP_01',
          progressPercent: 10.0,
          nextAction: '',
          status: 'Open',
          isActive: true,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];

      final resolved = DisplayNameResolver.resolveShipmentTitleByCode('IMP-2026-0010', shipments: shipments);
      expect(resolved, 'شحنة ألواح طاقة شمسية (IMP-2026-0010)');

      final fallback = DisplayNameResolver.resolveShipmentTitleByCode('IMP-9999-9999', shipments: shipments);
      expect(fallback, 'IMP-9999-9999');

      expect(DisplayNameResolver.resolveShipmentTitleByCode(null), '-');
      expect(DisplayNameResolver.resolveShipmentTitleByCode(''), '-');
    });

    // ── 4. Task Title Cleaning Tests ──────────────────────────────────────────
    test('cleanTaskTitle strips raw shipment tags and replaces (STEP_XX) with operation name', () {
      const rawTitle1 = '[IMP-2026-0004] مراجعة المتطلبات الخاصة بالبند الجمركي (STEP_03)';
      final cleaned1Ar = DisplayNameResolver.cleanTaskTitle(rawTitle1, isArabic: true);
      expect(cleaned1Ar, contains('اشتراطات ومتطلبات الاستيراد'));
      expect(cleaned1Ar, isNot(contains('[IMP-2026-0004]')));
      expect(cleaned1Ar, isNot(contains('STEP_03')));

      const rawTitle2 = '[IMP-2026-0002] تخصيص الحاويات وتنسيق التحميل (STEP_07)';
      final cleaned2En = DisplayNameResolver.cleanTaskTitle(rawTitle2, isArabic: false);
      expect(cleaned2En, contains('Container Allocation'));
      expect(cleaned2En, isNot(contains('[IMP-2026-0002]')));
      expect(cleaned2En, isNot(contains('STEP_07')));
    });

    test('cleanTaskTitle removes regulatory acronyms in Arabic mode', () {
      const rawTitle = 'استيفاء شهادة المنشأ (COO) للشاحن (STEP_08)';
      final cleaned = DisplayNameResolver.cleanTaskTitle(rawTitle, isArabic: true);
      expect(cleaned, isNot(contains('COO')));
      expect(cleaned, contains('شهادة المنشأ'));
    });

    test('cleanTaskTitle strips leading dashes, ACID tags, and provides clean English titles', () {
      const rawDashTask = '— تخصيص وتوزيع الحاويات والـ VGM (STEP_07)';
      expect(DisplayNameResolver.cleanTaskTitle(rawDashTask, isArabic: false), 'Container Allocation & VGM Verification');
      expect(DisplayNameResolver.cleanTaskTitle(rawDashTask, isArabic: true), 'تخصيص وتوزيع الحاويات والتحقق من الأوزان المعتمدة');

      const rawCargoTask = '— تخصيص وتوزيع الحاويات والبضائع (STEP_07)';
      expect(DisplayNameResolver.cleanTaskTitle(rawCargoTask, isArabic: false), 'Container Allocation & Cargo Distribution');
      expect(DisplayNameResolver.cleanTaskTitle(rawCargoTask, isArabic: true), 'تخصيص وتوزيع الحاويات والبضائع');

      const rawAcidTask = '[IMP-2026-0004] [ACID: 5281534391023010013] إصدار شهادة الفحص المسبق قبل الشحن (GOEIC - هيئة الرقابة)';
      expect(DisplayNameResolver.cleanTaskTitle(rawAcidTask, isArabic: false), 'Pre-shipment Inspection Certificate (GOEIC)');
      expect(DisplayNameResolver.cleanTaskTitle(rawAcidTask, isArabic: true), contains('شهادة الفحص المسبق'));
    });

    // ── 5. Action Title Resolution Tests ──────────────────────────────────────
    test('resolveActionTitle cleans STEP_XX prefixes and provides intelligent bilingual text', () {
      const vgmAction = 'STEP_07 تدقيق بيانات تخصيص الحاويات وأوزان VGM ومراجعة مسودات مستندات الشحن';
      expect(DisplayNameResolver.resolveActionTitle(vgmAction, isArabic: true), 'تدقيق بيانات تخصيص الحاويات وأوزان VGM ومراجعة مسودات الشحن');
      expect(DisplayNameResolver.resolveActionTitle(vgmAction, isArabic: false), 'VGM Verification & Shipping Drafts Review');

      const freightAction = 'Evaluate Shipping Scenarios (BP-007) & Request Freight Quotations (BP-008)';
      expect(DisplayNameResolver.resolveActionTitle(freightAction, isArabic: true), 'تقييم سيناريوهات الشحن وطلب عروض أسعار النولون');
      expect(DisplayNameResolver.resolveActionTitle(freightAction, isArabic: false), 'Evaluate Shipping Scenarios & Request Freight Quotes');

      expect(DisplayNameResolver.resolveActionTitle('STEP_01', isArabic: false), 'Freight Studies');
      expect(DisplayNameResolver.resolveActionTitle('STEP_01', isArabic: true), 'دراسات ومفاضلة النولون');
    });

    // ── 6. resolveShipmentNameByCode Tests ────────────────────────────────────
    test('resolveShipmentNameByCode returns clean shipment commercial name without duplicated codes', () {
      final shipments = [
        ImportFileModel(
          importFileId: 4,
          importFileCode: 'IMP-2026-0004',
          customFileNumber: 'PET Stock',
          companyName: 'Delta Importers',
          supplierName: 'Sino Chemical',
          priority: 'High',
          currentModule: 'Phase 1',
          currentStage: 'STEP_03',
          progressPercent: 20.0,
          nextAction: '',
          status: 'Open',
          isActive: true,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
        ImportFileModel(
          importFileId: 5,
          importFileCode: 'IMP-2026-0005',
          customFileNumber: null,
          companyName: 'Nile Trading',
          supplierName: 'Apex Exports',
          priority: 'Medium',
          currentModule: 'Phase 1',
          currentStage: 'STEP_01',
          progressPercent: 10.0,
          nextAction: '',
          status: 'Open',
          isActive: true,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];

      expect(
        DisplayNameResolver.resolveShipmentNameByCode('IMP-2026-0004', shipments: shipments, isArabic: true),
        'PET Stock',
      );
      expect(
        DisplayNameResolver.resolveShipmentNameByCode('IMP-2026-0005', shipments: shipments, isArabic: true),
        'IMP-2026-0005',
      );
      expect(
        DisplayNameResolver.resolveShipmentNameByCode('IMP-9999-9999', shipments: shipments, isArabic: true),
        'IMP-9999-9999',
      );
      expect(
        DisplayNameResolver.resolveShipmentNameByCode(null, shipments: shipments, isArabic: true),
        '-',
      );
    });

    // ── 7. Task Type and Status Localization Tests ────────────────────────────
    test('resolveTaskType localizes task types cleanly in Arabic and English', () {
      expect(DisplayNameResolver.resolveTaskType('System Generated', isArabic: true), 'توليد آلي من النظام');
      expect(DisplayNameResolver.resolveTaskType('System Generated', isArabic: false), 'System Generated');
      expect(DisplayNameResolver.resolveTaskType('Manual To-Do', isArabic: true), 'مهمة يدوية');
      expect(DisplayNameResolver.resolveTaskType('Manual To-Do', isArabic: false), 'Manual To-Do');
      expect(DisplayNameResolver.resolveTaskType('Reminder', isArabic: true), 'تذكير ومتابعة');
      expect(DisplayNameResolver.resolveTaskType('Reminder', isArabic: false), 'Reminder');
      expect(DisplayNameResolver.resolveTaskType(null, isArabic: true), '-');
    });

    test('resolveTaskStatus localizes task statuses cleanly in Arabic and English', () {
      expect(DisplayNameResolver.resolveTaskStatus('Pending', isArabic: true), 'معلقة');
      expect(DisplayNameResolver.resolveTaskStatus('Pending', isArabic: false), 'Pending');
      expect(DisplayNameResolver.resolveTaskStatus('In Progress', isArabic: true), 'قيد التنفيذ');
      expect(DisplayNameResolver.resolveTaskStatus('In Progress', isArabic: false), 'In Progress');
      expect(DisplayNameResolver.resolveTaskStatus('Completed', isArabic: true), 'مكتملة');
      expect(DisplayNameResolver.resolveTaskStatus('Completed', isArabic: false), 'Completed');
      expect(DisplayNameResolver.resolveTaskStatus('Cancelled', isArabic: true), 'ملغاة');
      expect(DisplayNameResolver.resolveTaskStatus('Cancelled', isArabic: false), 'Cancelled');
      expect(DisplayNameResolver.resolveTaskStatus(null, isArabic: true), '-');
    });

    // ── 8. Task Description & Natural Translation Tests ───────────────────────
    test('resolveTaskDescription replaces shipment codes in Arabic and translates to English', () {
      final shipments = [
        ImportFileModel(
          importFileId: 4,
          importFileCode: 'IMP-2026-0004',
          customFileNumber: 'PET Stock',
          companyName: 'Delta Importers',
          supplierName: 'Sino Chemical',
          priority: 'High',
          currentModule: 'Phase 1',
          currentStage: 'STEP_03',
          progressPercent: 20.0,
          nextAction: '',
          status: 'Open',
          isActive: true,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      ];

      const descAr = 'مراجعة اشتراطات الاستيراد للشحنة IMP-2026-0004 (STEP_03)';

      // Arabic mode: replaces raw code with PET Stock and STEP_03 with operation name
      final arRes = DisplayNameResolver.resolveTaskDescription(
        descAr,
        isArabic: true,
        shipmentCode: 'IMP-2026-0004',
        shipments: shipments,
      );
      expect(arRes, contains('PET Stock'));
      expect(arRes, isNot(contains('IMP-2026-0004')));
      expect(arRes, isNot(contains('STEP_03')));

      // English mode: provides natural English description with PET Stock
      final enRes = DisplayNameResolver.resolveTaskDescription(
        descAr,
        isArabic: false,
        shipmentCode: 'IMP-2026-0004',
        shipments: shipments,
      );
      expect(enRes, contains('PET Stock'));
      expect(enRes, contains('import requirements'));
      expect(enRes, isNot(contains('IMP-2026-0004')));
    });

    // ── 9. Update Category Localization Tests ─────────────────────────────────
    test('resolveUpdateCategory cleanly localizes categories', () {
      expect(DisplayNameResolver.resolveUpdateCategory('Follow-up & Notes', isArabic: true), 'متابعة وملاحظات');
      expect(DisplayNameResolver.resolveUpdateCategory('Follow-up & Notes', isArabic: false), 'Follow-up & Notes');
      expect(DisplayNameResolver.resolveUpdateCategory('Phase Cost Adjustment', isArabic: true), 'تعديل تكلفة المرحلة');
      expect(DisplayNameResolver.resolveUpdateCategory('Phase Cost Adjustment', isArabic: false), 'Phase Cost Adjustment');
      expect(DisplayNameResolver.resolveUpdateCategory('Future Phase Alert', isArabic: true), 'تنبيه مرحلة مستقبلية');
      expect(DisplayNameResolver.resolveUpdateCategory('Future Phase Alert', isArabic: false), 'Future Phase Alert');
      expect(DisplayNameResolver.resolveUpdateCategory(null, isArabic: true), '-');
    });

    // ── 10. Exact Screenshot Case: [IMP-2026-0004] (STEP_03) ... ──────────────
    test('Exact Screenshot Title: [IMP-2026-0004] (STEP_03) مراجعة اشتراطات الاستيراد والموافقات الرقابية', () {
      const rawScreenshotTitle = '[IMP-2026-0004] (STEP_03) مراجعة اشتراطات الاستيراد والموافقات الرقابية';

      // Arabic Mode
      final cleanedAr = DisplayNameResolver.cleanTaskTitle(rawScreenshotTitle, isArabic: true);
      expect(cleanedAr, 'مراجعة اشتراطات الاستيراد والموافقات الرقابية');
      expect(cleanedAr, isNot(contains('[IMP-2026-0004]')));
      expect(cleanedAr, isNot(contains('(STEP_03)')));
      expect(cleanedAr, isNot(contains('STEP_03')));

      // English Mode
      final cleanedEn = DisplayNameResolver.cleanTaskTitle(rawScreenshotTitle, isArabic: false);
      expect(cleanedEn, 'Review Import Requirements & Regulatory Approvals');
      expect(cleanedEn, isNot(contains('[IMP-2026-0004]')));
      expect(cleanedEn, isNot(contains('STEP_03')));
    });
  });
}

