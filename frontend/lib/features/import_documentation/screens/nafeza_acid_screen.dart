import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';

class NafezaAcidScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const NafezaAcidScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<NafezaAcidScreen> createState() => _NafezaAcidScreenState();
}

class _NafezaAcidScreenState extends ConsumerState<NafezaAcidScreen> {
  // Active Vertical Sub-Tab:
  // 0: 📝 طلب إصدار ACID (Request Form)
  // 1: ⚡ الإدخال الذكي من نافذة (MTS Smart Parser)
  // 2: 🔍 المقارنة والتحقق الجمركي (Discrepancy Matrix)
  // 3: 📋 سجل إصدارات ACID (Registry)
  // 4: ⏳ متتبع الصلاحية والإفراج (Expiry Tracker)
  int _selectedSubTab = 0;

  // Selected Import File
  int? _selectedImportFileId;

  // Controllers for Tab 0 (ACID Request)
  final _requestFormKey = GlobalKey<FormState>();
  final TextEditingController _acidNumberCtrl = TextEditingController(text: 'ACID-EG-2026-');
  int? _selectedImporterId;
  final TextEditingController _importerNameCtrl = TextEditingController();
  final TextEditingController _importerTaxIdCtrl = TextEditingController();
  final TextEditingController _importerAddressCtrl = TextEditingController();

  int? _selectedSupplierId;
  final TextEditingController _exporterNameCtrl = TextEditingController();
  String _exporterRegType = 'VAT Number';
  final TextEditingController _exporterRegIdCtrl = TextEditingController();
  final TextEditingController _exporterCountryCtrl = TextEditingController();
  final TextEditingController _exporterCountryCodeCtrl = TextEditingController();
  final TextEditingController _exporterAddressCtrl = TextEditingController();
  final TextEditingController _exporterPhoneCtrl = TextEditingController();
  final TextEditingController _cargoxIdCtrl = TextEditingController();

  int? _selectedPoId;
  final TextEditingController _poNoCtrl = TextEditingController();
  final TextEditingController _poDateCtrl = TextEditingController();
  final TextEditingController _proformaNoCtrl = TextEditingController();
  final TextEditingController _proformaDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  String _invoiceType = 'Proforma Invoice';

  final TextEditingController _polCtrl = TextEditingController(text: 'Shanghai Port (CNSHA)');
  final TextEditingController _podCtrl = TextEditingController(text: 'Alexandria Port (EG ALX)');

  int? _selectedBrokerId;
  final TextEditingController _brokerNameCtrl = TextEditingController();
  final TextEditingController _brokerPhoneCtrl = TextEditingController();

