class ContainerAllocationModel {
  final String containerType;
  final int quantity;
  final List<String> containerNumbers;
  final List<String> sealNumbers;
  final double vgmWeightKg;

  ContainerAllocationModel({
    required this.containerType,
    this.quantity = 1,
    this.containerNumbers = const [],
    this.sealNumbers = const [],
    this.vgmWeightKg = 0.0,
  });

  factory ContainerAllocationModel.fromJson(Map<String, dynamic> json) {
    var rawCNo = json['container_numbers'] as List<dynamic>? ?? [];
    var rawSNo = json['seal_numbers'] as List<dynamic>? ?? [];
    return ContainerAllocationModel(
      containerType: json['container_type'] ?? '40HC',
      quantity: json['quantity'] ?? 1,
      containerNumbers: rawCNo.map((e) => e.toString()).toList(),
      sealNumbers: rawSNo.map((e) => e.toString()).toList(),
      vgmWeightKg: (json['vgm_weight_kg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'container_type': containerType,
      'quantity': quantity,
      'container_numbers': containerNumbers,
      'seal_numbers': sealNumbers,
      'vgm_weight_kg': vgmWeightKg,
    };
  }
}

class BookingChargeModel {
  final String chargeType;
  final String unit;
  final int quantity;
  final String currency;
  final double rate;
  final double total;

  BookingChargeModel({
    required this.chargeType,
    this.unit = 'Per Container',
    this.quantity = 1,
    this.currency = 'USD',
    this.rate = 0.0,
    this.total = 0.0,
  });

  factory BookingChargeModel.fromJson(Map<String, dynamic> json) {
    return BookingChargeModel(
      chargeType: json['charge_type'] ?? 'Sea Freight',
      unit: json['unit'] ?? 'Per Container',
      quantity: json['quantity'] ?? 1,
      currency: json['currency'] ?? 'USD',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charge_type': chargeType,
      'unit': unit,
      'quantity': quantity,
      'currency': currency,
      'rate': rate,
      'total': total,
    };
  }
}

class ShipmentBookingModel {
  final int bookingId;
  final String bookingCode;
  final String? bookingConfirmationNo;
  final int? importFileId;
  final int? rfqRequestId;
  final int? freightForwarderId;
  final String? freightForwarderName;
  final int? shippingLineId;
  final String? shippingLineName;
  final String shipmentType;
  final int? polLocationId;
  final String? polName;
  final int? podLocationId;
  final String? podName;
  final String? bookingRequestDate;
  final String? bookingConfirmationDate;
  final String? etd;
  final String? eta;
  final int transitTimeDays;
  final int freeDemurrageDays;
  final String? cargoCutoffDate;
  final String? siCutoffDate;
  final String? vesselName;
  final String? voyageNumber;
  final String? containerReleaseOrderNo;
  final String freightTerms;
  final List<ContainerAllocationModel> containersData;
  final List<BookingChargeModel> costChargesData;
  final double totalFreightCostUsd;
  final String status;
  final String owner;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? importFileCode;

  ShipmentBookingModel({
    required this.bookingId,
    required this.bookingCode,
    this.bookingConfirmationNo,
    this.importFileId,
    this.rfqRequestId,
    this.freightForwarderId,
    this.freightForwarderName,
    this.shippingLineId,
    this.shippingLineName,
    this.shipmentType = 'Ocean FCL',
    this.polLocationId,
    this.polName,
    this.podLocationId,
    this.podName,
    this.bookingRequestDate,
    this.bookingConfirmationDate,
    this.etd,
    this.eta,
    this.transitTimeDays = 0,
    this.freeDemurrageDays = 14,
    this.cargoCutoffDate,
    this.siCutoffDate,
    this.vesselName,
    this.voyageNumber,
    this.containerReleaseOrderNo,
    this.freightTerms = 'Collect',
    this.containersData = const [],
    this.costChargesData = const [],
    this.totalFreightCostUsd = 0.0,
    this.status = 'Draft',
    this.owner = 'Kamal',
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.importFileCode,
  });

  factory ShipmentBookingModel.fromJson(Map<String, dynamic> json) {
    var rawCont = json['containers_data'] as List<dynamic>? ?? [];
    var rawCost = json['cost_charges_data'] as List<dynamic>? ?? [];

    return ShipmentBookingModel(
      bookingId: json['booking_id'],
      bookingCode: json['booking_code'] ?? '',
      bookingConfirmationNo: json['booking_confirmation_no'],
      importFileId: json['import_file_id'],
      rfqRequestId: json['rfq_request_id'],
      freightForwarderId: json['freight_forwarder_id'],
      freightForwarderName: json['freight_forwarder_name'],
      shippingLineId: json['shipping_line_id'],
      shippingLineName: json['shipping_line_name'],
      shipmentType: json['shipment_type'] ?? 'Ocean FCL',
      polLocationId: json['pol_location_id'],
      polName: json['pol_name'],
      podLocationId: json['pod_location_id'],
      podName: json['pod_name'],
      bookingRequestDate: json['booking_request_date'],
      bookingConfirmationDate: json['booking_confirmation_date'],
      etd: json['etd'],
      eta: json['eta'],
      transitTimeDays: json['transit_time_days'] ?? 0,
      freeDemurrageDays: json['free_demurrage_days'] ?? 14,
      cargoCutoffDate: json['cargo_cutoff_date'],
      siCutoffDate: json['si_cutoff_date'],
      vesselName: json['vessel_name'],
      voyageNumber: json['voyage_number'],
      containerReleaseOrderNo: json['container_release_order_no'],
      freightTerms: json['freight_terms'] ?? 'Collect',
      containersData: rawCont.map((c) => ContainerAllocationModel.fromJson(c)).toList(),
      costChargesData: rawCost.map((c) => BookingChargeModel.fromJson(c)).toList(),
      totalFreightCostUsd: (json['total_freight_cost_usd'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Draft',
      owner: json['owner'] ?? 'Kamal',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      importFileCode: json['import_file_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'booking_code': bookingCode,
      'booking_confirmation_no': bookingConfirmationNo,
      'import_file_id': importFileId,
      'rfq_request_id': rfqRequestId,
      'freight_forwarder_id': freightForwarderId,
      'freight_forwarder_name': freightForwarderName,
      'shipping_line_id': shippingLineId,
      'shipping_line_name': shippingLineName,
      'shipment_type': shipmentType,
      'pol_location_id': polLocationId,
      'pol_name': polName,
      'pod_location_id': podLocationId,
      'pod_name': podName,
      'etd': etd,
      'eta': eta,
      'free_demurrage_days': freeDemurrageDays,
      'cargo_cutoff_date': cargoCutoffDate,
      'si_cutoff_date': siCutoffDate,
      'vessel_name': vesselName,
      'voyage_number': voyageNumber,
      'container_release_order_no': containerReleaseOrderNo,
      'freight_terms': freightTerms,
      'containers_data': containersData.map((c) => c.toJson()).toList(),
      'cost_charges_data': costChargesData.map((c) => c.toJson()).toList(),
      'status': status,
      'owner': owner,
      'notes': notes,
    };
  }
}
