class ShippingScenarioItemModel {
  final int? itemId;
  final int? providerId;
  final String providerName;
  final String vesselName;
  final String? voyageNumber;
  final String sailingDate;
  final String estimatedArrivalDate;
  final int expectedLineDelayDays;
  final bool isExcludedFromAverage;
  final bool isRecommended;
  final bool isSelected;
  final String riskLevel;
  final String? notes;

  // Calculated fields
  final int vesselLeadTimeDays;
  final int readyForShippingDays;
  final int expectedTotalDaysToWarehouse;
  final String expectedWarehouseArrivalDate;

  ShippingScenarioItemModel({
    this.itemId,
    this.providerId,
    required this.providerName,
    required this.vesselName,
    this.voyageNumber,
    required this.sailingDate,
    required this.estimatedArrivalDate,
    this.expectedLineDelayDays = 0,
    this.isExcludedFromAverage = false,
    this.isRecommended = false,
    this.isSelected = false,
    this.riskLevel = 'Low',
    this.notes,
    this.vesselLeadTimeDays = 0,
    this.readyForShippingDays = 0,
    this.expectedTotalDaysToWarehouse = 0,
    this.expectedWarehouseArrivalDate = '',
  });

  factory ShippingScenarioItemModel.fromJson(Map<String, dynamic> json) {
    return ShippingScenarioItemModel(
      itemId: json['item_id'],
      providerId: json['provider_id'],
      providerName: json['provider_name'] ?? '',
      vesselName: json['vessel_name'] ?? '',
      voyageNumber: json['voyage_number'],
      sailingDate: json['sailing_date'] ?? '',
      estimatedArrivalDate: json['estimated_arrival_date'] ?? '',
      expectedLineDelayDays: json['expected_line_delay_days'] ?? 0,
      isExcludedFromAverage: json['is_excluded_from_average'] ?? false,
      isRecommended: json['is_recommended'] ?? false,
      isSelected: json['is_selected'] ?? false,
      riskLevel: json['risk_level'] ?? 'Low',
      notes: json['notes'],
      vesselLeadTimeDays: json['vessel_lead_time_days'] ?? 0,
      readyForShippingDays: json['ready_for_shipping_days'] ?? 0,
      expectedTotalDaysToWarehouse: json['expected_total_days_to_warehouse'] ?? 0,
      expectedWarehouseArrivalDate: json['expected_warehouse_arrival_date'] ?? '',
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (providerId != null) 'provider_id': providerId,
      'provider_name': providerName,
      'vessel_name': vesselName,
      if (voyageNumber != null && voyageNumber!.isNotEmpty) 'voyage_number': voyageNumber,
      'sailing_date': sailingDate,
      'estimated_arrival_date': estimatedArrivalDate,
      'expected_line_delay_days': expectedLineDelayDays,
      'is_excluded_from_average': isExcludedFromAverage,
      'is_recommended': isRecommended,
      'is_selected': isSelected,
      'risk_level': riskLevel,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class ShippingEvaluationModel {
  final int? sessionId;
  final String sessionCode;
  final String? title;
  final int? importFileId;
  final String cargoReadyDate;
  final int? portOfLoadingId;
  final int? portOfDischargeId;
  final int avgForm4Days;
  final int avgClearanceDays;
  final int? poId;
  final int? projectId;
  final String? notes;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  final String? importFileCode;
  final String? poNumber;
  final String? projectName;
  final String? polName;
  final String? podName;

  final List<ShippingScenarioItemModel> items;

  // Calculated metrics
  final double avgExpectedTransitDays;
  final String? avgExpectedWarehouseArrivalDate;
  final String? earliestArrivalScenarioProvider;
  final String? earliestArrivalDate;
  final String? latestArrivalScenarioProvider;
  final String? latestArrivalDate;
  final String? recommendedScenarioProvider;

  ShippingEvaluationModel({
    this.sessionId,
    required this.sessionCode,
    this.title,
    this.importFileId,
    required this.cargoReadyDate,
    this.portOfLoadingId,
    this.portOfDischargeId,
    this.avgForm4Days = 5,
    this.avgClearanceDays = 7,
    this.poId,
    this.projectId,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.importFileCode,
    this.poNumber,
    this.projectName,
    this.polName,
    this.podName,
    this.items = const [],
    this.avgExpectedTransitDays = 0.0,
    this.avgExpectedWarehouseArrivalDate,
    this.earliestArrivalScenarioProvider,
    this.earliestArrivalDate,
    this.latestArrivalScenarioProvider,
    this.latestArrivalDate,
    this.recommendedScenarioProvider,
  });

  factory ShippingEvaluationModel.fromJson(Map<String, dynamic> json) {
    return ShippingEvaluationModel(
      sessionId: json['session_id'],
      sessionCode: json['session_code'] ?? '',
      title: json['title'],
      importFileId: json['import_file_id'],
      cargoReadyDate: json['cargo_ready_date'] ?? '',
      portOfLoadingId: json['port_of_loading_id'],
      portOfDischargeId: json['port_of_discharge_id'],
      avgForm4Days: json['avg_form4_days'] ?? 5,
      avgClearanceDays: json['avg_clearance_days'] ?? 7,
      poId: json['po_id'],
      projectId: json['project_id'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      importFileCode: json['import_file_code'],
      poNumber: json['po_number'],
      projectName: json['project_name'],
      polName: json['pol_name'],
      podName: json['pod_name'],
      items: (json['items'] as List? ?? [])
          .map((i) => ShippingScenarioItemModel.fromJson(i))
          .toList(),
      avgExpectedTransitDays: (json['avg_expected_transit_days'] as num? ?? 0).toDouble(),
      avgExpectedWarehouseArrivalDate: json['avg_expected_warehouse_arrival_date'],
      earliestArrivalScenarioProvider: json['earliest_arrival_scenario_provider'],
      earliestArrivalDate: json['earliest_arrival_date'],
      latestArrivalScenarioProvider: json['latest_arrival_scenario_provider'],
      latestArrivalDate: json['latest_arrival_date'],
      recommendedScenarioProvider: json['recommended_scenario_provider'],
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (title != null && title!.isNotEmpty) 'title': title,
      if (importFileId != null) 'import_file_id': importFileId,
      'cargo_ready_date': cargoReadyDate,
      if (portOfLoadingId != null) 'port_of_loading_id': portOfLoadingId,
      if (portOfDischargeId != null) 'port_of_discharge_id': portOfDischargeId,
      'avg_form4_days': avgForm4Days,
      'avg_clearance_days': avgClearanceDays,
      if (poId != null) 'po_id': poId,
      if (projectId != null) 'project_id': projectId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'items': items.map((i) => i.toCreateJson()).toList(),
    };
  }
}
