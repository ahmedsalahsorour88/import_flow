class ExpenseInvoiceModel {
  final String invoiceNo;
  final String category;
  final String providerName;
  final String currency;
  final double amountFx;
  final double exchangeRate;
  final double amountEgp;
  final String allocationRule;

  ExpenseInvoiceModel({
    required this.invoiceNo,
    this.category = 'Freight',
    required this.providerName,
    this.currency = 'USD',
    this.amountFx = 0.0,
    this.exchangeRate = 50.0,
    this.amountEgp = 0.0,
    this.allocationRule = 'Value-Based',
  });

  factory ExpenseInvoiceModel.fromJson(Map<String, dynamic> json) {
    final fx = (json['amount_fx'] as num?)?.toDouble() ?? 0.0;
    final rate = (json['exchange_rate'] as num?)?.toDouble() ?? 1.0;
    final egp = (json['amount_egp'] as num?)?.toDouble() ?? (fx * rate);

    return ExpenseInvoiceModel(
      invoiceNo: json['invoice_no'] ?? '',
      category: json['category'] ?? 'Freight',
      providerName: json['provider_name'] ?? '',
      currency: json['currency'] ?? 'USD',
      amountFx: fx,
      exchangeRate: rate,
      amountEgp: egp,
      allocationRule: json['allocation_rule'] ?? 'Value-Based',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_no': invoiceNo,
      'category': category,
      'provider_name': providerName,
      'currency': currency,
      'amount_fx': amountFx,
      'exchange_rate': exchangeRate,
      'amount_egp': amountEgp,
      'allocation_rule': allocationRule,
    };
  }
}

class ItemLandedCostModel {
  final String itemCode;
  final String itemName;
  final int qty;
  final double grossWeightKg;
  final double cbm;
  final double fobUnitEgp;
  final double fobTotalEgp;
  final double allocatedFreightEgp;
  final double allocatedCustomsEgp;
  final double allocatedClearanceEgp;
  final double allocatedTransportEgp;
  final double allocatedOtherEgp;
  final double totalLandedCostEgp;
  final double unitLandedCostEgp;
  final double markupFactor;

  ItemLandedCostModel({
    required this.itemCode,
    required this.itemName,
    this.qty = 1,
    this.grossWeightKg = 0.0,
    this.cbm = 0.0,
    this.fobUnitEgp = 0.0,
    this.fobTotalEgp = 0.0,
    this.allocatedFreightEgp = 0.0,
    this.allocatedCustomsEgp = 0.0,
    this.allocatedClearanceEgp = 0.0,
    this.allocatedTransportEgp = 0.0,
    this.allocatedOtherEgp = 0.0,
    this.totalLandedCostEgp = 0.0,
    this.unitLandedCostEgp = 0.0,
    this.markupFactor = 1.0,
  });

  factory ItemLandedCostModel.fromJson(Map<String, dynamic> json) {
    return ItemLandedCostModel(
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      cbm: (json['cbm'] as num?)?.toDouble() ?? 0.0,
      fobUnitEgp: (json['fob_unit_egp'] as num?)?.toDouble() ?? 0.0,
      fobTotalEgp: (json['fob_total_egp'] as num?)?.toDouble() ?? 0.0,
      allocatedFreightEgp: (json['allocated_freight_egp'] as num?)?.toDouble() ?? 0.0,
      allocatedCustomsEgp: (json['allocated_customs_egp'] as num?)?.toDouble() ?? 0.0,
      allocatedClearanceEgp: (json['allocated_clearance_egp'] as num?)?.toDouble() ?? 0.0,
      allocatedTransportEgp: (json['allocated_transport_egp'] as num?)?.toDouble() ?? 0.0,
      allocatedOtherEgp: (json['allocated_other_egp'] as num?)?.toDouble() ?? 0.0,
      totalLandedCostEgp: (json['total_landed_cost_egp'] as num?)?.toDouble() ?? 0.0,
      unitLandedCostEgp: (json['unit_landed_cost_egp'] as num?)?.toDouble() ?? 0.0,
      markupFactor: (json['markup_factor'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'qty': qty,
      'gross_weight_kg': grossWeightKg,
      'cbm': cbm,
      'fob_unit_egp': fobUnitEgp,
      'fob_total_egp': fobTotalEgp,
      'allocated_freight_egp': allocatedFreightEgp,
      'allocated_customs_egp': allocatedCustomsEgp,
      'allocated_clearance_egp': allocatedClearanceEgp,
      'allocated_transport_egp': allocatedTransportEgp,
      'allocated_other_egp': allocatedOtherEgp,
      'total_landed_cost_egp': totalLandedCostEgp,
      'unit_landed_cost_egp': unitLandedCostEgp,
      'markup_factor': markupFactor,
    };
  }
}

class LandedCostSettlementModel {
  final int settlementId;
  final String settlementCode;
  final int importFileId;
  final List<ExpenseInvoiceModel> expenseInvoices;
  final double totalFobEgp;
  final double totalExpensesEgp;
  final double totalLandedCostEgp;
  final double averageMarkupFactor;
  final List<ItemLandedCostModel> itemLandedCosts;
  final String status;
  final String accountantName;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  LandedCostSettlementModel({
    required this.settlementId,
    required this.settlementCode,
    required this.importFileId,
    this.expenseInvoices = const [],
    this.totalFobEgp = 0.0,
    this.totalExpensesEgp = 0.0,
    this.totalLandedCostEgp = 0.0,
    this.averageMarkupFactor = 1.0,
    this.itemLandedCosts = const [],
    this.status = 'Draft',
    this.accountantName = 'Kamal',
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LandedCostSettlementModel.fromJson(Map<String, dynamic> json) {
    var rawExpenses = json['expense_invoices'] as List<dynamic>? ?? [];
    var rawItems = json['item_landed_costs'] as List<dynamic>? ?? [];

    return LandedCostSettlementModel(
      settlementId: json['settlement_id'],
      settlementCode: json['settlement_code'] ?? '',
      importFileId: json['import_file_id'],
      expenseInvoices: rawExpenses.map((e) => ExpenseInvoiceModel.fromJson(e)).toList(),
      totalFobEgp: (json['total_fob_egp'] as num?)?.toDouble() ?? 0.0,
      totalExpensesEgp: (json['total_expenses_egp'] as num?)?.toDouble() ?? 0.0,
      totalLandedCostEgp: (json['total_landed_cost_egp'] as num?)?.toDouble() ?? 0.0,
      averageMarkupFactor: (json['average_markup_factor'] as num?)?.toDouble() ?? 1.0,
      itemLandedCosts: rawItems.map((i) => ItemLandedCostModel.fromJson(i)).toList(),
      status: json['status'] ?? 'Draft',
      accountantName: json['accountant_name'] ?? 'Kamal',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settlement_id': settlementId,
      'settlement_code': settlementCode,
      'import_file_id': importFileId,
      'expense_invoices': expenseInvoices.map((e) => e.toJson()).toList(),
      'total_fob_egp': totalFobEgp,
      'total_expenses_egp': totalExpensesEgp,
      'total_landed_cost_egp': totalLandedCostEgp,
      'average_markup_factor': averageMarkupFactor,
      'item_landed_costs': itemLandedCosts.map((i) => i.toJson()).toList(),
      'status': status,
      'accountant_name': accountantName,
      'notes': notes,
    };
  }
}
