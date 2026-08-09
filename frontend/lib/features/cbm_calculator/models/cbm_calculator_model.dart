double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

int _numToInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

class CBMItemModel {
  final int? itemId;
  final int? calcId;
  final String packageType;
  final int quantity;
  final double length;
  final double width;
  final double height;
  final String unit; // mm, cm, m
  final double grossWeightPerUnitKg;
  final double totalCbm;
  final double volumetricWeightKg;
  final double totalGrossWeightKg;

  CBMItemModel({
    this.itemId,
    this.calcId,
    this.packageType = 'Carton',
    required this.quantity,
    required this.length,
    required this.width,
    required this.height,
    this.unit = 'cm',
    required this.grossWeightPerUnitKg,
    this.totalCbm = 0.0,
    this.volumetricWeightKg = 0.0,
    this.totalGrossWeightKg = 0.0,
  });

  double get lengthM => unit == 'mm' ? length / 1000.0 : (unit == 'cm' ? length / 100.0 : length);
  double get widthM => unit == 'mm' ? width / 1000.0 : (unit == 'cm' ? width / 100.0 : width);
  double get heightM => unit == 'mm' ? height / 1000.0 : (unit == 'cm' ? height / 100.0 : height);

  double get lengthCm => lengthM * 100.0;
  double get widthCm => widthM * 100.0;
  double get heightCm => heightM * 100.0;

  factory CBMItemModel.fromJson(Map<String, dynamic> json) {
    final u = json['unit']?.toString() ?? 'cm';
    final l = _numToDouble(json['length'], _numToDouble(json['length_cm'], 100.0));
    final w = _numToDouble(json['width'], _numToDouble(json['width_cm'], 80.0));
    final h = _numToDouble(json['height'], _numToDouble(json['height_cm'], 60.0));

    return CBMItemModel(
      itemId: json['item_id'] != null ? _numToInt(json['item_id']) : null,
      calcId: json['calc_id'] != null ? _numToInt(json['calc_id']) : null,
      packageType: json['package_type'] ?? 'Carton',
      quantity: _numToInt(json['quantity'], 1),
      length: l,
      width: w,
      height: h,
      unit: u,
      grossWeightPerUnitKg: _numToDouble(json['gross_weight_per_unit_kg']),
      totalCbm: _numToDouble(json['total_cbm']),
      volumetricWeightKg: _numToDouble(json['volumetric_weight_kg']),
      totalGrossWeightKg: _numToDouble(json['total_gross_weight_kg']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (calcId != null) 'calc_id': calcId,
      'package_type': packageType,
      'quantity': quantity,
      'length': length,
      'width': width,
      'height': height,
      'unit': unit,
      'length_cm': lengthCm,
      'width_cm': widthCm,
      'height_cm': heightCm,
      'gross_weight_per_unit_kg': grossWeightPerUnitKg,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'package_type': packageType,
      'quantity': quantity > 0 ? quantity : 1,
      'length': length > 0 ? length : 1.0,
      'width': width > 0 ? width : 1.0,
      'height': height > 0 ? height : 1.0,
      'unit': unit,
      'gross_weight_per_unit_kg': grossWeightPerUnitKg >= 0 ? grossWeightPerUnitKg : 0.0,
    };
  }
}

class CBMCalculationModel {
  final int? calcId;
  final String calcCode;
  final String? title;
  final int? importFileId;
  final int? projectId;
  final int? poId;
  final int totalQty;
  final double totalCbm;
  final double totalGrossWeightKg;
  final double totalVolumetricWeightKg;
  final double airChargeableWeightKg;
  final String? recommendedShippingMethod;
  final String? recommendedContainerType;
  final int recommendedContainerCount;
  final String? notes;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? importFileCode;
  final String? projectName;
  final String? poNumber;
  final List<CBMItemModel> items;

  CBMCalculationModel({
    this.calcId,
    required this.calcCode,
    this.title,
    this.importFileId,
    this.projectId,
    this.poId,
    this.totalQty = 0,
    this.totalCbm = 0.0,
    this.totalGrossWeightKg = 0.0,
    this.totalVolumetricWeightKg = 0.0,
    this.airChargeableWeightKg = 0.0,
    this.recommendedShippingMethod,
    this.recommendedContainerType,
    this.recommendedContainerCount = 0,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.importFileCode,
    this.projectName,
    this.poNumber,
    this.items = const [],
  });

  factory CBMCalculationModel.fromJson(Map<String, dynamic> json) {
    return CBMCalculationModel(
      calcId: json['calc_id'] != null ? _numToInt(json['calc_id']) : null,
      calcCode: json['calc_code'] ?? '',
      title: json['title'],
      importFileId: json['import_file_id'] != null ? _numToInt(json['import_file_id']) : null,
      projectId: json['project_id'] != null ? _numToInt(json['project_id']) : null,
      poId: json['po_id'] != null ? _numToInt(json['po_id']) : null,
      totalQty: _numToInt(json['total_qty']),
      totalCbm: _numToDouble(json['total_cbm']),
      totalGrossWeightKg: _numToDouble(json['total_gross_weight_kg']),
      totalVolumetricWeightKg: _numToDouble(json['total_volumetric_weight_kg']),
      airChargeableWeightKg: _numToDouble(json['air_chargeable_weight_kg']),
      recommendedShippingMethod: json['recommended_shipping_method'],
      recommendedContainerType: json['recommended_container_type'],
      recommendedContainerCount: _numToInt(json['recommended_container_count']),
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      importFileCode: json['import_file_code'],
      projectName: json['project_name'],
      poNumber: json['po_number'],
      items: json['items'] != null
          ? (json['items'] as List).map((i) => CBMItemModel.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (calcId != null) 'calc_id': calcId,
      'calc_code': calcCode,
      'title': title,
      if (importFileId != null) 'import_file_id': importFileId,
      'project_id': projectId,
      'po_id': poId,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      if (importFileId != null) 'import_file_id': importFileId,
      if (projectId != null) 'project_id': projectId,
      if (poId != null) 'po_id': poId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'items': items.map((i) => i.toCreateJson()).toList(),
    };
  }
}
