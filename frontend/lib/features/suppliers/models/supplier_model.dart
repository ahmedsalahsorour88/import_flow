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
  final String? email;
  final String? website;
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
    this.email,
    this.website,
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
      registrationType: json['registration_type'] ?? 'Factory',
      foreignExporterId: json['foreign_exporter_id'] ?? '',
      foreignExporterCountry: json['foreign_exporter_country'] ?? '',
      foreignExporterCountryCode: json['foreign_exporter_country_code'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
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
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (brands != null) 'brands': brands,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }
}
