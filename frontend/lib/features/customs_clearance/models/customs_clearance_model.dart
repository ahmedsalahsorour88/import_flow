class CustomsClearanceModel {
  final int customsClearanceId;
  final String clearanceCode;
  final int importFileId;
  final String? declaration46No;
  final String customsOfficeName;
  final String channelType;
  final String? inspectionDate;
  final List<String> regulatoryBodies;
  final String sampleTestStatus;
  final String? inspectionNotes;
  final double importDutyAmount;
  final double vatAmount;
  final double scheduleTaxAmount;
  final double whtAmount;
  final double labServiceFees;
  final double totalDutyPayable;
  final String paymentStatus;
  final String? bankReceiptNo;
  final String? payingBankName;
  final String? paymentDate;
  final String? paymentNotes;
  final String? releasePermitNo;
  final String? releaseDate;
  final double demurrageStorageFees;
  final bool dispatchAuthorized;
  final String? dispatchDate;
  final String status;
  final String owner;
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  CustomsClearanceModel({
    required this.customsClearanceId,
    required this.clearanceCode,
    required this.importFileId,
    this.declaration46No,
    this.customsOfficeName = 'Alexandria Port Customs',
    this.channelType = 'Red Channel',
    this.inspectionDate,
    this.regulatoryBodies = const [],
    this.sampleTestStatus = 'Samples Under Testing',
    this.inspectionNotes,
    this.importDutyAmount = 0.0,
    this.vatAmount = 0.0,
    this.scheduleTaxAmount = 0.0,
    this.whtAmount = 0.0,
    this.labServiceFees = 0.0,
    this.totalDutyPayable = 0.0,
    this.paymentStatus = 'Unpaid',
    this.bankReceiptNo,
    this.payingBankName,
    this.paymentDate,
    this.paymentNotes,
    this.releasePermitNo,
    this.releaseDate,
    this.demurrageStorageFees = 0.0,
    this.dispatchAuthorized = false,
    this.dispatchDate,
    this.status = 'Inspection In Progress',
    this.owner = 'Kamal',
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomsClearanceModel.fromJson(Map<String, dynamic> json) {
    var rawReg = json['regulatory_bodies'] as List<dynamic>? ?? [];
    return CustomsClearanceModel(
      customsClearanceId: json['customs_clearance_id'],
      clearanceCode: json['clearance_code'] ?? '',
      importFileId: json['import_file_id'],
      declaration46No: json['declaration_46_no'],
      customsOfficeName: json['customs_office_name'] ?? 'Alexandria Port Customs',
      channelType: json['channel_type'] ?? 'Red Channel',
      inspectionDate: json['inspection_date'],
      regulatoryBodies: rawReg.map((e) => e.toString()).toList(),
      sampleTestStatus: json['sample_test_status'] ?? 'Samples Under Testing',
      inspectionNotes: json['inspection_notes'],
      importDutyAmount: (json['import_duty_amount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0.0,
      scheduleTaxAmount: (json['schedule_tax_amount'] as num?)?.toDouble() ?? 0.0,
      whtAmount: (json['wht_amount'] as num?)?.toDouble() ?? 0.0,
      labServiceFees: (json['lab_service_fees'] as num?)?.toDouble() ?? 0.0,
      totalDutyPayable: (json['total_duty_payable'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      bankReceiptNo: json['bank_receipt_no'],
      payingBankName: json['paying_bank_name'],
      paymentDate: json['payment_date'],
      paymentNotes: json['payment_notes'],
      releasePermitNo: json['release_permit_no'],
      releaseDate: json['release_date'],
      demurrageStorageFees: (json['demurrage_storage_fees'] as num?)?.toDouble() ?? 0.0,
      dispatchAuthorized: json['dispatch_authorized'] ?? false,
      dispatchDate: json['dispatch_date'],
      status: json['status'] ?? 'Inspection In Progress',
      owner: json['owner'] ?? 'Kamal',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customs_clearance_id': customsClearanceId,
      'clearance_code': clearanceCode,
      'import_file_id': importFileId,
      'declaration_46_no': declaration46No,
      'customs_office_name': customsOfficeName,
      'channel_type': channelType,
      'inspection_date': inspectionDate,
      'regulatory_bodies': regulatoryBodies,
      'sample_test_status': sampleTestStatus,
      'inspection_notes': inspectionNotes,
      'import_duty_amount': importDutyAmount,
      'vat_amount': vatAmount,
      'schedule_tax_amount': scheduleTaxAmount,
      'wht_amount': whtAmount,
      'lab_service_fees': labServiceFees,
      'total_duty_payable': totalDutyPayable,
      'payment_status': paymentStatus,
      'bank_receipt_no': bankReceiptNo,
      'paying_bank_name': payingBankName,
      'payment_date': paymentDate,
      'payment_notes': paymentNotes,
      'release_permit_no': releasePermitNo,
      'release_date': releaseDate,
      'demurrage_storage_fees': demurrageStorageFees,
      'dispatch_authorized': dispatchAuthorized,
      'dispatch_date': dispatchDate,
      'status': status,
      'owner': owner,
      'notes': notes,
    };
  }
}
