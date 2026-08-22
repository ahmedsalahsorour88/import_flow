import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';
import 'package:frontend/features/purchase_orders/widgets/po_report_preview_dialog.dart';

void main() {
  testWidgets('POReportPreviewDialog renders complete ERP report format with items and pallets', (WidgetTester tester) async {
    final sampleItems = [
      POLineItemModel(
        itemId: 1,
        itemCode: 'PSHD041',
        descriptionAr: 'طاولة متحركة بقاعدة معدنية MOBI',
        descriptionEn: 'Mobile table with metal base MOBI',
        quantity: 4.0,
        unitOfMeasure: 'PCS',
        unitPrice: 124.0,
        totalPrice: 496.0,
        grossWeightKg: 51.95,
        netWeightKg: 46.0,
      ),
      POLineItemModel(
        itemId: 2,
        itemCode: 'G2A0913',
        descriptionAr: 'سطح مكتب 500x400x16',
        descriptionEn: 'Desktop 500x400x16',
        quantity: 4.0,
        unitOfMeasure: 'PCS',
        unitPrice: 35.0,
        totalPrice: 140.0,
        grossWeightKg: 10.28,
        netWeightKg: 8.8,
      ),
    ];

    final samplePacking = [
      PackingListItemModel(
        itemCode: 'PSHD041',
        description: 'طاولة متحركة بقاعدة معدنية MOBI',
        hsCode: '9403100000',
        qtyPkg: 4.0,
        qtyPcs: 4.0,
        packageType: 'Carton',
        totalGrossWeightKg: 51.95,
        totalNetWeightKg: 46.0,
        totalCbm: 0.086,
      ),
      PackingListItemModel(
        itemCode: 'G2A0913',
        description: 'سطح مكتب 500x400x16',
        hsCode: '9403100000',
        qtyPkg: 4.0,
        qtyPcs: 4.0,
        packageType: 'Carton',
        totalGrossWeightKg: 10.28,
        totalNetWeightKg: 8.8,
        totalCbm: 0.031,
      ),
    ];

    final samplePallets = [
      PalletPlanItemModel(
        palletType: 'Euro Pallet (120x80)',
        palletCount: 13,
        lengthCm: 120.0,
        widthCm: 80.0,
        heightCm: 150.0,
        grossWeightPerPalletKg: 137.5,
        isStackable: false,
        notes: 'بالتات قياسية غير قابلة للرص',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                POReportPreviewDialog.show(
                  context: context,
                  poNumber: 'PO-2026-TEST',
                  piNumber: 'PI-9988',
                  acidNumber: '7595528271020210010',
                  orderDate: DateTime(2026, 8, 23),
                  companyName: 'Archi Brands for Trading',
                  companyTaxId: '100200300',
                  supplierName: 'UAB Narbutas International',
                  supplierCountry: 'Lithuania',
                  incoterm: 'EXW',
                  currency: 'EUR',
                  exchangeRate: 54.50,
                  items: sampleItems,
                  packingItems: samplePacking,
                  palletItems: samplePallets,
                );
              },
              child: const Text('Open Preview'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open report preview
    await tester.tap(find.text('Open Preview'));
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('معاينة تقرير أمر الشراء وقائمة التعبئة المعتمدة (PO & Packing List Preview)'), findsOneWidget);
    expect(find.textContaining('PO-2026-TEST'), findsWidgets);
    expect(find.textContaining('PI-9988'), findsWidgets);
    expect(find.textContaining('7595528271020210010'), findsWidgets);
    expect(find.text('Archi Brands for Trading'), findsOneWidget);
    expect(find.text('UAB Narbutas International'), findsOneWidget);

    // Verify Items and Packing
    expect(find.text('PSHD041'), findsWidgets);
    expect(find.text('G2A0913'), findsWidgets);
    expect(find.text('Euro Pallet (120x80)'), findsOneWidget);
    expect(find.text('13 بالتات'), findsOneWidget);
    expect(find.text('نسخ نص التقرير'), findsOneWidget);
    expect(find.text('حفظ واعتماد أمر الشراء'), findsOneWidget);
  });
}
