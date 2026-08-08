class TransportLocationModel {
  final int? locationId;
  final String unLocode;
  final String locationName;
  final String locationType;
  final String country;
  final String city;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransportLocationModel({
    this.locationId,
    required this.unLocode,
    required this.locationName,
    required this.locationType,
    required this.country,
    required this.city,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TransportLocationModel.fromJson(Map<String, dynamic> json) {
    return TransportLocationModel(
      locationId: json['location_id'] as int?,
      unLocode: json['un_locode'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
      locationType: json['location_type'] as String? ?? 'Sea Port',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (locationId != null) 'location_id': locationId,
      'un_locode': unLocode,
      'location_name': locationName,
      'location_type': locationType,
      'country': country,
      'city': city,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }
}
