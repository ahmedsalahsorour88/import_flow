import 'package:flutter/material.dart';

/// Configurable Step Risk & Lifecycle Settings Model (Addendum: Section 10).
class StepConfigModel {
  final int id;
  final String stepCode;
  final String stepNameAr;
  final String stepNameEn;
  final int phaseId;
  final String skipPolicy; // "blocked" | "single_approval" | "dual_approval"
  final bool reasonRequired; // always true
  final List<String> reasonCategories;
  final List<String> approverRoles;
  final bool supportsPendingReference;
  final String? lastModifiedBy;
  final String? lastModifiedAt;

  const StepConfigModel({
    required this.id,
    required this.stepCode,
    required this.stepNameAr,
    required this.stepNameEn,
    required this.phaseId,
    this.skipPolicy = 'blocked',
    this.reasonRequired = true,
    this.reasonCategories = const [],
    this.approverRoles = const ['Manager'],
    this.supportsPendingReference = false,
    this.lastModifiedBy,
    this.lastModifiedAt,
  });

  bool get isBlocked => skipPolicy.toLowerCase() == 'blocked';
  bool get isSingleApproval => skipPolicy.toLowerCase() == 'single_approval';
  bool get isDualApproval => skipPolicy.toLowerCase() == 'dual_approval';
  bool get requiresSingleApproval => isSingleApproval;
  bool get requiresDualApproval => isDualApproval;
  bool get hasReasonCategories => reasonCategories.isNotEmpty;

  String get skipPolicyDisplayAr => isBlocked
      ? 'محظور التخطي نهائياً'
      : (isDualApproval ? 'موافقة ثنائية معتمدة' : 'موافقة أحادية');
  String get skipPolicyDisplayEn => isBlocked
      ? 'Strictly Blocked'
      : (isDualApproval ? 'Dual Approval' : 'Single Approval');

  String localizedName(bool isArabic) => isArabic ? stepNameAr : stepNameEn;

  String policyLabel(bool isArabic) {
    if (isArabic) {
      switch (skipPolicy.toLowerCase()) {
        case 'blocked':
          return 'محظورة من التخطي (Blocked)';
        case 'single_approval':
          return 'موافقة أحادية (Single Approval)';
        case 'dual_approval':
          return 'موافقة ثنائية مشددة (Dual Approval)';
        default:
          return skipPolicy;
      }
    } else {
      switch (skipPolicy.toLowerCase()) {
        case 'blocked':
          return 'Blocked (Non-Skippable)';
        case 'single_approval':
          return 'Single Approval';
        case 'dual_approval':
          return 'Dual Approval';
        default:
          return skipPolicy;
      }
    }
  }

  Color get policyColor {
    switch (skipPolicy.toLowerCase()) {
      case 'blocked':
        return const Color(0xFFC0392B); // Crimson Red
      case 'single_approval':
        return const Color(0xFFE67E22); // Flat Orange
      case 'dual_approval':
        return const Color(0xFF8E44AD); // Deep Purple
      default:
        return Colors.grey;
    }
  }

