import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/import_doc_stepper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';
import 'visual_draft_inspection_sheet.dart';

class InspectionReviewTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  const InspectionReviewTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<InspectionReviewTab> createState() => _InspectionReviewTabState();
}

class _InspectionReviewTabState extends ConsumerState<InspectionReviewTab> {
  int _activeStep = 0; // 0: Requirements, 1: Smart Input, 2: Discrepancy Matrix, 3: Registry
  int? _selectedImportFileId;

  String _inspType = 'COC (Certificate of Conformity)';
  String _inspAgency = 'SGS';
  final TextEditingController _certNumberCtrl = TextEditingController(text: 'DRAFT-COC-SGS-9901');
  final TextEditingController _importerCtrl = TextEditingController();
  final TextEditingController _exporterCtrl = TextEditingController();
  final TextEditingController _authorityCtrl = TextEditingController(text: 'GOEIC (الهيئة العامة للرقابة على الصادرات والواردات)');
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _specCtrl = TextEditingController(text: 'Egyptian Standard ES Egyptian Conformity');
  final TextEditingController _rawTextCtrl = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _comparisonResult;
  String? _pickedFileName;
  Map<String, dynamic>? _activeDraftTemplate;
  String? _activeAcidNumber;
  List<String> _activeStandards = [];

  static const List<ImportDocStep> _steps = [
    ImportDocStep(label: '1. متطلبات شهادة الفحص والمطابقة', icon: Icons.fact_check_outlined),
    ImportDocStep(label: '2. إدخال واستخراج الدرافت', icon: Icons.file_upload),
    ImportDocStep(label: '3. مصفوفة المقارنة والفروق', icon: Icons.rule),
    ImportDocStep(label: '4. سجل شهادات الفحص المعتمدة', icon: Icons.history),
  ];

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    if (_selectedImportFileId != null) {
      _loadSnapshot(_selectedImportFileId!);
    }
  }

  void _loadSnapshot(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    _importerCtrl.text = file.companyName;
    _exporterCtrl.text = file.supplierName;
    _invoiceNoCtrl.text = file.piNumber ?? 'INV-FINAL-${file.importFileCode}';
    _fetchAndApplyDraft(fileId);
  }

  Future<void> _fetchAndApplyDraft(int fileId) async {
    try {
      final res = await ref.read(inspectionReviewsProvider.notifier).fetchInspectionDraftTemplate(
            fileId,
            agency: _inspAgency,
            certType: _inspType,
          );
      final template = res['template_data'] as Map<String, dynamic>? ?? {};
      final standards = (res['applicable_standards'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final files = ref.read(importFilesProvider).value ?? [];
      final file = files.where((f) => f.importFileId == fileId).firstOrNull;

      if (mounted) {
        setState(() {
          _activeDraftTemplate = template;
          _activeAcidNumber = (file?.acidNumber != null && file!.acidNumber!.isNotEmpty)
              ? file.acidNumber
              : (template['acid_number'] ?? '7595528271015010011');
          _activeStandards = standards;

          if (template['coc_number'] != null) _certNumberCtrl.text = template['coc_number'].toString();
          if (template['exporter_name_and_address'] != null) _exporterCtrl.text = template['exporter_name_and_address'].toString();
          if (template['importer_name_and_address'] != null) _importerCtrl.text = template['importer_name_and_address'].toString();
          if (standards.isNotEmpty) _specCtrl.text = standards.join('\n');
        });
      }
    } catch (_) {}
  }

  Future<void> _runComparison() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final draftFields = {
        'inspection_type': _inspType,
        'inspection_agency': _inspAgency,
        'certificate_number': _certNumberCtrl.text.trim(),
        'importer_name': _importerCtrl.text.trim(),
        'exporter_name': _exporterCtrl.text.trim(),
        'regulatory_authority': _authorityCtrl.text.trim(),
        'invoice_number': _invoiceNoCtrl.text.trim(),
        'standard_specification': _specCtrl.text.trim(),
      };

      final res = await ref.read(inspectionReviewsProvider.notifier).compareInspection(
            _selectedImportFileId!,
            _inspType,
            _inspAgency,
            draftFields,
          );

      setState(() {
        _comparisonResult = res;
        _activeStep = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء المقارنة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReview() async {
    if (_comparisonResult == null || _selectedImportFileId == null) return;
    setState(() => _isLoading = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'inspection_type': _inspType,
        'inspection_agency': _inspAgency,
        'certificate_number': _certNumberCtrl.text.trim(),
        'raw_text': _rawTextCtrl.text,
        'system_snapshot_data': _comparisonResult!['system_snapshot_data'],
        'draft_input_data': _comparisonResult!['draft_input_data'],
        'comparison_matrix': _comparisonResult!['comparison_matrix'],
        'has_discrepancies': _comparisonResult!['has_discrepancies'],
        'has_critical_mismatch': _comparisonResult!['has_critical_mismatch'],
        'status': _comparisonResult!['status'],
      };

      await ref.read(inspectionReviewsProvider.notifier).saveInspectionReview(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ تم حفظ جلسة مراجعة شهادة الفحص بنجاح بالسجل'), backgroundColor: Colors.green),
        );
        setState(() => _activeStep = 3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TODO: Implement certificate file picker when upload endpoint is ready
  // Future<void> _pickCertificateFile() async { ... }

  Future<void> _generateOfficialDraft() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً لتوليد درافت شهادة الفحص'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ref.read(inspectionReviewsProvider.notifier).fetchInspectionDraftTemplate(
            _selectedImportFileId!,
            agency: _inspAgency,
            certType: _inspType,
          );

      if (!mounted) return;

      final template = res['template_data'] as Map<String, dynamic>? ?? {};
      final standards = (res['applicable_standards'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final files = ref.read(importFilesProvider).value ?? [];
      final file = files.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
      final acidNo = file?.acidNumber ?? '7595528271015010011';

      setState(() {
        _activeDraftTemplate = template;
        _activeAcidNumber = acidNo;
        _activeStandards = standards;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check, color: AppTheme.cobalt),
                  const SizedBox(width: 8),
                  Text('المعاينة المصورة لمسودة شهادة الفحص: $_inspAgency ($_inspType)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 860,
            child: SingleChildScrollView(
              child: VisualDraftInspectionSheet(
                templateData: template,
                agency: _inspAgency,
                certType: _inspType,
                acidNumber: acidNo,
                standards: standards,
                onRefresh: () => _fetchAndApplyDraft(_selectedImportFileId!),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء وإغلاق ✕', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('اعتماد وتعبئة الحقول تلقائياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  if (template['coc_number'] != null) _certNumberCtrl.text = template['coc_number'].toString();
                  if (template['regulatory_authority'] != null) _authorityCtrl.text = template['regulatory_authority'].toString();
                  if (template['exporter_name_and_address'] != null) _exporterCtrl.text = template['exporter_name_and_address'].toString();
                  if (template['importer_name_and_address'] != null) _importerCtrl.text = template['importer_name_and_address'].toString();
                  if (standards.isNotEmpty) _specCtrl.text = standards.join('\n');
                  _activeStep = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✔ تم ملء بيانات درافت شهادة الفحص بنجاح'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء توليد المسودة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _extractFromOcrText() async {
    final rawText = _rawTextCtrl.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى لصق نص شهادة الفحص أو رفع الملف أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ref.read(inspectionReviewsProvider.notifier).extractCertificate(
            'INSPECTION_VOC',
            rawText,
            importFileId: _selectedImportFileId,
          );

      final extracted = res['extracted_data'] as Map<String, dynamic>? ?? {};
      final isDraft = res['is_draft_detected'] as bool? ?? false;
      final warnings = res['warnings'] as List<dynamic>? ?? [];

      setState(() {
        if (extracted['coc_number'] != null && extracted['coc_number'].toString().isNotEmpty) {
          _certNumberCtrl.text = extracted['coc_number'].toString();
        }
        if (extracted['exporter_name'] != null && extracted['exporter_name'].toString().isNotEmpty) {
          _exporterCtrl.text = extracted['exporter_name'].toString();
        }
        if (extracted['importer_name'] != null && extracted['importer_name'].toString().isNotEmpty) {
          _importerCtrl.text = extracted['importer_name'].toString();
        }
        if (extracted['inspection_agency'] != null && extracted['inspection_agency'].toString().isNotEmpty) {
          _inspAgency = extracted['inspection_agency'].toString();
        }
        if (extracted['testing_standards'] != null && (extracted['testing_standards'] as List).isNotEmpty) {
          _specCtrl.text = (extracted['testing_standards'] as List).join(' + ');
        }
      });

      if (mounted) {
        if (isDraft) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ تم اكتشاف مسودة (DRAFT) - يرجى تأكيد الفحص خلال مهلة الـ 48 ساعة لتفادي رفض الإفراج.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✔ تم استخراج ومطابقة بيانات شهادة الفحص والمطابقة بنجاح'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الاستخراج: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return Column(
      children: [
        // Unified Stepper Navigation
        ImportDocStepper(
          steps: _steps,
          currentStep: _activeStep,
          onStepTapped: (i) => setState(() => _activeStep = i),
        ),
        const Divider(height: 1),

        // Body Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildCurrentStep(importFiles),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(List<dynamic> importFiles) {
    switch (_activeStep) {
      case 0:
        return _buildStep1(importFiles);
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(List<dynamic> importFiles) {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, color: AppTheme.cobalt),
                    SizedBox(width: 10),
                    Text('توليد متطلبات شهادة الفحص المسبق قبل الشحن (Pre-Shipment Inspection / COC)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SearchableDropdownField<int>(
                        value: _selectedImportFileId,
                        labelText: 'اختر ملف الشحنة *',
                        searchHintText: 'ابحث برقم الملف...',
                        items: importFiles
                            .map((f) => SearchableDropdownItem<int>(
                                  value: f.importFileId,
                                  label: '${f.importFileCode} - ${f.companyName}',
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedImportFileId = v);
                            _loadSnapshot(v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<String>(
                        value: _inspType,
                        labelText: 'نوع شهادة الفحص *',
                        searchHintText: 'اختر نوع الفحص...',
                        items: const [
                          SearchableDropdownItem(value: 'COC (Certificate of Conformity)', label: 'شهادة المطابقة النوعية (COC)'),
                          SearchableDropdownItem(value: 'COA (Certificate of Analysis)', label: 'شهادة التحليل المخبري (COA)'),
                          SearchableDropdownItem(value: 'VOC (Verification of Conformity)', label: 'التحقق من المطابقة (VOC)'),
                          SearchableDropdownItem(value: 'PSI (Pre-Shipment Inspection)', label: 'تقرير المعاينة قبل الشحن (PSI)'),
                        ],
                        onChanged: (v) {
                          setState(() => _inspType = v ?? 'COC (Certificate of Conformity)');
                          if (_selectedImportFileId != null) {
                            _fetchAndApplyDraft(_selectedImportFileId!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<String>(
                        value: _inspAgency,
                        labelText: 'شركة / جهة الفحص الدولية *',
                        searchHintText: 'اختر جهة الفحص...',
                        items: const [
                          SearchableDropdownItem(value: 'SGS', label: 'SGS International'),
                          SearchableDropdownItem(value: 'TÜV Rheinland', label: 'TÜV Rheinland'),
                          SearchableDropdownItem(value: 'Bureau Veritas', label: 'Bureau Veritas (BV)'),
                          SearchableDropdownItem(value: 'Intertek', label: 'Intertek Testing Services'),
                          SearchableDropdownItem(value: 'Cotecna', label: 'Cotecna Inspection'),
                        ],
                        onChanged: (v) {
                          setState(() => _inspAgency = v ?? 'SGS');
                          if (_selectedImportFileId != null) {
                            _fetchAndApplyDraft(_selectedImportFileId!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                      icon: const Icon(Icons.bolt, color: Colors.white),
                      label: const Text('⚡ فتح المعاينة والتصدير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _generateOfficialDraft,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: const Text('التالي: إدخال الدرافت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _activeStep = 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_activeDraftTemplate != null) ...[
          const SizedBox(height: 16),
          VisualDraftInspectionSheet(
            templateData: _activeDraftTemplate!,
            agency: _inspAgency,
            certType: _inspType,
            acidNumber: _activeAcidNumber ?? '7595528271015010011',
            standards: _activeStandards,
            onRefresh: () {
              if (_selectedImportFileId != null) {
                _fetchAndApplyDraft(_selectedImportFileId!);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إدخال واستخراج بيانات درافت شهادة الفحص (Inspection Draft Input)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.compare_arrows, color: Colors.white),
                  label: const Text('تشغيل المطابقة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _isLoading ? null : _runComparison,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _certNumberCtrl,
                    decoration: const InputDecoration(labelText: 'رقم درافت الشهادة *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _authorityCtrl,
                    decoration: const InputDecoration(labelText: 'الجهة الرقابية المصرية المختصة *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _invoiceNoCtrl,
                    decoration: const InputDecoration(labelText: 'رقم الفاتورة الخاضعة للفحص *', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _exporterCtrl,
                    decoration: const InputDecoration(labelText: 'اسم المصدر / الشاحن *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _importerCtrl,
                    decoration: const InputDecoration(labelText: 'اسم المستورد / طالب الفحص *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _specCtrl,
                    decoration: const InputDecoration(labelText: 'المواصفة القياسية المعتمدة *', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // File Picker & Smart Upload Row
            Row(
              children: [
                SmartUploadButton(
                  module: SmartUploadModule.inspectionCertificate,
                  label: 'رفع واستخراج شهادة الفحص الذكي (PDF / Word / Excel)',
                  onDataExtracted: (result) {
                    final fields = result.extractedFields;
                    setState(() {
                      _pickedFileName = result.filename;
                      if (fields['certificate_number'] != null && fields['certificate_number'].toString().isNotEmpty) {
                        _certNumberCtrl.text = fields['certificate_number'].toString();
                      }
                      if (fields['inspector_name'] != null && fields['inspector_name'].toString().isNotEmpty) {
                        _authorityCtrl.text = fields['inspector_name'].toString();
                      }
                      if (fields['product_description'] != null && fields['product_description'].toString().isNotEmpty) {
                        _specCtrl.text = fields['product_description'].toString();
                      }
                    });
                  },
                ),
                if (_pickedFileName != null) ...
                  [
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle, color: AppTheme.emerald, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _pickedFileName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('النص الخام لدرافت شهادة الفحص (Raw Text / OCR Dump):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 18),
                  label: const Text('⚡ استخراج ومطابقة ذكية من النص (Smart Extract)', style: TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                  onPressed: _isLoading ? null : _extractFromOcrText,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _rawTextCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'الصق النص الكامل لشهادة الفحص هنا (مثل نصوص Cotecna أو TÜV أو SGS)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    if (_comparisonResult == null) {
      return const Center(child: Text('يرجى تشغيل المقارنة أولاً'));
    }

    final matrix = _comparisonResult!['comparison_matrix'] as List<dynamic>? ?? [];
    final hasCritical = _comparisonResult!['has_critical_mismatch'] as bool? ?? false;
    final hasDisc = _comparisonResult!['has_discrepancies'] as bool? ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(hasCritical ? Icons.error : (hasDisc ? Icons.warning : Icons.check_circle), color: hasCritical ? Colors.red : (hasDisc ? Colors.orange : Colors.green), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      hasCritical ? '🚨 توجد اختلافات حرجة في بيانات شهادة الفحص' : (hasDisc ? '⚠️ توجد فروق طفيفة' : '✔ شهادة الفحص مطابقة 100%'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        side: const BorderSide(color: AppTheme.crimson),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('تصدير PDF', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم تصدير تقرير مطابقة شهادة الفحص قريباً')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.emerald,
                        side: const BorderSide(color: AppTheme.emerald),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.table_chart, size: 16),
                      label: const Text('Excel', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم تصدير تقرير المطابقة إلى Excel قريباً')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('حفظ بالسجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _saveReview,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            DataTable(
              columns: const [
                DataColumn(label: Text('الحقل')),
                DataColumn(label: Text('القيمة بالنظام')),
                DataColumn(label: Text('القيمة بالدرافت')),
                DataColumn(label: Text('حالة التطابق')),
                DataColumn(label: Text('التفاصيل')),
              ],
              rows: matrix.map((m) {
                return DataRow(cells: [
                  DataCell(Text(m['field_label_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(m['system_value']?.toString() ?? '—')),
                  DataCell(Text(m['draft_value']?.toString() ?? '—')),
                  DataCell(
                    Chip(
                      label: Text(m['match_status'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: m['severity'] == 'BLOCKING' ? Colors.red : (m['severity'] == 'WARNING' ? Colors.orange : Colors.green),
                    ),
                  ),
                  DataCell(Text(m['details'] ?? '')),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    final inspReviews = ref.watch(inspectionReviewsProvider);

    return inspReviews.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('خطأ: $e'),
      data: (reviews) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سجل مراجعات شهادات الفحص والمطابقة (Inspection Registry)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                if (reviews.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد مراجعات مسجلة')))
                else
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('كود الجلسة')),
                      DataColumn(label: Text('نوع الفحص')),
                      DataColumn(label: Text('جهة الفحص')),
                      DataColumn(label: Text('رقم الشهادة')),
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('تاريخ الإنشاء')),
                    ],
                    rows: reviews.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.inspectionReviewCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                        DataCell(Text(r.inspectionType)),
                        DataCell(Text(r.inspectionAgency)),
                        DataCell(Text(r.certificateNumber)),
                        DataCell(
                          Chip(
                            label: Text(r.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: r.status == 'Verified' ? Colors.green : Colors.orange,
                          ),
                        ),
                        DataCell(Text(r.createdAt.substring(0, 10))),
                      ]);
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
