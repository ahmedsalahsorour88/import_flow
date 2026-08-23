import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goods_in_transit_model.dart';

final gitSearchQueryProvider = StateProvider<String>((ref) => '');
final gitSelectedFileFilterProvider = StateProvider<String>((ref) => 'All');

final goodsInTransitProvider =
    StateNotifierProvider<GoodsInTransitNotifier, AsyncValue<List<GitLineItemModel>>>((ref) {
  return GoodsInTransitNotifier();
});

class GoodsInTransitNotifier extends StateNotifier<AsyncValue<List<GitLineItemModel>>> {
  GoodsInTransitNotifier() : super(const AsyncValue.loading()) {
    initLedger();
  }

  void initLedger() {
    // Initial rich state for goods in transit derived from approved POs & packing lists
    final initialList = [
      GitLineItemModel(
        importFileId: 1,
        importFileCode: 'IMP-2026-001',
        poId: 101,
        poNumber: 'PO-2026-IT-001',
        itemCode: 'ITM-SR-101',
        itemName: 'خوادم رقمية صناعية (Enterprise Servers)',
        invoicedQty: 250.0,
        packagesCount: 125,
        packageType: 'CT - Carton',
        containersCount: 2,
        containerType: '40ft High Cube',
        certifiedDate: '2026-08-20',
        isDeliveredToWarehouse: false,
      ),
      GitLineItemModel(
        importFileId: 1,
        importFileCode: 'IMP-2026-001',
        poId: 101,
        poNumber: 'PO-2026-IT-001',
        itemCode: 'ITM-SR-102',
        itemName: 'محولات شبكية ذكية (Smart Network Switches)',
        invoicedQty: 500.0,
        packagesCount: 100,
        packageType: 'BX - Box',
        containersCount: 2,
        containerType: '40ft High Cube',
        certifiedDate: '2026-08-20',
        isDeliveredToWarehouse: false,
      ),
      GitLineItemModel(
        importFileId: 2,
        importFileCode: 'IMP-2026-002',
        poId: 102,
        poNumber: 'PO-2026-DE-004',
        itemCode: 'ITM-MD-201',
        itemName: 'أجهزة قياس وضبط الجودة الهيدروليكية',
        invoicedQty: 180.0,
        packagesCount: 90,
        packageType: 'CR - Crate',
        containersCount: 1,
        containerType: '20ft Standard',
        certifiedDate: '2026-08-21',
        isDeliveredToWarehouse: false,
      ),
      GitLineItemModel(
        importFileId: 3,
        importFileCode: 'IMP-2026-003',
        poId: 103,
        poNumber: 'PO-2026-CN-009',
        itemCode: 'ITM-EL-301',
        itemName: 'لوحات دوائر كهربائية مطبوعة (PCBs)',
        invoicedQty: 1200.0,
        packagesCount: 240,
        packageType: 'PK - Package',
        containersCount: 2,
        containerType: '40ft High Cube',
        certifiedDate: '2026-08-22',
        isDeliveredToWarehouse: false,
      ),
    ];
    state = AsyncValue.data(initialList);
  }

  void addReconciledShipment({
    required int importFileId,
    required String importFileCode,
    required List<GitLineItemModel> items,
  }) {
    final current = state.value ?? [];
    final updated = List<GitLineItemModel>.from(current);
    // Remove old entries for this file if any, then insert new items
    updated.removeWhere((i) => i.importFileId == importFileId);
    updated.addAll(items);
    state = AsyncValue.data(updated);
  }

  void confirmWarehouseReceipt(int importFileId) {
    final current = state.value ?? [];
    final updated = current.map((item) {
      if (item.importFileId == importFileId) {
        return item.copyWith(isDeliveredToWarehouse: true);
      }
      return item;
    }).toList();
    state = AsyncValue.data(updated);
  }
}
