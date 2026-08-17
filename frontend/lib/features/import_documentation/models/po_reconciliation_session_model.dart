class POReconciliationSessionModel {
  final int? sessionId;
  final String sessionCode;
  final int importFileId;
  final String? importFileCode;
  final String? importerName;
  final String? finalInvoiceNumber;
  final String? finalPackingListNumber;
  final String? acidNumber;
  final String? shipperName;
  final double totalInvoiceAmount;
  final String currency;
  final double totalPackages;
  final double totalNetWeightKg;
  final double totalGrossWeightKg;
  final double totalCbm;
  final String overallStatus;
  final bool isSafeForCertification;
  final int criticalDiscrepanciesCount;
  final int warningDiscrepanciesCount;
  final List<dynamic>? headerDiscrepancies;
  final List<dynamic>? reconciledInvoiceItems;
  final List<dynamic>? reconciledPackingItems;
  final Map<String, dynamic>? extractedInvoiceData;
  final Map<String, dynamic>? extractedPackingData;
  final String? notes;
  final String? certifiedBy;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  POReconciliationSessionModel({
    this.sessionId,
    this.sessionCode = '',
    required this.importFileId,
    this.importFileCode,
    this.importerName,
    this.finalInvoiceNumber,
    this.finalPackingListNumber,
    this.acidNumber,
    this.shipperName,
    this.totalInvoiceAmount = 0.0,
    this.currency = 'EUR',
    this.totalPackages = 0.0,
    this.totalNetWeightKg = 0.0,
    this.totalGrossWeightKg = 0.0,
    this.totalCbm = 0.0,
    this.overallStatus = 'FULLY_MATCHED',
    this.isSafeForCertification = true,
    this.criticalDiscrepanciesCount = 0,
    this.warningDiscrepanciesCount = 0,
    this.headerDiscrepancies,
    this.reconciledInvoiceItems,
    this.reconciledPackingItems,
    this.extractedInvoiceData,
    this.extractedPackingData,
    this.notes,
    this.certifiedBy,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory POReconciliationSessionModel.fromJson(Map<String, dynamic> json) {
    return POReconciliationSessionModel(
      sessionId: json['session_id'] as int?,
      sessionCode: json['session_code'] as String? ?? '',
      importFileId: json['import_file_id'] as int? ?? 0,
      importFileCode: json['import_file_code'] as String?,
      importerName: json['importer_name'] as String?,
      finalInvoiceNumber: json['final_invoice_number'] as String?,
      finalPackingListNumber: json['final_packing_list_number'] as String?,
      acidNumber: json['acid_number'] as String?,
      shipperName: json['shipper_name'] as String?,
      totalInvoiceAmount: (json['total_invoice_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      totalPackages: (json['total_packages'] as num?)?.toDouble() ?? 0.0,
      totalNetWeightKg: (json['total_net_weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalGrossWeightKg: (json['total_gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalCbm: (json['total_cbm'] as num?)?.toDouble() ?? 0.0,
      overallStatus: json['overall_status'] as String? ?? 'FULLY_MATCHED',
      isSafeForCertification: json['is_safe_for_certification'] as bool? ?? true,
      criticalDiscrepanciesCount: json['critical_discrepancies_count'] as int? ?? 0,
      warningDiscrepanciesCount: json['warning_discrepancies_count'] as int? ?? 0,
      headerDiscrepancies: json['header_discrepancies'] as List<dynamic>?,
      reconciledInvoiceItems: json['reconciled_invoice_items'] as List<dynamic>?,
      reconciledPackingItems: json['reconciled_packing_items'] as List<dynamic>?,
      extractedInvoiceData: json['extracted_invoice_data'] as Map<String, dynamic>?,
      extractedPackingData: json['extracted_packing_data'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      certifiedBy: json['certified_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'session_id': sessionId,
      'session_code': sessionCode,
      'import_file_id': importFileId,
      'final_invoice_number': finalInvoiceNumber,
      'final_packing_list_number': finalPackingListNumber,
      'acid_number': acidNumber,
      'shipper_name': shipperName,
      'total_invoice_amount': totalInvoiceAmount,
      'currency': currency,
      'total_packages': totalPackages,
      'total_net_weight_kg': totalNetWeightKg,
      'total_gross_weight_kg': totalGrossWeightKg,
      'total_cbm': totalCbm,
      'overall_status': overallStatus,
      'is_safe_for_certification': isSafeForCertification,
      'critical_discrepancies_count': criticalDiscrepanciesCount,
      'warning_discrepancies_count': warningDiscrepanciesCount,
      'header_discrepancies': headerDiscrepancies,
      'reconciled_invoice_items': reconciledInvoiceItems,
      'reconciled_packing_items': reconciledPackingItems,
      'extracted_invoice_data': extractedInvoiceData,
      'extracted_packing_data': extractedPackingData,
      'notes': notes,
      'certified_by': certifiedBy,
    };
  }
}
