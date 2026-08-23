class GitLineItemModel {
  final int importFileId;
  final String importFileCode;
  final int poId;
  final String poNumber;
  final String itemCode;
  final String itemName;
  final double invoicedQty;
  final int packagesCount;
  final String packageType;
  final int containersCount;
  final String containerType;
  final String certifiedDate;
  final bool isDeliveredToWarehouse;

  GitLineItemModel({
    required this.importFileId,
    required this.importFileCode,
    required this.poId,
    required this.poNumber,
    required this.itemCode,
    required this.itemName,
    required this.invoicedQty,
    this.packagesCount = 0,
    this.packageType = 'CT - Carton',
    this.containersCount = 1,
    this.containerType = '40ft High Cube',
    required this.certifiedDate,
    this.isDeliveredToWarehouse = false,
  });

  factory GitLineItemModel.fromJson(Map<String, dynamic> json) {
    return GitLineItemModel(
      importFileId: json['import_file_id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String? ?? '',
      poId: json['po_id'] as int? ?? 0,
      poNumber: json['po_number'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      invoicedQty: (json['invoiced_qty'] as num?)?.toDouble() ?? 0.0,
      packagesCount: json['packages_count'] as int? ?? 0,
      packageType: json['package_type'] as String? ?? 'CT - Carton',
      containersCount: json['containers_count'] as int? ?? 1,
      containerType: json['container_type'] as String? ?? '40ft High Cube',
      certifiedDate: json['certified_date'] as String? ?? '',
      isDeliveredToWarehouse: json['is_delivered_to_warehouse'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'po_id': poId,
      'po_number': poNumber,
      'item_code': itemCode,
      'item_name': itemName,
      'invoiced_qty': invoicedQty,
      'packages_count': packagesCount,
      'package_type': packageType,
      'containers_count': containersCount,
      'container_type': containerType,
      'certified_date': certifiedDate,
      'is_delivered_to_warehouse': isDeliveredToWarehouse,
    };
  }

  GitLineItemModel copyWith({
    int? importFileId,
    String? importFileCode,
    int? poId,
    String? poNumber,
    String? itemCode,
    String? itemName,
    double? invoicedQty,
    int? packagesCount,
    String? packageType,
    int? containersCount,
    String? containerType,
    String? certifiedDate,
    bool? isDeliveredToWarehouse,
  }) {
    return GitLineItemModel(
      importFileId: importFileId ?? this.importFileId,
      importFileCode: importFileCode ?? this.importFileCode,
      poId: poId ?? this.poId,
      poNumber: poNumber ?? this.poNumber,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      invoicedQty: invoicedQty ?? this.invoicedQty,
      packagesCount: packagesCount ?? this.packagesCount,
      packageType: packageType ?? this.packageType,
      containersCount: containersCount ?? this.containersCount,
      containerType: containerType ?? this.containerType,
      certifiedDate: certifiedDate ?? this.certifiedDate,
      isDeliveredToWarehouse: isDeliveredToWarehouse ?? this.isDeliveredToWarehouse,
    );
  }
}
