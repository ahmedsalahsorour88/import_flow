class ImportRequirementHSCodeItemModel {
  final String hsCode;
  final String? commodityDescription;
  final String? itemCode;
  final String? countryOfOrigin;
  final String currency;
  final double itemValue;
  final double quantity;
  final String unitOfMeasure;
  final bool decree43Applicable;
  final bool cooRequired;
  final bool inspectionRequired;
  final bool permitRequired;
  final String? regulatoryAuthority;

  ImportRequirementHSCodeItemModel({
    required this.hsCode,
    this.commodityDescription,
    this.itemCode,
    this.countryOfOrigin,
    this.currency = 'USD',
    this.itemValue = 0.0,
    this.quantity = 1.0,
    this.unitOfMeasure = 'PCS',
    this.decree43Applicable = false,
    this.cooRequired = false,
    this.inspectionRequired = false,
    this.permitRequired = false,
    this.regulatoryAuthority,
  });

  factory ImportRequirementHSCodeItemModel.fromJson(Map<String, dynamic> json) {
    return ImportRequirementHSCodeItemModel(
      hsCode: json['hs_code'] ?? '',
      commodityDescription: json['commodity_description'],
      itemCode: json['item_code'],
      countryOfOrigin: json['country_of_origin'],
      currency: json['currency'] ?? 'USD',
      itemValue: (json['item_value'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitOfMeasure: json['unit_of_measure'] ?? 'PCS',
      decree43Applicable: json['decree_43_applicable'] ?? false,
      cooRequired: json['coo_required'] ?? false,
      inspectionRequired: json['inspection_required'] ?? false,
      permitRequired: json['permit_required'] ?? false,
      regulatoryAuthority: json['regulatory_authority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hs_code': hsCode,
      'commodity_description': commodityDescription,
      'item_code': itemCode,
      'country_of_origin': countryOfOrigin,
      'currency': currency,
      'item_value': itemValue,
      'quantity': quantity,
      'unit_of_measure': unitOfMeasure,
      'decree_43_applicable': decree43Applicable,
      'coo_required': cooRequired,
      'inspection_required': inspectionRequired,
      'permit_required': permitRequired,
      'regulatory_authority': regulatoryAuthority,
    };
  }
}

class ImportRequirementPrefillModel {
  final int importFileId;
  final String importFileCode;
  final String? importerName;
  final int? supplierId;
  final String? supplierName;
  final String? countryOfOrigin;
  final String? foreignExporterId;
  final String currency;
  final double shipmentValue;
  final String? poNumber;
  final String? piNumber;
  final String? acidNumber;
  final String? hsCode;
  final String? commodityDescription;
  final List<ImportRequirementHSCodeItemModel> hsCodeItems;

  final int? consultationId;
  final String? consultationCode;
  final String? brokerName;
  final String? consultationStatus;
  final double readinessPercentage;

  final bool decree43Applicable;
  final bool whiteListRequired;
  final bool whiteListVerified;
  final String? factoryRegistrationNo;

  final bool cooRequired;
  final String? cooType;
  final String cooStatus;
  final String? cooNotes;

  final bool inspectionRequired;
  final String? inspectionBody;
  final String inspectionStatus;
  final String? inspectionNotes;

  final bool importPermitRequired;
  final String? permitIssuingAuthority;
  final String permitStatus;
  final String? permitNotes;

  final bool msdsRequired;
  final String msdsStatus;
  final bool halalCertRequired;
  final String halalCertStatus;
  final bool coaRequired;
  final String coaStatus;
  final String? specialNotes;

  ImportRequirementPrefillModel({
    required this.importFileId,
    required this.importFileCode,
    this.importerName,
    this.supplierId,
    this.supplierName,
    this.countryOfOrigin,
    this.foreignExporterId,
    this.currency = 'USD',
    this.shipmentValue = 0.0,
    this.poNumber,
    this.piNumber,
    this.acidNumber,
    this.hsCode,
    this.commodityDescription,
    this.hsCodeItems = const [],
    this.consultationId,
    this.consultationCode,
    this.brokerName,
    this.consultationStatus,
    this.readinessPercentage = 0.0,
    this.decree43Applicable = false,
    this.whiteListRequired = false,
    this.whiteListVerified = false,
    this.factoryRegistrationNo,
    this.cooRequired = false,
    this.cooType,
    this.cooStatus = 'Not Required',
    this.cooNotes,
    this.inspectionRequired = false,
    this.inspectionBody,
    this.inspectionStatus = 'Not Required',
    this.inspectionNotes,
    this.importPermitRequired = false,
    this.permitIssuingAuthority,
    this.permitStatus = 'Not Required',
    this.permitNotes,
    this.msdsRequired = false,
    this.msdsStatus = 'Not Required',
    this.halalCertRequired = false,
    this.halalCertStatus = 'Not Required',
    this.coaRequired = false,
    this.coaStatus = 'Not Required',
    this.specialNotes,
  });

  factory ImportRequirementPrefillModel.fromJson(Map<String, dynamic> json) {
    var rawHsItems = json['hs_code_items'];
    List<ImportRequirementHSCodeItemModel> items = [];
    if (rawHsItems is List) {
      items = rawHsItems.map((e) => ImportRequirementHSCodeItemModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return ImportRequirementPrefillModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      importerName: json['importer_name'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      countryOfOrigin: json['country_of_origin'],
      foreignExporterId: json['foreign_exporter_id'],
      currency: json['currency'] ?? 'USD',
      shipmentValue: (json['shipment_value'] as num?)?.toDouble() ?? 0.0,
      poNumber: json['po_number'],
      piNumber: json['pi_number'],
      acidNumber: json['acid_number'],
      hsCode: json['hs_code'],
      commodityDescription: json['commodity_description'],
      hsCodeItems: items,
      consultationId: json['consultation_id'],
      consultationCode: json['consultation_code'],
      brokerName: json['broker_name'],
      consultationStatus: json['consultation_status'],
      readinessPercentage: (json['readiness_percentage'] as num?)?.toDouble() ?? 0.0,
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
      inspectionNotes: json['inspection_notes'],
      importPermitRequired: json['import_permit_required'] ?? false,
      permitIssuingAuthority: json['permit_issuing_authority'],
      permitStatus: json['permit_status'] ?? 'Not Required',
      permitNotes: json['permit_notes'],
      msdsRequired: json['msds_required'] ?? false,
      msdsStatus: json['msds_status'] ?? 'Not Required',
      halalCertRequired: json['halal_cert_required'] ?? false,
      halalCertStatus: json['halal_cert_status'] ?? 'Not Required',
      coaRequired: json['coa_required'] ?? false,
      coaStatus: json['coa_status'] ?? 'Not Required',
      specialNotes: json['special_notes'],
    );
  }
}

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
  final List<ImportRequirementHSCodeItemModel> hsCodeItems;

  // Post-ACID & Consultation confirmation fields
  final String? acidNumber;
  final int? consultationId;
  final String? consultationCode;
  final String confirmationStatus;
  final bool isPostAcidConfirmed;
  final DateTime? confirmedAt;
  final String? confirmedBy;

  // Sailing & Lifecycle Status (من إصدار ACID حتى الإبحار)
  final String sailingStatus;
  final String? sailingDate;

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
    this.hsCodeItems = const [],
    this.acidNumber,
    this.consultationId,
    this.consultationCode,
    this.confirmationStatus = 'Pending Confirmation',
    this.isPostAcidConfirmed = false,
    this.confirmedAt,
    this.confirmedBy,
    this.sailingStatus = 'Pre-Sailing',
    this.sailingDate,
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
    var rawHsItems = json['hs_code_items'] ?? json['other_requirements'];
    List<ImportRequirementHSCodeItemModel> items = [];
    if (rawHsItems is List) {
      items = rawHsItems
          .where((e) => e is Map && (e.containsKey('hs_code') || e.containsKey('item_value')))
          .map((e) => ImportRequirementHSCodeItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

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
      hsCodeItems: items,
      acidNumber: json['acid_number'],
      consultationId: json['consultation_id'],
      consultationCode: json['consultation_code'],
      confirmationStatus: json['confirmation_status'] ?? 'Pending Confirmation',
      isPostAcidConfirmed: json['is_post_acid_confirmed'] ?? false,
      confirmedAt: json['confirmed_at'] != null ? DateTime.tryParse(json['confirmed_at']) : null,
      confirmedBy: json['confirmed_by'],
      sailingStatus: json['sailing_status'] ?? 'Pre-Sailing',
      sailingDate: json['sailing_date'],
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
      'hs_code_items': hsCodeItems.map((e) => e.toJson()).toList(),
      'acid_number': acidNumber,
      'consultation_id': consultationId,
      'consultation_code': consultationCode,
      'confirmation_status': confirmationStatus,
      'is_post_acid_confirmed': isPostAcidConfirmed,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'confirmed_by': confirmedBy,
      'sailing_status': sailingStatus,
      'sailing_date': sailingDate,
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