  final TextEditingController _requestedDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));

  // Controllers for Tab 1 (Smart MTS Parser)
  final TextEditingController _rawMtsTextCtrl = TextEditingController();
  Map<String, dynamic>? _parsedMtsData;
  bool _isParsingMts = false;

  // Tab 2 (Comparison Result)
  AcidComparisonResult? _comparisonResult;
  bool _isComparing = false;
  final TextEditingController _discrepancyOverrideReasonCtrl = TextEditingController();

  // Tab 3 (Registry & Final Save)
  String _acidSearchQuery = '';
  final TextEditingController _generatedDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _expiryDateCtrl = TextEditingController(
    text: DateTime.now().add(const Duration(days: 90)).toString().substring(0, 10),
  );

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(importCompaniesProvider.notifier).fetchCompanies();
    ref.read(suppliersProvider.notifier).fetchSuppliers();
    ref.read(partnersProvider.notifier).fetchPartners();
    ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
    ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
  }

  @override
  void dispose() {
    _acidNumberCtrl.dispose();
    _importerNameCtrl.dispose();
    _importerTaxIdCtrl.dispose();
    _importerAddressCtrl.dispose();
    _exporterNameCtrl.dispose();
    _exporterRegIdCtrl.dispose();
    _exporterCountryCtrl.dispose();
    _exporterCountryCodeCtrl.dispose();
    _exporterAddressCtrl.dispose();
    _exporterPhoneCtrl.dispose();
    _cargoxIdCtrl.dispose();
    _poNoCtrl.dispose();
    _poDateCtrl.dispose();
    _proformaNoCtrl.dispose();
    _proformaDateCtrl.dispose();
    _polCtrl.dispose();
    _podCtrl.dispose();
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _requestedDateCtrl.dispose();
    _rawMtsTextCtrl.dispose();
    _discrepancyOverrideReasonCtrl.dispose();
    _generatedDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  void _onImportFileChanged(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) return;

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    // Importer
    final companies = ref.read(importCompaniesProvider).value ?? [];
    final matchedComp = companies.where((c) => c.companyId == file.companyId).firstOrNull;
    if (matchedComp != null) {
      _selectedImporterId = matchedComp.companyId;
      _importerNameCtrl.text = matchedComp.importerName;
      _importerTaxIdCtrl.text = matchedComp.vatId;
      _importerAddressCtrl.text = matchedComp.address;
    }

    // Exporter
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final matchedSupp = suppliers.where((s) => s.supplierId == file.supplierId).firstOrNull;
    if (matchedSupp != null) {
      _selectedSupplierId = matchedSupp.supplierId;
      _exporterNameCtrl.text = matchedSupp.companyName;
      _exporterCountryCtrl.text = matchedSupp.foreignExporterCountry;
      _exporterAddressCtrl.text = matchedSupp.address;
      _exporterPhoneCtrl.text = matchedSupp.phone ?? '';
      _cargoxIdCtrl.text = matchedSupp.cargoxPlatformId ?? '';
      _exporterRegIdCtrl.text = matchedSupp.foreignExporterId;
    }

    // Broker
    final partners = ref.read(partnersProvider).value ?? [];
    final matchedBroker = partners.where((p) => p.providerId == file.brokerId).firstOrNull;
    if (matchedBroker != null) {
      _selectedBrokerId = matchedBroker.providerId;
      _brokerNameCtrl.text = matchedBroker.partnerName;
      _brokerPhoneCtrl.text = matchedBroker.phone ?? '';
    }

    // PO
    final pos = ref.read(purchaseOrdersProvider).purchaseOrders;
    final matchedPo = pos.where((p) => p.importFileId == fileId).firstOrNull;
    if (matchedPo != null) {
      _selectedPoId = matchedPo.poId;
      _poNoCtrl.text = matchedPo.poNumber;
      _poDateCtrl.text = matchedPo.orderDate != null ? matchedPo.orderDate!.toIso8601String().substring(0, 10) : '';
      _proformaNoCtrl.text = 'PI-${matchedPo.poNumber}';
    } else {
      _poNoCtrl.text = 'PO-${file.importFileCode}';
      _proformaNoCtrl.text = 'PI-${file.importFileCode}';
    }

    _polCtrl.text = 'Shanghai Port (CNSHA)';
    _podCtrl.text = 'Alexandria Port (EG ALX)';
  }

  @override
  Widget build(BuildContext context) {
    final acidSessions = ref.watch(acidSessionsProvider).value ?? [];
    final trackerSummary = ref.watch(acidTrackerProvider).value;
    final trackerItems = trackerSummary?.items ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.assignment_turned_in_outlined,
        titleEn: 'ACID Request Form',
        titleAr: 'طلب إصدار الرقم المبدئي',
      ),
      const VerticalNavTabItem(
        icon: Icons.smart_toy_outlined,
        titleEn: 'MTS Smart AI Parser',
        titleAr: 'الإدخال الذكي من نافذة',
      ),
      VerticalNavTabItem(
        icon: Icons.rule_folder_outlined,
        titleEn: 'Discrepancy Matrix',
        titleAr: 'المقارنة والتحقق الجمركي',
        badge: _comparisonResult != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _comparisonResult!.allMatched ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _comparisonResult!.allMatched ? 'مطابق' : 'فروق',
                  style: TextStyle(
                    color: _comparisonResult!.allMatched ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
      VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'ACID Issuance Registry',
        titleAr: 'سجل إصدارات ACID',
        badge: acidSessions.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${acidSessions.length}',
                  style: const TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      VerticalNavTabItem(
        icon: Icons.timer_outlined,
        titleEn: 'Expiry & Release Tracker',
        titleAr: 'متتبع الصلاحية والإفراج',
        badge: trackerItems.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${trackerItems.length}',
                  style: const TextStyle(color: AppTheme.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Nafeza Advance Cargo Information (ACID)',
      titleAr: 'منظومة نافذة والتسجيل المسبق للشحنات',
      headerIcon: Icons.qr_code_scanner_outlined,
      headerColor: AppTheme.charcoal,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (index) {
        setState(() => _selectedSubTab = index);
        if (index == 3) {
          ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
        } else if (index == 4) {
          ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث البيانات (Refresh)',
          onPressed: _refreshData,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildCurrentSubTabContent(),
      ),
    );
  }

  Widget _buildCurrentSubTabContent() {
    switch (_selectedSubTab) {
      case 0:
        return _buildAcidRequestTab();
      case 1:
        return _buildSmartMtsParserTab();
      case 2:
        return _buildDiscrepancyMatrixTab();
      case 3:
        return _buildAcidSessionsRegistryTab();
      case 4:
        return _buildExpiryTrackerTab();
      default:
        return _buildAcidRequestTab();
    }
  }

  // --- SUB-VIEW 0: ACID REQUEST FORM ---
  Widget _buildAcidRequestTab() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final importCompanies = ref.watch(importCompaniesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];
    final partners = ref.watch(partnersProvider).value ?? [];
    final brokers = partners.where((p) => p.partnerType.contains('Broker') || p.partnerType.contains('مخلص')).toList();

    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informational Alert
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.cobalt, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تسجيل طلب استخراج رقم القيد الجمركي المبدئي (ACID) وفق متطلبات مصلحة الجمارك المصرية ومنظومة نافذة (MTS). اختر ملف الشحنة لتحميل بيانات المستورد والمورد الأجنبي تلقائياً.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // File Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SearchableDropdownField<int>(
              labelText: 'اختر ملف الشحنة لطلب ACID (Select Import File)',
              hintText: 'ابحث برقم الملف أو اسم المورد أو الشركة...',
              value: _selectedImportFileId,
              isRequired: true,
              items: importFiles.map((f) => SearchableDropdownItem<int>(
                value: f.importFileId,
                label: '${f.importFileCode} — ${f.supplierName} (${f.companyName})',
              )).toList(),
              onChanged: _onImportFileChanged,
            ),
          ),
          const SizedBox(height: 20),

          // Importer & Exporter Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. بيانات المستورد والمصدر الأجنبي (Importer & Exporter Parties):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Importer Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏢 الشركة المستوردة (Importer):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          SearchableDropdownField<int>(
                            labelText: 'الشركة المستوردة (Importer Company)',
                            hintText: 'اختر الشركة المستوردة...',
                            value: _selectedImporterId,
                            isRequired: true,
                            items: importCompanies.map((c) => SearchableDropdownItem<int>(
                              value: c.companyId ?? 0,
                              label: '${c.importerName} (${c.importerId})',
                            )).toList(),
                            onChanged: (val) {
                              setState(() => _selectedImporterId = val);
                              final c = importCompanies.where((comp) => comp.companyId == val).firstOrNull;
                              if (c != null) {
                                _importerNameCtrl.text = c.importerName;
                                _importerTaxIdCtrl.text = c.vatId;
                                _importerAddressCtrl.text = c.address;
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _importerTaxIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'الرقم الضريبي للمستورد (Tax ID) *',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _importerAddressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'عنوان المستورد المسجل بنافذة',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Exporter Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🌍 المصدر الأجنبي (Foreign Exporter):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          SearchableDropdownField<int>(
                            labelText: 'المورد الأجنبي (Foreign Exporter / Supplier)',
                            hintText: 'اختر المورد الأجنبي...',
                            value: _selectedSupplierId,
                            isRequired: true,
                            items: suppliers.map((s) => SearchableDropdownItem<int>(
                              value: s.supplierId ?? 0,
                              label: '${s.companyName} (${s.foreignExporterCountry})',
                            )).toList(),
                            onChanged: (val) {
                              setState(() => _selectedSupplierId = val);
                              final s = suppliers.where((supp) => supp.supplierId == val).firstOrNull;
                              if (s != null) {
                                _exporterNameCtrl.text = s.companyName;
                                _exporterCountryCtrl.text = s.foreignExporterCountry;
                                _exporterAddressCtrl.text = s.address;
                                _exporterPhoneCtrl.text = s.phone ?? '';
                                _cargoxIdCtrl.text = s.cargoxPlatformId ?? '';
                                _exporterRegIdCtrl.text = s.foreignExporterId;
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _exporterRegIdCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'رقم السجل / الضريبي بالخارج *',
                                    helperText: _exporterRegType,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _exporterRegType,
                                  decoration: const InputDecoration(labelText: 'نوع التسجيل', border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: 'VAT Number', child: Text('VAT')),
                                    DropdownMenuItem(value: 'Commercial Register', child: Text('CR')),
                                    DropdownMenuItem(value: 'Tax ID', child: Text('Tax ID')),
                                    DropdownMenuItem(value: 'DUNS Number', child: Text('DUNS')),
                                  ],
                                  onChanged: (val) => setState(() => _exporterRegType = val ?? 'VAT Number'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _exporterCountryCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'دولة المنشأ / التصدير *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _cargoxIdCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'CargoX Platform ID',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Invoice, Ports & Broker Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. بيانات الفاتورة المبدئية والموانئ والمخلص (Proforma, Ports & Broker):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _proformaNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم الفاتورة المبدئية (PI Number) *',
                          prefixIcon: Icon(Icons.receipt_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _proformaDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الفاتورة (PI Date) *',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _invoiceType,
                        decoration: const InputDecoration(labelText: 'نوع الفاتورة المقدمة', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Proforma Invoice', child: Text('فاتورة مبدئية (Proforma)')),
                          DropdownMenuItem(value: 'Commercial Invoice', child: Text('فاتورة تجارية نهائية')),
                        ],
                        onChanged: (val) => setState(() => _invoiceType = val ?? 'Proforma Invoice'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _polCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ميناء الشحن (Port of Loading - POL) *',
                          prefixIcon: Icon(Icons.directions_boat_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _podCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ميناء الوصول الجمركي بمصر (POD) *',
                          prefixIcon: Icon(Icons.anchor),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SearchableDropdownField<int>(
                        labelText: 'المخلص الجمركي المسؤول (Customs Broker)',
                        hintText: 'اختر المخلص الجمركي...',
                        value: _selectedBrokerId,
                        items: brokers.map((b) => SearchableDropdownItem<int>(
                          value: b.providerId ?? 0,
                          label: '${b.partnerName} (${b.partnerCode})',
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedBrokerId = val);
                          final b = brokers.where((brk) => brk.providerId == val).firstOrNull;
                          if (b != null) {
                            _brokerNameCtrl.text = b.partnerName;
                            _brokerPhoneCtrl.text = b.phone ?? '';
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _brokerPhoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'هاتف المخلص للتواصل',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _requestedDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ تقديم الطلب بنافذة *',
                          prefixIcon: Icon(Icons.event_available),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.charcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveAcidRequest,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'جارٍ الحفظ...' : 'حفظ بيانات الطلب وإرسالها للمطابقة',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      onPressed: () => setState(() => _selectedSubTab = 1),
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('الانتقال للإدخال الذكي من نافذة (MTS Parser)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW 1: SMART MTS PARSER TAB ---
  Widget _buildSmartMtsParserTab() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.teal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'المحلل الذكي لنصوص نافذة (MTS Smart Parser): الصق النص الخام المستلم من إشعار نافذة أو البريد الإلكتروني. سيقوم النظام باستخراج رقم ACID، تاريخ الصلاحية، بيانات المصدر والمستورد تلقائياً وبدقة 100%.',
                  style: TextStyle(color: Colors.teal.shade900, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        // File Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SearchableDropdownField<int>(
            labelText: 'ربط بنتيجة ملف شحنة (Select Import File)',
            hintText: 'اختر ملف الشحنة المرتبط...',
            value: _selectedImportFileId,
            items: importFiles.map((f) => SearchableDropdownItem<int>(
              value: f.importFileId,
              label: '${f.importFileCode} — ${f.supplierName}',
            )).toList(),
            onChanged: (val) => setState(() => _selectedImportFileId = val),
          ),
        ),
        const SizedBox(height: 20),

        // Raw Text Input Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('الصق نص إشعار نافذة الخام هنا (Raw Nafeza MTS Text):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _rawMtsTextCtrl.text = data!.text!;
                      }
                    },
                    icon: const Icon(Icons.paste, size: 16),
                    label: const Text('لصق من الحافظة'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _rawMtsTextCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'مثال:\nتم إصدار رقم القيد الجمركي المبدئي للشحنة بنجاح.\nرقم ACID: 202684920194857\nتاريخ الإصدار: 2026-08-17\nتاريخ الصلاحية: 2026-11-17\nاسم المستورد: ...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _isParsingMts ? null : _parseMtsText,
                    icon: _isParsingMts
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bolt),
                    label: Text(_isParsingMts ? 'جارٍ التحليل...' : 'تشغيل المحلل الذكي واستخراج البيانات', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _rawMtsTextCtrl.clear(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('مسح النص'),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_parsedMtsData != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade300, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.teal, size: 22),
                    const SizedBox(width: 8),
                    const Text('البيانات المستخرجة بنجاح من نص نافذة (Parsed MTS Result):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _selectedSubTab = 2),
                      icon: const Icon(Icons.compare_arrows, size: 16),
                      label: const Text('الانتقال للمطابقة والتحقق'),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    _buildExtractedField('رقم ACID', _parsedMtsData!['acid_number']?.toString() ?? 'غير محدد'),
                    _buildExtractedField('تاريخ الإصدار', _parsedMtsData!['generated_date']?.toString() ?? '-'),
                    _buildExtractedField('تاريخ الانتهاء', _parsedMtsData!['expiry_date']?.toString() ?? '-'),
                    _buildExtractedField('المستورد المستخرج', _parsedMtsData!['importer_name']?.toString() ?? '-'),
                    _buildExtractedField('المصدر الأجنبي', _parsedMtsData!['exporter_name']?.toString() ?? '-'),
                    _buildExtractedField('الفاتورة', _parsedMtsData!['proforma_invoice_no']?.toString() ?? '-'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExtractedField(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
        ],
      ),
    );
  }

  // --- SUB-VIEW 2: DISCREPANCY MATRIX TAB ---
  Widget _buildDiscrepancyMatrixTab() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File Selector & Compare Trigger
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: SearchableDropdownField<int>(
                  labelText: 'اختر ملف الشحنة للتحقق والمطابقة الجمركية',
                  hintText: 'اختر الملف...',
                  value: _selectedImportFileId,
                  items: importFiles.map((f) => SearchableDropdownItem<int>(
                    value: f.importFileId,
                    label: '${f.importFileCode} — ${f.supplierName}',
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: _isComparing ? null : _runComparison,
                icon: _isComparing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.compare_arrows),
                label: const Text('تشغيل مصفوفة المطابقة الفورية (Compare)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_comparisonResult != null) ...[
          // Discrepancy Matrix Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _comparisonResult!.allMatched ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _comparisonResult!.allMatched ? Colors.green : Colors.red,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _comparisonResult!.allMatched
                              ? 'المطابقة الجمركية كاملة بنسبة 100% (No Discrepancies)'
                              : 'يوجد عدم تطابق في بعض الحقول الجمركية الأساسية!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _comparisonResult!.allMatched ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        Text(
                          'نسبة التطابق: ${_comparisonResult!.matchPercentage.toStringAsFixed(1)}% — الحقول المتطابقة: ${_comparisonResult!.matchedCount} من ${_comparisonResult!.totalComparedFields}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                Table(
                  border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(padding: EdgeInsets.all(10), child: Text('الحقل الجمركي', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('البيان المطلوب (النظام)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('البيان الصادر (نافذة)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('حالة المطابقة', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ..._comparisonResult!.items.map((item) {
                      return TableRow(
                        decoration: BoxDecoration(color: item.isMatched ? Colors.white : Colors.red.shade50.withOpacity(0.5)),
                        children: [
                          Padding(padding: const EdgeInsets.all(10), child: Text(item.labelAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(10), child: Text(item.requestedValue, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(10), child: Text(item.generatedValue, style: const TextStyle(fontSize: 12))),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Icon(item.isMatched ? Icons.check_circle : Icons.cancel, size: 16, color: item.isMatched ? Colors.green : Colors.red),
                                const SizedBox(width: 4),
                                Text(item.isMatched ? 'مطابق' : 'فروق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.isMatched ? Colors.green : Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Approval & Override
                if (!_comparisonResult!.allMatched) ...[
                  const Text('ملاحظات وتبرير اعتماد الفروق (Discrepancy Override Justification):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _discrepancyOverrideReasonCtrl,
                    decoration: const InputDecoration(
                      hintText: 'اكتب سبب التجاوز أو التعديل لاعتماد رقم ACID رغم وجود الفروق...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _comparisonResult!.allMatched ? Colors.green : AppTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  ),
                  onPressed: _isSaving ? null : _saveVerifiedAcid,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.verified),
                  label: Text(_isSaving ? 'جارٍ الاعتماد...' : 'اعتماد وتثبيت رقم ACID بملف الشحنة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- SUB-VIEW 3: ACID REGISTRY TAB ---
  Widget _buildAcidSessionsRegistryTab() {
    final acidSessions = ref.watch(acidSessionsProvider).value ?? [];
    final filtered = acidSessions.where((s) {
      if (_acidSearchQuery.isEmpty) return true;
      return s.acidNumber.toLowerCase().contains(_acidSearchQuery.toLowerCase()) ||
          (s.importFileCode != null && s.importFileCode!.toLowerCase().contains(_acidSearchQuery.toLowerCase())) ||
          s.exporterName.toLowerCase().contains(_acidSearchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث في سجل أرقام ACID برقم القيد، المورد، رقم الملف...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _acidSearchQuery = val),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: () => setState(() => _selectedSubTab = 0),
              icon: const Icon(Icons.add),
              label: const Text('طلب ACID جديد'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('رقم ACID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('رقم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الشركة المستوردة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ الإصدار', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filtered.map((s) {
              final dateStr = s.generatedDate ?? s.requestedDate ?? '';
              final expStr = s.expiryDate ?? '';
              return DataRow(
                cells: [
                  DataCell(Text(s.acidNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                  DataCell(Text(s.importFileCode ?? '-')),
                  DataCell(Text(s.exporterName)),
                  DataCell(Text(s.importerName)),
                  DataCell(Text(dateStr.isNotEmpty ? dateStr.substring(0, min(10, dateStr.length)) : '-')),
                  DataCell(Text(expStr.isNotEmpty ? expStr.substring(0, min(10, expStr.length)) : '-')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.status == 'Issued' ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: s.status == 'Issued' ? Colors.green.shade300 : Colors.blue.shade300),
                      ),
                      child: Text(
                        s.status == 'Issued' ? 'صادر وساري' : 'قيد المراجعة',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.status == 'Issued' ? Colors.green.shade800 : Colors.blue.shade800),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- SUB-VIEW 4: EXPIRY TRACKER TAB ---
  Widget _buildExpiryTrackerTab() {
    final trackerSummary = ref.watch(acidTrackerProvider).value;
    final trackerItems = trackerSummary?.items ?? [];

    final filtered = trackerItems.where((t) {
      if (_acidSearchQuery.isEmpty) return true;
      return t.acidNumber.toLowerCase().contains(_acidSearchQuery.toLowerCase()) ||
          (t.importFileCode != null && t.importFileCode!.toLowerCase().contains(_acidSearchQuery.toLowerCase())) ||
          t.supplierName.toLowerCase().contains(_acidSearchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            _buildTrackerCard(
              title: 'إجمالي أرقام ACID',
              count: trackerSummary?.totalAcidsCount ?? trackerItems.length,
              color: AppTheme.charcoal,
              icon: Icons.qr_code,
            ),
            const SizedBox(width: 14),
            _buildTrackerCard(
              title: 'ساري (> 14 يوم)',
              count: trackerSummary?.validCount ?? trackerItems.where((t) => t.status != 'Expired' && t.daysRemaining > 14).length,
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 14),
            _buildTrackerCard(
              title: 'أوشك على الانتهاء (≤ 14 يوم)',
              count: trackerSummary?.expiringSoonCount ?? trackerItems.where((t) => t.status != 'Expired' && t.daysRemaining <= 14 && t.daysRemaining > 0).length,
              color: AppTheme.orange,
              icon: Icons.warning_amber,
            ),
            const SizedBox(width: 14),
            _buildTrackerCard(
              title: 'منتهي الصلاحية',
              count: trackerSummary?.expiredCount ?? trackerItems.where((t) => t.status == 'Expired' || t.daysRemaining <= 0).length,
              color: AppTheme.crimson,
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'بحث في متتبع الصلاحيات والإفراج الجمركي...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (val) => setState(() => _acidSearchQuery = val),
        ),
        const SizedBox(height: 16),

        // Tracker Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('رقم ACID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('رقم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ الانتهاء', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الأيام المتبقية', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('حالة الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filtered.map((t) {
              final days = t.daysRemaining;
              final isExp = t.status == 'Expired' || days <= 0;
              final isWarning = !isExp && days <= 14;

              final expDate = t.acidExpiryDate ?? '';
              return DataRow(
                cells: [
                  DataCell(Text(t.acidNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                  DataCell(Text(t.importFileCode ?? '-')),
                  DataCell(Text(t.supplierName)),
                  DataCell(Text(expDate.length >= 10 ? expDate.substring(0, 10) : expDate)),
                  DataCell(Text('$days يوم', style: TextStyle(fontWeight: FontWeight.bold, color: isExp ? Colors.red : isWarning ? Colors.orange : Colors.green))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExp ? Colors.red.shade50 : isWarning ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isExp ? Colors.red.shade300 : isWarning ? Colors.orange.shade300 : Colors.green.shade300),
                      ),
                      child: Text(
                        isExp ? 'منتهي الصلاحية ⛔' : isWarning ? 'أوشك على الانتهاء ⚠️' : 'ساري وصالح ✅',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isExp ? Colors.red.shade900 : isWarning ? Colors.orange.shade900 : Colors.green.shade900,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS ---
  Future<void> _saveAcidRequest() async {
    if (!_requestFormKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'importer_id': _selectedImporterId,
        'importer_name': _importerNameCtrl.text.trim(),
        'importer_tax_id': _importerTaxIdCtrl.text.trim(),
        'importer_address': _importerAddressCtrl.text.trim(),
        'supplier_id': _selectedSupplierId,
        'exporter_name': _exporterNameCtrl.text.trim(),
        'exporter_reg_type': _exporterRegType,
        'exporter_reg_id': _exporterRegIdCtrl.text.trim(),
        'exporter_country': _exporterCountryCtrl.text.trim(),
        'exporter_address': _exporterAddressCtrl.text.trim(),
        'exporter_phone': _exporterPhoneCtrl.text.trim(),
        'cargox_id': _cargoxIdCtrl.text.trim(),
        'po_id': _selectedPoId,
        'po_number': _poNoCtrl.text.trim(),
        'proforma_invoice_no': _proformaNoCtrl.text.trim(),
        'proforma_invoice_date': _proformaDateCtrl.text.trim(),
        'invoice_type': _invoiceType,
        'pol_name': _polCtrl.text.trim(),
        'pod_name': _podCtrl.text.trim(),
        'customs_broker_id': _selectedBrokerId,
        'customs_broker_name': _brokerNameCtrl.text.trim(),
        'customs_broker_phone': _brokerPhoneCtrl.text.trim(),
        'requested_date': _requestedDateCtrl.text.trim(),
      };

      await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل وحفظ طلب ACID بنجاح'), backgroundColor: AppTheme.emerald),
        );
        setState(() => _selectedSubTab = 1);
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في حفظ طلب ACID', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _parseMtsText() async {
    final raw = _rawMtsTextCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى لصق نص نافذة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isParsingMts = true);
    try {
      final result = await ref.read(acidSessionsProvider.notifier).parseAcidText(raw, importFileId: _selectedImportFileId);
      setState(() => _parsedMtsData = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحليل نص نافذة واستخراج البيانات بنجاح'), backgroundColor: AppTheme.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في تحليل نص نافذة', error: e);
      }
    } finally {
      if (mounted) setState(() => _isParsingMts = false);
    }
  }

  Future<void> _runComparison() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة للتحقق'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isComparing = true);
    try {
      final requestedData = {
        'import_file_id': _selectedImportFileId,
        'importer_name': _importerNameCtrl.text,
        'importer_tax_id': _importerTaxIdCtrl.text,
        'exporter_name': _exporterNameCtrl.text,
        'exporter_reg_id': _exporterRegIdCtrl.text,
        'proforma_invoice_no': _proformaNoCtrl.text,
      };
      final generatedData = _parsedMtsData ?? {};

      final res = await ref.read(acidSessionsProvider.notifier).compareAcid(requestedData, generatedData);
      setState(() => _comparisonResult = res);
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في المقارنة الجمركية', error: e);
      }
    } finally {
      if (mounted) setState(() => _isComparing = false);
    }
  }

  Future<void> _saveVerifiedAcid() async {
    if (_selectedImportFileId == null) return;
    setState(() => _isSaving = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'acid_number': _parsedMtsData?['acid_number'] ?? _acidNumberCtrl.text.trim(),
        'generated_date': _parsedMtsData?['generated_date'] ?? _generatedDateCtrl.text.trim(),
        'expiry_date': _parsedMtsData?['expiry_date'] ?? _expiryDateCtrl.text.trim(),
        'importer_name': _importerNameCtrl.text.trim(),
        'importer_tax_id': _importerTaxIdCtrl.text.trim(),
        'exporter_name': _exporterNameCtrl.text.trim(),
        'exporter_reg_id': _exporterRegIdCtrl.text.trim(),
        'exporter_country': _exporterCountryCtrl.text.trim(),
        'proforma_invoice_no': _proformaNoCtrl.text.trim(),
        'pol_name': _polCtrl.text.trim(),
        'pod_name': _podCtrl.text.trim(),
        'status': 'Issued',
        'is_verified': true,
        'discrepancy_override_reason': _discrepancyOverrideReasonCtrl.text.trim(),
      };

      await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم اعتماد وتثبيت رقم ACID بنجاح ✅'), backgroundColor: AppTheme.emerald),
        );
        setState(() => _selectedSubTab = 3);
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في اعتماد رقم ACID', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
