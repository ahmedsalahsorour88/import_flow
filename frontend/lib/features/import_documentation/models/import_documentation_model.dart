class AcidRegistrationModel {
  final int acidId;
  final String acidCode;
  final String acidNumber;
  final int? importFileId;
  final int? poId;
  final int? importerId;
  final String importerName;
  final String importerTaxId;
  final int? supplierId;
  final String exporterName;
  final String exporterRegId;
  final String exporterCountry;
  final String proformaInvoiceNo;
  final String polName;
  final String podName;
  final String requestedDate;
  final String? generatedDate;
  final String expiryDate;
  final bool isImporterMatched;
  final bool isExporterMatched;
  final bool isInvoiceMatched;
  final bool isPortsMatched;
  final String? verificationNotes;
  final String status;
  final int daysToExpiry;
  final bool isVerified;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

  AcidRegistrationModel({
    required this.acidId,
    required this.acidCode,
    required this.acidNumber,
    this.importFileId,
    this.poId,
    this.importerId,
    required this.importerName,
    required this.importerTaxId,
    this.supplierId,
    required this.exporterName,
    required this.exporterRegId,
    required this.exporterCountry,
    required this.proformaInvoiceNo,
    required this.polName,
    required this.podName,
    required this.requestedDate,
    this.generatedDate,
    required this.expiryDate,
    this.isImporterMatched = true,
    this.isExporterMatched = true,
    this.isInvoiceMatched = true,
    this.isPortsMatched = true,
    this.verificationNotes,
    required this.status,
    this.daysToExpiry = 90,
    this.isVerified = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory AcidRegistrationModel.fromJson(Map<String, dynamic> json) {
    return AcidRegistrationModel(
      acidId: json['acid_id'],
      acidCode: json['acid_code'] ?? '',
      acidNumber: json['acid_number'] ?? '',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      importerId: json['importer_id'],
      importerName: json['importer_name'] ?? '',
      importerTaxId: json['importer_tax_id'] ?? '',
      supplierId: json['supplier_id'],
      exporterName: json['exporter_name'] ?? '',
      exporterRegId: json['exporter_reg_id'] ?? '',
      exporterCountry: json['exporter_country'] ?? '',
      proformaInvoiceNo: json['proforma_invoice_no'] ?? '',
      polName: json['pol_name'] ?? '',
      podName: json['pod_name'] ?? '',
      requestedDate: json['requested_date'] ?? '',
      generatedDate: json['generated_date'],
      expiryDate: json['expiry_date'] ?? '',
      isImporterMatched: json['is_importer_matched'] ?? true,
      isExporterMatched: json['is_exporter_matched'] ?? true,
      isInvoiceMatched: json['is_invoice_matched'] ?? true,
      isPortsMatched: json['is_ports_matched'] ?? true,
      verificationNotes: json['verification_notes'],
      status: json['status'] ?? 'Generated',
      daysToExpiry: json['days_to_expiry'] ?? 90,
      isVerified: json['is_verified'] ?? true,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acid_id': acidId,
      'acid_code': acidCode,
      'acid_number': acidNumber,
      if (importFileId != null) 'import_file_id': importFileId,
      'po_id': poId,
      'importer_id': importerId,
      'importer_name': importerName,
      'importer_tax_id': importerTaxId,
      'supplier_id': supplierId,
      'exporter_name': exporterName,
      'exporter_reg_id': exporterRegId,
      'exporter_country': exporterCountry,
      'proforma_invoice_no': proformaInvoiceNo,
      'pol_name': polName,
      'pod_name': podName,
      'requested_date': requestedDate,
      'generated_date': generatedDate,
      'expiry_date': expiryDate,
      'is_importer_matched': isImporterMatched,
      'is_exporter_matched': isExporterMatched,
      'is_invoice_matched': isInvoiceMatched,
      'is_ports_matched': isPortsMatched,
      'verification_notes': verificationNotes,
      'status': status,
      'is_active': isActive,
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
  final String issueDate;
  final String? expiryDate;
  final String status;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

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
    required this.issueDate,
    this.expiryDate,
    required this.status,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory BankingDocumentModel.fromJson(Map<String, dynamic> json) {
    return BankingDocumentModel(
      bankDocId: json['bank_doc_id'],
      bankDocCode: json['bank_doc_code'] ?? '',
      docType: json['doc_type'] ?? 'Form 4',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      bankId: json['bank_id'],
      bankName: json['bank_name'] ?? '',
      docReferenceNumber: json['doc_reference_number'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currency_code'] ?? 'USD',
      issueDate: json['issue_date'] ?? '',
      expiryDate: json['expiry_date'],
      status: json['status'] ?? 'Form Issued',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
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
