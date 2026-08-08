double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

double? _numToNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int _numToInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

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
      itemId: _numToInt(json['item_id']),
      poId: _numToInt(json['po_id']),
      itemCode: json['item_code'] as String?,
      descriptionAr: json['description_ar'] as String? ?? '',
      descriptionEn: json['description_en'] as String?,
      tariffId: json['tariff_id'] != null ? _numToInt(json['tariff_id']) : null,
      quantity: _numToDouble(json['quantity'], 1.0),
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'PCS',
      unitPrice: _numToDouble(json['unit_price']),
      totalPrice: _numToDouble(json['total_price']),
      cbmPerUnit: _numToDouble(json['cbm_per_unit']),
      totalCbm: _numToDouble(json['total_cbm']),
      grossWeightKg: _numToDouble(json['gross_weight_kg']),
      netWeightKg: _numToDouble(json['net_weight_kg']),
      hsCode: json['hs_code'] as String?,
      dutyRate: _numToNullableDouble(json['duty_rate']),
      vatRate: _numToNullableDouble(json['vat_rate']),
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

class PackingListItemModel {
  final int? packingItemId;
  final int? poId;
  final String hsCode;
  final String itemCode;
  final double qtyPcs;
  final double qtyPkg;
  final String packageType;
  final String unit; // 'cm', 'mm', 'm'
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final double netWeightUnitKg;
  final double grossWeightUnitKg;
  final double totalNetWeightKg;
  final double totalGrossWeightKg;
  final double totalCbm;
  final double chargeableWeightKg;

  PackingListItemModel({
    this.packingItemId,
    this.poId,
    required this.hsCode,
    required this.itemCode,
    this.qtyPcs = 1.0,
    this.qtyPkg = 1.0,
    this.packageType = 'Carton',
    this.unit = 'cm',
    this.lengthCm = 0.0,
    this.widthCm = 0.0,
    this.heightCm = 0.0,
    this.netWeightUnitKg = 0.0,
    this.grossWeightUnitKg = 0.0,
    this.totalNetWeightKg = 0.0,
    this.totalGrossWeightKg = 0.0,
    this.totalCbm = 0.0,
    this.chargeableWeightKg = 0.0,
  });

  double get lengthM => unit == 'mm' ? lengthCm / 1000.0 : (unit == 'm' ? lengthCm : lengthCm / 100.0);
  double get widthM => unit == 'mm' ? widthCm / 1000.0 : (unit == 'm' ? widthCm : widthCm / 100.0);
  double get heightM => unit == 'mm' ? heightCm / 1000.0 : (unit == 'm' ? heightCm : heightCm / 100.0);

  double get calculatedCbm {
    if (lengthM <= 0 || widthM <= 0 || heightM <= 0) return 0.0;
    return qtyPkg * (lengthM * widthM * heightM);
  }

  factory PackingListItemModel.fromJson(Map<String, dynamic> json) {
    return PackingListItemModel(
      packingItemId: _numToInt(json['packing_item_id']),
      poId: _numToInt(json['po_id']),
      hsCode: json['hs_code'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      qtyPcs: _numToDouble(json['qty_pcs'], 1.0),
      qtyPkg: _numToDouble(json['qty_pkg'], 1.0),
      packageType: json['package_type'] as String? ?? 'Carton',
      unit: json['unit'] as String? ?? 'cm',
      lengthCm: _numToDouble(json['length_cm']),
      widthCm: _numToDouble(json['width_cm']),
      heightCm: _numToDouble(json['height_cm']),
      netWeightUnitKg: _numToDouble(json['net_weight_unit_kg']),
      grossWeightUnitKg: _numToDouble(json['gross_weight_unit_kg']),
      totalNetWeightKg: _numToDouble(json['total_net_weight_kg']),
      totalGrossWeightKg: _numToDouble(json['total_gross_weight_kg']),
      totalCbm: _numToDouble(json['total_cbm']),
      chargeableWeightKg: _numToDouble(json['chargeable_weight_kg']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (packingItemId != null) 'packing_item_id': packingItemId,
      if (poId != null) 'po_id': poId,
      'hs_code': hsCode,
      'item_code': itemCode,
      'qty_pcs': qtyPcs,
      'qty_pkg': qtyPkg,
      'package_type': packageType,
      'unit': unit,
      'length_cm': lengthCm,
      'width_cm': widthCm,
      'height_cm': heightCm,
      'net_weight_unit_kg': netWeightUnitKg,
      'gross_weight_unit_kg': grossWeightUnitKg,
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
  final List<PackingListItemModel> packingListItems;

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
    this.packingListItems = const [],
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      poId: json['po_id'] != null ? _numToInt(json['po_id']) : null,
      poNumber: json['po_number'] as String? ?? '',
      proformaInvoiceNumber: json['proforma_invoice_number'] as String?,
      projectId: _numToInt(json['project_id']),
      companyId: _numToInt(json['company_id']),
      supplierId: _numToInt(json['supplier_id']),
      incotermId: _numToInt(json['incoterm_id']),
      currencyId: _numToInt(json['currency_id']),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      exchangeRate: _numToDouble(json['exchange_rate'], 1.0),
      paymentTerms: json['payment_terms'] as String?,
      totalAmountFob: _numToDouble(json['total_amount_fob']),
      totalCbm: _numToDouble(json['total_cbm']),
      totalGrossWeightKg: _numToDouble(json['total_gross_weight_kg']),
      totalNetWeightKg: _numToDouble(json['total_net_weight_kg']),
      totalPackagesCount: _numToInt(json['total_packages_count']),
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
      packingListItems: json['packing_list_items'] != null
          ? (json['packing_list_items'] as List).map((i) => PackingListItemModel.fromJson(i as Map<String, dynamic>)).toList()
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
      'packing_list_items': packingListItems.map((i) => i.toJson()).toList(),
    };
  }
}

