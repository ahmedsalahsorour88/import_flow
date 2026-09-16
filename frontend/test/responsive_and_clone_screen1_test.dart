import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_files/screens/import_files_screen.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  final sampleItems = [
    ImportFileModel(
      importFileId: 4,
      importFileCode: 'IMP-2026-0004',
      customFileNumber: 'PET Stock',
      companyName: 'SCAS FOR CONSTRUCTION',
      supplierName: 'SUZHOU YUHENG TEXTILE',
      priority: 'High',
      shipmentCategory: 'Raw Materials',
      currentModule: 'STEP_07 تخصيص وتوزيع الحاويات والـ VGM',
      currentStage: 'Phase 3: Booking & Doc Prep',
      nextAction: 'تدقيق أوزان VGM واعتماد مسودات مستندات الشحن',
      progressPercent: 33.3,
      status: 'Open',
      owner: 'Ahmed Salah',
      createdAt: '2026-08-18T10:00:00Z',
      updatedAt: '2026-09-14T10:00:00Z',
      estimatedCost: 43704.0,
      estimatedCostCurrency: 'USD',
    ),
  ];

  Widget buildTestWidget({required Size surfaceSize, Locale locale = const Locale('ar')}) {
    return ProviderScope(
      overrides: [
        paginatedImportFilesProvider.overrideWith(
          (ref) => _MockPaginatedNotifier(
            PaginatedImportFilesState(
              items: sampleItems,
              total: 1,
              page: 1,
              pageSize: 50,
              totalPages: 1,
              isLoading: false,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        home: AppLocalizationsProvider(
          locale: locale,
          child: MediaQuery(
            data: MediaQueryData(size: surfaceSize),
            child: SizedBox(
              width: surfaceSize.width,
              height: surfaceSize.height,
              child: const ImportFilesScreen(),
            ),
          ),
        ),
      ),
    );
  }

  group('Screen 1 (ImportFilesScreen) Empirical Proof & Breakpoint Tests', () {
    testWidgets('Desktop (1440px): DataTable renders with persistent horizontal Scrollbar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(buildTestWidget(surfaceSize: const Size(1440, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsWidgets);
      expect(find.byType(Scrollbar), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tablet (1024px): DataTable renders without overflow and scrollbar active', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(buildTestWidget(surfaceSize: const Size(1024, 768)));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsWidgets);
      expect(find.byType(Scrollbar), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mobile (375px): Fallback to stacked cards with 0 RenderFlex overflows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(buildTestWidget(surfaceSize: const Size(375, 812)));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsNothing);
      expect(find.textContaining('PET Stock'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockPaginatedNotifier extends StateNotifier<PaginatedImportFilesState>
    implements PaginatedImportFilesNotifier {
  _MockPaginatedNotifier(super.state);

  @override
  Future<void> fetchPage(int page, {String? search, String? status, int? companyId, int? supplierId, int? brokerId, String? currentStage, String? priority, String? owner}) async {}

  void setPage(int page) {}

  void setPageSize(int pageSize) {}

  @override
  void nextPage() {}

  @override
  void prevPage() {}
}
