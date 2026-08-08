class ContainerLoadingModel {
  final String containerNo;
  final String sealNo;
  final double tareWeightKg;
  final double netWeightKg;
  final double grossWeightKg;
  final String vgmStatus;
  final String? vgmRefNo;

  ContainerLoadingModel({
    required this.containerNo,
    required this.sealNo,
    this.tareWeightKg = 0.0,
    this.netWeightKg = 0.0,
    this.grossWeightKg = 0.0,
    this.vgmStatus = "Submitted",
    this.vgmRefNo,
  });

  factory ContainerLoadingModel.fromJson(Map<String, dynamic> json) {
    return ContainerLoadingModel(
      containerNo: json['container_no'] ?? '',
      sealNo: json['seal_no'] ?? '',
      tareWeightKg: (json['tare_weight_kg'] as num?)?.toDouble() ?? 0.0,
      netWeightKg: (json['net_weight_kg'] as num?)?.toDouble() ?? 0.0,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      vgmStatus: json['vgm_status'] ?? 'Submitted',
      vgmRefNo: json['vgm_ref_no'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'container_no': containerNo,
      'seal_no': sealNo,
      'tare_weight_kg': tareWeightKg,
      'net_weight_kg': netWeightKg,
      'gross_weight_kg': grossWeightKg,
      'vgm_status': vgmStatus,
      'vgm_ref_no': vgmRefNo,
    };
  }
}

class CourierTrackingModel {
  final String courierProvider;
  final String? trackingNumber;
  final String? dispatchDate;
  final String receiptStatus;
  final String? receivedAt;
  final String? receivedBy;

  CourierTrackingModel({
    this.courierProvider = 'DHL Express',
    this.trackingNumber,
    this.dispatchDate,
    this.receiptStatus = 'Dispatched',
    this.receivedAt,
    this.receivedBy,
  });

  factory CourierTrackingModel.fromJson(Map<String, dynamic> json) {
    return CourierTrackingModel(
      courierProvider: json['courier_provider'] ?? 'DHL Express',
      trackingNumber: json['tracking_number'],
      dispatchDate: json['dispatch_date'],
      receiptStatus: json['receipt_status'] ?? 'Dispatched',
      receivedAt: json['received_at'],
      receivedBy: json['received_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courier_provider': courierProvider,
      'tracking_number': trackingNumber,
      'dispatch_date': dispatchDate,
      'receipt_status': receiptStatus,
      'received_at': receivedAt,
      'received_by': receivedBy,
    };
  }
}

class CargoXChecklistRule {
  final String ruleName;
  final bool passed;
  final String? details;

  CargoXChecklistRule({
    required this.ruleName,
    this.passed = false,
    this.details,
  });

  factory CargoXChecklistRule.fromJson(Map<String, dynamic> json) {
    return CargoXChecklistRule(
      ruleName: json['rule_name'] ?? '',
      passed: json['passed'] ?? false,
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rule_name': ruleName,
      'passed': passed,
      'details': details,
    };
  }
}

class CargoXExchangeModel {
  final String platformProvider;
  final String? envelopeId;
  final String envelopeStatus;
  final String? blockchainTxHash;
  final List<CargoXChecklistRule> verificationChecklist;

  CargoXExchangeModel({
    this.platformProvider = 'CargoX Platform',
    this.envelopeId,
    this.envelopeStatus = 'Created',
    this.blockchainTxHash,
    this.verificationChecklist = const [],
  });

  factory CargoXExchangeModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['verification_checklist'] as List<dynamic>? ?? [];
    return CargoXExchangeModel(
      platformProvider: json['platform_provider'] ?? 'CargoX Platform',
      envelopeId: json['envelope_id'],
      envelopeStatus: json['envelope_status'] ?? 'Created',
      blockchainTxHash: json['blockchain_tx_hash'],
      verificationChecklist: rawList.map((e) => CargoXChecklistRule.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform_provider': platformProvider,
      'envelope_id': envelopeId,
      'envelope_status': envelopeStatus,
      'blockchain_tx_hash': blockchainTxHash,
      'verification_checklist': verificationChecklist.map((e) => e.toJson()).toList(),
    };
  }
}

class CargoShippingModel {
  final int cargoShippingId;
  final String cargoShippingCode;
  final int importFileId;
  final int? bookingId;
  final String? crdDate;
  final String? cargoCutoffDate;
  final bool isCrdValidated;
  final List<ContainerLoadingModel> containersLoadingData;
  final String level1ApprovalStatus;
  final String? level1ApprovedBy;
  final String? level1ApprovedAt;
  final String? level1Notes;
  final String level2ApprovalStatus;
  final String? level2ApprovedBy;
  final String? level2ApprovedAt;
  final String? level2Notes;
  final String dualApprovalStatus;
  final CourierTrackingModel courierTrackingData;
  final CargoXExchangeModel cargoxExchangeData;
  final String? liveTrackingUrl;
  final String status;
  final String owner;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  CargoShippingModel({
    required this.cargoShippingId,
    required this.cargoShippingCode,
    required this.importFileId,
    this.bookingId,
    this.crdDate,
    this.cargoCutoffDate,
    this.isCrdValidated = true,
    this.containersLoadingData = const [],
    this.level1ApprovalStatus = 'Pending',
    this.level1ApprovedBy,
    this.level1ApprovedAt,
    this.level1Notes,
    this.level2ApprovalStatus = 'Pending',
    this.level2ApprovedBy,
    this.level2ApprovedAt,
    this.level2Notes,
    this.dualApprovalStatus = 'Pending',
    required this.courierTrackingData,
    required this.cargoxExchangeData,
    this.liveTrackingUrl,
    this.status = 'Cargo Ready',
    this.owner = 'Kamal',
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CargoShippingModel.fromJson(Map<String, dynamic> json) {
    var rawCont = json['containers_loading_data'] as List<dynamic>? ?? [];
    return CargoShippingModel(
      cargoShippingId: json['cargo_shipping_id'],
      cargoShippingCode: json['cargo_shipping_code'] ?? '',
      importFileId: json['import_file_id'],
      bookingId: json['booking_id'],
      crdDate: json['crd_date'],
      cargoCutoffDate: json['cargo_cutoff_date'],
      isCrdValidated: json['is_crd_validated'] ?? true,
      containersLoadingData: rawCont.map((e) => ContainerLoadingModel.fromJson(e)).toList(),
      level1ApprovalStatus: json['level1_approval_status'] ?? 'Pending',
      level1ApprovedBy: json['level1_approved_by'],
      level1ApprovedAt: json['level1_approved_at'],
      level1Notes: json['level1_notes'],
      level2ApprovalStatus: json['level2_approval_status'] ?? 'Pending',
      level2ApprovedBy: json['level2_approved_by'],
      level2ApprovedAt: json['level2_approved_at'],
      level2Notes: json['level2_notes'],
      dualApprovalStatus: json['dual_approval_status'] ?? 'Pending',
      courierTrackingData: CourierTrackingModel.fromJson(json['courier_tracking_data'] ?? {}),
      cargoxExchangeData: CargoXExchangeModel.fromJson(json['cargox_exchange_data'] ?? {}),
      liveTrackingUrl: json['live_tracking_url'],
      status: json['status'] ?? 'Cargo Ready',
      owner: json['owner'] ?? 'Kamal',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo_shipping_id': cargoShippingId,
      'cargo_shipping_code': cargoShippingCode,
      'import_file_id': importFileId,
      'booking_id': bookingId,
      'crd_date': crdDate,
      'cargo_cutoff_date': cargoCutoffDate,
      'is_crd_validated': isCrdValidated,
      'containers_loading_data': containersLoadingData.map((e) => e.toJson()).toList(),
      'courier_tracking_data': courierTrackingData.toJson(),
      'cargox_exchange_data': cargoxExchangeData.toJson(),
      'live_tracking_url': liveTrackingUrl,
      'status': status,
      'owner': owner,
      'notes': notes,
    };
  }
}
