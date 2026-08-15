class SupplierModel {
  final int? supplierId;
  final String supplierCode;
  final String companyName;
  final String supplierType;
  final String registrationType;
  final String foreignExporterId;
  final String? cargoxPlatformId;
  final String foreignExporterCountry;
  final String foreignExporterCountryCode;
  final String address;
  final String? phone;
  final String? mobile;
  final String? fax;
  final String? email;
  final String? secondaryEmail;
  final String? website;
  final String? bankName;
  final String? swiftCode;
  final String? accountNumber;
  final String? iban;
  final bool hasIso;
  final bool registeredDecree43;
  final bool whiteListRegistered;
  final String? brands;
  final String? notes;
  final bool isActive;

  SupplierModel({
    this.supplierId,
    required this.supplierCode,
    required this.companyName,
    required this.supplierType,
    required this.registrationType,
    required this.foreignExporterId,
    this.cargoxPlatformId,
    required this.foreignExporterCountry,
    required this.foreignExporterCountryCode,
    required this.address,
    this.phone,
    this.mobile,
    this.fax,
    this.email,
    this.secondaryEmail,
    this.website,
    this.bankName,
    this.swiftCode,
    this.accountNumber,
    this.iban,
    this.hasIso = false,
    this.registeredDecree43 = false,
    this.whiteListRegistered = false,
    this.brands,
    this.notes,
    this.isActive = true,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes' || s == 't';
      }
      return defaultValue;
    }

    return SupplierModel(
      supplierId: json['supplier_id'],
      supplierCode: json['supplier_code']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      supplierType: json['supplier_type']?.toString() ?? 'Manufacturer',
      registrationType: json['registration_type']?.toString() ?? 'Factory Registration',
      foreignExporterId: json['foreign_exporter_id']?.toString() ?? '',
      cargoxPlatformId: json['cargox_platform_id']?.toString(),
      foreignExporterCountry: json['foreign_exporter_country']?.toString() ?? '',
      foreignExporterCountryCode: json['foreign_exporter_country_code']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(),
      mobile: json['mobile']?.toString(),
      fax: json['fax']?.toString(),
      email: json['email']?.toString(),
      secondaryEmail: json['secondary_email']?.toString(),
      website: json['website']?.toString(),
      bankName: json['bank_name']?.toString(),
      swiftCode: json['swift_code']?.toString(),
      accountNumber: json['account_number']?.toString(),
      iban: json['iban']?.toString(),
      hasIso: parseBool(json['has_iso']),
      registeredDecree43: parseBool(json['registered_decree_43']),
      whiteListRegistered: parseBool(json['white_list_registered']),
      brands: json['brands']?.toString(),
      notes: json['notes']?.toString(),
      isActive: parseBool(json['is_active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (supplierId != null) 'supplier_id': supplierId,
      'supplier_code': supplierCode,
      'company_name': companyName,
      'supplier_type': supplierType,
      'registration_type': registrationType,
      'foreign_exporter_id': foreignExporterId,
      if (cargoxPlatformId != null) 'cargox_platform_id': cargoxPlatformId,
      'foreign_exporter_country': foreignExporterCountry,
      'foreign_exporter_country_code': foreignExporterCountryCode,
      'address': address,
      'phone': phone,
      'mobile': mobile,
      'fax': fax,
      'email': email,
      'secondary_email': secondaryEmail,
      'website': website,
      'bank_name': bankName,
      'swift_code': swiftCode,
      'account_number': accountNumber,
      'iban': iban,
      'has_iso': hasIso,
      'registered_decree_43': registeredDecree43,
      'white_list_registered': whiteListRegistered,
      'brands': brands,
      'notes': notes,
      'is_active': isActive,
    };
  }
}
