class AcidDiscrepancyItem {
  final String field;
  final String labelAr;
  final String labelEn;
  final String requestedValue;
  final String generatedValue;
  final bool isMatched;
  final String severity; // error, warning, info

  AcidDiscrepancyItem({
    required this.field,
    required this.labelAr,
    required this.labelEn,
    required this.requestedValue,
    required this.generatedValue,
    required this.isMatched,
    required this.severity,
  });

  factory AcidDiscrepancyItem.fromJson(Map<String, dynamic> json) {
    return AcidDiscrepancyItem(
      field: json['field'] ?? '',
      labelAr: json['label_ar'] ?? '',
      labelEn: json['label_en'] ?? '',
      requestedValue: json['requested_value']?.toString() ?? '',
      generatedValue: json['generated_value']?.toString() ?? '',
      isMatched: json['is_matched'] ?? false,
      severity: json['severity'] ?? 'info',
    );
  }

  Map<String, dynamic> toJson() => {
    'field': field,
    'label_ar': labelAr,
    'label_en': labelEn,
    'requested_value': requestedValue,
    'generated_value': generatedValue,
    'is_matched': isMatched,
    'severity': severity,
  };
}

class AcidComparisonResult {
  final bool allMatched;
  final bool hasCriticalError;
  final double matchPercentage;
  final int totalComparedFields;
  final int matchedCount;
  final int discrepantCount;
  final List<AcidDiscrepancyItem> items;

  AcidComparisonResult({
    required this.allMatched,
    required this.hasCriticalError,
    required this.matchPercentage,
    required this.totalComparedFields,
    required this.matchedCount,
    required this.discrepantCount,
    required this.items,
  });

