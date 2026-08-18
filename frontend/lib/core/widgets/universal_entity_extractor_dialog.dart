// TODO: Refactor to ConsumerWidget to use dioProvider/uploadDioProvider
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/widgets/searchable_dropdown_field.dart';

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
  late EntityTarget _selectedTarget;
  int _inputModeTab = 0; // 0: Raw Text, 1: File/Image
  bool _isExtracting = false;
  bool _isSaving = false;

  final TextEditingController _rawTextCtrl = TextEditingController();
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _taxIdCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _industryCtrl = TextEditingController();
  final TextEditingController _commercialRegisterCtrl = TextEditingController();
  final TextEditingController _importerIdCtrl = TextEditingController();
  final TextEditingController _swiftCodeCtrl = TextEditingController();
  final TextEditingController _bankAccountCtrl = TextEditingController();

  String _partnerTypeStr = 'Freight Forwarder';
  String? _selectedFileName;
  double _confidenceScore = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget;
  }

  @override
  void dispose() {
    _rawTextCtrl.dispose();
    _companyNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    _countryCtrl.dispose();
    _industryCtrl.dispose();
    _commercialRegisterCtrl.dispose();
    _importerIdCtrl.dispose();
    _swiftCodeCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  Future<void> _extractFromRawText() async {
    final text = _rawTextCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isExtracting = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({'raw_text': text});
      final resp = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse-text/master-data-entity',
        data: formData,
      );

      if (resp.statusCode == 200 && resp.data != null) {
        final extracted = resp.data['extracted_fields'] as Map<String, dynamic>? ?? {};
        final score = (resp.data['confidence_score'] as num?)?.toDouble() ?? 0.8;
        _populateFields(extracted, score);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استخراج النص: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
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

    setState(() {
      _isExtracting = true;
      _selectedFileName = file.name;
    });

    try {
      final dio = Dio();
      final multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);

      final formData = FormData.fromMap({'file': multipartFile});
      final resp = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse/master-data-entity',
        data: formData,
      );

      if (resp.statusCode == 200 && resp.data != null) {
        final extracted = resp.data['extracted_fields'] as Map<String, dynamic>? ?? {};
        final score = (resp.data['confidence_score'] as num?)?.toDouble() ?? 0.8;
        _populateFields(extracted, score);
      }
    } catch (e) {
      if (mounted) {
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
      _companyNameCtrl.text = ext['company_name']?.toString() ?? '';
      _contactPersonCtrl.text = ext['contact_person']?.toString() ?? '';
      _phoneCtrl.text = ext['phone_number']?.toString() ?? '';
      _mobileCtrl.text = ext['mobile_number']?.toString() ?? '';
      _emailCtrl.text = ext['email']?.toString() ?? '';
      _websiteCtrl.text = ext['website']?.toString() ?? '';
      _taxIdCtrl.text = ext['vat_tax_id']?.toString() ?? '';
      _addressCtrl.text = ext['address']?.toString() ?? '';
      _countryCtrl.text = ext['country_code']?.toString() ?? '';
      _industryCtrl.text = ext['industry_description']?.toString() ?? '';
      _commercialRegisterCtrl.text = ext['commercial_register']?.toString() ?? '';
      _importerIdCtrl.text = ext['importer_id']?.toString() ?? '';
      _swiftCodeCtrl.text = ext['swift_code']?.toString() ?? '';
      _bankAccountCtrl.text = ext['bank_account']?.toString() ?? ext['iban']?.toString() ?? '';
    });
  }

  Future<void> _saveEntityToDatabase() async {
    final name = _companyNameCtrl.text.trim();
    if (name.isEmpty) {
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
          final ctyCode = cty.length >= 2 ? cty.substring(0, 2).toUpperCase() : 'CN';
          final taxId = _taxIdCtrl.text.trim();
          payload = {
            'company_name': name,
            'supplier_type': _industryCtrl.text.trim().isNotEmpty ? _industryCtrl.text.trim() : 'Manufacturer',
            'registration_type': 'Foreign Exporter',
            'foreign_exporter_id': taxId.isNotEmpty ? taxId : 'EXP-${DateTime.now().millisecondsSinceEpoch}',
            'foreign_exporter_country': cty,
            'foreign_exporter_country_code': ctyCode,
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Foreign Exporter Address',
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'brands': _industryCtrl.text.trim(),
          };
          break;

        case EntityTarget.company:
          endpoint = '${ApiConstants.baseUrl}/import-companies';
          final impId = _importerIdCtrl.text.trim();
          final vatId = _taxIdCtrl.text.trim();
          final regNum = _commercialRegisterCtrl.text.trim();
          payload = {
            'importer_name': name,
            'company_type': _industryCtrl.text.trim().isNotEmpty ? _industryCtrl.text.trim() : 'LLC',
            'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'القاهرة - مصر',
            'country': _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : 'Egypt',
            'importer_id': impId.isNotEmpty ? impId : 'IMP-REG-${DateTime.now().millisecondsSinceEpoch}',
            'importer_id_expiry': '2030-12-31',
            'vat_id': vatId.isNotEmpty ? vatId : '000000000',
            'vat_id_expiry': '2030-12-31',
            'registration_number': regNum.isNotEmpty ? regNum : '000000',
            'registration_expiry': '2030-12-31',
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'contact_person': _contactPersonCtrl.text.trim(),
            'bank_name': 'Commercial International Bank (CIB)',
            'bank_account': _bankAccountCtrl.text.trim(),
            'iban': _bankAccountCtrl.text.trim(),
            'swift_code': _swiftCodeCtrl.text.trim(),
          };
          break;

        case EntityTarget.partner:
          endpoint = '${ApiConstants.baseUrl}/external-service-providers';
          payload = {
            'partner_name': name,
            'partner_type': _partnerTypeStr,
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'website': _websiteCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'country': _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : 'Egypt',
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
            'branch_name': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'Main Branch',
            'contact_person': _contactPersonCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'country': _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : 'Egypt',
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
            content: Text('✅ تم تكويد وحفظ السجل كـ ${_targetLabel(_selectedTarget)} بنجاح!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String msg = '$e';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['detail'] != null) {
            msg = data['detail'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.crimson,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 1020,
        height: 680,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ── Header Bar & Entity Target Selector ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_alt_rounded, color: AppTheme.cobalt, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'أداة التكويد والاستخراج الذكي الشاملة للمستوردين والموردين والشركاء',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target Selector Buttons (الجهة المطلوب التكويد إليها)
                  Row(
                    children: [
                      const Text('توجيه التكويد إلى: ',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      _buildTargetChip(EntityTarget.supplier, '🌍 مورد أجنبي', Icons.public_rounded),
                      const SizedBox(width: 8),
                      _buildTargetChip(EntityTarget.company, '🏢 شركة مستوردة', Icons.domain_rounded),
                      const SizedBox(width: 8),
                      _buildTargetChip(EntityTarget.partner, '🤝 شريك / مخلص / ناقل', Icons.handshake_rounded),
                      const SizedBox(width: 8),
                      _buildTargetChip(EntityTarget.bank, '🏦 بنك / جهة مصرفية', Icons.account_balance_rounded),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Body: Left Input Pane & Right Extracted Form Pane ──────────────
            Expanded(
              child: Row(
                children: [
                  // Left Pane: Input Modes (Raw Text / File OCR)
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.cloudWhite.withOpacity(0.5),
                        border: Border(left: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [Icon(Icons.paste_rounded, size: 14), SizedBox(width: 6), Text('لصق نص حرة')],
                                ),
                                selected: _inputModeTab == 0,
                                onSelected: (sel) => setState(() => _inputModeTab = 0),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [Icon(Icons.upload_file_rounded, size: 14), SizedBox(width: 6), Text('صورة / PDF / Excel')],
                                ),
                                selected: _inputModeTab == 1,
                                onSelected: (sel) => setState(() => _inputModeTab = 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_inputModeTab == 0) ...[
                            Expanded(
                              child: TextField(
                                controller: _rawTextCtrl,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(fontSize: 13, height: 1.4),
                                decoration: InputDecoration(
                                  hintText: 'الصق النص الكامل للشركة هنا...\nمثال:\nFactory owner M:0086 15962900581 W:www.yhacoustic.com\nSuzhou Yuheng Textile Co.,Ltd\nFactory Address: N0.16, Kangsheng Road...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isExtracting ? AppTheme.cobalt.withOpacity(0.7) : AppTheme.cobalt,
                                  foregroundColor: Colors.white,
                                ),
                                icon: _isExtracting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                                label: Text(_isExtracting ? 'جاري تحليل النص واستخراج البيانات...' : 'استخراج وتحليل البيانات تلقائياً'),
                                onPressed: _isExtracting ? null : _extractFromRawText,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: _isExtracting
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cobalt.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.cobalt, width: 2),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cobalt.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const CircularProgressIndicator(color: AppTheme.cobalt, strokeWidth: 3),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            '🚀 جاري قراءة واستخراج البيانات بالذكاء الاصطناعي...',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _selectedFileName != null
                                                ? 'جاري تحليل المستند: $_selectedFileName\nقد تستغرق العملية بضع ثوانٍ...'
                                                : 'جاري المعالجة والتحليل...',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, height: 1.4),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: const SizedBox(
                                              width: 180,
                                              height: 4,
                                              child: LinearProgressIndicator(color: AppTheme.cobalt, backgroundColor: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : InkWell(
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
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                                            const SizedBox(height: 6),
                                            Text(
                                              _selectedFileName ?? 'يدعم صيغ (PNG, JPG, PDF, XLSX, DOCX)',
                                              style: TextStyle(fontSize: 12, color: AppTheme.charcoal.withOpacity(0.6)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isExtracting ? AppTheme.cobalt.withOpacity(0.7) : AppTheme.cobalt,
                                  foregroundColor: Colors.white,
                                ),
                                icon: _isExtracting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.file_open_rounded, size: 18),
                                label: Text(_isExtracting ? 'جاري تحليل المستند واستخراج البيانات...' : 'اختيار ملف واستخراج البيانات'),
                                onPressed: _isExtracting ? null : _pickAndExtractFile,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Right Pane: Extracted Fields Preview & Edit Form
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الحقول والبيانات المستخرجة للتكويد',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              if (_confidenceScore > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.emerald),
                                  ),
                                  child: Text(
                                    'نسبة الثقة: ${(_confidenceScore * 100).round()}%',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Expanded(
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _companyNameCtrl,
                                    decoration: const InputDecoration(labelText: 'اسم الشركة / المورد *', prefixIcon: Icon(Icons.business_rounded, size: 18)),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _contactPersonCtrl,
                                          decoration: const InputDecoration(labelText: 'المسؤول / المالِك', prefixIcon: Icon(Icons.person_rounded, size: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _countryCtrl,
                                          decoration: const InputDecoration(labelText: 'دولة المنشأ / المقر (Code)', prefixIcon: Icon(Icons.flag_rounded, size: 18)),
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
                                          decoration: const InputDecoration(labelText: 'الهاتف الأرصي / المباشر', prefixIcon: Icon(Icons.phone_rounded, size: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _mobileCtrl,
                                          decoration: const InputDecoration(labelText: 'المحمول (Mobile / WhatsApp)', prefixIcon: Icon(Icons.phone_android_rounded, size: 18)),
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
                                          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_rounded, size: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _websiteCtrl,
                                          decoration: const InputDecoration(labelText: 'الموقع الإلكتروني (Web)', prefixIcon: Icon(Icons.language_rounded, size: 18)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Dynamic Entity-Specific Fields
                                  if (_selectedTarget == EntityTarget.company) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _importerIdCtrl,
                                            decoration: const InputDecoration(labelText: 'كود / بطاقة المستورد *', prefixIcon: Icon(Icons.card_membership_rounded, size: 18)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _commercialRegisterCtrl,
                                            decoration: const InputDecoration(labelText: 'رقم السجل التجاري *', prefixIcon: Icon(Icons.receipt_long_rounded, size: 18)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _taxIdCtrl,
                                            decoration: const InputDecoration(labelText: 'الرقم الضريبي / Tax Card *', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _bankAccountCtrl,
                                            decoration: const InputDecoration(labelText: 'رقم الحساب البنكي / IBAN', prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 18)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ] else if (_selectedTarget == EntityTarget.bank) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _swiftCodeCtrl,
                                            decoration: const InputDecoration(labelText: 'كود السويفت SWIFT Code *', prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _bankAccountCtrl,
                                            decoration: const InputDecoration(labelText: 'رقم الحساب / الآيبان IBAN', prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 18)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ] else if (_selectedTarget == EntityTarget.partner) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SearchableDropdownField<String>(
                                            value: _partnerTypeStr,
                                            labelText: 'نوع الشريك / الخدمة *',
                                            items: const [
                                              SearchableDropdownItem(value: 'Freight Forwarder', label: 'Freight Forwarder (شركة شحن دولي)'),
                                              SearchableDropdownItem(value: 'Customs Broker', label: 'Customs Broker (مخلص جمركي)'),
                                              SearchableDropdownItem(value: 'Shipping Line', label: 'Shipping Line (خط شحن)'),
                                              SearchableDropdownItem(value: 'Inland Transport', label: 'Inland Transport (ناقل داخلي)'),
                                              SearchableDropdownItem(value: 'Inspection Agency', label: 'Inspection Agency (شركة فحص ومعاينة)'),
                                            ],
                                            onChanged: (v) {
                                              if (v != null) setState(() => _partnerTypeStr = v);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _taxIdCtrl,
                                            decoration: const InputDecoration(labelText: 'الرقم الضريبي / السجل', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ] else ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _taxIdCtrl,
                                            decoration: const InputDecoration(labelText: 'الرقم الضريبي / VAT ID / Exporter ID', prefixIcon: Icon(Icons.badge_rounded, size: 18)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _industryCtrl,
                                            decoration: const InputDecoration(labelText: 'نشاط الشركة / التصنيع / البراندات', prefixIcon: Icon(Icons.category_rounded, size: 18)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  TextField(
                                    controller: _addressCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(labelText: 'العنوان التفصيلي ومقر الشركة / المصنع / البنك', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
                                  ),
                                ],
                              ),
                            ),
                            if (_isExtracting)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.88),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: AppTheme.cobalt, strokeWidth: 3),
                                        SizedBox(height: 16),
                                        Text(
                                          '⚡ جاري استخراج وتعبئة الحقول بالذكاء الاصطناعي...',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'سيتم توجيه البيانات المستخرجة إلى حقول التكويد فور الانتهاء',
                                          style: TextStyle(fontSize: 12, color: AppTheme.charcoal),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save_rounded, size: 18),
                                label: Text('حفظ وتكويد كـ ${_targetLabel(_selectedTarget)}'),
                                onPressed: _isSaving ? null : _saveEntityToDatabase,
                              ),
                            ],
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

  Widget _buildTargetChip(EntityTarget target, String label, IconData icon) {
    final isSelected = _selectedTarget == target;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.charcoal),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
      selectedColor: AppTheme.cobalt,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.charcoal),
      onSelected: (sel) {
        if (sel) setState(() => _selectedTarget = target);
      },
    );
  }

  String _targetLabel(EntityTarget target) {
    switch (target) {
      case EntityTarget.supplier:
        return 'مورد أجنبي';
      case EntityTarget.company:
        return 'شركة مستوردة';
      case EntityTarget.partner:
        return 'شريك / مخلص';
      case EntityTarget.bank:
        return 'بنك مصرفي';
    }
  }
}
