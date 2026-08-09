class IncotermModel {
  final int incotermId;
  final String incotermCode;
  final String incotermName;
  final String version;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncotermModel({
    required this.incotermId,
    required this.incotermCode,
    required this.incotermName,
    required this.version,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncotermModel.fromJson(Map<String, dynamic> json) {
    return IncotermModel(
      incotermId: json['incoterm_id'] as int? ?? 0,
      incotermCode: json['incoterm_code']?.toString() ?? '',
      incotermName: json['incoterm_name']?.toString() ?? '',
      version: json['version']?.toString() ?? '2020',
      description: json['description']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'incoterm_id': incotermId,
        'incoterm_code': incotermCode,
        'incoterm_name': incotermName,
        'version': version,
        'description': description,
        'is_active': isActive,
      };
}

class CostItemModel {
  final int costItemId;
  final String costItemCode;
  final String costItemName;
  final String costCategory;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CostItemModel({
    required this.costItemId,
    required this.costItemCode,
    required this.costItemName,
    required this.costCategory,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CostItemModel.fromJson(Map<String, dynamic> json) {
    return CostItemModel(
      costItemId: json['cost_item_id'] as int? ?? 0,
      costItemCode: json['cost_item_code']?.toString() ?? '',
      costItemName: json['cost_item_name']?.toString() ?? '',
      costCategory: json['cost_category']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cost_item_id': costItemId,
        'cost_item_code': costItemCode,
        'cost_item_name': costItemName,
        'cost_category': costCategory,
        'description': description,
        'is_active': isActive,
      };
}

class IncotermResponsibilityModel {
  final int responsibilityId;
  final int incotermId;
  final int costItemId;
  final String responsibleParty;
  final bool includedInIncoterm;
  final String? notes;
  final String? incotermCode;
  final String? costItemName;
  final String? costCategory;

  const IncotermResponsibilityModel({
    required this.responsibilityId,
    required this.incotermId,
    required this.costItemId,
    required this.responsibleParty,
    required this.includedInIncoterm,
    this.notes,
    this.incotermCode,
    this.costItemName,
    this.costCategory,
  });

  factory IncotermResponsibilityModel.fromJson(Map<String, dynamic> json) {
    return IncotermResponsibilityModel(
      responsibilityId: json['responsibility_id'] as int,
      incotermId: json['incoterm_id'] as int,
      costItemId: json['cost_item_id'] as int,
      responsibleParty: json['responsible_party'] as String,
      includedInIncoterm: json['included_in_incoterm'] as bool,
      notes: json['notes'] as String?,
      incotermCode: json['incoterm_code'] as String?,
      costItemName: json['cost_item_name'] as String?,
      costCategory: json['cost_category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'responsibility_id': responsibilityId,
        'incoterm_id': incotermId,
        'cost_item_id': costItemId,
        'responsible_party': responsibleParty,
        'included_in_incoterm': includedInIncoterm,
        'notes': notes,
      };
}
