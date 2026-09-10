class ShipmentInquiryFilterModel {
  final int? supplierId;
  final int? companyId;
  final String hsCodeOrProduct;
  final String? incotermCode;
  final String? portOfLoading;
  final String? portOfDischarge;
  final String? shipmentMode;
  final String? carrier;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String search;

  const ShipmentInquiryFilterModel({
    this.supplierId,
    this.companyId,
    this.hsCodeOrProduct = '',
    this.incotermCode,
    this.portOfLoading,
    this.portOfDischarge,
    this.shipmentMode,
    this.carrier,
    this.dateFrom,
    this.dateTo,
    this.search = '',
  });

  ShipmentInquiryFilterModel copyWith({
    int? supplierId,
    bool clearSupplier = false,
    int? companyId,
    bool clearCompany = false,
    String? hsCodeOrProduct,
    String? incotermCode,
    bool clearIncoterm = false,
    String? portOfLoading,
    bool clearPol = false,
    String? portOfDischarge,
    bool clearPod = false,
    String? shipmentMode,
    bool clearMode = false,
    String? carrier,
    bool clearCarrier = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? search,
  }) {
    return ShipmentInquiryFilterModel(
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      companyId: clearCompany ? null : (companyId ?? this.companyId),
      hsCodeOrProduct: hsCodeOrProduct ?? this.hsCodeOrProduct,
      incotermCode: clearIncoterm ? null : (incotermCode ?? this.incotermCode),
      portOfLoading: clearPol ? null : (portOfLoading ?? this.portOfLoading),
      portOfDischarge: clearPod ? null : (portOfDischarge ?? this.portOfDischarge),
      shipmentMode: clearMode ? null : (shipmentMode ?? this.shipmentMode),
      carrier: clearCarrier ? null : (carrier ?? this.carrier),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      search: search ?? this.search,
    );
  }

  bool get hasActiveFilters =>
      supplierId != null ||
      companyId != null ||
      hsCodeOrProduct.trim().isNotEmpty ||
      (incotermCode != null && incotermCode != 'All') ||
      (portOfLoading != null && portOfLoading!.trim().isNotEmpty) ||
      (portOfDischarge != null && portOfDischarge!.trim().isNotEmpty) ||
      (shipmentMode != null && shipmentMode != 'All') ||
      (carrier != null && carrier!.trim().isNotEmpty) ||
      dateFrom != null ||
      dateTo != null ||
      search.trim().isNotEmpty;

  static const ShipmentInquiryFilterModel empty = ShipmentInquiryFilterModel();
}
