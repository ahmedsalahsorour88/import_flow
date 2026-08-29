class InvoiceItemModel {
  final String invoiceNo;
  final String invoiceType;
  final String? date;
  final double amount;
  final String currency;

  InvoiceItemModel({
    required this.invoiceNo,
    this.invoiceType = 'Proforma Invoice',
    this.date,
    this.amount = 0.0,
    this.currency = 'USD',
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      invoiceNo: json['invoice_no'] ?? '',
      invoiceType: json['invoice_type'] ?? 'Proforma Invoice',
      date: json['date'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_no': invoiceNo,
      'invoice_type': invoiceType,
      'date': date,
      'amount': amount,
      'currency': currency,
    };
  }
}

class PackingListItemModel {
  final String plNo;
  final String? date;
  final int totalPackages;
  final double grossWeightKg;
  final double cbm;
  final bool isStackable;

  PackingListItemModel({
    required this.plNo,
    this.date,
    this.totalPackages = 0,
    this.grossWeightKg = 0.0,
    this.cbm = 0.0,
    this.isStackable = true,
  });

  factory PackingListItemModel.fromJson(Map<String, dynamic> json) {
    return PackingListItemModel(
      plNo: json['pl_no'] ?? '',
      date: json['date'],
      totalPackages: json['total_packages'] ?? 0,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      cbm: (json['cbm'] as num?)?.toDouble() ?? 0.0,
      isStackable: json['is_stackable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pl_no': plNo,
      'date': date,
      'total_packages': totalPackages,
      'gross_weight_kg': grossWeightKg,
      'cbm': cbm,
      'is_stackable': isStackable,
    };
  }
}

class ImportFileModel {
  final int importFileId;
  final String importFileCode;
  final String? customFileNumber;
  final int? companyId;
  final String companyName;
  final int? supplierId;
  final String supplierName;
  final int? brokerId;
  final String? brokerName;
  final String? poNumber;
  final List<int>? poIds;
  final String? piNumber;
  final List<InvoiceItemModel> invoicesData;
  final List<PackingListItemModel> packingListsData;
  final List<int> projectIds;
  final String? projectNames;
  final String shipmentMode;
  final String incotermCode;
  final String priority;
  final String shipmentCategory;
  final String? requiredEta;
  final String? fileOpeningDate;
  final String? selectedScenario;
  final String? pickupAddress;
  final String? portOfLoading;
  final String? portOfDischarge;
  final String? cargoReadyDate;
  final int? targetFreeDays;
  final String? serviceTypePreference;
  final String? shippingInstructionsNotes;
  final String? acidNumber;
  final String? acidRequestDate;
  final String? acidIssueDate;
  final String? acidExpiryDate;
  final int? acidExecutionDays;
  final bool isCustomsReleased;
  final String? customsReleasedAt;
  final String? form4No;
  final String? form4RequestDate;
  final String? form4ReceivedDate;
  final int? form4ExecutionDays;
  final String? swiftNo;
  final String? form46No;
  final double estimatedCost;
  final String estimatedCostCurrency;
  final String currentModule;
  final String currentStage;
  final double progressPercent;
  final String nextAction;
  final String? initialStartingStage;
  final String? initialStartingStep;
  final String? pausedAtStage;
  final String? pausedAtStep;
  final String? holdReason;
  final String? holdDate;
  final List<String> skippedStages;
  final String status;
  final String owner;
  final String? notes;
  final String? closureReason;
  final String? closedAtPhase;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  ImportFileModel({
    required this.importFileId,
    required this.importFileCode,
    this.customFileNumber,
    this.companyId,
    required this.companyName,
    this.supplierId,
    required this.supplierName,
    this.brokerId,
    this.brokerName,
    this.poNumber,
    this.poIds,
    this.piNumber,
    this.invoicesData = const [],
    this.packingListsData = const [],
    this.projectIds = const [],
    this.projectNames,
    this.shipmentMode = 'Sea FCL',
    this.incotermCode = 'FOB',
    this.priority = 'High',
    this.shipmentCategory = 'New Purchase',
    this.requiredEta,
    this.fileOpeningDate,
    this.selectedScenario,
    this.pickupAddress,
    this.portOfLoading,
    this.portOfDischarge = 'El Dekheila Port (non TMT)',
    this.cargoReadyDate,
    this.targetFreeDays = 21,
    this.serviceTypePreference = 'Direct',
    this.shippingInstructionsNotes,
    this.acidNumber,
    this.acidRequestDate,
    this.acidIssueDate,
    this.acidExpiryDate,
    this.acidExecutionDays,
    this.isCustomsReleased = false,
    this.customsReleasedAt,
    this.form4No,
    this.form4RequestDate,
    this.form4ReceivedDate,
    this.form4ExecutionDays,
    this.swiftNo,
    this.form46No,
    this.estimatedCost = 0.0,
    this.estimatedCostCurrency = 'USD',
    required this.currentModule,
    required this.currentStage,
    this.progressPercent = 10.0,
    required this.nextAction,
    this.initialStartingStage = 'Phase 1 - Planning & Feasibility',
    this.initialStartingStep = 'STEP_01',
    this.pausedAtStage,
    this.pausedAtStep,
    this.holdReason,
    this.holdDate,
    this.skippedStages = const [],
    this.status = 'Open',
    this.owner = 'Kamal',
    this.notes,
    this.closureReason,
    this.closedAtPhase,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImportFileModel.fromJson(Map<String, dynamic> json) {
    var rawInvoices = json['invoices_data'] as List<dynamic>? ?? [];
    var rawPacking = json['packing_lists_data'] as List<dynamic>? ?? [];
    var rawProjects = json['project_ids'] as List<dynamic>? ?? [];
    var rawSkipped = json['skipped_stages'] as List<dynamic>? ?? [];

    return ImportFileModel(
      importFileId: json['import_file_id'],
      importFileCode: json['import_file_code'] ?? '',
      customFileNumber: json['custom_file_number'],
      companyId: json['company_id'],
      companyName: json['company_name'] ?? '',
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'] ?? '',
      brokerId: json['broker_id'],
      brokerName: json['broker_name'],
      poNumber: json['po_number'],
      poIds: (json['po_ids'] as List<dynamic>?)?.map((e) => e as int).toList(),
      piNumber: json['pi_number'],
      invoicesData: rawInvoices.map((i) => InvoiceItemModel.fromJson(i)).toList(),
      packingListsData: rawPacking.map((p) => PackingListItemModel.fromJson(p)).toList(),
      projectIds: rawProjects.map((p) => p as int).toList(),
      projectNames: json['project_names'],
      shipmentMode: json['shipment_mode'] ?? 'Sea FCL',
      incotermCode: json['incoterm_code'] ?? 'FOB',
      priority: json['priority'] ?? 'High',
      shipmentCategory: json['shipment_category'] ?? 'New Purchase',
      requiredEta: json['required_eta'],
      fileOpeningDate: json['file_opening_date'],
      selectedScenario: json['selected_scenario'],
      pickupAddress: json['pickup_address'],
      portOfLoading: json['port_of_loading'],
      portOfDischarge: json['port_of_discharge'] ?? 'El Dekheila Port (non TMT)',
      cargoReadyDate: json['cargo_ready_date'],
      targetFreeDays: json['target_free_days'] as int? ?? 21,
      serviceTypePreference: json['service_type_preference'] ?? 'Direct',
      shippingInstructionsNotes: json['shipping_instructions_notes'],
      acidNumber: json['acid_number'],
      acidRequestDate: json['acid_request_date'],
      acidIssueDate: json['acid_issue_date'],
      acidExpiryDate: json['acid_expiry_date'],
      acidExecutionDays: json['acid_execution_days'] as int?,
      isCustomsReleased: json['is_customs_released'] ?? false,
      customsReleasedAt: json['customs_released_at'],
      form4No: json['form4_no'],
      form4RequestDate: json['form4_request_date'],
      form4ReceivedDate: json['form4_received_date'],
      form4ExecutionDays: json['form4_execution_days'] as int?,
      swiftNo: json['swift_no'],
      form46No: json['form46_no'],
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      estimatedCostCurrency: json['estimated_cost_currency'] ?? 'USD',
      currentModule: json['current_module'] ?? '',
      currentStage: json['current_stage'] ?? '',
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      nextAction: json['next_action'] ?? '',
      initialStartingStage: json['initial_starting_stage'],
      initialStartingStep: json['initial_starting_step'],
      pausedAtStage: json['paused_at_stage'],
      pausedAtStep: json['paused_at_step'],
      holdReason: json['hold_reason'],
      holdDate: json['hold_date'],
      skippedStages: rawSkipped.map((s) => s.toString()).toList(),
      status: json['status'] ?? 'Open',
      owner: json['owner'] ?? 'Kamal',
      notes: json['notes'],
      closureReason: json['closure_reason'],
      closedAtPhase: json['closed_at_phase'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'import_file_id': importFileId,
      'import_file_code': importFileCode,
      'custom_file_number': customFileNumber,
      'company_id': companyId,
      'company_name': companyName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'broker_id': brokerId,
      'broker_name': brokerName,
      'po_number': poNumber,
      'po_ids': poIds,
      'pi_number': piNumber,
      'invoices_data': invoicesData.map((i) => i.toJson()).toList(),
      'packing_lists_data': packingListsData.map((p) => p.toJson()).toList(),
      'project_ids': projectIds,
      'project_names': projectNames,
      'shipment_mode': shipmentMode,
      'incoterm_code': incotermCode,
      'priority': priority,
      'shipment_category': shipmentCategory,
      'required_eta': requiredEta,
      'file_opening_date': fileOpeningDate,
      'selected_scenario': selectedScenario,
      'pickup_address': pickupAddress,
      'port_of_loading': portOfLoading,
      'port_of_discharge': portOfDischarge,
      'cargo_ready_date': cargoReadyDate,
      'target_free_days': targetFreeDays,
      'service_type_preference': serviceTypePreference,
      'shipping_instructions_notes': shippingInstructionsNotes,
      'acid_number': acidNumber,
      'acid_request_date': acidRequestDate,
      'acid_issue_date': acidIssueDate,
      'acid_expiry_date': acidExpiryDate,
      'acid_execution_days': acidExecutionDays,
      'is_customs_released': isCustomsReleased,
      'customs_released_at': customsReleasedAt,
      'form4_no': form4No,
      'form4_request_date': form4RequestDate,
      'form4_received_date': form4ReceivedDate,
      'form4_execution_days': form4ExecutionDays,
      'swift_no': swiftNo,
      'form46_no': form46No,
      'estimated_cost': estimatedCost,
      'estimated_cost_currency': estimatedCostCurrency,
      if (initialStartingStage != null) 'initial_starting_stage': initialStartingStage,
      if (initialStartingStep != null) 'initial_starting_step': initialStartingStep,
      if (pausedAtStage != null) 'paused_at_stage': pausedAtStage,
      if (pausedAtStep != null) 'paused_at_step': pausedAtStep,
      if (holdReason != null) 'hold_reason': holdReason,
      if (holdDate != null) 'hold_date': holdDate,
      'skipped_stages': skippedStages,
      'status': status,
      'owner': owner,
      'notes': notes,
      'is_active': isActive,
    };
  }
}

class FreightRfqDataModel {
  final int importFileId;
  final String importFileCode;
  final String? customFileNumber;
  final String companyName;
  final String supplierName;
  final String incotermCode;
  final String commodity;
  final String hsCodes;
  final String shipmentMode;
  final bool isAir;
  final String recommendedContainers;
  final double totalCbm;
  final double grossWeightKg;
  final double netWeightKg;
  final double volumetricWeightKg;
  final double chargeableWeightKg;
  final int totalPackages;
  final String packagesBreakdown;
  final String stackability;
  final String pickupAddress;
  final String portOfLoading;
  final String portOfDischarge;
  final String cargoReadyDate;
  final int targetFreeDays;
  final String serviceType;
  final String specialRequirements;
  final String emailSubject;
  final String emailBodyTemplate;
  final String whatsappTextTemplate;

  FreightRfqDataModel({
    required this.importFileId,
    required this.importFileCode,
    this.customFileNumber,
    required this.companyName,
    required this.supplierName,
    required this.incotermCode,
    required this.commodity,
    this.hsCodes = '',
    required this.shipmentMode,
    this.isAir = false,
    required this.recommendedContainers,
    required this.totalCbm,
    required this.grossWeightKg,
    required this.netWeightKg,
    this.volumetricWeightKg = 0.0,
    this.chargeableWeightKg = 0.0,
    required this.totalPackages,
    required this.packagesBreakdown,
    this.stackability = 'Stackable',
    required this.pickupAddress,
    required this.portOfLoading,
    required this.portOfDischarge,
    required this.cargoReadyDate,
    required this.targetFreeDays,
    required this.serviceType,
    required this.specialRequirements,
    required this.emailSubject,
    required this.emailBodyTemplate,
    required this.whatsappTextTemplate,
  });

  factory FreightRfqDataModel.fromJson(Map<String, dynamic> json) {
    return FreightRfqDataModel(
      importFileId: json['import_file_id'] ?? 0,
      importFileCode: json['import_file_code'] ?? '',
      customFileNumber: json['custom_file_number'],
      companyName: json['company_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      incotermCode: json['incoterm_code'] ?? 'EXW',
      commodity: json['commodity'] ?? '',
      hsCodes: json['hs_codes_str'] ?? (json['hs_codes'] is List ? (json['hs_codes'] as List).join(', ') : ''),
      shipmentMode: json['shipment_mode'] ?? 'Sea FCL',
      isAir: json['is_air'] ?? (json['shipment_mode']?.toString().toLowerCase().contains('air') == true),
      recommendedContainers: json['recommended_containers'] ?? '',
      totalCbm: (json['total_cbm'] as num?)?.toDouble() ?? 0.0,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      netWeightKg: (json['net_weight_kg'] as num?)?.toDouble() ?? 0.0,
      volumetricWeightKg: (json['volumetric_weight_kg'] as num?)?.toDouble() ?? 0.0,
      chargeableWeightKg: (json['chargeable_weight_kg'] as num?)?.toDouble() ?? ((json['gross_weight_kg'] as num?)?.toDouble() ?? 0.0),
      totalPackages: (json['total_packages'] as num?)?.toInt() ?? 0,
      packagesBreakdown: json['packages_breakdown'] ?? '',
      stackability: json['stackability'] ?? 'Stackable',
      pickupAddress: json['pickup_address'] ?? '',
      portOfLoading: json['port_of_loading'] ?? '',
      portOfDischarge: json['port_of_discharge'] ?? '',
      cargoReadyDate: json['cargo_ready_date'] ?? '',
      targetFreeDays: (json['target_free_days'] as num?)?.toInt() ?? 21,
      serviceType: json['service_type'] ?? 'Direct',
      specialRequirements: json['special_requirements'] ?? '',
      emailSubject: json['email_subject'] ?? '',
      emailBodyTemplate: json['email_body_template'] ?? '',
      whatsappTextTemplate: json['whatsapp_text_template'] ?? '',
    );
  }
}

class ImportMasterReportSummaryModel {
  final int totalImportFiles;
  final int openFilesCount;
  final int inProgressCount;
  final int closedFilesCount;
  final double totalEstimatedCost;
  final List<ImportFileModel> files;

  ImportMasterReportSummaryModel({
    required this.totalImportFiles,
    required this.openFilesCount,
    required this.inProgressCount,
    required this.closedFilesCount,
    required this.totalEstimatedCost,
    required this.files,
  });

  factory ImportMasterReportSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawFiles = json['files'] as List<dynamic>? ?? [];
    return ImportMasterReportSummaryModel(
      totalImportFiles: json['total_import_files'] ?? 0,
      openFilesCount: json['open_files_count'] ?? 0,
      inProgressCount: json['in_progress_count'] ?? 0,
      closedFilesCount: json['closed_files_count'] ?? 0,
      totalEstimatedCost: (json['total_estimated_cost'] as num?)?.toDouble() ?? 0.0,
      files: rawFiles.map((f) => ImportFileModel.fromJson(f)).toList(),
    );
  }
}
