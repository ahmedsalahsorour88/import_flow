class ImportCompanyModel {
  final int? companyId;
  final String importerName;
  final String address;
  final String country;
  final String importerId;
  final DateTime importerIdExpiry;
  final String vatId;
  final DateTime vatIdExpiry;
  final String registrationNumber;
  final DateTime registrationExpiry;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? notes;

  ImportCompanyModel({
    this.companyId,
    required this.importerName,
    required this.address,
    required this.country,
    required this.importerId,
    required this.importerIdExpiry,
    required this.vatId,
    required this.vatIdExpiry,
    required this.registrationNumber,
    required this.registrationExpiry,
    this.phone,
    this.email,
    this.isActive = true,
    this.notes,
  });

  factory ImportCompanyModel.fromJson(Map<String, dynamic> json) {
    return ImportCompanyModel(
      companyId: json['company_id'],
      importerName: json['importer_name'] ?? '',
      address: json['address'] ?? '',
      country: json['country'] ?? '',
      importerId: json['importer_id'] ?? '',
      importerIdExpiry: DateTime.parse(json['importer_id_expiry']),
      vatId: json['vat_id'] ?? '',
      vatIdExpiry: DateTime.parse(json['vat_id_expiry']),
      registrationNumber: json['registration_number'] ?? '',
      registrationExpiry: DateTime.parse(json['registration_expiry']),
      phone: json['phone'],
      email: json['email'],
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (companyId != null) 'company_id': companyId,
      'importer_name': importerName,
      'address': address,
      'country': country,
      'importer_id': importerId,
      'importer_id_expiry': importerIdExpiry.toIso8601String().split('T')[0],
      'vat_id': vatId,
      'vat_id_expiry': vatIdExpiry.toIso8601String().split('T')[0],
      'registration_number': registrationNumber,
      'registration_expiry': registrationExpiry.toIso8601String().split('T')[0],
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'notes': notes,
    };
  }

  // Days remaining helper
  int get daysUntilImporterIdExpiry => importerIdExpiry.difference(DateTime.now()).inDays;
  int get daysUntilVatExpiry => vatIdExpiry.difference(DateTime.now()).inDays;
  int get daysUntilRegExpiry => registrationExpiry.difference(DateTime.now()).inDays;
}
