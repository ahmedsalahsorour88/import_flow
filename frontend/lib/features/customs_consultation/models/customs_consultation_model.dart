class ClearanceExpenseTypeModel {
  final int expenseId;
  final String expenseCode;
  final String nameAr;
  final String? nameEn;
  final String category;
  final String defaultUnit;
  final String defaultCurrency;
  final int displayOrder;
  final bool isActive;

  ClearanceExpenseTypeModel({
    required this.expenseId,
    required this.expenseCode,
    required this.nameAr,
    this.nameEn,
    required this.category,
    required this.defaultUnit,
    this.defaultCurrency = 'EGP',
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ClearanceExpenseTypeModel.fromJson(Map<String, dynamic> json) {
    return ClearanceExpenseTypeModel(
      expenseId: json['expense_id'] ?? 0,
      expenseCode: json['expense_code'] ?? '',
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'],
      category: json['category'] ?? 'Clearance Fees (أتعاب ومصاريف تخليص)',
      defaultUnit: json['default_unit'] ?? 'Per Invoice (لكل فاتورة)',
      defaultCurrency: json['default_currency'] ?? 'EGP',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'expense_code': expenseCode,
      'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      'category': category,
      'default_unit': defaultUnit,
      'default_currency': defaultCurrency,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}

class BrokerPriceListItemModel {
  final int? itemId;
  final int? priceListId;
  final int? expenseTypeId;
  final String expenseName;
  final String category;
  final String unitType;
  final double standardPrice;
  final String currency;
  final double? minPrice;
  final double? maxPrice;
  final String? notes;
  final bool isActive;

  BrokerPriceListItemModel({
    this.itemId,
    this.priceListId,
    this.expenseTypeId,
    required this.expenseName,
    required this.category,
    required this.unitType,
    required this.standardPrice,
    this.currency = 'EGP',
    this.minPrice,
    this.maxPrice,
    this.notes,
    this.isActive = true,
  });

  factory BrokerPriceListItemModel.fromJson(Map<String, dynamic> json) {
    return BrokerPriceListItemModel(
      itemId: json['item_id'],
      priceListId: json['price_list_id'],
      expenseTypeId: json['expense_type_id'],
      expenseName: json['expense_name'] ?? '',
      category: json['category'] ?? '',
      unitType: json['unit_type'] ?? 'Per Invoice',
      standardPrice: (json['standard_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (priceListId != null) 'price_list_id': priceListId,
      if (expenseTypeId != null) 'expense_type_id': expenseTypeId,
      'expense_name': expenseName,
      'category': category,
      'unit_type': unitType,
      'standard_price': standardPrice,
      'currency': currency,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }
}

class BrokerPriceListModel {
  final int priceListId;
  final String priceListCode;
  final String title;
  final int brokerId;
  final String brokerName;
  final String? portName;
  final String effectiveFrom;
  final String? effectiveTo;
  final int version;
  final bool isActive;
  final String? notes;
  final List<BrokerPriceListItemModel> items;

  BrokerPriceListModel({
    required this.priceListId,
    required this.priceListCode,
    required this.title,
    required this.brokerId,
    required this.brokerName,
    this.portName,
    required this.effectiveFrom,
    this.effectiveTo,
    this.version = 1,
    this.isActive = true,
    this.notes,
    this.items = const [],
  });

  factory BrokerPriceListModel.fromJson(Map<String, dynamic> json) {
    return BrokerPriceListModel(
      priceListId: json['price_list_id'] ?? 0,
      priceListCode: json['price_list_code'] ?? '',
      title: json['title'] ?? '',
      brokerId: json['broker_id'] ?? 0,
      brokerName: json['broker_name'] ?? '',
      portName: json['port_name'],
      effectiveFrom: json['effective_from'] ?? '',
      effectiveTo: json['effective_to'],
      version: json['version'] ?? 1,
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => BrokerPriceListItemModel.fromJson(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price_list_id': priceListId,
      'price_list_code': priceListCode,
      'title': title,
      'broker_id': brokerId,
      'broker_name': brokerName,
      if (portName != null) 'port_name': portName,
      'effective_from': effectiveFrom,
      if (effectiveTo != null) 'effective_to': effectiveTo,
      'version': version,
      'is_active': isActive,
      if (notes != null) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class CustomsBrokerQuoteItemModel {
  final int? quoteItemId;
  final int? consultationId;
  final int? expenseTypeId;
  final String expenseName;
  final String category;
  final String unitType;
  final double unitPrice;
  final String currency;
  final double qty;
  final bool isApplicable;
  final double totalAmount;
  final String? notes;

  CustomsBrokerQuoteItemModel({
    this.quoteItemId,
    this.consultationId,
    this.expenseTypeId,
    required this.expenseName,
    required this.category,
    this.unitType = 'Per Invoice',
    this.unitPrice = 0.0,
    this.currency = 'EGP',
    this.qty = 1.0,
    this.isApplicable = true,
    this.totalAmount = 0.0,
    this.notes,
  });

  factory CustomsBrokerQuoteItemModel.fromJson(Map<String, dynamic> json) {
    return CustomsBrokerQuoteItemModel(
      quoteItemId: json['quote_item_id'],
      consultationId: json['consultation_id'],
      expenseTypeId: json['expense_type_id'],
      expenseName: json['expense_name'] ?? '',
      category: json['category'] ?? '',
      unitType: json['unit_type'] ?? 'Per Invoice',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
      isApplicable: json['is_applicable'] ?? true,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (quoteItemId != null) 'quote_item_id': quoteItemId,
      if (consultationId != null) 'consultation_id': consultationId,
      if (expenseTypeId != null) 'expense_type_id': expenseTypeId,
      'expense_name': expenseName,
      'category': category,
      'unit_type': unitType,
      'unit_price': unitPrice,
      'currency': currency,
      'qty': qty,
      'is_applicable': isApplicable,
      'total_amount': totalAmount,
      if (notes != null) 'notes': notes,
    };
  }

  CustomsBrokerQuoteItemModel copyWith({
    int? quoteItemId,
    int? consultationId,
    int? expenseTypeId,
    String? expenseName,
    String? category,
    String? unitType,
    double? unitPrice,
    String? currency,
    double? qty,
    bool? isApplicable,
    double? totalAmount,
    String? notes,
  }) {
    return CustomsBrokerQuoteItemModel(
      quoteItemId: quoteItemId ?? this.quoteItemId,
      consultationId: consultationId ?? this.consultationId,
      expenseTypeId: expenseTypeId ?? this.expenseTypeId,
      expenseName: expenseName ?? this.expenseName,
      category: category ?? this.category,
      unitType: unitType ?? this.unitType,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
      qty: qty ?? this.qty,
      isApplicable: isApplicable ?? this.isApplicable,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
    );
  }
}

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
  final int? brokerPriceListId;
  final int? poId;
  final int? projectId;
  final String overallStatus; // Pending Review, In Progress, Action Required, Clearance Ready, Blocked
  final bool hasBlockingIssues;
  final double readinessPercentage;
  final double estimatedDutiesEgp;
  final double totalBrokerFeesEgp;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;
  final List<CustomsChecklistItemModel> checklistItems;
  final List<CustomsBrokerQuoteItemModel> brokerQuoteItems;
  final int totalDocumentsCount;
  final int approvedDocumentsCount;
  final int blockingIssuesCount;
  final int appliedBrokerItemsCount;

  CustomsConsultationModel({
    required this.consultationId,
    required this.consultationCode,
    required this.title,
    this.importFileId,
    required this.brokerId,
    required this.brokerName,
    this.brokerContactPerson,
    this.brokerPriceListId,
    this.poId,
    this.projectId,
    required this.overallStatus,
    this.hasBlockingIssues = false,
    this.readinessPercentage = 0.0,
    this.estimatedDutiesEgp = 0.0,
    this.totalBrokerFeesEgp = 0.0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
    this.checklistItems = const [],
    this.brokerQuoteItems = const [],
    this.totalDocumentsCount = 0,
    this.approvedDocumentsCount = 0,
    this.blockingIssuesCount = 0,
    this.appliedBrokerItemsCount = 0,
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
      brokerPriceListId: json['broker_price_list_id'],
      poId: json['po_id'],
      projectId: json['project_id'],
      overallStatus: json['overall_status'] ?? 'Pending Review',
      hasBlockingIssues: json['has_blocking_issues'] ?? false,
      readinessPercentage: (json['readiness_percentage'] as num?)?.toDouble() ?? 0.0,
      estimatedDutiesEgp: (json['estimated_duties_egp'] as num?)?.toDouble() ?? 0.0,
      totalBrokerFeesEgp: (json['total_broker_fees_egp'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
      checklistItems: (json['checklist_items'] as List<dynamic>?)
              ?.map((item) => CustomsChecklistItemModel.fromJson(item))
              .toList() ??
          [],
      brokerQuoteItems: (json['broker_quote_items'] as List<dynamic>?)
              ?.map((item) => CustomsBrokerQuoteItemModel.fromJson(item))
              .toList() ??
          [],
      totalDocumentsCount: json['total_documents_count'] ?? 0,
      approvedDocumentsCount: json['approved_documents_count'] ?? 0,
      blockingIssuesCount: json['blocking_issues_count'] ?? 0,
      appliedBrokerItemsCount: json['applied_broker_items_count'] ?? 0,
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
      if (brokerPriceListId != null) 'broker_price_list_id': brokerPriceListId,
      'po_id': poId,
      'project_id': projectId,
      'overall_status': overallStatus,
      'has_blocking_issues': hasBlockingIssues,
      'readiness_percentage': readinessPercentage,
      'estimated_duties_egp': estimatedDutiesEgp,
      'total_broker_fees_egp': totalBrokerFeesEgp,
      'notes': notes,
      'is_active': isActive,
      'checklist_items': checklistItems.map((item) => item.toJson()).toList(),
      'broker_quote_items': brokerQuoteItems.map((item) => item.toJson()).toList(),
    };
  }
}
