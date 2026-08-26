import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend/features/cargo_shipping/screens/cargo_shipping_screen.dart';
import 'package:frontend/features/cargo_shipping/providers/cargo_shipping_provider.dart';
import 'package:frontend/features/cargo_shipping/models/cargo_shipping_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/freight_booking/providers/freight_booking_provider.dart';
import 'package:frontend/features/purchase_orders/providers/purchase_orders_provider.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';
import 'package:frontend/features/freight_booking/models/freight_booking_model.dart';

void main() {
  testWidgets('CargoShippingScreen should prefill dates, times, and milestone notes accurately', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRecord = CargoShippingModel(
      cargoShippingId: 4,
      cargoShippingCode: 'SHP-2026-0004',
      importFileId: 1,
      importFileCode: '6701068100-HSR',
      companyName: 'ECO ASSOCIATES',
      shipmentType: 'FCL',
      containersLoadingData: [
        ContainerLoadingModel(
          containerNo: 'MSCU1234567',
          sealNo: 'SL-99001',
          containerType: '40HC',
          tareWeightKg: 3800.0,
          netWeightKg: 20700.0,
          grossWeightKg: 24500.0,
          vgmStatus: 'Submitted',
          vgmRefNo: 'VGM-9901',
          containerAssignmentDate: '2026-08-16T12:00:00',
          arrivalAtSupplierAt: '2026-08-16T13:56:00',
          loadingStartAt: '2026-08-16T15:56:00',
          loadingEndAt: '2026-08-16T18:56:00',
          portGateInAt: '2026-08-16T23:56:00',
          trackingStatus: 'GATED_IN_AT_PORT',
          milestoneNotes: {
            '1': 'تخصيص الحاوية بواسطة الخط الملاحي',
            '2': 'وصول الحاوية لمخزن المورد',
          },
        )
      ],
      courierTrackingData: CourierTrackingModel(),
      cargoxExchangeData: CargoXExchangeModel(),
      status: 'Cargo Ready',
      owner: 'Kamal',
      isActive: true,
      createdAt: '2026-08-16T10:00:00',
      updatedAt: '2026-08-16T12:00:00',
    );

    final container = ProviderContainer(
      overrides: [
        cargoShippingProvider.overrideWith((ref) => _MockCargoShippingNotifier([mockRecord])),
        importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([
          ImportFileModel(
            importFileId: 1,
            importFileCode: '6701068100-HSR',
            companyId: 1,
            companyName: 'ECO ASSOCIATES',
            supplierName: 'Siemens Mobility',
            currentModule: 'Cargo Shipping',
            currentStage: 'Cargo Preparation',
            nextAction: 'Track Containers',
            status: 'Active',
            createdAt: '2026-08-16T00:00:00',
            updatedAt: '2026-08-16T00:00:00',
          )
        ])),
        freightBookingProvider.overrideWith((ref) => _MockFreightBookingNotifier([])),
        purchaseOrdersProvider.overrideWith((ref) => _MockPurchaseOrdersNotifier([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: AppLocalizationsProvider(
                locale: Locale('ar'),
                child: CargoShippingScreen(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify screen loaded
    expect(find.textContaining('تخصيص وتوزيع الحاويات ومتابعة حركة الشحن'), findsOneWidget);
    
    // Tap Tab 2 (Saved Registry)
    await tester.tap(find.textContaining('سجل متابعة الشحنات والتحميل'));
    await tester.pumpAndSettle();

    // Find the record and verify it exists
    expect(find.textContaining('SHP-2026-0004'), findsOneWidget);

    // Tap on the saved record to edit/load
    await tester.tap(find.textContaining('SHP-2026-0004'));
    await tester.pumpAndSettle();

    // Verify all 5 timestamps are loaded in step 2
    expect(find.textContaining('2026-08-16 | 12:00'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 1:56'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 3:56'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 6:56'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 11:56'), findsOneWidget);

    // Verify note is loaded
    expect(find.textContaining('تخصيص الحاوية بواسطة الخط الملاحي'), findsNWidgets(2));
  });

  testWidgets('Selecting import file from dropdown should auto-load dates and notes', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRecord = CargoShippingModel(
      cargoShippingId: 4,
      cargoShippingCode: 'SHP-2026-0004',
      importFileId: 1,
      importFileCode: '6701068100-HSR',
      companyName: 'ECO ASSOCIATES',
      shipmentType: 'FCL',
      containersLoadingData: [
        ContainerLoadingModel(
          containerNo: 'MSCU1234567',
          sealNo: 'SL-99001',
          containerType: '40HC',
          tareWeightKg: 3800.0,
          netWeightKg: 20700.0,
          grossWeightKg: 24500.0,
          vgmStatus: 'Submitted',
          vgmRefNo: 'VGM-9901',
          containerAssignmentDate: '2026-08-16T12:00:00',
          arrivalAtSupplierAt: '2026-08-16T13:56:00',
          loadingStartAt: '2026-08-16T15:56:00',
          loadingEndAt: '2026-08-16T18:56:00',
          portGateInAt: '2026-08-16T23:56:00',
          trackingStatus: 'GATED_IN_AT_PORT',
          milestoneNotes: {
            '1': 'تخصيص الحاوية بواسطة الخط الملاحي',
            '2': 'وصول الحاوية لمخزن المورد',
          },
        )
      ],
      courierTrackingData: CourierTrackingModel(),
      cargoxExchangeData: CargoXExchangeModel(),
      status: 'Cargo Ready',
      owner: 'Kamal',
      isActive: true,
      createdAt: '2026-08-16T10:00:00',
      updatedAt: '2026-08-16T12:00:00',
    );

    final container = ProviderContainer(
      overrides: [
        cargoShippingProvider.overrideWith((ref) => _MockCargoShippingNotifier([mockRecord])),
        importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([
          ImportFileModel(
            importFileId: 1,
            importFileCode: '6701068100-HSR',
            companyId: 1,
            companyName: 'ECO ASSOCIATES',
            supplierName: 'Siemens Mobility',
            currentModule: 'Cargo Shipping',
            currentStage: 'Cargo Preparation',
            nextAction: 'Track Containers',
            status: 'Active',
            createdAt: '2026-08-16T00:00:00',
            updatedAt: '2026-08-16T00:00:00',
          )
        ])),
        freightBookingProvider.overrideWith((ref) => _MockFreightBookingNotifier([])),
        purchaseOrdersProvider.overrideWith((ref) => _MockPurchaseOrdersNotifier([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: AppLocalizationsProvider(
                locale: Locale('ar'),
                child: CargoShippingScreen(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Select import file from SearchableDropdownField
    await tester.tap(find.textContaining('اختر ملف الشحنة...'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap the option for file 1
    await tester.tap(find.textContaining('ECO ASSOCIATES').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify all 5 timestamps are loaded
    expect(find.textContaining('2026-08-16 | 12:00'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 1:56'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 3:56'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 6:56'), findsOneWidget);
    expect(find.textContaining('2026-08-16 | 11:56'), findsOneWidget);

    // Verify note is loaded
    expect(find.textContaining('تخصيص الحاوية بواسطة الخط الملاحي'), findsNWidgets(2));
  });

}

class _MockCargoShippingNotifier extends CargoShippingNotifier {
  final List<CargoShippingModel> initialRecords;
  _MockCargoShippingNotifier(this.initialRecords) : super(Dio()) {
    state = AsyncValue.data(initialRecords);
  }

  @override
  Future<void> fetchRecords({bool includeInactive = true, int? importFileId, String? status, String? search}) async {
    state = AsyncValue.data(initialRecords);
  }
}

class _MockImportFilesNotifier extends ImportFilesNotifier {
  final List<ImportFileModel> initialFiles;
  _MockImportFilesNotifier(this.initialFiles) : super(Dio()) {
    state = AsyncValue.data(initialFiles);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {
    state = AsyncValue.data(initialFiles);
  }
}

class _MockFreightBookingNotifier extends FreightBookingNotifier {
  final List<ShipmentBookingModel> initialBookings;
  _MockFreightBookingNotifier(this.initialBookings) : super(Dio()) {
    state = AsyncValue.data(initialBookings);
  }

  @override
  Future<void> fetchBookings({bool includeInactive = false, int? importFileId, String? status, String? search}) async {
    state = AsyncValue.data(initialBookings);
  }
}

class _MockPurchaseOrdersNotifier extends StateNotifier<PurchaseOrdersState> implements PurchaseOrdersNotifier {
  final List<PurchaseOrderModel> initialPOs;
  _MockPurchaseOrdersNotifier(this.initialPOs) : super(PurchaseOrdersState(purchaseOrders: initialPOs));

  @override
  Future<void> fetchPurchaseOrders({
    bool includeInactive = false,
    String? search,
    int? importFileId,
    int? supplierId,
    String? status,
  }) async {
    state = state.copyWith(purchaseOrders: initialPOs, isLoading: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
