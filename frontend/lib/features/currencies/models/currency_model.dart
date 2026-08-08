double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

double? _numToNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int _numToInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

class ExchangeRateModel {
  final int? rateId;
  final int currencyId;
  final double commercialRate;
  final double customsRate;
  final String effectiveDate;
  final bool isActive;
  final DateTime? createdAt;

  ExchangeRateModel({
    this.rateId,
    required this.currencyId,
    required this.commercialRate,
    required this.customsRate,
    required this.effectiveDate,
    this.isActive = true,
    this.createdAt,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      rateId: json['rate_id'] != null ? _numToInt(json['rate_id']) : null,
      currencyId: _numToInt(json['currency_id']),
      commercialRate: _numToDouble(json['commercial_rate'], 1.0),
      customsRate: _numToDouble(json['customs_rate'], 1.0),
      effectiveDate: json['effective_date'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_id': currencyId,
      'commercial_rate': commercialRate,
      'customs_rate': customsRate,
      'effective_date': effectiveDate,
    };
  }
}

class CurrencyModel {
  final int? currencyId;
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;
  final bool isBaseCurrency;
  final int decimalPlaces;
  final bool isActive;
  final double? latestCommercialRate;
  final double? latestCustomsRate;
  final List<ExchangeRateModel>? exchangeRates;

  CurrencyModel({
    this.currencyId,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    this.isBaseCurrency = false,
    this.decimalPlaces = 2,
    this.isActive = true,
    this.latestCommercialRate,
    this.latestCustomsRate,
    this.exchangeRates,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      currencyId: json['currency_id'] != null ? _numToInt(json['currency_id']) : null,
      currencyCode: json['currency_code'] as String? ?? '',
      currencyName: json['currency_name'] as String? ?? '',
      currencySymbol: json['currency_symbol'] as String? ?? '',
      isBaseCurrency: json['is_base_currency'] as bool? ?? false,
      decimalPlaces: _numToInt(json['decimal_places'], 2),
      isActive: json['is_active'] as bool? ?? true,
      latestCommercialRate: _numToNullableDouble(json['latest_commercial_rate']),
      latestCustomsRate: _numToNullableDouble(json['latest_customs_rate']),
      exchangeRates: json['exchange_rates'] != null
          ? (json['exchange_rates'] as List).map((r) => ExchangeRateModel.fromJson(r)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (currencyId != null) 'currency_id': currencyId,
      'currency_code': currencyCode,
      'currency_name': currencyName,
      'currency_symbol': currencySymbol,
      'is_base_currency': isBaseCurrency,
      'decimal_places': decimalPlaces,
      'is_active': isActive,
    };
  }
}
