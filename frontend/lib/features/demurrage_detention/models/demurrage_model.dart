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
