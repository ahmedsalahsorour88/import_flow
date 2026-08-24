import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/import_requirement_model.dart';
import '../providers/import_requirements_provider.dart';

Color _getStatusColor(String status) {
  switch (status) {
    case 'Obtained':
    case 'Completed':
    case 'Approved':
    case 'Cleared':
    case 'Confirmed':
    case 'Cleared for Sailing':
    case 'Sailed':
    case 'تم الاستلام والتحقق':
    case 'تم الفحص واجتياز المطابقة':
    case 'تمت الموافقة والاعتماد':
    case 'معتمد ومصرح للشحن':
    case 'مؤكد ومصرح للشحن':
    case 'جاهز للإبحار':
    case 'تم الإبحار':
      return AppTheme.emerald;
    case 'Pending':
    case 'In Progress':
    case 'Applied':
    case 'Scheduled':
    case 'Pre-Sailing':
    case 'مطلوبة':
    case 'قيد الاستيفاء':
    case 'قيد الاستيفاء والتأكيد':
    case 'تم تقديم الطلب':
    case 'تم التكليف والتنسيق':
    case 'قبل الإبحار':
      return AppTheme.orange;
    case 'Rejected':
    case 'مرفوض':
    case 'مرفوضة':
      return AppTheme.crimson;
    case 'Waived':
    case 'تم الإعفاء':
      return AppTheme.cobalt;
    default:
      return Colors.grey.shade600;
  }
}

Color _getRiskLevelColor(String risk) {
  switch (risk) {
    case 'Low':
    case 'منخفض':
    case 'منخفض (Low)':
      return AppTheme.emerald;
    case 'Medium':
    case 'متوسط':
    case 'متوسط (Medium)':
      return AppTheme.orange;
    case 'High':
    case 'مرتفع':
    case 'مرتفع (High)':
      return AppTheme.crimson;
    default:
      return Colors.grey;
  }
}

class ImportRequirementsScreen extends ConsumerStatefulWidget {
  const ImportRequirementsScreen({super.key});

  @override
  ConsumerState<ImportRequirementsScreen> createState() => _ImportRequirementsScreenState();
}

