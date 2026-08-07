import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/supplier_model.dart';

final showInactiveSuppliersProvider = StateProvider<bool>((ref) => true);

final suppliersProvider = StateNotifierProvider<SuppliersNotifier, AsyncValue<List<SupplierModel>>>((ref) {
  final showInactive = ref.watch(showInactiveSuppliersProvider);
  return SuppliersNotifier(showInactive: showInactive);
});

class SuppliersNotifier extends StateNotifier<AsyncValue<List<SupplierModel>>> {
  final Dio _dio = Dio();
  final bool showInactive;

  SuppliersNotifier({required this.showInactive}) : super(const AsyncValue.loading()) {
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/suppliers/',
        queryParameters: {'include_inactive': showInactive},
      );
      final List data = response.data;
      final list = data.map((json) => SupplierModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createSupplier(SupplierModel supplier) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/suppliers/',
        data: supplier.toJson(),
      );
      await fetchSuppliers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleActiveStatus(int supplierId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/suppliers/$supplierId');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/suppliers/$supplierId/restore');
      }
      await fetchSuppliers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
