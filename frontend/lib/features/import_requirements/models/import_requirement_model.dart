class ImportRequirementModel {
  final int? assessmentId;
  final String assessmentCode;
  final int? importFileId;
  final String? importFileCode;
  final String? hsCode;
  final String? commodityDescription;
  final String? countryOfOrigin;
  final double shipmentValueUsd;
  final bool cooRequired;
  final String? cooType;
  final String cooStatus;
  final String? cooNotes;
  final bool inspectionRequired;
  final String? inspectionBody;
  final String inspectionStatus;
  final String? inspectionNotes;
  final bool msdsRequired;
  final String msdsStatus;
  final String? msdsNotes;
  final bool halalCertRequired;
  final String halalCertStatus;
  final String? halalCertNotes;
  final bool importPermitRequired;
  final String? permitIssuingAuthority;
  final String permitStatus;
  final String? permitNotes;
  final bool decree43Applicable;
  final bool whiteListRequired;
  final String overallStatus;
  final String riskLevel;
  final String assessedBy;
  final String? assessmentNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImportRequirementModel({
    this.assessmentId,
    required this.assessmentCode,
    this.importFileId,
    this.importFileCode,
    this.hsCode,
    this.commodityDescription,
    this.countryOfOrigin,
    required this.shipmentValueUsd,
    required this.cooRequired,
    this.cooType,
    required this.cooStatus,
    this.cooNotes,
    required this.inspectionRequired,
    this.inspectionBody,
    required this.inspectionStatus,
    this.inspectionNotes,
    required this.msdsRequired,
    required this.msdsStatus,
    this.msdsNotes,
    required this.halalCertRequired,
    required this.halalCertStatus,
    this.halalCertNotes,
    required this.importPermitRequired,
    this.permitIssuingAuthority,
    required this.permitStatus,
    this.permitNotes,
    required this.decree43Applicable,
    required this.whiteListRequired,
    required this.overallStatus,
    required this.riskLevel,
    required this.assessedBy,
    this.assessmentNotes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImportRequirementModel.fromJson(Map<String, dynamic> json) {
    return ImportRequirementModel(
      assessmentId: json['assessment_id'],
      assessmentCode: json['assessment_code'] ?? '',
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'],
      hsCode: json['hs_code'],
      commodityDescription: json['commodity_description'],
      countryOfOrigin: json['country_of_origin'],
      shipmentValueUsd: (json['shipment_value_usd'] ?? 0.0).toDouble(),
      cooRequired: json['coo_required'] ?? false,
      cooType: json['coo_type'],
      cooStatus: json['coo_status'] ?? 'Not Required',
      cooNotes: json['coo_notes'],
      inspectionRequired: json['inspection_required'] ?? false,
      inspectionBody: json['inspection_body'],
      inspectionStatus: json['inspection_status'] ?? 'Not Required',
      inspectionNotes: json['inspection_notes'],
      msdsRequired: json['msds_required'] ?? false,
      msdsStatus: json['msds_status'] ?? 'Not Required',
      msdsNotes: json['msds_notes'],
      halalCertRequired: json['halal_cert_required'] ?? false,
      halalCertStatus: json['halal_cert_status'] ?? 'Not Required',
      halalCertNotes: json['halal_cert_notes'],
      importPermitRequired: json['import_permit_required'] ?? false,
      permitIssuingAuthority: json['permit_issuing_authority'],
      permitStatus: json['permit_status'] ?? 'Not Required',
      permitNotes: json['permit_notes'],
      decree43Applicable: json['decree_43_applicable'] ?? false,
      whiteListRequired: json['white_list_required'] ?? false,
      overallStatus: json['overall_status'] ?? 'Draft',
      riskLevel: json['risk_level'] ?? 'Low',
      assessedBy: json['assessed_by'] ?? 'System',
      assessmentNotes: json['assessment_notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assessment_id': assessmentId,
      'assessment_code': assessmentCode,
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'hs_code': hsCode,
      'commodity_description': commodityDescription,
      'country_of_origin': countryOfOrigin,
      'shipment_value_usd': shipmentValueUsd,
      'coo_required': cooRequired,
      'coo_type': cooType,
      'coo_status': cooStatus,
      'coo_notes': cooNotes,
      'inspection_required': inspectionRequired,
      'inspection_body': inspectionBody,
      'inspection_status': inspectionStatus,
      'inspection_notes': inspectionNotes,
      'msds_required': msdsRequired,
      'msds_status': msdsStatus,
      'msds_notes': msdsNotes,
      'halal_cert_required': halalCertRequired,
      'halal_cert_status': halalCertStatus,
      'halal_cert_notes': halalCertNotes,
      'import_permit_required': importPermitRequired,
      'permit_issuing_authority': permitIssuingAuthority,
      'permit_status': permitStatus,
      'permit_notes': permitNotes,
      'decree_43_applicable': decree43Applicable,
      'white_list_required': whiteListRequired,
      'overall_status': overallStatus,
      'risk_level': riskLevel,
      'assessed_by': assessedBy,
      'assessment_notes': assessmentNotes,
      'is_active': isActive,
    };
  }
}
