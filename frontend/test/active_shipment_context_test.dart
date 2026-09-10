import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/active_shipment_context.dart';

void main() {
  group('ActiveShipmentContext - Model & Inactivity Window', () {
    test('creates valid model with correct initial values', () {
      final now = DateTime.now();
      final ctx = ActiveShipmentContext(
        shipmentId: 4,
        shipmentName: 'PET Stock',
        clientName: 'SCAS',
        fileCode: 'IMP-2026-0004',
        stepId: 5,
        stepNameAr: 'تخصيص الحاويات',
        stepNameEn: 'Container Allocation',
        screenReference: 'شاشة شحن وتجهيز البضاعة (Phase 5)',
        setAt: now,
      );

      expect(ctx.shipmentId, equals(4));
      expect(ctx.shipmentName, equals('PET Stock'));
      expect(ctx.clientName, equals('SCAS'));
      expect(ctx.fileCode, equals('IMP-2026-0004'));
      expect(ctx.stepId, equals(5));
      expect(ctx.stepNameAr, equals('تخصيص الحاويات'));
      expect(ctx.stepNameEn, equals('Container Allocation'));
      expect(ctx.screenReference, equals('شاشة شحن وتجهيز البضاعة (Phase 5)'));
      expect(ctx.setAt, equals(now));
    });

    test('returns localized stepName and displayText correctly', () {
      final ctx = ActiveShipmentContext(
        shipmentId: 4,
        shipmentName: 'PET Stock',
        clientName: 'SCAS',
        fileCode: 'IMP-2026-0004',
        stepId: 5,
        stepNameAr: 'تخصيص الحاويات',
        stepNameEn: 'Container Allocation',
        setAt: DateTime.now(),
      );

      expect(ctx.stepName('ar'), equals('تخصيص الحاويات'));
      expect(ctx.stepName('en'), equals('Container Allocation'));

      expect(ctx.displayText('ar'), equals('PET Stock – SCAS ← تخصيص الحاويات'));
      expect(ctx.displayText('en'), equals('PET Stock – SCAS ← Container Allocation'));
    });

    test('inactivity timeout evaluation (4-hour window)', () {
      final now = DateTime.now();

      // Fresh context (just created)
      final fresh = ActiveShipmentContext(
        shipmentId: 1,
        shipmentName: 'Cargo',
        clientName: 'Client',
        fileCode: 'IMP-1',
        stepId: 1,
        stepNameAr: 'الجدوى',
        stepNameEn: 'Feasibility',
        setAt: now,
      );
      expect(fresh.isExpired(), isFalse);

      // Context 2 hours old -> NOT expired
      final twoHoursOld = fresh.copyWith(
        setAt: now.subtract(const Duration(hours: 2)),
      );
      expect(twoHoursOld.isExpired(), isFalse);

      // Context exactly 3 hours 59 minutes old -> NOT expired
      final almostExpired = fresh.copyWith(
        setAt: now.subtract(const Duration(hours: 3, minutes: 59)),
      );
      expect(almostExpired.isExpired(), isFalse);

      // Context 4 hours and 1 minute old -> EXPIRED
      final expired = fresh.copyWith(
        setAt: now.subtract(const Duration(hours: 4, minutes: 1)),
      );
      expect(expired.isExpired(), isTrue);

      // Custom timeout (e.g. 30 minutes)
      expect(fresh.copyWith(setAt: now.subtract(const Duration(minutes: 35))).isExpired(timeout: const Duration(minutes: 30)), isTrue);
      expect(fresh.copyWith(setAt: now.subtract(const Duration(minutes: 20))).isExpired(timeout: const Duration(minutes: 30)), isFalse);
    });

    test('serializes to and from Map and JSON string correctly', () {
      final setAt = DateTime.parse('2026-09-09T10:00:00.000');
      final original = ActiveShipmentContext(
        shipmentId: 7,
        shipmentName: 'PVC Resin',
        clientName: 'Egyptian Polymers',
        fileCode: 'IMP-2026-0007',
        stepId: 4,
        stepNameAr: 'حجز الشحن والناقل',
        stepNameEn: 'Freight Booking',
        screenReference: 'شاشة حجز الشحن',
        setAt: setAt,
      );

      final jsonMap = original.toJson();
      expect(jsonMap['shipment_id'], equals(7));
      expect(jsonMap['shipment_name'], equals('PVC Resin'));
      expect(jsonMap['file_code'], equals('IMP-2026-0007'));
      expect(jsonMap['step_id'], equals(4));

      final restoredFromMap = ActiveShipmentContext.fromJson(jsonMap);
      expect(restoredFromMap.shipmentId, equals(original.shipmentId));
      expect(restoredFromMap.shipmentName, equals(original.shipmentName));
      expect(restoredFromMap.clientName, equals(original.clientName));
      expect(restoredFromMap.fileCode, equals(original.fileCode));
      expect(restoredFromMap.stepId, equals(original.stepId));
      expect(restoredFromMap.stepNameAr, equals(original.stepNameAr));
      expect(restoredFromMap.stepNameEn, equals(original.stepNameEn));
      expect(restoredFromMap.screenReference, equals(original.screenReference));

      // String serialization for SharedPreferences
      final jsonStr = original.toJsonString();
      final restoredFromString = ActiveShipmentContext.fromJsonString(jsonStr);
      expect(restoredFromString, isNotNull);
      expect(restoredFromString!.shipmentId, equals(original.shipmentId));
      expect(restoredFromString.fileCode, equals(original.fileCode));
      expect(restoredFromString.stepNameEn, equals(original.stepNameEn));

      // Invalid JSON string returns null safely without throwing
      expect(ActiveShipmentContext.fromJsonString('invalid-json'), isNull);
    });
  });
}
