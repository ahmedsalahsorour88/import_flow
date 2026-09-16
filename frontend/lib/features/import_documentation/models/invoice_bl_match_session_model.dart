class InvoiceBLMatchSessionModel {
  final int sessionId;
  final String sessionCode;
  final int importFileId;
  final String? importFileCode;
  final String? sessionTitle;
  final bool isDraft;
  final String? invoiceRawText;
  final String? blRawText;
  final String? packingListRawText;
  final String? invoiceFileName;
  final String? blFileName;
  final String? packingFileName;
  final double matchScore;
  final bool isSafeForCertification;
  final bool hasCriticalDiscrepancies;
  final int discrepancyCount;
  final List<dynamic>? comparisonMatrix;
  final Map<String, dynamic>? invoiceExtractedData;
  final Map<String, dynamic>? blExtractedData;
  final Map<String, dynamic>? packingExtractedData;
  final String? sessionNotes;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  InvoiceBLMatchSessionModel({
    required this.sessionId,
    required this.sessionCode,
    required this.importFileId,
    this.importFileCode,
    this.sessionTitle,
    this.isDraft = false,
    this.invoiceRawText,
    this.blRawText,
    this.packingListRawText,
    this.invoiceFileName,
    this.blFileName,
    this.packingFileName,
    this.matchScore = 0.0,
    this.isSafeForCertification = false,
    this.hasCriticalDiscrepancies = false,
    this.discrepancyCount = 0,
    this.comparisonMatrix,
    this.invoiceExtractedData,
    this.blExtractedData,
    this.packingExtractedData,
    this.sessionNotes,
    this.createdBy = 'system',
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceBLMatchSessionModel.fromJson(Map<String, dynamic> json) {
    return InvoiceBLMatchSessionModel(
      sessionId: json['session_id'] as int? ?? 0,
      sessionCode: json['session_code'] as String? ?? '',
      importFileId: json['import_file_id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String?,
      sessionTitle: json['session_title'] as String?,
      isDraft: json['is_draft'] as bool? ?? false,
      invoiceRawText: json['invoice_raw_text'] as String?,
      blRawText: json['bl_raw_text'] as String?,
      packingListRawText: json['packing_list_raw_text'] as String?,
      invoiceFileName: json['invoice_file_name'] as String?,
      blFileName: json['bl_file_name'] as String?,
      packingFileName: json['packing_file_name'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      isSafeForCertification: json['is_safe_for_certification'] as bool? ?? false,
      hasCriticalDiscrepancies: json['has_critical_discrepancies'] as bool? ?? false,
      discrepancyCount: json['discrepancy_count'] as int? ?? 0,
      comparisonMatrix: json['comparison_matrix'] as List<dynamic>?,
      invoiceExtractedData: json['invoice_extracted_data'] as Map<String, dynamic>?,
      blExtractedData: json['bl_extracted_data'] as Map<String, dynamic>?,
      packingExtractedData: json['packing_extracted_data'] as Map<String, dynamic>?,
      sessionNotes: json['session_notes'] as String?,
      createdBy: json['created_by'] as String? ?? 'system',
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
    if (invoiceRawText != null) 'invoice_raw_text': invoiceRawText,
    if (blRawText != null) 'bl_raw_text': blRawText,
    if (packingListRawText != null) 'packing_list_raw_text': packingListRawText,
    if (invoiceFileName != null) 'invoice_file_name': invoiceFileName,
    if (blFileName != null) 'bl_file_name': blFileName,
    if (packingFileName != null) 'packing_file_name': packingFileName,
    'match_score': matchScore,
    'is_safe_for_certification': isSafeForCertification,
    'has_critical_discrepancies': hasCriticalDiscrepancies,
    'discrepancy_count': discrepancyCount,
    if (comparisonMatrix != null) 'comparison_matrix': comparisonMatrix,
    if (invoiceExtractedData != null) 'invoice_extracted_data': invoiceExtractedData,
    if (blExtractedData != null) 'bl_extracted_data': blExtractedData,
    if (packingExtractedData != null) 'packing_extracted_data': packingExtractedData,
    if (sessionNotes != null) 'session_notes': sessionNotes,
    'created_by': createdBy,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
