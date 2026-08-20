import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/import_doc_stepper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';
import 'visual_draft_coo_sheet.dart';

class COOReviewTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  const COOReviewTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<COOReviewTab> createState() => _COOReviewTabState();
}

class _COOReviewTabState extends ConsumerState<COOReviewTab> {
  int _activeStep = 0; // 0: Requirements, 1: Smart Input, 2: Discrepancy Matrix, 3: Registry
  int? _selectedImportFileId;

  String _certType = 'EUR.1';
  final TextEditingController _certNumberCtrl = TextEditingController(text: 'DRAFT-EUR1-001');
  final TextEditingController _exporterCtrl = TextEditingController();
  final TextEditingController _importerCtrl = TextEditingController();
  final TextEditingController _originCountryCtrl = TextEditingController(text: 'Germany');
  final TextEditingController _destCountryCtrl = TextEditingController(text: 'Egypt');
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _rawTextCtrl = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _comparisonResult;
  String? _pickedFileName;
  Map<String, dynamic>? _activeDraftTemplate;
  String? _activeAcidNumber;
  String? _activeExemptionNotes;
  bool _showVisualDraftSheet = true;

  static const List<ImportDocStep> _steps = [
    ImportDocStep(label: '1. متطلبات شهادة المنشأ / EUR.1', icon: Icons.description),
    ImportDocStep(label: '2. إدخال واستخراج الدرافت', icon: Icons.file_upload),
    ImportDocStep(label: '3. مصفوفة المقارنة والفروق', icon: Icons.fact_check),
    ImportDocStep(label: '4. سجل مراجعات المنشأ', icon: Icons.history_edu),
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
      final res = await ref.read(cooReviewsProvider.notifier).fetchCooDraftTemplate(
            fileId,
            certType: _certType,
          );
      final template = res['template_data'] as Map<String, dynamic>? ?? {};
      final files = ref.read(importFilesProvider).value ?? [];
      final file = files.where((f) => f.importFileId == fileId).firstOrNull;

      if (mounted) {
        setState(() {
          _activeDraftTemplate = template;
          _activeAcidNumber = (file?.acidNumber != null && file!.acidNumber!.isNotEmpty)
              ? file.acidNumber
              : (template['box_7_description_and_acid'] ?? template['box_10_invoices_and_acid'] ?? '7595528271020210010');
          _activeExemptionNotes = res['exemption_notes']?.toString();

          if (template['certificate_number'] != null) _certNumberCtrl.text = template['certificate_number'].toString();
          if (template['country_of_origin'] != null) _originCountryCtrl.text = template['country_of_origin'].toString();
          if (template['box_1_exporter'] != null) _exporterCtrl.text = template['box_1_exporter'].toString();
          if (template['box_2_consignee'] != null) _importerCtrl.text = template['box_2_consignee'].toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _generateOfficialDraft() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً لتوليد المسودة'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ref.read(cooReviewsProvider.notifier).fetchCooDraftTemplate(
            _selectedImportFileId!,
            certType: _certType,
          );

      if (!mounted) return;

      final preview = res['preview_markdown']?.toString() ?? '';
      final template = res['template_data'] as Map<String, dynamic>? ?? {};
      final exemption = res['exemption_notes']?.toString() ?? '';
      final files = ref.read(importFilesProvider).value ?? [];
      final file = files.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
      final acidNo = file?.acidNumber ?? '7595528271020210010';

      setState(() {
        _activeDraftTemplate = template;
        _activeAcidNumber = acidNo;
        _activeExemptionNotes = exemption;
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
                  const Icon(Icons.verified, color: AppTheme.cobalt),
                  const SizedBox(width: 8),
                  Text('المعاينة المصورة لمسودة شهادة المنشأ الرسمية: ${res['certificate_type'] ?? _certType}',
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
              child: VisualDraftCOOSheet(
                templateData: template,
                certificateType: res['certificate_type'] ?? _certType,
                acidNumber: acidNo,
                exemptionNotes: exemption,
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
                  if (template['certificate_number'] != null) _certNumberCtrl.text = template['certificate_number'].toString();
                  if (template['country_of_origin'] != null) _originCountryCtrl.text = template['country_of_origin'].toString();
                  if (template['destination_country'] != null) _destCountryCtrl.text = template['destination_country'].toString();
                  if (template['box_1_exporter'] != null) _exporterCtrl.text = template['box_1_exporter'].toString();
                  if (template['box_2_consignee'] != null) _importerCtrl.text = template['box_2_consignee'].toString();
                  _rawTextCtrl.text = preview;
                  _activeStep = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✔ تم ملء بيانات المسودة الرسمية بنجاح'), backgroundColor: Colors.green),
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
        const SnackBar(content: Text('يرجى لصق نص الشهادة أو رفع الملف أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docTypeKey = _certType.contains('China') ? 'CHINA_COO' : 'EUR1';
      final res = await ref.read(cooReviewsProvider.notifier).extractCertificate(
            docTypeKey,
            rawText,
            importFileId: _selectedImportFileId,
          );

      final extracted = res['extracted_data'] as Map<String, dynamic>? ?? {};
      final warnings = res['warnings'] as List<dynamic>? ?? [];

      setState(() {
        if (extracted['certificate_number'] != null && extracted['certificate_number'].toString().isNotEmpty) {
          _certNumberCtrl.text = extracted['certificate_number'].toString();
        }
        if (extracted['country_of_origin'] != null && extracted['country_of_origin'].toString().isNotEmpty) {
          _originCountryCtrl.text = extracted['country_of_origin'].toString();
        }
        if (extracted['destination_country'] != null && extracted['destination_country'].toString().isNotEmpty) {
          _destCountryCtrl.text = extracted['destination_country'].toString();
        }
        if (extracted['exporter_name'] != null && extracted['exporter_name'].toString().isNotEmpty) {
          _exporterCtrl.text = extracted['exporter_name'].toString();
        }
        if (extracted['importer_name'] != null && extracted['importer_name'].toString().isNotEmpty) {
          _importerCtrl.text = extracted['importer_name'].toString();
        }
        if (extracted['invoice_number'] != null && extracted['invoice_number'].toString().isNotEmpty) {
          _invoiceNoCtrl.text = extracted['invoice_number'].toString();
        }
      });

      if (mounted) {
        if (warnings.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(warnings.join('\n')), backgroundColor: Colors.orange, duration: const Duration(seconds: 4)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✔ تم استخراج ومطابقة بيانات الشهادة بالذكاء الاصطناعي بنجاح'), backgroundColor: Colors.green),
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
        'certificate_type': _certType,
        'certificate_number': _certNumberCtrl.text.trim(),
        'exporter_name': _exporterCtrl.text.trim(),
        'importer_name': _importerCtrl.text.trim(),
        'country_of_origin': _originCountryCtrl.text.trim(),
        'destination_country': _destCountryCtrl.text.trim(),
        'invoice_number': _invoiceNoCtrl.text.trim(),
      };

      final res = await ref.read(cooReviewsProvider.notifier).compareCOO(
            _selectedImportFileId!,
            _certType,
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
        'certificate_type': _certType,
        'certificate_number': _certNumberCtrl.text.trim(),
        'raw_text': _rawTextCtrl.text,
        'system_snapshot_data': _comparisonResult!['system_snapshot_data'],
        'draft_input_data': _comparisonResult!['draft_input_data'],
        'comparison_matrix': _comparisonResult!['comparison_matrix'],
        'has_discrepancies': _comparisonResult!['has_discrepancies'],
        'has_critical_mismatch': _comparisonResult!['has_critical_mismatch'],
        'status': _comparisonResult!['status'],
      };

      await ref.read(cooReviewsProvider.notifier).saveCOOReview(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ تم حفظ جلسة مراجعة شهادة المنشأ بنجاح بالسجل'), backgroundColor: Colors.green),
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
                    Icon(Icons.flag, color: AppTheme.cobalt),
                    SizedBox(width: 10),
                    Text('توليد واستدعاء مسودة شهادة المنشأ الرسمية (EUR.1 / China CCPIT / General COO)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      flex: 3,
                      child: SearchableDropdownField<String>(
                        value: _certType,
                        labelText: 'نوع شهادة المنشأ *',
                        searchHintText: 'اختر نوع الشهادة...',
                        items: const [
                          SearchableDropdownItem(value: 'EUR.1', label: 'EUR.1 (الاتفاقية المصرية الأوروبية - قواعد معدلة)'),
                          SearchableDropdownItem(value: 'China Certificate of Origin (CCPIT)', label: 'شهادة منشأ الصين (CCPIT / China-Egypt)'),
                          SearchableDropdownItem(value: 'Standard COO', label: 'Standard Certificate of Origin (شهادة منشأ عادية)'),
                          SearchableDropdownItem(value: 'Form A / GSP', label: 'Form A / Generalized System of Preferences'),
                          SearchableDropdownItem(value: 'Agadir Agreement', label: 'شهادة اتفاقية أغادير'),
                          SearchableDropdownItem(value: 'GAFTA', label: 'شهادة منطقة التجارة الحرة العربية الكبرى'),
                        ],
                        onChanged: (v) {
                          setState(() => _certType = v ?? 'EUR.1');
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
                      label: const Text('⚡ فتح المعاينة المصورة والتصدير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          VisualDraftCOOSheet(
            templateData: _activeDraftTemplate!,
            certificateType: _certType,
            acidNumber: _activeAcidNumber ?? '7595528271020210010',
            exemptionNotes: _activeExemptionNotes,
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
                const Text('إدخال واستخراج بيانات درافت شهادة المنشأ (COO Draft Input)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.compare_arrows, color: Colors.white),
                  label: const Text('تشغيل المقارنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    controller: _originCountryCtrl,
                    decoration: const InputDecoration(labelText: 'بلد المنشأ (Country of Origin) *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _destCountryCtrl,
                    decoration: const InputDecoration(labelText: 'بلد المقصد (Destination) *', border: OutlineInputBorder()),
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
                    decoration: const InputDecoration(labelText: 'اسم المستورد / المرسل إليه *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _invoiceNoCtrl,
                    decoration: const InputDecoration(labelText: 'رقم الفاتورة التجارية المذكورة *', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // File Picker & Smart Upload Row
            Row(
              children: [
                SmartUploadButton(
                  module: SmartUploadModule.cooCertificate,
                  label: 'رفع واستخراج شهادة المنشأ الذكي (PDF / Word / Excel)',
                  onDataExtracted: (result) {
                    final fields = result.extractedFields;
                    setState(() {
                      _pickedFileName = result.filename;
                      if (fields['certificate_number'] != null && fields['certificate_number'].toString().isNotEmpty) {
                        _certNumberCtrl.text = fields['certificate_number'].toString();
                      }
                      if (fields['origin_country'] != null && fields['origin_country'].toString().isNotEmpty) {
                        _originCountryCtrl.text = fields['origin_country'].toString();
                      }
                      if (fields['exporter_name'] != null && fields['exporter_name'].toString().isNotEmpty) {
                        _exporterCtrl.text = fields['exporter_name'].toString();
                      }
                      if (fields['consignee_name'] != null && fields['consignee_name'].toString().isNotEmpty) {
                        _importerCtrl.text = fields['consignee_name'].toString();
                      }
                      if (fields['invoice_number'] != null && fields['invoice_number'].toString().isNotEmpty) {
                        _invoiceNoCtrl.text = fields['invoice_number'].toString();
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
                const Text('النص الخام لدرافت شهادة المنشأ (Raw Text / OCR):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 18),
                  label: const Text('⚡ استخراج وتعبئة ذكية من النص (Smart Extract)', style: TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                  onPressed: _isLoading ? null : _extractFromOcrText,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _rawTextCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'الصق النص الكامل للشهادة هنا (مثل نصوص CCPIT أو EUR.1)...',
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
                      hasCritical ? '🚨 توجد اختلافات حرجة في بيانات شهادة المنشأ' : (hasDisc ? '⚠️ توجد فروق طفيفة' : '✔ شهادة المنشأ مطابقة 100%'),
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
                          const SnackBar(content: Text('سيتم تصدير تقرير مطابقة شهادة المنشأ قريباً')),
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
    final cooReviews = ref.watch(cooReviewsProvider);

    return cooReviews.when(
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
                const Text('سجل مراجعات شهادات المنشأ واليورو 1 (COO Review Registry)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                if (reviews.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد مراجعات مسجلة')))
                else
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('كود الجلسة')),
                      DataColumn(label: Text('النوع')),
                      DataColumn(label: Text('رقم الشهادة')),
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('تاريخ الإنشاء')),
                    ],
                    rows: reviews.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.cooReviewCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                        DataCell(Text(r.certificateType)),
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
