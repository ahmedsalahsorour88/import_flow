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
    final l = (json['length'] as num?)?.toDouble() ?? (json['length_cm'] as num?)?.toDouble() ?? 100.0;
    final w = (json['width'] as num?)?.toDouble() ?? (json['width_cm'] as num?)?.toDouble() ?? 80.0;
    final h = (json['height'] as num?)?.toDouble() ?? (json['height_cm'] as num?)?.toDouble() ?? 60.0;

    return CBMItemModel(
      itemId: json['item_id'],
      calcId: json['calc_id'],
      packageType: json['package_type'] ?? 'Carton',
      quantity: json['quantity'] ?? 1,
      length: l,
      width: w,
      height: h,
      unit: u,
      grossWeightPerUnitKg: (json['gross_weight_per_unit_kg'] as num?)?.toDouble() ?? 0.0,
      totalCbm: (json['total_cbm'] as num?)?.toDouble() ?? 0.0,
      volumetricWeightKg: (json['volumetric_weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalGrossWeightKg: (json['total_gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
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
  final String? projectName;
  final String? poNumber;
  final List<CBMItemModel> items;

  CBMCalculationModel({
    this.calcId,
    required this.calcCode,
    this.title,
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
    this.projectName,
    this.poNumber,
    this.items = const [],
  });

  factory CBMCalculationModel.fromJson(Map<String, dynamic> json) {
    return CBMCalculationModel(
      calcId: json['calc_id'],
      calcCode: json['calc_code'] ?? '',
      title: json['title'],
      projectId: json['project_id'],
      poId: json['po_id'],
      totalQty: json['total_qty'] ?? 0,
      totalCbm: (json['total_cbm'] as num?)?.toDouble() ?? 0.0,
      totalGrossWeightKg: (json['total_gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalVolumetricWeightKg: (json['total_volumetric_weight_kg'] as num?)?.toDouble() ?? 0.0,
      airChargeableWeightKg: (json['air_chargeable_weight_kg'] as num?)?.toDouble() ?? 0.0,
      recommendedShippingMethod: json['recommended_shipping_method'],
      recommendedContainerType: json['recommended_container_type'],
      recommendedContainerCount: json['recommended_container_count'] ?? 0,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
      'project_id': projectId,
      'po_id': poId,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      if (projectId != null) 'project_id': projectId,
      if (poId != null) 'po_id': poId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'items': items.map((i) => i.toCreateJson()).toList(),
    };
  }
}
