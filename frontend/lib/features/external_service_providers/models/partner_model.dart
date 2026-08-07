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
  final String? email;
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
    this.email,
    this.address,
    this.country = 'Egypt',
    this.paymentType = 'Credit',
    this.creditLimit = 0.0,
    this.rating = 5.0,
    this.notes,
    this.isActive = true,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      providerId: json['provider_id'],
      partnerCode: json['partner_code'] ?? '',
      partnerName: json['partner_name'] ?? '',
      partnerType: json['partner_type'] ?? 'Customs Broker',
      taxId: json['tax_id'],
      commercialRegister: json['commercial_register'],
      clearanceLicenseNumber: json['clearance_license_number'],
      scacCode: json['scac_code'],
      trackingUrl: json['tracking_url'],
      swiftCode: json['swift_code'],
      bankCode: json['bank_code'],
      branchName: json['branch_name'],
      contactPerson: json['contact_person'],
      phone: json['phone'],
      mobile: json['mobile'],
      email: json['email'],
      address: json['address'],
      country: json['country'] ?? 'Egypt',
      paymentType: json['payment_type'] ?? 'Credit',
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
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
      'email': email,
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
