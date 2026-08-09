class PartnerModel {
  final int? providerId;
  final String partnerCode;
  final String partnerName;
  final String partnerType; // Bank, Shipping Line, Customs Broker, Freight Forwarder, Inland Transport, Inspection Agency
  final String? taxId;
  final String? commercialRegister;
  final String? clearanceLicenseNumber;
  final String? scacCode;
  final String? trackingUrl;
  final String? swiftCode;
  final String? bankCode;
  final String? branchName;
  final String? contactPerson;
  final String? phone;
  final String? mobile;
  final String? fax;
  final String? email;
  final String? secondaryEmail;
  final String? website;
  final String? address;
  final String country;
  final String paymentType;
  final double creditLimit;
  final double rating;
  final String? notes;
  final bool isActive;

  List<String> get categoriesList => partnerType
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  PartnerModel({
    this.providerId,
    required this.partnerCode,
    required this.partnerName,
    required this.partnerType,
    this.taxId,
    this.commercialRegister,
    this.clearanceLicenseNumber,
    this.scacCode,
    this.trackingUrl,
    this.swiftCode,
    this.bankCode,
    this.branchName,
    this.contactPerson,
    this.phone,
    this.mobile,
    this.fax,
    this.email,
    this.secondaryEmail,
    this.website,
    this.address,
    this.country = 'Egypt',
    this.paymentType = 'Credit',
    this.creditLimit = 0.0,
    this.rating = 5.0,
    this.notes,
    this.isActive = true,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
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

    return PartnerModel(
      providerId: json['provider_id'],
      partnerCode: json['partner_code']?.toString() ?? '',
      partnerName: json['partner_name']?.toString() ?? '',
      partnerType: json['partner_type']?.toString() ?? 'Customs Broker',
      taxId: json['tax_id']?.toString(),
      commercialRegister: json['commercial_register']?.toString(),
      clearanceLicenseNumber: json['clearance_license_number']?.toString(),
      scacCode: json['scac_code']?.toString(),
      trackingUrl: json['tracking_url']?.toString(),
      swiftCode: json['swift_code']?.toString(),
      bankCode: json['bank_code']?.toString(),
      branchName: json['branch_name']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      phone: json['phone']?.toString(),
      mobile: json['mobile']?.toString(),
      fax: json['fax']?.toString(),
      email: json['email']?.toString(),
      secondaryEmail: json['secondary_email']?.toString(),
      website: json['website']?.toString(),
      address: json['address']?.toString(),
      country: json['country']?.toString() ?? 'Egypt',
      paymentType: json['payment_type']?.toString() ?? 'Credit',
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      notes: json['notes']?.toString(),
      isActive: parseBool(json['is_active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (providerId != null) 'provider_id': providerId,
      'partner_code': partnerCode,
      'partner_name': partnerName,
      'partner_type': partnerType,
      'tax_id': taxId,
      'commercial_register': commercialRegister,
      'clearance_license_number': clearanceLicenseNumber,
      'scac_code': scacCode,
      'tracking_url': trackingUrl,
      'swift_code': swiftCode,
      'bank_code': bankCode,
      'branch_name': branchName,
      'contact_person': contactPerson,
      'phone': phone,
      'mobile': mobile,
      'fax': fax,
      'email': email,
      'secondary_email': secondaryEmail,
      'website': website,
      'address': address,
      'country': country,
      'payment_type': paymentType,
      'credit_limit': creditLimit,
      'rating': rating,
      'notes': notes,
      'is_active': isActive,
    };
  }
}
