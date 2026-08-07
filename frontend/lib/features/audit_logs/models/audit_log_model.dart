class AuditLogModel {
  final int logId;
  final String entityType;
  final int entityId;
  final String? entityCode;
  final String action;
  final String? changesSummary;
  final String? oldValues;
  final String? newValues;
  final DateTime performedAt;
  final String performedBy;

  AuditLogModel({
    required this.logId,
    required this.entityType,
    required this.entityId,
    this.entityCode,
    required this.action,
    this.changesSummary,
    this.oldValues,
    this.newValues,
    required this.performedAt,
    required this.performedBy,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      logId: json['log_id'] as int,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      entityCode: json['entity_code'] as String?,
      action: json['action'] as String,
      changesSummary: json['changes_summary'] as String?,
      oldValues: json['old_values'] as String?,
      newValues: json['new_values'] as String?,
      performedAt: DateTime.parse(json['performed_at'] as String),
      performedBy: json['performed_by'] as String? ?? 'System Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_code': entityCode,
      'action': action,
      'changes_summary': changesSummary,
      'old_values': oldValues,
      'new_values': newValues,
      'performed_at': performedAt.toIso8601String(),
      'performed_by': performedBy,
    };
  }
}
