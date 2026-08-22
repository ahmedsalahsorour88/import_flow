import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/production_sync_model.dart';
import '../services/production_sync_service.dart';

final productionSyncServiceProvider = Provider<ProductionSyncService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProductionSyncService(dio);
});

final syncComparisonProvider = FutureProvider.autoDispose<SyncComparisonResponseModel>((ref) async {
  final service = ref.watch(productionSyncServiceProvider);
  return await service.getComparison();
});

final backupsListProvider = FutureProvider.autoDispose<List<BackupItemModel>>((ref) async {
  final service = ref.watch(productionSyncServiceProvider);
  return await service.listBackups();
});

class ProductionSyncNotifier extends StateNotifier<AsyncValue<SyncActionResponseModel?>> {
  final ProductionSyncService _service;
  final Ref _ref;

  ProductionSyncNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<SyncActionResponseModel?> syncDevToProd() async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.syncDevToProd();
      state = AsyncValue.data(result);
      _ref.invalidate(syncComparisonProvider);
      _ref.invalidate(backupsListProvider);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<SyncActionResponseModel?> pullProdToDev() async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.pullProdToDev();
      state = AsyncValue.data(result);
      _ref.invalidate(syncComparisonProvider);
      _ref.invalidate(backupsListProvider);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<BackupItemModel> createManualBackup({String target = 'dev'}) async {
    state = const AsyncValue.loading();
    try {
      final backup = await _service.createManualBackup(target: target);
      state = const AsyncValue.data(null);
      _ref.invalidate(backupsListProvider);
      return backup;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final productionSyncNotifierProvider =
    StateNotifierProvider<ProductionSyncNotifier, AsyncValue<SyncActionResponseModel?>>((ref) {
  final service = ref.watch(productionSyncServiceProvider);
  return ProductionSyncNotifier(service, ref);
});