  factory AcidComparisonResult.fromJson(Map<String, dynamic> json) {
    return AcidComparisonResult(
      allMatched: json['all_matched'] ?? true,
      hasCriticalError: json['has_critical_error'] ?? false,
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 100.0,
      totalComparedFields: json['total_compared_fields'] ?? 0,
      matchedCount: json['matched_count'] ?? 0,
      discrepantCount: json['discrepant_count'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => AcidDiscrepancyItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'all_matched': allMatched,
    'has_critical_error': hasCriticalError,
    'match_percentage': matchPercentage,
    'total_compared_fields': totalComparedFields,
    'matched_count': matchedCount,
    'discrepant_count': discrepantCount,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class AcidRegistrationModel {
  final int acidId;
  final String acidCode;
  final String acidNumber;
  final int? importFileId;
  final String? importFileCode;
  final int? poId;
  final String? poNumber;
  final String? poDate;

  final int? importerId;
  final String importerName;
  final String importerTaxId;
  final String? importerAddress;

  final int? supplierId;
  final String exporterName;
  final String? exporterRegType;
  final String exporterRegId;
  final String exporterCountry;
  final String? exporterCountryCode;
  final String? exporterAddress;
  final String? exporterPhone;
  final String? cargoxId;

  final String proformaInvoiceNo;
  final String? proformaInvoiceDate;
  final String? invoiceDate;
  final String? invoiceType;
  final String? invoiceAttachmentName;

  final String polName;
  final String podName;

  final int? customsBrokerId;
  final String? customsBrokerName;
  final String? customsBrokerPhone;

  final String? requestedDate;
  final String? generatedDate;
  final String? expiryDate;
  final int? executionDays;

  final String? rawNafezaText;
  final Map<String, dynamic>? requestedData;
  final Map<String, dynamic>? generatedData;
  final Map<String, dynamic>? discrepanciesData;
  final String? discrepancyOverrideReason;

  final bool isImporterMatched;
  final bool isExporterMatched;
  final bool isInvoiceMatched;
  final bool isPortsMatched;
  final bool hasDiscrepancies;
  final String? verificationNotes;
  final String status;
  final int daysToExpiry;
  final bool isVerified;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  AcidRegistrationModel({
    required this.acidId,
    required this.acidCode,
    required this.acidNumber,
    this.importFileId,
    this.importFileCode,
    this.poId,
    this.poNumber,
    this.poDate,
    this.importerId,
    required this.importerName,
    required this.importerTaxId,
    this.importerAddress,
    this.supplierId,
    required this.exporterName,
    this.exporterRegType = 'VAT Number',
    required this.exporterRegId,
    required this.exporterCountry,
    this.exporterCountryCode,
    this.exporterAddress,
    this.exporterPhone,
    this.cargoxId,
    required this.proformaInvoiceNo,
    this.proformaInvoiceDate,
    this.invoiceDate,
    this.invoiceType = 'Proforma Invoice',
    this.invoiceAttachmentName,
    required this.polName,
    required this.podName,
    this.customsBrokerId,
    this.customsBrokerName,
    this.customsBrokerPhone,
    this.requestedDate,
    this.generatedDate,
    this.expiryDate,
    this.executionDays,
    this.rawNafezaText,
    this.requestedData,
    this.generatedData,
    this.discrepanciesData,
    this.discrepancyOverrideReason,
    this.isImporterMatched = true,
    this.isExporterMatched = true,
    this.isInvoiceMatched = true,
    this.isPortsMatched = true,
    this.hasDiscrepancies = false,
    this.verificationNotes,
    required this.status,
    this.daysToExpiry = 90,
    this.isVerified = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcidRegistrationModel.fromJson(Map<String, dynamic> json) {
    return AcidRegistrationModel(
      acidId: json['acid_id'] ?? 0,
      acidCode: json['acid_code'] ?? '',
      acidNumber: json['acid_number'] ?? '',
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'],
      poId: json['po_id'],
      poNumber: json['po_number'],
      poDate: json['po_date'],
      importerId: json['importer_id'],
      importerName: json['importer_name'] ?? '',
      importerTaxId: json['importer_tax_id'] ?? '',
      importerAddress: json['importer_address'],
      supplierId: json['supplier_id'],
      exporterName: json['exporter_name'] ?? '',
      exporterRegType: json['exporter_reg_type'] ?? 'VAT Number',
      exporterRegId: json['exporter_reg_id'] ?? '',
      exporterCountry: json['exporter_country'] ?? '',
      exporterCountryCode: json['exporter_country_code'],
      exporterAddress: json['exporter_address'],
      exporterPhone: json['exporter_phone'],
      cargoxId: json['cargox_id'],
      proformaInvoiceNo: json['proforma_invoice_no'] ?? '',
      proformaInvoiceDate: json['proforma_invoice_date'],
      invoiceDate: json['invoice_date'],
      invoiceType: json['invoice_type'] ?? 'Proforma Invoice',
      invoiceAttachmentName: json['invoice_attachment_name'],
      polName: json['pol_name'] ?? '',
      podName: json['pod_name'] ?? '',
      customsBrokerId: json['customs_broker_id'],
      customsBrokerName: json['customs_broker_name'],
      customsBrokerPhone: json['customs_broker_phone'],
      requestedDate: json['requested_date'],
      generatedDate: json['generated_date'],
      expiryDate: json['expiry_date'],
      executionDays: json['execution_days'] as int?,
      rawNafezaText: json['raw_nafeza_text'],
      requestedData: json['requested_data'] != null ? Map<String, dynamic>.from(json['requested_data']) : null,
      generatedData: json['generated_data'] != null ? Map<String, dynamic>.from(json['generated_data']) : null,
      discrepanciesData: json['discrepancies_data'] != null ? Map<String, dynamic>.from(json['discrepancies_data']) : null,
      discrepancyOverrideReason: json['discrepancy_override_reason'],
      isImporterMatched: json['is_importer_matched'] ?? true,
      isExporterMatched: json['is_exporter_matched'] ?? true,
      isInvoiceMatched: json['is_invoice_matched'] ?? true,
      isPortsMatched: json['is_ports_matched'] ?? true,
      hasDiscrepancies: json['has_discrepancies'] ?? false,
      verificationNotes: json['verification_notes'],
      status: json['status'] ?? 'Requested',
      daysToExpiry: json['days_to_expiry'] ?? 90,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acid_id': acidId,
      'acid_code': acidCode,
      'acid_number': acidNumber,
      if (importFileId != null) 'import_file_id': importFileId,
      if (importFileCode != null) 'import_file_code': importFileCode,
      if (poId != null) 'po_id': poId,
      if (poNumber != null) 'po_number': poNumber,
      if (poDate != null) 'po_date': poDate,
      if (importerId != null) 'importer_id': importerId,
      'importer_name': importerName,
      'importer_tax_id': importerTaxId,
      if (importerAddress != null) 'importer_address': importerAddress,
      if (supplierId != null) 'supplier_id': supplierId,
      'exporter_name': exporterName,
      'exporter_reg_type': exporterRegType,
      'exporter_reg_id': exporterRegId,
      'exporter_country': exporterCountry,
      if (exporterCountryCode != null) 'exporter_country_code': exporterCountryCode,
      if (exporterAddress != null) 'exporter_address': exporterAddress,
      if (exporterPhone != null) 'exporter_phone': exporterPhone,
      if (cargoxId != null) 'cargox_id': cargoxId,
      'proforma_invoice_no': proformaInvoiceNo,
      if (proformaInvoiceDate != null) 'proforma_invoice_date': proformaInvoiceDate,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      'invoice_type': invoiceType,
      if (invoiceAttachmentName != null) 'invoice_attachment_name': invoiceAttachmentName,
      'pol_name': polName,
      'pod_name': podName,
      if (customsBrokerId != null) 'customs_broker_id': customsBrokerId,
      if (customsBrokerName != null) 'customs_broker_name': customsBrokerName,
      if (customsBrokerPhone != null) 'customs_broker_phone': customsBrokerPhone,
      if (requestedDate != null) 'requested_date': requestedDate,
      if (generatedDate != null) 'generated_date': generatedDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (executionDays != null) 'execution_days': executionDays,
      if (rawNafezaText != null) 'raw_nafeza_text': rawNafezaText,
      if (requestedData != null) 'requested_data': requestedData,
      if (generatedData != null) 'generated_data': generatedData,
      if (discrepanciesData != null) 'discrepancies_data': discrepanciesData,
      if (discrepancyOverrideReason != null) 'discrepancy_override_reason': discrepancyOverrideReason,
      'is_importer_matched': isImporterMatched,
      'is_exporter_matched': isExporterMatched,
      'is_invoice_matched': isInvoiceMatched,
      'is_ports_matched': isPortsMatched,
      'has_discrepancies': hasDiscrepancies,
      if (verificationNotes != null) 'verification_notes': verificationNotes,
      'status': status,
    };
  }
}

class BankingDocumentModel {
  final int bankDocId;
  final String bankDocCode;
  final String docType;
  final int? importFileId;
  final int? poId;
  final int? bankId;
  final String bankName;
  final String docReferenceNumber;
  final double amount;
  final String currencyCode;
  final String? requestDate;
  final String? receivedDate;
  final int executionDays;
  final String issueDate;
  final String? expiryDate;
  final String status;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;
  final String? importerName;
  final String? supplierName;
  final String? poNumber;

  BankingDocumentModel({
    required this.bankDocId,
    required this.bankDocCode,
    required this.docType,
    this.importFileId,
    this.poId,
    this.bankId,
    required this.bankName,
    required this.docReferenceNumber,
    required this.amount,
    this.currencyCode = 'USD',
    this.requestDate,
    this.receivedDate,
    this.executionDays = 0,
    required this.issueDate,
    this.expiryDate,
    required this.status,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
    this.importerName,
    this.supplierName,
    this.poNumber,
  });

  factory BankingDocumentModel.fromJson(Map<String, dynamic> json) {
    return BankingDocumentModel(
      bankDocId: json['bank_doc_id'] ?? 0,
      bankDocCode: json['bank_doc_code'] ?? '',
      docType: json['doc_type'] ?? 'Form 4',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      bankId: json['bank_id'],
      bankName: json['bank_name'] ?? '',
      docReferenceNumber: json['doc_reference_number'] ?? 'PENDING',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currency_code'] ?? 'USD',
      requestDate: json['request_date']?.toString(),
      receivedDate: json['received_date']?.toString(),
      executionDays: (json['execution_days'] as num?)?.toInt() ?? 0,
      issueDate: json['issue_date']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString(),
      status: json['status'] ?? 'Requested',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      importFileCode: json['import_file_code'],
      importerName: json['importer_name'],
      supplierName: json['supplier_name'],
      poNumber: json['po_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_doc_id': bankDocId,
      'bank_doc_code': bankDocCode,
      'doc_type': docType,
      if (importFileId != null) 'import_file_id': importFileId,
      'po_id': poId,
      'bank_id': bankId,
      'bank_name': bankName,
      'doc_reference_number': docReferenceNumber,
      'amount': amount,
      'currency_code': currencyCode,
      if (requestDate != null) 'request_date': requestDate,
      if (receivedDate != null) 'received_date': receivedDate,
      'execution_days': executionDays,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'status': status,
      'notes': notes,
      'is_active': isActive,
    };
  }
}

class ShipmentDocumentModel {
  final int documentId;
  final String documentCode;
  final int? importFileId;
  final int? poId;
  final String docName;
  final String docNumber;
  final String issueDate;
  final String? receivedDate;
  final String status;
  final bool isCargoxUploaded;
  final String? cargoxEnvelopeId;
  final bool isBlEndorsed;
  final String? endorsementNumber;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

  ShipmentDocumentModel({
    required this.documentId,
    required this.documentCode,
    this.importFileId,
    this.poId,
    required this.docName,
    required this.docNumber,
    required this.issueDate,
    this.receivedDate,
    required this.status,
    this.isCargoxUploaded = false,
    this.cargoxEnvelopeId,
    this.isBlEndorsed = false,
    this.endorsementNumber,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory ShipmentDocumentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentDocumentModel(
      documentId: json['document_id'],
      documentCode: json['document_code'] ?? '',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      docName: json['doc_name'] ?? '',
      docNumber: json['doc_number'] ?? '',
      issueDate: json['issue_date'] ?? '',
      receivedDate: json['received_date'],
      status: json['status'] ?? 'Approved',
      isCargoxUploaded: json['is_cargox_uploaded'] ?? false,
      cargoxEnvelopeId: json['cargox_envelope_id'],
      isBlEndorsed: json['is_bl_endorsed'] ?? false,
      endorsementNumber: json['endorsement_number'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'document_code': documentCode,
      if (importFileId != null) 'import_file_id': importFileId,
      'po_id': poId,
      'doc_name': docName,
      'doc_number': docNumber,
      'issue_date': issueDate,
      'received_date': receivedDate,
      'status': status,
      'is_cargox_uploaded': isCargoxUploaded,
      'cargox_envelope_id': cargoxEnvelopeId,
      'is_bl_endorsed': isBlEndorsed,
      'endorsement_number': endorsementNumber,
      'notes': notes,
      'is_active': isActive,
    };
  }
}

class CustomsDeclarationModel {
  final int declarationId;
  final String declarationCode;
  final int? importFileId;
  final int? poId;
  final String acidNumber;
  final String? form4Number;
  final String? blNumber;
  final double totalCifValEgp;
  final double totalCustomsDutiesEgp;
  final double totalVatEgp;
  final String declarationStatus;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

  CustomsDeclarationModel({
    required this.declarationId,
    required this.declarationCode,
    this.importFileId,
    this.poId,
    required this.acidNumber,
    this.form4Number,
    this.blNumber,
    this.totalCifValEgp = 0.0,
    this.totalCustomsDutiesEgp = 0.0,
    this.totalVatEgp = 0.0,
    required this.declarationStatus,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory CustomsDeclarationModel.fromJson(Map<String, dynamic> json) {
    return CustomsDeclarationModel(
      declarationId: json['declaration_id'],
      declarationCode: json['declaration_code'] ?? '',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      acidNumber: json['acid_number'] ?? '',
      form4Number: json['form4_number'],
      blNumber: json['bl_number'],
      totalCifValEgp: (json['total_cif_val_egp'] as num?)?.toDouble() ?? 0.0,
      totalCustomsDutiesEgp: (json['total_customs_duties_egp'] as num?)?.toDouble() ?? 0.0,
      totalVatEgp: (json['total_vat_egp'] as num?)?.toDouble() ?? 0.0,
      declarationStatus: json['declaration_status'] ?? 'Draft Prepared',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'declaration_id': declarationId,
      'declaration_code': declarationCode,
      if (importFileId != null) 'import_file_id': importFileId,
      'po_id': poId,
      'acid_number': acidNumber,
      'form4_number': form4Number,
      'bl_number': blNumber,
      'total_cif_val_egp': totalCifValEgp,
      'total_customs_duties_egp': totalCustomsDutiesEgp,
      'total_vat_egp': totalVatEgp,
      'declaration_status': declarationStatus,
      'is_active': isActive,
    };
  }
}

class AcidTrackerItemModel {
  final int? importFileId;
  final String? importFileCode;
  final String? customFileNumber;
  final int? acidSessionId;
  final String? acidCode;
  final String acidNumber;
  final String importerName;
  final String supplierName;
  final String? poNumber;
  final String? piNumber;
  final String? shipmentMode;
  final String? currentStage;
  final String? customsBrokerName;

  final String? acidIssueDate;
  final String? acidExpiryDate;
  final int? executionDays;
  final int daysRemaining;
  final int totalValidityDays;
  final double validityPercentage;

  final bool isCustomsReleased;
  final String? customsReleasedAt;
  final String? releasePermitNo;

  final String status;
  final String statusLabelAr;
  final bool alertRequired;

  AcidTrackerItemModel({
    this.importFileId,
    this.importFileCode,
    this.customFileNumber,
    this.acidSessionId,
    this.acidCode,
    required this.acidNumber,
    required this.importerName,
    required this.supplierName,
    this.poNumber,
    this.piNumber,
    this.shipmentMode,
    this.currentStage,
    this.customsBrokerName,
    this.acidIssueDate,
    this.acidExpiryDate,
    this.executionDays,
    required this.daysRemaining,
    this.totalValidityDays = 90,
    required this.validityPercentage,
    this.isCustomsReleased = false,
    this.customsReleasedAt,
    this.releasePermitNo,
    required this.status,
    required this.statusLabelAr,
    required this.alertRequired,
  });

  factory AcidTrackerItemModel.fromJson(Map<String, dynamic> json) {
    return AcidTrackerItemModel(
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'],
      customFileNumber: json['custom_file_number'],
      acidSessionId: json['acid_session_id'],
      acidCode: json['acid_code'],
      acidNumber: json['acid_number'] ?? '',
      importerName: json['importer_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      poNumber: json['po_number'],
      piNumber: json['pi_number'],
      shipmentMode: json['shipment_mode'],
      currentStage: json['current_stage'],
      customsBrokerName: json['customs_broker_name'],
      acidIssueDate: json['acid_issue_date'],
      acidExpiryDate: json['acid_expiry_date'],
      executionDays: json['execution_days'] as int?,
      daysRemaining: json['days_remaining'] ?? 0,
      totalValidityDays: json['total_validity_days'] ?? 90,
      validityPercentage: (json['validity_percentage'] as num?)?.toDouble() ?? 0.0,
      isCustomsReleased: json['is_customs_released'] ?? false,
      customsReleasedAt: json['customs_released_at'],
      releasePermitNo: json['release_permit_no'],
      status: json['status'] ?? 'Valid',
      statusLabelAr: json['status_label_ar'] ?? '',
      alertRequired: json['alert_required'] ?? false,
    );
  }
}

class AcidTrackerSummaryModel {
  final int totalAcidsCount;
  final int validCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int customsReleasedCount;
  final int pendingIssueCount;
  final List<AcidTrackerItemModel> items;

  AcidTrackerSummaryModel({
    required this.totalAcidsCount,
    required this.validCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.customsReleasedCount,
    required this.pendingIssueCount,
    required this.items,
  });

  factory AcidTrackerSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    return AcidTrackerSummaryModel(
      totalAcidsCount: json['total_acids_count'] ?? 0,
      validCount: json['valid_count'] ?? 0,
      expiringSoonCount: json['expiring_soon_count'] ?? 0,
      expiredCount: json['expired_count'] ?? 0,
      customsReleasedCount: json['customs_released_count'] ?? 0,
      pendingIssueCount: json['pending_issue_count'] ?? 0,
      items: rawItems.map((i) => AcidTrackerItemModel.fromJson(i)).toList(),
    );
  }
}

