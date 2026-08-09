import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/warehouse_receiving/models/warehouse_receiving_model.dart';

void main() {
  group('WarehouseReceivingModel Unit Tests (Phase 8)', () {
    test('Should parse WarehouseReceivingModel from JSON correctly', () {
      final json = {
        'receiving_id': 201,
        'grn_code': 'GRN-2026-0001',
        'import_file_id': 10,
        'warehouse_name': 'Cairo Central Warehouse',
        'arrival_datetime': '2026-08-09T14:30:00Z',
        'truck_plate_number': 'TRK-100',
        'driver_name': 'Mahmoud Ali',
        'driver_phone': '01001122334',
        'seal_number': 'SEAL-998877',
        'seal_intact': true,
        'grn_items': [
          {
            'item_code': 'ITM-01',
            'item_name': 'Steel Valves',
            'invoiced_qty': 100,
            'accepted_qty': 98,
            'shortage_qty': 2,
            'damaged_qty': 0,
            'quarantine_flag': false,
          }
        ],
        'total_invoiced_qty': 100,
        'total_accepted_qty': 98,
        'total_shortage_qty': 2,
        'total_damaged_qty': 0,
        'discrepancy_type': 'Shortage',
        'discrepancy_notes': '2 valves missing upon opening container.',
        'quarantine_zone_assigned': false,
        'insurance_claim_filed': true,
        'insurance_claim_ref': 'INS-CLAIM-7766',
        'status': 'Goods Received',
        'inspector_name': 'Kamal',
        'is_active': true,
        'created_at': '2026-08-09T14:30:00Z',
        'updated_at': '2026-08-09T14:30:00Z',
      };

      final model = WarehouseReceivingModel.fromJson(json);

      expect(model.receivingId, 201);
      expect(model.grnCode, 'GRN-2026-0001');
      expect(model.warehouseName, 'Cairo Central Warehouse');
      expect(model.sealIntact, true);
      expect(model.grnItems.length, 1);
      expect(model.totalShortageQty, 2);
      expect(model.discrepancyType, 'Shortage');
      expect(model.insuranceClaimFiled, true);
    });

    test('Should serialize WarehouseReceivingModel to JSON correctly', () {
      final item = GrnItemModel(
        itemCode: 'ITM-02',
        itemName: 'Copper Tubes',
        invoicedQty: 50,
        acceptedQty: 40,
        shortageQty: 0,
        damagedQty: 10,
        quarantineFlag: true,
      );

      final model = WarehouseReceivingModel(
        receivingId: 202,
        grnCode: 'GRN-2026-0002',
        importFileId: 14,
        warehouseName: 'Alexandria Logistics Hub',
        arrivalDatetime: '2026-08-09T15:00:00Z',
        sealIntact: false,
        sealNumber: 'SEAL-BROKEN-99',
        grnItems: [item],
        totalInvoicedQty: 50,
        totalAcceptedQty: 40,
        totalDamagedQty: 10,
        discrepancyType: 'Damage',
        quarantineZoneAssigned: true,
        createdAt: '2026-08-09T15:00:00Z',
        updatedAt: '2026-08-09T15:00:00Z',
      );

      final json = model.toJson();

      expect(json['grn_code'], 'GRN-2026-0002');
      expect(json['seal_intact'], false);
      expect(json['discrepancy_type'], 'Damage');
      expect(json['quarantine_zone_assigned'], true);
      expect((json['grn_items'] as List).length, 1);
    });
  });
}
