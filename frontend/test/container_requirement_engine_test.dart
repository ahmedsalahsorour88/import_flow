import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/container_requirement_engine.dart';

void main() {
  group('ContainerRequirementEngine - Cargo Stacking & Shipment Mode Skill Tests', () {
    test('Should recommend Sea LCL when total CBM < 15 m³ (and not qualifying for Air)', () {
      final rec = ContainerRequirementEngine.recommendShipmentMode(
        totalCbm: 10.0,
        totalWeightKg: 500.0, // Air Volumetric Wt = 10 * 166.67 = 1666.7 kg (> 500 kg, so fails Air Condition 1)
      );

      expect(rec.recommendedMode, equals('Sea LCL'));
      expect(rec.isLclSuggested, isTrue);
      expect(rec.isAirSuggested, isFalse);
      expect(rec.reasonAr, contains('شحن بحري جزئي (Sea LCL)'));
    });

    test('Should recommend Air Freight ONLY when BOTH Condition 1 (Gross Wt >= Air Chargeable Wt) AND Condition 2 (CBM < 5) are met', () {
      // Satisfies BOTH conditions:
      // Condition 1: Gross Weight 800 kg >= Volumetric Weight (3.0 * 166.67 = 500.01 kg) -> TRUE
      // Condition 2: CBM 3.0 < 5.0 -> TRUE
      final rec = ContainerRequirementEngine.recommendShipmentMode(
        totalCbm: 3.0,
        totalWeightKg: 800.0,
      );

      expect(rec.recommendedMode, equals('Air'));
      expect(rec.isAirSuggested, isTrue);
      expect(rec.isLclSuggested, isFalse);
      expect(rec.reasonAr, contains('اقتراح شحن جوي (AIR)'));
    });

    test('Should NOT recommend Air Freight if CBM >= 5 m³ even if Gross Wt is high (Condition 2 fails)', () {
      // Gross Weight 2000 kg >= Volumetric Wt (6.0 * 166.67 = 1000 kg) -> Condition 1 passes
      // CBM 6.0 >= 5.0 -> Condition 2 FAILS!
      final rec = ContainerRequirementEngine.recommendShipmentMode(
        totalCbm: 6.0,
        totalWeightKg: 2000.0,
      );

      expect(rec.recommendedMode, equals('Sea LCL'));
      expect(rec.isAirSuggested, isFalse);
      expect(rec.isLclSuggested, isTrue);
    });

    test('Should NOT recommend Air Freight if Gross Wt < Volumetric Wt even if CBM < 5 m³ (Condition 1 fails)', () {
      // CBM 4.0 < 5.0 -> Condition 2 passes
      // Gross Wt 200 kg < Volumetric Wt (4.0 * 166.67 = 666.68 kg) -> Condition 1 FAILS!
      final rec = ContainerRequirementEngine.recommendShipmentMode(
        totalCbm: 4.0,
        totalWeightKg: 200.0,
      );

      expect(rec.recommendedMode, equals('Sea LCL'));
      expect(rec.isAirSuggested, isFalse);
      expect(rec.isLclSuggested, isTrue);
    });

    test('Should recommend Sea FCL when total CBM >= 15 m³', () {
      final rec = ContainerRequirementEngine.recommendShipmentMode(
        totalCbm: 35.0,
        totalWeightKg: 12000.0,
      );

      expect(rec.recommendedMode, equals('Sea FCL'));
      expect(rec.isAirSuggested, isFalse);
      expect(rec.isLclSuggested, isFalse);
      expect(rec.reasonAr, contains('شحن بحري حاوية كاملة (Sea FCL)'));
    });

    test('calculateBoth should attach modeRecommendation correctly', () {
      final dual = ContainerRequirementEngine.calculateBoth(
        totalCbm: 4.0,
        totalWeightKg: 1500.0, // High density small cargo -> Air
      );

      expect(dual.modeRecommendation.recommendedMode, equals('Air'));
      expect(dual.stackableResult.modeRecommendation.recommendedMode, equals('Air'));
      expect(dual.nonStackableResult.modeRecommendation.recommendedMode, equals('Air'));
    });

    test('packCargo should handle mixed stackable and non-stackable cargo safely', () {
      // 1. Non-stackable heavy crate: 300 x 190 x 104 cm, 590 kg
      // 2. Stackable box 1: 120 x 80 x 100 cm, 200 kg
      // 3. Stackable box 2: 120 x 80 x 100 cm, 200 kg (should stack on top of box 1)
      final items = [
        CargoItem(itemId: '1', length: 300, width: 190, height: 104, weight: 590, isStackable: false),
        CargoItem(itemId: '2', length: 120, width: 80, height: 100, weight: 200, isStackable: true),
        CargoItem(itemId: '3', length: 120, width: 80, height: 100, weight: 200, isStackable: true),
      ];

      final spec = ContainerRequirementEngine.specs.firstWhere((s) => s.code == '40HC');
      final result = ContainerRequirementEngine.packCargo(items: items, spec: spec);

      expect(result.fits, isTrue);
      expect(result.placedItems.length, equals(3));

      // Non-stackable item #1 must be on the floor (z = 0)
      final placed1 = result.placedItems.firstWhere((p) => p.item.itemId == '1');
      expect(placed1.isOnFloor, isTrue);
      expect(placed1.z, equals(0.0));

      // One of the stackable items should be stacked on top of the other (z = 100)
      final placedStack = result.placedItems.where((p) => p.item.isStackable).toList();
      expect(placedStack.length, equals(2));
      final elevated = placedStack.where((p) => p.z > 0).toList();
      expect(elevated.length, equals(1));
      expect(elevated.first.z, equals(100.0));
    });

    test('109.925 CBM Stackable should recommend 2 x 40HC, and Non-Stackable should recommend 2 x 40HC + 1 x 20GP', () {
      final stackable = ContainerRequirementEngine.calculate(
        totalCbm: 109.925,
        totalWeightKg: 15834.0,
        isStackable: true,
      );
      expect(stackable.recommendationSummary, contains('2 x 40HC'));

      final nonStackable = ContainerRequirementEngine.calculate(
        totalCbm: 109.925,
        totalWeightKg: 15834.0,
        isStackable: false,
      );
      expect(nonStackable.recommendationSummary, contains('2 x 40HC + 1 x 20GP'));
    });

    test('planShipment should respect forceStackable modes (all stackable, all non-stackable, and mixed)', () {
      // 4 items: each 300 x 190 x 104 cm
      final items = [
        CargoItem(itemId: '1', length: 300, width: 190, height: 104, weight: 500, isStackable: false),
        CargoItem(itemId: '2', length: 300, width: 190, height: 104, weight: 500, isStackable: false),
        CargoItem(itemId: '3', length: 300, width: 190, height: 104, weight: 500, isStackable: true),
        CargoItem(itemId: '4', length: 300, width: 190, height: 104, weight: 500, isStackable: true),
      ];

      // 1. Force Stackable
      final planStackable = ContainerRequirementEngine.planShipment(items, forceStackable: true);
      expect(planStackable.isNotEmpty, isTrue);

      // 2. Force Non-Stackable
      final planNonStackable = ContainerRequirementEngine.planShipment(items, forceStackable: false);
      expect(planNonStackable.isNotEmpty, isTrue);

      // 3. Mixed (actual)
      final planMixed = ContainerRequirementEngine.planShipment(items, forceStackable: null);
      expect(planMixed.isNotEmpty, isTrue);
    });

    test('19 packages with 7 stackable and 12 non-stackable should NOT exceed all-non-stackable container count', () {
      final items = <CargoItem>[];
      for (int i = 1; i <= 5; i++) {
        items.add(CargoItem(itemId: '$i', length: 215.8, width: 200.0, height: 225.0, weight: 2700.0, isStackable: true, packageType: 'Pallet'));
      }
      for (int i = 6; i <= 15; i++) {
        items.add(CargoItem(itemId: '$i', length: 100.0, width: 80.0, height: 100.0, weight: 6.0, isStackable: false, packageType: 'Carton'));
      }
      for (int i = 16; i <= 17; i++) {
        items.add(CargoItem(itemId: '$i', length: 395.0, width: 225.0, height: 225.0, weight: 1135.0, isStackable: false, packageType: 'Unit'));
      }
      for (int i = 18; i <= 19; i++) {
        items.add(CargoItem(itemId: '$i', length: 27.5, width: 26.5, height: 16.0, weight: 2.0, isStackable: false, packageType: 'Box'));
      }

      final planMixed = ContainerRequirementEngine.planShipment(items);
      final planNonStackable = ContainerRequirementEngine.planShipment(items, forceStackable: false);

      // Mixed plan should have <= container count than non-stackable plan (3 containers: 2 x 40HC + 1 x 20GP)
      expect(planMixed.length, equals(3));
      expect(planMixed.length, lessThanOrEqualTo(planNonStackable.length));
      expect(planMixed[0].containerCode, equals('40HC'));
      expect(planMixed[1].containerCode, equals('40HC'));
      expect(planMixed[2].containerCode, equals('20GP'));
    });
  });
}

