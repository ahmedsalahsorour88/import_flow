class ImportRequirementModel {
  final int? assessmentId;
  final String assessmentCode;
  final int? importFileId;
  final String? importFileCode;
  final String? hsCode;
  final String? commodityDescription;
  final String? countryOfOrigin;
  final String currency;
  final double shipmentValue;
  final double shipmentValueUsd;

  // Pillar 1: Decree 43 & Foreign Suppliers
  final int? supplierId;
  final String? supplierName;
  final bool decree43Applicable;
  final bool whiteListRequired;
  final bool whiteListVerified;
  final String? factoryRegistrationNo;

  // Pillar 2: Certificate of Origin (COO) & Trade Reductions
  final bool cooRequired;
  final String? cooType;
  final String cooStatus;
  final String? cooNotes;

  // Pillar 3: Pre-Shipment Inspection Certificate
  final bool inspectionRequired;
  final String? inspectionBody;
  final String inspectionStatus;
  final String? inspectionReportNo;
  final String? inspectionNotes;

  // Pillar 4: Prior Import Permit & Regulatory Authority
  final bool importPermitRequired;
  final String? permitIssuingAuthority;
  final String? permitNumber;
  final String permitStatus;
  final String? permitNotes;

  // Pillar 5: Technical & Special Certificates (MSDS / Halal / COA)
  final bool msdsRequired;
  final String msdsStatus;
  final String? msdsNotes;

  final bool halalCertRequired;
  final String halalCertStatus;
  final String? halalCertNotes;

  final bool coaRequired;
  final String coaStatus;
  final String? coaNotes;

  // Assessment Summary
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
    this.currency = 'USD',
    this.shipmentValue = 0.0,
    required this.shipmentValueUsd,
    this.supplierId,
    this.supplierName,
    required this.decree43Applicable,
    required this.whiteListRequired,
    this.whiteListVerified = false,
    this.factoryRegistrationNo,
    required this.cooRequired,
    this.cooType,
    required this.cooStatus,
    this.cooNotes,
    required this.inspectionRequired,
    this.inspectionBody,
    required this.inspectionStatus,
    this.inspectionReportNo,
    this.inspectionNotes,
    required this.importPermitRequired,
    this.permitIssuingAuthority,
    this.permitNumber,
    required this.permitStatus,
    this.permitNotes,
    required this.msdsRequired,
    required this.msdsStatus,
    this.msdsNotes,
    required this.halalCertRequired,
    required this.halalCertStatus,
    this.halalCertNotes,
    this.coaRequired = false,
    this.coaStatus = 'Not Required',
    this.coaNotes,
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
      currency: json['currency'] ?? 'USD',
      shipmentValue: (json['shipment_value'] ?? json['shipment_value_usd'] ?? 0.0).toDouble(),
      shipmentValueUsd: (json['shipment_value_usd'] ?? 0.0).toDouble(),
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      decree43Applicable: json['decree_43_applicable'] ?? false,
      whiteListRequired: json['white_list_required'] ?? false,
      whiteListVerified: json['white_list_verified'] ?? false,
      factoryRegistrationNo: json['factory_registration_no'],
      cooRequired: json['coo_required'] ?? false,
      cooType: json['coo_type'],
      cooStatus: json['coo_status'] ?? 'Not Required',
      cooNotes: json['coo_notes'],
      inspectionRequired: json['inspection_required'] ?? false,
      inspectionBody: json['inspection_body'],
      inspectionStatus: json['inspection_status'] ?? 'Not Required',
      inspectionReportNo: json['inspection_report_no'],
      inspectionNotes: json['inspection_notes'],
      importPermitRequired: json['import_permit_required'] ?? false,
      permitIssuingAuthority: json['permit_issuing_authority'],
      permitNumber: json['permit_number'],
      permitStatus: json['permit_status'] ?? 'Not Required',
      permitNotes: json['permit_notes'],
      msdsRequired: json['msds_required'] ?? false,
      msdsStatus: json['msds_status'] ?? 'Not Required',
      msdsNotes: json['msds_notes'],
      halalCertRequired: json['halal_cert_required'] ?? false,
      halalCertStatus: json['halal_cert_status'] ?? 'Not Required',
      halalCertNotes: json['halal_cert_notes'],
      coaRequired: json['coa_required'] ?? false,
      coaStatus: json['coa_status'] ?? 'Not Required',
      coaNotes: json['coa_notes'],
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
      'currency': currency,
      'shipment_value': shipmentValue,
      'shipment_value_usd': shipmentValueUsd,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'decree_43_applicable': decree43Applicable,
      'white_list_required': whiteListRequired,
      'white_list_verified': whiteListVerified,
      'factory_registration_no': factoryRegistrationNo,
      'coo_required': cooRequired,
      'coo_type': cooType,
      'coo_status': cooStatus,
      'coo_notes': cooNotes,
      'inspection_required': inspectionRequired,
      'inspection_body': inspectionBody,
      'inspection_status': inspectionStatus,
      'inspection_report_no': inspectionReportNo,
      'inspection_notes': inspectionNotes,
      'import_permit_required': importPermitRequired,
      'permit_issuing_authority': permitIssuingAuthority,
      'permit_number': permitNumber,
      'permit_status': permitStatus,
      'permit_notes': permitNotes,
      'msds_required': msdsRequired,
      'msds_status': msdsStatus,
      'msds_notes': msdsNotes,
      'halal_cert_required': halalCertRequired,
      'halal_cert_status': halalCertStatus,
      'halal_cert_notes': halalCertNotes,
      'coa_required': coaRequired,
      'coa_status': coaStatus,
      'coa_notes': coaNotes,
      'overall_status': overallStatus,
      'risk_level': riskLevel,
      'assessed_by': assessedBy,
      'assessment_notes': assessmentNotes,
      'is_active': isActive,
    };
  }
}
