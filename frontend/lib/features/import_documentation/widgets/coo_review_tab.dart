import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/import_doc_stepper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';
import '../services/coo_export_service.dart';
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
  final TextEditingController _exporterRegIdCtrl = TextEditingController();
  final TextEditingController _importerCtrl = TextEditingController();
  final TextEditingController _originCountryCtrl = TextEditingController(text: 'Germany');
  final TextEditingController _destCountryCtrl = TextEditingController(text: 'Egypt');
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _rawTextCtrl = TextEditingController();
  final TextEditingController _overrideReasonCtrl = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _comparisonResult;
  String? _pickedFileName;
  Map<String, dynamic>? _activeDraftTemplate;
  String? _activeAcidNumber;
  String? _activeExemptionNotes;
  String? _recommendationAlert;
  bool _isManualChoiceRequired = false;
  List<String> _allowedCertTypes = [];

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(importFilesProvider.notifier).fetchImportFiles();
      await ref.read(cooReviewsProvider.notifier).fetchCOOReviews();
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
  void didUpdateWidget(covariant COOReviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImportFileId != oldWidget.initialImportFileId && widget.initialImportFileId != null) {
      setState(() {
        _selectedImportFileId = widget.initialImportFileId;
      });
      _loadSnapshot(_selectedImportFileId!);
    }
  }

  @override
  void dispose() {
    _certNumberCtrl.dispose();
    _exporterCtrl.dispose();
    _exporterRegIdCtrl.dispose();
    _importerCtrl.dispose();
    _originCountryCtrl.dispose();
    _destCountryCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _rawTextCtrl.dispose();
    _overrideReasonCtrl.dispose();
    super.dispose();
  }

  void _loadSnapshot(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file != null) {
      _importerCtrl.text = file.companyName;
      _exporterCtrl.text = file.supplierName;
      _invoiceNoCtrl.text = file.piNumber ?? 'INV-FINAL-${file.importFileCode}';
    }
    _fetchAndApplyDraft(fileId);
  }

  Future<void> _fetchAndApplyDraft(int fileId, {String? overrideCertType}) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(cooReviewsProvider.notifier).fetchCooDraftTemplate(
            fileId,
            certType: overrideCertType,
          );
      final template = res['template_data'] as Map<String, dynamic>? ?? {};
      final files = ref.read(importFilesProvider).value ?? [];
      final file = files.where((f) => f.importFileId == fileId).firstOrNull;
      final recType = res['recommended_certificate_type']?.toString();
      final retCertType = (res['certificate_type'] ?? template['certificate_type'] ?? recType)?.toString();
      final allowed = (res['allowed_certificate_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final alertMsg = res['recommendation_alert']?.toString();
      final manualReq = res['is_manual_choice_required'] == true;

      if (mounted) {
        setState(() {
          if (overrideCertType != null) {
            _certType = overrideCertType;
          } else if (retCertType != null && retCertType.isNotEmpty) {
            _certType = retCertType;
          } else if (recType != null && recType.isNotEmpty) {
            _certType = recType;
          }
          _recommendationAlert = alertMsg;
          _isManualChoiceRequired = manualReq;
          _allowedCertTypes = allowed;
          _activeDraftTemplate = template;
          _activeAcidNumber = (file?.acidNumber != null && file!.acidNumber!.isNotEmpty)
              ? file.acidNumber
              : '5281534391023010013';
          _activeExemptionNotes = res['exemption_notes']?.toString();

          if (template['certificate_number'] != null) _certNumberCtrl.text = template['certificate_number'].toString();
          if (template['country_of_origin'] != null) _originCountryCtrl.text = template['country_of_origin'].toString();
          if (template['box_1_exporter'] != null) _exporterCtrl.text = template['box_1_exporter'].toString();
          if (template['box_2_consignee'] != null) _importerCtrl.text = template['box_2_consignee'].toString();
        });
      }
    } catch (e) {
      debugPrint('Error fetching COO template: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateOfficialDraft() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cooSelectFileFirstForComparison), backgroundColor: Colors.red),
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
                  Text(context.l10n.cooVisualPreviewTitle(res['certificate_type'] ?? _certType),
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
              child: Text(context.l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(context.l10n.cooAutoFillFieldsButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  SnackBar(content: Text(context.l10n.cooDraftFilledSuccess), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cooGenerateDraftError(e.toString())), backgroundColor: Colors.red),
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
        SnackBar(content: Text(context.l10n.cooPasteTextOrUploadWarning), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docTypeKey = _certType.contains('China') ? 'CHINA_COO' : (_certType.contains('EUR') ? 'EUR1' : 'STANDARD_COO');
      final res = await ref.read(cooReviewsProvider.notifier).extractCertificate(
            docTypeKey,
            rawText,
            importFileId: _selectedImportFileId,
          );

      final extracted = res['extracted_data'] as Map<String, dynamic>? ?? {};
      final warnings = res['warnings'] as List<dynamic>? ?? [];

      setState(() {
        _certNumberCtrl.text = extracted['certificate_number']?.toString() ?? '';
        _originCountryCtrl.text = extracted['country_of_origin']?.toString() ?? extracted['origin_country']?.toString() ?? '';
        _destCountryCtrl.text = extracted['destination_country']?.toString() ?? 'Egypt';
        _exporterCtrl.text = extracted['exporter_name']?.toString() ?? '';
        _exporterRegIdCtrl.text = extracted['exporter_reg_id']?.toString() ?? '';
        _importerCtrl.text = extracted['importer_name']?.toString() ?? extracted['consignee_name']?.toString() ?? '';
        _invoiceNoCtrl.text = extracted['invoice_number']?.toString() ?? '';
      });

      if (mounted) {
        if (warnings.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(warnings.join('\n')), backgroundColor: Colors.orange, duration: const Duration(seconds: 4)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.cooAiExtractSuccess), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cooExtractError(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runComparison() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cooSelectFileFirstForComparison), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final draftFields = {
        'certificate_type': _certType,
        'certificate_number': _certNumberCtrl.text.trim(),
        'exporter_name': _exporterCtrl.text.trim(),
        'exporter_reg_id': _exporterRegIdCtrl.text.trim(),
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
          SnackBar(content: Text(context.l10n.cooComparisonError(e.toString())), backgroundColor: Colors.red),
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
        SnackBar(
          content: Text(context.l10n.cooMustProvideJustificationSnackbar),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snap = _comparisonResult!['system_snapshot_data'] as Map<String, dynamic>? ?? {};
      final draft = _comparisonResult!['draft_input_data'] as Map<String, dynamic>? ?? {};

      final expName = _exporterCtrl.text.trim().isNotEmpty
          ? _exporterCtrl.text.trim()
          : (draft['exporter_name'] ?? snap['exporter_name'] ?? 'Exporter');
      final impName = _importerCtrl.text.trim().isNotEmpty
          ? _importerCtrl.text.trim()
          : (draft['importer_name'] ?? snap['importer_name'] ?? 'Importer');
      final originCountry = _originCountryCtrl.text.trim().isNotEmpty
          ? _originCountryCtrl.text.trim()
          : (draft['country_of_origin'] ?? snap['country_of_origin'] ?? 'China');
      final destCountry = _destCountryCtrl.text.trim().isNotEmpty
          ? _destCountryCtrl.text.trim()
          : 'Egypt';

      final payload = {
        'import_file_id': _selectedImportFileId,
        'certificate_type': _certType,
        'certificate_number': _certNumberCtrl.text.trim().isNotEmpty ? _certNumberCtrl.text.trim() : 'DRAFT-COO',
        'exporter_name': expName,
        'importer_name': impName,
        'country_of_origin': originCountry,
        'destination_country': destCountry,
        'invoice_number': _invoiceNoCtrl.text.trim(),
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

      await ref.read(cooReviewsProvider.notifier).saveCOOReview(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cooSessionSavedSuccess), backgroundColor: Colors.green),
        );
        setState(() => _activeStep = 3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cooSaveError(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    if (_selectedImportFileId == null && importFiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedImportFileId == null && importFiles.isNotEmpty) {
          final firstId = importFiles.first.importFileId;
          setState(() {
            _selectedImportFileId = firstId;
          });
          _loadSnapshot(firstId);
        }
      });
    }

    final steps = [
      ImportDocStep(label: context.l10n.cooStage1Requirements, icon: Icons.description),
      ImportDocStep(label: context.l10n.cooStage2DraftInput, icon: Icons.file_upload),
      ImportDocStep(label: context.l10n.cooStage3DiscrepancyMatrix, icon: Icons.fact_check),
      ImportDocStep(label: context.l10n.cooStage4Registry, icon: Icons.history_edu),
    ];

    return Column(
      children: [
        // Unified Stepper Navigation
        ImportDocStepper(
          steps: steps,
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
    final existingReviews = ref.watch(cooReviewsProvider).value ?? [];
    final existingReview = existingReviews.where((r) => r.importFileId == _selectedImportFileId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dedicated COO Decision Engine Header Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.charcoal, AppTheme.charcoal.withOpacity(0.92)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.cooDecisionEngineTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.cooDecisionEngineSub,
                            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_selectedImportFileId != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(context.l10n.cooRecheckAgreementButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _fetchAndApplyDraft(_selectedImportFileId!),
                    ),
                ],
              ),
              if (_selectedImportFileId != null) ...[
                const Divider(color: Colors.white24, height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_originCountryCtrl.text.isNotEmpty || _activeDraftTemplate?['country_of_origin'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          context.l10n.cooInvoiceOriginBadge(_activeDraftTemplate?['country_of_origin'] ?? _originCountryCtrl.text),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isManualChoiceRequired ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _isManualChoiceRequired ? Colors.amber : Colors.greenAccent),
                      ),
                      child: Text(
                        _isManualChoiceRequired ? context.l10n.cooManualChoiceRequiredBadge : context.l10n.cooApprovedCertBadge(_certType),
                        style: TextStyle(
                          color: _isManualChoiceRequired ? Colors.amberAccent : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

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
                            context.l10n.cooExistingReviewBanner(existingReview.cooReviewCode, existingReview.status),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          icon: const Icon(Icons.history, color: Colors.white, size: 14),
                          label: Text(context.l10n.cooReviewRegistryButton, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _activeStep = 3),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    const Icon(Icons.flag, color: AppTheme.cobalt),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(context.l10n.cooGenerateDraftHeader, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SearchableDropdownField<int>(
                        value: _selectedImportFileId,
                        labelText: context.l10n.cooSelectImportFileLabel,
                        searchHintText: context.l10n.cooSearchFileHint,
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
                        labelText: context.l10n.cooCertTypeLabel,
                        searchHintText: context.l10n.cooSelectCertTypeHint,
                        items: [
                          SearchableDropdownItem(value: 'EUR.1', label: context.l10n.cooCertTypeEur1),
                          SearchableDropdownItem(value: 'China Certificate of Origin (CCPIT)', label: context.l10n.cooCertTypeChina),
                          SearchableDropdownItem(value: 'Standard COO', label: context.l10n.cooCertTypeStandard),
                          SearchableDropdownItem(value: 'Form A / GSP', label: context.l10n.cooCertTypeFormA),
                          SearchableDropdownItem(value: 'Agadir Agreement', label: context.l10n.cooCertTypeAgadir),
                          SearchableDropdownItem(value: 'GAFTA', label: context.l10n.cooCertTypeGafta),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _certType = v);
                            if (_selectedImportFileId != null) {
                              _fetchAndApplyDraft(_selectedImportFileId!, overrideCertType: v);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                      icon: const Icon(Icons.bolt, color: Colors.white),
                      label: Text(context.l10n.cooOpenVisualPreviewButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _generateOfficialDraft,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text(context.l10n.cooNextDraftInputButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _activeStep = 1),
                    ),
                  ],
                ),
                if (_recommendationAlert != null && _recommendationAlert!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isManualChoiceRequired ? Colors.amber.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _isManualChoiceRequired ? Colors.amber.shade400 : Colors.green.shade400, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_isManualChoiceRequired ? Icons.warning_amber_rounded : Icons.verified, color: _isManualChoiceRequired ? Colors.amber.shade800 : Colors.green.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _recommendationAlert!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isManualChoiceRequired ? Colors.amber.shade900 : Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isManualChoiceRequired && _allowedCertTypes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _allowedCertTypes.map((type) {
                              final isSelected = _certType == type;
                              final typeLabel = type == 'Agadir Agreement'
                                  ? context.l10n.cooCertTypeAgadir
                                  : (type == 'GAFTA'
                                      ? context.l10n.cooCertTypeGafta
                                      : (type == 'EUR.1'
                                          ? context.l10n.cooCertTypeEur1
                                          : (type.contains('China')
                                              ? context.l10n.cooCertTypeChina
                                              : type)));
                              return ChoiceChip(
                                label: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.cobalt,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _certType = type);
                                    if (_selectedImportFileId != null) {
                                      _fetchAndApplyDraft(_selectedImportFileId!, overrideCertType: type);
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
                Text(context.l10n.cooDraftInputTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.compare_arrows, color: Colors.white),
                  label: Text(context.l10n.cooRunComparisonButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    labelText: context.l10n.cooLinkedImportFileLabel,
                    searchHintText: context.l10n.cooSearchFileHint,
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
                    labelText: context.l10n.cooCertTypeLabel,
                    searchHintText: context.l10n.cooSelectCertTypeHint,
                    items: [
                      SearchableDropdownItem(value: 'EUR.1', label: context.l10n.cooCertTypeEur1),
                      SearchableDropdownItem(value: 'China Certificate of Origin (CCPIT)', label: context.l10n.cooCertTypeChina),
                      SearchableDropdownItem(value: 'Standard COO', label: context.l10n.cooCertTypeStandard),
                      SearchableDropdownItem(value: 'Form A / GSP', label: context.l10n.cooCertTypeFormA),
                      SearchableDropdownItem(value: 'Agadir Agreement', label: context.l10n.cooCertTypeAgadir),
                      SearchableDropdownItem(value: 'GAFTA', label: context.l10n.cooCertTypeGafta),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _certType = v);
                      }
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
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.cooSelectFileWarning,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12.5),
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
                    decoration: InputDecoration(labelText: context.l10n.cooDraftCertNumberLabel, border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _originCountryCtrl,
                    decoration: InputDecoration(labelText: context.l10n.cooOriginCountryLabel, border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _destCountryCtrl,
                    decoration: InputDecoration(labelText: context.l10n.cooDestinationCountryLabel, border: const OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _exporterCtrl,
                    decoration: InputDecoration(labelText: context.l10n.cooExporterNameLabel, border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _exporterRegIdCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.cooExporterRegIdLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _importerCtrl,
                    decoration: InputDecoration(labelText: context.l10n.cooImporterNameLabel, border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _invoiceNoCtrl,
                    decoration: InputDecoration(labelText: context.l10n.cooInvoiceNumberLabel, border: const OutlineInputBorder()),
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
                  label: context.l10n.cooSmartUploadButtonLabel,
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
                      if (fields['exporter_reg_id'] != null && fields['exporter_reg_id'].toString().isNotEmpty) {
                        _exporterRegIdCtrl.text = fields['exporter_reg_id'].toString();
                      }
                      if (fields['consignee_name'] != null && fields['consignee_name'].toString().isNotEmpty) {
                        _importerCtrl.text = fields['consignee_name'].toString();
                      }
                      if (fields['importer_name'] != null && fields['importer_name'].toString().isNotEmpty) {
                        _importerCtrl.text = fields['importer_name'].toString();
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.cooRawTextSectionTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 18),
                  label: Text(context.l10n.cooSmartExtractFromTextButton, style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                  onPressed: (_isLoading || _selectedImportFileId == null) ? null : _extractFromOcrText,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _rawTextCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: context.l10n.cooRawTextHint,
                border: const OutlineInputBorder(),
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
              Text(context.l10n.cooSelectFileToViewMatrix, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: Text(context.l10n.cooBackToSelectFile, style: const TextStyle(color: Colors.white)),
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
              Text(context.l10n.cooRunComparisonPreviousStep, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: Text(context.l10n.cooBackToRunComparison, style: const TextStyle(color: Colors.white)),
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
                      hasCritical ? context.l10n.cooCriticalMismatchAlert : (hasDisc ? context.l10n.cooMinorDiscrepancyAlert : context.l10n.cooPerfectMatchSuccess),
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
                      label: Text(context.l10n.cooExportPdfButton, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        if (_selectedImportFileId != null && _activeDraftTemplate != null) {
                          CooExportService.printOrSavePdf(
                            templateData: _activeDraftTemplate!,
                            certificateType: _certType,
                            acidNumber: _activeAcidNumber ?? '7595528271020210010',
                            exemptionNotes: _activeExemptionNotes,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.cooExportingPdfReportSnackbar)),
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
                      label: Text(context.l10n.cooExportExcelButton, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        if (_activeDraftTemplate != null) {
                          final csv = CooExportService.exportCOOCsv(
                            templateData: _activeDraftTemplate!,
                            certificateType: _certType,
                            acidNumber: _activeAcidNumber ?? '7595528271020210010',
                          );
                          Clipboard.setData(ClipboardData(text: csv));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.cooExcelCopiedSnackbar), backgroundColor: Colors.green),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(context.l10n.cooSaveToRegistryButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                columns: [
                  DataColumn(label: Text(context.l10n.cooMatrixColField)),
                  DataColumn(label: Text(context.l10n.cooMatrixColSystemValue)),
                  DataColumn(label: Text(context.l10n.cooMatrixColDraftValue)),
                  DataColumn(label: Text(context.l10n.cooMatrixColStatus)),
                  DataColumn(label: Text(context.l10n.cooMatrixColDetails)),
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
                            context.l10n.cooOverrideReasonTitle,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.cooOverrideReasonSub,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _overrideReasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: context.l10n.cooOverrideReasonLabel,
                        hintText: context.l10n.cooOverrideReasonHint,
                        border: const OutlineInputBorder(),
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
                          label: Text(context.l10n.cooSaveWithJustificationButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          label: Text(context.l10n.cooReturnToEditAndNotifySupplierButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final cooReviews = ref.watch(cooReviewsProvider);

    return cooReviews.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
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
                    Text(context.l10n.cooRegistryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: Text(context.l10n.cooReviewNewDraftButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _activeStep = 0),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (reviews.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(30), child: Text(context.l10n.cooNoReviewsYet)))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(context.l10n.cooRegistryColCode)),
                        DataColumn(label: Text(context.l10n.cooRegistryColType)),
                        DataColumn(label: Text(context.l10n.cooRegistryColNumber)),
                        DataColumn(label: Text(context.l10n.cooRegistryColExporter)),
                        DataColumn(label: Text(context.l10n.cooRegistryColStatus)),
                        DataColumn(label: Text(context.l10n.cooRegistryColDate)),
                        DataColumn(label: Text(context.l10n.cooRegistryColActions)),
                      ],
                      rows: reviews.map((r) {
                        final expName = r.draftInputData?['exporter_name'] ?? r.draftInputData?['box_1_exporter'] ?? '—';
                        final impName = r.draftInputData?['importer_name'] ?? r.draftInputData?['box_2_consignee'] ?? '—';
                        final originCountry = r.draftInputData?['country_of_origin'] ?? '—';
                        final destCountry = r.draftInputData?['destination_country'] ?? r.draftInputData?['box_4_country_of_destination'] ?? '—';
                        final invNo = r.draftInputData?['invoice_number'] ?? r.draftInputData?['box_10_invoice_number_and_date'] ?? '—';
                        final rawTxt = r.rawText ?? r.draftInputData?['raw_text'] ?? '';
                        final overrideReason = r.notes ?? r.draftInputData?['override_reason'] ?? '';

                        return DataRow(cells: [
                          DataCell(Text(r.cooReviewCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                          DataCell(Text(r.certificateType)),
                          DataCell(Text(r.certificateNumber)),
                          DataCell(Text(expName)),
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
                                  tooltip: context.l10n.cooEditSessionTooltip,
                                  onPressed: () {
                                    setState(() {
                                      _selectedImportFileId = r.importFileId;
                                      _certType = r.certificateType;
                                      _certNumberCtrl.text = r.certificateNumber;
                                      _exporterCtrl.text = expName != '—' ? expName : '';
                                      _importerCtrl.text = impName != '—' ? impName : '';
                                      _originCountryCtrl.text = originCountry != '—' ? originCountry : 'Germany';
                                      _destCountryCtrl.text = destCountry != '—' ? destCountry : 'Egypt';
                                      _invoiceNoCtrl.text = invNo != '—' ? invNo : '';
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
                                      SnackBar(content: Text(context.l10n.cooLoadedSessionForEditSnackbar(r.cooReviewCode))),
                                    );
                                  },
                                ),
                                // 2. View (مشاهدة)
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: AppTheme.charcoal, size: 18),
                                  tooltip: context.l10n.cooViewDetailsTooltip,
                                  onPressed: () => _showCOOReviewDetailsDialog(r),
                                ),
                                // 3. Download PDF (تنزيل PDF)
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: AppTheme.crimson, size: 18),
                                  tooltip: context.l10n.cooDownloadPdfTooltip,
                                  onPressed: () async {
                                    final tData = {
                                      'certificate_number': r.certificateNumber,
                                      'box_1_exporter': expName,
                                      'box_2_consignee': impName,
                                      'country_of_origin': originCountry,
                                      'box_4_country_of_destination': destCountry,
                                      'box_10_invoice_number_and_date': invNo,
                                    };
                                    await CooExportService.printOrSavePdf(
                                      templateData: tData,
                                      certificateType: r.certificateType,
                                      acidNumber: '7595528271020210010',
                                    );
                                  },
                                ),
                                // 4. Delete (حذف)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  tooltip: context.l10n.cooDeleteSessionTooltip,
                                  onPressed: () => _confirmDeleteCOOReview(r),
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

  void _showCOOReviewDetailsDialog(CertificateOfOriginReviewModel r) {
    final expName = r.draftInputData?['exporter_name'] ?? r.draftInputData?['box_1_exporter'] ?? '—';
    final impName = r.draftInputData?['importer_name'] ?? r.draftInputData?['box_2_consignee'] ?? '—';
    final originCountry = r.draftInputData?['country_of_origin'] ?? '—';
    final destCountry = r.draftInputData?['destination_country'] ?? r.draftInputData?['box_4_country_of_destination'] ?? '—';
    final overrideReason = r.notes ?? r.draftInputData?['override_reason'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text(context.l10n.cooDetailsDialogTitle(r.cooReviewCode)),
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
                  title: Text(context.l10n.cooDetailsCertTypeAndNumber),
                  subtitle: Text('${r.certificateType} — #${r.certificateNumber}'),
                  dense: true,
                ),
                ListTile(
                  title: Text(context.l10n.cooDetailsExporterAndImporter),
                  subtitle: Text('${r.draftInputData?['exporter_name'] != null ? "Exporter" : "المصدر"}: $expName\n${r.draftInputData?['importer_name'] != null ? "Importer" : "المستورد"}: $impName'),
                  dense: true,
                ),
                ListTile(
                  title: Text(context.l10n.cooDetailsOriginAndDestination),
                  subtitle: Text('$originCountry ➔ $destCountry'),
                  dense: true,
                ),
                if (overrideReason.isNotEmpty)
                  ListTile(
                    title: Text(context.l10n.cooDetailsOverrideReason),
                    subtitle: Text(overrideReason, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    dense: true,
                  ),
                if (r.comparisonMatrix.isNotEmpty) ...[
                  const Divider(),
                  Text(context.l10n.cooDetailsMatrixTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              '${item['field_label_ar'] ?? item['field']}: [${item['draft_value']}] vs [${item['system_value']}]',
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
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCOOReview(CertificateOfOriginReviewModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(context.l10n.cooDeleteDialogTitle),
          ],
        ),
        content: Text(context.l10n.cooDeleteDialogContent(r.cooReviewCode, r.certificateNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(cooReviewsProvider.notifier).deleteCOOReview(r.cooReviewId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.cooDeleteSuccessSnackbar), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.cooDeleteErrorSnackbar(e.toString())), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
