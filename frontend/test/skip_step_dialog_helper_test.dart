// Tests for SkipStepDialogHelper logic & inferStepCode.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/lifecycle_board/widgets/skip_step_dialog_helper.dart';

void main() {
  group('SkipStepDialogHelper.inferStepCode resolution tests', () {
    test('resolves explicit STEP_xx codes correctly', () {
      expect(SkipStepDialogHelper.inferStepCode('STEP_01'), 'STEP_01');
      expect(SkipStepDialogHelper.inferStepCode('step_05'), 'STEP_05');
      expect(SkipStepDialogHelper.inferStepCode('Customs consultation STEP_02'), 'STEP_02');
      expect(SkipStepDialogHelper.inferStepCode('STEP_13 - Clearance'), 'STEP_13');
    });

    test('infers step from stage names and Arabic keywords', () {
      expect(SkipStepDialogHelper.inferStepCode('دراسات ومفاضلة نولون الشحن'), 'STEP_01');
      expect(SkipStepDialogHelper.inferStepCode('الدراسات والاستشارات الجمركية'), 'STEP_02');
      expect(SkipStepDialogHelper.inferStepCode('متطلبات واشتراطات الاستيراد'), 'STEP_03');
      expect(SkipStepDialogHelper.inferStepCode('الاعتماد المالي وصرف الدفعة'), 'STEP_04');
      expect(SkipStepDialogHelper.inferStepCode('استخراج رقم ACID وتوثيق نافذة'), 'STEP_05');
      expect(SkipStepDialogHelper.inferStepCode('حجز الشحن والخط الملاحي'), 'STEP_06');
      expect(SkipStepDialogHelper.inferStepCode('توثيق مستندات الشحن على CargoX'), 'STEP_07');
      expect(SkipStepDialogHelper.inferStepCode('تتبع الإبحار وتاريخ الوصول'), 'STEP_08');
      expect(SkipStepDialogHelper.inferStepCode('إجراءات المعاينة والتخليص الجمركي'), 'STEP_13');
      expect(SkipStepDialogHelper.inferStepCode('استلام المخازن وتوليد إذن GRN'), 'STEP_19');
      expect(SkipStepDialogHelper.inferStepCode('تسوية تكلفة الوصول الشاملة Landed Cost'), 'STEP_20');
      expect(SkipStepDialogHelper.inferStepCode('أرشفة وإغلاق الملف الاستيرادي'), 'STEP_21');
    });

    test('falls back safely to STEP_01 when input is null, empty or unknown', () {
      expect(SkipStepDialogHelper.inferStepCode(null), 'STEP_01');
      expect(SkipStepDialogHelper.inferStepCode(''), 'STEP_01');
      expect(SkipStepDialogHelper.inferStepCode('Unknown Random Phase'), 'STEP_01');
    });
  });
}
