import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/currency_model.dart';

final currenciesProvider =
    StateNotifierProvider<CurrenciesNotifier, AsyncValue<List<CurrencyModel>>>((ref) {
  return CurrenciesNotifier();
});

class CurrenciesNotifier extends StateNotifier<AsyncValue<List<CurrencyModel>>> {
  final Dio _dio = Dio();

  CurrenciesNotifier() : super(const AsyncValue.loading()) {
    fetchCurrencies();
  }

  Future<void> fetchCurrencies({bool includeInactive = true, String? search}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/currencies',
        queryParameters: queryParams,
      );
      final List data = response.data as List;
      final currencies = data.map((json) => CurrencyModel.fromJson(json)).toList();
      state = AsyncValue.data(currencies);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<bool> createCurrency(CurrencyModel model) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/currencies',
        data: model.toJson(),
      );
      await fetchCurrencies();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> updateCurrency(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/currencies/$id',
        data: data,
      );
      await fetchCurrencies();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> toggleActive(int id, bool currentStatus) async {
    try {
      if (currentStatus) {
        await _dio.delete('${ApiConstants.baseUrl}/currencies/$id');
      } else {
        await _dio.post('${ApiConstants.baseUrl}/currencies/$id/restore');
      }
      await fetchCurrencies();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> addExchangeRate(ExchangeRateModel rate) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/currencies/rates',
        data: rate.toJson(),
      );
      await fetchCurrencies();
      return true;
    } catch (err) {
      return false;
    }
  }
}
