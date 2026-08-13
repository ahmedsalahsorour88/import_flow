import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/import_documentation_model.dart';

final acidSessionsProvider =
    StateNotifierProvider<AcidSessionsNotifier, AsyncValue<List<AcidRegistrationModel>>>((ref) {
  return AcidSessionsNotifier();
});

class AcidSessionsNotifier extends StateNotifier<AsyncValue<List<AcidRegistrationModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  AcidSessionsNotifier() : super(const AsyncValue.loading()) {
    fetchAcidSessions();
  }

  Future<void> fetchAcidSessions({
    bool includeInactive = false,
    String? search,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty && status != 'All') queryParams['status'] = status;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/import-documentation/acid-sessions',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final sessions = data.map((json) => AcidRegistrationModel.fromJson(json)).toList();
      state = AsyncValue.data(sessions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<AcidRegistrationModel?> createAcidSession(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/acid-sessions',
        data: payload,
      );
      final created = AcidRegistrationModel.fromJson(response.data);
      await fetchAcidSessions();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteAcidSession(int acidId) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}/import-documentation/acid-sessions/$acidId');
      await fetchAcidSessions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreAcidSession(int acidId) async {
    try {
      await _dio.patch('${ApiConstants.baseUrl}/import-documentation/acid-sessions/$acidId/restore');
      await fetchAcidSessions();
    } catch (e) {
      rethrow;
    }
  }
}

final bankingDocumentsProvider =
    StateNotifierProvider<BankingDocumentsNotifier, AsyncValue<List<BankingDocumentModel>>>((ref) {
  return BankingDocumentsNotifier();
});

class BankingDocumentsNotifier extends StateNotifier<AsyncValue<List<BankingDocumentModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  BankingDocumentsNotifier() : super(const AsyncValue.loading()) {
    fetchBankingDocuments();
  }

  Future<void> fetchBankingDocuments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/import-documentation/banking-documents');
      final List<dynamic> data = response.data;
      final docs = data.map((json) => BankingDocumentModel.fromJson(json)).toList();
      state = AsyncValue.data(docs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<BankingDocumentModel?> createBankingDocument(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/banking-documents',
        data: payload,
      );
      final created = BankingDocumentModel.fromJson(response.data);
      await fetchBankingDocuments();
      return created;
    } catch (e) {
      rethrow;
    }
  }
}

final shipmentDocumentsProvider =
    StateNotifierProvider<ShipmentDocumentsNotifier, AsyncValue<List<ShipmentDocumentModel>>>((ref) {
  return ShipmentDocumentsNotifier();
});

class ShipmentDocumentsNotifier extends StateNotifier<AsyncValue<List<ShipmentDocumentModel>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ShipmentDocumentsNotifier() : super(const AsyncValue.loading()) {
    fetchShipmentDocuments();
  }

  Future<void> fetchShipmentDocuments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/import-documentation/shipment-documents');
      final List<dynamic> data = response.data;
      final docs = data.map((json) => ShipmentDocumentModel.fromJson(json)).toList();
      state = AsyncValue.data(docs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<ShipmentDocumentModel?> createShipmentDocument(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/shipment-documents',
        data: payload,
      );
      final created = ShipmentDocumentModel.fromJson(response.data);
      await fetchShipmentDocuments();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ShipmentDocumentModel?> updateCargoXAndBLEndorsement(int docId, {String? cargoxEnvId, String? endorsementNum}) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/import-documentation/shipment-documents/$docId/cargox-bl',
        queryParameters: {
          if (cargoxEnvId != null) 'cargox_envelope_id': cargoxEnvId,
          if (endorsementNum != null) 'endorsement_number': endorsementNum,
        },
      );
      final updated = ShipmentDocumentModel.fromJson(response.data);
      await fetchShipmentDocuments();
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}
