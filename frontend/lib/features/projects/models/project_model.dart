class ProjectModel {
  final int? projectId;
  final String projectCode;
  final String projectName;
  final String projectOwner;
  final int companyId;
  final List<int> companyIds;
  final int supplierId;
  final int incotermId;
  final String importType;
  final String priority;
  final String shipmentCategory;
  final bool allowMultiShipment;
  final bool allowMultiCompany;
  final double? totalBudgetUsd;
  final String status;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? companyName;
  final String? supplierName;
  final String? incotermCode;

  ProjectModel({
    this.projectId,
    required this.projectCode,
    required this.projectName,
    required this.projectOwner,
    required this.companyId,
    this.companyIds = const [],
    required this.supplierId,
    required this.incotermId,
    this.importType = 'Direct Commercial',
    this.priority = 'Medium',
    this.shipmentCategory = 'FCL Container',
    this.allowMultiShipment = true,
    this.allowMultiCompany = true,
    this.totalBudgetUsd,
    this.status = 'Open',
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.companyName,
    this.supplierName,
    this.incotermCode,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    List<int> cIds = [];
    if (json['company_ids'] != null && json['company_ids'] is List) {
      cIds = (json['company_ids'] as List).map((e) => e as int).toList();
    } else if (json['company_id'] != null) {
      cIds = [json['company_id'] as int];
    }

    return ProjectModel(
      projectId: json['project_id'] as int?,
      projectCode: json['project_code'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      projectOwner: json['project_owner'] as String? ?? '',
      companyId: json['company_id'] as int? ?? 0,
      companyIds: cIds,
      supplierId: json['supplier_id'] as int? ?? 0,
      incotermId: json['incoterm_id'] as int? ?? 0,
      importType: json['import_type'] as String? ?? 'Direct Commercial',
      priority: json['priority'] as String? ?? 'Medium',
      shipmentCategory: json['shipment_category'] as String? ?? 'FCL Container',
      allowMultiShipment: json['allow_multi_shipment'] as bool? ?? true,
      allowMultiCompany: json['allow_multi_company'] as bool? ?? true,
      totalBudgetUsd: (json['total_budget_usd'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Open',
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      companyName: json['company_name'] as String?,
      supplierName: json['supplier_name'] as String?,
      incotermCode: json['incoterm_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (projectId != null) 'project_id': projectId,
      if (projectCode.isNotEmpty) 'project_code': projectCode,
      'project_name': projectName,
      'project_owner': projectOwner,
      'company_id': companyIds.isNotEmpty ? companyIds.first : companyId,
      'company_ids': companyIds,
      'supplier_id': supplierId,
      'incoterm_id': incotermId,
      'import_type': importType,
      'priority': priority,
      'shipment_category': shipmentCategory,
      'allow_multi_shipment': allowMultiShipment,
      'allow_multi_company': allowMultiCompany,
      if (totalBudgetUsd != null) 'total_budget_usd': totalBudgetUsd,
      'status': status,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }
}
