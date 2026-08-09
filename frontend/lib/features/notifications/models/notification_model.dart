class NotificationModel {
  final int notificationId;
  final String title;
  final String message;
  final String severity; // INFO, WARNING, CRITICAL
  final String category; // COMPANY_EXPIRY, ACID_EXPIRY, DUTY_PAYMENT, SYSTEM
  final String? entityType;
  final int? entityId;
  final String targetRole;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    this.severity = 'INFO',
    this.category = 'SYSTEM',
    this.entityType,
    this.entityId,
    this.targetRole = 'ALL',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: (json['notification_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'INFO',
      category: json['category']?.toString() ?? 'SYSTEM',
      entityType: json['entity_type']?.toString(),
      entityId: (json['entity_id'] as num?)?.toInt(),
      targetRole: json['target_role']?.toString() ?? 'ALL',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class NotificationSummaryModel {
  final int unreadCount;
  final int totalCount;
  final int criticalCount;
  final int warningCount;

  NotificationSummaryModel({
    this.unreadCount = 0,
    this.totalCount = 0,
    this.criticalCount = 0,
    this.warningCount = 0,
  });

  factory NotificationSummaryModel.fromJson(Map<String, dynamic> json) {
    return NotificationSummaryModel(
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      criticalCount: (json['critical_count'] as num?)?.toInt() ?? 0,
      warningCount: (json['warning_count'] as num?)?.toInt() ?? 0,
    );
  }
}
