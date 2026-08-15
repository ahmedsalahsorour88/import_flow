double _safeDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

class PreferentialAgreementModel {
  final int agreementId;
  final String hsCode;
  final String agreementName;
  final String reductionType;
  final double reductionPercentage;
  final double? preferentialDutyRate;
  final String? publicationNotice;
  final String originCountries;
  final String? conditionsNote;
  final String? requiredDocument;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? sourceUrl;

  const PreferentialAgreementModel({
    required this.agreementId,
    required this.hsCode,
    required this.agreementName,
    required this.reductionType,
    required this.reductionPercentage,
    this.preferentialDutyRate,
    this.publicationNotice,
    required this.originCountries,
    this.conditionsNote,
    this.requiredDocument,
    required this.effectiveFrom,
    this.effectiveTo,
    this.sourceUrl,
  });

  factory PreferentialAgreementModel.fromJson(Map<String, dynamic> json) {
    return PreferentialAgreementModel(
      agreementId: _safeInt(json['agreement_id']),
      hsCode: json['hs_code']?.toString() ?? '',
      agreementName: json['agreement_name']?.toString() ?? '',
      reductionType: json['reduction_type']?.toString() ?? 'percentage_of_duty',
      reductionPercentage: _safeDouble(json['reduction_percentage'], 1.0),
      preferentialDutyRate: json['preferential_duty_rate'] != null
          ? _safeDouble(json['preferential_duty_rate'])
          : null,
      publicationNotice: json['publication_notice']?.toString(),
      originCountries: json['origin_countries']?.toString() ?? '',
      conditionsNote: json['conditions_note']?.toString(),
      requiredDocument: json['required_document']?.toString(),
      effectiveFrom: json['effective_from'] != null
          ? DateTime.tryParse(json['effective_from'].toString()) ?? DateTime.now()
          : DateTime.now(),
      effectiveTo: json['effective_to'] != null
          ? DateTime.tryParse(json['effective_to'].toString())
          : null,
      sourceUrl: json['source_url']?.toString(),
    );
  }
}
