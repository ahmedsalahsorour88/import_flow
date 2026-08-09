class SupplierModel {
  final int? supplierId;
  final String supplierCode;
  final String companyName;
  final String supplierType;
  final String registrationType;
  final String foreignExporterId;
  final String foreignExporterCountry;
  final String foreignExporterCountryCode;
  final String address;
  final String? phone;
  final String? mobile;
  final String? fax;
  final String? email;
  final String? secondaryEmail;
  final String? website;
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
    required this.foreignExporterCountry,
    required this.foreignExporterCountryCode,
    required this.address,
    this.phone,
    this.mobile,
    this.fax,
    this.email,
    this.secondaryEmail,
    this.website,
    this.hasIso = false,
    this.registeredDecree43 = false,
    this.whiteListRegistered = false,
    this.brands,
    this.notes,
    this.isActive = true,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      supplierId: json['supplier_id'],
      supplierCode: json['supplier_code'] ?? '',
      companyName: json['company_name'] ?? '',
      supplierType: json['supplier_type'] ?? 'Manufacturer',
      registrationType: json['registration_type'] ?? 'Factory Registration',
      foreignExporterId: json['foreign_exporter_id'] ?? '',
      foreignExporterCountry: json['foreign_exporter_country'] ?? '',
      foreignExporterCountryCode: json['foreign_exporter_country_code'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      mobile: json['mobile'],
      fax: json['fax'],
      email: json['email'],
      secondaryEmail: json['secondary_email'],
      website: json['website'],
      hasIso: json['has_iso'] ?? false,
      registeredDecree43: json['registered_decree_43'] ?? false,
      whiteListRegistered: json['white_list_registered'] ?? false,
      brands: json['brands'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
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
      'foreign_exporter_country': foreignExporterCountry,
      'foreign_exporter_country_code': foreignExporterCountryCode,
      'address': address,
      'phone': phone,
      'mobile': mobile,
      'fax': fax,
      'email': email,
      'secondary_email': secondaryEmail,
      'website': website,
      'has_iso': hasIso,
      'registered_decree_43': registeredDecree43,
      'white_list_registered': whiteListRegistered,
      'brands': brands,
      'notes': notes,
      'is_active': isActive,
    };
  }
}
