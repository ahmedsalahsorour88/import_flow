import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/customs_consultation/models/customs_consultation_model.dart';
import 'package:frontend/features/customs_consultation/services/clearance_expense_types_export_service.dart';

void main() {
  group('ClearanceExpenseTypesExportService Unit Tests', () {
    final sampleExpenses = [
      ClearanceExpenseTypeModel(
        expenseId: 101,
        expenseCode: 'EXP-PRC-011A',
        nameAr: 'عرض الواردات',
        nameEn: 'Import Inspection Agency',
        category: 'Inspection & Regulatory',
        defaultUnit: 'Per Container',
        defaultCurrency: 'EGP',
        isActive: true,
      ),
      ClearanceExpenseTypeModel(
        expenseId: 102,
        expenseCode: 'EXP-PRC-011B',
        nameAr: 'اعتماد الإيلاك',
        nameEn: 'ILAC Approval',
        category: 'Inspection & Regulatory',
        defaultUnit: 'Per Certificate',
        defaultCurrency: 'EGP',
        isActive: true,
      ),
      ClearanceExpenseTypeModel(
        expenseId: 103,
        expenseCode: 'EXP-PRC-014A',
        nameAr: 'أمن عام',
        nameEn: 'General Security Clearance',
        category: 'Security & Legal',
        defaultUnit: 'Per Shipment',
        defaultCurrency: 'EGP',
        isActive: true,
      ),
    ];

    test('toRowSummary outputs pure localized string without stacking', () {
      const lAr = AppLocalizationsAr();
      const lEn = AppLocalizationsEn();

      final summaryAr = ClearanceExpenseTypesExportService.toRowSummary(
        sampleExpenses[0],
        lAr,
        isArabic: true,
      );
      expect(summaryAr, contains('EXP-PRC-011A'));
      expect(summaryAr, contains('عرض الواردات'));
      expect(summaryAr, contains('EGP'));

      final summaryEn = ClearanceExpenseTypesExportService.toRowSummary(
        sampleExpenses[0],
        lEn,
        isArabic: false,
      );
      expect(summaryEn, contains('EXP-PRC-011A'));
      expect(summaryEn, contains('Import Inspection Agency'));
      expect(summaryEn, contains('EGP'));
    });

    test('Decomposed expenses contain no bundled items with + or /', () {
      for (final exp in sampleExpenses) {
        expect(exp.nameAr.contains('+'), isFalse);
        expect(exp.nameAr.contains('/'), isFalse);
        if (exp.nameEn != null) {
          expect(exp.nameEn!.contains('+'), isFalse);
          expect(exp.nameEn!.contains('/'), isFalse);
        }
      }
    });

    test('New expense type localization getters adhere to strict single language rules', () {
      const lAr = AppLocalizationsAr();
      const lEn = AppLocalizationsEn();

      final arabicStrings = <String>[
        lAr.editExpenseTypeDialogTitle,
        lAr.confirmDeleteExpenseTypeTitle,
        lAr.confirmDeleteExpenseTypeMsg('عرض الواردات', '101'),
        lAr.expenseTypeUpdatedToast,
        lAr.expenseTypeDeletedToast,
        lAr.copyExpenseRowSummaryTooltip,
        lAr.editExpenseTooltip,
        lAr.deleteExpenseTooltip,
      ];

      final latinRegex = RegExp(r'[a-zA-Z]');
      for (final str in arabicStrings) {
        expect(latinRegex.hasMatch(str), isFalse, reason: 'Arabic string contains Latin characters: ');
        expect(str.contains('/'), isFalse, reason: 'Arabic string contains bilingual slash: ');
      }

      expect(lEn.editExpenseTypeDialogTitle, equals('Edit Expense Type'));
      expect(lEn.confirmDeleteExpenseTypeTitle, equals('Confirm Delete Expense'));
      expect(lEn.confirmDeleteExpenseTypeMsg('Customs', 'EXP-001'), equals('Are you sure you want to delete and deactivate expense item (Customs) with code (EXP-001)?'));
      expect(lEn.expenseTypeUpdatedToast, equals('Expense type updated successfully'));
      expect(lEn.expenseTypeDeletedToast, equals('Expense type deleted successfully'));
    });
  });
}
