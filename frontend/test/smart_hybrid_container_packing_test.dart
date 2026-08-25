import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/container_requirement_engine.dart';

void main() {
  group('Smart Hybrid 3D Container Bin Packing Tests (MD-019.1)', () {
    test('Scenario 1: User 144 packages (286x124x13 cm) in Smart Hybrid Mode fits 100% in 1 x 40HC', () {
      // 144 items of 286 x 124 x 13 cm, 73 kg each
      final items = List.generate(
        144,
        (i) => CargoItem(
          itemId: '${i + 1}',
          length: 286.0,
          width: 124.0,
          height: 13.0,
          weight: 73.0,
          rotate: true,
          isStackable: true,
          orientationPreference: CargoOrientationPreference.smartHybrid,
        ),
      );

      final spec40HC = ContainerRequirementEngine.specs.firstWhere((s) => s.code == '40HC');
      final result = ContainerRequirementEngine.packCargo(
        items: items,
        spec: spec40HC,
        forceOrientation: CargoOrientationPreference.smartHybrid,
      );

      expect(result.fits, isTrue);
      expect(result.placedItems.length, equals(144));
      expect(result.unplacedItems.length, equals(0));
      expect(result.edgePlacedCount, greaterThan(0)); // Proves on-edge vertical placement was utilized!
      expect(result.flatPlacedCount, greaterThan(0)); // Proves flat placement was utilized!

      // Test Shipment Plan
      final plan = ContainerRequirementEngine.planShipment(
        items,
        forceOrientation: CargoOrientationPreference.smartHybrid,
      );
      expect(plan.length, equals(1));
      expect(plan.first.containerCode, equals('40HC'));
      expect(plan.first.fits, isTrue);
      expect(plan.first.placedItems.length, equals(144));
    });

    test('Scenario 2: User 144 packages in Flat Only Mode requires 2 containers (1x40HC + 1x40GP)', () {
      final items = List.generate(
        144,
        (i) => CargoItem(
          itemId: '${i + 1}',
          length: 286.0,
          width: 124.0,
          height: 13.0,
          weight: 73.0,
          rotate: true,
          isStackable: true,
          orientationPreference: CargoOrientationPreference.flatOnly,
        ),
      );

      final spec40HC = ContainerRequirementEngine.specs.firstWhere((s) => s.code == '40HC');
      final result = ContainerRequirementEngine.packCargo(
        items: items,
        spec: spec40HC,
        forceOrientation: CargoOrientationPreference.flatOnly,
      );

      // In flat only mode, a single 40HC can only fit 80 items due to width channel limitation
      expect(result.placedItems.length, equals(80));
      expect(result.unplacedItems.length, equals(64));
      expect(result.fits, isFalse);

      final plan = ContainerRequirementEngine.planShipment(
        items,
        forceOrientation: CargoOrientationPreference.flatOnly,
      );
      expect(plan.length, equals(2));
      expect(plan[0].containerCode, equals('40HC'));
      expect(plan[0].placedItems.length, equals(80));
      expect(plan[1].containerCode, equals('40GP'));
      expect(plan[1].placedItems.length, equals(64));
    });

    test('Scenario 3: calculateBoth provides dual comparison and identifies hybrid savings', () {
      const double totalCbm = 66.389;
      const double totalWeightKg = 10512.0;

      final dualRec = ContainerRequirementEngine.calculateBoth(
        totalCbm: totalCbm,
        totalWeightKg: totalWeightKg,
      );

      expect(dualRec.smartHybridResult, isNotNull);
      expect(dualRec.flatOnlyResult, isNotNull);
      expect(dualRec.smartHybridResult!.requiredContainersCount, equals(1));
      expect(dualRec.flatOnlyResult!.requiredContainersCount, equals(2));
      expect(dualRec.hasHybridSavings, isTrue);
      expect(dualRec.containersSavedCount, equals(1));
    });
  });
}
