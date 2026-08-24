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
    // Clean initial state with zero demo/mock records
    state = const AsyncValue.data([]);
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
