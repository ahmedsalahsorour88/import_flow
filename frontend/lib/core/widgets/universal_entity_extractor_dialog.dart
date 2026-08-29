import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../constants/api_constants.dart';
import 'searchable_dropdown_field.dart';
import 'extraction_progress_dialog.dart';

enum EntityTarget {
  supplier,
  company,
  customsBroker,
  shippingLine,
  freightForwarder,
  inlandTransport,
  inspectionAgency,
  insuranceCompany,
  bank,
  partner,
}

class UniversalEntityExtractorDialog extends StatefulWidget {
  final EntityTarget initialTarget;
  final bool lockTarget;
  final VoidCallback? onSaved;

  const UniversalEntityExtractorDialog({
    super.key,
    this.initialTarget = EntityTarget.supplier,
    this.lockTarget = false,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    EntityTarget initialTarget = EntityTarget.supplier,
    bool lockTarget = false,
    VoidCallback? onSaved,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UniversalEntityExtractorDialog(
        initialTarget: initialTarget,
        lockTarget: lockTarget,
        onSaved: onSaved,
      ),
    );
  }

  static Future<void> showSupplierExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.supplier, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showImporterExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.company, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showCustomsBrokerExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.customsBroker, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showShippingLineExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.shippingLine, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showFreightForwarderExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.freightForwarder, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showInlandTransportExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.inlandTransport, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showInspectionAgencyExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.inspectionAgency, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showInsuranceCompanyExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.insuranceCompany, lockTarget: true, onSaved: onSaved);
  }

  static Future<void> showBankExtractor(BuildContext context, {VoidCallback? onSaved}) {
    return show(context, initialTarget: EntityTarget.bank, lockTarget: true, onSaved: onSaved);
  }

  @override
  State<UniversalEntityExtractorDialog> createState() => _UniversalEntityExtractorDialogState();
}

