class ClosureChecklistModel {
  final bool docsVerified;
  final bool customsCleared;
  final bool warehouseReceived;
  final bool landedCostSettled;
  final bool tasksClosed;

  ClosureChecklistModel({
    this.docsVerified = true,
    this.customsCleared = true,
    this.warehouseReceived = true,
    this.landedCostSettled = true,
    this.tasksClosed = true,
  });

  bool get isAllCompleted =>
      docsVerified && customsCleared && warehouseReceived && landedCostSettled && tasksClosed;

  factory ClosureChecklistModel.fromJson(Map<String, dynamic> json) {
    return ClosureChecklistModel(
      docsVerified: json['docs_verified'] ?? true,
      customsCleared: json['customs_cleared'] ?? true,
      warehouseReceived: json['warehouse_received'] ?? true,
      landedCostSettled: json['landed_cost_settled'] ?? true,
      tasksClosed: json['tasks_closed'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docs_verified': docsVerified,
      'customs_cleared': customsCleared,
      'warehouse_received': warehouseReceived,
      'landed_cost_settled': landedCostSettled,
      'tasks_closed': tasksClosed,
    };
  }
}

class ImportFileClosureModel {
  final int closureId;
  final String closureCode;
  final int importFileId;
  final ClosureChecklistModel closureChecklist;
  final String auditorName;
  final String archiveLocation;
  final String? archivalNotes;
  final String status;
  final bool isActive;
  final String closedAt;
  final String createdAt;
  final String updatedAt;

  ImportFileClosureModel({
    required this.closureId,
    required this.closureCode,
    required this.importFileId,
    required this.closureChecklist,
    this.auditorName = 'Internal Auditor',
    this.archiveLocation = 'Digital Archive Vault - 2026',
    this.archivalNotes,
    this.status = 'Closed',
    this.isActive = true,
    required this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImportFileClosureModel.fromJson(Map<String, dynamic> json) {
    return ImportFileClosureModel(
      closureId: json['closure_id'],
      closureCode: json['closure_code'] ?? '',
      importFileId: json['import_file_id'],
      closureChecklist: ClosureChecklistModel.fromJson(json['closure_checklist'] ?? {}),
      auditorName: json['auditor_name'] ?? 'Internal Auditor',
      archiveLocation: json['archive_location'] ?? 'Digital Archive Vault - 2026',
      archivalNotes: json['archival_notes'],
      status: json['status'] ?? 'Closed',
      isActive: json['is_active'] ?? true,
      closedAt: json['closed_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'closure_id': closureId,
      'closure_code': closureCode,
      'import_file_id': importFileId,
      'closure_checklist': closureChecklist.toJson(),
      'auditor_name': auditorName,
      'archive_location': archiveLocation,
      'archival_notes': archivalNotes,
      'status': status,
    };
  }
}
