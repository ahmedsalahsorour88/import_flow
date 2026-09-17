import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/utils/container_requirement_engine.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart' hide PackingListItemModel;
import 'package:frontend/features/import_files/widgets/visual_container_load_planner_dialog.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';

void main() {
  group('PL-05: CBM & 3D Container Loading Test Suite', () {
    test('1. Auto 90-Degree Horizontal Rotation enables fitting wide cargo', () {
      // Cargo item with Width = 350 cm (> 235 cm container width),
      // but Length = 200 cm (<= 235 cm container width) and Width = 350 cm (<= 1203 cm length)
      final wideCargo = CargoItem(
        itemId: 'WIDE-01',
        length: 200.0,
        width: 350.0,
        height: 120.0,
        weight: 1500.0,
        rotate: true,
        isStackable: true,
      );

      final spec40hc = ContainerRequirementEngine.specs.firstWhere((s) => s.code == '40HC');
      final result = ContainerRequirementEngine.packCargo(
        items: [wideCargo],
        spec: spec40hc,
      );

      expect(result.fits, isTrue);
      expect(result.placedItems.length, equals(1));
      final placed = result.placedItems.first;
      // Dimensions were rotated so that placed width is <= 235 cm
      expect(placed.width, lessThanOrEqualTo(spec40hc.internalWidth));
      expect(placed.orientationType, anyOf(equals('flat_rotated'), equals('flat')));
    });

    test('2. Explicit Failure Diagnostics when cargo dimensions exceed container limits', () {
      // Both Length and Width exceed 235 cm container width (250 x 250 cm)
      final oversizedCargo = CargoItem(
        itemId: 'OVERSIZE-01',
        length: 250.0,
        width: 250.0,
        height: 150.0,
        weight: 2000.0,
        rotate: true,
        isStackable: false,
      );

      final spec20gp = ContainerRequirementEngine.specs.firstWhere((s) => s.code == '20GP');
      final result = ContainerRequirementEngine.packCargo(
        items: [oversizedCargo],
        spec: spec20gp,
      );

      expect(result.fits, isFalse);
      expect(result.unplacedItems.length, equals(1));
      expect(result.failureReason, isNotNull);
      expect(
        result.failureReason,
        contains('فشل الرص: تجاوز الطول والعرض الأبعاد القياسية للحاوية'),
      );
      expect(result.failureReason, contains('250 × 250'));
    });

    test('3. Explicit Failure Diagnostics when payload exceeds max allowable weight', () {
      // 2 pallets fitting in space (120x80 cm) but weighing 15,000 kg each = 30,000 kg (exceeds 20' GP max payload of 21,700 kg)
      final heavyItems = [
        CargoItem(
          itemId: 'HEAVY-01',
          length: 120.0,
          width: 80.0,
          height: 100.0,
          weight: 15000.0,
          rotate: true,
          isStackable: false,
        ),
        CargoItem(
          itemId: 'HEAVY-02',
          length: 120.0,
          width: 80.0,
          height: 100.0,
          weight: 15000.0,
          rotate: true,
          isStackable: false,
        ),
      ];

      final spec20gp = ContainerRequirementEngine.specs.firstWhere((s) => s.code == '20GP');
      final result = ContainerRequirementEngine.packCargo(
        items: heavyItems,
        spec: spec20gp,
      );

      expect(result.fits, isFalse);
      expect(result.placedItems.length, equals(2)); // Both fit on floor
      expect(result.unplacedItems, isEmpty);
      expect(result.failureReason, isNotNull);
      expect(result.failureReason, contains('يتجاوز الوزن المسموح للحاوية'));
    });

    test('4. Smart Hybrid multi-orientation saves container count over Flat Only', () {
      // Generate standard cargo items where vertical standing allows packing extra units per container
      final items = List.generate(
        52,
        (i) => CargoItem(
          itemId: 'PKG-$i',
          length: 120.0,
          width: 80.0,
          height: 95.0,
          weight: 280.0,
          rotate: true,
          isStackable: true,
          orientationPreference: CargoOrientationPreference.smartHybrid,
        ),
      );

      final planHybrid = ContainerRequirementEngine.planShipment(
        items,
        forceOrientation: CargoOrientationPreference.smartHybrid,
      );

      final planFlat = ContainerRequirementEngine.planShipment(
        items,
        forceOrientation: CargoOrientationPreference.flatOnly,
      );

      expect(planHybrid.length, lessThanOrEqualTo(planFlat.length));
      final dual = ContainerRequirementEngine.calculateBoth(
        totalCbm: 48.0,
        totalWeightKg: 14560.0,
      );
      expect(dual.modeRecommendation.recommendedMode, equals('Sea FCL'));
    });

    testWidgets('5. VisualContainerLoadPlannerDialog renders interactive 3D simulation and metrics', (tester) async {
      tester.view.physicalSize = const Size(1400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleFile = ImportFileModel(
        importFileId: 10,
        importFileCode: 'IMP-2026-0001',
        customFileNumber: 'Industrial Machinery',
        companyName: 'EL-DELTA GROUP',
        supplierName: 'KRAUSS MAFFEI GMBH',
        priority: 'High',
        shipmentCategory: 'Equipment',
        currentModule: 'STEP_07 تخصيص وتوزيع الحاويات والـ VGM',
        currentStage: 'Phase 3: Booking & Doc Prep',
        nextAction: 'مراجعة حمولة الحاويات',
        progressPercent: 35.0,
        status: 'Open',
        owner: 'Operations Lead',
        createdAt: '2026-09-01T10:00:00Z',
        updatedAt: '2026-09-17T10:00:00Z',
        estimatedCost: 85000.0,
        estimatedCostCurrency: 'USD',
      );

      final samplePO = PurchaseOrderModel(
        poId: 201,
        poNumber: 'PO-2026-0001',
        projectId: 1,
        companyId: 1,
        supplierId: 1,
        incotermId: 1,
        currencyId: 1,
        packingListItems: [
          PackingListItemModel(
            packingItemId: 1,
            poId: 201,
            hsCode: '8418.69.00',
            itemCode: 'CHILLER-01',
            description: 'Industrial Chiller Unit',
            qtyPcs: 1,
            qtyPkg: 1,
            packageType: 'CR - Crate (صندوق خشبي)',
            unit: 'cm',
            lengthCm: 220,
            widthCm: 140,
            heightCm: 160,
            weightUnit: 'KGM',
            netWeightUnitKg: 1700,
            grossWeightUnitKg: 1800,
            totalGrossWeightKg: 1800,
            totalNetWeightKg: 1700,
            totalCbm: 4.93,
            isStackable: false,
          ),
          PackingListItemModel(
            packingItemId: 2,
            poId: 201,
            hsCode: '8413.70.00',
            itemCode: 'PUMP-BOX-01',
            description: 'Circulation Pumps Pallet',
            qtyPcs: 4,
            qtyPkg: 4,
            packageType: 'PL - Pallet (طبلية)',
            unit: 'cm',
            lengthCm: 120,
            widthCm: 80,
            heightCm: 120,
            weightUnit: 'KGM',
            netWeightUnitKg: 320,
            grossWeightUnitKg: 350,
            totalGrossWeightKg: 1400,
            totalNetWeightKg: 1280,
            totalCbm: 4.61,
            isStackable: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: AppLocalizationsProvider(
                  locale: const Locale('ar'),
                  child: VisualContainerLoadPlannerDialog(
                    file: sampleFile,
                    linkedPOs: [samplePO],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify dialog header & title
      expect(find.textContaining('مخطط ومحاكاة رص الحاويات'), findsOneWidget);
      expect(find.textContaining('IMP-2026-0001'), findsOneWidget);

      // 2. Verify metric badges (Container code / Volume utilization / Export action buttons)
      expect(find.textContaining('20GP'), findsWidgets);
      expect(find.byIcon(Icons.view_in_ar), findsWidgets);
      expect(find.byIcon(Icons.table_chart_outlined), findsWidgets);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsWidgets);

      // 3. Verify stacking scenario choice chips
      expect(find.byKey(const Key('scenarioChip_1')), findsOneWidget);
      expect(find.byKey(const Key('scenarioChip_2')), findsOneWidget);
      expect(find.byKey(const Key('scenarioChip_3')), findsOneWidget);
    });
  });
}
