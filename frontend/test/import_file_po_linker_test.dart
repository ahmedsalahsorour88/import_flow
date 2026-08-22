import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/import_file_po_linker.dart';
import 'package:frontend/core/utils/container_requirement_engine.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';

void main() {
  group('ImportFilePoLinker Unit Tests', () {
    final sampleFile = ImportFileModel(
      importFileId: 1,
      importFileCode: 'IMP-2026-0001',
      customFileNumber: '6701068100',
      companyId: 10,
      companyName: 'ECO ASSOCIATES for Trading and Contracting',
      supplierId: 20,
      supplierName: 'G.I. Industrial Holding S.p.A.',
      poNumber: 'PO-2026-001',
      poIds: [101],
      piNumber: 'PI-889',
      currentModule: 'Phase 1',
      currentStage: 'Phase 1',
      nextAction: 'Review',
      createdAt: '2026-08-22T00:00:00Z',
      updatedAt: '2026-08-22T00:00:00Z',
    );

    final po1 = PurchaseOrderModel(
      poId: 101,
      poNumber: 'PO-2026-001',
      proformaInvoiceNumber: 'PI-889',
      importFileId: 1,
      importFileCode: 'IMP-2026-0001',
      companyId: 10,
      supplierId: 20,
      projectId: 5,
      incotermId: 1,
      currencyId: 1,
      totalCbm: 40.017,
      totalGrossWeightKg: 2274.0,
      items: [
        POLineItemModel(
          itemId: 1,
          poId: 101,
          descriptionAr: 'RTAXTK/EC/MS 182 IM/RFM/RFL/PF/NS',
          quantity: 2.0,
          unitPrice: 18602.38,
          totalPrice: 37204.75,
          totalCbm: 39.994,
          grossWeightKg: 2254.0,
        ),
      ],
    );

    final po2 = PurchaseOrderModel(
      poId: 102,
      poNumber: 'PO-2026-002',
      importFileId: null,
      companyId: 99,
      supplierId: 99,
      projectId: 1,
      incotermId: 1,
      currencyId: 1,
    );

    test('getLinkedPOs should correctly identify linked POs using PO numbers, IDs, and codes', () {
      final linked = ImportFilePoLinker.getLinkedPOs(
        file: sampleFile,
        allPOs: [po1, po2],
      );

      expect(linked.length, equals(1));
      expect(linked.first.poId, equals(101));
      expect(linked.first.poNumber, equals('PO-2026-001'));
    });

    test('computeMetrics should aggregate CBM, weight, and invoice numbers from PO line items', () {
      final metrics = ImportFilePoLinker.computeMetrics(
        file: sampleFile,
        linkedPOs: [po1],
      );

      expect(metrics.cbm, equals(39.994));
      expect(metrics.weightKg, equals(2254.0));
      expect(metrics.invoices.contains('PI-889'), isTrue);
      expect(metrics.invoices.contains('PO-2026-001'), isTrue);
    });

    test('buildCargoItems should create 3D cargo items for 40 CBM shipments resulting in 40HC container recommendation', () {
      final items = ImportFilePoLinker.buildCargoItems(
        pos: [po1],
        file: sampleFile,
        fallbackCbm: 40.017,
        fallbackWeight: 2274.0,
      );

      expect(items.isNotEmpty, isTrue);

      final plan = ContainerRequirementEngine.planShipment(items);
      expect(plan.isNotEmpty, isTrue);
      expect(plan.first.containerCode.startsWith('40'), isTrue);
      final util = (plan.first.totalVolume / plan.first.spec.internalVolumeCbm) * 100;
      expect(util, greaterThan(45.0));
    });
  });
}
