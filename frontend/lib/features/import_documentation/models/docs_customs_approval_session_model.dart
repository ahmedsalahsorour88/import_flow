class DocsCustomsApprovalSessionModel {
  final int sessionId;
  final String sessionCode;
  final int importFileId;
  final String? importFileCode;
  final String? sessionTitle;
  final bool isDraft;
  final String? overallCompliance;
  final int totalChecks;
  final int passedChecks;
  final int failedChecks;
  final List<dynamic>? checksMatrix;
  final List<String>? recommendations;
  final String? sessionNotes;
  final String createdBy;
  final int version;
  final String createdAt;
  final String updatedAt;

  DocsCustomsApprovalSessionModel({
    required this.sessionId,
    required this.sessionCode,
    required this.importFileId,
    this.importFileCode,
    this.sessionTitle,
    this.isDraft = false,
    this.overallCompliance,
    this.totalChecks = 0,
    this.passedChecks = 0,
    this.failedChecks = 0,
    this.checksMatrix,
    this.recommendations,
    this.sessionNotes,
    this.createdBy = 'system',
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocsCustomsApprovalSessionModel.fromJson(Map<String, dynamic> json) {
    return DocsCustomsApprovalSessionModel(
      sessionId: json['session_id'] as int? ?? 0,
      sessionCode: json['session_code'] as String? ?? '',
      importFileId: json['import_file_id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String?,
      sessionTitle: json['session_title'] as String?,
      isDraft: json['is_draft'] as bool? ?? false,
      overallCompliance: json['overall_compliance'] as String?,
      totalChecks: json['total_checks'] as int? ?? 0,
      passedChecks: json['passed_checks'] as int? ?? 0,
      failedChecks: json['failed_checks'] as int? ?? 0,
      checksMatrix: json['checks_matrix'] as List<dynamic>?,
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      sessionNotes: json['session_notes'] as String?,
      createdBy: json['created_by'] as String? ?? 'system',
      version: json['version'] as int? ?? 1,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'session_code': sessionCode,
    'import_file_id': importFileId,
    if (importFileCode != null) 'import_file_code': importFileCode,
    if (sessionTitle != null) 'session_title': sessionTitle,
    'is_draft': isDraft,
    if (overallCompliance != null) 'overall_compliance': overallCompliance,
    'total_checks': totalChecks,
    'passed_checks': passedChecks,
    'failed_checks': failedChecks,
    if (checksMatrix != null) 'checks_matrix': checksMatrix,
    if (recommendations != null) 'recommendations': recommendations,
    if (sessionNotes != null) 'session_notes': sessionNotes,
    'created_by': createdBy,
    'version': version,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
