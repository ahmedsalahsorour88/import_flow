import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 50: Landed Cost Comparison Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 50 getters should return non-empty strings in Arabic and English', () {
      expect(ar.landedCostComparisonTitle('IMP-001'), contains('IMP-001'));
      expect(en.landedCostComparisonTitle('IMP-001'), contains('IMP-001'));
      expect(ar.landedCostLoadError('Database Error'), contains('Database Error'));
      expect(en.landedCostLoadError('Database Error'), contains('Database Error'));
      expect(ar.noLandedCostDataRegistered, isNotEmpty);
      expect(en.noLandedCostDataRegistered, isNotEmpty);
      expect(ar.expenseBreakdownHeader, isNotEmpty);
      expect(en.expenseBreakdownHeader, isNotEmpty);
      expect(ar.itemLandedCostHeader, isNotEmpty);
      expect(en.itemLandedCostHeader, isNotEmpty);
      expect(ar.estimatedCostHeader, isNotEmpty);
      expect(en.estimatedCostHeader, isNotEmpty);
      expect(ar.actualCostHeader, isNotEmpty);
      expect(en.actualCostHeader, isNotEmpty);
      expect(ar.fobValueCardTitle, isNotEmpty);
      expect(en.fobValueCardTitle, isNotEmpty);
      expect(ar.totalExpensesCardTitle, isNotEmpty);
      expect(en.totalExpensesCardTitle, isNotEmpty);
      expect(ar.totalLandedCostCardTitle, isNotEmpty);
      expect(en.totalLandedCostCardTitle, isNotEmpty);
      expect(ar.estAbbreviation, isNotEmpty);
      expect(en.estAbbreviation, isNotEmpty);
      expect(ar.actAbbreviation, isNotEmpty);
      expect(en.actAbbreviation, isNotEmpty);
      expect(ar.colExpenseCategory, isNotEmpty);
      expect(en.colExpenseCategory, isNotEmpty);
      expect(ar.colExpenseProvider, isNotEmpty);
      expect(en.colExpenseProvider, isNotEmpty);
      expect(ar.colExpenseCurrency, isNotEmpty);
      expect(en.colExpenseCurrency, isNotEmpty);
      expect(ar.colExpenseAmountFx, isNotEmpty);
      expect(en.colExpenseAmountFx, isNotEmpty);
      expect(ar.colExpenseExchangeRate, isNotEmpty);
      expect(en.colExpenseExchangeRate, isNotEmpty);
      expect(ar.colExpenseAmountEgp, isNotEmpty);
      expect(en.colExpenseAmountEgp, isNotEmpty);
      expect(ar.colItemCode, isNotEmpty);
      expect(en.colItemCode, isNotEmpty);
      expect(ar.colItemName, isNotEmpty);
      expect(en.colItemName, isNotEmpty);
      expect(ar.colItemQty, isNotEmpty);
      expect(en.colItemQty, isNotEmpty);
      expect(ar.colFobUnitPrice, isNotEmpty);
      expect(en.colFobUnitPrice, isNotEmpty);
      expect(ar.colLandedUnitPrice, isNotEmpty);
      expect(en.colLandedUnitPrice, isNotEmpty);
      expect(ar.colCostMarkupFactor, isNotEmpty);
      expect(en.colCostMarkupFactor, isNotEmpty);
      expect(ar.landedCostOverBudgetBanner('15.2'), contains('15.2'));
      expect(en.landedCostOverBudgetBanner('15.2'), contains('15.2'));
      expect(ar.landedCostUnderBudgetBanner('8.5'), contains('8.5'));
      expect(en.landedCostUnderBudgetBanner('8.5'), contains('8.5'));

      expect(ar.expenseCategoryName('freight'), isNotEmpty);
      expect(en.expenseCategoryName('freight'), isNotEmpty);
      expect(ar.expenseCategoryName('customs'), isNotEmpty);
      expect(en.expenseCategoryName('customs'), isNotEmpty);
      expect(ar.expenseCategoryName('clearance'), isNotEmpty);
      expect(en.expenseCategoryName('clearance'), isNotEmpty);
      expect(ar.expenseCategoryName('transport'), isNotEmpty);
      expect(en.expenseCategoryName('transport'), isNotEmpty);
      expect(ar.expenseCategoryName('storage'), isNotEmpty);
      expect(en.expenseCategoryName('storage'), isNotEmpty);
      expect(ar.expenseCategoryName('other'), isNotEmpty);
      expect(en.expenseCategoryName('other'), isNotEmpty);
    });

    test('Arabic static strings should not contain English or Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');
      expect(latinPattern.hasMatch(ar.noLandedCostDataRegistered), isFalse);
      expect(latinPattern.hasMatch(ar.expenseBreakdownHeader), isFalse);
      expect(latinPattern.hasMatch(ar.itemLandedCostHeader), isFalse);
      expect(latinPattern.hasMatch(ar.estimatedCostHeader), isFalse);
      expect(latinPattern.hasMatch(ar.actualCostHeader), isFalse);
      expect(latinPattern.hasMatch(ar.fobValueCardTitle), isFalse);
      expect(latinPattern.hasMatch(ar.totalExpensesCardTitle), isFalse);
      expect(latinPattern.hasMatch(ar.totalLandedCostCardTitle), isFalse);
      expect(latinPattern.hasMatch(ar.estAbbreviation), isFalse);
      expect(latinPattern.hasMatch(ar.actAbbreviation), isFalse);
      expect(latinPattern.hasMatch(ar.colExpenseCategory), isFalse);
      expect(latinPattern.hasMatch(ar.colExpenseProvider), isFalse);
      expect(latinPattern.hasMatch(ar.colExpenseCurrency), isFalse);
      expect(latinPattern.hasMatch(ar.colExpenseAmountFx), isFalse);
      expect(latinPattern.hasMatch(ar.colExpenseExchangeRate), isFalse);
      expect(latinPattern.hasMatch(ar.colExpenseAmountEgp), isFalse);
      expect(latinPattern.hasMatch(ar.colItemCode), isFalse);
      expect(latinPattern.hasMatch(ar.colItemName), isFalse);
      expect(latinPattern.hasMatch(ar.colItemQty), isFalse);
      expect(latinPattern.hasMatch(ar.colFobUnitPrice), isFalse);
      expect(latinPattern.hasMatch(ar.colLandedUnitPrice), isFalse);
      expect(latinPattern.hasMatch(ar.colCostMarkupFactor), isFalse);

      expect(latinPattern.hasMatch(ar.expenseCategoryName('freight')), isFalse);
      expect(latinPattern.hasMatch(ar.expenseCategoryName('customs')), isFalse);
      expect(latinPattern.hasMatch(ar.expenseCategoryName('clearance')), isFalse);
      expect(latinPattern.hasMatch(ar.expenseCategoryName('transport')), isFalse);
      expect(latinPattern.hasMatch(ar.expenseCategoryName('storage')), isFalse);
      expect(latinPattern.hasMatch(ar.expenseCategoryName('other')), isFalse);
    });
  });
}
