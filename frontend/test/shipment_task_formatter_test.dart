import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/shipment_task_formatter.dart';
import 'package:frontend/features/smart_tasks/models/smart_task_model.dart';

void main() {
  group('ShipmentTaskFormatter - Rule 2: Human-Readable Shipment Identity', () {
    test('extracts literal first word for standard company names', () {
      expect(
        ShipmentTaskFormatter.formatClientShortName('SCAS For Construction And Finishing'),
        equals('SCAS'),
      );
      expect(
        ShipmentTaskFormatter.formatClientShortName('ECO ASSOCIATES for Trading and Contracting'),
        equals('ECO'),
      );
    });

    test('falls back to first two words if first word is a generic prefix', () {
      expect(
        ShipmentTaskFormatter.formatClientShortName('The Egyptian Import Co'),
        equals('The Egyptian'),
      );
      expect(
        ShipmentTaskFormatter.formatClientShortName('Al Amal Trading'),
        equals('Al Amal'),
      );
      expect(
        ShipmentTaskFormatter.formatClientShortName('Company Global Logistics'),
        equals('Company Global'),
      );
      expect(
        ShipmentTaskFormatter.formatClientShortName('شركة الأهرام للتوريدات'),
        equals('شركة الأهرام'),
      );
      expect(
        ShipmentTaskFormatter.formatClientShortName('الشركة الدولية للمقاولات'),
        equals('الشركة الدولية'),
      );
    });

    test('formats clean shipment label without file code by default, and with code when requested', () {
      final labelClean = ShipmentTaskFormatter.formatShipmentLabel(
        shipmentName: 'PET Stock',
        clientName: 'SCAS For Construction And Finishing',
        fileCode: 'IMP-2026-0004',
      );
      expect(labelClean, equals('PET Stock – SCAS'));

      final labelWithCode = ShipmentTaskFormatter.formatShipmentLabel(
        shipmentName: 'PET Stock',
        clientName: 'SCAS For Construction And Finishing',
        fileCode: 'IMP-2026-0004',
        includeCode: true,
      );
      expect(labelWithCode, equals('PET Stock – SCAS (IMP-2026-0004)'));
    });

    test('cleanTaskTitle strips technical file codes, ACID prefixes, and step numbers', () {
      expect(
        ShipmentTaskFormatter.cleanTaskTitle(
          '[IMP-2026-0004] [ACID: 5281534391023010013] إصدار شهادة الفحص المسبق قبل الشحن (GOEIC)',
        ),
        equals('إصدار شهادة الفحص المسبق قبل الشحن (GOEIC)'),
      );
      expect(
        ShipmentTaskFormatter.cleanTaskTitle(
          '[IMP-2026-0004] — مراجعة اشتراطات الاستيراد والموافقات الرقابية (STEP_03)',
        ),
        equals('مراجعة اشتراطات الاستيراد والموافقات الرقابية'),
      );
      expect(
        ShipmentTaskFormatter.cleanTaskTitle(
          '[IMP-2026-0004] — تخصيص وتوزيع الحاويات والـ VGM (STEP_07)',
        ),
        equals('تخصيص وتوزيع الحاويات والـ VGM'),
      );
    });
  });

  group('ShipmentTaskFormatter - Rule 7: Priority Indicators', () {
    test('assigns correct priority icons', () {
      expect(ShipmentTaskFormatter.getPriorityIcon('Critical'), equals('🔴'));
      expect(ShipmentTaskFormatter.getPriorityIcon('حرجة'), equals('🔴'));
      expect(ShipmentTaskFormatter.getPriorityIcon('High'), equals('🟠'));
      expect(ShipmentTaskFormatter.getPriorityIcon('عالية'), equals('🟠'));
      expect(ShipmentTaskFormatter.getPriorityIcon('Medium'), equals('🟡'));
      expect(ShipmentTaskFormatter.getPriorityIcon('متوسطة'), equals('🟡'));
      expect(ShipmentTaskFormatter.getPriorityIcon('Low'), equals('🟢'));
      expect(ShipmentTaskFormatter.getPriorityIcon('High', status: 'Completed'), equals('🟢'));
    });
  });

  group('ShipmentTaskFormatter - Rule 8: Shipment Completion Percentage', () {
    test('generates percentage, color cue, and 10-block progress bar correctly', () {
      // 20%: Early stage (🔴)
      final ind20 = ShipmentTaskFormatter.formatCompletionIndicator(
        completedSteps: 2,
        totalSteps: 10,
      );
      expect(ind20, contains('🔴 20%'));
      expect(ind20, contains('2 من 10 خطوة مكتملة'));
      expect(ind20, contains('▓▓░░░░░░░░'));

      // 40%: In progress (🟡)
      final ind40 = ShipmentTaskFormatter.formatCompletionIndicator(
        completedSteps: 4,
        totalSteps: 10,
      );
      expect(ind40, contains('🟡 40%'));
      expect(ind40, contains('4 من 10 خطوة مكتملة'));
      expect(ind40, contains('▓▓▓▓░░░░░░'));

      // 80%: Near completion (🟢)
      final ind80 = ShipmentTaskFormatter.formatCompletionIndicator(
        completedSteps: 8,
        totalSteps: 10,
      );
      expect(ind80, contains('🟢 80%'));
      expect(ind80, contains('▓▓▓▓▓▓▓▓░░'));

      // 100%: Complete (✅)
      final ind100 = ShipmentTaskFormatter.formatCompletionIndicator(
        completedSteps: 10,
        totalSteps: 10,
      );
      expect(ind100, contains('✅ 100%'));
      expect(ind100, contains('▓▓▓▓▓▓▓▓▓▓'));
    });
  });

  group('ShipmentTaskFormatter - Target Reference Output Scenario', () {
    test('matches exact reference output structure with overdue alert, grouping, duplicate flag, and next action', () {
      // Simulation Date: 2026-09-09
      final now = DateTime(2026, 9, 9, 12, 0);

      final tasks = [
        SmartTaskModel(
          taskId: 1,
          taskCode: 'TSK-2026-0001',
          title: 'إصدار شهادة الفحص المسبق (GOEIC)',
          taskType: 'System Generated',
          assignedUser: 'Kamal',
          priority: 'Critical',
          reminderType: 'Document',
          dueDate: '2026-08-31', // 9 days overdue
          status: 'Pending',
          isAutoClosed: false,
          isActive: true,
          createdAt: '2026-08-20',
          createdBy: 'System',
        ),
        SmartTaskModel(
          taskId: 2,
          taskCode: 'TSK-2026-0002',
          title: 'استيفاء شهادة المنشأ (COO)',
          taskType: 'System Generated',
          assignedUser: 'Kamal',
          priority: 'High',
          reminderType: 'Document',
          dueDate: '2026-09-02', // 7 days overdue
          status: 'Pending',
          isAutoClosed: false,
          isActive: true,
          createdAt: '2026-08-20',
          createdBy: 'System',
        ),
        SmartTaskModel(
          taskId: 3,
          taskCode: 'TSK-2026-0003',
          title: 'مراجعة اشتراطات الاستيراد والموافقات الرقابية',
          taskType: 'System Generated',
          assignedUser: 'Kamal',
          priority: 'High',
          reminderType: 'Document',
          dueDate: '2026-09-05', // 4 days overdue
          status: 'Pending',
          isAutoClosed: false,
          isActive: true,
          createdAt: '2026-08-20',
          createdBy: 'System',
        ),
        SmartTaskModel(
          taskId: 4,
          taskCode: 'TSK-2026-0004',
          title: 'تخصيص وتوزيع الحاويات ووثائق الوزن (VGM)',
          taskType: 'System Generated',
          assignedUser: 'Kamal',
          priority: 'High',
          reminderType: 'Document',
          dueDate: '2026-09-15', // Upcoming
          status: 'Pending',
          isAutoClosed: false,
          isActive: true,
          createdAt: '2026-08-20',
          createdBy: 'System',
        ),
        SmartTaskModel(
          taskId: 5,
          taskCode: 'TSK-2026-0005',
          title: 'تخصيص وتوزيع الحاويات والبضائع',
          taskType: 'System Generated',
          assignedUser: 'Kamal',
          priority: 'High',
          reminderType: 'Document',
          dueDate: '2026-09-16', // Duplicate with task 4
          status: 'Pending',
          isAutoClosed: false,
          isActive: true,
          createdAt: '2026-08-20',
          createdBy: 'System',
        ),
      ];

      final output = ShipmentTaskFormatter.formatTaskList(
        shipmentName: 'PET Stock',
        clientName: 'SCAS For Construction And Finishing',
        fileCode: 'IMP-2026-0004',
        completedSteps: 4,
        totalSteps: 10,
        tasks: tasks,
        renderTime: now,
      );

      // Assertions
      // 1. Alert line
      expect(output, contains('⚠️ 3 مهام متأخرة منذ 9 أيام — شحنة PET Stock – SCAS'));
      // 2. Completion indicator
      expect(output, contains('نسبة الإنجاز: 🟡 40% (4 من 10 خطوة مكتملة) ▓▓▓▓░░░░░░'));
      // 3. Sections order
      expect(output.indexOf('متأخرة:'), lessThan(output.indexOf('قادمة:')));
      // 4. Overdue tasks listed
      expect(output, contains('🔴 إصدار شهادة الفحص المسبق (GOEIC)'));
      expect(output, contains('🟠 استيفاء شهادة المنشأ (COO)'));
      expect(output, contains('🟠 مراجعة اشتراطات الاستيراد والموافقات الرقابية'));
      // 5. Upcoming duplicate detected
      expect(output, contains('🟠 تخصيص وتوزيع الحاويات ووثائق الوزن (VGM)'));
      expect(output, contains('🟠 تخصيص وتوزيع الحاويات والبضائع'));
      expect(output, contains('⚠️ يبدو تكرار بين هاتين المهمتين — برجاء التأكد من النظام'));
      // 6. Next action
      expect(output, contains('المطلوب منك الآن: بيانات شهادة GOEIC عشان نقفل أقدم مهمة متأخرة.'));
    });
  });

  group('ShipmentTaskFormatter - Edge Cases', () {
    test('Edge Case: All tasks done shows confirmation line without empty list', () {
      final output = ShipmentTaskFormatter.formatTaskList(
        shipmentName: 'PET Stock',
        clientName: 'SCAS',
        fileCode: 'IMP-2026-0004',
        completedSteps: 10,
        totalSteps: 10,
        tasks: [],
      );

      expect(output, contains('شحنة PET Stock – SCAS'));
      expect(output, contains('نسبة الإنجاز: ✅ 100% (10 من 10 خطوة مكتملة) ▓▓▓▓▓▓▓▓▓▓'));
      expect(output, contains('✅ اكتملت جميع مراحل الشحنة بنجاح.'));
      expect(output, isNot(contains('متأخرة:')));
      expect(output, isNot(contains('قادمة:')));
    });

    test('Edge Case: No overdue tasks opens directly without alert line', () {
      final now = DateTime(2026, 9, 9);
      final tasks = [
        SmartTaskModel(
          taskId: 1,
          taskCode: 'TSK-1',
          title: 'حجز نولون الشحن البحري',
          taskType: 'System Generated',
          assignedUser: 'Kamal',
          priority: 'High',
          reminderType: 'Shipping Line',
          dueDate: '2026-09-12', // Future
          status: 'Pending',
          isAutoClosed: false,
          isActive: true,
          createdAt: '2026-09-01',
          createdBy: 'System',
        ),
      ];

      final output = ShipmentTaskFormatter.formatTaskList(
        shipmentName: 'PET Stock',
        clientName: 'SCAS',
        fileCode: 'IMP-2026-0004',
        completedSteps: 3,
        totalSteps: 10,
        tasks: tasks,
        renderTime: now,
      );

      expect(output, isNot(contains('⚠️')));
      expect(output, contains('شحنة PET Stock – SCAS'));
      expect(output, contains('نسبة الإنجاز: 🔴 30%'));
      // Single task only: skips group headers
      expect(output, contains('🟠 حجز نولون الشحن البحري'));
    });
  });
}
