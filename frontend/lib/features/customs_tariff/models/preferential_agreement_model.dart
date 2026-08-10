class PreferentialAgreementModel {
  final int agreementId;
  final String hsCode;
  final String agreementName;
  final String reductionType;
  final double reductionPercentage;
  final String originCountries;
  final String? conditionsNote;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? sourceUrl;

  const PreferentialAgreementModel({
    required this.agreementId,
    required this.hsCode,
    required this.agreementName,
    required this.reductionType,
    required this.reductionPercentage,
    required this.originCountries,
    this.conditionsNote,
    required this.effectiveFrom,
    this.effectiveTo,
    this.sourceUrl,
  });

  factory PreferentialAgreementModel.fromJson(Map<String, dynamic> json) {
    return PreferentialAgreementModel(
      agreementId: json['agreement_id'] as int? ?? 0,
      hsCode: json['hs_code']?.toString() ?? '',
      agreementName: json['agreement_name']?.toString() ?? '',
      reductionType: json['reduction_type']?.toString() ?? 'percentage_of_duty',
      reductionPercentage: (json['reduction_percentage'] as num?)?.toDouble() ?? 1.0,
      originCountries: json['origin_countries']?.toString() ?? '',
      conditionsNote: json['conditions_note']?.toString(),
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
