import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/change_diff_dialog.dart';

void main() {
  group('FieldChangeItem Unit Tests', () {
    test('isDifferent should accurately compare strings with trimming', () {
      expect(FieldChangeItem.isDifferent('Cairo', 'Cairo'), isFalse);
      expect(FieldChangeItem.isDifferent('Cairo ', 'Cairo'), isFalse);
      expect(FieldChangeItem.isDifferent('Cairo', 'Alexandria'), isTrue);
      expect(FieldChangeItem.isDifferent(null, null), isFalse);
      expect(FieldChangeItem.isDifferent(null, 'Cairo'), isTrue);
      expect(FieldChangeItem.isDifferent('Cairo', null), isTrue);
    });

    test('isDifferent should accurately compare booleans and numbers', () {
      expect(FieldChangeItem.isDifferent(true, true), isFalse);
      expect(FieldChangeItem.isDifferent(true, false), isTrue);
      expect(FieldChangeItem.isDifferent(100.0, 100.0), isFalse);
      expect(FieldChangeItem.isDifferent(100.0, 100.00001), isFalse);
      expect(FieldChangeItem.isDifferent(100.0, 105.0), isTrue);
    });

    test('formatValue should format booleans and empty values with arabic descriptive tags', () {
      expect(FieldChangeItem.formatValue(true), contains('قابل للرص'));
      expect(FieldChangeItem.formatValue(false), contains('غير قابل للرص'));
      expect(FieldChangeItem.formatValue(null), contains('فارغ'));
      expect(FieldChangeItem.formatValue(''), contains('فارغ'));
      expect(FieldChangeItem.formatValue('100 USD'), equals('100 USD'));
    });
  });

  group('ChangeDiffConfirmationDialog Widget Tests', () {
    testWidgets('Should render diff comparison table and confirm button', (WidgetTester tester) async {
      final changes = [
        FieldChangeItem(
          section: 'قائمة التعبئة',
          fieldName: 'تعليمات الرص',
          oldValue: true,
          newValue: false,
        ),
        FieldChangeItem(
          section: 'البيانات الأساسية',
          fieldName: 'سعر الوحدة',
          oldValue: '10.00 USD',
          newValue: '15.00 USD',
        ),
      ];

      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                userChoice = await showChangeDiffConfirmationDialog(
                  context,
                  title: 'مراجعة وتأكيد تعديلات أمر الشراء',
                  itemReference: 'PO-2026-001',
                  changes: changes,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      // Tap button to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog contents
      expect(find.text('مراجعة وتأكيد تعديلات أمر الشراء'), findsOneWidget);
      expect(find.textContaining('PO-2026-001'), findsOneWidget);
      expect(find.text('قائمة التعبئة'), findsOneWidget);
      expect(find.text('تعليمات الرص'), findsOneWidget);
      expect(find.text('سعر الوحدة'), findsOneWidget);
      expect(find.text('10.00 USD'), findsOneWidget);
      expect(find.text('15.00 USD'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('تأكيد وحفظ التعديلات'));
      await tester.pumpAndSettle();

      expect(userChoice, isTrue);
    });

    testWidgets('Empty changes should return true immediately without showing dialog', (WidgetTester tester) async {
      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                userChoice = await showChangeDiffConfirmationDialog(
                  context,
                  title: 'مراجعة التعديلات',
                  itemReference: 'PO-2026-001',
                  changes: [],
                );
              },
              child: const Text('Open Empty Diff'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Empty Diff'));
      await tester.pump();

      expect(userChoice, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
