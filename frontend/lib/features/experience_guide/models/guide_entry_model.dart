class GuideScopeModel {
  final int? scopeId;
  final int? guideEntryId;
  final String scopeType;
  final String scopeValue;

  GuideScopeModel({
    this.scopeId,
    this.guideEntryId,
    required this.scopeType,
    required this.scopeValue,
  });

  factory GuideScopeModel.fromJson(Map<String, dynamic> json) {
    return GuideScopeModel(
      scopeId: json['scope_id'],
      guideEntryId: json['guide_entry_id'],
      scopeType: json['scope_type'] ?? 'hs_code',
      scopeValue: json['scope_value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scopeId != null) 'scope_id': scopeId,
      if (guideEntryId != null) 'guide_entry_id': guideEntryId,
      'scope_type': scopeType,
      'scope_value': scopeValue,
    };
  }
}

class GuideEntryModel {
  final int entryId;
  final String title;
  final String content;
  final String entryType;
  final String severity;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final bool isActive;
  final List<GuideScopeModel> scopes;

  GuideEntryModel({
    required this.entryId,
    required this.title,
    required this.content,
    this.entryType = 'alert',
    this.severity = 'info',
    this.createdBy = 'System',
    this.createdAt = '',
    this.updatedAt = '',
    this.isActive = true,
    this.scopes = const [],
  });

  factory GuideEntryModel.fromJson(Map<String, dynamic> json) {
    var rawScopes = json['scopes'] as List<dynamic>? ?? [];
    return GuideEntryModel(
      entryId: json['entry_id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      entryType: json['entry_type'] ?? 'alert',
      severity: json['severity'] ?? 'info',
      createdBy: json['created_by'] ?? 'System',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isActive: json['is_active'] ?? true,
      scopes: rawScopes.map((s) => GuideScopeModel.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'title': title,
      'content': content,
      'entry_type': entryType,
      'severity': severity,
      'created_by': createdBy,
      'is_active': isActive,
      'scopes': scopes.map((s) => s.toJson()).toList(),
    };
  }
}

class GuideMatchResultModel {
  final List<GuideEntryModel> matchedEntries;
  final bool hasCriticalAlert;
  final bool hasWarningAlert;
  final List<String> mandatoryPorts;
  final List<String> requiredDocuments;
  final List<String> suggestedNotes;

  GuideMatchResultModel({
    this.matchedEntries = const [],
    this.hasCriticalAlert = false,
    this.hasWarningAlert = false,
    this.mandatoryPorts = const [],
    this.requiredDocuments = const [],
    this.suggestedNotes = const [],
  });

  factory GuideMatchResultModel.fromJson(Map<String, dynamic> json) {
    var rawEntries = json['matched_entries'] as List<dynamic>? ?? [];
    var rawPorts = json['mandatory_ports'] as List<dynamic>? ?? [];
    var rawDocs = json['required_documents'] as List<dynamic>? ?? [];
    var rawNotes = json['suggested_notes'] as List<dynamic>? ?? [];

    return GuideMatchResultModel(
      matchedEntries: rawEntries.map((e) => GuideEntryModel.fromJson(e as Map<String, dynamic>)).toList(),
      hasCriticalAlert: json['has_critical_alert'] ?? false,
      hasWarningAlert: json['has_warning_alert'] ?? false,
      mandatoryPorts: rawPorts.map((p) => p.toString()).toList(),
      requiredDocuments: rawDocs.map((d) => d.toString()).toList(),
      suggestedNotes: rawNotes.map((n) => n.toString()).toList(),
    );
  }
}
