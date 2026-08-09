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
  });
}
