import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_consultation/models/customs_consultation_model.dart';
import 'package:frontend/features/customs_consultation/widgets/recalculation_variance_comparison_card.dart';

void main() {
  testWidgets('RecalculationVarianceComparisonCard renders all KPIs and items correctly', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final recalculationResult = CustomsRecalculationResponseModel(
      importFileId: 10,
      importFileCode: 'IMP-2026-001',
      finalInvoiceNumber: 'INV-FINAL-2026-88',
      reconciliationSessionId: 5,
      isReconciled: true,
      sourceDescription: 'الفاتورة وقائمة التعبئة النهائية المعتمدة',
      exchangeRate: 52.0,
      estimateDate: '2026-08-21',
      preliminaryFobEgp: 500000.0,
      finalFobEgp: 624000.0,
      fobVarianceEgp: 124000.0,
      preliminaryCifEgp: 520000.0,
      finalCifEgp: 644000.0,
      cifVarianceEgp: 124000.0,
      preliminaryDutyEgp: 52000.0,
      finalDutyEgp: 64400.0,
      dutyVarianceEgp: 12400.0,
      preliminaryVatEgp: 80080.0,
      finalVatEgp: 99176.0,
      vatVarianceEgp: 19096.0,
      preliminaryTotalTaxesEgp: 132080.0,
      finalTotalTaxesEgp: 163576.0,
      totalTaxesVarianceEgp: 31496.0,
      variancePercentage: 23.8,
      forecastStatus: 'Increased Cost',
      comparisonLines: [
        LineVarianceComparisonModel(
          itemName: 'Raw Marble Blocks',
          hsCode: '6802.99',
          countryOfOrigin: 'CN',
          preliminaryQty: 100.0,
          finalQty: 120.0,
          qtyVariance: 20.0,
          preliminaryUnitPrice: 100.0,
          finalUnitPrice: 100.0,
          unitPriceVariance: 0.0,
          preliminaryFobEgp: 500000.0,
          finalFobEgp: 624000.0,
          fobVarianceEgp: 124000.0,
          preliminaryCifEgp: 520000.0,
          finalCifEgp: 644000.0,
          cifVarianceEgp: 124000.0,
          dutyRatePct: 10.0,
          preliminaryDutyEgp: 52000.0,
          finalDutyEgp: 64400.0,
          dutyVarianceEgp: 12400.0,
          vatRatePct: 14.0,
          preliminaryVatEgp: 80080.0,
          finalVatEgp: 99176.0,
          vatVarianceEgp: 19096.0,
          preliminaryTotalTaxesEgp: 132080.0,
          finalTotalTaxesEgp: 163576.0,
          totalTaxesVarianceEgp: 31496.0,
        ),
      ],
    );

    bool applied = false;
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecalculationVarianceComparisonCard(
              recalculationResult: recalculationResult,
              onApplyNewFees: () => applied = true,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('شاشة إعادة احتساب الجمارك ومقارنة الفروق وتوقع السيولة'), findsOneWidget);
    expect(find.textContaining('INV-FINAL-2026-88'), findsOneWidget);
    expect(find.text('Raw Marble Blocks'), findsOneWidget);
    expect(find.text('6802.99'), findsOneWidget);
    expect(find.text('💾 حفظ الرسوم الجديدة واعتماد دراسة الجمارك المحدثة'), findsOneWidget);

    await tester.tap(find.text('💾 حفظ الرسوم الجديدة واعتماد دراسة الجمارك المحدثة'));
    expect(applied, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });
}
