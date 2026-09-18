class TierRateModel {
  final int fromDay;
  final int? toDay;
  final double ratePerDay;

  TierRateModel({
    required this.fromDay,
    this.toDay,
    required this.ratePerDay,
  });

  factory TierRateModel.fromJson(Map<String, dynamic> json) {
    return TierRateModel(
      fromDay: json['from_day'] ?? 1,
      toDay: json['to_day'],
      ratePerDay: (json['rate_per_day'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_day': fromDay,
      'to_day': toDay,
      'rate_per_day': ratePerDay,
    };
  }
}

class DemurragePolicyModel {
  final int policyId;
  final String carrierName;
  final String containerType;
  final int demurrageFreeDays;
  final int detentionFreeDays;
  final int portStorageFreeDays;
  final String currency;
  final double portStorageDailyRateEgp;
  final List<TierRateModel> demurrageTiers;
  final List<TierRateModel> detentionTiers;
  final String? notes;
  final bool isActive;

  DemurragePolicyModel({
    required this.policyId,
    required this.carrierName,
    required this.containerType,
    required this.demurrageFreeDays,
    required this.detentionFreeDays,
    required this.portStorageFreeDays,
    required this.currency,
    required this.portStorageDailyRateEgp,
    required this.demurrageTiers,
    required this.detentionTiers,
    this.notes,
    required this.isActive,
  });

  factory DemurragePolicyModel.fromJson(Map<String, dynamic> json) {
    return DemurragePolicyModel(
      policyId: json['policy_id'] ?? 0,
      carrierName: json['carrier_name'] ?? '',
      containerType: json['container_type'] ?? '',
      demurrageFreeDays: json['demurrage_free_days'] ?? 14,
      detentionFreeDays: json['detention_free_days'] ?? 7,
      portStorageFreeDays: json['port_storage_free_days'] ?? 5,
      currency: json['currency'] ?? 'USD',
      portStorageDailyRateEgp: (json['port_storage_daily_rate_egp'] ?? 250.0).toDouble(),
      demurrageTiers: (json['demurrage_tiers'] as List?)
              ?.map((t) => TierRateModel.fromJson(t))
              .toList() ??
          [],
      detentionTiers: (json['detention_tiers'] as List?)
              ?.map((t) => TierRateModel.fromJson(t))
              .toList() ??
          [],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class DemurrageTrackingModel {
  final int trackingId;
  final String trackingCode;
  final int? importFileId;
  final String? importFileCode;
  final int? policyId;
  final String carrierName;
  final String billOfLadingNo;
  final String portName;
  final String dischargeDate;
  final String? gateOutDate;
  final String? emptyReturnDate;
  final List<dynamic> containers;
  final double totalDemurrageFx;
  final double totalDetentionFx;
  final double totalStorageEgp;
  final String currency;
  final double exchangeRate;
  final double totalCostEgp;
  final String status;
  final bool isPushedToSettlement;
  final int? settlementRecordId;
  final String? notes;
  final bool isActive;

  DemurrageTrackingModel({
    required this.trackingId,
    required this.trackingCode,
    this.importFileId,
    this.importFileCode,
    this.policyId,
    required this.carrierName,
    required this.billOfLadingNo,
    required this.portName,
    required this.dischargeDate,
    this.gateOutDate,
    this.emptyReturnDate,
    required this.containers,
    required this.totalDemurrageFx,
    required this.totalDetentionFx,
    required this.totalStorageEgp,
    required this.currency,
    required this.exchangeRate,
    required this.totalCostEgp,
    required this.status,
    required this.isPushedToSettlement,
    this.settlementRecordId,
    this.notes,
    required this.isActive,
  });

  factory DemurrageTrackingModel.fromJson(Map<String, dynamic> json) {
    return DemurrageTrackingModel(
      trackingId: json['tracking_id'] ?? 0,
      trackingCode: json['tracking_code'] ?? '',
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'],
      policyId: json['policy_id'],
      carrierName: json['carrier_name'] ?? '',
      billOfLadingNo: json['bill_of_lading_no'] ?? '',
      portName: json['port_name'] ?? 'Alexandria Port',
      dischargeDate: json['discharge_date'] ?? '',
      gateOutDate: json['gate_out_date'],
      emptyReturnDate: json['empty_return_date'],
      containers: json['containers'] ?? [],
      totalDemurrageFx: (json['total_demurrage_fx'] ?? 0.0).toDouble(),
      totalDetentionFx: (json['total_detention_fx'] ?? 0.0).toDouble(),
      totalStorageEgp: (json['total_storage_egp'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      exchangeRate: (json['exchange_rate'] ?? 50.0).toDouble(),
      totalCostEgp: (json['total_cost_egp'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Free Time Active',
      isPushedToSettlement: json['is_pushed_to_settlement'] ?? false,
      settlementRecordId: json['settlement_record_id'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class DemurrageSimulationResultModel {
  final int demurrageDaysConsumed;
  final int demurrageFreeDays;
  final int demurrageDaysOverdue;
  final double demurrageFeeFx;
  final String demurrageExpiryDate;
  final int detentionDaysConsumed;
  final int detentionFreeDays;
  final int detentionDaysOverdue;
  final double detentionFeeFx;
  final String? detentionExpiryDate;
  final int storageDaysConsumed;
  final int storageFreeDays;
  final int storageDaysOverdue;
  final double storageFeeEgp;
  final double totalFeeFx;
  final double totalCostEgp;
  final String statusBadge;
  final String countdownSummaryAr;
  final List<dynamic> breakdownDetails;

  DemurrageSimulationResultModel({
    required this.demurrageDaysConsumed,
    required this.demurrageFreeDays,
    required this.demurrageDaysOverdue,
    required this.demurrageFeeFx,
    required this.demurrageExpiryDate,
    required this.detentionDaysConsumed,
    required this.detentionFreeDays,
    required this.detentionDaysOverdue,
    required this.detentionFeeFx,
    this.detentionExpiryDate,
    required this.storageDaysConsumed,
    required this.storageFreeDays,
    required this.storageDaysOverdue,
    required this.storageFeeEgp,
    required this.totalFeeFx,
    required this.totalCostEgp,
    required this.statusBadge,
    required this.countdownSummaryAr,
    required this.breakdownDetails,
  });

  factory DemurrageSimulationResultModel.fromJson(Map<String, dynamic> json) {
    return DemurrageSimulationResultModel(
      demurrageDaysConsumed: json['demurrage_days_consumed'] ?? 0,
      demurrageFreeDays: json['demurrage_free_days'] ?? 14,
      demurrageDaysOverdue: json['demurrage_days_overdue'] ?? 0,
      demurrageFeeFx: (json['demurrage_fee_fx'] ?? 0.0).toDouble(),
      demurrageExpiryDate: json['demurrage_expiry_date'] ?? '',
      detentionDaysConsumed: json['detention_days_consumed'] ?? 0,
      detentionFreeDays: json['detention_free_days'] ?? 7,
      detentionDaysOverdue: json['detention_days_overdue'] ?? 0,
      detentionFeeFx: (json['detention_fee_fx'] ?? 0.0).toDouble(),
      detentionExpiryDate: json['detention_expiry_date'],
      storageDaysConsumed: json['storage_days_consumed'] ?? 0,
      storageFreeDays: json['storage_free_days'] ?? 5,
      storageDaysOverdue: json['storage_days_overdue'] ?? 0,
      storageFeeEgp: (json['storage_fee_egp'] ?? 0.0).toDouble(),
      totalFeeFx: (json['total_fee_fx'] ?? 0.0).toDouble(),
      totalCostEgp: (json['total_cost_egp'] ?? 0.0).toDouble(),
      statusBadge: json['status_badge'] ?? 'SAFE',
      countdownSummaryAr: json['countdown_summary_ar'] ?? '',
      breakdownDetails: json['breakdown_details'] ?? [],
    );
  }
}

class FreeDaysAgreementModel {
  final int importFileId;
  final String importFileCode;
  final String carrierName;
  final String? bookingCode;
  final String? bookingConfirmationNo;
  final int standardPolicyDemurrageDays;
  final int agreedDemurrageFreeDays;
  final int agreedDetentionFreeDays;
  final int portStorageFreeDays;
  final int additionalFreeDaysGained;
  final double estimatedCostAvoidanceUsd;
  final String? agreementReference;
  final String? agreementDate;
  final String radarStatus;
  final String? notes;

  FreeDaysAgreementModel({
    required this.importFileId,
    required this.importFileCode,
    required this.carrierName,
    this.bookingCode,
    this.bookingConfirmationNo,
    required this.standardPolicyDemurrageDays,
    required this.agreedDemurrageFreeDays,
    required this.agreedDetentionFreeDays,
    required this.portStorageFreeDays,
    required this.additionalFreeDaysGained,
    required this.estimatedCostAvoidanceUsd,
    this.agreementReference,
    this.agreementDate,
    required this.radarStatus,
    this.notes,
  });

  factory FreeDaysAgreementModel.fromJson(Map<String, dynamic> json) {
    return FreeDaysAgreementModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      carrierName: json['carrier_name'] ?? '',
      bookingCode: json['booking_code'],
      bookingConfirmationNo: json['booking_confirmation_no'],
      standardPolicyDemurrageDays: json['standard_policy_demurrage_days'] ?? 14,
      agreedDemurrageFreeDays: json['agreed_demurrage_free_days'] ?? 14,
      agreedDetentionFreeDays: json['agreed_detention_free_days'] ?? 7,
      portStorageFreeDays: json['port_storage_free_days'] ?? 5,
      additionalFreeDaysGained: json['additional_free_days_gained'] ?? 0,
      estimatedCostAvoidanceUsd: (json['estimated_cost_avoidance_usd'] ?? 0.0).toDouble(),
      agreementReference: json['agreement_reference'],
      agreementDate: json['agreement_date']?.toString(),
      radarStatus: json['radar_status'] ?? 'Safe',
      notes: json['notes'],
    );
  }
}

class ContainerRadarItemModel {
  final int trackingId;
  final int importFileId;
  final String importFileCode;
  final String billOfLadingNo;
  final String carrierName;
  final String containerNumber;
  final String containerType;
  final String dischargeDate;
  final String? gateOutDate;
  final String? emptyReturnDate;
  final String radarStatus; // SAFE, WARNING, CRITICAL_OVERDUE, RETURNED_SAFE
  final String colorCode; // #27AE60, #E67E22, #C0392B, #7F8C8D
  final String statusLabelAr;
  final int demurrageDaysConsumed;
  final int demurrageFreeDays;
  final int demurrageDaysRemaining;
  final int storageDaysConsumed;
  final int storageFreeDays;
  final int storageDaysRemaining;
  final double accruedDemurrageUsd;
  final double accruedStorageEgp;
  final double totalAccruedEgp;
  final String alertMessageAr;

  ContainerRadarItemModel({
    required this.trackingId,
    required this.importFileId,
    required this.importFileCode,
    required this.billOfLadingNo,
    required this.carrierName,
    required this.containerNumber,
    required this.containerType,
    required this.dischargeDate,
    this.gateOutDate,
    this.emptyReturnDate,
    required this.radarStatus,
    required this.colorCode,
    required this.statusLabelAr,
    required this.demurrageDaysConsumed,
    required this.demurrageFreeDays,
    required this.demurrageDaysRemaining,
    required this.storageDaysConsumed,
    required this.storageFreeDays,
    required this.storageDaysRemaining,
    required this.accruedDemurrageUsd,
    required this.accruedStorageEgp,
    required this.totalAccruedEgp,
    required this.alertMessageAr,
  });

  factory ContainerRadarItemModel.fromJson(Map<String, dynamic> json) {
    return ContainerRadarItemModel(
      trackingId: json['tracking_id'] ?? 0,
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      billOfLadingNo: json['bill_of_lading_no'] ?? '',
      carrierName: json['carrier_name'] ?? '',
      containerNumber: json['container_number'] ?? '',
      containerType: json['container_type'] ?? '40ft High Cube',
      dischargeDate: json['discharge_date']?.toString() ?? '',
      gateOutDate: json['gate_out_date']?.toString(),
      emptyReturnDate: json['empty_return_date']?.toString(),
      radarStatus: json['radar_status'] ?? 'SAFE',
      colorCode: json['color_code'] ?? '#27AE60',
      statusLabelAr: json['status_label_ar'] ?? '',
      demurrageDaysConsumed: json['demurrage_days_consumed'] ?? 0,
      demurrageFreeDays: json['demurrage_free_days'] ?? 14,
      demurrageDaysRemaining: json['demurrage_days_remaining'] ?? 0,
      storageDaysConsumed: json['storage_days_consumed'] ?? 0,
      storageFreeDays: json['storage_free_days'] ?? 5,
      storageDaysRemaining: json['storage_days_remaining'] ?? 0,
      accruedDemurrageUsd: (json['accrued_demurrage_usd'] ?? 0.0).toDouble(),
      accruedStorageEgp: (json['accrued_storage_egp'] ?? 0.0).toDouble(),
      totalAccruedEgp: (json['total_accrued_egp'] ?? 0.0).toDouble(),
      alertMessageAr: json['alert_message_ar'] ?? '',
    );
  }
}

class ContainerRadarOverviewModel {
  final int totalContainersTracked;
  final int safeContainersCount;
  final int warningContainersCount;
  final int criticalOverdueCount;
  final int returnedContainersCount;
  final double totalAccruedDemurrageUsd;
  final double totalAccruedStorageEgp;
  final double totalEstimatedExposureEgp;
  final List<ContainerRadarItemModel> radarItems;
  final String generatedAt;

  ContainerRadarOverviewModel({
    required this.totalContainersTracked,
    required this.safeContainersCount,
    required this.warningContainersCount,
    required this.criticalOverdueCount,
    required this.returnedContainersCount,
    required this.totalAccruedDemurrageUsd,
    required this.totalAccruedStorageEgp,
    required this.totalEstimatedExposureEgp,
    required this.radarItems,
    required this.generatedAt,
  });

  factory ContainerRadarOverviewModel.fromJson(Map<String, dynamic> json) {
    return ContainerRadarOverviewModel(
      totalContainersTracked: json['total_containers_tracked'] ?? 0,
      safeContainersCount: json['safe_containers_count'] ?? 0,
      warningContainersCount: json['warning_containers_count'] ?? 0,
      criticalOverdueCount: json['critical_overdue_count'] ?? 0,
      returnedContainersCount: json['returned_containers_count'] ?? 0,
      totalAccruedDemurrageUsd: (json['total_accrued_demurrage_usd'] ?? 0.0).toDouble(),
      totalAccruedStorageEgp: (json['total_accrued_storage_egp'] ?? 0.0).toDouble(),
      totalEstimatedExposureEgp: (json['total_estimated_exposure_egp'] ?? 0.0).toDouble(),
      radarItems: (json['radar_items'] as List?)
              ?.map((item) => ContainerRadarItemModel.fromJson(item))
              .toList() ??
          [],
      generatedAt: json['generated_at']?.toString() ?? '',
    );
  }
}

// =========================================================================
// TR-05: Empty Container Return (EIR) Models
// =========================================================================

class EmptyContainerReturnSubmitModel {
  final int importFileId;
  final String eirNumber;
  final String emptyReturnDate;
  final String? depotName;
  final List<String>? returnedContainers;
  final String containerCondition;
  final String? damageNotes;
  final double damageFeeEstimated;
  final String damageCurrency;
  final String? driverName;
  final String? truckPlateNo;
  final String? notes;

  EmptyContainerReturnSubmitModel({
    required this.importFileId,
    required this.eirNumber,
    required this.emptyReturnDate,
    this.depotName,
    this.returnedContainers,
    this.containerCondition = 'SOUND_CLEAN',
    this.damageNotes,
    this.damageFeeEstimated = 0.0,
    this.damageCurrency = 'USD',
    this.driverName,
    this.truckPlateNo,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'import_file_id': importFileId,
      'eir_number': eirNumber,
      'empty_return_date': emptyReturnDate,
      if (depotName != null) 'depot_name': depotName,
      if (returnedContainers != null && returnedContainers!.isNotEmpty)
        'returned_containers': returnedContainers,
      'container_condition': containerCondition,
      if (damageNotes != null) 'damage_notes': damageNotes,
      if (damageFeeEstimated > 0) 'damage_fee_estimated': damageFeeEstimated,
      'damage_currency': damageCurrency,
      if (driverName != null) 'driver_name': driverName,
      if (truckPlateNo != null) 'truck_plate_no': truckPlateNo,
      if (notes != null) 'notes': notes,
    };
  }
}

class EmptyContainerReturnResponseModel {
  final int importFileId;
  final String importFileCode;
  final int? trackingId;
  final String? trackingCode;
  final String eirNumber;
  final String emptyReturnDate;
  final String? depotName;
  final List<String> returnedContainers;
  final int containersReturnedCount;
  final int totalContainersCount;
  final bool allContainersReturned;
  final String containerCondition;
  final double damageFeeEstimated;
  final double demurrageFinalFx;
  final double detentionFinalFx;
  final double storageFinalEgp;
  final double totalExposureEgp;
  final String trackingStatus;
  final String nextAction;
  final String currentStage;
  final double progressPercent;
  final String messageAr;
  final String returnedAt;

  EmptyContainerReturnResponseModel({
    required this.importFileId,
    required this.importFileCode,
    this.trackingId,
    this.trackingCode,
    required this.eirNumber,
    required this.emptyReturnDate,
    this.depotName,
    required this.returnedContainers,
    required this.containersReturnedCount,
    required this.totalContainersCount,
    required this.allContainersReturned,
    required this.containerCondition,
    required this.damageFeeEstimated,
    required this.demurrageFinalFx,
    required this.detentionFinalFx,
    required this.storageFinalEgp,
    required this.totalExposureEgp,
    required this.trackingStatus,
    required this.nextAction,
    required this.currentStage,
    required this.progressPercent,
    required this.messageAr,
    required this.returnedAt,
  });

  factory EmptyContainerReturnResponseModel.fromJson(Map<String, dynamic> json) {
    return EmptyContainerReturnResponseModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      trackingId: json['tracking_id'],
      trackingCode: json['tracking_code'],
      eirNumber: json['eir_number'] ?? '',
      emptyReturnDate: json['empty_return_date']?.toString() ?? '',
      depotName: json['depot_name'],
      returnedContainers: (json['returned_containers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      containersReturnedCount: json['containers_returned_count'] ?? 0,
      totalContainersCount: json['total_containers_count'] ?? 0,
      allContainersReturned: json['all_containers_returned'] ?? false,
      containerCondition: json['container_condition'] ?? 'SOUND_CLEAN',
      damageFeeEstimated: (json['damage_fee_estimated'] ?? 0.0).toDouble(),
      demurrageFinalFx: (json['demurrage_final_fx'] ?? 0.0).toDouble(),
      detentionFinalFx: (json['detention_final_fx'] ?? 0.0).toDouble(),
      storageFinalEgp: (json['storage_final_egp'] ?? 0.0).toDouble(),
      totalExposureEgp: (json['total_exposure_egp'] ?? 0.0).toDouble(),
      trackingStatus: json['tracking_status'] ?? '',
      nextAction: json['next_action'] ?? '',
      currentStage: json['current_stage'] ?? '',
      progressPercent: (json['progress_percent'] ?? 0.0).toDouble(),
      messageAr: json['message_ar'] ?? '',
      returnedAt: json['returned_at']?.toString() ?? '',
    );
  }
}
