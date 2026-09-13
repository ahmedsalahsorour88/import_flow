class ChecklistItemModel {
  final int itemId;
  final int importFileId;
  final String? importFileCode;
  final String phaseCode;
  final String questionCode;
  final String questionTitleAr;
  final String? descriptionAr;
  final String? questionTitleEn;
  final String? descriptionEn;
  final String responsibleRole;
  final bool isMandatory;
  final String verificationType;
  final String? autoCheckSource;
  final String status;
  final String? verifiedBy;
  final String? verifiedAt;
  final String? notes;
  final String? overrideReason;
  final String? actionRoute;

  const ChecklistItemModel({
    required this.itemId,
    required this.importFileId,
    this.importFileCode,
    required this.phaseCode,
    required this.questionCode,
    required this.questionTitleAr,
    this.descriptionAr,
    this.questionTitleEn,
    this.descriptionEn,
    required this.responsibleRole,
    required this.isMandatory,
    required this.verificationType,
    this.autoCheckSource,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
    this.overrideReason,
    this.actionRoute,
  });

  bool get isPassed => status.toUpperCase() == 'PASSED';
  bool get isWaived => status.toUpperCase() == 'WAIVED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  String getTitle(bool isArabic) {
    if (isArabic) return questionTitleAr;
    return (questionTitleEn != null && questionTitleEn!.isNotEmpty) ? questionTitleEn! : questionTitleAr;
  }

  String? getDescription(bool isArabic) {
    if (isArabic) return descriptionAr;
    return (descriptionEn != null && descriptionEn!.isNotEmpty) ? descriptionEn : descriptionAr;
  }

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      itemId: json['item_id'] as int? ?? 0,
      importFileId: json['import_file_id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String?,
      phaseCode: json['phase_code'] as String? ?? 'PRE_SHIPMENT',
      questionCode: json['question_code'] as String? ?? '',
      questionTitleAr: json['question_title_ar'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      questionTitleEn: json['question_title_en'] as String?,
      descriptionEn: json['description_en'] as String?,
      responsibleRole: json['responsible_role'] as String? ?? 'COORDINATOR',
      isMandatory: json['is_mandatory'] as bool? ?? true,
      verificationType: json['verification_type'] as String? ?? 'MANUAL',
      autoCheckSource: json['auto_check_source'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] as String?,
      notes: json['notes'] as String?,
      overrideReason: json['override_reason'] as String?,
      actionRoute: json['action_route'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'phase_code': phaseCode,
      'question_code': questionCode,
      'question_title_ar': questionTitleAr,
      'description_ar': descriptionAr,
      'question_title_en': questionTitleEn,
      'description_en': descriptionEn,
      'responsible_role': responsibleRole,
      'is_mandatory': isMandatory,
      'verification_type': verificationType,
      'auto_check_source': autoCheckSource,
      'status': status,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt,
      'notes': notes,
      'override_reason': overrideReason,
      'action_route': actionRoute,
    };
  }

  ChecklistItemModel copyWith({
    String? status,
    String? verifiedBy,
    String? notes,
    String? overrideReason,
    String? questionTitleAr,
    String? questionTitleEn,
    String? descriptionAr,
    String? descriptionEn,
  }) {
    return ChecklistItemModel(
      itemId: itemId,
      importFileId: importFileId,
      importFileCode: importFileCode,
      phaseCode: phaseCode,
      questionCode: questionCode,
      questionTitleAr: questionTitleAr ?? this.questionTitleAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      questionTitleEn: questionTitleEn ?? this.questionTitleEn,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      responsibleRole: responsibleRole,
      isMandatory: isMandatory,
      verificationType: verificationType,
      autoCheckSource: autoCheckSource,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt,
      notes: notes ?? this.notes,
      overrideReason: overrideReason ?? this.overrideReason,
      actionRoute: actionRoute,
    );
  }
}

class ChecklistSummaryModel {
  final int importFileId;
  final String? importFileCode;
  final int totalItems;
  final int passedItems;
  final int pendingItems;
  final int waivedItems;
  final int mandatoryPendingItems;
  final int readinessScorePct;
  final bool isGateBlocked;
  final List<String> blockingQuestions;
  final List<ChecklistItemModel> items;

  const ChecklistSummaryModel({
    required this.importFileId,
    this.importFileCode,
    required this.totalItems,
    required this.passedItems,
    required this.pendingItems,
    required this.waivedItems,
    required this.mandatoryPendingItems,
    required this.readinessScorePct,
    required this.isGateBlocked,
    required this.blockingQuestions,
    required this.items,
  });

  factory ChecklistSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChecklistSummaryModel(
      importFileId: json['import_file_id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String?,
      totalItems: json['total_items'] as int? ?? 0,
      passedItems: json['passed_items'] as int? ?? 0,
      pendingItems: json['pending_items'] as int? ?? 0,
      waivedItems: json['waived_items'] as int? ?? 0,
      mandatoryPendingItems: json['mandatory_pending_items'] as int? ?? 0,
      readinessScorePct: json['readiness_score_pct'] as int? ?? 0,
      isGateBlocked: json['is_gate_blocked'] as bool? ?? false,
      blockingQuestions: (json['blocking_questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
