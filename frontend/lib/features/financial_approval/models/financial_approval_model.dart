class PaymentRequestModel {
  final int paymentId;
  final String paymentCode;
  final String title;
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
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  PaymentRequestModel({
    required this.paymentId,
    required this.paymentCode,
    required this.title,
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
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return PaymentRequestModel(
      paymentId: json['payment_id'],
      paymentCode: json['payment_code'] ?? '',
      title: json['title'] ?? '',
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
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'payment_code': paymentCode,
      'title': title,
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
      'notes': notes,
      'is_active': isActive,
    };
  }
}

class ImportBudgetModel {
  final int budgetId;
  final String budgetCode;
  final String title;
  final int? poId;
  final int? projectId;
  final double invoiceAmountEgp;
  final double freightCostEgp;
  final double customsDutiesEgp;
  final double clearanceInlandEgp;
  final double totalBudgetEgp;
  final String budgetStatus;
  final String? approvedBy;
  final String? approvedDate;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  ImportBudgetModel({
    required this.budgetId,
    required this.budgetCode,
    required this.title,
    this.poId,
    this.projectId,
    this.invoiceAmountEgp = 0.0,
    this.freightCostEgp = 0.0,
    this.customsDutiesEgp = 0.0,
    this.clearanceInlandEgp = 0.0,
    required this.totalBudgetEgp,
    required this.budgetStatus,
    this.approvedBy,
    this.approvedDate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImportBudgetModel.fromJson(Map<String, dynamic> json) {
    return ImportBudgetModel(
      budgetId: json['budget_id'],
      budgetCode: json['budget_code'] ?? '',
      title: json['title'] ?? '',
      poId: json['po_id'],
      projectId: json['project_id'],
      invoiceAmountEgp: (json['invoice_amount_egp'] as num?)?.toDouble() ?? 0.0,
      freightCostEgp: (json['freight_cost_egp'] as num?)?.toDouble() ?? 0.0,
      customsDutiesEgp: (json['customs_duties_egp'] as num?)?.toDouble() ?? 0.0,
      clearanceInlandEgp: (json['clearance_inland_egp'] as num?)?.toDouble() ?? 0.0,
      totalBudgetEgp: (json['total_budget_egp'] as num?)?.toDouble() ?? 0.0,
      budgetStatus: json['budget_status'] ?? 'Pending Review',
      approvedBy: json['approved_by'],
      approvedDate: json['approved_date'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget_id': budgetId,
      'budget_code': budgetCode,
      'title': title,
      'po_id': poId,
      'project_id': projectId,
      'invoice_amount_egp': invoiceAmountEgp,
      'freight_cost_egp': freightCostEgp,
      'customs_duties_egp': customsDutiesEgp,
      'clearance_inland_egp': clearanceInlandEgp,
      'total_budget_egp': totalBudgetEgp,
      'budget_status': budgetStatus,
      'approved_by': approvedBy,
      'approved_date': approvedDate,
      'notes': notes,
      'is_active': isActive,
    };
  }
}
