import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/import_doc_stepper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';
import '../services/inspection_export_service.dart';
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
  final TextEditingController _authorityCtrl = TextEditingController(text: 'General Organization for Export and Import Control (GOEIC)');
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _acidCtrl = TextEditingController(text: '7595528271015010011');
  final TextEditingController _originCountryCtrl = TextEditingController(text: 'Italy');
  final TextEditingController _specCtrl = TextEditingController(text: 'Egyptian Standard ES / EN 13501-1:2018');
  final TextEditingController _rawTextCtrl = TextEditingController();
  final TextEditingController _overrideReasonCtrl = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(importFilesProvider.notifier).fetchImportFiles();
      await ref.read(inspectionReviewsProvider.notifier).fetchInspectionReviews();
      final files = ref.read(importFilesProvider).value ?? [];
      if (_selectedImportFileId == null && files.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedImportFileId = files.first.importFileId;
          });
        }
      }
      if (_selectedImportFileId != null) {
        _loadSnapshot(_selectedImportFileId!);
      }
    });
  }

  @override
  void dispose() {
    _certNumberCtrl.dispose();
    _importerCtrl.dispose();
    _exporterCtrl.dispose();
    _authorityCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _acidCtrl.dispose();
    _originCountryCtrl.dispose();
    _specCtrl.dispose();
    _rawTextCtrl.dispose();
    _overrideReasonCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InspectionReviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImportFileId != oldWidget.initialImportFileId && widget.initialImportFileId != null) {
      setState(() {
        _selectedImportFileId = widget.initialImportFileId;
      });
      _loadSnapshot(_selectedImportFileId!);
    }
  }

  void _loadSnapshot(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file != null) {
      _importerCtrl.text = file.companyName;
      _exporterCtrl.text = file.supplierName;
      _invoiceNoCtrl.text = file.piNumber ?? 'IT-DN26-003201, IT-DN26-003196, IT-DN26-003401, IT-DN26-003400';
      if (file.acidNumber != null && file.acidNumber!.isNotEmpty) {
        _acidCtrl.text = file.acidNumber!;
      }
    }
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
          if (template['acid_number'] != null) _acidCtrl.text = template['acid_number'].toString();
          if (template['country_of_origin'] != null) _originCountryCtrl.text = template['country_of_origin'].toString();
          if (standards.isNotEmpty) _specCtrl.text = standards.join('\n');
        });
      }
    } catch (_) {}
  }

  /// Normalizes a free-text agency name (e.g. from OCR) to a valid Dropdown value.
  String _normalizeInspAgency(String raw) {
    final r = raw.trim().toLowerCase();
    if (r.contains('tuv') || r.contains('tüv') || r.contains('rheinland')) return 'TÜV Rheinland';
    if (r.contains('bureau') || r.contains('veritas') || r.contains('bv')) return 'Bureau Veritas';
    if (r.contains('intertek')) return 'Intertek';
    if (r.contains('cotecna')) return 'Cotecna';
    if (r.contains('sgs')) return 'SGS';
    return 'SGS'; // fallback
  }

  /// Normalizes a free-text cert type to a valid Dropdown value.
  String _normalizeInspType(String raw) {
    final r = raw.trim().toLowerCase();
    if (r.contains('analysis') || r.contains('coa')) return 'COA (Certificate of Analysis)';
    if (r.contains('verification') || r.contains('voc')) return 'VOC (Verification of Conformity)';
    if (r.contains('pre-shipment') || r.contains('psi')) return 'PSI (Pre-Shipment Inspection)';
    return 'COC (Certificate of Conformity)'; // default
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
        'acid_number': _acidCtrl.text.trim(),
        'country_of_origin': _originCountryCtrl.text.trim(),
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

    final hasDisc = _comparisonResult!['has_discrepancies'] as bool? ?? false;
    final hasCritical = _comparisonResult!['has_critical_mismatch'] as bool? ?? false;
    final reason = _overrideReasonCtrl.text.trim();

    if ((hasDisc || hasCritical) && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يجب كتابة سبب ومبرر الموافقة على الاختلافات قبل الاعتماد والحفظ، أو الضغط على [العودة للتعديل ومخاطبة المورد].'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'inspection_type': _inspType,
        'inspection_agency': _inspAgency,
        'certificate_number': _certNumberCtrl.text.trim().isNotEmpty ? _certNumberCtrl.text.trim() : 'DRAFT-INSP',
        'regulatory_authority': _authorityCtrl.text.trim().isNotEmpty ? _authorityCtrl.text.trim() : 'General Organization for Export and Import Control (GOEIC)',
        'standard_specification': _specCtrl.text.trim(),
        'raw_input_text': _rawTextCtrl.text,
        'raw_text': _rawTextCtrl.text,
        'system_snapshot_data': _comparisonResult!['system_snapshot_data'],
        'draft_input_data': _comparisonResult!['draft_input_data'],
        'comparison_matrix': _comparisonResult!['comparison_matrix'],
        'has_discrepancies': hasDisc,
        'has_critical_mismatch': hasCritical,
        'override_reason': reason,
        'status': hasDisc ? (hasCritical ? 'Correction Requested' : 'Discrepancy_Accepted') : 'Verified',
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
        } else if (extracted['certificate_number'] != null && extracted['certificate_number'].toString().isNotEmpty) {
          _certNumberCtrl.text = extracted['certificate_number'].toString();
        }
        if (extracted['exporter_name'] != null && extracted['exporter_name'].toString().isNotEmpty) {
          _exporterCtrl.text = extracted['exporter_name'].toString();
        }
        if (extracted['importer_name'] != null && extracted['importer_name'].toString().isNotEmpty) {
          _importerCtrl.text = extracted['importer_name'].toString();
        }
        if (extracted['invoice_number'] != null && extracted['invoice_number'].toString().isNotEmpty) {
          _invoiceNoCtrl.text = extracted['invoice_number'].toString();
        } else if (extracted['invoices'] != null && (extracted['invoices'] as List).isNotEmpty) {
          final invList = (extracted['invoices'] as List)
              .map((i) => i is Map ? (i['invoice_number'] ?? '').toString() : i.toString())
              .where((s) => s.isNotEmpty)
              .toList();
          if (invList.isNotEmpty) _invoiceNoCtrl.text = invList.join(', ');
        }
        if (extracted['regulatory_authority'] != null && extracted['regulatory_authority'].toString().isNotEmpty) {
          _authorityCtrl.text = extracted['regulatory_authority'].toString();
        }
        if (extracted['inspection_agency'] != null && extracted['inspection_agency'].toString().isNotEmpty) {
          _inspAgency = _normalizeInspAgency(extracted['inspection_agency'].toString());
        }
        if (extracted['certificate_type'] != null && extracted['certificate_type'].toString().isNotEmpty) {
          _inspType = _normalizeInspType(extracted['certificate_type'].toString());
        } else if (extracted['inspection_type'] != null && extracted['inspection_type'].toString().isNotEmpty) {
          _inspType = _normalizeInspType(extracted['inspection_type'].toString());
        }
        if (extracted['acid_number'] != null && extracted['acid_number'].toString().isNotEmpty) {
          _acidCtrl.text = extracted['acid_number'].toString();
        }
        if (extracted['country_of_origin'] != null && extracted['country_of_origin'].toString().isNotEmpty) {
          _originCountryCtrl.text = extracted['country_of_origin'].toString();
        } else if (extracted['origin_country'] != null && extracted['origin_country'].toString().isNotEmpty) {
          _originCountryCtrl.text = extracted['origin_country'].toString();
        }
        if (extracted['testing_standards'] != null && (extracted['testing_standards'] as List).isNotEmpty) {
          _specCtrl.text = (extracted['testing_standards'] as List).join(' + ');
        } else if (extracted['standards_tested'] != null && (extracted['standards_tested'] as List).isNotEmpty) {
          _specCtrl.text = (extracted['standards_tested'] as List).join(' + ');
        }
      });

      if (mounted) {
        if (warnings.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ تنبيهات الاستخراج: ${warnings.join(", ")}'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (isDraft) {
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
        return _buildStep2(importFiles);
      case 2:
        return _buildStep3(importFiles);
      case 3:
        return _buildStep4(importFiles);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(List<dynamic> importFiles) {
    final existingReviews = ref.watch(inspectionReviewsProvider).value ?? [];
    final existingReview = existingReviews.where((r) => r.importFileId == _selectedImportFileId).firstOrNull;

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
                if (existingReview != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.cobalt, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ℹ️ توجد دراسة مسجلة مسبقاً لهذا الملف [كود الجلسة: ${existingReview.inspectionReviewCode} - الحالة: ${existingReview.status}]. سيتم تحديث وتعديل نفس الدراسة المعتمدة لضمان عدم تكرار السجلات.',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          icon: const Icon(Icons.history, color: Colors.white, size: 14),
                          label: const Text('سجل الشهادات', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _activeStep = 3),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildStep2(List<dynamic> importFiles) {
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
                  onPressed: (_isLoading || _selectedImportFileId == null) ? null : _runComparison,
                ),
              ],
            ),
            const Divider(height: 24),
            // Mandatory Import File Selector Row
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SearchableDropdownField<int>(
                    value: _selectedImportFileId,
                    labelText: 'اختر ملف الشحنة المربوط *',
                    searchHintText: 'ابحث برقم الملف أو اسم الشركة...',
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
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: SearchableDropdownField<String>(
                    value: _inspAgency,
                    labelText: 'جهة الفحص الدولية *',
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
                    },
                  ),
                ),
              ],
            ),
            if (_selectedImportFileId == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ يرجى اختيار وتحديد ملف الشحنة أولاً حتى يتم استخراج البيانات ومقارنتها بسجلات النظام.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _acidCtrl,
                    decoration: const InputDecoration(labelText: 'رقم القيد الجمركي المسبق (ACID Number) *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _originCountryCtrl,
                    decoration: const InputDecoration(labelText: 'بلد المنشأ (Country of Origin) *', border: OutlineInputBorder()),
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
                      if (fields['importer_name'] != null && fields['importer_name'].toString().isNotEmpty) {
                        _importerCtrl.text = fields['importer_name'].toString();
                      }
                      if (fields['exporter_name'] != null && fields['exporter_name'].toString().isNotEmpty) {
                        _exporterCtrl.text = fields['exporter_name'].toString();
                      }
                      if (fields['acid_number'] != null && fields['acid_number'].toString().isNotEmpty) {
                        _acidCtrl.text = fields['acid_number'].toString();
                      }
                      if (fields['country_of_origin'] != null && fields['country_of_origin'].toString().isNotEmpty) {
                        _originCountryCtrl.text = fields['country_of_origin'].toString();
                      } else if (fields['origin_country'] != null && fields['origin_country'].toString().isNotEmpty) {
                        _originCountryCtrl.text = fields['origin_country'].toString();
                      }
                      if (fields['invoice_number'] != null && fields['invoice_number'].toString().isNotEmpty) {
                        _invoiceNoCtrl.text = fields['invoice_number'].toString();
                      }
                      if (fields['inspection_agency'] != null && fields['inspection_agency'].toString().isNotEmpty) {
                        _inspAgency = _normalizeInspAgency(fields['inspection_agency'].toString());
                      }
                      if (fields['regulatory_authority'] != null && fields['regulatory_authority'].toString().isNotEmpty) {
                        _authorityCtrl.text = fields['regulatory_authority'].toString();
                      } else if (fields['inspector_name'] != null && fields['inspector_name'].toString().isNotEmpty) {
                        _authorityCtrl.text = fields['inspector_name'].toString();
                      }
                      if (fields['standard_specification'] != null && fields['standard_specification'].toString().isNotEmpty) {
                        _specCtrl.text = fields['standard_specification'].toString();
                      } else if (fields['standards'] != null && (fields['standards'] as List).isNotEmpty) {
                        _specCtrl.text = (fields['standards'] as List).join(' + ');
                      } else if (fields['product_description'] != null && fields['product_description'].toString().isNotEmpty) {
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('النص الخام لدرافت شهادة الفحص (Raw Text / OCR Dump):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 18),
                  label: const Text('⚡ استخراج ومطابقة ذكية من النص (Smart Extract)', style: TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                  onPressed: (_isLoading || _selectedImportFileId == null) ? null : _extractFromOcrText,
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

  Widget _buildStep3(List<dynamic> importFiles) {
    if (_selectedImportFileId == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.folder_off, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              const Text('⚠️ يجب اختيار ملف الشحنة أولاً لعرض مصفوفة المقارنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('العودة لاختيار الملف', style: TextStyle(color: Colors.white)),
                onPressed: () => setState(() => _activeStep = 1),
              ),
            ],
          ),
        ),
      );
    }

    if (_comparisonResult == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.compare_arrows, size: 48, color: AppTheme.cobalt),
              const SizedBox(height: 12),
              const Text('يرجى تشغيل المطابقة في الخطوة السابقة لاستعراض مصفوفة الفروق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('العودة لتشغيل المطابقة', style: TextStyle(color: Colors.white)),
                onPressed: () => setState(() => _activeStep = 1),
              ),
            ],
          ),
        ),
      );
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
                        if (_selectedImportFileId != null && _activeDraftTemplate != null) {
                          InspectionExportService.printOrSavePdf(
                            templateData: _activeDraftTemplate!,
                            agency: _inspAgency,
                            certType: _inspType,
                            acidNumber: _activeAcidNumber ?? '7595528271015010011',
                            standards: _activeStandards,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('جارٍ تصدير تقرير مطابقة شهادة الفحص...')),
                          );
                        }
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
                        if (_activeDraftTemplate != null) {
                          final csv = InspectionExportService.exportInspectionCsv(
                            templateData: _activeDraftTemplate!,
                            agency: _inspAgency,
                            certType: _inspType,
                            acidNumber: _activeAcidNumber ?? '7595528271015010011',
                            standards: _activeStandards,
                          );
                          Clipboard.setData(ClipboardData(text: csv));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📊 تم نسخ وتصدير بيانات المطابقة إلى Excel بنجاح'), backgroundColor: Colors.green),
                          );
                        }
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
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
            ),
            if (hasDisc || hasCritical) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سبب ومبررات الموافقة على الاختلافات (إلزامي للاعتماد والحفظ):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عند وجود فروق أو اختلافات في شهادة الفحص والمطابقة، يجب تسجيل سبب الموافقة والاعتماد (مثال: اعتماد المعمل المرجعي / استثناء الفحص الظاهري)، أو الضغط على العودة للتعديل ومخاطبة المورد.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _overrideReasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'سبب ومبرر الموافقة على الاختلافات (Approval Justification) *',
                        hintText: 'اكتب مبررات قبول الاختلافات هنا قبل الحفظ...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _overrideReasonCtrl.text.trim().isNotEmpty ? AppTheme.emerald : Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          label: const Text('✔ اعتماد وحفظ مع ذكر سبب الموافقة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _saveReview,
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.crimson,
                            side: const BorderSide(color: AppTheme.crimson),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('↩ العودة لتعديل المسودة ومخاطبة المورد', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _activeStep = 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep4(List<dynamic> importFiles) {
    final reviewsState = ref.watch(inspectionReviewsProvider);

    return reviewsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ في جلب السجلات: $err')),
      data: (reviews) {
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
                        const Icon(Icons.history_edu, color: AppTheme.cobalt, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'سجل مراجعات واعتماد شهادات الفحص والتفتيش (${reviews.length} جلسة)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: const Text('بدء مراجعة جديدة', style: TextStyle(color: Colors.white)),
                      onPressed: () => setState(() => _activeStep = 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (reviews.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('لا توجد جلسات مراجعة مسجلة لشهادات الفحص حتى الآن.')),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.06)),
                      columns: const [
                        DataColumn(label: Text('كود الجلسة')),
                        DataColumn(label: Text('نوع الفحص')),
                        DataColumn(label: Text('جهة الفحص')),
                        DataColumn(label: Text('رقم الشهادة')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('تاريخ الإنشاء')),
                        DataColumn(label: Text('الإجراءات')),
                      ],
                      rows: reviews.map((r) {
                        final rawTxt = r.rawText ?? r.draftInputData?['raw_text'] ?? '';
                        final overrideReason = r.notes ?? r.draftInputData?['override_reason'] ?? '';

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
                          DataCell(Text(r.createdAt.length >= 10 ? r.createdAt.substring(0, 10) : r.createdAt)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. Edit (تعديل)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                                  tooltip: 'تعديل الجلسة',
                                  onPressed: () {
                                    setState(() {
                                      _selectedImportFileId = r.importFileId;
                                      _inspType = r.inspectionType;
                                      _inspAgency = r.inspectionAgency;
                                      _certNumberCtrl.text = r.certificateNumber;
                                      _rawTextCtrl.text = rawTxt;
                                      _overrideReasonCtrl.text = overrideReason;
                                      if (r.comparisonMatrix.isNotEmpty) {
                                        _comparisonResult = {
                                          'comparison_matrix': r.comparisonMatrix,
                                          'has_discrepancies': r.hasDiscrepancies,
                                          'has_critical_mismatch': r.hasCriticalMismatch,
                                          'system_snapshot_data': r.systemSnapshotData,
                                          'draft_input_data': r.draftInputData,
                                        };
                                      }
                                      _activeStep = 1;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم تحميل بيانات الجلسة (${r.inspectionReviewCode}) للتعديل')),
                                    );
                                  },
                                ),
                                // 2. View (مشاهدة)
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: AppTheme.charcoal, size: 18),
                                  tooltip: 'معاينة التفاصيل',
                                  onPressed: () => _showInspectionReviewDetailsDialog(r),
                                ),
                                // 3. Download PDF (تنزيل PDF)
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: AppTheme.crimson, size: 18),
                                  tooltip: 'تنزيل PDF',
                                  onPressed: () async {
                                    final tData = {
                                      'certificate_number': r.certificateNumber,
                                      'inspection_agency': r.inspectionAgency,
                                      'inspection_type': r.inspectionType,
                                      ...?r.draftInputData,
                                    };
                                    await InspectionExportService.printOrSavePdf(
                                      templateData: tData,
                                      agency: r.inspectionAgency,
                                      certType: r.inspectionType,
                                      acidNumber: '7595528271015010011',
                                      standards: _activeStandards,
                                    );
                                  },
                                ),
                                // 4. Delete (حذف)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  tooltip: 'حذف الجلسة',
                                  onPressed: () => _confirmDeleteInspectionReview(r),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInspectionReviewDetailsDialog(InspectionCertificateReviewModel r) {
    final overrideReason = r.notes ?? r.draftInputData?['override_reason'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text('تفاصيل جلسة مراجعة شهادة الفحص: ${r.inspectionReviewCode}'),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('نوع الفحص والجهة المصدرة'),
                  subtitle: Text('${r.inspectionType} — جهة الفحص: ${r.inspectionAgency}'),
                  dense: true,
                ),
                ListTile(
                  title: const Text('رقم الشهادة والحالة'),
                  subtitle: Text('رقم الشهادة: ${r.certificateNumber} | الحالة: ${r.status}'),
                  dense: true,
                ),
                if (overrideReason.isNotEmpty)
                  ListTile(
                    title: const Text('سبب ومبرر الموافقة على الاختلافات'),
                    subtitle: Text(overrideReason, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    dense: true,
                  ),
                if (r.comparisonMatrix.isNotEmpty) ...[
                  const Divider(),
                  const Text('مصفوفة الفروق والمطابقة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...r.comparisonMatrix.map((m) {
                    final item = m is Map ? m : {};
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(item['match_status'] == 'MATCH' ? Icons.check_circle : Icons.warning,
                              color: item['match_status'] == 'MATCH' ? Colors.green : Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${item['field_label_ar'] ?? item['field']}: [درافت: ${item['draft_value']}] vs [نظام: ${item['system_value']}]',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteInspectionReview(InspectionCertificateReviewModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد حذف جلسة مراجعة الفحص'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف جلسة المراجعة رقم (${r.inspectionReviewCode}) لشهادة (${r.certificateNumber})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(inspectionReviewsProvider.notifier).deleteInspectionReview(r.inspectionReviewId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✔ تم حذف جلسة مراجعة الفحص بنجاح'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
