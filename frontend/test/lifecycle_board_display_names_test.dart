import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/services/display_name_resolver.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/lifecycle_board/models/lifecycle_board_model.dart';
import 'package:frontend/features/lifecycle_board/services/lifecycle_board_export_service.dart';

Widget _buildTestWidget({Locale locale = const Locale('ar'), required Widget child}) {
  return MaterialApp(
    locale: locale,
    home: Directionality(
      textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: AppLocalizationsProvider(
        locale: locale,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task D — Lifecycle Board (Screen 48) Human-Readable Names & Exports', () {
    late List<ImportFileModel> sampleImportFiles;
    late List<ShipmentStageCardModel> sampleShipments;
    late List<PhaseSummaryModel> samplePhases;
    late List<LiveLogisticsTrackingItemModel> sampleRadarItems;

    setUp(() {
      sampleImportFiles = [
        ImportFileModel(
          importFileId: 101,
          importFileCode: 'IMP-2026-0001',
          customFileNumber: 'شحنة حبيبات البلاستيك PET',
          companyName: 'شركة النيل للصناعات البلاستيكية',
          supplierName: 'Sino Chemical Corp',
          brokerName: 'مكتب الأمل للتخليص الجمركي',
          priority: 'High',
          shipmentCategory: 'Raw Materials',
          currentModule: 'Phase 2: Approvals & ACID',
          currentStage: 'STEP_04',
          nextAction: 'STEP_05',
          status: 'Under Process',
          owner: 'Ahmed Kamal',
          createdAt: '2026-09-01T10:00:00Z',
          updatedAt: '2026-09-02T10:00:00Z',
        ),
        ImportFileModel(
          importFileId: 102,
          importFileCode: 'IMP-2026-0002',
          customFileNumber: '',
          companyName: 'الأهرام للهندسة والإنشاءات',
          supplierName: 'Bavaria Heavy Tools',
          brokerName: 'شركة الفراعنة للتخليص',
          priority: 'Critical',
          shipmentCategory: 'Heavy Equipment',
          currentModule: 'Phase 5: Clearance & Release',
          currentStage: 'STEP_13',
          nextAction: 'STEP_14',
          status: 'Under Process',
          owner: 'Sara Hassan',
          createdAt: '2026-09-05T10:00:00Z',
          updatedAt: '2026-09-06T10:00:00Z',
        ),
      ];

      sampleShipments = [
        ShipmentStageCardModel(
          importFileCode: 'IMP-2026-0001',
          companyName: 'شركة النيل للصناعات البلاستيكية',
          supplierName: 'Sino Chemical Corp',
          stepCode: 'STEP_04',
          stepNameEn: 'Budget Approval',
          stepNameAr: 'اعتماد الميزانية وصرف الدفعة',
          previousStepCode: 'STEP_03',
          previousStepNameEn: 'Import Requirements',
          previousStepNameAr: 'اشتراطات ومتطلبات الاستيراد',
          nextStepCode: 'STEP_05',
          nextStepNameEn: 'Nafeza ACID Issue',
          nextStepNameAr: 'إصدار رقم التسجيل المسبق نافذة',
          shipmentMode: 'FCL / Sea',
          incotermCode: 'CIF',
          priority: 'High',
          estimatedCost: 150000.0,
          estimatedCostCurrency: 'EGP',
          status: 'In-Progress',
        ),
        ShipmentStageCardModel(
          importFileCode: 'IMP-2026-0002',
          companyName: 'الأهرام للهندسة والإنشاءات',
          supplierName: 'Bavaria Heavy Tools',
          stepCode: 'STEP_13',
          stepNameEn: 'Form 46 KM',
          stepNameAr: 'قيد إقرار 46 ك.م جمركي',
          previousStepCode: 'STEP_12',
          previousStepNameEn: 'Bank Form 4',
          previousStepNameAr: 'استخراج نموذج 4 البنكي',
          nextStepCode: 'STEP_14',
          nextStepNameEn: 'Inspection & Valuation',
          nextStepNameAr: 'الكشف والمعاينة والتثمين',
          shipmentMode: 'Air Freight',
          incotermCode: 'DAP',
          priority: 'Critical',
          estimatedCost: 85000.0,
          estimatedCostCurrency: 'USD',
          status: 'On-Hold',
        ),
      ];

      samplePhases = [
        PhaseSummaryModel(
          phaseId: 2,
          titleAr: 'المرحلة الثانية: الاعتمادات ورقم التسجيل المسبق',
          titleEn: 'Phase 2: Approvals & ACID',
          colorHex: '#3498DB',
          totalActiveShipments: 1,
          stepCodes: ['STEP_04', 'STEP_05'],
          stepCounts: {'STEP_04': 1, 'STEP_05': 0},
        ),
        PhaseSummaryModel(
          phaseId: 5,
          titleAr: 'المرحلة الخامسة: التخليص الجمركي والإفراج',
          titleEn: 'Phase 5: Clearance & Release',
          colorHex: '#E67E22',
          totalActiveShipments: 1,
          stepCodes: ['STEP_13', 'STEP_14'],
          stepCounts: {'STEP_13': 1, 'STEP_14': 0},
        ),
      ];

      sampleRadarItems = [
        LiveLogisticsTrackingItemModel(
          importFileId: 101,
          importFileCode: 'IMP-2026-0001',
          companyName: 'شركة النيل للصناعات البلاستيكية',
          supplierName: 'Sino Chemical Corp',
          shipmentMode: 'FCL',
          incotermCode: 'CIF',
          priority: 'High',
          carrierName: 'MSC Line',
          vesselName: 'MSC Isabella',
          blNumber: 'MSCU12345678',
          polName: 'Shanghai',
          podName: 'Alexandria',
          eta: '2026-09-20',
          arrivalStatus: 'En Route',
          demurrageStatus: 'Normal',
          demurrageRiskLevel: 'Safe',
          freeDaysRemaining: 12,
          freeDaysTotal: 14,
          usedFreeDays: 2,
          accumulatedDemurrageFx: 0.0,
          accumulatedDemurrageEgp: 0.0,
          sampleTestStatus: 'Under Testing',
          docReadinessPercent: 85.0,
          verifiedDocumentsCount: 5,
          totalRequiredDocuments: 6,
          missingDocuments: const [],
          operationalHealthScore: '92.5%',
          currentStepCode: 'STEP_07',
          currentStepNameAr: 'تخصيص وتوزيع الحاويات والبضائع',
          currentStepNameEn: 'Container Allocation',
          nextAction: 'STEP_08',
        ),
      ];
    });

    test('DisplayNameResolver resolves all 21 steps cleanly in Arabic without Latin STEP_ prefix', () {
      for (int i = 1; i <= 21; i++) {
        final stepCode = 'STEP_${i.toString().padLeft(2, '0')}';
        final resolvedAr = DisplayNameResolver.resolveStepName(stepCode, isArabic: true);
        expect(resolvedAr, isNot(contains('STEP_')));
        expect(resolvedAr.trim().isNotEmpty, isTrue);
      }
    });

    test('DisplayNameResolver resolves commercial shipment names and secondary codes', () {
      final name1 = DisplayNameResolver.resolveShipmentName(sampleImportFiles[0], isArabic: true);
      expect(name1, equals('شحنة حبيبات البلاستيك PET'));

      final title1 = DisplayNameResolver.resolveShipmentTitle(sampleImportFiles[0], isArabic: true);
      expect(title1, equals('شحنة حبيبات البلاستيك PET (IMP-2026-0001)'));

      final name2 = DisplayNameResolver.resolveShipmentName(sampleImportFiles[1], isArabic: true);
      expect(name2, equals('IMP-2026-0002'));

      final titleByCode = DisplayNameResolver.resolveShipmentTitleByCode(
        'IMP-2026-0001',
        shipments: sampleImportFiles,
        isArabic: true,
      );
      expect(titleByCode, equals('شحنة حبيبات البلاستيك PET (IMP-2026-0001)'));
    });

    testWidgets('buildKanbanDossierText outputs commercial names and clean Arabic step titles', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              final dossier = LifecycleBoardExportService.buildKanbanDossierText(
                context: context,
                shipments: sampleShipments,
                phases: samplePhases,
                allImportFiles: sampleImportFiles,
              );

              expect(dossier, contains('شحنة حبيبات البلاستيك PET (IMP-2026-0001)'));
              expect(dossier, contains('اعتماد الميزانية وصرف الدفعة'));
              expect(dossier, contains('اشتراطات ومتطلبات الاستيراد'));
              expect(dossier, contains('إصدار رقم التسجيل المسبق نافذة'));
              expect(dossier, isNot(contains('STEP_04:')));
              expect(dossier, isNot(contains('STEP_03:')));

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('buildRadarDossierText outputs commercial shipment names', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              final dossier = LifecycleBoardExportService.buildRadarDossierText(
                context: context,
                items: sampleRadarItems,
                allImportFiles: sampleImportFiles,
              );

              expect(dossier, contains('شحنة حبيبات البلاستيك PET (IMP-2026-0001)'));
              expect(dossier, contains('MSC Line (MSC Isabella)'));

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
