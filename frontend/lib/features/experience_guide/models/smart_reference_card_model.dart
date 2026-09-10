import 'guide_entry_model.dart';

class SmartReferenceCardModel {
  final int importFileId;
  final String importFileCode;
  final String? customFileNumber;
  final Map<String, dynamic> productSummary;
  final Map<String, dynamic> routeSummary;
  final Map<String, dynamic> criticalDates;
  final Map<String, dynamic> documentStatus;
  final List<GuideEntryModel> matchedGuideEntries;
  final Map<String, dynamic> costSummary;

  SmartReferenceCardModel({
    required this.importFileId,
    required this.importFileCode,
    this.customFileNumber,
    this.productSummary = const {},
    this.routeSummary = const {},
    this.criticalDates = const {},
    this.documentStatus = const {},
    this.matchedGuideEntries = const [],
    this.costSummary = const {},
  });

  factory SmartReferenceCardModel.fromJson(Map<String, dynamic> json) {
    var rawEntries = json['matched_guide_entries'] as List<dynamic>? ?? [];
    return SmartReferenceCardModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      customFileNumber: json['custom_file_number'],
      productSummary: (json['product_summary'] as Map<String, dynamic>?) ?? {},
      routeSummary: (json['route_summary'] as Map<String, dynamic>?) ?? {},
      criticalDates: (json['critical_dates'] as Map<String, dynamic>?) ?? {},
      documentStatus: (json['document_status'] as Map<String, dynamic>?) ?? {},
      matchedGuideEntries: rawEntries.map((e) => GuideEntryModel.fromJson(e as Map<String, dynamic>)).toList(),
      costSummary: (json['cost_summary'] as Map<String, dynamic>?) ?? {},
    );
  }

  // Convenient helper getters
  String get hsCode => (productSummary['hs_code'] as String?) ?? '';
  String get productCategory => (productSummary['product_category'] as String?) ?? '';
  double get totalCbm => (productSummary['total_cbm'] as num?)?.toDouble() ?? 0.0;
  double get totalGrossWeightKg => (productSummary['total_gross_weight_kg'] as num?)?.toDouble() ?? 0.0;
  int get packagesCount => (productSummary['packages_count'] as num?)?.toInt() ?? 0;

  String get originPort => (routeSummary['origin_port'] as String?) ?? 'غير محدد';
  String get destinationPort => (routeSummary['destination_port'] as String?) ?? 'ميناء الإسكندرية';
  String get carrier => (routeSummary['shipping_line'] as String?) ?? '';

  int get freeDays => (criticalDates['target_free_days'] as num?)?.toInt() ?? 21;
  String get freeTimeStatus => (criticalDates['free_time_status'] as String?) ?? '';

  bool get isDocsComplete => documentStatus['is_complete'] as bool? ?? false;
  bool get hasCooAttached => documentStatus['has_coo_attached'] as bool? ?? false;
  bool get isCooRequired => documentStatus['is_coo_required'] as bool? ?? false;
  List<String> get attachedDocuments => (documentStatus['attached_documents'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  List<String> get pendingDocuments => (documentStatus['pending_documents'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  double get estimatedCost => (costSummary['estimated_cost'] as num?)?.toDouble() ?? 0.0;
  double get actualCost => (costSummary['actual_invoiced_cost'] as num?)?.toDouble() ?? 0.0;
  double get varianceAmount => (costSummary['variance_amount'] as num?)?.toDouble() ?? 0.0;
  double get variancePercentage => (costSummary['variance_percentage'] as num?)?.toDouble() ?? 0.0;
  String get currency => (costSummary['currency'] as String?) ?? 'USD';
}
