import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_clearance/models/customs_clearance_model.dart';
import 'package:frontend/features/customs_clearance/providers/customs_clearance_provider.dart';
import 'package:frontend/features/customs_clearance/screens/customs_clearance_screen.dart';
import 'package:frontend/features/external_service_providers/models/partner_model.dart';
import 'package:frontend/features/external_service_providers/providers/partners_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class _MockClearanceNotifier extends CustomsClearanceNotifier {
  final List<CustomsClearanceModel> initialRecords;
  _MockClearanceNotifier(this.initialRecords) : super(Dio()) {
    state = AsyncValue.data(initialRecords);
  }

  @override
  Future<void> fetchRecords({
    bool includeInactive = false,
    int? importFileId,
    String? status,
    String? search,
  }) async {
    state = AsyncValue.data(initialRecords);
  }
}

class _MockImportFilesNotifier extends ImportFilesNotifier {
  _MockImportFilesNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
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
    state = const AsyncValue.data([]);
  }
}

class _MockPartnersNotifier extends PartnersNotifier {
  _MockPartnersNotifier() : super(category: 'All', showInactive: true, dio: Dio()) {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> fetchPartners() async {
    state = const AsyncValue.data([]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockClearance = CustomsClearanceModel(
    customsClearanceId: 10,
    clearanceCode: 'CLR-2026-0010',
    importFileId: 5,
    declaration46No: '46-ALX-2026-991',
    customsOfficeName: 'Alexandria Port Customs',
    channelType: 'Red Channel',
    inspectionNotes: 'كشف فعلي وظاهري بنسبة 100%',
    importDutyAmount: 25000.0,
    vatAmount: 38000.0,
    totalDutyPayable: 63000.0,
    actualDutyTotal: 63000.0,
    paymentStatus: 'Paid & Verified',
    status: 'Duty Paid',
    deliveryOrderNumber: 'DO-MEDU-99881',
    freeDaysAllowed: 14,
    createdAt: '2026-08-23T00:00:00Z',
    updatedAt: '2026-08-23T00:00:00Z',
    owner: 'Admin',
  );

  group('CustomsClearanceScreen 4 Subtabs Tests', () {
    testWidgets('Renders Tab 0 (Customs Clearance Follow-up) correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customsClearanceProvider.overrideWith((ref) => _MockClearanceNotifier([mockClearance])),
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier()),
            partnersProvider.overrideWith((ref) => _MockPartnersNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomsClearanceScreen(initialSubTab: 0),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('متابعة الكشف والتثمين والتفتيش الجمركي'), findsWidgets);
      expect(find.text('CLR-2026-0010'), findsOneWidget);
      expect(find.text('46 ك.م: 46-ALX-2026-991'), findsOneWidget);
    });

    testWidgets('Renders Tab 1 (Drawing Samples & Shortage) correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customsClearanceProvider.overrideWith((ref) => _MockClearanceNotifier([mockClearance])),
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier()),
            partnersProvider.overrideWith((ref) => _MockPartnersNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomsClearanceScreen(initialSubTab: 1),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('سحب العينات وتتبع الفحص المعملي'), findsWidgets);
      expect(find.textContaining('سجل العينات المسحوبة للفحص والتحليل المعملي'), findsOneWidget);
      expect(find.text('تسجيل سحب عينة'), findsOneWidget);
    });

    testWidgets('Renders Tab 2 (Discrepancy & Damage) correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customsClearanceProvider.overrideWith((ref) => _MockClearanceNotifier([mockClearance])),
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier()),
            partnersProvider.overrideWith((ref) => _MockPartnersNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomsClearanceScreen(initialSubTab: 2),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('سجل إثبات الفاقد والتلف الجمركي'), findsWidgets);
      expect(find.text('تحرير محضر مشترك'), findsOneWidget);
    });

    testWidgets('Renders Tab 3 (Final Customs Duty Payment & Release) correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customsClearanceProvider.overrideWith((ref) => _MockClearanceNotifier([mockClearance])),
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier()),
            partnersProvider.overrideWith((ref) => _MockPartnersNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomsClearanceScreen(initialSubTab: 3),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('سداد الرسوم والضرائب الجمركية وإذن الإفراج النهائي'), findsWidgets);
      expect(find.textContaining('سجل أذون سداد نافذة المعتمدة ومطابقة الرسوم'), findsOneWidget);
    });
  });
}
