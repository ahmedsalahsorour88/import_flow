class CustomsChecklistItemModel {
  final int? itemId;
  final int? consultationId;
  final String documentType;
  final String? hsCode;
  final bool isRequired;
  final String requiredText; // '✓', 'حسب الحالة', 'لاحقاً', 'حسب Incoterm'
  final bool isBlockingShipment;
  final String responsibleParty;
  final String status; // Pending, Received, Verified, Approved, Rejected
  final String? receivedDate; // تاريخ العرض / الاستلام
  final String? verifiedDate; // تاريخ الموافقة النهائية (auto once approved)
  final String? regulatoryAgency;
  final String? remarks;
  final String? correctiveActionRequired;

  CustomsChecklistItemModel({
    this.itemId,
    this.consultationId,
    required this.documentType,
    this.hsCode,
    this.isRequired = true,
    this.requiredText = '✓',
    this.isBlockingShipment = true,
    this.responsibleParty = 'Customs Broker',
    this.status = 'Pending',
    this.receivedDate,
    this.verifiedDate,
    this.regulatoryAgency,
    this.remarks,
    this.correctiveActionRequired,
  });

  factory CustomsChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return CustomsChecklistItemModel(
      itemId: json['item_id'],
      consultationId: json['consultation_id'],
      documentType: json['document_type'] ?? '',
      hsCode: json['hs_code'],
      isRequired: json['is_required'] ?? true,
      requiredText: json['required_text'] ?? ((json['is_required'] ?? true) ? '✓' : 'حسب الحالة'),
      isBlockingShipment: json['is_blocking_shipment'] ?? true,
      responsibleParty: json['responsible_party'] ?? 'Customs Broker',
      status: json['status'] ?? 'Pending',
      receivedDate: json['received_date'],
      verifiedDate: json['verified_date'],
      regulatoryAgency: json['regulatory_agency'],
      remarks: json['remarks'],
      correctiveActionRequired: json['corrective_action_required'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (consultationId != null) 'consultation_id': consultationId,
      'document_type': documentType,
      'hs_code': hsCode,
      'is_required': isRequired,
      'required_text': requiredText,
      'is_blocking_shipment': isBlockingShipment,
      'responsible_party': responsibleParty,
      'status': status,
      'received_date': receivedDate,
      'verified_date': verifiedDate,
      'regulatory_agency': regulatoryAgency,
      'remarks': remarks,
      'corrective_action_required': correctiveActionRequired,
    };
  }

  CustomsChecklistItemModel copyWith({
    int? itemId,
    int? consultationId,
    String? documentType,
    String? hsCode,
    bool? isRequired,
    String? requiredText,
    bool? isBlockingShipment,
    String? responsibleParty,
    String? status,
    String? receivedDate,
    String? verifiedDate,
    String? regulatoryAgency,
    String? remarks,
    String? correctiveActionRequired,
  }) {
    return CustomsChecklistItemModel(
      itemId: itemId ?? this.itemId,
      consultationId: consultationId ?? this.consultationId,
      documentType: documentType ?? this.documentType,
      hsCode: hsCode ?? this.hsCode,
      isRequired: isRequired ?? this.isRequired,
      requiredText: requiredText ?? this.requiredText,
      isBlockingShipment: isBlockingShipment ?? this.isBlockingShipment,
      responsibleParty: responsibleParty ?? this.responsibleParty,
      status: status ?? this.status,
      receivedDate: receivedDate ?? this.receivedDate,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      regulatoryAgency: regulatoryAgency ?? this.regulatoryAgency,
      remarks: remarks ?? this.remarks,
      correctiveActionRequired: correctiveActionRequired ?? this.correctiveActionRequired,
    );
  }
}

class CustomsConsultationModel {
  final int consultationId;
  final String consultationCode;
  final String title;
  final int? importFileId;
  final int brokerId;
  final String brokerName;
  final String? brokerContactPerson;
  final int? poId;
  final int? projectId;
  final String overallStatus; // Pending Review, In Progress, Action Required, Clearance Ready, Blocked
  final bool hasBlockingIssues;
  final double readinessPercentage;
  final double estimatedDutiesEgp;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;
  final List<CustomsChecklistItemModel> checklistItems;
  final int totalDocumentsCount;
  final int approvedDocumentsCount;
  final int blockingIssuesCount;

  CustomsConsultationModel({
    required this.consultationId,
    required this.consultationCode,
    required this.title,
    this.importFileId,
    required this.brokerId,
    required this.brokerName,
    this.brokerContactPerson,
    this.poId,
    this.projectId,
    required this.overallStatus,
    this.hasBlockingIssues = false,
    this.readinessPercentage = 0.0,
    this.estimatedDutiesEgp = 0.0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
    this.checklistItems = const [],
    this.totalDocumentsCount = 0,
    this.approvedDocumentsCount = 0,
    this.blockingIssuesCount = 0,
  });

  factory CustomsConsultationModel.fromJson(Map<String, dynamic> json) {
    return CustomsConsultationModel(
      consultationId: json['consultation_id'],
      consultationCode: json['consultation_code'] ?? '',
      title: json['title'] ?? '',
      importFileId: json['import_file_id'],
      brokerId: json['broker_id'],
      brokerName: json['broker_name'] ?? '',
      brokerContactPerson: json['broker_contact_person'],
      poId: json['po_id'],
      projectId: json['project_id'],
      overallStatus: json['overall_status'] ?? 'Pending Review',
      hasBlockingIssues: json['has_blocking_issues'] ?? false,
      readinessPercentage: (json['readiness_percentage'] as num?)?.toDouble() ?? 0.0,
      estimatedDutiesEgp: (json['estimated_duties_egp'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
      checklistItems: (json['checklist_items'] as List<dynamic>?)
              ?.map((item) => CustomsChecklistItemModel.fromJson(item))
              .toList() ??
          [],
      totalDocumentsCount: json['total_documents_count'] ?? 0,
      approvedDocumentsCount: json['approved_documents_count'] ?? 0,
      blockingIssuesCount: json['blocking_issues_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_id': consultationId,
      'consultation_code': consultationCode,
      'title': title,
      if (importFileId != null) 'import_file_id': importFileId,
      'broker_id': brokerId,
      'broker_name': brokerName,
      'broker_contact_person': brokerContactPerson,
      'po_id': poId,
      'project_id': projectId,
      'overall_status': overallStatus,
      'has_blocking_issues': hasBlockingIssues,
      'readiness_percentage': readinessPercentage,
      'estimated_duties_egp': estimatedDutiesEgp,
      'notes': notes,
      'is_active': isActive,
      'checklist_items': checklistItems.map((item) => item.toJson()).toList(),
    };
  }
}
