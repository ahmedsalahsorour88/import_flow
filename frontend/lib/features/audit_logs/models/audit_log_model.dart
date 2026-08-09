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
      logId: (json['log_id'] as num?)?.toInt() ?? 0,
      entityType: json['entity_type']?.toString() ?? '',
      entityId: (json['entity_id'] as num?)?.toInt() ?? 0,
      entityCode: json['entity_code']?.toString(),
      action: json['action']?.toString() ?? '',
      changesSummary: json['changes_summary']?.toString(),
      oldValues: json['old_values']?.toString(),
      newValues: json['new_values']?.toString(),
      performedAt: json['performed_at'] != null
          ? DateTime.tryParse(json['performed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      performedBy: json['performed_by']?.toString() ?? 'System Admin',
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
