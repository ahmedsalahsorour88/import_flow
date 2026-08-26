import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/extraction_progress_dialog.dart';

void main() {
  group('ExtractionProgressController Tests', () {
    test('initial state should be 0%', () {
      final ctrl = ExtractionProgressController();
      expect(ctrl.percent, 0.0);
      expect(ctrl.percentInt, 0);
      expect(ctrl.currentStep, 1);
      ctrl.dispose();
    });

    test('update method should reflect progress and status', () {
      final ctrl = ExtractionProgressController();
      ctrl.update(
        percent: 0.45,
        status: 'جاري رفع الملف...',
        stepLabel: 'المرحلة 2 من 4',
        currentStep: 2,
      );

      expect(ctrl.percent, 0.45);
      expect(ctrl.percentInt, 45);
      expect(ctrl.status, 'جاري رفع الملف...');
      expect(ctrl.stepLabel, 'المرحلة 2 من 4');
      expect(ctrl.currentStep, 2);
      ctrl.dispose();
    });

    test('complete method should set progress to 100%', () {
      final ctrl = ExtractionProgressController();
      ctrl.complete();

      expect(ctrl.percent, 1.0);
      expect(ctrl.percentInt, 100);
      expect(ctrl.currentStep, 4);
      ctrl.dispose();
    });
  });

  group('ExtractionProgressDialog Widget Tests', () {
    testWidgets('should render progress dialog with title, filename and percentage', (tester) async {
      final ctrl = ExtractionProgressController();
      ctrl.update(
        percent: 0.65,
        status: 'جاري التعرف الضوئي OCR...',
        stepLabel: 'المرحلة 3 من 4: التعرف الضوئي',
        currentStep: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: ExtractionProgressDialog(
                title: 'جاري استخراج بيانات الفاتورة المبدئية',
                fileName: 'Proforma_Invoice_901.pdf',
                fileSize: '450.0 KB',
                controller: ctrl,
              ),
            ),
          ),
        ),
      );

      expect(find.text('جاري استخراج بيانات الفاتورة المبدئية'), findsOneWidget);
      expect(find.text('Proforma_Invoice_901.pdf'), findsOneWidget);
      expect(find.text('450.0 KB'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);

      ctrl.dispose();
    });
  });
}
