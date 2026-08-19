class LinkedPOItemModel {
  final int poId;
  final String poNumber;
  final String? piNumber;
  final int? projectId;
  final String? projectName;
  final String paymentTerms;
  final String currency;
  final double totalAmount;
  final String status;

  LinkedPOItemModel({
    required this.poId,
    required this.poNumber,
    this.piNumber,
    this.projectId,
    this.projectName,
    required this.paymentTerms,
    required this.currency,
    required this.totalAmount,
    required this.status,
  });

  factory LinkedPOItemModel.fromJson(Map<String, dynamic> json) {
    return LinkedPOItemModel(
      poId: json['po_id'] ?? 0,
      poNumber: json['po_number'] ?? '',
      piNumber: json['pi_number'],
      projectId: json['project_id'],
      projectName: json['project_name'],
      paymentTerms: json['payment_terms'] ?? 'Standard',
      currency: json['currency'] ?? 'USD',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'po_id': poId,
      'po_number': poNumber,
      'pi_number': piNumber,
      'project_id': projectId,
      'project_name': projectName,
      'payment_terms': paymentTerms,
      'currency': currency,
      'total_amount': totalAmount,
      'status': status,
    };
  }
}

class BudgetPrefillModel {
  final int importFileId;
  final String importFileCode;
  final String importFileTitle;
  final String incoterm;
  final int? supplierId;
  final String supplierName;
  final String? beneficiaryName;
  final String? bankName;
  final String? swiftCode;
  final String? accountNumber;
  final String? iban;
  final String paymentTermsSummary;
  final List<LinkedPOItemModel> linkedPos;
  final double totalInvoiceAmount;
  final String invoiceCurrency;
  final double totalInvoiceAmountEgp;
  final double estimatedFreightCost;
  final String freightCurrency;
  final double estimatedFreightCostEgp;
  final double estimatedCustomsDutiesEgp;
  final double estimatedClearanceFeesEgp;
  final double estimatedGrandTotalEgp;
  final double exchangeRate;

  BudgetPrefillModel({
    required this.importFileId,
    required this.importFileCode,
    required this.importFileTitle,
    required this.incoterm,
    this.supplierId,
    required this.supplierName,
    this.beneficiaryName,
    this.bankName,
    this.swiftCode,
    this.accountNumber,
    this.iban,
    required this.paymentTermsSummary,
    required this.linkedPos,
    required this.totalInvoiceAmount,
    this.invoiceCurrency = 'USD',
    required this.totalInvoiceAmountEgp,
    required this.estimatedFreightCost,
    this.freightCurrency = 'USD',
    required this.estimatedFreightCostEgp,
    required this.estimatedCustomsDutiesEgp,
    required this.estimatedClearanceFeesEgp,
    required this.estimatedGrandTotalEgp,
    this.exchangeRate = 50.0,
  });

  factory BudgetPrefillModel.fromJson(Map<String, dynamic> json) {
    final list = (json['linked_pos'] as List<dynamic>?)
            ?.map((p) => LinkedPOItemModel.fromJson(p))
            .toList() ??
        [];

    return BudgetPrefillModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      importFileTitle: json['import_file_title'] ?? '',
      incoterm: json['incoterm'] ?? 'FOB',
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'] ?? '',
      beneficiaryName: json['beneficiary_name'],
      bankName: json['bank_name'],
      swiftCode: json['swift_code'],
      accountNumber: json['account_number'],
      iban: json['iban'],
      paymentTermsSummary: json['payment_terms_summary'] ?? '',
      linkedPos: list,
      totalInvoiceAmount: (json['total_invoice_amount'] as num?)?.toDouble() ?? 0.0,
      invoiceCurrency: json['invoice_currency'] ?? 'USD',
      totalInvoiceAmountEgp: (json['total_invoice_amount_egp'] as num?)?.toDouble() ?? 0.0,
      estimatedFreightCost: (json['estimated_freight_cost'] as num?)?.toDouble() ?? 0.0,
      freightCurrency: json['freight_currency'] ?? 'USD',
      estimatedFreightCostEgp: (json['estimated_freight_cost_egp'] as num?)?.toDouble() ?? 0.0,
      estimatedCustomsDutiesEgp: (json['estimated_customs_duties_egp'] as num?)?.toDouble() ?? 0.0,
      estimatedClearanceFeesEgp: (json['estimated_clearance_fees_egp'] as num?)?.toDouble() ?? 0.0,
      estimatedGrandTotalEgp: (json['estimated_grand_total_egp'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 50.0,
    );
  }
}

class PaymentRequestModel {
  final int paymentId;
  final String paymentCode;
  final String title;
  final int? importFileId;
  final int? poId;
  final int? supplierId;
  final String supplierName;
  final int? projectId;
  final String paymentType;
  final double requestedAmount;
  final String currencyCode;
  final double exchangeRate;
  final double requestedAmountEgp;
  final String dueDate;
  final String requestDate;
  final String status;
  final String? beneficiaryName;
  final String? bankName;
  final String? swiftCode;
  final String? ibanAccountNo;
  final String? bankCountry;
  final String? swiftReferenceNo;
  final String? swiftReceiptDate;
  final double? swiftTransferredAmount;
  final String? swiftTransferredCurrency;
  final double? swiftVarianceAmount;
  final String? swiftVarianceStatus;
  final int? swiftProcessingDays;
  final String? swiftReconciliationNotes;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

