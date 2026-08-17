import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String _cooType = 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)';
  String _cooStatus = 'Not Required';

  bool _inspectionRequired = false;
  String _inspectionBody = 'SGS (الشركة العامة للمعاينة)';
  String _inspectionStatus = 'Not Required';

  bool _importPermitRequired = false;
  String _permitIssuingAuthority = 'جهاز شئون البيئة (EEAA)';
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
      _cooType = 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)';
      _cooStatus = 'Not Required';
      _inspectionRequired = false;
      _inspectionBody = 'SGS (الشركة العامة للمعاينة)';
      _inspectionStatus = 'Not Required';
      _importPermitRequired = false;
      _permitIssuingAuthority = 'جهاز شئون البيئة (EEAA)';
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
        _cooType = prefill.cooType ?? 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)';
        _cooStatus = prefill.cooStatus;
        _cooNotesCtrl.text = prefill.cooNotes ?? '';

        _inspectionRequired = prefill.inspectionRequired;
        _inspectionBody = prefill.inspectionBody ?? 'SGS (الشركة العامة للمعاينة)';
        _inspectionStatus = prefill.inspectionStatus;
        _inspNotesCtrl.text = prefill.inspectionNotes ?? '';

        _importPermitRequired = prefill.importPermitRequired;
        _permitIssuingAuthority = prefill.permitIssuingAuthority ?? 'جهاز شئون البيئة (EEAA)';
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
          content: Text('⚡ تم استدعاء بنود التعريفة (${prefill.hsCodeItems.length} بند) والمتطلبات تلقائياً للملف ${prefill.importFileCode}'),
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
      _cooType = item.cooType ?? 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)';
      _cooStatus = item.cooStatus;

      _inspectionRequired = item.inspectionRequired;
      _inspectionBody = item.inspectionBody ?? 'SGS (الشركة العامة للمعاينة)';
      _inspectionStatus = item.inspectionStatus;

      _importPermitRequired = item.importPermitRequired;
      _permitIssuingAuthority = item.permitIssuingAuthority ?? 'جهاز شئون البيئة (EEAA)';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📂 تم تحميل التقييم (${item.assessmentCode}) وجاهز للتعديل والمطابقة!'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ تم استيفاء وتأكيد جاهزية كافة المحاور وتجهيز الشحنة للإبحار!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء التأكد من تعبئة جميع الحقول المطلوبة.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة الاستيرادية المربوط أولاً.'), backgroundColor: Colors.orange),
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
              content: Text('✅ تم تعديل وحفظ تقييم المتطلبات ($_editingAssessmentCode) بنجاح!'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } else {
        await ref.read(importRequirementsProvider.notifier).addRequirement(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إنشاء وحفظ تقييم المتطلبات التنظيمية والمطابقة بنجاح!'),
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
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('تنبيه عدم التكرار / خطأ بالحفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(errorMsg, style: const TextStyle(fontSize: 13, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mainTabController.animateTo(1);
                },
                child: const Text('الانتقال للسجلات المحفوظة والتعديل عليها', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: AppTheme.cobalt, size: 24),
            SizedBox(width: 10),
            Text(
              'تقييم متطلبات ومستندات الاستيراد والموافقات التنظيمية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: '📋 تقييم ومطابقة المتطلبات التنظيمية (Interactive Form)'),
            Tab(icon: Icon(Icons.folder_shared_outlined, size: 18), text: '📑 سجل دراسات المتطلبات المحفوظة (Saved Registry)'),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'إعادة تحميل حية',
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
                        'أنت الآن في وضع تعديل واستكمال التقييم: ($_editingAssessmentCode) — سيتم تحديث السجل وإعادة تفعيله فور الحفظ.',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('إلغاء التعديل والبدء من جديد', style: TextStyle(color: Colors.red, fontSize: 12)),
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
              const Text(
                'نطاق ومسار المتطلبات (من إصدار ACID حتى الإبحار والشحن الفعلي):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
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
                  'حالة الإبحار: $_sailingStatus',
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
                title: 'إصدار الـ ACID',
                subtitle: _acidNumberCtrl.text.isNotEmpty ? _acidNumberCtrl.text : 'قيد الانتظار',
                isCompleted: _acidNumberCtrl.text.isNotEmpty,
                isActive: true,
              ),
              _buildStepConnector(isCompleted: _acidNumberCtrl.text.isNotEmpty),
              _buildStepNode(
                step: '2',
                title: 'فحص ومطابقة ما قبل الشحن',
                subtitle: _inspectionStatus == 'Completed' ? 'تمت المطابقة' : 'قيد الفحص والتنسيق',
                isCompleted: _inspectionStatus == 'Completed',
                isActive: true,
              ),
              _buildStepConnector(isCompleted: _inspectionStatus == 'Completed'),
              _buildStepNode(
                step: '3',
                title: 'الموافقات والشهادات',
                subtitle: _cooStatus == 'Obtained' && _whiteListVerified ? 'مستوفاة 100%' : 'قيد الاعتماد',
                isCompleted: _cooStatus == 'Obtained' && _whiteListVerified,
                isActive: true,
              ),
              _buildStepConnector(isCompleted: _sailingStatus == 'Cleared for Sailing' || _sailingStatus == 'Sailed'),
              _buildStepNode(
                step: '4',
                title: 'التصريح بالإبحار والشحن',
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
              const Text('ربط ملف الشحنة الاستيرادية والاستشارة الجمركية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              const Spacer(),
              if (_selectedConsultationCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cobalt),
                  ),
                  child: Text('دراسة الاستشارة: $_selectedConsultationCode (جاهزية ${_consultationReadiness.toInt()}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SearchableDropdownField<int?>(
                  labelText: 'ملف الشحنة المربوط (Import File) *',
                  hintText: 'اختر ملف الشحنة الاستيرادية...',
                  value: _selectedImportFileId,
                  items: [
                    const SearchableDropdownItem<int?>(value: null, label: '-- اختر ملف الشحنة --'),
                    ...importFiles.map((f) => SearchableDropdownItem<int?>(
                          value: f.importFileId,
                          label: '[${f.importFileCode}] ${f.companyName} | ACID: ${f.acidNumber ?? "لم يصدر"}',
                        )),
                  ],
                  onChanged: _onImportFileChanged,
                  validator: (v) => v == null ? 'يرجى اختيار ملف الشحنة' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _acidNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم القيد الجمركي المسبق (ACID) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب إدخال رقم ACID' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<int?>(
                  labelText: 'المورد الخارجي / المصنع (Supplier)',
                  hintText: 'المورد الأجنبي...',
                  value: _selectedSupplierId,
                  items: [
                    const SearchableDropdownItem<int?>(value: null, label: '-- غير محدد --'),
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
                'بنود التعريفة الجمركية المرتبطة بالشحنة (Linked HS Codes & Values) — ${_hsCodeItems.length} بنود مسجلة:',
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
                  'إجمالي القيمة: ${_valueCtrl.text} ${_currencyCtrl.text}',
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
                                '${itm.hsCode} (${itm.itemCode ?? "Item"})',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? AppTheme.cobalt : AppTheme.charcoal),
                              ),
                              Text(
                                '${itm.commodityDescription ?? "صنف"} | ${itm.itemValue.toStringAsFixed(2)} ${itm.currency}',
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
                  decoration: const InputDecoration(
                    labelText: 'بند التعريفة الجمركية (HS Code) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_2, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب إدخال HS Code' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'وصف السلعة / الصنف التجاري *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب إدخال وصف الصنف' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _originCtrl,
                  decoration: const InputDecoration(
                    labelText: 'بلد المنشأ والتصدير (Origin) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public, color: AppTheme.cobalt, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب إدخال بلد المنشأ' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _currencyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العملة *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _valueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'القيمة بالعملة *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on, color: AppTheme.emerald, size: 18),
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
                  _buildPillarTabButton(0, '1. قرار 43 وتسجيل المصانع', Icons.factory_outlined, _whiteListVerified),
                  _buildPillarTabButton(1, '2. شهادة المنشأ والاتفاقيات', Icons.public, _cooStatus == 'Obtained'),
                  _buildPillarTabButton(2, '3. فحص ما قبل الشحن', Icons.fact_check_outlined, _inspectionStatus == 'Completed'),
                  _buildPillarTabButton(3, '4. موافقات وتصاريح جهات العرض', Icons.account_balance_outlined, _permitStatus == 'Approved'),
                  _buildPillarTabButton(4, '5. الشهادات الفنية وتأكيد الإبحار', Icons.science_outlined, _isPostAcidConfirmed),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المحور 1: قرار 43 لسنة 2016 وتسجيل المصانع المؤهلة بالهيئة (GOEIC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('يخضع الصنف لقرار 43 لسنة 2016 (تسجيل مصانع)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('السلع تامة الصنع والمنتجات الاستهلاكية الواجب قيد مصنعها'),
                value: _decree43Applicable,
                onChanged: (v) => setState(() => _decree43Applicable = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('المصنع مسجل بالقائمة البيضاء (White List Verified)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('تم التحقق من قيد المصنع بالهيئة العامة للرقابة على الصادرات والواردات'),
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
          decoration: const InputDecoration(
            labelText: 'رقم قيد المصنع بالهيئة / Foreign Factory Registration No.',
            hintText: 'مثال: GOEIC-REG-77821 أو رقم القيد بالهيئة',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge, color: AppTheme.cobalt),
          ),
        ),
      ],
    );
  }

  // Pillar 2: Certificate of Origin
  Widget _buildPillar2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المحور 2: شهادة المنشأ والاتفاقيات التفضيلية (COO & Preferential Agreements)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CheckboxListTile(
                title: const Text('شهادة المنشأ إلزامية (COO Required)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _cooRequired,
                onChanged: (v) => setState(() => _cooRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: 'نوع شهادة المنشأ (COO Type)',
                value: _cooType,
                items: const [
                  SearchableDropdownItem(value: 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)', label: 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)'),
                  SearchableDropdownItem(value: 'Form A (النظام المعمم للمزايا GSP)', label: 'Form A (النظام المعمم للمزايا GSP)'),
                  SearchableDropdownItem(value: 'Arab League COO (منطقة التجارة العربية الكبرى GAFTA)', label: 'Arab League COO (منطقة التجارة العربية الكبرى GAFTA)'),
                  SearchableDropdownItem(value: 'COMESA (السوق المشتركة لشرق وجنوب إفريقيا)', label: 'COMESA (السوق المشتركة لشرق وجنوب إفريقيا)'),
                  SearchableDropdownItem(value: 'شهادة منشأ عادية معتمدة وموثقة من الغرفة التجارية', label: 'شهادة منشأ عادية معتمدة وموثقة من الغرفة التجارية'),
                ],
                onChanged: (v) => setState(() => _cooType = v ?? _cooType),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: 'حالة الاستيفاء (COO Status)',
                value: _cooStatus,
                items: const [
                  SearchableDropdownItem(value: 'Not Required', label: 'غير مطلوبة (Not Required)'),
                  SearchableDropdownItem(value: 'Pending', label: 'قيد الاستيفاء من المصنع (Pending)'),
                  SearchableDropdownItem(value: 'Obtained', label: 'تم الاستلام والتحقق (Obtained)'),
                  SearchableDropdownItem(value: 'Waived', label: 'معفاة / مستثناة (Waived)'),
                ],
                onChanged: (v) => setState(() => _cooStatus = v ?? _cooStatus),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _cooNotesCtrl,
          decoration: const InputDecoration(
            labelText: 'ملاحظات المنشأ والاتفاقيات التفضيلية والإعفاءات',
            hintText: 'مثال: إعفاء جمركي بنسبة 100% طبقاً لاتفاقية الشراكة الأوروبية',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // Pillar 3: Pre-Shipment Inspection
  Widget _buildPillar3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المحور 3: فحص ما قبل الشحن والشهادات المعملية (Pre-Shipment Inspection & ILAC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CheckboxListTile(
                title: const Text('شهادة الفحص إلزامية (Inspection Required)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _inspectionRequired,
                onChanged: (v) => setState(() => _inspectionRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: 'جهة الفحص الدولية المعتمدة (Inspection Body)',
                value: _inspectionBody,
                items: const [
                  SearchableDropdownItem(value: 'SGS (الشركة العامة للمعاينة)', label: 'SGS (الشركة العامة للمعاينة)'),
                  SearchableDropdownItem(value: 'Bureau Veritas (Bureau Veritas)', label: 'Bureau Veritas (Bureau Veritas)'),
                  SearchableDropdownItem(value: 'TÜV Rheinland / TÜV SÜD', label: 'TÜV Rheinland / TÜV SÜD'),
                  SearchableDropdownItem(value: 'Intertek International', label: 'Intertek International'),
                  SearchableDropdownItem(value: 'QIMA Inspection Services', label: 'QIMA Inspection Services'),
                  SearchableDropdownItem(value: 'معمل دولي معتمد ILAC / ISO 17025', label: 'معمل دولي معتمد ILAC / ISO 17025'),
                ],
                onChanged: (v) => setState(() => _inspectionBody = v ?? _inspectionBody),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: 'حالة الفحص (Inspection Status)',
                value: _inspectionStatus,
                items: const [
                  SearchableDropdownItem(value: 'Not Required', label: 'غير مطلوبة (Not Required)'),
                  SearchableDropdownItem(value: 'Pending', label: 'قيد التنسيق والطلب (Pending)'),
                  SearchableDropdownItem(value: 'Scheduled', label: 'تم تحديد موعد المعاينة (Scheduled)'),
                  SearchableDropdownItem(value: 'Completed', label: 'تم الفحص واجتياز المطابقة (Completed)'),
                  SearchableDropdownItem(value: 'Rejected', label: 'غير مطابق للمواصفات (Rejected)'),
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
                decoration: const InputDecoration(
                  labelText: 'رقم شهادة / تقرير الفحص (Inspection Report / Certificate No.)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _inspNotesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات الفحص والنتائج المعملية',
                  border: OutlineInputBorder(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المحور 4: موافقات وتصاريح جهات العرض والجهات الرقابية المسبقة (Regulatory Permits)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: CheckboxListTile(
                title: const Text('تصريح مسبق إلزامي (Permit Required)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                value: _importPermitRequired,
                onChanged: (v) => setState(() => _importPermitRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: 'جهة العرض والترخيص (Issuing Authority)',
                value: _permitIssuingAuthority,
                items: const [
                  SearchableDropdownItem(value: 'جهاز شئون البيئة (EEAA)', label: 'جهاز شئون البيئة (EEAA)'),
                  SearchableDropdownItem(value: 'الهيئة القومية لسلامة الغذاء (NFSA)', label: 'الهيئة القومية لسلامة الغذاء (NFSA)'),
                  SearchableDropdownItem(value: 'هيئة الدواء المصرية (EDA)', label: 'هيئة الدواء المصرية (EDA)'),
                  SearchableDropdownItem(value: 'الجهاز القومي لتنظيم الاتصالات (NTRA)', label: 'الجهاز القومي لتنظيم الاتصالات (NTRA)'),
                  SearchableDropdownItem(value: 'الأمن العام / مصلحة الأمن والرقابة', label: 'الأمن العام / مصلحة الأمن والرقابة'),
                  SearchableDropdownItem(value: 'مصلحة الكيمياء / الطاقة الذرية', label: 'مصلحة الكيمياء / الطاقة الذرية'),
                  SearchableDropdownItem(value: 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)', label: 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)'),
                ],
                onChanged: (v) => setState(() => _permitIssuingAuthority = v ?? _permitIssuingAuthority),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SearchableDropdownField<String>(
                labelText: 'حالة التصريح (Permit Status)',
                value: _permitStatus,
                items: const [
                  SearchableDropdownItem(value: 'Not Required', label: 'غير مطلوبة (Not Required)'),
                  SearchableDropdownItem(value: 'Applied', label: 'تم تقديم الطلب (Applied)'),
                  SearchableDropdownItem(value: 'Approved', label: 'تمت الموافقة والاعتماد (Approved)'),
                  SearchableDropdownItem(value: 'Rejected', label: 'مرفوض (Rejected)'),
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
                decoration: const InputDecoration(
                  labelText: 'رقم التصريح / الموافقة الرقابية',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _permitNotesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات وشروط الموافقة الرقابية',
                  border: OutlineInputBorder(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المحور 5: الشهادات الفنية الخاصة وتأكيد الجاهزية للإبحار (Technical Certs & Sailing Clearance)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('شهادة صحيفة بيانات الأمان (MSDS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _msdsRequired,
                onChanged: (v) => setState(() => _msdsRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('شهادة الذبح الحلال (Halal Certificate)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _halalCertRequired,
                onChanged: (v) => setState(() => _halalCertRequired = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('شهادة التحليل المخبري (COA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  labelText: 'حالة الإبحار والشحن الفعلي (Sailing Status)',
                  value: _sailingStatus,
                  items: const [
                    SearchableDropdownItem(value: 'Pre-Sailing', label: 'قبل الإبحار (Pre-Sailing)'),
                    SearchableDropdownItem(value: 'Cleared for Sailing', label: 'مصرح وجاهز للإبحار (Cleared for Sailing)'),
                    SearchableDropdownItem(value: 'Sailed', label: 'تم الإبحار والشحن الفعلي (Sailed)'),
                  ],
                  onChanged: (v) => setState(() => _sailingStatus = v ?? _sailingStatus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _sailingDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الإبحار الفعلي / المتوقع (Sailing Date)',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_boat, color: AppTheme.cobalt, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  labelText: 'تقييم المخاطر (Risk Level)',
                  value: _riskLevel,
                  items: const [
                    SearchableDropdownItem(value: 'Low', label: 'منخفض (Low)'),
                    SearchableDropdownItem(value: 'Medium', label: 'متوسط (Medium)'),
                    SearchableDropdownItem(value: 'High', label: 'مرتفع (High)'),
                  ],
                  onChanged: (v) => setState(() => _riskLevel = v ?? _riskLevel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  labelText: 'الحالة الإجمالية (Overall Status)',
                  value: _overallStatus,
                  items: const [
                    SearchableDropdownItem(value: 'Draft', label: 'مسودة (Draft)'),
                    SearchableDropdownItem(value: 'In Progress', label: 'قيد الاستيفاء (In Progress)'),
                    SearchableDropdownItem(value: 'Complete', label: 'مكتمل (Complete)'),
                    SearchableDropdownItem(value: 'Confirmed', label: 'معتمد ومصرح للشحن (Confirmed)'),
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
            label: const Text('استيفاء وتأكيد كافة المحاور ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
            label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            label: const Text('تفريغ وبدء تسجيل جديد 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            label: const Text('حفظ مؤقت ومتابعة لاحقة 💾', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
              _editingAssessmentId != null ? 'تحديث وحفظ التعديلات' : 'حفظ واعتماد التقييم التأكيدي',
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
                    decoration: const InputDecoration(
                      hintText: 'بحث برقم التقييم، البند الجمركي HS Code، رقم الـ ACID، المورد، أو الوصف...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.cobalt),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: 'حالة المطابقة',
                    value: _registryStatusFilter,
                    items: const [
                      SearchableDropdownItem(value: 'All', label: 'كافة الحالات (All)'),
                      SearchableDropdownItem(value: 'Draft', label: 'مسودة (Draft)'),
                      SearchableDropdownItem(value: 'In Progress', label: 'قيد الاستيفاء (In Progress)'),
                      SearchableDropdownItem(value: 'Complete', label: 'مكتمل (Complete)'),
                      SearchableDropdownItem(value: 'Confirmed', label: 'معتمد ومصرح للشحن (Confirmed)'),
                    ],
                    onChanged: (v) => setState(() => _registryStatusFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: 'مستوى المخاطر',
                    value: _registryRiskFilter,
                    items: const [
                      SearchableDropdownItem(value: 'All', label: 'كافة المستويات (All)'),
                      SearchableDropdownItem(value: 'Low', label: 'منخفض (Low)'),
                      SearchableDropdownItem(value: 'Medium', label: 'متوسط (Medium)'),
                      SearchableDropdownItem(value: 'High', label: 'مرتفع (High)'),
                    ],
                    onChanged: (v) => setState(() => _registryRiskFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: 'السجلات النشطة / المحذوفة',
                    value: _registryActiveFilter,
                    items: const [
                      SearchableDropdownItem(value: 'All', label: 'كافة السجلات (النشطة والمحذوفة)'),
                      SearchableDropdownItem(value: 'Active', label: 'النشطة فقط (Active)'),
                      SearchableDropdownItem(value: 'Deleted', label: 'المحذوفة فقط (Deleted)'),
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
                child: Text('خطأ في تحميل سجلات التقييم: $err', style: const TextStyle(color: Colors.red)),
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
                        const Text('لا توجد تقييمات مسجلة مطابقة للبحث الحالي.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                          onPressed: () => _mainTabController.animateTo(0),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('إنشاء دراسة تقييم جديدة', style: TextStyle(color: Colors.white)),
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
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final matchingFile = importFiles.where((f) => f.importFileId == req.importFileId).firstOrNull;
    final fileCode = matchingFile?.customFileNumber ?? matchingFile?.importFileCode ?? req.importFileCode ?? (req.importFileId != null ? 'IMP-${req.importFileId}' : '');
    final companyName = (matchingFile?.companyName.isNotEmpty == true && matchingFile?.companyName != 'N/A')
        ? matchingFile!.companyName
        : 'الشركة المستوردة';
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
              child: const Text('محذوف منطقياً (Soft Deleted)', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'البند الجمركي: ${req.hsCode ?? "N/A"} — ${req.commodityDescription ?? ""} | القيمة: ${req.shipmentValue.toStringAsFixed(2)} ${req.currency} | المورد: ${req.supplierName ?? "N/A"} (${req.countryOfOrigin ?? "N/A"})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildBadge('حالة الإبحار: ${req.sailingStatus}', _getStatusColor(req.sailingStatus)),
                _buildBadge('الحالة: ${req.overallStatus}', _getStatusColor(req.overallStatus)),
                _buildBadge('المخاطر: ${req.riskLevel}', _getRiskLevelColor(req.riskLevel)),
                if (req.hsCodeItems.isNotEmpty)
                  _buildBadge('${req.hsCodeItems.length} بنود HS', AppTheme.cobalt),
                if (req.decree43Applicable && req.whiteListVerified)
                  _buildBadge('قرار 43 معتمد', AppTheme.emerald),
                if (req.cooRequired && req.cooStatus == 'Obtained')
                  _buildBadge('منشأ مستوفى', AppTheme.emerald),
                if (req.inspectionRequired && req.inspectionStatus == 'Completed')
                  _buildBadge('فحص SGS مجتاز', AppTheme.emerald),
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
            tooltip: 'تعديل واستكمال التقييم وإعادة تفعيله',
            onPressed: () => _loadAssessmentForEditing(req),
          ),
          // Restore Button if inactive
          if (!req.isActive)
            IconButton(
              icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald),
              tooltip: 'استعادة وتفعيل التقييم',
              onPressed: () async {
                if (req.assessmentId != null) {
                  await ref.read(importRequirementsProvider.notifier).restoreRequirement(req.assessmentId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('♻️ تم استعادة التقييم (${req.assessmentCode}) بنجاح!'), backgroundColor: AppTheme.emerald),
                    );
                  }
                }
              },
            ),
          // Delete Button
          if (req.isActive)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'حذف منطقي',
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف المنطقي للتقييم'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف تقييم المتطلبات (${req.assessmentCode}) للملف (${req.importFileCode})؟\n\nيمكنك استعادته أو إعادة تفعيله في أي وقت من خلال تعديله أو عبر زر الاستعادة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              if (req.assessmentId != null) {
                await ref.read(importRequirementsProvider.notifier).deleteRequirement(req.assessmentId!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🗑️ تم حذف التقييم (${req.assessmentCode}) منطقياً.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
