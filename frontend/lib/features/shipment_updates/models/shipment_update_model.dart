class ShipmentUpdateLogModel {
  final int updateId;
  final String updateCode;
  final int importFileId;
  final String importFileCode;
  final String updateCategory; // Follow-up & Notes, Phase Cost Adjustment, Future Phase Alert, Daily Check-in
  final String targetPhase; // Phase 1 -> Phase 10
  final String phaseStatus; // Completed, Current, Future
  final String logDate;
  final String note;
  final String? adjustedCostItem;
  final double previousCost;
  final double newCost;
  final String alertPriority; // Normal, High, Critical
  final String assignedUser;
  final bool isActive;
  final String createdAt;
  final String createdBy;

  ShipmentUpdateLogModel({
    required this.updateId,
    required this.updateCode,
    required this.importFileId,
    required this.importFileCode,
    required this.updateCategory,
    required this.targetPhase,
    required this.phaseStatus,
    required this.logDate,
    required this.note,
    this.adjustedCostItem,
    this.previousCost = 0.0,
    this.newCost = 0.0,
    required this.alertPriority,
    required this.assignedUser,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
  });

  factory ShipmentUpdateLogModel.fromJson(Map<String, dynamic> json) {
    return ShipmentUpdateLogModel(
      updateId: json['update_id'] ?? 0,
      updateCode: json['update_code'] ?? '',
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      updateCategory: json['update_category'] ?? 'Follow-up & Notes',
      targetPhase: json['target_phase'] ?? 'Phase 1',
      phaseStatus: json['phase_status'] ?? 'Current',
      logDate: json['log_date'] ?? '',
      note: json['note'] ?? '',
      adjustedCostItem: json['adjusted_cost_item'],
      previousCost: (json['previous_cost'] as num?)?.toDouble() ?? 0.0,
      newCost: (json['new_cost'] as num?)?.toDouble() ?? 0.0,
      alertPriority: json['alert_priority'] ?? 'Normal',
      assignedUser: json['assigned_user'] ?? 'Kamal',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      createdBy: json['created_by'] ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'update_id': updateId,
      'update_code': updateCode,
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'update_category': updateCategory,
      'target_phase': targetPhase,
      'phase_status': phaseStatus,
      'log_date': logDate,
      'note': note,
      'adjusted_cost_item': adjustedCostItem,
      'previous_cost': previousCost,
      'new_cost': newCost,
      'alert_priority': alertPriority,
      'assigned_user': assignedUser,
      'is_active': isActive,
      'created_at': createdAt,
      'created_by': createdBy,
    };
  }
}

class PhaseInspectionModel {
  final String phaseCode;
  final String phaseName;
  final int phaseNumber;
  final String status; // Completed, Current, Future
  final String? completionDate;
  final String? lastNote;
  final int updateCount;

  PhaseInspectionModel({
    required this.phaseCode,
    required this.phaseName,
    required this.phaseNumber,
    required this.status,
    this.completionDate,
    this.lastNote,
    required this.updateCount,
  });

  factory PhaseInspectionModel.fromJson(Map<String, dynamic> json) {
    return PhaseInspectionModel(
      phaseCode: json['phase_code'] ?? '',
      phaseName: json['phase_name'] ?? '',
      phaseNumber: json['phase_number'] ?? 1,
      status: json['status'] ?? 'Current',
      completionDate: json['completion_date'],
      lastNote: json['last_note'],
      updateCount: json['update_count'] ?? 0,
    );
  }
}
