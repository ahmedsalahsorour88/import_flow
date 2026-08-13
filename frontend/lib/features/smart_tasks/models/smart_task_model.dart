class SmartTaskModel {
  final int taskId;
  final String taskCode;
  final String title;
  final String? description;
  final String taskType; // System Generated, Manual To-Do
  final int? importFileId;
  final String? importFileCode;
  final String? phaseName;
  final String assignedUser;
  final String priority; // Low, Medium, High, Critical
  final String reminderType; // Supplier, Bank, Shipping Line, Broker, Document, ETA, General
  final String? dueDate;
  final String? reminderDate;
  final String status; // Pending, In Progress, Completed, Cancelled
  final String? notes;
  final String? attachmentUrl;
  final bool isAutoClosed;
  final bool isActive;
  final String createdAt;
  final String createdBy;

  SmartTaskModel({
    required this.taskId,
    required this.taskCode,
    required this.title,
    this.description,
    required this.taskType,
    this.importFileId,
    this.importFileCode,
    this.phaseName,
    required this.assignedUser,
    required this.priority,
    required this.reminderType,
    this.dueDate,
    this.reminderDate,
    required this.status,
    this.notes,
    this.attachmentUrl,
    required this.isAutoClosed,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
  });

  factory SmartTaskModel.fromJson(Map<String, dynamic> json) {
    return SmartTaskModel(
      taskId: json['task_id'] ?? 0,
      taskCode: json['task_code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      taskType: json['task_type'] ?? 'Manual To-Do',
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'],
      phaseName: json['phase_name'],
      assignedUser: json['assigned_user'] ?? 'Kamal',
      priority: json['priority'] ?? 'Medium',
      reminderType: json['reminder_type'] ?? 'General Reminder',
      dueDate: json['due_date'],
      reminderDate: json['reminder_date'],
      status: json['status'] ?? 'Pending',
      notes: json['notes'],
      attachmentUrl: json['attachment_url'],
      isAutoClosed: json['is_auto_closed'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      createdBy: json['created_by'] ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'task_code': taskCode,
      'title': title,
      'description': description,
      'task_type': taskType,
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'phase_name': phaseName,
      'assigned_user': assignedUser,
      'priority': priority,
      'reminder_type': reminderType,
      'due_date': dueDate,
      'reminder_date': reminderDate,
      'status': status,
      'notes': notes,
      'attachment_url': attachmentUrl,
      'is_auto_closed': isAutoClosed,
      'is_active': isActive,
      'created_at': createdAt,
      'created_by': createdBy,
    };
  }
}

class SmartTaskSummaryMetricsModel {
  final int totalTasks;
  final int todaysTasks;
  final int pendingTasks;
  final int upcomingShipments;
  final int arrivingThisWeek;
  final int etaChanges;
  final int waitingForPayment;
  final int waitingForForm4;
  final int pendingRequirements;
  final int highPriorityAlerts;

  SmartTaskSummaryMetricsModel({
    required this.totalTasks,
    required this.todaysTasks,
    required this.pendingTasks,
    required this.upcomingShipments,
    required this.arrivingThisWeek,
    required this.etaChanges,
    required this.waitingForPayment,
    required this.waitingForForm4,
    required this.pendingRequirements,
    required this.highPriorityAlerts,
  });

  factory SmartTaskSummaryMetricsModel.fromJson(Map<String, dynamic> json) {
    return SmartTaskSummaryMetricsModel(
      totalTasks: json['total_tasks'] ?? 0,
      todaysTasks: json['todays_tasks'] ?? 0,
      pendingTasks: json['pending_tasks'] ?? 0,
      upcomingShipments: json['upcoming_shipments'] ?? 0,
      arrivingThisWeek: json['arriving_this_week'] ?? 0,
      etaChanges: json['eta_changes'] ?? 0,
      waitingForPayment: json['waiting_for_payment'] ?? 0,
      waitingForForm4: json['waiting_for_form4'] ?? 0,
      pendingRequirements: json['pending_requirements'] ?? 0,
      highPriorityAlerts: json['high_priority_alerts'] ?? 0,
    );
  }
}
