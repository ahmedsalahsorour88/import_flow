import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_consultation/services/customs_export_service.dart';

void main() {
  group('CustomsExportService & Nafeza Statement Fee Engine Unit Tests (MD-008)', () {
    test('computeNafezaFeeBreakdown should construct all 5 official Nafeza collection groups accurately', () {
      const duty = 17541.92;
      const vat = 39456.22;
      const serviceFee = 6230.0;
      const scheduleTax = 0.0;

      final result = CustomsExportService.computeNafezaFeeBreakdown(
        totalDutyEgp: duty,
        totalVatEgp: vat,
        totalServiceFeeEgp: serviceFee,
        totalScheduleTaxEgp: scheduleTax,
      );

      // 1. Check all 5 groups exist
      expect(result.groups.length, 5);
      expect(result.groups[0].groupName, 'رسم مستخلص');
      expect(result.groups[1].groupName, 'ضريبة جمارك');
      expect(result.groups[2].groupName, 'أ.ت.ص');
      expect(result.groups[3].groupName, 'ض.مبيعات');
      expect(result.groups[4].groupName, 'رسوم النافذة الموحدة');

      // 2. Check Group 1: رسم مستخلص
      final g1 = result.groups[0];
      expect(g1.totalAmount, 50.0);
      expect(g1.items.first.code, '77');
      expect(g1.items.first.nameAr, 'ضريبة مهن حرة');

      // 3. Check Group 2: ضريبة جمارك
      final g2 = result.groups[1];
      final item1 = g2.items.firstWhere((i) => i.code == '1');
      expect(item1.calculatedAmount, duty);
      expect(item1.calculationType, 'reference');

      final item250 = g2.items.firstWhere((i) => i.code == '250');
      expect(item250.calculatedAmount, 55.0);

      // 4. Check Group 3: أ.ت.ص
      final g3 = result.groups[2];
      expect(g3.items.first.code, '37');
      expect(g3.items.first.calculatedAmount, serviceFee);

      // 5. Check Group 4: ض.مبيعات
      final g4 = result.groups[3];
      final item32 = g4.items.firstWhere((i) => i.code == '32');
      expect(item32.calculatedAmount, vat);
      final item232 = g4.items.firstWhere((i) => i.code == '232');
      expect(item232.calculatedAmount, 100.0);

      // 6. Check Group 5: رسوم النافذة الموحدة
      final g5 = result.groups[4];
      final item390 = g5.items.firstWhere((i) => i.code == '390');
      expect(item390.calculatedAmount, 1081.0);
      final item392 = g5.items.firstWhere((i) => i.code == '392');
      expect(item392.calculatedAmount, 3457.0);
      final item394 = g5.items.firstWhere((i) => i.code == '394');
      expect(item394.calculatedAmount, closeTo((1081.0 + 3457.0) * 0.14, 0.01));

      // 7. Check Grand Total
      final sumGroups = result.groups.fold(0.0, (s, g) => s + g.totalAmount);
      expect(result.grandTotal, closeTo(sumGroups, 0.001));
    });
  });
}