  PaymentRequestModel({
    required this.paymentId,
    required this.paymentCode,
    required this.title,
    this.importFileId,
    this.poId,
    this.supplierId,
    required this.supplierName,
    this.projectId,
    required this.paymentType,
    required this.requestedAmount,
    this.currencyCode = 'USD',
    this.exchangeRate = 50.0,
    required this.requestedAmountEgp,
    required this.dueDate,
    required this.requestDate,
    required this.status,
    this.beneficiaryName,
    this.bankName,
    this.swiftCode,
    this.ibanAccountNo,
    this.bankCountry,
    this.swiftReferenceNo,
    this.swiftReceiptDate,
    this.swiftTransferredAmount,
    this.swiftTransferredCurrency,
    this.swiftVarianceAmount,
    this.swiftVarianceStatus,
    this.swiftProcessingDays,
    this.swiftReconciliationNotes,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return PaymentRequestModel(
      paymentId: json['payment_id'],
      paymentCode: json['payment_code'] ?? '',
      title: json['title'] ?? '',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'] ?? '',
      projectId: json['project_id'],
      paymentType: json['payment_type'] ?? 'Advance Payment',
      requestedAmount: (json['requested_amount'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currency_code'] ?? 'USD',
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 50.0,
      requestedAmountEgp: (json['requested_amount_egp'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] ?? '',
      requestDate: json['request_date'] ?? '',
      status: json['status'] ?? 'Draft',
      beneficiaryName: json['beneficiary_name'],
      bankName: json['bank_name'],
      swiftCode: json['swift_code'],
      ibanAccountNo: json['iban_account_no'],
      bankCountry: json['bank_country'],
      swiftReferenceNo: json['swift_reference_no'],
      swiftReceiptDate: json['swift_receipt_date'],
      swiftTransferredAmount: (json['swift_transferred_amount'] as num?)?.toDouble(),
      swiftTransferredCurrency: json['swift_transferred_currency'],
      swiftVarianceAmount: (json['swift_variance_amount'] as num?)?.toDouble(),
      swiftVarianceStatus: json['swift_variance_status'],
      swiftProcessingDays: json['swift_processing_days'],
      swiftReconciliationNotes: json['swift_reconciliation_notes'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'payment_code': paymentCode,
      'title': title,
      if (importFileId != null) 'import_file_id': importFileId,
      'po_id': poId,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'project_id': projectId,
      'payment_type': paymentType,
      'requested_amount': requestedAmount,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'requested_amount_egp': requestedAmountEgp,
      'due_date': dueDate,
      'request_date': requestDate,
      'status': status,
      'beneficiary_name': beneficiaryName,
      'bank_name': bankName,
      'swift_code': swiftCode,
      'iban_account_no': ibanAccountNo,
      'bank_country': bankCountry,
      'swift_reference_no': swiftReferenceNo,
      'swift_receipt_date': swiftReceiptDate,
      'swift_transferred_amount': swiftTransferredAmount,
      'swift_transferred_currency': swiftTransferredCurrency,
      'swift_variance_amount': swiftVarianceAmount,
      'swift_variance_status': swiftVarianceStatus,
      'swift_processing_days': swiftProcessingDays,
      'swift_reconciliation_notes': swiftReconciliationNotes,
      'notes': notes,
      'is_active': isActive,
    };
  }
}

class ImportBudgetModel {
  final int budgetId;
  final String budgetCode;
  final String title;
  final int? importFileId;
  final int? poId;
  final int? projectId;
  final double invoiceAmountEgp;
  final double invoiceAmountForeign;
  final String invoiceCurrency;
  final double freightCostEgp;
  final double freightCostForeign;
  final String freightCurrency;
  final double customsDutiesEgp;
  final double clearanceInlandEgp;
  final double exchangeRate;
  final double totalBudgetEgp;
  final String budgetStatus;
  final String? approvedBy;
  final String? approvedDate;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

  ImportBudgetModel({
    required this.budgetId,
    required this.budgetCode,
    required this.title,
    this.importFileId,
    this.poId,
    this.projectId,
    this.invoiceAmountEgp = 0.0,
    this.invoiceAmountForeign = 0.0,
    this.invoiceCurrency = 'USD',
    this.freightCostEgp = 0.0,
    this.freightCostForeign = 0.0,
    this.freightCurrency = 'USD',
    this.customsDutiesEgp = 0.0,
    this.clearanceInlandEgp = 0.0,
    this.exchangeRate = 50.0,
    required this.totalBudgetEgp,
    required this.budgetStatus,
    this.approvedBy,
    this.approvedDate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory ImportBudgetModel.fromJson(Map<String, dynamic> json) {
    return ImportBudgetModel(
      budgetId: json['budget_id'],
      budgetCode: json['budget_code'] ?? '',
      title: json['title'] ?? '',
      importFileId: json['import_file_id'],
      poId: json['po_id'],
      projectId: json['project_id'],
      invoiceAmountEgp: (json['invoice_amount_egp'] as num?)?.toDouble() ?? 0.0,
      invoiceAmountForeign: (json['invoice_amount_foreign'] as num?)?.toDouble() ?? 0.0,
      invoiceCurrency: json['invoice_currency'] ?? 'USD',
      freightCostEgp: (json['freight_cost_egp'] as num?)?.toDouble() ?? 0.0,
      freightCostForeign: (json['freight_cost_foreign'] as num?)?.toDouble() ?? 0.0,
      freightCurrency: json['freight_currency'] ?? 'USD',
      customsDutiesEgp: (json['customs_duties_egp'] as num?)?.toDouble() ?? 0.0,
      clearanceInlandEgp: (json['clearance_inland_egp'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 50.0,
      totalBudgetEgp: (json['total_budget_egp'] as num?)?.toDouble() ?? 0.0,
      budgetStatus: json['budget_status'] ?? 'Pending Review',
      approvedBy: json['approved_by'],
      approvedDate: json['approved_date'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget_id': budgetId,
      'budget_code': budgetCode,
      'title': title,
      if (importFileId != null) 'import_file_id': importFileId,
      'po_id': poId,
      'project_id': projectId,
      'invoice_amount_egp': invoiceAmountEgp,
      'invoice_amount_foreign': invoiceAmountForeign,
      'invoice_currency': invoiceCurrency,
      'freight_cost_egp': freightCostEgp,
      'freight_cost_foreign': freightCostForeign,
      'freight_currency': freightCurrency,
      'customs_duties_egp': customsDutiesEgp,
      'clearance_inland_egp': clearanceInlandEgp,
      'exchange_rate': exchangeRate,
      'total_budget_egp': totalBudgetEgp,
      'budget_status': budgetStatus,
      'approved_by': approvedBy,
      'approved_date': approvedDate,
      'notes': notes,
      'is_active': isActive,
    };
  }
}

class SmartSwiftExtractResultModel {
  final bool success;
  final Map<String, dynamic> parsedSwift;
  final Map<String, dynamic>? matchedPaymentRequest;
  final List<dynamic> candidateMatches;
  final String? rawText;
  final String? detectedFilename;
  final String? detectedFileType;
  final String? error;

  SmartSwiftExtractResultModel({
    required this.success,
    required this.parsedSwift,
    this.matchedPaymentRequest,
    this.candidateMatches = const [],
    this.rawText,
    this.detectedFilename,
    this.detectedFileType,
    this.error,
  });

  factory SmartSwiftExtractResultModel.fromJson(Map<String, dynamic> json) {
    return SmartSwiftExtractResultModel(
      success: json['success'] ?? false,
      parsedSwift: json['parsed_swift'] != null ? Map<String, dynamic>.from(json['parsed_swift']) : {},
      matchedPaymentRequest: json['matched_payment_request'] != null ? Map<String, dynamic>.from(json['matched_payment_request']) : null,
      candidateMatches: json['candidate_matches'] != null ? List<dynamic>.from(json['candidate_matches']) : [],
      rawText: json['raw_text'],
      detectedFilename: json['detected_filename'],
      detectedFileType: json['detected_file_type'],
      error: json['error'],
    );
  }
}