  IconData get policyIcon {
    switch (skipPolicy.toLowerCase()) {
      case 'blocked':
        return Icons.block_rounded;
      case 'single_approval':
        return Icons.verified_user_outlined;
      case 'dual_approval':
        return Icons.security_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  factory StepConfigModel.fromJson(Map<String, dynamic> json) {
    return StepConfigModel(
      id: json['id'] as int? ?? 0,
      stepCode: json['step_code'] as String? ?? '',
      stepNameAr: json['step_name_ar'] as String? ?? '',
      stepNameEn: json['step_name_en'] as String? ?? '',
      phaseId: json['phase_id'] as int? ?? 1,
      skipPolicy: json['skip_policy'] as String? ?? 'blocked',
      reasonRequired: json['reason_required'] as bool? ?? true,
      reasonCategories: (json['reason_categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      approverRoles: (json['approver_roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Manager'],
      supportsPendingReference:
          json['supports_pending_reference'] as bool? ?? false,
      lastModifiedBy: json['last_modified_by'] as String?,
      lastModifiedAt: json['last_modified_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'step_code': stepCode,
        'step_name_ar': stepNameAr,
        'step_name_en': stepNameEn,
        'phase_id': phaseId,
        'skip_policy': skipPolicy,
        'reason_required': reasonRequired,
        'reason_categories': reasonCategories,
        'approver_roles': approverRoles,
        'supports_pending_reference': supportsPendingReference,
        'last_modified_by': lastModifiedBy,
        'last_modified_at': lastModifiedAt,
      };

  StepConfigModel copyWith({
    int? id,
    String? stepCode,
    String? stepNameAr,
    String? stepNameEn,
    int? phaseId,
    String? skipPolicy,
    bool? reasonRequired,
    List<String>? reasonCategories,
    List<String>? approverRoles,
    bool? supportsPendingReference,
    String? lastModifiedBy,
    String? lastModifiedAt,
  }) {
    return StepConfigModel(
      id: id ?? this.id,
      stepCode: stepCode ?? this.stepCode,
      stepNameAr: stepNameAr ?? this.stepNameAr,
      stepNameEn: stepNameEn ?? this.stepNameEn,
      phaseId: phaseId ?? this.phaseId,
      skipPolicy: skipPolicy ?? this.skipPolicy,
      reasonRequired: reasonRequired ?? this.reasonRequired,
      reasonCategories: reasonCategories ?? this.reasonCategories,
      approverRoles: approverRoles ?? this.approverRoles,
      supportsPendingReference:
          supportsPendingReference ?? this.supportsPendingReference,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }
}

/// Audit Log Model for Classification Rules Changes (Section 10.3).
class StepConfigAuditLogModel {
  final int id;
  final String stepCode;
  final String action;
  final String changedBy;
  final String changedAt;
  final String? oldPolicy;
  final String? newPolicy;
  final List<String>? oldApproverRoles;
  final List<String>? newApproverRoles;
  final bool? oldSupportsPendingReference;
  final bool? newSupportsPendingReference;
  final String justification;

  const StepConfigAuditLogModel({
    required this.id,
    required this.stepCode,
    required this.action,
    required this.changedBy,
    required this.changedAt,
    this.oldPolicy,
    this.newPolicy,
    this.oldApproverRoles,
    this.newApproverRoles,
    this.oldSupportsPendingReference,
    this.newSupportsPendingReference,
    required this.justification,
  });

  factory StepConfigAuditLogModel.fromJson(Map<String, dynamic> json) {
    return StepConfigAuditLogModel(
      id: json['id'] as int? ?? 0,
      stepCode: json['step_code'] as String? ?? '',
      action: json['action'] as String? ?? 'UPDATE_POLICY',
      changedBy: json['changed_by'] as String? ?? '',
      changedAt: json['changed_at'] as String? ?? '',
      oldPolicy: json['old_policy'] as String?,
      newPolicy: json['new_policy'] as String?,
      oldApproverRoles: (json['old_approver_roles'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      newApproverRoles: (json['new_approver_roles'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      oldSupportsPendingReference:
          json['old_supports_pending_reference'] as bool?,
      newSupportsPendingReference:
          json['new_supports_pending_reference'] as bool?,
      justification: json['justification'] as String? ?? '',
    );
  }
}

/// Partial / Reference-Only Registration Model (Section 10.4).
class PendingReferenceModel {
  final int id;
  final String importFileCode;
  final String stepCode;
  final String referenceNumber;
  final String reasonText;
  final String? expectedCompletionDate;
  final String? registeredBy;
  final String registeredAt;
  final String status;

  bool get isCompleted => false; // Reference-only step remains incomplete per Section 10.4

  const PendingReferenceModel({
    required this.id,
    required this.importFileCode,
    required this.stepCode,
    required this.referenceNumber,
    required this.reasonText,
    this.expectedCompletionDate,
    this.registeredBy,
    required this.registeredAt,
    this.status = 'Pending Documentation',
  });

  factory PendingReferenceModel.fromJson(Map<String, dynamic> json) {
    return PendingReferenceModel(
      id: json['id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String? ?? '',
      stepCode: json['step_code'] as String? ?? '',
      referenceNumber: json['reference_number'] as String? ?? '',
      reasonText: json['reason_text'] as String? ?? '',
      expectedCompletionDate: json['expected_completion_date'] as String?,
      registeredBy: json['registered_by'] as String?,
      registeredAt: json['registered_at'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending Documentation',
    );
  }
}
