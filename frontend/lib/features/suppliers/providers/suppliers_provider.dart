import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../audit_logs/providers/audit_logs_provider.dart';
import '../models/supplier_model.dart';

final showInactiveSuppliersProvider = StateProvider<bool>((ref) => true);

final suppliersProvider = StateNotifierProvider<SuppliersNotifier, AsyncValue<List<SupplierModel>>>((ref) {
  final showInactive = ref.watch(showInactiveSuppliersProvider);
  return SuppliersNotifier(ref: ref, showInactive: showInactive);
});

class SuppliersNotifier extends StateNotifier<AsyncValue<List<SupplierModel>>> {
  final Ref? ref;
  final Dio _dio = Dio();
  final bool showInactive;

  SuppliersNotifier({this.ref, required this.showInactive}) : super(const AsyncValue.loading()) {
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/suppliers',
        queryParameters: {'include_inactive': showInactive},
      );
      final List data = response.data;
      final list = data.map((json) => SupplierModel.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createSupplier(SupplierModel supplier) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/suppliers',
        data: supplier.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      await fetchSuppliers();
      return null; // Success
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString();
      }
      return 'Failed to create supplier. Please check inputs.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> updateSupplier(int supplierId, SupplierModel supplier) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/suppliers/$supplierId',
        data: supplier.toJson(),
      );
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(entityAuditTimelineProvider((entityType: 'Supplier', entityId: supplierId)));
      await fetchSuppliers();
      return null; // Success
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString();
      }
      return 'Failed to update supplier. Please check inputs.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<bool> toggleActiveStatus(int supplierId, bool currentlyActive) async {
    try {
      if (currentlyActive) {
        await _dio.delete('${ApiConstants.baseUrl}/suppliers/$supplierId');
      } else {
        await _dio.patch('${ApiConstants.baseUrl}/suppliers/$supplierId/restore');
      }
      ref?.invalidate(systemAuditLogsProvider);
      ref?.invalidate(entityAuditTimelineProvider((entityType: 'Supplier', entityId: supplierId)));
      await fetchSuppliers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
