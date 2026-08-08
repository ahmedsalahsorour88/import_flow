class CustomsTariffModel {
  final int tariffId;
  final String hsCode;
  final String hsDescription;
  final String? customsCategory;

  final double customsDutyRate;
  final double vatRate;
  final double scheduleTaxRate;
  final double developmentFeeRate;
  final double importFeeRate;

  final bool requiresCoo;
  final bool requiresInspection;
  final bool requiresAcid;
  final String? regulatoryAuthority;

  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomsTariffModel({
    required this.tariffId,
    required this.hsCode,
    required this.hsDescription,
    this.customsCategory,
    required this.customsDutyRate,
    required this.vatRate,
    required this.scheduleTaxRate,
    required this.developmentFeeRate,
    required this.importFeeRate,
    required this.requiresCoo,
    required this.requiresInspection,
    required this.requiresAcid,
    this.regulatoryAuthority,
    required this.effectiveFrom,
    this.effectiveTo,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomsTariffModel.fromJson(Map<String, dynamic> json) {
    return CustomsTariffModel(
      tariffId: json['tariff_id'] as int,
      hsCode: json['hs_code'] as String,
      hsDescription: json['hs_description'] as String,
      customsCategory: json['customs_category'] as String?,
      customsDutyRate: (json['customs_duty_rate'] as num).toDouble(),
      vatRate: (json['vat_rate'] as num).toDouble(),
      scheduleTaxRate: (json['schedule_tax_rate'] as num).toDouble(),
      developmentFeeRate: (json['development_fee_rate'] as num).toDouble(),
      importFeeRate: (json['import_fee_rate'] as num).toDouble(),
      requiresCoo: json['requires_coo'] as bool,
      requiresInspection: json['requires_inspection'] as bool,
      requiresAcid: json['requires_acid'] as bool,
      regulatoryAuthority: json['regulatory_authority'] as String?,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'hs_code': hsCode,
        'hs_description': hsDescription,
        'customs_category': customsCategory,
        'customs_duty_rate': customsDutyRate,
        'vat_rate': vatRate,
        'schedule_tax_rate': scheduleTaxRate,
        'development_fee_rate': developmentFeeRate,
        'import_fee_rate': importFeeRate,
        'requires_coo': requiresCoo,
        'requires_inspection': requiresInspection,
        'requires_acid': requiresAcid,
        'regulatory_authority': regulatoryAuthority,
        'effective_from': effectiveFrom.toIso8601String().split('T').first,
        'effective_to': effectiveTo?.toIso8601String().split('T').first,
        'notes': notes,
      };
}

class CustomsDutyBreakdownModel {
  final String hsCode;
  final String hsDescription;
  final String? customsCategory;
  final DateTime estimateDate;

  final double cifValue;
  final double freight;

  final double customsDutyRate;
  final double vatRate;
  final double scheduleTaxRate;
  final double developmentFeeRate;
  final double importFeeRate;

  final double importDutyAmount;
  final double vatBase;
  final double vatAmount;
  final double scheduleTaxAmount;
  final double developmentFeeAmount;
  final double importFeeAmount;
  final double totalTaxesAndFees;

  final bool requiresCoo;
  final bool requiresInspection;
  final bool requiresAcid;
  final String? regulatoryAuthority;

  const CustomsDutyBreakdownModel({
    required this.hsCode,
    required this.hsDescription,
    this.customsCategory,
    required this.estimateDate,
    required this.cifValue,
    required this.freight,
    required this.customsDutyRate,
    required this.vatRate,
    required this.scheduleTaxRate,
    required this.developmentFeeRate,
    required this.importFeeRate,
    required this.importDutyAmount,
    required this.vatBase,
    required this.vatAmount,
    required this.scheduleTaxAmount,
    required this.developmentFeeAmount,
    required this.importFeeAmount,
    required this.totalTaxesAndFees,
    required this.requiresCoo,
    required this.requiresInspection,
    required this.requiresAcid,
    this.regulatoryAuthority,
  });

  factory CustomsDutyBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CustomsDutyBreakdownModel(
      hsCode: json['hs_code'] as String,
      hsDescription: json['hs_description'] as String,
      customsCategory: json['customs_category'] as String?,
      estimateDate: DateTime.parse(json['estimate_date'] as String),
      cifValue: (json['cif_value'] as num).toDouble(),
      freight: (json['freight'] as num).toDouble(),
      customsDutyRate: (json['customs_duty_rate'] as num).toDouble(),
      vatRate: (json['vat_rate'] as num).toDouble(),
      scheduleTaxRate: (json['schedule_tax_rate'] as num).toDouble(),
      developmentFeeRate: (json['development_fee_rate'] as num).toDouble(),
      importFeeRate: (json['import_fee_rate'] as num).toDouble(),
      importDutyAmount: (json['import_duty_amount'] as num).toDouble(),
      vatBase: (json['vat_base'] as num).toDouble(),
      vatAmount: (json['vat_amount'] as num).toDouble(),
      scheduleTaxAmount: (json['schedule_tax_amount'] as num).toDouble(),
      developmentFeeAmount: (json['development_fee_amount'] as num).toDouble(),
      importFeeAmount: (json['import_fee_amount'] as num).toDouble(),
      totalTaxesAndFees: (json['total_taxes_and_fees'] as num).toDouble(),
      requiresCoo: json['requires_coo'] as bool,
      requiresInspection: json['requires_inspection'] as bool,
      requiresAcid: json['requires_acid'] as bool,
      regulatoryAuthority: json['regulatory_authority'] as String?,
    );
  }
}