class _ImportRequirementsScreenState extends ConsumerState<ImportRequirementsScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Registry Filters
  String _registryStatusFilter = 'All';
  String _registryRiskFilter = 'All';
  String _registryActiveFilter = 'Active'; // 'All', 'Active', 'Deleted'

  // Form State
  int _activePillarIndex = 0;
  int? _editingAssessmentId;
  String? _editingAssessmentCode;
  int? _selectedImportFileId;
  String? _selectedImportFileCode;
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  String? _selectedConsultationCode;
  int? _selectedConsultationId;
  double _consultationReadiness = 0.0;
  bool _isSaving = false;

  // Selected HS Code items
  final List<ImportRequirementHSCodeItemModel> _hsCodeItems = [];
  int _selectedHsItemIndex = 0;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _hsCodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'USD');
  final _valueCtrl = TextEditingController(text: '0.0');
  final _acidNumberCtrl = TextEditingController();
  final _factoryRegCtrl = TextEditingController();
  final _cooNotesCtrl = TextEditingController();
  final _inspReportNoCtrl = TextEditingController();
  final _inspNotesCtrl = TextEditingController();
  final _permitNumberCtrl = TextEditingController();
  final _permitNotesCtrl = TextEditingController();
  final _msdsNotesCtrl = TextEditingController();
  final _halalNotesCtrl = TextEditingController();
  final _coaNotesCtrl = TextEditingController();
  final _specialNotesCtrl = TextEditingController();
  final _sailingDateCtrl = TextEditingController();
  final _assessedByCtrl = TextEditingController(text: 'Kamal (Import Compliance Mgr)');

  // Pillar Form State Variables
  bool _decree43Applicable = false;
  bool _whiteListRequired = false;
  bool _whiteListVerified = false;

  bool _cooRequired = false;
  String _cooType = 'EUR.1';
  String _cooStatus = 'Not Required';

  bool _inspectionRequired = false;
  String _inspectionBody = 'SGS';
  String _inspectionStatus = 'Not Required';

  bool _importPermitRequired = false;
  String _permitIssuingAuthority = 'EEAA';
  String _permitStatus = 'Not Required';

  bool _msdsRequired = false;
  String _msdsStatus = 'Not Required';

  bool _halalCertRequired = false;
  String _halalCertStatus = 'Not Required';

  bool _coaRequired = false;
  String _coaStatus = 'Not Required';

  String _confirmationStatus = 'Pending Confirmation';
  bool _isPostAcidConfirmed = false;
  String _sailingStatus = 'Pre-Sailing'; // Pre-Sailing, Cleared for Sailing, Sailed
  String _overallStatus = 'Draft';
  String _riskLevel = 'Low';

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _searchController.dispose();
    _hsCodeCtrl.dispose();
    _descCtrl.dispose();
    _originCtrl.dispose();
    _currencyCtrl.dispose();
    _valueCtrl.dispose();
    _acidNumberCtrl.dispose();
    _factoryRegCtrl.dispose();
    _cooNotesCtrl.dispose();
    _inspReportNoCtrl.dispose();
    _inspNotesCtrl.dispose();
    _permitNumberCtrl.dispose();
    _permitNotesCtrl.dispose();
    _msdsNotesCtrl.dispose();
    _halalNotesCtrl.dispose();
    _coaNotesCtrl.dispose();
    _specialNotesCtrl.dispose();
    _sailingDateCtrl.dispose();
    _assessedByCtrl.dispose();
    super.dispose();
  }

  void _refreshAllData() {
    ref.read(importRequirementsProvider.notifier).refreshData();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(suppliersProvider.notifier).fetchSuppliers();
    ref.read(customsTariffProvider.notifier).fetchTariffs();
    ref.read(customsConsultationsProvider.notifier).fetchConsultations();
    ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
  }

  void _resetForm() {
    setState(() {
      _editingAssessmentId = null;
      _editingAssessmentCode = null;
      _selectedImportFileId = null;
      _selectedImportFileCode = null;
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _selectedConsultationCode = null;
      _selectedConsultationId = null;
      _consultationReadiness = 0.0;
      _hsCodeItems.clear();
      _selectedHsItemIndex = 0;

      _hsCodeCtrl.clear();
      _descCtrl.clear();
      _originCtrl.clear();
      _currencyCtrl.text = 'USD';
      _valueCtrl.text = '0.0';
      _acidNumberCtrl.clear();
      _factoryRegCtrl.clear();
      _cooNotesCtrl.clear();
      _inspReportNoCtrl.clear();
      _inspNotesCtrl.clear();
      _permitNumberCtrl.clear();
      _permitNotesCtrl.clear();
      _msdsNotesCtrl.clear();
      _halalNotesCtrl.clear();
      _coaNotesCtrl.clear();
      _specialNotesCtrl.clear();
      _sailingDateCtrl.clear();

      _decree43Applicable = false;
      _whiteListRequired = false;
      _whiteListVerified = false;
      _cooRequired = false;
      _cooType = 'EUR.1';
      _cooStatus = 'Not Required';
      _inspectionRequired = false;
      _inspectionBody = 'SGS';
      _inspectionStatus = 'Not Required';
      _importPermitRequired = false;
      _permitIssuingAuthority = 'EEAA';
      _permitStatus = 'Not Required';
      _msdsRequired = false;
      _msdsStatus = 'Not Required';
      _halalCertRequired = false;
      _halalCertStatus = 'Not Required';
      _coaRequired = false;
      _coaStatus = 'Not Required';
      _confirmationStatus = 'Pending Confirmation';
      _isPostAcidConfirmed = false;
      _sailingStatus = 'Pre-Sailing';
      _overallStatus = 'Draft';
      _riskLevel = 'Low';
      _activePillarIndex = 0;
    });
  }

  Future<void> _onImportFileChanged(int? fileId) async {
    if (fileId == null) {
      _resetForm();
      return;
    }

    final prefill = await ref.read(importRequirementsProvider.notifier).fetchPrefillData(fileId);
    if (!mounted) return;

    final l10n = context.l10n;

    if (prefill != null) {
      setState(() {
        _selectedImportFileId = prefill.importFileId;
        _selectedImportFileCode = prefill.importFileCode;
        _selectedSupplierId = prefill.supplierId;
        _selectedSupplierName = prefill.supplierName;
        _selectedConsultationCode = prefill.consultationCode;
        _selectedConsultationId = prefill.consultationId;
        _consultationReadiness = prefill.readinessPercentage;

        _acidNumberCtrl.text = prefill.acidNumber ?? '';
        _originCtrl.text = prefill.countryOfOrigin ?? 'China';
        _currencyCtrl.text = prefill.currency;
        _valueCtrl.text = prefill.shipmentValue.toStringAsFixed(2);
        _factoryRegCtrl.text = prefill.factoryRegistrationNo ?? prefill.foreignExporterId ?? '';

        _hsCodeItems.clear();
        _hsCodeItems.addAll(prefill.hsCodeItems);
        _selectedHsItemIndex = 0;

        if (_hsCodeItems.isNotEmpty) {
          _selectHsCodeItem(_hsCodeItems[0]);
        } else {
          _hsCodeCtrl.text = prefill.hsCode ?? '';
          _descCtrl.text = prefill.commodityDescription ?? '';
        }

        _decree43Applicable = prefill.decree43Applicable;
        _whiteListRequired = prefill.whiteListRequired;
        _whiteListVerified = prefill.whiteListVerified;

        _cooRequired = prefill.cooRequired;
        _cooType = prefill.cooType ?? 'EUR.1';
        _cooStatus = prefill.cooStatus;
        _cooNotesCtrl.text = prefill.cooNotes ?? '';

        _inspectionRequired = prefill.inspectionRequired;
        _inspectionBody = prefill.inspectionBody ?? 'SGS';
        _inspectionStatus = prefill.inspectionStatus;
        _inspNotesCtrl.text = prefill.inspectionNotes ?? '';

        _importPermitRequired = prefill.importPermitRequired;
        _permitIssuingAuthority = prefill.permitIssuingAuthority ?? 'EEAA';
        _permitStatus = prefill.permitStatus;
        _permitNotesCtrl.text = prefill.permitNotes ?? '';

        _msdsRequired = prefill.msdsRequired;
        _msdsStatus = prefill.msdsStatus;
        _halalCertRequired = prefill.halalCertRequired;
        _halalCertStatus = prefill.halalCertStatus;
        _coaRequired = prefill.coaRequired;
        _coaStatus = prefill.coaStatus;
        _specialNotesCtrl.text = prefill.specialNotes ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.prefillImportRequirementSuccess(prefill.hsCodeItems.length, prefill.importFileCode)),
          backgroundColor: AppTheme.cobalt,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _selectHsCodeItem(ImportRequirementHSCodeItemModel item) {
    setState(() {
      _hsCodeCtrl.text = item.hsCode;
      _descCtrl.text = item.commodityDescription ?? '';
      _originCtrl.text = item.countryOfOrigin ?? _originCtrl.text;
      _currencyCtrl.text = item.currency;
      _valueCtrl.text = item.itemValue.toStringAsFixed(2);

      if (item.cooRequired) _cooRequired = true;
      if (item.inspectionRequired) _inspectionRequired = true;
      if (item.permitRequired) {
        _importPermitRequired = true;
        if (item.regulatoryAuthority != null) {
          _permitIssuingAuthority = item.regulatoryAuthority!;
        }
      }
      if (item.decree43Applicable) _decree43Applicable = true;
    });
  }

  void _loadAssessmentForEditing(ImportRequirementModel item) {
    setState(() {
      _editingAssessmentId = item.assessmentId;
      _editingAssessmentCode = item.assessmentCode;
      _selectedImportFileId = item.importFileId;
      _selectedImportFileCode = item.importFileCode;
      _selectedSupplierId = item.supplierId;
      _selectedSupplierName = item.supplierName;
      _selectedConsultationCode = item.consultationCode;
      _selectedConsultationId = item.consultationId;

      _hsCodeCtrl.text = item.hsCode ?? '';
      _descCtrl.text = item.commodityDescription ?? '';
      _originCtrl.text = item.countryOfOrigin ?? '';
      _currencyCtrl.text = item.currency;
      _valueCtrl.text = item.shipmentValue.toStringAsFixed(2);
      _acidNumberCtrl.text = item.acidNumber ?? '';
      _factoryRegCtrl.text = item.factoryRegistrationNo ?? '';
      _cooNotesCtrl.text = item.cooNotes ?? '';
      _inspReportNoCtrl.text = item.inspectionReportNo ?? '';
      _inspNotesCtrl.text = item.inspectionNotes ?? '';
      _permitNumberCtrl.text = item.permitNumber ?? '';
      _permitNotesCtrl.text = item.permitNotes ?? '';
      _msdsNotesCtrl.text = item.msdsNotes ?? '';
      _halalNotesCtrl.text = item.halalCertNotes ?? '';
      _coaNotesCtrl.text = item.coaNotes ?? '';
      _specialNotesCtrl.text = item.assessmentNotes ?? '';
      _sailingDateCtrl.text = item.sailingDate ?? '';
      _assessedByCtrl.text = item.assessedBy;

      _hsCodeItems.clear();
      _hsCodeItems.addAll(item.hsCodeItems);
      _selectedHsItemIndex = 0;

      _decree43Applicable = item.decree43Applicable;
      _whiteListRequired = item.whiteListRequired;
      _whiteListVerified = item.whiteListVerified;

      _cooRequired = item.cooRequired;
      _cooType = item.cooType ?? 'EUR.1';
      _cooStatus = item.cooStatus;

      _inspectionRequired = item.inspectionRequired;
      _inspectionBody = item.inspectionBody ?? 'SGS';
      _inspectionStatus = item.inspectionStatus;

      _importPermitRequired = item.importPermitRequired;
      _permitIssuingAuthority = item.permitIssuingAuthority ?? 'EEAA';
      _permitStatus = item.permitStatus;

      _msdsRequired = item.msdsRequired;
      _msdsStatus = item.msdsStatus;
      _halalCertRequired = item.halalCertRequired;
      _halalCertStatus = item.halalCertStatus;
      _coaRequired = item.coaRequired;
      _coaStatus = item.coaStatus;

      _confirmationStatus = item.confirmationStatus;
      _isPostAcidConfirmed = item.isPostAcidConfirmed;
      _sailingStatus = item.sailingStatus;
      _overallStatus = item.overallStatus;
      _riskLevel = item.riskLevel;
    });

    _mainTabController.animateTo(0);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.loadedRequirementForEditingSnack(item.assessmentCode)),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _autoCompleteAllPillars() {
    setState(() {
      _whiteListVerified = true;
      _cooStatus = 'Obtained';
      _inspectionStatus = 'Completed';
      _permitStatus = 'Approved';
      _msdsStatus = 'Obtained';
      _halalCertStatus = 'Obtained';
      _coaStatus = 'Obtained';
      _isPostAcidConfirmed = true;
      _confirmationStatus = 'Confirmed & Cleared for Sailing';
      _sailingStatus = 'Cleared for Sailing';
      _overallStatus = 'Confirmed';
      _riskLevel = 'Low';
      if (_factoryRegCtrl.text.isEmpty) _factoryRegCtrl.text = 'GOEIC-REG-PASS-2026';
      if (_inspReportNoCtrl.text.isEmpty) _inspReportNoCtrl.text = 'ILAC-SGS-99201';
      if (_permitNumberCtrl.text.isEmpty) _permitNumberCtrl.text = 'PERMIT-GOEIC-8871';
    });
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.completeAllPillarsSuccessSnack),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  Future<void> _saveAssessment() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillRequiredFieldsError), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectImportFileError), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'import_file_id': _selectedImportFileId,
      'import_file_code': _selectedImportFileCode,
      'hs_code': _hsCodeCtrl.text.trim(),
      'commodity_description': _descCtrl.text.trim(),
      'country_of_origin': _originCtrl.text.trim(),
      'currency': _currencyCtrl.text.trim(),
      'shipment_value': double.tryParse(_valueCtrl.text) ?? 0.0,
      'shipment_value_usd': double.tryParse(_valueCtrl.text) ?? 0.0,
      'hs_code_items': _hsCodeItems.map((e) => e.toJson()).toList(),
      'supplier_id': _selectedSupplierId,
      'supplier_name': _selectedSupplierName,
      'decree_43_applicable': _decree43Applicable,
      'white_list_required': _whiteListRequired,
      'white_list_verified': _whiteListVerified,
      'factory_registration_no': _factoryRegCtrl.text.trim(),
      'coo_required': _cooRequired,
      'coo_type': _cooType,
      'coo_status': _cooStatus,
      'coo_notes': _cooNotesCtrl.text.trim(),
      'inspection_required': _inspectionRequired,
      'inspection_body': _inspectionBody,
      'inspection_status': _inspectionStatus,
      'inspection_report_no': _inspReportNoCtrl.text.trim(),
      'inspection_notes': _inspNotesCtrl.text.trim(),
      'import_permit_required': _importPermitRequired,
      'permit_issuing_authority': _permitIssuingAuthority,
      'permit_number': _permitNumberCtrl.text.trim(),
      'permit_status': _permitStatus,
      'permit_notes': _permitNotesCtrl.text.trim(),
      'msds_required': _msdsRequired,
      'msds_status': _msdsStatus,
      'msds_notes': _msdsNotesCtrl.text.trim(),
      'halal_cert_required': _halalCertRequired,
      'halal_cert_status': _halalCertStatus,
      'halal_cert_notes': _halalNotesCtrl.text.trim(),
      'coa_required': _coaRequired,
      'coa_status': _coaStatus,
      'coa_notes': _coaNotesCtrl.text.trim(),
      'acid_number': _acidNumberCtrl.text.trim(),
      'consultation_id': _selectedConsultationId,
      'consultation_code': _selectedConsultationCode,
      'confirmation_status': _confirmationStatus,
      'is_post_acid_confirmed': _isPostAcidConfirmed,
      'confirmed_at': _isPostAcidConfirmed ? DateTime.now().toIso8601String() : null,
      'confirmed_by': _assessedByCtrl.text.trim(),
      'sailing_status': _sailingStatus,
      'sailing_date': _sailingDateCtrl.text.trim(),
      'overall_status': _overallStatus,
      'risk_level': _riskLevel,
      'assessed_by': _assessedByCtrl.text.trim(),
      'assessment_notes': _specialNotesCtrl.text.trim(),
    };

    try {
      if (_editingAssessmentId != null) {
        await ref.read(importRequirementsProvider.notifier).updateRequirement(_editingAssessmentId!, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.updateRequirementSuccessSnack(_editingAssessmentCode ?? '')),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } else {
        await ref.read(importRequirementsProvider.notifier).addRequirement(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.createRequirementSuccessSnack),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      }

      _resetForm();
      _mainTabController.animateTo(1);
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Text(l10n.saveRequirementErrorTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(errorMsg, style: const TextStyle(fontSize: 13, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mainTabController.animateTo(1);
                },
                child: Text(l10n.goToSavedRequirementsBtn, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.verified_outlined, color: AppTheme.cobalt, size: 24),
            const SizedBox(width: 10),
            Text(
              l10n.importRequirementsScreenTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppTheme.emerald,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(icon: const Icon(Icons.assignment_outlined, size: 18), text: l10n.importRequirementsFormTab),
            Tab(icon: const Icon(Icons.folder_shared_outlined, size: 18), text: l10n.importRequirementsRegistryTab),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: l10n.refresh,
            onPressed: _refreshAllData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildInteractiveAssessmentFormTab(),
          _buildSavedAssessmentsRegistryTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: INTERACTIVE 5-PILLARS ASSESSMENT FORM
  // ===========================================================================
  Widget _buildInteractiveAssessmentFormTab() {
    final l10n = context.l10n;
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Editing Banner if in Edit Mode
            if (_editingAssessmentId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cobalt),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: AppTheme.cobalt, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.editingRequirementBanner(_editingAssessmentCode ?? ''),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: Text(l10n.cancelEditingAndStartNewBtn, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Card 1: Lifecycle & Progress Tracker (من إصدار ACID حتى الإبحار)
            _buildLifecycleProgressCard(),
            const SizedBox(height: 12),

            // Card 2: Import File & Supplier Info Card
            _buildImportFileSelectorCard(importFiles, suppliers),
            const SizedBox(height: 12),

            // Card 3: HS Codes List & Values Selector
            _buildHsCodesSelectorCard(),
            const SizedBox(height: 12),

            // Card 4: 5 Pillars Interactive Tabs Workspace
            _build5PillarsWorkspaceCard(),
            const SizedBox(height: 16),

            // Card 5: Bottom Final Actions Toolbar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleProgressCard() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.requirementsLifecycleCardTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_sailingStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(_sailingStatus)),
                ),
                child: Text(
                  l10n.sailingStatusBadge(_sailingStatus),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _getStatusColor(_sailingStatus)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStepNode(
                step: '1',
                title: l10n.acidIssuanceStep,
                subtitle: _acidNumberCtrl.text.isNotEmpty ? _acidNumberCtrl.text : l10n.pending,
                isCompleted: _acidNumberCtrl.text.isNotEmpty,
                isActive: true,
              ),
              _buildStepConnector(isCompleted: _acidNumberCtrl.text.isNotEmpty),
              _buildStepNode(
                step: '2',
                title: l10n.preShipmentInspectionStep,
                subtitle: _inspectionStatus == 'Completed' ? l10n.completedAndPassedInspection : l10n.pendingInspectionCoordination,
                isCompleted: _inspectionStatus == 'Completed',
                isActive: true,
              ),
              _buildStepConnector(isCompleted: _inspectionStatus == 'Completed'),
              _buildStepNode(
                step: '3',
                title: l10n.approvalsAndCertsStep,
                subtitle: _cooStatus == 'Obtained' && _whiteListVerified ? l10n.allCertsFulfilled100 : l10n.pendingApprovals,
                isCompleted: _cooStatus == 'Obtained' && _whiteListVerified,
                isActive: true,
              ),
              _buildStepConnector(isCompleted: _sailingStatus == 'Cleared for Sailing' || _sailingStatus == 'Sailed'),
              _buildStepNode(
                step: '4',
                title: l10n.sailingClearanceStep,
                subtitle: _sailingStatus,
                isCompleted: _sailingStatus == 'Cleared for Sailing' || _sailingStatus == 'Sailed',
                isActive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required String step,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
  }) {
    final color = isCompleted ? AppTheme.emerald : (isActive ? AppTheme.cobalt : Colors.grey);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: color,
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(step, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color), overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Container(
      width: 16,
      height: 2,
      color: isCompleted ? AppTheme.emerald : Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildImportFileSelectorCard(List<dynamic> importFiles, List<dynamic> suppliers) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(l10n.linkImportFileAndConsultationHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              const Spacer(),
              if (_selectedConsultationCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cobalt),
                  ),
                  child: Text(l10n.consultationStudyBadge(_selectedConsultationCode, _consultationReadiness.toInt()), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SearchableDropdownField<int?>(
                  labelText: l10n.linkedImportFileFieldLabel,
                  hintText: l10n.selectImportFileHint,
                  value: _selectedImportFileId,
                  items: [
                    SearchableDropdownItem<int?>(value: null, label: l10n.selectImportFileOption),
                    ...importFiles.map((f) => SearchableDropdownItem<int?>(
                          value: f.importFileId,
                          label: '[${f.importFileCode}] ${f.companyName} | ACID: ${f.acidNumber ?? l10n.acidNotIssued}',
                        )),
                  ],
                  onChanged: _onImportFileChanged,
                  validator: (v) => v == null ? l10n.pleaseSelectImportFileError : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _acidNumberCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.acidNumberFieldLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.acidNumberRequiredError : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<int?>(
                  labelText: l10n.foreignSupplierFieldLabel,
                  hintText: l10n.foreignSupplierHint,
                  value: _selectedSupplierId,
                  items: [
                    SearchableDropdownItem<int?>(value: null, label: l10n.notSpecifiedOption),
                    ...suppliers.map((s) => SearchableDropdownItem<int?>(
                          value: s.supplierId,
                          label: '${s.companyName} (${s.foreignExporterCountry ?? "N/A"})',
                        )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedSupplierId = v;
                      final matched = suppliers.where((s) => s.supplierId == v).firstOrNull;
                      if (matched != null) {
                        _selectedSupplierName = matched.companyName;
                        _originCtrl.text = matched.foreignExporterCountry ?? _originCtrl.text;
                        _factoryRegCtrl.text = matched.foreignExporterId ?? _factoryRegCtrl.text;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHsCodesSelectorCard() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.hsCodesSelectorCardTitle(_hsCodeItems.length),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.emerald),
                ),
                child: Text(
                  l10n.totalHsValueBadge(_valueCtrl.text, _currencyCtrl.text),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.emerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // If multiple HS codes exist, display an interactive horizontal list of chips/cards
          if (_hsCodeItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_hsCodeItems.length, (idx) {
                  final itm = _hsCodeItems[idx];
                  final isSelected = _selectedHsItemIndex == idx;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedHsItemIndex = idx);
                      _selectHsCodeItem(itm);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.cobalt.withOpacity(0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.cobalt : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: isSelected ? AppTheme.cobalt : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.hsItemCodeLabel(itm.hsCode, itm.itemCode ?? 'Item'),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? AppTheme.cobalt : AppTheme.charcoal),
                              ),
                              Text(
                                l10n.hsItemDescLabel(itm.commodityDescription ?? '', itm.itemValue.toStringAsFixed(2), itm.currency),
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Primary HS Code Detail Fields
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _hsCodeCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.hsCodeFieldLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.qr_code_2, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.hsCodeRequiredError : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.commodityDescFieldLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.description, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commodityDescRequiredError : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _originCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.countryOfOriginFieldLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.public, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.countryOfOriginRequiredError : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _currencyCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.currencyFieldLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _valueCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.valueInCurrencyFieldLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.monetization_on, color: AppTheme.emerald, size: 18),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build5PillarsWorkspaceCard() {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-tabs Selector for 5 Pillars
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPillarTabButton(0, l10n.pillar1Decree43Tab, Icons.factory_outlined, _whiteListVerified),
                  _buildPillarTabButton(1, l10n.pillar2CooTab, Icons.public, _cooStatus == 'Obtained'),
                  _buildPillarTabButton(2, l10n.pillar3InspectionTab, Icons.fact_check_outlined, _inspectionStatus == 'Completed'),
                  _buildPillarTabButton(3, l10n.pillar4PermitsTab, Icons.account_balance_outlined, _permitStatus == 'Approved'),
                  _buildPillarTabButton(4, l10n.pillar5TechCertsTab, Icons.science_outlined, _isPostAcidConfirmed),
                ],
              ),
            ),
          ),

          // Pillar Content Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IndexedStack(
              index: _activePillarIndex,
              children: [
                _buildPillar1Content(),
                _buildPillar2Content(),
                _buildPillar3Content(),
                _buildPillar4Content(),
                _buildPillar5Content(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTabButton(int index, String title, IconData icon, bool isFulfilled) {
    final isSelected = _activePillarIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _activePillarIndex = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cobalt : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.charcoal),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.charcoal,
                ),
              ),
              const SizedBox(width: 6),
              if (isFulfilled)
                const Icon(Icons.check_circle, size: 14, color: AppTheme.emerald)
              else
                Icon(Icons.circle_outlined, size: 12, color: isSelected ? Colors.white70 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Pillar 1: Decree 43
  Widget _buildPillar1Content() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pillar1Header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text(l10n.decree43ApplicableCheck, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(l10n.decree43ApplicableSub),
                value: _decree43Applicable,
                onChanged: (v) => setState(() => _decree43Applicable = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text(l10n.whiteListVerifiedCheck, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(l10n.whiteListVerifiedSub),
                value: _whiteListVerified,
                onChanged: (v) => setState(() => _whiteListVerified = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _factoryRegCtrl,
          decoration: InputDecoration(
            labelText: l10n.factoryRegNumFieldLabel,
            hintText: l10n.factoryRegNumHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.badge, color: AppTheme.cobalt),
          ),
        ),
      ],
    );
  }

  // Pillar 2: Certificate of Origin
  Widget _buildPillar2Content() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pillar2Header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CheckboxListTile(
                title: Text(l10n.cooRequiredCheck, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _cooRequired,
                onChanged: (v) => setState(() => _cooRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: l10n.cooTypeFieldLabel,
                value: _cooType,
                items: [
                  SearchableDropdownItem(value: 'EUR.1', label: l10n.cooTypeEur1Option),
                  SearchableDropdownItem(value: 'Form A', label: l10n.cooTypeFormAOption),
                  SearchableDropdownItem(value: 'Arab League COO', label: l10n.cooTypeGaftaOption),
                  SearchableDropdownItem(value: 'COMESA', label: l10n.cooTypeComesaOption),
                  SearchableDropdownItem(value: 'Standard COO', label: l10n.cooTypeStandardChamberOption),
                ],
                onChanged: (v) => setState(() => _cooType = v ?? _cooType),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: l10n.cooStatusFieldLabel,
                value: _cooStatus,
                items: [
                  SearchableDropdownItem(value: 'Not Required', label: l10n.statusInactive),
                  SearchableDropdownItem(value: 'Pending', label: l10n.cooStatusPendingOption),
                  SearchableDropdownItem(value: 'Obtained', label: l10n.cooStatusObtainedOption),
                  SearchableDropdownItem(value: 'Waived', label: l10n.cooStatusWaivedOption),
                ],
                onChanged: (v) => setState(() => _cooStatus = v ?? _cooStatus),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _cooNotesCtrl,
          decoration: InputDecoration(
            labelText: l10n.cooNotesFieldLabel,
            hintText: l10n.cooNotesHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Pillar 3: Pre-Shipment Inspection
  Widget _buildPillar3Content() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pillar3Header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CheckboxListTile(
                title: Text(l10n.inspectionRequiredCheck, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _inspectionRequired,
                onChanged: (v) => setState(() => _inspectionRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: l10n.inspectionBodyFieldLabel,
                value: _inspectionBody,
                items: [
                  SearchableDropdownItem(value: 'SGS', label: l10n.inspectionBodySgsOption),
                  SearchableDropdownItem(value: 'Bureau Veritas', label: l10n.inspectionBodyBvOption),
                  SearchableDropdownItem(value: 'TÜV', label: l10n.inspectionBodyTuvOption),
                  SearchableDropdownItem(value: 'Intertek', label: l10n.inspectionBodyIntertekOption),
                  SearchableDropdownItem(value: 'QIMA', label: l10n.inspectionBodyQimaOption),
                  SearchableDropdownItem(value: 'ILAC ISO 17025', label: l10n.inspectionBodyIlacOption),
                ],
                onChanged: (v) => setState(() => _inspectionBody = v ?? _inspectionBody),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: l10n.inspectionStatusFieldLabel,
                value: _inspectionStatus,
                items: [
                  SearchableDropdownItem(value: 'Not Required', label: l10n.statusInactive),
                  SearchableDropdownItem(value: 'Pending', label: l10n.inspectionStatusPendingOption),
                  SearchableDropdownItem(value: 'Scheduled', label: l10n.inspectionStatusScheduledOption),
                  SearchableDropdownItem(value: 'Completed', label: l10n.inspectionStatusCompletedOption),
                  SearchableDropdownItem(value: 'Rejected', label: l10n.inspectionStatusRejectedOption),
                ],
                onChanged: (v) => setState(() => _inspectionStatus = v ?? _inspectionStatus),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _inspReportNoCtrl,
                decoration: InputDecoration(
                  labelText: l10n.inspectionReportNumFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _inspNotesCtrl,
                decoration: InputDecoration(
                  labelText: l10n.inspectionNotesFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Pillar 4: Prior Import Permits
  Widget _buildPillar4Content() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pillar4Header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CheckboxListTile(
                title: Text(l10n.importPermitRequiredCheck, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _importPermitRequired,
                onChanged: (v) => setState(() => _importPermitRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: l10n.issuingAuthorityFieldLabel,
                value: _permitIssuingAuthority,
                items: [
                  SearchableDropdownItem(value: 'EEAA', label: l10n.authorityEeaaOption),
                  SearchableDropdownItem(value: 'NFSA', label: l10n.authorityNfsaOption),
                  SearchableDropdownItem(value: 'EDA', label: l10n.authorityEdaOption),
                  SearchableDropdownItem(value: 'NTRA', label: l10n.authorityNtraOption),
                  SearchableDropdownItem(value: 'Public Security', label: l10n.authorityPublicSecurityOption),
                  SearchableDropdownItem(value: 'Chemistry Authority', label: l10n.authorityChemistryOption),
                  SearchableDropdownItem(value: 'GOEIC', label: l10n.authorityGoeicOption),
                ],
                onChanged: (v) => setState(() => _permitIssuingAuthority = v ?? _permitIssuingAuthority),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: l10n.permitStatusFieldLabel,
                value: _permitStatus,
                items: [
                  SearchableDropdownItem(value: 'Not Required', label: l10n.statusInactive),
                  SearchableDropdownItem(value: 'Applied', label: l10n.permitStatusAppliedOption),
                  SearchableDropdownItem(value: 'Approved', label: l10n.permitStatusApprovedOption),
                  SearchableDropdownItem(value: 'Rejected', label: l10n.permitStatusRejectedOption),
                ],
                onChanged: (v) => setState(() => _permitStatus = v ?? _permitStatus),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _permitNumberCtrl,
                decoration: InputDecoration(
                  labelText: l10n.permitNumberFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _permitNotesCtrl,
                decoration: InputDecoration(
                  labelText: l10n.permitNotesFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Pillar 5: Technical Certificates & Sailing Confirmation
  Widget _buildPillar5Content() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pillar5Header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text(l10n.msdsRequiredCheck, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _msdsRequired,
                onChanged: (v) => setState(() => _msdsRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text(l10n.halalCertRequiredCheck, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _halalCertRequired,
                onChanged: (v) => setState(() => _halalCertRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text(l10n.coaRequiredCheck, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _coaRequired,
                onChanged: (v) => setState(() => _coaRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  labelText: l10n.sailingStatusFieldLabel,
                  value: _sailingStatus,
                  items: [
                    SearchableDropdownItem(value: 'Pre-Sailing', label: l10n.sailingStatusPreSailingOption),
                    SearchableDropdownItem(value: 'Cleared for Sailing', label: l10n.sailingStatusClearedOption),
                    SearchableDropdownItem(value: 'Sailed', label: l10n.sailingStatusSailedOption),
                  ],
                  onChanged: (v) => setState(() => _sailingStatus = v ?? _sailingStatus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _sailingDateCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.sailingDateFieldLabel,
                    hintText: 'YYYY-MM-DD',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.directions_boat, color: AppTheme.cobalt, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  labelText: l10n.riskLevelFieldLabel,
                  value: _riskLevel,
                  items: [
                    SearchableDropdownItem(value: 'Low', label: l10n.riskLevelLowOption),
                    SearchableDropdownItem(value: 'Medium', label: l10n.riskLevelMediumOption),
                    SearchableDropdownItem(value: 'High', label: l10n.riskLevelHighOption),
                  ],
                  onChanged: (v) => setState(() => _riskLevel = v ?? _riskLevel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  labelText: l10n.statusCol,
                  value: _overallStatus,
                  items: [
                    SearchableDropdownItem(value: 'Draft', label: l10n.overallStatusDraftOption),
                    SearchableDropdownItem(value: 'In Progress', label: l10n.overallStatusInProgressOption),
                    SearchableDropdownItem(value: 'Complete', label: l10n.overallStatusCompleteOption),
                    SearchableDropdownItem(value: 'Confirmed', label: l10n.overallStatusConfirmedOption),
                  ],
                  onChanged: (v) => setState(() => _overallStatus = v ?? _overallStatus),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2FE),
              foregroundColor: AppTheme.cobalt,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: _autoCompleteAllPillars,
            icon: const Icon(Icons.bolt, color: AppTheme.cobalt, size: 18),
            label: Text(l10n.completeAllPillarsBtn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.charcoal,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: _refreshAllData,
            icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
            label: Text(l10n.refresh, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: _resetForm,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.blueGrey),
            label: Text(l10n.cancelEditingAndStartNewBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFF6FF),
              foregroundColor: AppTheme.cobalt,
              elevation: 0,
              side: const BorderSide(color: AppTheme.cobalt),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: _isSaving ? null : _saveAssessment,
            icon: const Icon(Icons.save_outlined, size: 18, color: AppTheme.cobalt),
            label: Text(l10n.saveRequirementDraftBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 2,
            ),
            onPressed: _isSaving ? null : _saveAssessment,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              _editingAssessmentId != null ? l10n.updateRequirementSubmitBtn : l10n.saveRequirementSubmitBtn,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SAVED ASSESSMENTS REGISTRY
  // ===========================================================================
  Widget _buildSavedAssessmentsRegistryTab() {
    final l10n = context.l10n;
    final asyncReqs = ref.watch(importRequirementsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          MasterDataToolbarWidget(
            moduleEndpoint: 'import-requirements',
            title: 'Import_Requirements_Registry',
            onRefreshNeeded: _refreshAllData,
          ),
          const SizedBox(height: 12),

          // Filters Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchRequirementsHint,
                      prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: l10n.complianceStatusFilterLabel,
                    value: _registryStatusFilter,
                    items: [
                      SearchableDropdownItem(value: 'All', label: l10n.partnerCatAll),
                      SearchableDropdownItem(value: 'Draft', label: l10n.overallStatusDraftOption),
                      SearchableDropdownItem(value: 'In Progress', label: l10n.overallStatusInProgressOption),
                      SearchableDropdownItem(value: 'Complete', label: l10n.overallStatusCompleteOption),
                      SearchableDropdownItem(value: 'Confirmed', label: l10n.overallStatusConfirmedOption),
                    ],
                    onChanged: (v) => setState(() => _registryStatusFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: l10n.riskLevelFilterLabel,
                    value: _registryRiskFilter,
                    items: [
                      SearchableDropdownItem(value: 'All', label: l10n.partnerCatAll),
                      SearchableDropdownItem(value: 'Low', label: l10n.riskLevelLowOption),
                      SearchableDropdownItem(value: 'Medium', label: l10n.riskLevelMediumOption),
                      SearchableDropdownItem(value: 'High', label: l10n.riskLevelHighOption),
                    ],
                    onChanged: (v) => setState(() => _registryRiskFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: l10n.activeDeletedFilterLabel,
                    value: _registryActiveFilter,
                    items: [
                      SearchableDropdownItem(value: 'All', label: l10n.allRecordsActiveAndDeleted),
                      SearchableDropdownItem(value: 'Active', label: l10n.activeOnlyOption),
                      SearchableDropdownItem(value: 'Deleted', label: l10n.deletedOnlyOption),
                    ],
                    onChanged: (v) => setState(() => _registryActiveFilter = v ?? 'Active'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Registry DataTable
          Expanded(
            child: asyncReqs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(l10n.requirementsFetchError(err.toString()), style: const TextStyle(color: Colors.red)),
              ),
              data: (list) {
                final filtered = list.where((item) {
                  // Search query filter
                  final query = _searchController.text.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    final matchCode = item.assessmentCode.toLowerCase().contains(query);
                    final matchFile = (item.importFileCode ?? '').toLowerCase().contains(query);
                    final matchHs = (item.hsCode ?? '').toLowerCase().contains(query);
                    final matchAcid = (item.acidNumber ?? '').toLowerCase().contains(query);
                    final matchSupp = (item.supplierName ?? '').toLowerCase().contains(query);
                    final matchDesc = (item.commodityDescription ?? '').toLowerCase().contains(query);
                    if (!matchCode && !matchFile && !matchHs && !matchAcid && !matchSupp && !matchDesc) {
                      return false;
                    }
                  }

                  // Status filter
                  if (_registryStatusFilter != 'All' && item.overallStatus != _registryStatusFilter) {
                    return false;
                  }

                  // Risk filter
                  if (_registryRiskFilter != 'All' && item.riskLevel != _registryRiskFilter) {
                    return false;
                  }

                  // Active filter
                  if (_registryActiveFilter == 'Active' && !item.isActive) return false;
                  if (_registryActiveFilter == 'Deleted' && item.isActive) return false;

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(l10n.noRequirementsFound, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                          onPressed: () => _mainTabController.animateTo(0),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(l10n.createNewRequirementBtn, style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final req = filtered[idx];
                      return _buildRegistryRow(req);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryRow(ImportRequirementModel req) {
    final l10n = context.l10n;
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final matchingFile = importFiles.where((f) => f.importFileId == req.importFileId).firstOrNull;
    final fileCode = matchingFile?.customFileNumber ?? matchingFile?.importFileCode ?? req.importFileCode ?? (req.importFileId != null ? 'IMP-${req.importFileId}' : '');
    final companyName = (matchingFile?.companyName.isNotEmpty == true && matchingFile?.companyName != 'N/A')
        ? matchingFile!.companyName
        : l10n.fallbackImportingCompany;
    final displayName = fileCode.isNotEmpty ? '[$fileCode] $companyName' : req.assessmentCode;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: req.isActive ? AppTheme.cobalt.withOpacity(0.12) : Colors.grey.shade300,
        child: Icon(
          req.isActive ? Icons.verified : Icons.delete_outline,
          color: req.isActive ? AppTheme.cobalt : Colors.grey,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(req.assessmentCode, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          if (req.acidNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('ACID: ${req.acidNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.bold)),
            ),
          const Spacer(),
          if (!req.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
              child: Text(l10n.deletedOnlyOption, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.requirementRowSubtitle(req.hsCode ?? "N/A", req.commodityDescription ?? "", req.shipmentValue.toStringAsFixed(2), req.currency, req.supplierName ?? "N/A", req.countryOfOrigin ?? "N/A"),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildBadge(l10n.sailingStatusBadgeRow(req.sailingStatus), _getStatusColor(req.sailingStatus)),
                _buildBadge(l10n.requirementStatusBadgeRow(req.overallStatus), _getStatusColor(req.overallStatus)),
                _buildBadge(l10n.riskLevelBadgeRow(req.riskLevel), _getRiskLevelColor(req.riskLevel)),
                if (req.hsCodeItems.isNotEmpty)
                  _buildBadge(l10n.hsItemsCountBadge(req.hsCodeItems.length), AppTheme.cobalt),
                if (req.decree43Applicable && req.whiteListVerified)
                  _buildBadge(l10n.decree43VerifiedBadge, AppTheme.emerald),
                if (req.cooRequired && req.cooStatus == 'Obtained')
                  _buildBadge(l10n.cooObtainedBadge, AppTheme.emerald),
                if (req.inspectionRequired && req.inspectionStatus == 'Completed')
                  _buildBadge(l10n.inspectionPassedBadge, AppTheme.emerald),
              ],
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit Button (Restores if deleted and loads into form)
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.cobalt),
            tooltip: l10n.editRequirementTooltip,
            onPressed: () => _loadAssessmentForEditing(req),
          ),
          // Restore Button if inactive
          if (!req.isActive)
            IconButton(
              icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald),
              tooltip: l10n.restoreRequirementTooltip,
              onPressed: () async {
                if (req.assessmentId != null) {
                  await ref.read(importRequirementsProvider.notifier).restoreRequirement(req.assessmentId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.restoredRequirementSuccessSnack(req.assessmentCode)), backgroundColor: AppTheme.emerald),
                    );
                  }
                }
              },
            ),
          // Delete Button
          if (req.isActive)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: l10n.deleteRequirementTooltip,
              onPressed: () => _confirmDeleteAssessment(req),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _confirmDeleteAssessment(ImportRequirementModel req) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.confirmDeleteRequirementTitle),
          ],
        ),
        content: Text(l10n.confirmDeleteRequirementContent(req.assessmentCode, req.importFileCode ?? '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              if (req.assessmentId != null) {
                await ref.read(importRequirementsProvider.notifier).deleteRequirement(req.assessmentId!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.deletedRequirementSuccessSnack(req.assessmentCode)), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
