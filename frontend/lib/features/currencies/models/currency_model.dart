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
      rateId: json['rate_id'] as int?,
      currencyId: json['currency_id'] as int? ?? 0,
      commercialRate: (json['commercial_rate'] as num?)?.toDouble() ?? 1.0,
      customsRate: (json['customs_rate'] as num?)?.toDouble() ?? 1.0,
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
      currencyId: json['currency_id'] as int?,
      currencyCode: json['currency_code'] as String? ?? '',
      currencyName: json['currency_name'] as String? ?? '',
      currencySymbol: json['currency_symbol'] as String? ?? '',
      isBaseCurrency: json['is_base_currency'] as bool? ?? false,
      decimalPlaces: json['decimal_places'] as int? ?? 2,
      isActive: json['is_active'] as bool? ?? true,
      latestCommercialRate: (json['latest_commercial_rate'] as num?)?.toDouble(),
      latestCustomsRate: (json['latest_customs_rate'] as num?)?.toDouble(),
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
