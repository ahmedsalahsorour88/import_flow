import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/warehouse_receiving/models/warehouse_receiving_model.dart';
import 'package:frontend/features/financial_settlement/models/financial_settlement_model.dart';
import 'package:frontend/features/file_closure/models/file_closure_model.dart';

void main() {
  group('Phase 8, 9, 10 Models Unit Tests', () {
    test('WarehouseReceivingModel JSON serialization and parsing', () {
      final json = {
        'receiving_id': 1,
        'grn_code': 'GRN-2026-0001',
        'import_file_id': 10,
        'warehouse_name': 'Al-Obour Central Warehouse',
        'arrival_datetime': '2026-08-23T10:00:00Z',
        'truck_plate_number': 'TRK-1234',
        'driver_name': 'Hassan Ali',
        'seal_number': 'SEAL-8899',
        'seal_intact': true,
        'grn_items': [
          {
            'item_code': 'ITM-01',
            'item_name': 'Office Desk',
            'invoiced_qty': 100,
            'accepted_qty': 98,
            'shortage_qty': 1,
            'damaged_qty': 1,
            'quarantine_flag': true,
          }
        ],
        'total_invoiced_qty': 100,
        'total_accepted_qty': 98,
        'total_shortage_qty': 1,
        'total_damaged_qty': 1,
        'discrepancy_type': 'Damage & Shortage',
        'status': 'Goods Received',
        'inspector_name': 'Kamal',
        'created_at': '2026-08-23T10:00:00Z',
        'updated_at': '2026-08-23T10:00:00Z',
      };

      final model = WarehouseReceivingModel.fromJson(json);
      expect(model.grnCode, 'GRN-2026-0001');
      expect(model.sealIntact, true);
      expect(model.grnItems.length, 1);
      expect(model.grnItems.first.acceptedQty, 98);
      expect(model.grnItems.first.damagedQty, 1);
    });

    test('FinancialSettlementModel JSON serialization and parsing', () {
      final json = {
        'settlement_id': 5,
        'settlement_code': 'LCS-2026-0005',
        'import_file_id': 10,
        'total_fob_egp': 100000.0,
        'total_expenses_egp': 45000.0,
        'total_landed_cost_egp': 145000.0,
        'average_markup_factor': 1.45,
        'status': 'Calculated',
        'accountant_name': 'Kamal',
        'item_landed_costs': [
          {
            'item_code': 'ITM-01',
            'item_name': 'Office Desk',
            'qty': 100,
            'fob_unit_egp': 1000.0,
            'fob_total_egp': 100000.0,
            'allocated_freight_egp': 20000.0,
            'allocated_customs_egp': 15000.0,
            'allocated_clearance_egp': 5000.0,
            'allocated_transport_egp': 5000.0,
            'allocated_other_egp': 0.0,
            'total_landed_cost_egp': 145000.0,
            'unit_landed_cost_egp': 1450.0,
            'markup_factor': 1.45,
          }
        ],
        'created_at': '2026-08-23T10:00:00Z',
        'updated_at': '2026-08-23T10:00:00Z',
      };

      final model = LandedCostSettlementModel.fromJson(json);
      expect(model.settlementCode, 'LCS-2026-0005');
      expect(model.totalLandedCostEgp, 145000.0);
      expect(model.averageMarkupFactor, 1.45);
      expect(model.itemLandedCosts.length, 1);
      expect(model.itemLandedCosts.first.unitLandedCostEgp, 1450.0);
    });

    test('ImportFileClosureModel JSON serialization and parsing', () {
      final json = {
        'closure_id': 2,
        'closure_code': 'CLR-2026-0002',
        'import_file_id': 10,
        'closure_checklist': {
          'docs_verified': true,
          'customs_cleared': true,
          'warehouse_received': true,
          'landed_cost_settled': true,
          'tasks_closed': true,
        },
        'auditor_name': 'Chief Auditor Kamal',
        'archive_location': 'Digital Vault 2026',
        'status': 'Closed',
        'closed_at': '2026-08-23T10:00:00Z',
        'created_at': '2026-08-23T10:00:00Z',
        'updated_at': '2026-08-23T10:00:00Z',
      };

      final model = ImportFileClosureModel.fromJson(json);
      expect(model.closureCode, 'CLR-2026-0002');
      expect(model.status, 'Closed');
      expect(model.closureChecklist.docsVerified, true);
      expect(model.closureChecklist.landedCostSettled, true);
    });
  });
}
