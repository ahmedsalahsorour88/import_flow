class POLineItemModel {
  final int? itemId;
  final int? poId;
  final String? itemCode;
  final String descriptionAr;
  final String? descriptionEn;
  final int? tariffId;
  final double quantity;
  final String unitOfMeasure;
  final double unitPrice;
  final double totalPrice;
  final double cbmPerUnit;
  final double totalCbm;
  final double grossWeightKg;
  final double netWeightKg;
  final String? hsCode;
  final double? dutyRate;
  final double? vatRate;

  POLineItemModel({
    this.itemId,
    this.poId,
    this.itemCode,
    required this.descriptionAr,
    this.descriptionEn,
    this.tariffId,
    this.quantity = 1.0,
    this.unitOfMeasure = 'PCS',
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.cbmPerUnit = 0.0,
    this.totalCbm = 0.0,
    this.grossWeightKg = 0.0,
    this.netWeightKg = 0.0,
    this.hsCode,
    this.dutyRate,
    this.vatRate,
  });

  factory POLineItemModel.fromJson(Map<String, dynamic> json) {
    return POLineItemModel(
      itemId: json['item_id'] as int?,
      poId: json['po_id'] as int?,
      itemCode: json['item_code'] as String?,
      descriptionAr: json['description_ar'] as String? ?? '',
      descriptionEn: json['description_en'] as String?,
      tariffId: json['tariff_id'] as int?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'PCS',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      cbmPerUnit: (json['cbm_per_unit'] as num?)?.toDouble() ?? 0.0,
      totalCbm: (json['total_cbm'] as num?)?.toDouble() ?? 0.0,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      netWeightKg: (json['net_weight_kg'] as num?)?.toDouble() ?? 0.0,
      hsCode: json['hs_code'] as String?,
      dutyRate: (json['duty_rate'] as num?)?.toDouble(),
      vatRate: (json['vat_rate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (poId != null) 'po_id': poId,
      if (itemCode != null) 'item_code': itemCode,
      'description_ar': descriptionAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (tariffId != null) 'tariff_id': tariffId,
      'quantity': quantity,
      'unit_of_measure': unitOfMeasure,
      'unit_price': unitPrice,
      'cbm_per_unit': cbmPerUnit,
      'gross_weight_kg': grossWeightKg,
      'net_weight_kg': netWeightKg,
    };
  }
}

class PurchaseOrderModel {
  final int? poId;
  final String poNumber;
  final String? proformaInvoiceNumber;
  final int projectId;
  final int companyId;
  final int supplierId;
  final int incotermId;
  final int currencyId;
  final DateTime? expectedDeliveryDate;
  final double exchangeRate;
  final String? paymentTerms;
  final double totalAmountFob;
  final double totalCbm;
  final double totalGrossWeightKg;
  final double totalNetWeightKg;
  final int totalPackagesCount;
  final String status;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? projectName;
  final String? companyName;
  final String? supplierName;
  final String? incotermCode;
  final String? currencyCode;
  final List<POLineItemModel> items;

  PurchaseOrderModel({
    this.poId,
    required this.poNumber,
    this.proformaInvoiceNumber,
    required this.projectId,
    required this.companyId,
    required this.supplierId,
    required this.incotermId,
    required this.currencyId,
    this.expectedDeliveryDate,
    this.exchangeRate = 1.0,
    this.paymentTerms = 'LC at Sight / اعتماد مستندي',
    this.totalAmountFob = 0.0,
    this.totalCbm = 0.0,
    this.totalGrossWeightKg = 0.0,
    this.totalNetWeightKg = 0.0,
    this.totalPackagesCount = 0,
    this.status = 'Draft',
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.projectName,
    this.companyName,
    this.supplierName,
    this.incotermCode,
    this.currencyCode,
    this.items = const [],
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      poId: json['po_id'] as int?,
      poNumber: json['po_number'] as String? ?? '',
      proformaInvoiceNumber: json['proforma_invoice_number'] as String?,
      projectId: json['project_id'] as int? ?? 0,
      companyId: json['company_id'] as int? ?? 0,
      supplierId: json['supplier_id'] as int? ?? 0,
      incotermId: json['incoterm_id'] as int? ?? 0,
      currencyId: json['currency_id'] as int? ?? 0,
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 1.0,
      paymentTerms: json['payment_terms'] as String?,
      totalAmountFob: (json['total_amount_fob'] as num?)?.toDouble() ?? 0.0,
      totalCbm: (json['total_cbm'] as num?)?.toDouble() ?? 0.0,
      totalGrossWeightKg: (json['total_gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalNetWeightKg: (json['total_net_weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalPackagesCount: json['total_packages_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'Draft',
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      projectName: json['project_name'] as String?,
      companyName: json['company_name'] as String?,
      supplierName: json['supplier_name'] as String?,
      incotermCode: json['incoterm_code'] as String?,
      currencyCode: json['currency_code'] as String?,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => POLineItemModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (poId != null) 'po_id': poId,
      if (poNumber.isNotEmpty) 'po_number': poNumber,
      if (proformaInvoiceNumber != null) 'proforma_invoice_number': proformaInvoiceNumber,
      'project_id': projectId,
      'company_id': companyId,
      'supplier_id': supplierId,
      'incoterm_id': incotermId,
      'currency_id': currencyId,
      if (expectedDeliveryDate != null) 'expected_delivery_date': expectedDeliveryDate!.toIso8601String(),
      'exchange_rate': exchangeRate,
      if (paymentTerms != null) 'payment_terms': paymentTerms,
      'status': status,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
