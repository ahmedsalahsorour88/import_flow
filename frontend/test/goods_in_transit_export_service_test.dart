import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/warehouse_receiving/models/goods_in_transit_model.dart';
import 'package:frontend/features/warehouse_receiving/services/goods_in_transit_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockItems = [
    GitLineItemModel(
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      poId: 101,
      poNumber: 'PO-2026-IT-001',
      itemCode: 'ITM-SR-101',
      itemName: 'Enterprise Servers Rack Unit',
      invoicedQty: 250.0,
      packagesCount: 125,
      packageType: 'CT - Carton',
      containersCount: 2,
      containerType: '40ft High Cube',
      certifiedDate: '2026-08-20',
      isDeliveredToWarehouse: false,
    ),
    GitLineItemModel(
      importFileId: 2,
      importFileCode: 'IMP-2026-002',
      poId: 102,
      poNumber: 'PO-2026-MED-002',
      itemCode: 'ITM-SR-202',
      itemName: 'Ultrasound Probe Sensors',
      invoicedQty: 50.0,
      packagesCount: 25,
      packageType: 'PL - Pallet',
      containersCount: 1,
      containerType: '20ft Standard',
      certifiedDate: '2026-08-22',
      isDeliveredToWarehouse: true,
    ),
  ];

  Widget buildTestWidget({Locale locale = const Locale('ar')}) {
    return MaterialApp(
      home: AppLocalizationsProvider(
        locale: locale,
        child: const Scaffold(body: SizedBox()),
      ),
    );
  }

  group('GoodsInTransitExportService Tests', () {
    testWidgets('exportGitToTsv produces valid TSV with UTF-8 BOM and correct headers', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ar')));
      final contextAr = tester.element(find.byType(SizedBox));
      final tsvAr = GoodsInTransitExportService.exportGitToTsv(contextAr, mockItems);

      expect(tsvAr.startsWith('\uFEFF'), true, reason: 'TSV must begin with UTF-8 BOM');
      expect(tsvAr.contains('IMP-2026-001'), true);
      expect(tsvAr.contains('PO-2026-IT-001'), true);
      expect(tsvAr.contains('ITM-SR-101'), true);
      expect(tsvAr.contains('250'), true);
      expect(tsvAr.contains('في الطريق'), true);
      expect(tsvAr.contains('تم الاستلام بالمخزن'), true);

      // Verify English locale
      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      final contextEn = tester.element(find.byType(SizedBox));
      final tsvEn = GoodsInTransitExportService.exportGitToTsv(contextEn, mockItems);

      expect(tsvEn.startsWith('\uFEFF'), true);
      expect(tsvEn.contains('Import File Code'), true);
      expect(tsvEn.contains('PO Number'), true);
      expect(tsvEn.contains('In Transit (GIT)'), true);
      expect(tsvEn.contains('Delivered to Warehouse'), true);
    });

    testWidgets('exportGitToCsv produces valid CSV with UTF-8 BOM and quoted fields', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ar')));
      final contextAr = tester.element(find.byType(SizedBox));
      final csvAr = GoodsInTransitExportService.exportGitToCsv(contextAr, mockItems);

      expect(csvAr.startsWith('\uFEFF'), true, reason: 'CSV must begin with UTF-8 BOM');
      expect(csvAr.contains('IMP-2026-001'), true);
      expect(csvAr.contains('PO-2026-IT-001'), true);
      expect(csvAr.contains('Enterprise Servers Rack Unit'), true);
      expect(csvAr.contains('40ft High Cube'), true);
    });

    testWidgets('buildGitDossier produces formatted text dossier with KPI breakdown', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ar')));
      final contextAr = tester.element(find.byType(SizedBox));
      final dossierAr = GoodsInTransitExportService.buildGitDossier(
        context: contextAr,
        items: mockItems,
      );

      expect(dossierAr.contains('ملف رصيد البضاعة في الطريق ومطابقة الشحنات'), true);
      expect(dossierAr.contains('ملخص مؤشرات الرصيد والحركة'), true);
      expect(dossierAr.contains('IMP-2026-001'), true);
      expect(dossierAr.contains('PO-2026-IT-001'), true);
      expect(dossierAr.contains('نهاية ملف رصيد البضاعة في الطريق'), true);

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      final contextEn = tester.element(find.byType(SizedBox));
      final dossierEn = GoodsInTransitExportService.buildGitDossier(
        context: contextEn,
        items: mockItems,
      );

      expect(dossierEn.contains('Goods In Transit Ledger & Matching Dossier'), true);
      expect(dossierEn.contains('Ledger KPI Summary'), true);
      expect(dossierEn.contains('End of Goods In Transit Dossier'), true);
    });

    testWidgets('Empty ledger export generates proper headers without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ar')));
      final context = tester.element(find.byType(SizedBox));

      final tsv = GoodsInTransitExportService.exportGitToTsv(context, []);
      final csv = GoodsInTransitExportService.exportGitToCsv(context, []);
      final dossier = GoodsInTransitExportService.buildGitDossier(
        context: context,
        items: [],
      );

      expect(tsv.startsWith('\uFEFF'), true);
      expect(csv.startsWith('\uFEFF'), true);
      expect(dossier.contains('لا توجد بضائع في الطريق مطابقة لمعايير البحث حالياً.'), true);
    });
  });
}
