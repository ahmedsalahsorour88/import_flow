import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/providers/ai_assistant_provider.dart';
import 'package:frontend/core/utils/ai_glossary.dart';
import 'package:frontend/core/utils/shipment_task_formatter.dart';
import 'package:frontend/features/smart_tasks/models/smart_task_model.dart';

void main() {
  group('AiGlossary - Rule 4: Domain Logistics Terminology & Directives', () {
    test('contains verified bidirectional terminology', () {
      expect(AiGlossary.lookupEnToAr('Container Allocation'), equals('تخصيص الحاويات'));
      expect(AiGlossary.lookupEnToAr('Bill of Lading (B/L)'), equals('بوليصة الشحن'));
      expect(AiGlossary.lookupEnToAr('ACID Number'), equals('رقم القيد الجمركي المسبق (ACID)'));
      expect(AiGlossary.lookupEnToAr('Landed Cost'), equals('تكلفة الوصول الشاملة'));
      expect(AiGlossary.lookupEnToAr('Import Duty'), equals('ضريبة الوارد (الجمارك)'));
      expect(AiGlossary.lookupEnToAr('Verified Gross Mass (VGM)'), equals('وزن الحاوية المعتمد (VGM)'));

      expect(AiGlossary.lookupArToEn('تخصيص الحاويات'), equals('Container Allocation'));
      expect(AiGlossary.lookupArToEn('بوليصة الشحن'), equals('Bill of Lading (B/L)'));
      expect(AiGlossary.lookupArToEn('تكلفة الوصول الشاملة'), equals('Landed Cost'));
    });

    test('generates strict language directives with identifier preservation rules', () {
      final arDirective = AiGlossary.getLanguageDirective('ar');
      expect(arDirective, contains('العربية'));
      expect(arDirective, contains('IMP-2026-0004'));

      final enDirective = AiGlossary.getLanguageDirective('en');
      expect(enDirective, contains('ENGLISH'));
      expect(enDirective, contains('IMP-2026-0004'));
    });

    test('generates system prompt glossary instructions', () {
      final prompt = AiGlossary.getGlossaryPrompt();
      expect(prompt, contains('Bilingual Support & Approved Domain Glossary'));
      expect(prompt, contains('Container Allocation'));
      expect(prompt, contains('Landed Cost'));
    });
  });

  group('AiAssistantState - Bilingual Support & Language Toggle', () {
    test('defaults to Arabic with proper boolean getters', () {
      const state = AiAssistantState();
      expect(state.activeLanguage, equals('ar'));
      expect(state.isArabic, isTrue);
      expect(state.isEnglish, isFalse);
    });

    test('updates active language correctly via copyWith', () {
      const state = AiAssistantState();
      final enState = state.copyWith(activeLanguage: 'en');
      expect(enState.activeLanguage, equals('en'));
      expect(enState.isArabic, isFalse);
      expect(enState.isEnglish, isTrue);

      final arState = enState.copyWith(activeLanguage: 'ar');
      expect(arState.activeLanguage, equals('ar'));
      expect(arState.isArabic, isTrue);
    });
  });

  group('Categorized Bilingual Quick Suggestions - Rule 3', () {
    test('contains 3 major logistics categories with bilingual titles', () {
      expect(kCategorizedQuickSuggestions.length, equals(3));

      final containerCat = kCategorizedQuickSuggestions[0];
      expect(containerCat.titleAr, equals('إدارة الحاويات والشحن'));
      expect(containerCat.titleEn, equals('Container Management'));
      expect(containerCat.title('ar'), equals('إدارة الحاويات والشحن'));
      expect(containerCat.title('en'), equals('Container Management'));
      expect(containerCat.items.isNotEmpty, isTrue);

      final customsCat = kCategorizedQuickSuggestions[1];
      expect(customsCat.titleAr, equals('الجمارك ومنظومة نافذة'));
      expect(customsCat.titleEn, equals('Customs & Nafeza'));

      final prioritiesCat = kCategorizedQuickSuggestions[2];
      expect(prioritiesCat.titleAr, equals('أولويات ومهام اليوم'));
      expect(prioritiesCat.titleEn, equals('Daily Priorities & Tasks'));
    });

    test('quick suggestion items provide localized label and prompt', () {
      final item = kCategorizedQuickSuggestions[0].items[0];
      expect(item.label('ar'), equals('تخصيص الحاويات'));
      expect(item.label('en'), equals('Container Allocation'));
      expect(item.prompt('ar'), contains('تخصيص الحاويات'));
      expect(item.prompt('en'), contains('container allocations'));
    });
  });

  group('ShipmentTaskFormatter - Bilingual Output & Identifier Preservation', () {
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
        dueDate: '2026-08-31', // Overdue
        status: 'Pending',
        isAutoClosed: false,
        isActive: true,
        createdAt: '2026-08-20',
        createdBy: 'System',
      ),
      SmartTaskModel(
        taskId: 2,
        taskCode: 'TSK-2026-0002',
        title: 'سداد رسوم الجمارك ومطابقة نافذة',
        taskType: 'System Generated',
        assignedUser: 'Kamal',
        priority: 'High',
        reminderType: 'Customs',
        dueDate: '2026-09-09', // Due today
        status: 'Pending',
        isAutoClosed: false,
        isActive: true,
        createdAt: '2026-08-20',
        createdBy: 'System',
      ),
      SmartTaskModel(
        taskId: 3,
        taskCode: 'TSK-2026-0003',
        title: 'تخصيص وتوزيع الحاويات ووثائق الوزن (VGM)',
        taskType: 'System Generated',
        assignedUser: 'Kamal',
        priority: 'Medium',
        reminderType: 'Document',
        dueDate: '2026-09-15', // Upcoming
        status: 'Pending',
        isAutoClosed: false,
        isActive: true,
        createdAt: '2026-08-20',
        createdBy: 'System',
      ),
    ];

    test('formats task list in Arabic with Arabic section titles and preserved identifiers', () {
      final output = ShipmentTaskFormatter.formatTaskList(
        shipmentName: 'PET Stock',
        clientName: 'SCAS For Construction And Finishing',
        fileCode: 'IMP-2026-0004',
        completedSteps: 4,
        totalSteps: 10,
        tasks: tasks,
        renderTime: now,
        isArabic: true,
      );

      // Arabic section titles & alert line
      expect(output, contains('⚠️ مهمة واحدة متأخرة منذ 9 أيام'));
      expect(output, contains('متأخرة:'));
      expect(output, contains('مستحقة اليوم:'));
      expect(output, contains('قادمة:'));
      expect(output, contains('نسبة الإنجاز: 🟡 40%'));

      // Human-readable identity
      expect(output, contains('PET Stock – SCAS (IMP-2026-0004)'));

      // Exception: System identifiers NEVER translated
      expect(output, contains('IMP-2026-0004'));
      expect(output, contains('متأخرة منذ 9 أيام'));
    });

    test('formats task list in English with English section titles and preserved identifiers', () {
      final output = ShipmentTaskFormatter.formatTaskList(
        shipmentName: 'PET Stock',
        clientName: 'SCAS For Construction And Finishing',
        fileCode: 'IMP-2026-0004',
        completedSteps: 4,
        totalSteps: 10,
        tasks: tasks,
        renderTime: now,
        isArabic: false,
      );

      // English section titles & alert line
      expect(output, contains('⚠️ 1 task overdue since 9 days'));
      expect(output, contains('Overdue:'));
      expect(output, contains('Due today:'));
      expect(output, contains('Upcoming:'));
      expect(output, contains('Completion Rate: 🟡 40%'));

      // Human-readable identity
      expect(output, contains('PET Stock – SCAS (IMP-2026-0004)'));

      // Exception: System identifiers NEVER translated
      expect(output, contains('IMP-2026-0004'));
      expect(output, contains('overdue by 9 days'));
    });

    test('formats completion indicator and next action bilingually', () {
      final arCompletion = ShipmentTaskFormatter.formatCompletionIndicator(
        completedSteps: 8,
        totalSteps: 10,
        isArabic: true,
      );
      expect(arCompletion, contains('نسبة الإنجاز: 🟢 80% (8 من 10 خطوة مكتملة) ▓▓▓▓▓▓▓▓░░'));

      final enCompletion = ShipmentTaskFormatter.formatCompletionIndicator(
        completedSteps: 8,
        totalSteps: 10,
        isArabic: false,
      );
      expect(enCompletion, contains('Completion Rate: 🟢 80% (8 of 10 steps completed) ▓▓▓▓▓▓▓▓░░'));

      final arNext = ShipmentTaskFormatter.formatNextAction(
        'إصدار شهادة الفحص المسبق (GOEIC)',
        isArabic: true,
      );
      expect(arNext, contains('المطلوب منك الآن: بيانات شهادة GOEIC عشان نقفل أقدم مهمة متأخرة.'));

      final enNext = ShipmentTaskFormatter.formatNextAction(
        'Container Allocation and VGM',
        isArabic: false,
      );
      expect(enNext, contains('What is needed now: container numbers, seals, and VGM weights in order to close oldest overdue task.'));
    });
  });
}
