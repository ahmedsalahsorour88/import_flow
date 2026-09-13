class EmailSettingsModel {
  final int? settingsId;
  final String providerType; // LOCAL_OUTLOOK, GMAIL, OUTLOOK, CUSTOM
  final String emailAddress;
  final String username;
  final String? password;
  final String imapHost;
  final int imapPort;
  final bool imapUseSsl;
  final String smtpHost;
  final int smtpPort;
  final bool smtpUseTls;
  final bool smtpUseSsl;
  final String senderDisplayName;
  final bool autoFetchEnabled;
  final int fetchIntervalMinutes;
  final bool hasPassword;
  final String? lastSyncAt;
  final String? lastSyncStatus;
  final String? lastSyncMessage;
  final bool isActive;

  EmailSettingsModel({
    this.settingsId,
    this.providerType = 'GMAIL',
    required this.emailAddress,
    required this.username,
    this.password,
    this.imapHost = 'imap.gmail.com',
    this.imapPort = 993,
    this.imapUseSsl = true,
    this.smtpHost = 'smtp.gmail.com',
    this.smtpPort = 587,
    this.smtpUseTls = true,
    this.smtpUseSsl = false,
    this.senderDisplayName = 'Sorour Logistics Operations',
    this.autoFetchEnabled = false,
    this.fetchIntervalMinutes = 15,
    this.hasPassword = false,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.lastSyncMessage,
    this.isActive = true,
  });

  factory EmailSettingsModel.fromJson(Map<String, dynamic> json) {
    return EmailSettingsModel(
      settingsId: json['settings_id'],
      providerType: json['provider_type'] ?? 'CUSTOM',
      emailAddress: json['email_address'] ?? '',
      username: json['username'] ?? '',
      password: null, // never returned from backend for security
      imapHost: json['imap_host'] ?? 'imap.gmail.com',
      imapPort: json['imap_port'] ?? 993,
      imapUseSsl: json['imap_use_ssl'] ?? true,
      smtpHost: json['smtp_host'] ?? 'smtp.gmail.com',
      smtpPort: json['smtp_port'] ?? 587,
      smtpUseTls: json['smtp_use_tls'] ?? true,
      smtpUseSsl: json['smtp_use_ssl'] ?? false,
      senderDisplayName: json['sender_display_name'] ?? 'Sorour Logistics Operations',
      autoFetchEnabled: json['auto_fetch_enabled'] ?? false,
      fetchIntervalMinutes: json['fetch_interval_minutes'] ?? 15,
      hasPassword: json['has_password'] ?? false,
      lastSyncAt: json['last_sync_at'],
      lastSyncStatus: json['last_sync_status'],
      lastSyncMessage: json['last_sync_message'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson({String? newPassword}) {
    final map = <String, dynamic>{
      'provider_type': providerType,
      'email_address': emailAddress,
      'username': username,
      'imap_host': imapHost,
      'imap_port': imapPort,
      'imap_use_ssl': imapUseSsl,
      'smtp_host': smtpHost,
      'smtp_port': smtpPort,
      'smtp_use_tls': smtpUseTls,
      'smtp_use_ssl': smtpUseSsl,
      'sender_display_name': senderDisplayName,
      'auto_fetch_enabled': autoFetchEnabled,
      'fetch_interval_minutes': fetchIntervalMinutes,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      map['password'] = newPassword;
    } else if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    return map;
  }

  EmailSettingsModel copyWith({
    int? settingsId,
    String? providerType,
    String? emailAddress,
    String? username,
    String? password,
    String? imapHost,
    int? imapPort,
    bool? imapUseSsl,
    String? smtpHost,
    int? smtpPort,
    bool? smtpUseTls,
    bool? smtpUseSsl,
    String? senderDisplayName,
    bool? autoFetchEnabled,
    int? fetchIntervalMinutes,
    bool? hasPassword,
    String? lastSyncAt,
    String? lastSyncStatus,
    String? lastSyncMessage,
    bool? isActive,
  }) {
    return EmailSettingsModel(
      settingsId: settingsId ?? this.settingsId,
      providerType: providerType ?? this.providerType,
      emailAddress: emailAddress ?? this.emailAddress,
      username: username ?? this.username,
      password: password ?? this.password,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      imapUseSsl: imapUseSsl ?? this.imapUseSsl,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUseTls: smtpUseTls ?? this.smtpUseTls,
      smtpUseSsl: smtpUseSsl ?? this.smtpUseSsl,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      autoFetchEnabled: autoFetchEnabled ?? this.autoFetchEnabled,
      fetchIntervalMinutes: fetchIntervalMinutes ?? this.fetchIntervalMinutes,
      hasPassword: hasPassword ?? this.hasPassword,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      isActive: isActive ?? this.isActive,
    );
  }
}

class EmailConnectionTestResultModel {
  final bool imapConnected;
  final String imapMessage;
  final bool smtpConnected;
  final String smtpMessage;
  final bool overallSuccess;
  final String? details;

  EmailConnectionTestResultModel({
    required this.imapConnected,
    required this.imapMessage,
    required this.smtpConnected,
    required this.smtpMessage,
    required this.overallSuccess,
    this.details,
  });

  factory EmailConnectionTestResultModel.fromJson(Map<String, dynamic> json) {
    return EmailConnectionTestResultModel(
      imapConnected: json['imap_connected'] ?? false,
      imapMessage: json['imap_message'] ?? '',
      smtpConnected: json['smtp_connected'] ?? false,
      smtpMessage: json['smtp_message'] ?? '',
      overallSuccess: json['overall_success'] ?? false,
      details: json['details'],
    );
  }
}

class InboxFetchResultModel {
  final int totalFetched;
  final int matchedFilesCount;
  final int tasksCreatedCount;
  final String message;
  final List<dynamic> results;
  final List<ArrivalNoticeParseResultModel> parsedResults;

  InboxFetchResultModel({
    required this.totalFetched,
    required this.matchedFilesCount,
    required this.tasksCreatedCount,
    required this.message,
    required this.results,
    required this.parsedResults,
  });

  factory InboxFetchResultModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    final parsed = rawResults
        .whereType<Map<String, dynamic>>()
        .map((e) => ArrivalNoticeParseResultModel.fromJson(e))
        .toList();

    return InboxFetchResultModel(
      totalFetched: json['total_fetched'] ?? 0,
      matchedFilesCount: json['matched_files_count'] ?? 0,
      tasksCreatedCount: json['tasks_created_count'] ?? 0,
      message: json['message'] ?? '',
      results: rawResults,
      parsedResults: parsed,
    );
  }
}

class ArrivalNoticeParseResultModel {
  final String? extractedBlNumber;
  final String? extractedEta;
  final String? extractedVessel;
  final String? extractedVoyage;
  final List<String> extractedContainers;
  final bool isMatchedFile;
  final int? importFileId;
  final String? importFileCode;
  final bool paymentTaskCreated;
  final int? taskId;
  final String summaryMessage;
  final int? emailId;
  final String? senderEmail;
  final String? subject;
  final String? shipmentTitle;
  final String? matchReason;
  final String? taskCode;
  final String? taskTitle;
  final String assignedUser;
  final String priority;
  final String? dueDate;

  ArrivalNoticeParseResultModel({
    this.extractedBlNumber,
    this.extractedEta,
    this.extractedVessel,
    this.extractedVoyage,
    this.extractedContainers = const [],
    this.isMatchedFile = false,
    this.importFileId,
    this.importFileCode,
    this.paymentTaskCreated = false,
    this.taskId,
    required this.summaryMessage,
    this.emailId,
    this.senderEmail,
    this.subject,
    this.shipmentTitle,
    this.matchReason,
    this.taskCode,
    this.taskTitle,
    this.assignedUser = 'Finance Team',
    this.priority = 'High',
    this.dueDate,
  });

  factory ArrivalNoticeParseResultModel.fromJson(Map<String, dynamic> json) {
    return ArrivalNoticeParseResultModel(
      extractedBlNumber: json['extracted_bl_number'],
      extractedEta: json['extracted_eta']?.toString(),
      extractedVessel: json['extracted_vessel'],
      extractedVoyage: json['extracted_voyage'],
      extractedContainers: (json['extracted_containers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isMatchedFile: json['is_matched_file'] ?? false,
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'],
      paymentTaskCreated: json['payment_task_created'] ?? false,
      taskId: json['task_id'],
      summaryMessage: json['summary_message'] ?? '',
      emailId: json['email_id'],
      senderEmail: json['sender_email'],
      subject: json['subject'],
      shipmentTitle: json['shipment_title'],
      matchReason: json['match_reason'],
      taskCode: json['task_code'],
      taskTitle: json['task_title'],
      assignedUser: json['assigned_user'] ?? 'Finance Team',
      priority: json['priority'] ?? 'High',
      dueDate: json['due_date']?.toString(),
    );
  }
}

class TaskRouteApprovalItemModel {
  final int importFileId;
  final String importFileCode;
  final String title;
  final String? description;
  final String assignedUser;
  final String priority;
  final String? dueDate;
  final String reminderType;
  final String? blNumber;
  final String? notes;
  final int? emailId;
  final int? taskId;

  TaskRouteApprovalItemModel({
    required this.importFileId,
    required this.importFileCode,
    required this.title,
    this.description,
    this.assignedUser = 'Finance Team',
    this.priority = 'High',
    this.dueDate,
    this.reminderType = 'Arrival Notice Payment',
    this.blNumber,
    this.notes,
    this.emailId,
    this.taskId,
  });

  Map<String, dynamic> toJson() {
    return {
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'title': title,
      if (description != null) 'description': description,
      'assigned_user': assignedUser,
      'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      'reminder_type': reminderType,
      if (blNumber != null) 'bl_number': blNumber,
      if (notes != null) 'notes': notes,
      if (emailId != null) 'email_id': emailId,
      if (taskId != null) 'task_id': taskId,
    };
  }
}

class LocalOutlookStatusModel {
  final bool available;
  final String? userName;
  final String? emailAddress;
  final int inboxCount;
  final String? error;

  LocalOutlookStatusModel({
    required this.available,
    this.userName,
    this.emailAddress,
    this.inboxCount = 0,
    this.error,
  });

  factory LocalOutlookStatusModel.fromJson(Map<String, dynamic> json) {
    return LocalOutlookStatusModel(
      available: json['available'] ?? false,
      userName: json['user_name'],
      emailAddress: json['email_address'],
      inboxCount: json['inbox_count'] ?? 0,
      error: json['error'],
    );
  }
}