class _UniversalEntityExtractorDialogState extends State<UniversalEntityExtractorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late EntityTarget _selectedTarget;
  int _inputModeTab = 0;
  bool _isExtracting = false;
  bool _isSaving = false;

  final TextEditingController _rawTextCtrl = TextEditingController();
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _arabicNameCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _secondaryEmailCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'China');
  final TextEditingController _countryCodeCtrl = TextEditingController(text: 'CN');

  final TextEditingController _cargoxIdCtrl = TextEditingController();
  final TextEditingController _foreignTaxIdCtrl = TextEditingController();
  final TextEditingController _brandsCtrl = TextEditingController();
  String _supplierRegType = 'Commercial Register';

  final TextEditingController _importerCountryCtrl = TextEditingController(text: 'Egypt');
  final TextEditingController _taxIdCtrl = TextEditingController();
  final TextEditingController _commercialRegisterCtrl = TextEditingController();
  final TextEditingController _importerCardCtrl = TextEditingController();
  final TextEditingController _nafezaTokenCtrl = TextEditingController();
  DateTime _importerIdExpiry = DateTime.now().add(const Duration(days: 365 * 3));
  DateTime _vatIdExpiry = DateTime.now().add(const Duration(days: 365 * 3));
  DateTime _registrationExpiry = DateTime.now().add(const Duration(days: 365 * 3));

  final TextEditingController _scacCodeCtrl = TextEditingController();
  final TextEditingController _trackingUrlCtrl = TextEditingController();

  final TextEditingController _brokerLicenseCtrl = TextEditingController();
  final TextEditingController _portsCtrl = TextEditingController(text: 'Alexandria Port, Sokhna Port');

  final TextEditingController _servicesScopeCtrl = TextEditingController(text: 'Ocean FCL/LCL, Air Freight, Customs Clearance');

  final TextEditingController _fleetTypesCtrl = TextEditingController(text: 'Container Chassis, Flatbed Trailers');

  final TextEditingController _inspectionScopeCtrl = TextEditingController(text: 'Pre-Shipment Inspection (PSI), VOC, GOIEC Testing');

  final TextEditingController _policyTermsCtrl = TextEditingController(text: 'Institute Cargo Clauses (A) - All Risks');

  final TextEditingController _swiftCodeCtrl = TextEditingController();
  final TextEditingController _branchNameCtrl = TextEditingController(text: 'Main Branch');
  final TextEditingController _bankAccountCtrl = TextEditingController();

  String? _selectedFileName;
  double _confidenceScore = 0.0;

  static const List<Map<String, String>> _countryList = [
    {'code': 'CN', 'name': 'China (CN)'},
    {'code': 'DE', 'name': 'Germany (DE)'},
    {'code': 'IT', 'name': 'Italy (IT)'},
    {'code': 'TR', 'name': 'Turkey (TR)'},
    {'code': 'US', 'name': 'United States (US)'},
    {'code': 'GB', 'name': 'United Kingdom (GB)'},
    {'code': 'ES', 'name': 'Spain (ES)'},
    {'code': 'FR', 'name': 'France (FR)'},
    {'code': 'IN', 'name': 'India (IN)'},
    {'code': 'JP', 'name': 'Japan (JP)'},
    {'code': 'KR', 'name': 'South Korea (KR)'},
    {'code': 'AE', 'name': 'United Arab Emirates (AE)'},
    {'code': 'SA', 'name': 'Saudi Arabia (SA)'},
    {'code': 'EG', 'name': 'Egypt (EG)'},
    {'code': 'BR', 'name': 'Brazil (BR)'},
    {'code': 'RU', 'name': 'Russia (RU)'},
    {'code': 'VN', 'name': 'Vietnam (VN)'},
    {'code': 'NL', 'name': 'Netherlands (NL)'},
    {'code': 'CH', 'name': 'Switzerland (CH)'},
    {'code': 'BE', 'name': 'Belgium (BE)'},
    {'code': 'PL', 'name': 'Poland (PL)'},
    {'code': 'LT', 'name': 'Lithuania (LT)'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget;
    _setupInitialDefaults();
  }

  void _setupInitialDefaults() {
    if (_selectedTarget == EntityTarget.company ||
        _selectedTarget == EntityTarget.customsBroker ||
        _selectedTarget == EntityTarget.shippingLine ||
        _selectedTarget == EntityTarget.inlandTransport ||
        _selectedTarget == EntityTarget.insuranceCompany ||
        _selectedTarget == EntityTarget.bank) {
      _countryCtrl.text = 'Egypt';
      _countryCodeCtrl.text = 'EG';
    } else {
      _countryCtrl.text = 'China';
      _countryCodeCtrl.text = 'CN';
    }
  }

  @override
  void dispose() {
    _rawTextCtrl.dispose();
    _companyNameCtrl.dispose();
    _arabicNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _secondaryEmailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _countryCtrl.dispose();
    _countryCodeCtrl.dispose();
    _importerCountryCtrl.dispose();
    _cargoxIdCtrl.dispose();
    _foreignTaxIdCtrl.dispose();
    _brandsCtrl.dispose();
    _taxIdCtrl.dispose();
    _commercialRegisterCtrl.dispose();
    _importerCardCtrl.dispose();
    _nafezaTokenCtrl.dispose();
    _scacCodeCtrl.dispose();
    _trackingUrlCtrl.dispose();
    _brokerLicenseCtrl.dispose();
    _portsCtrl.dispose();
    _servicesScopeCtrl.dispose();
    _fleetTypesCtrl.dispose();
    _inspectionScopeCtrl.dispose();
    _policyTermsCtrl.dispose();
    _swiftCodeCtrl.dispose();
    _branchNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  String _getModuleForTarget(EntityTarget t) {
    switch (t) {
      case EntityTarget.supplier:
        return 'supplier-entity';
      case EntityTarget.company:
        return 'importer-entity';
      case EntityTarget.customsBroker:
        return 'customs-broker-entity';
      case EntityTarget.shippingLine:
        return 'shipping-line-entity';
      case EntityTarget.freightForwarder:
        return 'freight-forwarder-entity';
      case EntityTarget.inlandTransport:
        return 'inland-transport-entity';
      case EntityTarget.inspectionAgency:
        return 'inspection-agency-entity';
      case EntityTarget.insuranceCompany:
        return 'insurance-company-entity';
      case EntityTarget.bank:
        return 'bank-entity';
      case EntityTarget.partner:
        return 'partner-entity';
    }
  }

  Future<void> _extractFromRawText() async {
    final text = _rawTextCtrl.text.trim();
    if (text.isEmpty) return;

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.15,
      status: 'جاري فحص النص وتحليل الحقول التخصصية...',
      stepLabel: 'المرحلة 1 من 4: تحليل النص',
      currentStep: 1,
    );

    setState(() => _isExtracting = true);

    if (mounted) {
      ExtractionProgressDialog.show(
        context: context,
        title: 'جاري استخراج بيانات ${_targetArabicName(_selectedTarget)}',
        fileName: 'النص المنسوخ (${text.length} حرف)',
        controller: progressCtrl,
      );
    }

    try {
      final dio = Dio();
      final formData = FormData.fromMap({'raw_text': text});
      final moduleName = _getModuleForTarget(_selectedTarget);
      final resp = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse-text/$moduleName',
        data: formData,
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final extracted = resp.data['extracted_fields'] as Map<String, dynamic>? ?? {};
        final score = (resp.data['confidence_score'] as num?)?.toDouble() ?? 0.85;
        _populateFields(extracted, score);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استخراج النص: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  String _targetArabicName(EntityTarget t) {
    switch (t) {
      case EntityTarget.supplier:
        return 'المورد الأجنبي';
      case EntityTarget.company:
        return 'الشركة المستوردة';
      case EntityTarget.customsBroker:
        return 'المخلص الجمركي';
      case EntityTarget.shippingLine:
        return 'الخط الملاحي';
      case EntityTarget.freightForwarder:
        return 'شركة الشحن الدولي';
      case EntityTarget.inlandTransport:
        return 'الناقل البري';
      case EntityTarget.inspectionAgency:
        return 'شركة الفحص والمعاينة';
      case EntityTarget.insuranceCompany:
        return 'شركة التأمين';
      case EntityTarget.bank:
        return 'البنك المصرفي';
      case EntityTarget.partner:
        return 'الشريك اللوجستي';
    }
  }

  String _targetEnglishName(EntityTarget t) {
    switch (t) {
      case EntityTarget.supplier:
        return 'Foreign Supplier';
      case EntityTarget.company:
        return 'Importing Company';
      case EntityTarget.customsBroker:
        return 'Customs Broker';
      case EntityTarget.shippingLine:
        return 'Shipping Line';
      case EntityTarget.freightForwarder:
        return 'Freight Forwarder';
      case EntityTarget.inlandTransport:
        return 'Inland Transport';
      case EntityTarget.inspectionAgency:
        return 'Inspection Agency';
      case EntityTarget.insuranceCompany:
        return 'Insurance Company';
      case EntityTarget.bank:
        return 'Commercial Bank';
      case EntityTarget.partner:
        return 'Logistics Partner';
    }
  }

  Future<void> _pickAndExtractFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx', 'xls', 'docx', 'doc', 'png', 'jpg', 'jpeg', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر قراءة محتوى الملف المختَار.'), backgroundColor: AppTheme.crimson),
        );
      }
      return;
    }

    final fileSizeFormatted = file.size > 1024 * 1024
        ? '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(file.size / 1024).toStringAsFixed(0)} KB';

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.10,
      status: 'جاري قراءة واستخراج ملف ${file.name} ($fileSizeFormatted)...',
      stepLabel: 'المرحلة 1 من 4: قراءة الملف',
      currentStep: 1,
    );

    setState(() {
      _selectedFileName = file.name;
      _isExtracting = true;
    });

    if (mounted) {
      ExtractionProgressDialog.show(
        context: context,
        title: 'استخراج بيانات ${_targetArabicName(_selectedTarget)} من الملف',
        fileName: file.name,
        controller: progressCtrl,
      );
    }

    progressCtrl.startAutoAdvance(targetPercent: 0.90, duration: const Duration(seconds: 4));

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final moduleName = _getModuleForTarget(_selectedTarget);
      final resp = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/upload/$moduleName',
        data: formData,
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final extracted = resp.data['extracted_fields'] as Map<String, dynamic>? ?? {};
        final score = (resp.data['confidence_score'] as num?)?.toDouble() ?? 0.85;
        _populateFields(extracted, score);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استخراج الملف: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  void _populateFields(Map<String, dynamic> ext, double score) {
    setState(() {
      _confidenceScore = score;

      if (ext['company_name'] != null && ext['company_name'].toString().trim().isNotEmpty) {
        _companyNameCtrl.text = ext['company_name'].toString().trim();
      }
      if (ext['arabic_name'] != null) _arabicNameCtrl.text = ext['arabic_name'].toString().trim();
      if (ext['contact_person'] != null) _contactPersonCtrl.text = ext['contact_person'].toString().trim();
      if (ext['phone_number'] != null) _phoneCtrl.text = ext['phone_number'].toString().trim();
      if (ext['mobile_number'] != null) _mobileCtrl.text = ext['mobile_number'].toString().trim();
      if (ext['email'] != null) _emailCtrl.text = ext['email'].toString().trim();
      if (ext['website'] != null) _websiteCtrl.text = ext['website'].toString().trim();
      if (ext['address'] != null) _addressCtrl.text = ext['address'].toString().trim();

      if (ext['country_code'] != null) {
        final code = ext['country_code'].toString().toUpperCase().trim();
        final match = _countryList.firstWhere((c) => c['code'] == code, orElse: () => {});
        if (match.isNotEmpty) {
          _countryCodeCtrl.text = code;
          _countryCtrl.text = match['name'] ?? code;
        } else {
          _countryCodeCtrl.text = code;
          _countryCtrl.text = code;
        }
      }

      if (ext['scac_code'] != null) _scacCodeCtrl.text = ext['scac_code'].toString().toUpperCase().trim();
      if (ext['tracking_url'] != null) _trackingUrlCtrl.text = ext['tracking_url'].toString().trim();
      if (ext['clearance_license_number'] != null || ext['license_number'] != null) {
        _brokerLicenseCtrl.text = (ext['clearance_license_number'] ?? ext['license_number']).toString().trim();
      }
      if (ext['fleet_types'] != null) _fleetTypesCtrl.text = ext['fleet_types'].toString().trim();
      if (ext['inspection_scope'] != null) _inspectionScopeCtrl.text = ext['inspection_scope'].toString().trim();
      if (ext['insurance_terms'] != null) _policyTermsCtrl.text = ext['insurance_terms'].toString().trim();
      if (ext['ports'] != null) _portsCtrl.text = ext['ports'].toString().trim();

      if (ext['cargox_id'] != null) _cargoxIdCtrl.text = ext['cargox_id'].toString().trim();
      if (ext['vat_tax_id'] != null || ext['foreign_exporter_id'] != null) {
        final tax = (ext['vat_tax_id'] ?? ext['foreign_exporter_id']).toString().trim();
        _foreignTaxIdCtrl.text = tax;
        _taxIdCtrl.text = tax;
      }
      if (ext['commercial_register'] != null) {
        _commercialRegisterCtrl.text = ext['commercial_register'].toString().trim();
      }
      if (ext['importer_id'] != null) {
        _importerCardCtrl.text = ext['importer_id'].toString().replaceAll('-', '').replaceAll(' ', '').trim();
      }
      if (ext['swift_code'] != null) _swiftCodeCtrl.text = ext['swift_code'].toString().trim();
      if (ext['bank_account'] != null || ext['iban'] != null) {
        _bankAccountCtrl.text = (ext['bank_account'] ?? ext['iban']).toString().trim();
      }
      if (ext['industry_description'] != null) _brandsCtrl.text = ext['industry_description'].toString().trim();

      if (ext['importer_id_expiry'] != null) {
        final d = DateTime.tryParse(ext['importer_id_expiry'].toString());
        if (d != null) _importerIdExpiry = d;
      }
      if (ext['vat_id_expiry'] != null) {
        final d = DateTime.tryParse(ext['vat_id_expiry'].toString());
        if (d != null) _vatIdExpiry = d;
      }
      if (ext['registration_expiry'] != null) {
        final d = DateTime.tryParse(ext['registration_expiry'].toString());
        if (d != null) _registrationExpiry = d;
      }
    });
  }

  Future<void> _saveEntityToDatabase() async {
    final name = _companyNameCtrl.text.trim();
    final arabicName = _arabicNameCtrl.text.trim();
    final effectiveName = name.isNotEmpty ? name : arabicName;

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    if (effectiveName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ اسم الشركة / الشريك مطلوب لإتمام التكويد.'), backgroundColor: AppTheme.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = Dio();
      String endpoint = '${ApiConstants.baseUrl}/suppliers';
      Map<String, dynamic> payload = {};

      switch (_selectedTarget) {
        case EntityTarget.supplier:
          endpoint = '${ApiConstants.baseUrl}/suppliers';
          payload = {
            'company_name': effectiveName,
            'supplier_type': 'Manufacturer',
            'registration_type': _supplierRegType,
            'foreign_exporter_id': _foreignTaxIdCtrl.text.trim().isNotEmpty ? _foreignTaxIdCtrl.text.trim() : 'EXP-${DateTime.now().millisecondsSinceEpoch}',
            'foreign_exporter_country': _countryCtrl.text.trim(),
            'foreign_exporter_country_code': _countryCodeCtrl.text.trim(),
            'cargox_id': _cargoxIdCtrl.text.trim().isNotEmpty ? _cargoxIdCtrl.text.trim() : null,
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Foreign Address',
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'brands': _brandsCtrl.text.trim(),
            'swift_code': _swiftCodeCtrl.text.trim(),
            'bank_account': _bankAccountCtrl.text.trim(),
          };
          break;

        case EntityTarget.company:
          endpoint = '${ApiConstants.baseUrl}/import-companies';
          payload = {
            'importer_name': effectiveName,
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Cairo, Egypt',
            'country': 'Egypt',
            'importer_id': _importerCardCtrl.text.trim().isNotEmpty ? _importerCardCtrl.text.trim() : 'IMP-${DateTime.now().millisecondsSinceEpoch}',
            'importer_id_expiry': '${_importerIdExpiry.year}-${_importerIdExpiry.month.toString().padLeft(2, '0')}-${_importerIdExpiry.day.toString().padLeft(2, '0')}',
            'vat_id': _taxIdCtrl.text.trim().isNotEmpty ? _taxIdCtrl.text.trim() : '000000000',
            'vat_id_expiry': '${_vatIdExpiry.year}-${_vatIdExpiry.month.toString().padLeft(2, '0')}-${_vatIdExpiry.day.toString().padLeft(2, '0')}',
            'registration_number': _commercialRegisterCtrl.text.trim().isNotEmpty ? _commercialRegisterCtrl.text.trim() : '000000',
            'registration_expiry': '${_registrationExpiry.year}-${_registrationExpiry.month.toString().padLeft(2, '0')}-${_registrationExpiry.day.toString().padLeft(2, '0')}',
            'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
            'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
            'notes': _nafezaTokenCtrl.text.trim().isNotEmpty ? 'Nafeza E-Token: ${_nafezaTokenCtrl.text.trim()}' : null,
          };
          break;

        case EntityTarget.customsBroker:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': 'Customs Broker',
            'clearance_license_number': _brokerLicenseCtrl.text.trim().isNotEmpty ? _brokerLicenseCtrl.text.trim() : null,
            'notes': _portsCtrl.text.trim().isNotEmpty ? 'Operating Ports: ${_portsCtrl.text.trim()}' : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Egypt',
            'country': 'Egypt',
            'tax_id': _taxIdCtrl.text.trim(),
            'commercial_register': _commercialRegisterCtrl.text.trim(),
          };
          break;

        case EntityTarget.shippingLine:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          final scac = _scacCodeCtrl.text.trim().toUpperCase();
          payload = {
            'partner_name': name,
            'partner_type': 'Shipping Line',
            'scac_code': scac.isNotEmpty ? scac : 'LINE',
            'tracking_url': _trackingUrlCtrl.text.trim().isNotEmpty ? _trackingUrlCtrl.text.trim() : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'secondary_email': _secondaryEmailCtrl.text.trim().isNotEmpty ? _secondaryEmailCtrl.text.trim() : null,
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Egypt Local Agency',
            'country': 'Egypt',
          };
          break;

        case EntityTarget.freightForwarder:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': 'Freight Forwarder',
            'notes': _servicesScopeCtrl.text.trim().isNotEmpty ? 'Services: ${_servicesScopeCtrl.text.trim()}' : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Egypt',
            'country': 'Egypt',
            'commercial_register': _commercialRegisterCtrl.text.trim(),
          };
          break;

        case EntityTarget.inlandTransport:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': 'Inland Transport',
            'notes': _fleetTypesCtrl.text.trim().isNotEmpty ? 'Fleet: ${_fleetTypesCtrl.text.trim()}' : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Egypt Fleet Garage',
            'country': 'Egypt',
          };
          break;

        case EntityTarget.inspectionAgency:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': 'Inspection Agency',
            'clearance_license_number': _brokerLicenseCtrl.text.trim().isNotEmpty ? _brokerLicenseCtrl.text.trim() : null,
            'notes': _inspectionScopeCtrl.text.trim().isNotEmpty ? 'Scope: ${_inspectionScopeCtrl.text.trim()}' : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Egypt Hub',
            'country': 'Egypt',
          };
          break;

        case EntityTarget.insuranceCompany:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': 'Insurance Company',
            'notes': _policyTermsCtrl.text.trim().isNotEmpty ? 'Coverage: ${_policyTermsCtrl.text.trim()}' : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Egypt HQ',
            'country': 'Egypt',
          };
          break;

        case EntityTarget.bank:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          final swift = _swiftCodeCtrl.text.trim();
          payload = {
            'partner_name': name,
            'partner_type': 'Bank',
            'swift_code': swift.isNotEmpty ? swift : 'BANK-EG-SWIFT',
            'bank_code': 'BNK-001',
            'branch_name': _branchNameCtrl.text.trim().isNotEmpty ? _branchNameCtrl.text.trim() : 'Main Branch',
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'country': 'Egypt',
          };
          break;

        case EntityTarget.partner:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': 'Freight Forwarder',
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'country': 'Egypt',
          };
          break;
      }

      await dio.post(endpoint, data: payload);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تكويد وحفظ ${_targetArabicName(_selectedTarget)} "$effectiveName" بنجاح!'),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String msg = e.toString();
        if (e is DioException && e.response?.data != null) {
          msg = e.response?.data['detail']?.toString() ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحفظ: $msg'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 1080,
        height: 720,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDialogHeader(),
            if (!widget.lockTarget) _buildTargetSelectorBar(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Side: Input (Raw Text or File Upload)
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(left: BorderSide(color: Colors.grey.shade200)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputModeSwitcher(),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _inputModeTab == 0 ? _buildRawTextInputArea() : _buildFileUploadArea(),
                          ),
                          const SizedBox(height: 12),
                          _buildExtractActionButton(),
                        ],
                      ),
                    ),
                  ),

                  // Right Side: Extracted Structured Form
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getTargetIcon(_selectedTarget), color: AppTheme.cobalt, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'بيانات تكويد ${_targetArabicName(_selectedTarget)} (${_targetEnglishName(_selectedTarget)})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                                    ),
                                  ],
                                ),
                                if (_confidenceScore > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _confidenceScore >= 0.8 ? AppTheme.emerald.withOpacity(0.15) : AppTheme.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'دقة التحليل: ${(_confidenceScore * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _confidenceScore >= 0.8 ? AppTheme.emerald : AppTheme.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildTargetSpecificFields(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSaveActionButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.charcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.orange, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أداة التكويد والاستخراج الذكي: ${_targetArabicName(_selectedTarget)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'AI-Powered ${_targetEnglishName(_selectedTarget)} Extractor & Auto-Registration Engine',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelectorBar() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('الكيان المستهدف: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
            const SizedBox(width: 8),
            _targetChip(EntityTarget.supplier, 'مورد أجنبي', Icons.public),
            _targetChip(EntityTarget.company, 'شركة مستوردة', Icons.domain),
            _targetChip(EntityTarget.customsBroker, 'مخلص جمركي', Icons.badge_rounded),
            _targetChip(EntityTarget.shippingLine, 'خط ملاحي', Icons.directions_boat_rounded),
            _targetChip(EntityTarget.freightForwarder, 'شحن دولي', Icons.local_shipping_rounded),
            _targetChip(EntityTarget.inlandTransport, 'ناقل بري', Icons.fire_truck_rounded),
            _targetChip(EntityTarget.inspectionAgency, 'فحص ومعاينة', Icons.fact_check_rounded),
            _targetChip(EntityTarget.insuranceCompany, 'شركة تأمين', Icons.security_rounded),
            _targetChip(EntityTarget.bank, 'بنك معتمد', Icons.account_balance),
          ],
        ),
      ),
    );
  }

  Widget _targetChip(EntityTarget target, String label, IconData icon) {
    final isSelected = _selectedTarget == target;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.cobalt),
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppTheme.charcoal)),
        selected: isSelected,
        selectedColor: AppTheme.cobalt,
        backgroundColor: Colors.white,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedTarget = target;
              _setupInitialDefaults();
            });
          }
        },
      ),
    );
  }

  Widget _buildInputModeSwitcher() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _inputModeTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _inputModeTab == 0 ? AppTheme.emerald : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _inputModeTab == 0 ? AppTheme.emerald : Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_paste_rounded, size: 16, color: _inputModeTab == 0 ? Colors.white : AppTheme.charcoal),
                  const SizedBox(width: 6),
                  Text('لصق نص حر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _inputModeTab == 0 ? Colors.white : AppTheme.charcoal)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _inputModeTab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _inputModeTab == 1 ? AppTheme.emerald : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _inputModeTab == 1 ? AppTheme.emerald : Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_file_rounded, size: 16, color: _inputModeTab == 1 ? Colors.white : AppTheme.charcoal),
                  const SizedBox(width: 6),
                  Text('صورة / PDF / Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _inputModeTab == 1 ? Colors.white : AppTheme.charcoal)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawTextInputArea() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _rawTextCtrl,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: _getPlaceholderForTarget(_selectedTarget),
              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadArea() {
    return InkWell(
      onTap: _isExtracting ? null : _pickAndExtractFile,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.cobalt.withOpacity(0.4), style: BorderStyle.solid),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.cobalt),
            const SizedBox(height: 12),
            Text(
              _selectedFileName ?? 'اضغط لاختيار ملف أو سحب مستند الفاتورة / الكارت',
              style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFileName != null ? AppTheme.charcoal : Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text('يدعم: PDF, Images (PNG/JPG), Excel, Word', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        icon: _isExtracting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.auto_awesome, size: 18),
        label: Text(_isExtracting ? 'جاري التحليل والاستخراج...' : 'استخراج وتحليل البيانات تلقائياً ✨'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
        onPressed: _isExtracting
            ? null
            : () {
                if (_inputModeTab == 0) {
                  _extractFromRawText();
                } else {
                  _pickAndExtractFile();
                }
              },
      ),
    );
  }

  Widget _buildSaveActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        icon: _isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_circle_rounded, size: 20),
        label: Text('حفظ وتكويد ${_targetArabicName(_selectedTarget)} في قاعدة البيانات 💾', style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
        onPressed: (_isSaving || _isExtracting) ? null : _saveEntityToDatabase,
      ),
    );
  }

  Widget _buildTargetSpecificFields() {
    switch (_selectedTarget) {
      case EntityTarget.supplier:
        return _buildSupplierFields();
      case EntityTarget.company:
        return _buildImporterFields();
      case EntityTarget.customsBroker:
        return _buildCustomsBrokerFields();
      case EntityTarget.shippingLine:
        return _buildShippingLineFields();
      case EntityTarget.freightForwarder:
        return _buildFreightForwarderFields();
      case EntityTarget.inlandTransport:
        return _buildInlandTransportFields();
      case EntityTarget.inspectionAgency:
        return _buildInspectionAgencyFields();
      case EntityTarget.insuranceCompany:
        return _buildInsuranceCompanyFields();
      case EntityTarget.bank:
        return _buildBankFields();
      case EntityTarget.partner:
        return _buildFreightForwarderFields();
    }
  }

  Widget _buildSupplierFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم المورد الأجنبي بالإنجليزية *', prefixIcon: Icon(Icons.business_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المورد مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SearchableDropdownField<String>(
                value: _countryCtrl.text.isNotEmpty ? _countryCtrl.text : 'China (CN)',
                labelText: 'دولة المنشأ / المقر *',
                items: _countryList.map((c) => SearchableDropdownItem(value: c['name']!, label: c['name']!)).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _countryCtrl.text = v;
                      final match = _countryList.firstWhere((c) => c['name'] == v, orElse: () => {});
                      if (match.isNotEmpty) _countryCodeCtrl.text = match['code']!;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: SearchableDropdownField<String>(
                value: _supplierRegType,
                labelText: 'نوع السجل الأجنبي *',
                items: const [
                  SearchableDropdownItem(value: 'Commercial Register', label: 'Commercial Register'),
                  SearchableDropdownItem(value: 'Tax Number', label: 'Tax Number'),
                  SearchableDropdownItem(value: 'VAT Number', label: 'VAT Number'),
                  SearchableDropdownItem(value: 'Business License', label: 'Business License'),
                  SearchableDropdownItem(value: 'DUNS Number', label: 'DUNS Number'),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _supplierRegType = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _foreignTaxIdCtrl,
                decoration: const InputDecoration(labelText: 'رقم السجل / التعريف الضريبي *', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم السجل مطلوب' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _cargoxIdCtrl,
                decoration: const InputDecoration(labelText: 'معرف بلوكتشين كارجو اكس (CargoX ID)', prefixIcon: Icon(Icons.hub_rounded, size: 18, color: Colors.blue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المصنع / المقر الرئيسي *', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'مسؤول التواصل / المبيعات', prefixIcon: Icon(Icons.person_outline, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف / الواتساب', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _websiteCtrl, decoration: const InputDecoration(labelText: 'الموقع الإلكتروني', prefixIcon: Icon(Icons.language_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _swiftCodeCtrl, decoration: const InputDecoration(labelText: 'كود السويفت البنكي (SWIFT)', prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _brandsCtrl, decoration: const InputDecoration(labelText: 'العلامات التجارية والنشاط الصناعي', prefixIcon: Icon(Icons.category_rounded, size: 18)))),
          ],
        ),
      ],
    );
  }

  Widget _buildImporterFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم الشركة المستوردة بالإنجليزية *', prefixIcon: Icon(Icons.domain_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم بالإنجليزية مطلوب' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _arabicNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم الشركة المستوردة بالعربية *', prefixIcon: Icon(Icons.translate_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _taxIdCtrl,
                decoration: const InputDecoration(labelText: 'الرقم الضريبي المصري (9 أرقام) *', prefixIcon: Icon(Icons.pin_rounded, size: 18)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'الرقم الضريبي مطلوب' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _commercialRegisterCtrl,
                decoration: const InputDecoration(labelText: 'رقم السجل التجاري *', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'السجل التجاري مطلوب' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _importerCardCtrl,
                decoration: const InputDecoration(labelText: 'رقم البطاقة الاستيرادية *', prefixIcon: Icon(Icons.credit_card_rounded, size: 18)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'البطاقة الاستيرادية مطلوبة' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _nafezaTokenCtrl,
                decoration: const InputDecoration(labelText: 'معرف التوكن بنافذة (Nafeza Token ID)', prefixIcon: Icon(Icons.vpn_key_rounded, size: 18, color: Colors.blue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المقر الرئيسي / المسجل *', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الرسمي', prefixIcon: Icon(Icons.email_outlined, size: 18)))),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomsBrokerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم مكتب / شركة التخليص الجمركي بالإنجليزية *', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المستخلص مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brokerLicenseCtrl,
                decoration: const InputDecoration(labelText: 'رقم رخصة التخليص الجمركي *', prefixIcon: Icon(Icons.assignment_ind_rounded, size: 18, color: Colors.blue)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الرخصة مطلوب' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _portsCtrl,
                decoration: const InputDecoration(labelText: 'موانئ ومواقع العمل الجمركي *', prefixIcon: Icon(Icons.anchor_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _taxIdCtrl,
                decoration: const InputDecoration(labelText: 'الرقم الضريبي', prefixIcon: Icon(Icons.pin_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _commercialRegisterCtrl,
                decoration: const InputDecoration(labelText: 'السجل التجاري', prefixIcon: Icon(Icons.receipt_long_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المكتب والمقر الرئيسي', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'المخلص الجمركي المعتمد / المسؤول', prefixIcon: Icon(Icons.person_outline, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف / المحمول', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني للعمليات', prefixIcon: Icon(Icons.email_outlined, size: 18)),
        ),
      ],
    );
  }

  Widget _buildShippingLineFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم الخط الملاحي بالإنجليزية (Carrier Name) *', prefixIcon: Icon(Icons.directions_boat_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الخط الملاحي مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _scacCodeCtrl,
                decoration: const InputDecoration(labelText: 'كود الناقل الملاحي (SCAC Code) *', prefixIcon: Icon(Icons.qr_code_rounded, size: 18, color: Colors.blue)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'كود SCAC مطلوب' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _trackingUrlCtrl,
                decoration: const InputDecoration(labelText: 'رابط التتبع الحي للشحنات (Tracking Web URL) *', prefixIcon: Icon(Icons.travel_explore_rounded, size: 18, color: Colors.blue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(labelText: 'الموقع الإلكتروني الرسمي (Website URL)', prefixIcon: Icon(Icons.language_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني لخدمة العملاء والعمليات *', prefixIcon: Icon(Icons.email_outlined, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _secondaryEmailCtrl,
                decoration: const InputDecoration(labelText: 'بريد الحجوزات الثانوي (Booking Email)', prefixIcon: Icon(Icons.alternate_email_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'أرقام هواتف وخدمة عملاء الوكيل المحلي', prefixIcon: Icon(Icons.phone_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عناوين مقرات الوكيل الملاحي في مصر (القاهرة / الإسكندرية)', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
      ],
    );
  }

  Widget _buildFreightForwarderFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم شركة الشحن الدولي بالإنجليزية (Freight Forwarder) *', prefixIcon: Icon(Icons.local_shipping_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم شركة الشحن مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _commercialRegisterCtrl,
                decoration: const InputDecoration(labelText: 'السجل التجاري / رخصة الفياتا (FIATA / CR)', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _servicesScopeCtrl,
                decoration: const InputDecoration(labelText: 'مجالات الشحن والخدمات المغطاة', prefixIcon: Icon(Icons.alt_route_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المكتب والمقر الرئيسي', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'مسؤول التسعير والعمليات', prefixIcon: Icon(Icons.person_outline, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف / المحمول', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'بريد عروض الأسعار والعمليات *', prefixIcon: Icon(Icons.email_outlined, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _websiteCtrl, decoration: const InputDecoration(labelText: 'الموقع الإلكتروني', prefixIcon: Icon(Icons.language_rounded, size: 18)))),
          ],
        ),
      ],
    );
  }

  Widget _buildInlandTransportFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم شركة النقل البري بالإنجليزية *', prefixIcon: Icon(Icons.fire_truck_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم شركة النقل مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brokerLicenseCtrl,
                decoration: const InputDecoration(labelText: 'رقم ترخيص النقل البري / السجل', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _fleetTypesCtrl,
                decoration: const InputDecoration(labelText: 'أنواع الأسطول وتجهيزات الشاحنات *', prefixIcon: Icon(Icons.view_carousel_rounded, size: 18, color: Colors.blue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان الجراج والمستودع الرئيسي ومناطق التغطية', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'مسؤول الحركة والتشغيل', prefixIcon: Icon(Icons.person_outline, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'هاتف الطوارئ والتتبع 24/7 *', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني للتشغيل', prefixIcon: Icon(Icons.email_outlined, size: 18)),
        ),
      ],
    );
  }

  Widget _buildInspectionAgencyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم شركة الفحص والمعاينة بالإنجليزية (e.g. SGS, Bureau Veritas) *', prefixIcon: Icon(Icons.fact_check_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم جهة الفحص مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brokerLicenseCtrl,
                decoration: const InputDecoration(labelText: 'رقم الاعتماد والتسجيل بالرقابة على الصادرات', prefixIcon: Icon(Icons.verified_user_rounded, size: 18, color: Colors.blue)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _inspectionScopeCtrl,
                decoration: const InputDecoration(labelText: 'نطاق الفحص والاختبارات المعتمدة (Scope of Work) *', prefixIcon: Icon(Icons.biotech_rounded, size: 18, color: Colors.blue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المعامل والمقر الإقليمي', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'مسؤول المعاينة / المدير الفني', prefixIcon: Icon(Icons.person_outline, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني للشهادات والتقارير *', prefixIcon: Icon(Icons.email_outlined, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _websiteCtrl, decoration: const InputDecoration(labelText: 'الموقع الإلكتروني', prefixIcon: Icon(Icons.language_rounded, size: 18)))),
          ],
        ),
      ],
    );
  }

  Widget _buildInsuranceCompanyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم شركة التأمين بالإنجليزية (e.g. Misr Insurance, GIG, Allianz) *', prefixIcon: Icon(Icons.security_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم شركة التأمين مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brokerLicenseCtrl,
                decoration: const InputDecoration(labelText: 'رقم ترخيص هيئة الرقابة المالية (FRA License)', prefixIcon: Icon(Icons.verified_rounded, size: 18, color: Colors.blue)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _policyTermsCtrl,
                decoration: const InputDecoration(labelText: 'شروط ووثائق التأمين البحري المغطاة *', prefixIcon: Icon(Icons.shield_outlined, size: 18, color: Colors.blue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المقر الرئيسي وفروع التأمين البحري', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'مسؤول الاكتتاب البحري / التعويضات', prefixIcon: Icon(Icons.person_outline, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'الخط الساخن / الهاتف', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني للوثائق والمطالبات *', prefixIcon: Icon(Icons.email_outlined, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _websiteCtrl, decoration: const InputDecoration(labelText: 'الموقع الإلكتروني', prefixIcon: Icon(Icons.language_rounded, size: 18)))),
          ],
        ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(labelText: 'اسم البنك المصرفي بالإنجليزية *', prefixIcon: Icon(Icons.account_balance_rounded, size: 18)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم البنك مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _swiftCodeCtrl,
                decoration: const InputDecoration(labelText: 'كود السويفت الدولي (SWIFT / BIC) *', prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.blue), hintText: 'e.g. CIBEGGCAXXX'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'كود السويفت مطلوب' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _branchNameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الفرع المعتمد *', prefixIcon: Icon(Icons.store_rounded, size: 18), hintText: 'Main Branch'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'عنوان المقر / الفرع', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'هاتف الاعتمادات المستندية', prefixIcon: Icon(Icons.phone_rounded, size: 18)))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني للفرع', prefixIcon: Icon(Icons.email_outlined, size: 18)))),
          ],
        ),
      ],
    );
  }

  IconData _getTargetIcon(EntityTarget target) {
    switch (target) {
      case EntityTarget.supplier:
        return Icons.public;
      case EntityTarget.company:
        return Icons.domain;
      case EntityTarget.customsBroker:
        return Icons.badge_rounded;
      case EntityTarget.shippingLine:
        return Icons.directions_boat_rounded;
      case EntityTarget.freightForwarder:
        return Icons.local_shipping_rounded;
      case EntityTarget.inlandTransport:
        return Icons.fire_truck_rounded;
      case EntityTarget.inspectionAgency:
        return Icons.fact_check_rounded;
      case EntityTarget.insuranceCompany:
        return Icons.security_rounded;
      case EntityTarget.bank:
        return Icons.account_balance;
      case EntityTarget.partner:
        return Icons.handshake;
    }
  }

  String _getPlaceholderForTarget(EntityTarget target) {
    switch (target) {
      case EntityTarget.supplier:
        return 'الصق هنا ترويسة الفاتورة المبدئية أو كارت المورد الأجنبي:\n\nمثال:\nSuzhou Yuheng Textile Co., Ltd\nFactory Address: No.16, Kangsheng Road, Changshu, Jiangsu, China\nVAT Number: 91320581MA1X7... CargoX ID: 0x71C8a9...\nTel: +86-512-52889988\nEmail: export@yuheng.com\nSWIFT: BKCHCNBJ920';
      case EntityTarget.company:
        return 'الصق هنا بيانات الشركة المستوردة أو السجل التجاري والبطاقة الضريبية:\n\nمثال:\nشركة النيل للاستيراد والتصدير ش.م.م\nNile Import & Export SAE\nالعنوان: 15 شارع مصدق، الدقي، الجيزة، مصر\nالسجل التجاري: 184520 | البطاقة الاستيرادية: 489201\nالرقم الضريبي: 200-183-044\nالهاتف: +20 2 3762 1000 | البريد: info@nile-import.com\nتوكن نافذة: NFT-88921-EG';
      case EntityTarget.customsBroker:
        return 'الصق هنا كارت أو بيانات مكتب التخليص الجمركي:\n\nمثال:\nAl-Ahram Customs Clearance & Logistics Office\nAddress: 14 El-Sultan Hussein St., Alexandria, Egypt\nCustoms License No: 14820/2021 | Tax ID: 312-884-912\nOperating Ports: Alexandria Port, Dekheila, Sokhna, Damietta\nContact: Customs Specialist Tarek Mahmoud (+20 100 123 4567)\nEmail: clearance@ahram-customs.com | Tel: +20 3 487 6000';
      case EntityTarget.shippingLine:
        return 'الصق هنا بيانات الخط الملاحي والناقل البحري:\n\nمثال:\nHapag-Lloyd AG\nSCAC Code: HLCU\nTracking URL: https://www.hapag-lloyd.com/en/online-business/track/track-by-booking-solution.html\nWebsite: https://www.hapag-lloyd.com\nEmail: egypt@hlag.com | Tel: +20 2 2696 4500\nAddress: Citystars Complex, Building 3, Heliopolis, Cairo, Egypt';
      case EntityTarget.freightForwarder:
        return 'الصق هنا بيانات شركة الشحن الدولي:\n\nمثال:\nApex Global Freight Forwarding Ltd\nCommercial Register: 294810 | FIATA ID: EG-7721\nServices: Ocean FCL/LCL, Air Cargo, Multimodal Transport\nContact: Pricing Manager Karim Nabil (+20 122 345 6789)\nEmail: pricing@apex-freight.com | Web: https://www.apex-freight.com\nAddress: 22 Hassan Allam St., Heliopolis, Cairo, Egypt';
      case EntityTarget.inlandTransport:
        return 'الصق هنا بيانات شركة النقل البري والأسطول:\n\nمثال:\nAl-Rowad Heavy Inland Transport & Fleet Services\nTransport License: TR-88412 | Tax ID: 412-990-123\nFleet Types: Container Chassis, 40ft Flatbed, Lowbed, Refrigerated\nOperations Dispatcher: Mostafa Gamal (+20 111 888 9999 - 24/7)\nEmail: dispatch@rowad-transport.com\nGarage & Hub: Plot 4, 10th of Ramadan Industrial Zone, Egypt';
      case EntityTarget.inspectionAgency:
        return 'الصق هنا بيانات شركة الفحص والمعاينة الدولية:\n\nمثال:\nSGS Egypt International Inspection & Testing\nAccreditation No: GOIEC-REG-4412 / ISO 17020\nScope: Pre-Shipment Inspection (PSI), Verification of Conformity (VOC), Chemical Testing\nContact: Eng. Hossam Farouk (+20 102 555 4433)\nEmail: egypt.industrial@sgs.com | Web: https://www.sgs.com\nAddress: Alexandria Port Free Zone / Cairo Industrial Hub';
      case EntityTarget.insuranceCompany:
        return 'الصق هنا بيانات شركة التأمين البحري:\n\nمثال:\nMisr Insurance Company - Marine Hull & Cargo Department\nFRA Authority License: INS-001 | Tax ID: 100-200-300\nMarine Underwriting Specialist: Ayman Helmy (+20 100 777 6655)\nHotline: 19990 | Marine Email: marine.cargo@misr-ins.com.eg\nWeb: https://www.misr-ins.com.eg\nCoverage: Institute Cargo Clauses (A) - All Risks, War & Strikes\nAddress: 7 Talaat Harb St., Downtown, Cairo, Egypt';
      case EntityTarget.bank:
        return 'الصق هنا بيانات البنك المصرفي والسويفت كود:\n\nمثال:\nNational Bank of Egypt (NBE)\nSWIFT / BIC Code: NBEGEGCX001\nBank Code: NBE-001 | Branch: Corporate Main Branch\nContact: Trade Finance Officer Ahmed Salem\nPhone: +20 2 2594 5000 | Email: corporate@nbe.com.eg\nAddress: 1187 Corniche El-Nil, Cairo, Egypt';
      case EntityTarget.partner:
        return 'الصق هنا بيانات الشريك اللوجستي...';
    }
  }
}

