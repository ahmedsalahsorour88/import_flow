class SimilarShipmentModel {
  final int importFileId;
  final String importFileCode;
  final String? supplierName;
  final String? portOfDischarge;
  final String? hsCode;
  final String? productCategory;
  final String? shippingLine;
  final String? status;
  final int? customsExecutionDays;
  final double? landedCostTotal;
  final double? costVariancePct;
  final String? notes;
  final List<String> matchedAttributes;

  SimilarShipmentModel({
    required this.importFileId,
    required this.importFileCode,
    this.supplierName,
    this.portOfDischarge,
    this.hsCode,
    this.productCategory,
    this.shippingLine,
    this.status,
    this.customsExecutionDays,
    this.landedCostTotal,
    this.costVariancePct,
    this.notes,
    this.matchedAttributes = const [],
  });

  factory SimilarShipmentModel.fromJson(Map<String, dynamic> json) {
    var rawMatched = json['matched_attributes'] as List<dynamic>? ?? [];
    return SimilarShipmentModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      supplierName: json['supplier_name'],
      portOfDischarge: json['port_of_discharge'],
      hsCode: json['hs_code'],
      productCategory: json['product_category'],
      shippingLine: json['shipping_line'],
      status: json['status'],
      customsExecutionDays: json['customs_execution_days'],
      landedCostTotal: (json['landed_cost_total'] as num?)?.toDouble(),
      costVariancePct: (json['cost_variance_pct'] as num?)?.toDouble(),
      notes: json['notes'],
      matchedAttributes: rawMatched.map((m) => m.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'supplier_name': supplierName,
      'port_of_discharge': portOfDischarge,
      'hs_code': hsCode,
      'product_category': productCategory,
      'shipping_line': shippingLine,
      'status': status,
      'customs_execution_days': customsExecutionDays,
      'landed_cost_total': landedCostTotal,
      'cost_variance_pct': costVariancePct,
      'notes': notes,
      'matched_attributes': matchedAttributes,
    };
  }
}
