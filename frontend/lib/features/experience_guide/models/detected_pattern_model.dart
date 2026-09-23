class DetectedPatternModel {
  final String patternType;
  final String dimensionType;
  final String dimensionValue;
  final String description;
  final String suggestedAction;
  final String severity;
  final int occurrenceCount;
  final List<String> evidenceShipments;

  DetectedPatternModel({
    required this.patternType,
    required this.dimensionType,
    required this.dimensionValue,
    required this.description,
    required this.suggestedAction,
    this.severity = 'warning',
    this.occurrenceCount = 1,
    this.evidenceShipments = const [],
  });

  factory DetectedPatternModel.fromJson(Map<String, dynamic> json) {
    var rawEvidence = json['evidence_shipments'] as List<dynamic>? ?? [];
    return DetectedPatternModel(
      patternType: json['pattern_type'] ?? '',
      dimensionType: json['dimension_type'] ?? '',
      dimensionValue: json['dimension_value'] ?? '',
      description: json['description'] ?? '',
      suggestedAction: json['suggested_action'] ?? '',
      severity: json['severity'] ?? 'warning',
      occurrenceCount: json['occurrence_count'] ?? 1,
      evidenceShipments: rawEvidence.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern_type': patternType,
      'dimension_type': dimensionType,
      'dimension_value': dimensionValue,
      'description': description,
      'suggested_action': suggestedAction,
      'severity': severity,
      'occurrence_count': occurrenceCount,
      'evidence_shipments': evidenceShipments,
    };
  }
}
