import 'dart:convert';

/// Model representing the shared active shipment and lifecycle step context
/// between the free-text chat surface and the interactive lifecycle navigator.
class ActiveShipmentContext {
  final int shipmentId;
  final String shipmentName;
  final String clientName;
  final String fileCode;
  final int stepId;
  final String stepNameAr;
  final String stepNameEn;
  final String? screenReference;
  final DateTime setAt;

  const ActiveShipmentContext({
    required this.shipmentId,
    required this.shipmentName,
    required this.clientName,
    required this.fileCode,
    required this.stepId,
    required this.stepNameAr,
    required this.stepNameEn,
    this.screenReference,
    required this.setAt,
  });

  /// Localized step name based on active language ('ar' or 'en')
  String stepName(String lang) => lang == 'en' ? stepNameEn : stepNameAr;

  /// Human-readable label for context badge (e.g., "PET Stock – SCAS ← تخصيص الحاويات")
  String displayText(String lang) {
    return '$shipmentName – $clientName ← ${stepName(lang)}';
  }

  /// Checks if the context has exceeded the configurable inactivity timeout (default: 4 hours)
  bool isExpired({Duration timeout = const Duration(hours: 4)}) {
    return DateTime.now().difference(setAt) > timeout;
  }

  ActiveShipmentContext copyWith({
    int? shipmentId,
    String? shipmentName,
    String? clientName,
    String? fileCode,
    int? stepId,
    String? stepNameAr,
    String? stepNameEn,
    String? screenReference,
    DateTime? setAt,
  }) {
    return ActiveShipmentContext(
      shipmentId: shipmentId ?? this.shipmentId,
      shipmentName: shipmentName ?? this.shipmentName,
      clientName: clientName ?? this.clientName,
      fileCode: fileCode ?? this.fileCode,
      stepId: stepId ?? this.stepId,
      stepNameAr: stepNameAr ?? this.stepNameAr,
      stepNameEn: stepNameEn ?? this.stepNameEn,
      screenReference: screenReference ?? this.screenReference,
      setAt: setAt ?? this.setAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipment_id': shipmentId,
      'shipment_name': shipmentName,
      'client_name': clientName,
      'file_code': fileCode,
      'step_id': stepId,
      'step_name_ar': stepNameAr,
      'step_name_en': stepNameEn,
      'screen_reference': screenReference,
      'set_at': setAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory ActiveShipmentContext.fromJson(Map<String, dynamic> json) {
    return ActiveShipmentContext(
      shipmentId: (json['shipment_id'] as num?)?.toInt() ?? 0,
      shipmentName: json['shipment_name'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      fileCode: json['file_code'] as String? ?? '',
      stepId: (json['step_id'] as num?)?.toInt() ?? 1,
      stepNameAr: json['step_name_ar'] as String? ?? '',
      stepNameEn: json['step_name_en'] as String? ?? '',
      screenReference: json['screen_reference'] as String?,
      setAt: json['set_at'] != null
          ? DateTime.tryParse(json['set_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static ActiveShipmentContext? fromJsonString(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ActiveShipmentContext.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
