class PhaseSummaryModel {
  final int phaseId;
  final String titleEn;
  final String titleAr;
  final String colorHex;
  final List<String> stepCodes;
  final int totalActiveShipments;
  final Map<String, int> stepCounts;

  PhaseSummaryModel({
    required this.phaseId,
    required this.titleEn,
    required this.titleAr,
    required this.colorHex,
    required this.stepCodes,
    required this.totalActiveShipments,
    required this.stepCounts,
  });

  factory PhaseSummaryModel.fromJson(Map<String, dynamic> json) {
    return PhaseSummaryModel(
      phaseId: json['phase_id'] ?? 1,
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      colorHex: json['color_hex'] ?? '#3498DB',
      stepCodes: List<String>.from(json['step_codes'] ?? []),
      totalActiveShipments: json['total_active_shipments'] ?? 0,
      stepCounts: Map<String, int>.from(json['step_counts'] ?? {}),
    );
  }
}

class ShipmentStageCardModel {
  final String importFileCode;
  final String companyName;
  final String supplierName;
  final String? poNumber;
  final String shipmentMode;
  final String incotermCode;
  final String priority;
  final double estimatedCost;
  final String estimatedCostCurrency;
  final String stepCode;
  final String stepNameEn;
  final String stepNameAr;
  final String? previousStepCode;
  final String? previousStepNameEn;
  final String? previousStepNameAr;
  final String? nextStepCode;
  final String? nextStepNameEn;
  final String? nextStepNameAr;
  final String status;
  final String? startedAt;
  final String? notes;

  ShipmentStageCardModel({
    required this.importFileCode,
    required this.companyName,
    required this.supplierName,
    this.poNumber,
    required this.shipmentMode,
    required this.incotermCode,
    required this.priority,
    required this.estimatedCost,
    required this.estimatedCostCurrency,
    required this.stepCode,
    required this.stepNameEn,
    required this.stepNameAr,
    this.previousStepCode,
    this.previousStepNameEn,
    this.previousStepNameAr,
    this.nextStepCode,
    this.nextStepNameEn,
    this.nextStepNameAr,
    required this.status,
    this.startedAt,
    this.notes,
  });

  factory ShipmentStageCardModel.fromJson(Map<String, dynamic> json) {
    return ShipmentStageCardModel(
      importFileCode: json['import_file_code'] ?? '',
      companyName: json['company_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      poNumber: json['po_number'],
      shipmentMode: json['shipment_mode'] ?? 'Sea FCL',
      incotermCode: json['incoterm_code'] ?? 'FOB',
      priority: json['priority'] ?? 'High',
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      estimatedCostCurrency: json['estimated_cost_currency'] ?? 'USD',
      stepCode: json['step_code'] ?? '',
      stepNameEn: json['step_name_en'] ?? '',
      stepNameAr: json['step_name_ar'] ?? '',
      previousStepCode: json['previous_step_code'],
      previousStepNameEn: json['previous_step_name_en'],
      previousStepNameAr: json['previous_step_name_ar'],
      nextStepCode: json['next_step_code'],
      nextStepNameEn: json['next_step_name_en'],
      nextStepNameAr: json['next_step_name_ar'],
      status: json['status'] ?? 'In-Progress',
      startedAt: json['started_at'],
      notes: json['notes'],
    );
  }
}

class LifecycleBoardSummaryModel {
  final List<PhaseSummaryModel> phases;
  final int totalActiveFiles;
  final List<ShipmentStageCardModel> allShipments;

  LifecycleBoardSummaryModel({
    required this.phases,
    required this.totalActiveFiles,
    required this.allShipments,
  });

  factory LifecycleBoardSummaryModel.fromJson(Map<String, dynamic> json) {
    return LifecycleBoardSummaryModel(
      phases: (json['phases'] as List<dynamic>?)
              ?.map((e) => PhaseSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalActiveFiles: json['total_active_files'] ?? 0,
      allShipments: (json['all_shipments'] as List<dynamic>?)
              ?.map((e) => ShipmentStageCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
