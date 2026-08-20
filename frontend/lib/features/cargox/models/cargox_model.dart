class CargoXDocumentModel {
  final int docId;
  final int envelopeId;
  final String docType;
  final String? docNumber;
  final String fileName;
  final String? fileHash;
  final double fileSizeKb;
  final bool isMandatory;
  final bool isUploaded;
  final DateTime uploadedAt;
  final bool verifiedAgainstAcid;
  final String? pkiSignature;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  CargoXDocumentModel({
    required this.docId,
    required this.envelopeId,
    required this.docType,
    this.docNumber,
    required this.fileName,
    this.fileHash,
    required this.fileSizeKb,
    required this.isMandatory,
    required this.isUploaded,
    required this.uploadedAt,
    required this.verifiedAgainstAcid,
    this.pkiSignature,
    this.notes,
    required this.isActive,
    required this.createdAt,
  });

  factory CargoXDocumentModel.fromJson(Map<String, dynamic> json) {
    return CargoXDocumentModel(
      docId: json['doc_id'] as int? ?? 0,
      envelopeId: json['envelope_id'] as int? ?? 0,
      docType: json['doc_type'] as String? ?? '',
      docNumber: json['doc_number'] as String?,
      fileName: json['file_name'] as String? ?? '',
      fileHash: json['file_hash'] as String?,
      fileSizeKb: (json['file_size_kb'] as num?)?.toDouble() ?? 0.0,
      isMandatory: json['is_mandatory'] as bool? ?? true,
      isUploaded: json['is_uploaded'] as bool? ?? true,
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at']) : DateTime.now(),
      verifiedAgainstAcid: json['verified_against_acid'] as bool? ?? true,
      pkiSignature: json['pki_signature'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doc_id': docId,
      'envelope_id': envelopeId,
      'doc_type': docType,
      'doc_number': docNumber,
      'file_name': fileName,
      'file_hash': fileHash,
      'file_size_kb': fileSizeKb,
      'is_mandatory': isMandatory,
      'is_uploaded': isUploaded,
      'uploaded_at': uploadedAt.toIso8601String(),
      'verified_against_acid': verifiedAgainstAcid,
      'pki_signature': pkiSignature,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CargoXEnvelopeModel {
  final int envelopeId;
  final String envelopeCode;
  final int? importFileId;
  final String? importFileCode;
  final String acidNumber;
  final int? importerCompanyId;
  final String importerCompanyName;
  final String? importerTaxNumber;
  final int? supplierId;
  final String supplierName;
  final String supplierCargoxId;
  final String? blNumber;
  final String status;
  final String? blockchainTxHash;
  final String? pkiSignature;
  final bool isAcidVerified;
  final bool allDocumentsSealed;
  final DateTime? transferredToCustomsAt;
  final String? customsConfirmationReceipt;
  final String? customsRejectionReason;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final List<CargoXDocumentModel> documents;

  CargoXEnvelopeModel({
    required this.envelopeId,
    required this.envelopeCode,
    this.importFileId,
    this.importFileCode,
    required this.acidNumber,
    this.importerCompanyId,
    required this.importerCompanyName,
    this.importerTaxNumber,
    this.supplierId,
    required this.supplierName,
    required this.supplierCargoxId,
    this.blNumber,
    required this.status,
    this.blockchainTxHash,
    this.pkiSignature,
    required this.isAcidVerified,
    required this.allDocumentsSealed,
    this.transferredToCustomsAt,
    this.customsConfirmationReceipt,
    this.customsRejectionReason,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.documents = const [],
  });

  factory CargoXEnvelopeModel.fromJson(Map<String, dynamic> json) {
    return CargoXEnvelopeModel(
      envelopeId: json['envelope_id'] as int? ?? 0,
      envelopeCode: json['envelope_code'] as String? ?? '',
      importFileId: json['import_file_id'] as int?,
      importFileCode: json['import_file_code'] as String?,
      acidNumber: json['acid_number'] as String? ?? '',
      importerCompanyId: json['importer_company_id'] as int?,
      importerCompanyName: json['importer_company_name'] as String? ?? '',
      importerTaxNumber: json['importer_tax_number'] as String?,
      supplierId: json['supplier_id'] as int?,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierCargoxId: json['supplier_cargox_id'] as String? ?? '',
      blNumber: json['bl_number'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      blockchainTxHash: json['blockchain_tx_hash'] as String?,
      pkiSignature: json['pki_signature'] as String?,
      isAcidVerified: json['is_acid_verified'] as bool? ?? false,
      allDocumentsSealed: json['all_documents_sealed'] as bool? ?? false,
      transferredToCustomsAt: json['transferred_to_customs_at'] != null ? DateTime.parse(json['transferred_to_customs_at']) : null,
      customsConfirmationReceipt: json['customs_confirmation_receipt'] as String?,
      customsRejectionReason: json['customs_rejection_reason'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      createdBy: json['created_by'] as String? ?? 'SYSTEM',
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      updatedBy: json['updated_by'] as String? ?? 'SYSTEM',
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => CargoXDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'envelope_id': envelopeId,
      'envelope_code': envelopeCode,
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'acid_number': acidNumber,
      'importer_company_id': importerCompanyId,
      'importer_company_name': importerCompanyName,
      'importer_tax_number': importerTaxNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_cargox_id': supplierCargoxId,
      'bl_number': blNumber,
      'status': status,
      'blockchain_tx_hash': blockchainTxHash,
      'pki_signature': pkiSignature,
      'is_acid_verified': isAcidVerified,
      'all_documents_sealed': allDocumentsSealed,
      'transferred_to_customs_at': transferredToCustomsAt?.toIso8601String(),
      'customs_confirmation_receipt': customsConfirmationReceipt,
      'customs_rejection_reason': customsRejectionReason,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
      'documents': documents.map((e) => e.toJson()).toList(),
    };
  }
}

class ACIDVerificationItemModel {
  final String docType;
  final String? docNumber;
  final String documentAcid;
  final bool isMatched;
  final String status;
  final String? notes;

  ACIDVerificationItemModel({
    required this.docType,
    this.docNumber,
    required this.documentAcid,
    required this.isMatched,
    required this.status,
    this.notes,
  });

  factory ACIDVerificationItemModel.fromJson(Map<String, dynamic> json) {
    return ACIDVerificationItemModel(
      docType: json['doc_type'] as String? ?? '',
      docNumber: json['doc_number'] as String?,
      documentAcid: json['document_acid'] as String? ?? '',
      isMatched: json['is_matched'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class CargoXAcidVerificationReportModel {
  final int envelopeId;
  final String envelopeCode;
  final String targetAcidNumber;
  final bool allMatched;
  final int verifiedCount;
  final int totalDocuments;
  final String verificationStatus;
  final List<ACIDVerificationItemModel> items;

  CargoXAcidVerificationReportModel({
    required this.envelopeId,
    required this.envelopeCode,
    required this.targetAcidNumber,
    required this.allMatched,
    required this.verifiedCount,
    required this.totalDocuments,
    required this.verificationStatus,
    this.items = const [],
  });

  factory CargoXAcidVerificationReportModel.fromJson(Map<String, dynamic> json) {
    return CargoXAcidVerificationReportModel(
      envelopeId: json['envelope_id'] as int? ?? 0,
      envelopeCode: json['envelope_code'] as String? ?? '',
      targetAcidNumber: json['target_acid_number'] as String? ?? '',
      allMatched: json['all_matched'] as bool? ?? false,
      verifiedCount: json['verified_count'] as int? ?? 0,
      totalDocuments: json['total_documents'] as int? ?? 0,
      verificationStatus: json['verification_status'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ACIDVerificationItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DigitalManifestModel {
  final int envelopeId;
  final String envelopeCode;
  final String acidNumber;
  final Map<String, dynamic> manifestJson;
  final DateTime exportedAt;
  final String formattedSummary;

  DigitalManifestModel({
    required this.envelopeId,
    required this.envelopeCode,
    required this.acidNumber,
    required this.manifestJson,
    required this.exportedAt,
    required this.formattedSummary,
  });

  factory DigitalManifestModel.fromJson(Map<String, dynamic> json) {
    return DigitalManifestModel(
      envelopeId: json['envelope_id'] as int? ?? 0,
      envelopeCode: json['envelope_code'] as String? ?? '',
      acidNumber: json['acid_number'] as String? ?? '',
      manifestJson: json['manifest_json'] as Map<String, dynamic>? ?? {},
      exportedAt: json['exported_at'] != null ? DateTime.parse(json['exported_at']) : DateTime.now(),
      formattedSummary: json['formatted_summary'] as String? ?? '',
    );
  }
}
