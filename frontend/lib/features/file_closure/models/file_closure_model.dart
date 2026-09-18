class ClosureChecklistModel {
  final bool docsVerified;
  final bool customsCleared;
  final bool warehouseReceived;
  final bool landedCostSettled;
  final bool tasksClosed;
  final bool? dossierExported;
  final bool? emptyContainersReturned;

  ClosureChecklistModel({
    this.docsVerified = true,
    this.customsCleared = true,
    this.warehouseReceived = true,
    this.landedCostSettled = true,
    this.tasksClosed = true,
    this.dossierExported,
    this.emptyContainersReturned,
  });

  bool get isAllCompleted =>
      docsVerified &&
      customsCleared &&
      warehouseReceived &&
      landedCostSettled &&
      tasksClosed &&
      (dossierExported ?? true) &&
      (emptyContainersReturned ?? true);

  factory ClosureChecklistModel.fromJson(Map<String, dynamic> json) {
    return ClosureChecklistModel(
      docsVerified: json['docs_verified'] ?? true,
      customsCleared: json['customs_cleared'] ?? true,
      warehouseReceived: json['warehouse_received'] ?? true,
      landedCostSettled: json['landed_cost_settled'] ?? true,
      tasksClosed: json['tasks_closed'] ?? true,
      dossierExported: json['dossier_exported'],
      emptyContainersReturned: json['empty_containers_returned'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'docs_verified': docsVerified,
      'customs_cleared': customsCleared,
      'warehouse_received': warehouseReceived,
      'landed_cost_settled': landedCostSettled,
      'tasks_closed': tasksClosed,
    };
    if (dossierExported != null) {
      map['dossier_exported'] = dossierExported;
    }
    if (emptyContainersReturned != null) {
      map['empty_containers_returned'] = emptyContainersReturned;
    }
    return map;
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

  bool get isFullyVerified => closureChecklist.isAllCompleted && status == 'Closed';

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

class ClosurePrecheckResponseModel {
  final int importFileId;
  final String importFileCode;
  final String companyName;
  final String supplierName;
  final bool canClose;
  final List<String> blockingReasons;
  final List<String> warnings;
  final Map<String, bool> checklistStatus;
  final double actualLandedCostEgp;
  final double actualMarkupFactor;
  final String? dossierExportedAt;
  final String? dossierExportedBy;
  final String? emptyContainersReturnedAt;
  final String certificateCodePreview;

  ClosurePrecheckResponseModel({
    required this.importFileId,
    required this.importFileCode,
    required this.companyName,
    required this.supplierName,
    required this.canClose,
    this.blockingReasons = const [],
    this.warnings = const [],
    this.checklistStatus = const {},
    this.actualLandedCostEgp = 0.0,
    this.actualMarkupFactor = 1.0,
    this.dossierExportedAt,
    this.dossierExportedBy,
    this.emptyContainersReturnedAt,
    required this.certificateCodePreview,
  });

  factory ClosurePrecheckResponseModel.fromJson(Map<String, dynamic> json) {
    return ClosurePrecheckResponseModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      companyName: json['company_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      canClose: json['can_close'] ?? false,
      blockingReasons: (json['blocking_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      checklistStatus: (json['checklist_status'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v == true)) ??
          const {},
      actualLandedCostEgp:
          (json['actual_landed_cost_egp'] as num?)?.toDouble() ?? 0.0,
      actualMarkupFactor:
          (json['actual_markup_factor'] as num?)?.toDouble() ?? 1.0,
      dossierExportedAt: json['dossier_exported_at']?.toString(),
      dossierExportedBy: json['dossier_exported_by']?.toString(),
      emptyContainersReturnedAt:
          json['empty_containers_returned_at']?.toString(),
      certificateCodePreview: json['certificate_code_preview'] ?? '',
    );
  }
}

class OfficialClosureCertificateResponseModel {
  final bool success;
  final int closureId;
  final String closureCode;
  final int importFileId;
  final String importFileCode;
  final String companyName;
  final String supplierName;
  final String auditorName;
  final String archiveLocation;
  final String? archivalNotes;
  final String closedAt;
  final String status;
  final double progressPercent;
  final String currentStage;
  final String currentModule;
  final String nextAction;
  final String message;

  OfficialClosureCertificateResponseModel({
    required this.success,
    required this.closureId,
    required this.closureCode,
    required this.importFileId,
    required this.importFileCode,
    required this.companyName,
    required this.supplierName,
    required this.auditorName,
    required this.archiveLocation,
    this.archivalNotes,
    required this.closedAt,
    required this.status,
    required this.progressPercent,
    required this.currentStage,
    required this.currentModule,
    required this.nextAction,
    required this.message,
  });

  factory OfficialClosureCertificateResponseModel.fromJson(Map<String, dynamic> json) {
    return OfficialClosureCertificateResponseModel(
      success: json['success'] ?? false,
      closureId: json['closure_id'] ?? 0,
      closureCode: json['closure_code'] ?? '',
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      companyName: json['company_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      auditorName: json['auditor_name'] ?? '',
      archiveLocation: json['archive_location'] ?? '',
      archivalNotes: json['archival_notes']?.toString(),
      closedAt: json['closed_at'] ?? '',
      status: json['status'] ?? 'Closed',
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 100.0,
      currentStage: json['current_stage'] ?? '',
      currentModule: json['current_module'] ?? '',
      nextAction: json['next_action'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

