import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../constants/api_constants.dart';
import 'searchable_dropdown_field.dart';
import 'extraction_progress_dialog.dart';

enum EntityTarget { supplier, company, partner, bank }

class UniversalEntityExtractorDialog extends StatefulWidget {
  final EntityTarget initialTarget;
  final VoidCallback? onSaved;

  const UniversalEntityExtractorDialog({
    super.key,
    this.initialTarget = EntityTarget.supplier,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    EntityTarget initialTarget = EntityTarget.supplier,
    VoidCallback? onSaved,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UniversalEntityExtractorDialog(
        initialTarget: initialTarget,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<UniversalEntityExtractorDialog> createState() => _UniversalEntityExtractorDialogState();
}

class _UniversalEntityExtractorDialogState extends State<UniversalEntityExtractorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late EntityTarget _selectedTarget;
  int _inputModeTab = 0; // 0: Raw Text, 1: File/Image
  bool _isExtracting = false;
  bool _isSaving = false;

  final TextEditingController _rawTextCtrl = TextEditingController();

  // Common Controllers
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _arabicNameCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'China');
  final TextEditingController _countryCodeCtrl = TextEditingController(text: 'CN');

  // Supplier Specific
  final TextEditingController _cargoxIdCtrl = TextEditingController();
  final TextEditingController _foreignTaxIdCtrl = TextEditingController();
  final TextEditingController _brandsCtrl = TextEditingController();
  String _supplierRegType = 'Commercial Register';
  final String _supplierType = 'Manufacturer';

  // Importer Specific
  String _importerCountry = 'Egypt';
  final TextEditingController _importerCountryCtrl = TextEditingController(text: 'Egypt');
  final TextEditingController _taxIdCtrl = TextEditingController(); // 9-digits Egyptian Tax
  final TextEditingController _commercialRegisterCtrl = TextEditingController();
  final TextEditingController _importerCardCtrl = TextEditingController();
  final TextEditingController _nafezaTokenCtrl = TextEditingController();
  DateTime _importerIdExpiry = DateTime.now().add(const Duration(days: 365 * 3));
  DateTime _vatIdExpiry = DateTime.now().add(const Duration(days: 365 * 3));
  DateTime _registrationExpiry = DateTime.now().add(const Duration(days: 365 * 3));

  // Partner Specific
  String _partnerTypeStr = 'Customs Broker';
  final TextEditingController _brokerLicenseCtrl = TextEditingController();
  final TextEditingController _portsCtrl = TextEditingController(text: 'الإسكندرية, السخنة');

  // Bank Specific
  final TextEditingController _swiftCodeCtrl = TextEditingController();
  final TextEditingController _branchNameCtrl = TextEditingController(text: 'Main Branch');
  final TextEditingController _bankAccountCtrl = TextEditingController();

  String? _selectedFileName;
  double _confidenceScore = 0.0;

  static const List<Map<String, String>> _countryList = [
    {'code': 'CN', 'name': 'الصين (China)'},
    {'code': 'DE', 'name': 'ألمانيا (Germany)'},
    {'code': 'IT', 'name': 'إيطاليا (Italy)'},
    {'code': 'TR', 'name': 'تركيا (Turkey)'},
    {'code': 'US', 'name': 'الولايات المتحدة (USA)'},
    {'code': 'GB', 'name': 'المملكة المتحدة (UK)'},
    {'code': 'ES', 'name': 'إسبانيا (Spain)'},
    {'code': 'FR', 'name': 'فرنسا (France)'},
    {'code': 'IN', 'name': 'الهند (India)'},
    {'code': 'JP', 'name': 'اليابان (Japan)'},
    {'code': 'KR', 'name': 'كوريا الجنوبية (South Korea)'},
    {'code': 'AE', 'name': 'الإمارات (UAE)'},
    {'code': 'SA', 'name': 'السعودية (Saudi Arabia)'},
    {'code': 'EG', 'name': 'مصر (Egypt)'},
    {'code': 'BR', 'name': 'البرازيل (Brazil)'},
    {'code': 'RU', 'name': 'روسيا (Russia)'},
    {'code': 'VN', 'name': 'فيتنام (Vietnam)'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget;
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
    _brokerLicenseCtrl.dispose();
    _portsCtrl.dispose();
    _swiftCodeCtrl.dispose();
    _branchNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  Future<void> _extractFromRawText() async {
    final text = _rawTextCtrl.text.trim();
    if (text.isEmpty) return;

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.15,
      status: 'جاري فحص النص المدخل...',
      stepLabel: 'المرحلة 1 من 4: تحليل النص',
      currentStep: 1,
    );

    setState(() => _isExtracting = true);

    if (mounted) {
      ExtractionProgressDialog.show(
        context: context,
        title: 'جاري استخراج بيانات ${_targetArabicName(_selectedTarget)} من النص',
        fileName: 'النص المنسوخ (${text.length} حرف)',
        controller: progressCtrl,
      );
    }

    progressCtrl.startAutoAdvance(targetPercent: 0.90, duration: const Duration(seconds: 3));

    try {
      final dio = Dio();
      final formData = FormData.fromMap({'raw_text': text});
      final resp = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse-text/master-data-entity',
        data: formData,
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 350));

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
      case EntityTarget.partner:
        return 'مقدم الخدمة / المخلص';
      case EntityTarget.bank:
        return 'البنك المصرفي';
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
        ? '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '${(file.size / 1024).toStringAsFixed(1)} KB';

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.15,
      status: 'جاري قراءة محتوى المستند...',
      stepLabel: 'المرحلة 1 من 4: فحص وتهيئة المستند',
      currentStep: 1,
    );

    setState(() {
      _isExtracting = true;
      _selectedFileName = file.name;
    });

    if (mounted) {
      ExtractionProgressDialog.show(
        context: context,
        title: 'جاري استخراج بيانات ${_targetArabicName(_selectedTarget)} (OCR)',
        fileName: file.name,
        fileSize: fileSizeFormatted,
        controller: progressCtrl,
      );
    }

    try {
      final dio = Dio();
      final multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);

      final formData = FormData.fromMap({'file': multipartFile});
      final resp = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse/master-data-entity',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final uploadRatio = sent / total;
            final currentP = 0.15 + (uploadRatio * 0.35);
            final pctInt = (currentP * 100).round();
            progressCtrl.update(
              percent: currentP,
              status: 'جاري رفع المستند ($pctInt%)...',
              stepLabel: 'المرحلة 2 من 4: رفع المستند',
              currentStep: 2,
            );

            if (uploadRatio >= 0.99) {
              progressCtrl.startAutoAdvance(targetPercent: 0.92, duration: const Duration(seconds: 4));
            }
          }
        },
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 350));

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
          SnackBar(content: Text('خطأ في قراءة المستند: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  void _populateFields(Map<String, dynamic> ext, double score) {
    setState(() {
      _confidenceScore = score;
      if (ext['company_name'] != null) _companyNameCtrl.text = ext['company_name'].toString();
      if (ext['arabic_name'] != null) _arabicNameCtrl.text = ext['arabic_name'].toString();
      if (ext['contact_person'] != null) _contactPersonCtrl.text = ext['contact_person'].toString();
      if (ext['phone_number'] != null) _phoneCtrl.text = ext['phone_number'].toString();
      if (ext['mobile_number'] != null) _mobileCtrl.text = ext['mobile_number'].toString();
      if (ext['email'] != null) _emailCtrl.text = ext['email'].toString();
      if (ext['website'] != null) _websiteCtrl.text = ext['website'].toString();
      if (ext['address'] != null) _addressCtrl.text = ext['address'].toString();

      final ctyCode = ext['country_code']?.toString().toUpperCase() ?? '';
      if (ctyCode.isNotEmpty) {
        _countryCodeCtrl.text = ctyCode;
        final match = _countryList.firstWhere((c) => c['code'] == ctyCode, orElse: () => {'name': ctyCode});
        _countryCtrl.text = match['name'] ?? ctyCode;
        if (ctyCode == 'EG') {
          _importerCountryCtrl.text = 'Egypt';
        }
      }

      if (ext['cargox_id'] != null) _cargoxIdCtrl.text = ext['cargox_id'].toString();
      if (ext['vat_tax_id'] != null) {
        _foreignTaxIdCtrl.text = ext['vat_tax_id'].toString();
        _taxIdCtrl.text = ext['vat_tax_id'].toString();
      }
      if (ext['commercial_register'] != null) _commercialRegisterCtrl.text = ext['commercial_register'].toString();
      if (ext['importer_id'] != null) _importerCardCtrl.text = ext['importer_id'].toString();
      if (ext['license_number'] != null) _brokerLicenseCtrl.text = ext['license_number'].toString();
      if (ext['swift_code'] != null) _swiftCodeCtrl.text = ext['swift_code'].toString();
      if (ext['bank_account'] != null || ext['iban'] != null) {
        _bankAccountCtrl.text = ext['bank_account']?.toString() ?? ext['iban']?.toString() ?? '';
      }
      if (ext['industry_description'] != null) _brandsCtrl.text = ext['industry_description'].toString();

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
    final effectiveName = arabicName.isNotEmpty ? arabicName : name;

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    if (effectiveName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ اسم الشركة / الجهة مطلوب لإتمام الحفظ والتكويد.'), backgroundColor: AppTheme.orange),
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
          final cty = _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : 'China';
          final ctyCode = _countryCodeCtrl.text.trim().isNotEmpty ? _countryCodeCtrl.text.trim() : 'CN';
          final taxId = _foreignTaxIdCtrl.text.trim();
          final cargox = _cargoxIdCtrl.text.trim();
          payload = {
            'company_name': name.isNotEmpty ? name : arabicName,
            'supplier_type': _supplierType,
            'registration_type': _supplierRegType,
            'foreign_exporter_id': taxId.isNotEmpty ? taxId : 'EXP-${DateTime.now().millisecondsSinceEpoch}',
            'foreign_exporter_country': cty,
            'foreign_exporter_country_code': ctyCode,
            'cargox_id': cargox.isNotEmpty ? cargox : null,
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Foreign Exporter Address',
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'brands': _brandsCtrl.text.trim(),
            'swift_code': _swiftCodeCtrl.text.trim(),
            'bank_account': _bankAccountCtrl.text.trim(),
          };
          break;

        case EntityTarget.company:
          endpoint = '${ApiConstants.baseUrl}/import-companies';
          final impId = _importerCardCtrl.text.trim();
          final vatId = _taxIdCtrl.text.trim();
          final regNum = _commercialRegisterCtrl.text.trim();
          final finalName = name.isNotEmpty ? name : arabicName;

          payload = {
            'importer_name': finalName,
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Cairo, Egypt',
            'country': _importerCountry.isNotEmpty ? _importerCountry : (_importerCountryCtrl.text.trim().isNotEmpty ? _importerCountryCtrl.text.trim() : 'Egypt'),
            'importer_id': impId.isNotEmpty ? impId : 'IMP-${DateTime.now().millisecondsSinceEpoch}',
            'importer_id_expiry': '${_importerIdExpiry.year}-${_importerIdExpiry.month.toString().padLeft(2, '0')}-${_importerIdExpiry.day.toString().padLeft(2, '0')}',
            'vat_id': vatId.isNotEmpty ? vatId : '000000000',
            'vat_id_expiry': '${_vatIdExpiry.year}-${_vatIdExpiry.month.toString().padLeft(2, '0')}-${_vatIdExpiry.day.toString().padLeft(2, '0')}',
            'registration_number': regNum.isNotEmpty ? regNum : '000000',
            'registration_expiry': '${_registrationExpiry.year}-${_registrationExpiry.month.toString().padLeft(2, '0')}-${_registrationExpiry.day.toString().padLeft(2, '0')}',
            'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
            'email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
            'notes': _nafezaTokenCtrl.text.trim().isNotEmpty ? 'Nafeza E-Token: ${_nafezaTokenCtrl.text.trim()}' : null,
          };
          break;

        case EntityTarget.partner:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': _partnerTypeStr,
            'license_number': _brokerLicenseCtrl.text.trim().isNotEmpty ? _brokerLicenseCtrl.text.trim() : null,
            'ports_of_operation': _portsCtrl.text.trim().isNotEmpty ? _portsCtrl.text.trim() : null,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'country': 'Egypt',
            'tax_id': _taxIdCtrl.text.trim(),
            'commercial_register': _commercialRegisterCtrl.text.trim(),
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
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'country': 'Egypt',
          };
          break;
      }

      await dio.post(endpoint, data: payload);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تكويد وحفظ السجل كـ ${_targetLabel(_selectedTarget)} بنجاح في قاعدة البيانات!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String errMsg = 'خطأ أثناء الحفظ في قاعدة البيانات';
        if (e is DioException) {
          final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
          errMsg = detail != null ? detail.toString() : (e.message ?? errMsg);
        } else {
          errMsg = '$e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errMsg'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  String _targetLabel(EntityTarget target) {
    switch (target) {
      case EntityTarget.supplier:
        return 'مورد أجنبي (Supplier / Exporter)';
      case EntityTarget.company:
        return 'شركة مستوردة (Importer / Consignee)';
      case EntityTarget.partner:
        return 'شريك / مخلص / ناقل (Partner / Broker)';
      case EntityTarget.bank:
        return 'بنك معتمد (Bank / Financial)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1100,
        height: 750,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أداة التكويد والاستخراج الذكي الشاملة للمستوردين والموردين والشركاء والبنوك',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'AI-Powered Universal Master Data Entity Extractor & Auto-Registration Engine',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Top Target Selector Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Text('توجيه التكويد المباشر إلى:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                  const SizedBox(width: 12),
                  _buildTargetButton(EntityTarget.supplier, '🌍 مورد أجنبي', Icons.public),
                  const SizedBox(width: 8),
                  _buildTargetButton(EntityTarget.company, '🏢 شركة مستوردة', Icons.domain),
                  const SizedBox(width: 8),
                  _buildTargetButton(EntityTarget.partner, '🤝 شريك / مخلص / ناقل', Icons.handshake),
                  const SizedBox(width: 8),
                  _buildTargetButton(EntityTarget.bank, '🏦 بنك معتمد', Icons.account_balance),
                ],
              ),
            ),

            // Main Split Workspace
            Expanded(
              child: Row(
                children: [
                  // Left Pane: Input Sources (Text / File / Image)
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.cloudWhite.withOpacity(0.35),
                        border: Border(left: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Input Mode Selector Tabs
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _inputModeTab == 0 ? AppTheme.emerald : Colors.white,
                                    foregroundColor: _inputModeTab == 0 ? Colors.white : AppTheme.charcoal,
                                    elevation: _inputModeTab == 0 ? 2 : 0,
                                    side: BorderSide(color: _inputModeTab == 0 ? AppTheme.emerald : Colors.grey.shade300),
                                  ),
                                  icon: const Icon(Icons.paste_rounded, size: 16),
                                  label: const Text('لصق نص حر (Raw Text)'),
                                  onPressed: () => setState(() => _inputModeTab = 0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _inputModeTab == 1 ? AppTheme.cobalt : Colors.white,
                                    foregroundColor: _inputModeTab == 1 ? Colors.white : AppTheme.charcoal,
                                    elevation: _inputModeTab == 1 ? 2 : 0,
                                    side: BorderSide(color: _inputModeTab == 1 ? AppTheme.cobalt : Colors.grey.shade300),
                                  ),
                                  icon: const Icon(Icons.file_present_rounded, size: 16),
                                  label: const Text('ملف PDF / Excel / صورة'),
                                  onPressed: () => setState(() => _inputModeTab = 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Left Body
                          if (_inputModeTab == 0) ...[
                            Expanded(
                              child: TextField(
                                controller: _rawTextCtrl,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: _getPlaceholderForTarget(_selectedTarget),
                                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cobalt,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: _isExtracting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: Text(_isExtracting ? 'جاري تحليل النص بالذكاء الاصطناعي...' : 'استخراج وتحليل البيانات تلقائياً ✨'),
                                onPressed: _isExtracting ? null : _extractFromRawText,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: InkWell(
                                onTap: _pickAndExtractFile,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.cobalt.withOpacity(0.5), width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_upload_rounded, color: AppTheme.cobalt, size: 48),
                                      const SizedBox(height: 12),
                                      const Text('اضغط لاختيار صورة، كارت عمل، PDF، أو Excel',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      const SizedBox(height: 6),
                                      Text(
                                        _selectedFileName ?? 'يدعم صيغ (PNG, JPG, PDF, XLSX, DOCX)',
                                        style: TextStyle(fontSize: 11, color: AppTheme.charcoal.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cobalt,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: _isExtracting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.file_open_rounded, size: 18),
                                label: Text(_isExtracting ? 'جاري قراءة وتحليل المستند...' : 'اختيار ملف واستخراج البيانات ✨'),
                                onPressed: _isExtracting ? null : _pickAndExtractFile,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Right Pane: Dedicated Form Cards per Entity
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header + Confidence Score + Target Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(_getTargetIcon(_selectedTarget), color: AppTheme.cobalt, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'بيانات تكويد ${_targetLabel(_selectedTarget)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                              if (_confidenceScore > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.emerald),
                                  ),
                                  child: Text(
                                    'دقة الاستخراج: ${(_confidenceScore * 100).round()}%',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Scrollable Form Fields
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                child: _buildDedicatedFormForTarget(_selectedTarget),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          // Bottom Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emerald,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: _isSaving
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_rounded, size: 20),
                              label: Text(
                                _isSaving ? 'جاري حفظ وتكويد السجل...' : 'حفظ وتكويد ${_targetLabel(_selectedTarget)} في قاعدة البيانات 💾',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: _isSaving ? null : _saveEntityToDatabase,
                            ),
                          ),
                        ],
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

  Widget _buildTargetButton(EntityTarget target, String label, IconData icon) {
    final isSelected = _selectedTarget == target;
    return InkWell(
      onTap: () => setState(() => _selectedTarget = target),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cobalt : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.cobalt : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.cobalt.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.charcoal),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.charcoal,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDedicatedFormForTarget(EntityTarget target) {
    switch (target) {
      case EntityTarget.supplier:
        return _buildSupplierForm();
      case EntityTarget.company:
        return _buildImporterForm();
      case EntityTarget.partner:
        return _buildPartnerForm();
      case EntityTarget.bank:
        return _buildBankForm();
    }
  }

  // 1. 🌍 Foreign Supplier Form
  Widget _buildSupplierForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(
            labelText: 'اسم المورد الأجنبي بالإنجليزية (Company English Name) *',
            prefixIcon: Icon(Icons.business_rounded, size: 18),
            hintText: 'e.g. Suzhou Yuheng Textile Co., Ltd',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المورد الأجنبي مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                value: _countryCodeCtrl.text.isNotEmpty ? _countryCodeCtrl.text : 'CN',
                labelText: 'دولة المنشأ / المقر (Country) *',
                items: _countryList.map((c) => SearchableDropdownItem(value: c['code']!, label: '${c['code']} - ${c['name']}')).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _countryCodeCtrl.text = val;
                      final match = _countryList.firstWhere((c) => c['code'] == val, orElse: () => {'name': val});
                      _countryCtrl.text = match['name'] ?? val;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                value: _supplierRegType,
                labelText: 'نوع السجل الأجنبي *',
                items: const [
                  SearchableDropdownItem(value: 'Company Registration Number', label: 'Company Registration Number (رقم تسجيل الشركة)'),
                  SearchableDropdownItem(value: 'Commercial Register', label: 'Commercial Register (سجل تجاري)'),
                  SearchableDropdownItem(value: 'Foreign Exporter Number (Nafeza)', label: 'Foreign Exporter Number (Nafeza)'),
                  SearchableDropdownItem(value: 'Factory Registration', label: 'Factory Registration (تسجيل مصنع)'),
                  SearchableDropdownItem(value: 'VAT Number', label: 'VAT Number (رقم القيمة المضافة)'),
                  SearchableDropdownItem(value: 'Tax Number', label: 'Tax Number (رقم ضريبي)'),
                  SearchableDropdownItem(value: 'DUNS Number', label: 'DUNS No (رقم دنز)'),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _supplierRegType = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _foreignTaxIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم التسجيل الأجنبي (Foreign Exporter ID / VAT) *',
                  prefixIcon: Icon(Icons.badge_rounded, size: 18),
                  hintText: 'e.g. 91320581MA1X...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _cargoxIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'معرف كارجو إكس (CargoX Blockchain ID) *',
                  prefixIcon: Icon(Icons.token_rounded, size: 18, color: Colors.indigo),
                  hintText: 'e.g. 0x71C... أو CX-98214',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان المصنع / المقر الرئيسي (Factory Address) *',
            prefixIcon: Icon(Icons.location_on_rounded, size: 18),
            hintText: 'e.g. No.16, Kangsheng Road, Changshu, Jiangsu, China',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _contactPersonCtrl,
                decoration: const InputDecoration(labelText: 'مسؤول التواصل / المبيعات', prefixIcon: Icon(Icons.person_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _mobileCtrl,
                decoration: const InputDecoration(labelText: 'واتساب / المحمول (WhatsApp)', prefixIcon: Icon(Icons.phone_android_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني (Email)', prefixIcon: Icon(Icons.email_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(labelText: 'الموقع الإلكتروني (Website)', prefixIcon: Icon(Icons.language_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _swiftCodeCtrl,
                decoration: const InputDecoration(labelText: 'السويفت كود البنكي (SWIFT)', prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _brandsCtrl,
                decoration: const InputDecoration(labelText: 'العلامات التجارية والنشاط (Brands / Industry)', prefixIcon: Icon(Icons.category_rounded, size: 18)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. 🏢 Importing Company Form (Matches Egyptian Import Company Specifications)
  Widget _buildImporterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Name
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(
            labelText: 'اسم الشركة المستوردة (Company Name) *',
            prefixIcon: Icon(Icons.domain_rounded, size: 18),
            hintText: 'e.g. Al-Noor Import & Export LLC',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الشركة المستوردة مطلوب' : null,
        ),
        const SizedBox(height: 10),

        // Address & Country
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'المقر الرئيسي والعنوان (Address) *',
                  prefixIcon: Icon(Icons.location_on_rounded, size: 18),
                  hintText: 'مثال: 15 شارع طلعت حرب - وسط البلد - القاهرة',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                value: _importerCountry,
                labelText: 'الدولة (Country) *',
                searchHintText: 'ابحث عن الدولة...',
                items: _countryList.map((c) => SearchableDropdownItem<String>(
                  value: c['name'] ?? 'Egypt',
                  label: c['name'] ?? 'Egypt',
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _importerCountry = val;
                      _importerCountryCtrl.text = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Importer Card & Expiry Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _importerCardCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم البطاقة الاستيرادية (Importer Card ID - 9 digits) *',
                  prefixIcon: Icon(Icons.card_membership_rounded, size: 18, color: AppTheme.cobalt),
                  hintText: 'مثال: 528153439',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDatePickerBox(
                label: 'تاريخ انتهاء البطاقة الاستيرادية *',
                date: _importerIdExpiry,
                onDateSelected: (newDate) => setState(() => _importerIdExpiry = newDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // VAT Tax ID & Expiry Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _taxIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم البطاقة الضريبية (VAT Registration ID - 9 digits) *',
                  prefixIcon: Icon(Icons.receipt_long_rounded, size: 18, color: Colors.deepOrange),
                  hintText: 'مثال: 528153439',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDatePickerBox(
                label: 'تاريخ انتهاء التسجيل الضريبي *',
                date: _vatIdExpiry,
                onDateSelected: (newDate) => setState(() => _vatIdExpiry = newDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Commercial Register & Expiry Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _commercialRegisterCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم السجل التجاري (Commercial Reg # - 15 digits) *',
                  prefixIcon: Icon(Icons.app_registration_rounded, size: 18),
                  hintText: 'مثال: 100200000070828',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDatePickerBox(
                label: 'تاريخ انتهاء السجل التجاري *',
                date: _registrationExpiry,
                onDateSelected: (newDate) => setState(() => _registrationExpiry = newDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Phone & Email
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف / المحمول (Phone Number)',
                  prefixIcon: Icon(Icons.phone_rounded, size: 18),
                  hintText: '+20 100 000 0000',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني للشركة (Email)',
                  prefixIcon: Icon(Icons.email_rounded, size: 18),
                  hintText: 'info@company.com',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Nafeza Token / Notes
        TextField(
          controller: _nafezaTokenCtrl,
          decoration: const InputDecoration(
            labelText: 'كود حساب نافذة / الرمز الإلكتروني (Nafeza E-Token / Notes)',
            prefixIcon: Icon(Icons.vpn_key_rounded, size: 18),
            hintText: 'مثال: Nafeza-Portal-Token أو ملاحظات إضافية',
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerBox({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2045),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.cobalt),
                const SizedBox(width: 8),
                Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. 🤝 External Partner Form
  Widget _buildPartnerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                value: _partnerTypeStr,
                labelText: 'نوع وتصنيف الشريك *',
                items: const [
                  SearchableDropdownItem(value: 'Customs Broker', label: 'Customs Broker (مخلص جمركي)'),
                  SearchableDropdownItem(value: 'Shipping Line', label: 'Shipping Line (خط ملاحي)'),
                  SearchableDropdownItem(value: 'Freight Forwarder', label: 'Freight Forwarder (شركة شحن دولي)'),
                  SearchableDropdownItem(value: 'Inland Transport', label: 'Inland Transport (ناقل بري محلي)'),
                  SearchableDropdownItem(value: 'Inspection Agency', label: 'Inspection Agency (شركة فحص ومعاينة)'),
                  SearchableDropdownItem(value: 'Insurance Company', label: 'Insurance Co (شركة تأمين)'),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _partnerTypeStr = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _companyNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم التجاري للشريك / المكتب *',
                  prefixIcon: Icon(Icons.handshake_rounded, size: 18),
                  hintText: 'مثال: مكتب النسر للتخليص الجمركي',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الشريك مطلوب' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_partnerTypeStr == 'Customs Broker') ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _brokerLicenseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم رخصة القيد والتخليص الجمركي *',
                    prefixIcon: Icon(Icons.verified_rounded, size: 18, color: Colors.purple),
                    hintText: 'مثال: LIC-EG-2024/991',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _portsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'موانئ التخصص والعمل *',
                    prefixIcon: Icon(Icons.anchor_rounded, size: 18),
                    hintText: 'الإسكندرية, السخنة, بورسعيد...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taxIdCtrl,
                decoration: const InputDecoration(labelText: 'الرقم الضريبي / السجل', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _contactPersonCtrl,
                decoration: const InputDecoration(labelText: 'الشخص المسؤول / المنسق', prefixIcon: Icon(Icons.person_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'الهاتف المباشر', prefixIcon: Icon(Icons.phone_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _mobileCtrl,
                decoration: const InputDecoration(labelText: 'المحمول / واتساب العمل', prefixIcon: Icon(Icons.phone_android_rounded, size: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان المكتب / الفرع الرئيسي',
            prefixIcon: Icon(Icons.location_on_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  // 4. 🏦 Bank Form
  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameCtrl,
          decoration: const InputDecoration(
            labelText: 'اسم البنك والمؤسسة المصرفية *',
            prefixIcon: Icon(Icons.account_balance_rounded, size: 18),
            hintText: 'مثال: البنك التجاري الدولي (CIB) أو Banque Misr',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم البنك مطلوب' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _swiftCodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'كود السويفت الدولي (SWIFT / BIC Code) *',
                  prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.blue),
                  hintText: 'e.g. CIBEGGCAXXX',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _branchNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الفرع المعتمد (Branch Name) *',
                  prefixIcon: Icon(Icons.store_rounded, size: 18),
                  hintText: 'مثال: فرع المهندسين / فرع مدينة نصر',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان المقر / الفرع',
            prefixIcon: Icon(Icons.location_on_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'هاتف خدمة العملاء والاعتمادات', prefixIcon: Icon(Icons.phone_rounded, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني للفرع', prefixIcon: Icon(Icons.email_rounded, size: 18)),
              ),
            ),
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
      case EntityTarget.partner:
        return Icons.handshake;
      case EntityTarget.bank:
        return Icons.account_balance;
    }
  }

  String _getPlaceholderForTarget(EntityTarget target) {
    switch (target) {
      case EntityTarget.supplier:
        return 'الصق هنا ترويسة الفاتورة المبدئية أو كارت المورد الأجنبي:\n\nمثال:\nSuzhou Yuheng Textile Co., Ltd\nFactory Address: No.16, Kangsheng Road, Changshu, Jiangsu, China\nVAT Number: 91320581MA1X7... CargoX ID: 0x71C8a9...\nTel: +86-512-52889988\nEmail: export@yuheng.com\nSWIFT: BKCHCNBJ920';
      case EntityTarget.company:
        return 'الصق هنا بيانات الشركة المستوردة أو السجل التجاري والبطاقة الضريبية:\n\nمثال:\nشركة النور للاستيراد والتصدير ش.م.م\nالعنوان: 15 شارع طلعت حرب - القاهرة\nالدولة: Egypt\nالبطاقة الاستيرادية: 759552827 (تنتهي في 2029-03-31)\nالبطاقة الضريبية: 759552827 (تنتهي في 2029-03-31)\nالسجل التجاري: 228795 (ينتهي في 2029-03-04)\nهاتف: +20 100 000 0000\nالبريد: info@alnoor-import.com';
      case EntityTarget.partner:
        return 'الصق هنا كارت المخلص الجمركي أو شركة الشحن:\n\nمثال:\nمكتب النسر للخدمات اللوجستية والتخليص الجمركي\nرخصة التخليص: 2024/819\nموانئ العمل: الإسكندرية - السخنة - الدخيلة\nهاتف: 01001234567';
      case EntityTarget.bank:
        return 'الصق هنا بيانات البنك والسويفت كود:\n\nمثال:\nCommercial International Bank (CIB)\nSWIFT Code: CIBEGGCAXXX\nBranch: Head Office Cairo Egypt';
    }
  }
}
