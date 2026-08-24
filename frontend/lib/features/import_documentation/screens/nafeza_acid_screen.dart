import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/models/supplier_model.dart';
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
  int? _editingAcidSessionId;
  String? _editingAcidCode;
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _onImportFileChanged(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) {
      setState(() {
        _editingAcidSessionId = null;
        _editingAcidCode = null;
      });
      return;
    }

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    // Check if an existing ACID session exists for this import file
    final sessions = ref.read(acidSessionsProvider).value ?? [];
    final existingSession = sessions.where((s) => s.importFileId == fileId && s.isActive).firstOrNull;
    if (existingSession != null) {
      _editingAcidSessionId = existingSession.acidId;
      _editingAcidCode = existingSession.acidCode;
      if (existingSession.acidNumber.isNotEmpty && existingSession.acidNumber != 'PENDING') {
        _acidNumberCtrl.text = existingSession.acidNumber;
      }
    } else {
      _editingAcidSessionId = null;
      _editingAcidCode = null;
    }

    // Importer
    final companies = ref.read(importCompaniesProvider).value ?? [];
    final matchedComp = companies.where((c) => c.companyId == file.companyId).firstOrNull;
    if (matchedComp != null) {
      _selectedImporterId = matchedComp.companyId;
      _importerNameCtrl.text = matchedComp.importerName;
      _importerTaxIdCtrl.text = matchedComp.vatId;
      _importerAddressCtrl.text = matchedComp.address;
    } else {
      _importerNameCtrl.text = file.companyName;
    }

    // Exporter
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final matchedSupp = suppliers.where((s) => s.supplierId == file.supplierId).firstOrNull;
    if (matchedSupp != null) {
      _selectedSupplierId = matchedSupp.supplierId;
      _exporterNameCtrl.text = matchedSupp.companyName;
      _exporterCountryCtrl.text = matchedSupp.foreignExporterCountry;
      _exporterCountryCodeCtrl.text = matchedSupp.foreignExporterCountryCode;
      _exporterAddressCtrl.text = matchedSupp.address;
      _exporterPhoneCtrl.text = matchedSupp.phone ?? '';
      _cargoxIdCtrl.text = matchedSupp.cargoxPlatformId ?? '';
      _exporterRegIdCtrl.text = matchedSupp.foreignExporterId;
      _exporterRegType = matchedSupp.registrationType.isNotEmpty ? matchedSupp.registrationType : 'Company Registration Number';
    } else {
      _exporterNameCtrl.text = file.supplierName;
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
      _proformaNoCtrl.text = (file.piNumber != null && file.piNumber!.isNotEmpty) ? file.piNumber! : 'PI-${matchedPo.poNumber}';
    } else {
      _poNoCtrl.text = (file.poNumber != null && file.poNumber!.isNotEmpty) ? file.poNumber! : 'PO-${file.importFileCode}';
      _proformaNoCtrl.text = (file.piNumber != null && file.piNumber!.isNotEmpty) ? file.piNumber! : 'PI-${file.importFileCode}';
    }

    if (_polCtrl.text.isEmpty || _polCtrl.text == 'Shanghai Port (CNSHA)') {
      _polCtrl.text = 'CHANGSHU';
    }
    if (_podCtrl.text.isEmpty || _podCtrl.text == 'Alexandria Port (EG ALX)') {
      _podCtrl.text = 'Alexandria';
    }
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
                  _comparisonResult!.allMatched ? context.l10n.matchedStatus : context.l10n.discrepancyStatus,
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
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: _refreshData,
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: context.l10n.refresh,
          onPressed: _refreshData,
        ),
      ],
      body: SingleChildScrollView(
        controller: _scrollController,
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
            margin: const EdgeInsets.only(bottom: 16),
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
                    context.l10n.acidInfoBanner,
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Edit Mode Banner
          if (_editingAcidSessionId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.orange, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.l10n.activeEditModeBanner}: ${_editingAcidCode ?? ''}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.savePaymentChangesButton,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade900, side: BorderSide(color: Colors.orange.shade400)),
                    onPressed: () {
                      setState(() {
                        _editingAcidSessionId = null;
                        _editingAcidCode = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(context.l10n.cancelEdit),
                  ),
                ],
              ),
            ),
          ],

          // File Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SearchableDropdownField<int>(
              labelText: context.l10n.selectImportFileAcidLabel,
              hintText: context.l10n.searchFileOrSupplierHint,
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
                Text(
                  context.l10n.importerAndExporterSection,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                          Text('🏢 ${context.l10n.importerSectionTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          SearchableDropdownField<int>(
                            labelText: context.l10n.importerSectionTitle,
                            hintText: context.l10n.searchFileOrSupplierHint,
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
                            decoration: InputDecoration(
                              labelText: '${context.l10n.importerTaxIdLabel} *',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? context.l10n.importerTaxIdLabel : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _importerAddressCtrl,
                            decoration: InputDecoration(
                              labelText: context.l10n.importerAddressLabel,
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              border: const OutlineInputBorder(),
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
                          Text('🌍 ${context.l10n.foreignExporterSectionTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          SearchableDropdownField<int>(
                            labelText: context.l10n.foreignExporterSectionTitle,
                            hintText: context.l10n.searchFileOrSupplierHint,
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
                                    labelText: '${context.l10n.foreignExporterIdLabel} *',
                                    helperText: _exporterRegType,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.foreignExporterIdLabel : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _exporterRegType,
                                  decoration: InputDecoration(labelText: context.l10n.regTypeLabel, border: const OutlineInputBorder()),
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
                                  decoration: InputDecoration(
                                    labelText: '${context.l10n.countryOfOriginExportLabel} *',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.countryOfOriginExportLabel : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _cargoxIdCtrl,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.cargoxPlatformIdLabel,
                                    border: const OutlineInputBorder(),
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
                Text(
                  context.l10n.proformaPortsBrokerSection,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _proformaNoCtrl,
                        decoration: InputDecoration(
                          labelText: '${context.l10n.proformaInvoiceNoLabel} *',
                          prefixIcon: const Icon(Icons.receipt_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? context.l10n.proformaInvoiceNoLabel : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _proformaDateCtrl,
                        decoration: InputDecoration(
                          labelText: '${context.l10n.proformaInvoiceDateLabel} *',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _invoiceType,
                        decoration: InputDecoration(labelText: context.l10n.invoiceTypeLabel, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'Proforma Invoice', child: Text(context.l10n.proformaInvoiceNoLabel)),
                          const DropdownMenuItem(value: 'Commercial Invoice', child: Text('Commercial Invoice')),
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
                        decoration: InputDecoration(
                          labelText: '${context.l10n.portOfLoadingLabel} *',
                          prefixIcon: const Icon(Icons.directions_boat_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? context.l10n.portOfLoadingLabel : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _podCtrl,
                        decoration: InputDecoration(
                          labelText: '${context.l10n.portOfDischargeLabel} *',
                          prefixIcon: const Icon(Icons.anchor),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? context.l10n.portOfDischargeLabel : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SearchableDropdownField<int>(
                        labelText: context.l10n.customsBrokerResponsibleLabel,
                        hintText: context.l10n.searchFileOrSupplierHint,
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
                        decoration: InputDecoration(
                          labelText: context.l10n.brokerPhoneLabel,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _requestedDateCtrl,
                        decoration: InputDecoration(
                          labelText: '${context.l10n.acidRequestDateLabel} *',
                          prefixIcon: const Icon(Icons.event_available),
                          border: const OutlineInputBorder(),
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
                        _isSaving
                            ? context.l10n.loading
                            : (_editingAcidSessionId != null ? context.l10n.updateAcidRequestButton : context.l10n.saveAcidRequestButton),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      onPressed: () => setState(() => _selectedSubTab = 1),
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: Text(context.l10n.goToSmartParserButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Generated Broker Message Preview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.brokerDispatchMessageTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.brokerDispatchMessageSub,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _buildWhatsAppMessage()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ WhatsApp Message Copied'), backgroundColor: AppTheme.emerald),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(context.l10n.copyArabicWhatsApp, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _buildEnglishRequestMessage()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ ACID Request Message Copied (English)'), backgroundColor: AppTheme.emerald),
                        );
                      },
                      icon: const Icon(Icons.language, size: 16),
                      label: Text(context.l10n.copyEnglishRequest, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.charcoal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _buildEmailMessage()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Email Template Copied'), backgroundColor: AppTheme.emerald),
                        );
                      },
                      icon: const Icon(Icons.email_outlined, size: 16),
                      label: Text(context.l10n.emailTemplateButton),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: SelectableText(
                    _buildWhatsAppMessage(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: AppTheme.charcoal),
                  ),
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
                  context.l10n.smartParserInfoBanner,
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
            labelText: context.l10n.linkImportFileResult,
            hintText: context.l10n.searchFileOrSupplierHint,
            value: _selectedImportFileId,
            items: importFiles.map((f) => SearchableDropdownItem<int>(
              value: f.importFileId,
              label: '${f.importFileCode} — ${f.supplierName}',
            )).toList(),
            onChanged: (val) => _onImportFileChanged(val),
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
                  Text('${context.l10n.pasteRawMtsTextTitle}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.cobalt,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: _loadSampleMtsText,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: Text(context.l10n.loadSampleMtsTextButton),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _rawMtsTextCtrl.text = data!.text!;
                      }
                    },
                    icon: const Icon(Icons.paste, size: 16),
                    label: Text(context.l10n.pasteFromClipboardButton),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _rawMtsTextCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'MTS Notification [ACID: 19 digits]...',
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
                    label: Text(_isParsingMts ? context.l10n.loading : context.l10n.runSmartParserButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _rawMtsTextCtrl.clear();
                      _parsedMtsData = null;
                    }),
                    icon: const Icon(Icons.clear_all),
                    label: Text(context.l10n.clearTextButton),
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
              border: Border.all(color: (_parsedMtsData!['acid_number']?.toString().isNotEmpty ?? false) ? Colors.teal.shade300 : AppTheme.orange, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      (_parsedMtsData!['acid_number']?.toString().isNotEmpty ?? false) ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: (_parsedMtsData!['acid_number']?.toString().isNotEmpty ?? false) ? Colors.teal : AppTheme.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (_parsedMtsData!['acid_number']?.toString().isNotEmpty ?? false)
                          ? context.l10n.parsedMtsSuccessTitle
                          : context.l10n.parsedMtsNoAcidTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: (_parsedMtsData!['acid_number']?.toString().isNotEmpty ?? false) ? Colors.teal : AppTheme.orange,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _selectedSubTab = 2);
                        if (_selectedImportFileId != null) {
                          _runComparison();
                        }
                      },
                      icon: const Icon(Icons.compare_arrows, size: 16),
                      label: Text(context.l10n.goToVerificationButton),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildExtractedField(context.l10n.acidNumberCol, _parsedMtsData!['acid_number']?.toString().isNotEmpty ?? false ? _parsedMtsData!['acid_number']!.toString() : '-'),
                    _buildExtractedField(context.l10n.issueDateCol, _parsedMtsData!['generated_date']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.expiryDateCol, _parsedMtsData!['expiry_date']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.importerCompanyCol, _parsedMtsData!['importer_name']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.importerTaxIdLabel, _parsedMtsData!['importer_tax_id']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.foreignExporterCol, _parsedMtsData!['exporter_name']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.foreignExporterIdLabel, _parsedMtsData!['exporter_reg_id']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.regTypeLabel, _parsedMtsData!['exporter_reg_type']?.toString() ?? 'Company Registration Number'),
                    _buildExtractedField(context.l10n.countryOfOriginExportLabel, _parsedMtsData!['exporter_country']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.cargoxPlatformIdLabel, _parsedMtsData!['cargox_id']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.proformaInvoiceNoLabel, _parsedMtsData!['proforma_invoice_no']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.portOfLoadingLabel, _parsedMtsData!['pol_name']?.toString() ?? '-'),
                    _buildExtractedField(context.l10n.portOfDischargeLabel, _parsedMtsData!['pod_name']?.toString() ?? '-'),
                  ],
                ),
                const Divider(height: 24),
                // Action Buttons Bar
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : () => _saveMtsResultAsAcidSession(isDraft: false),
                      icon: const Icon(Icons.save_as, size: 18),
                      label: Text(context.l10n.saveAndCertifyAcidButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : () => _saveMtsResultAsAcidSession(isDraft: true),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(context.l10n.saveTempDraftButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: AppTheme.cobalt),
                      ),
                      onPressed: _showEditMtsDataDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(context.l10n.editExtractedDataButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _codeSupplierFromMts,
                      icon: const Icon(Icons.business_outlined, size: 18),
                      label: Text(context.l10n.codeSupplierButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
                  labelText: context.l10n.selectImportFileAcidLabel,
                  hintText: context.l10n.searchFileOrSupplierHint,
                  value: _selectedImportFileId,
                  items: importFiles.map((f) => SearchableDropdownItem<int>(
                    value: f.importFileId,
                    label: '${f.importFileCode} — ${f.supplierName}',
                  )).toList(),
                  onChanged: (val) {
                    _onImportFileChanged(val);
                    if (val != null && _parsedMtsData != null) {
                      _runComparison();
                    }
                  },
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
                label: Text(context.l10n.runDiscrepancyMatrixButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              ? context.l10n.perfectMatchTitle
                              : context.l10n.discrepancyFoundTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _comparisonResult!.allMatched ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        Text(
                          '${context.l10n.matchingStatusCol}: ${_comparisonResult!.matchPercentage.toStringAsFixed(1)}% (${_comparisonResult!.matchedCount} / ${_comparisonResult!.totalComparedFields})',
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
                      children: [
                        Padding(padding: const EdgeInsets.all(10), child: Text(context.l10n.customsFieldCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(context.l10n.requestedValueCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(context.l10n.generatedValueCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(context.l10n.matchingStatusCol, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                Text(item.isMatched ? context.l10n.matchedStatus : context.l10n.discrepancyStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.isMatched ? Colors.green : Colors.red)),
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
                  Text(context.l10n.discrepancyOverrideJustificationLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _discrepancyOverrideReasonCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Discrepancy override reason...',
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
                  label: Text(_isSaving ? context.l10n.loading : context.l10n.verifyAndCertifyAcidButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  hintText: context.l10n.searchAcidRegistryHint,
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
              label: Text(context.l10n.newAcidRequestButton),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: [
                DataColumn(label: Text(context.l10n.acidNumberCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.importFile, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.foreignExporterCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.importerCompanyCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.issueDateCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.expiryDateCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.validityStatusCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(context.l10n.actionCol, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                          s.status == 'Issued' ? context.l10n.issuedAndValidStatus : (s.status == 'DRAFT' ? context.l10n.tempDraftStatus : context.l10n.underReviewStatus),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.status == 'Issued' ? Colors.green.shade800 : Colors.blue.shade800),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: AppTheme.cobalt, size: 22),
                            tooltip: context.l10n.edit,
                            onPressed: () => _loadSessionForEdit(s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 20),
                            tooltip: context.l10n.delete,
                            onPressed: () => _confirmDeleteAcidSession(s),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
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
              title: context.l10n.totalAcidsCard,
              count: trackerSummary?.totalAcidsCount ?? trackerItems.length,
              color: AppTheme.charcoal,
              icon: Icons.qr_code,
            ),
            const SizedBox(width: 14),
            _buildTrackerCard(
              title: context.l10n.validAcidsCard,
              count: trackerSummary?.validCount ?? trackerItems.where((t) => t.status != 'Expired' && t.daysRemaining > 14).length,
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 14),
            _buildTrackerCard(
              title: context.l10n.expiringSoonAcidsCard,
              count: trackerSummary?.expiringSoonCount ?? trackerItems.where((t) => t.status != 'Expired' && t.daysRemaining <= 14 && t.daysRemaining > 0).length,
              color: AppTheme.orange,
              icon: Icons.warning_amber,
            ),
            const SizedBox(width: 14),
            _buildTrackerCard(
              title: context.l10n.expiredAcidsCard,
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
            hintText: context.l10n.searchExpiryTrackerHint,
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
            columns: [
              DataColumn(label: Text(context.l10n.acidNumberCol, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.l10n.importFile, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.l10n.foreignExporterCol, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.l10n.expiryDateCol, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.l10n.daysRemainingCol, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.l10n.validityStatusCol, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                  DataCell(Text('$days', style: TextStyle(fontWeight: FontWeight.bold, color: isExp ? Colors.red : isWarning ? Colors.orange : Colors.green))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExp ? Colors.red.shade50 : isWarning ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isExp ? Colors.red.shade300 : isWarning ? Colors.orange.shade300 : Colors.green.shade300),
                      ),
                      child: Text(
                        isExp ? context.l10n.expiredStatusBadge : isWarning ? context.l10n.expiringSoonStatusBadge : context.l10n.validStatusBadge,
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
        'exporter_country_code': _exporterCountryCodeCtrl.text.trim(),
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

      // Check if session exists or is in edit mode
      final sessions = ref.read(acidSessionsProvider).value ?? [];
      final existing = sessions.where((s) => s.importFileId == _selectedImportFileId && s.isActive).firstOrNull;
      final targetAcidId = _editingAcidSessionId ?? existing?.acidId;

      if (targetAcidId != null) {
        await ref.read(acidSessionsProvider.notifier).updateAcidSession(targetAcidId, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تعديل وتحديث بيانات طلب ACID (${existing?.acidCode ?? _editingAcidCode ?? ''}) بنجاح'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          setState(() {
            _editingAcidSessionId = targetAcidId;
            _selectedSubTab = 1;
          });
        }
      } else {
        await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل وحفظ طلب ACID بنجاح'), backgroundColor: AppTheme.emerald),
          );
          setState(() => _selectedSubTab = 1);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في حفظ طلب ACID', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _loadSampleMtsText() {
    setState(() {
      _rawMtsTextCtrl.text = '''MTS Notification
Dear Suzhou Yuheng Textile Co.,Ltd,

Kindly be informed that an Advance Cargo Information request (ACI) has been approved for shipping:
[ACID: 5281534391023010013]
Requested: 19-Aug-2026 11:26:47 AM   Generated: 19-Aug-2026 11:26:54 AM   Expires: 19-Feb-2027 11:26:54 AM 

Egyptian Importer
Egyptian Importer Name: SCAS For Construction And Finishing
Egyptian Importer Tax ID: 528153439
Address: 44ش 18 المعادى القاهرة رقم ملف 36221ق

Foreign Exporter
Foreign Exporter Name: Suzhou Yuheng Textile Co.,Ltd
Registration Type: Company Registration Number
Foreign Exporter ID: 913205813141920259
Country: CHINA
Country Code: CN 
Address: No.16 Kangsheng Road, Changshu,Suzhou,China 215500
Tel. No.: 0

Shipment
Proforma Invoice No.: YH20260730-6
Proforma Invoice Date: 7/30/2026 12:00:00 AM
Invoice Date: 8/19/2026 11:23:01 AM
Type of invoice: Proforma Invoice
Shipping Port: CHANGSHU
Destination Port: Alexandria

Please note that the required documents for the mentioned shipment must be uploaded from the exporter who registered with ID: 5b1b827d-5840-4ad6-b692-c5f636881c0e on the CargoX platform.''';

      if (_importerNameCtrl.text.isEmpty) _importerNameCtrl.text = 'SCAS For Construction And Finishing';
      if (_importerTaxIdCtrl.text.isEmpty) _importerTaxIdCtrl.text = '528153439';
      if (_importerAddressCtrl.text.isEmpty) _importerAddressCtrl.text = '44ش 18 المعادى القاهرة رقم ملف 36221ق';
      if (_exporterNameCtrl.text.isEmpty) _exporterNameCtrl.text = 'Suzhou Yuheng Textile Co.,Ltd';
      if (_exporterRegIdCtrl.text.isEmpty) _exporterRegIdCtrl.text = '913205813141920259';
      if (_exporterCountryCtrl.text.isEmpty) _exporterCountryCtrl.text = 'CHINA';
      if (_exporterCountryCodeCtrl.text.isEmpty) _exporterCountryCodeCtrl.text = 'CN';
      _exporterRegType = 'Company Registration Number';
      if (_proformaNoCtrl.text.isEmpty) _proformaNoCtrl.text = 'YH20260730-6';
      _polCtrl.text = 'CHANGSHU';
      _podCtrl.text = 'Alexandria';
      if (_cargoxIdCtrl.text.isEmpty) _cargoxIdCtrl.text = '5b1b827d-5840-4ad6-b692-c5f636881c0e';
    });
    _parseMtsText();
  }

  Future<void> _parseMtsText() async {
    final raw = _rawMtsTextCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى لصق نص نافذة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    // Check if user pasted only the legal email disclaimer
    if (raw.contains('MTS EMAIL NOTICE This Electronic Mail') &&
        !raw.contains('ACID') &&
        !RegExp(r'\d{19}').hasMatch(raw)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 26),
              SizedBox(width: 8),
              Text('تنبيه: نص تذييل الإيميل فقط'),
            ],
          ),
          content: const Text(
            'النص الملصق يحتوي فقط على إشعار السرية وتذييل الإيميل القانوني (Email Disclaimer):\n\n'
            '«MTS EMAIL NOTICE This Electronic Mail...»\n\n'
            'ولا يحتوي على بيانات إشعار القيد الجمركي (رقم ACID، تاريخ الصلاحية، المصدر والمستورد).\n\n'
            '👉 يرجى نسخ محتوى الإيميل الرئيسي من الأعلى، أو تجربة النموذج بالنقر على الزر أدناه.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _loadSampleMtsText();
              },
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('تحميل نص إشعار نافذة نموذجي وتجربته فوراً'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isParsingMts = true);
    try {
      final responseData = await ref.read(acidSessionsProvider.notifier).parseAcidText(raw, importFileId: _selectedImportFileId);
      final Map<String, dynamic> parsedFields = (responseData['parsed_data'] != null && responseData['parsed_data'] is Map)
          ? Map<String, dynamic>.from(responseData['parsed_data'] as Map)
          : Map<String, dynamic>.from(responseData);
      
      setState(() => _parsedMtsData = parsedFields);
      
      // Auto-scroll to results card
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });

      if (mounted) {
        final acidFound = (parsedFields['acid_number'] != null && parsedFields['acid_number'].toString().trim().isNotEmpty);
        if (acidFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم استخراج رقم ACID: ${parsedFields['acid_number']} وكافة بيانات الشحنة بنجاح!'),
              backgroundColor: AppTheme.emerald,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.orange, size: 26),
                  SizedBox(width: 8),
                  Text('لم يتم العثور على رقم ACID في النص الملصق'),
                ],
              ),
              content: const Text(
                'النص الذي تم لصقه ينقصه السطور العلوية الأولى من إشعار نافذة (التي تحتوي على رقم ACID المكون من 19 رقماً وتواريخ الصلاحية).\n\n'
                '📌 للتجربة الفورية ورؤية جدول الاستخراج بالكامل، اضغط على "تحميل إشعار نافذة نموذجي".',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadSampleMtsText();
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('تحميل نص نموذجي واستخراجه فوراً'),
                ),
              ],
            ),
          );
        }
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

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
    final companies = ref.read(importCompaniesProvider).value ?? [];
    final comp = companies.where((c) => c.companyId == file?.companyId).firstOrNull;
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final supp = suppliers.where((s) => s.supplierId == file?.supplierId).firstOrNull;
    final pos = ref.read(purchaseOrdersProvider).purchaseOrders;
    final po = pos.where((p) => p.importFileId == _selectedImportFileId).firstOrNull;

    setState(() => _isComparing = true);
    try {
      final requestedData = {
        'import_file_id': _selectedImportFileId,
        'importer_name': _importerNameCtrl.text.isNotEmpty ? _importerNameCtrl.text : (comp?.importerName ?? file?.companyName ?? ''),
        'importer_tax_id': _importerTaxIdCtrl.text.isNotEmpty ? _importerTaxIdCtrl.text : (comp?.vatId ?? ''),
        'exporter_name': _exporterNameCtrl.text.isNotEmpty ? _exporterNameCtrl.text : (supp?.companyName ?? file?.supplierName ?? ''),
        'exporter_reg_type': _exporterRegType.isNotEmpty ? _exporterRegType : (supp?.registrationType ?? 'Company Registration Number'),
        'exporter_reg_id': _exporterRegIdCtrl.text.isNotEmpty ? _exporterRegIdCtrl.text : (supp?.foreignExporterId ?? ''),
        'exporter_country': _exporterCountryCtrl.text.isNotEmpty ? _exporterCountryCtrl.text : (supp?.foreignExporterCountry ?? ''),
        'exporter_country_code': _exporterCountryCodeCtrl.text.isNotEmpty ? _exporterCountryCodeCtrl.text : (supp?.foreignExporterCountryCode ?? ''),
        'proforma_invoice_no': _proformaNoCtrl.text.isNotEmpty ? _proformaNoCtrl.text : (file?.piNumber ?? (po != null ? 'PI-${po.poNumber}' : 'YH20260730-6')),
        'pol_name': _polCtrl.text.isNotEmpty ? _polCtrl.text : 'CHANGSHU',
        'pod_name': _podCtrl.text.isNotEmpty ? _podCtrl.text : 'Alexandria',
        'cargox_id': _cargoxIdCtrl.text.isNotEmpty ? _cargoxIdCtrl.text : (supp?.cargoxPlatformId ?? '5b1b827d-5840-4ad6-b692-c5f636881c0e'),
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

      final sessions = ref.read(acidSessionsProvider).value ?? [];
      final existing = sessions.where((s) => s.importFileId == _selectedImportFileId && s.isActive).firstOrNull;
      final targetAcidId = _editingAcidSessionId ?? existing?.acidId;

      if (targetAcidId != null) {
        await ref.read(acidSessionsProvider.notifier).updateAcidSession(targetAcidId, payload);
      } else {
        await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);
      }

      await ref.read(importFilesProvider.notifier).fetchImportFiles();
      await ref.read(acidTrackerProvider.notifier).fetchAcidTracker();

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

  void _loadSessionForEdit(AcidRegistrationModel session) {
    setState(() {
      _selectedImportFileId = session.importFileId;
      _editingAcidSessionId = session.acidId;
      _editingAcidCode = session.acidCode;
      _selectedImporterId = session.importerId;
      _importerNameCtrl.text = session.importerName;
      _importerTaxIdCtrl.text = session.importerTaxId;
      _importerAddressCtrl.text = session.importerAddress ?? '';
      _selectedSupplierId = session.supplierId;
      _exporterNameCtrl.text = session.exporterName;
      _exporterRegIdCtrl.text = session.exporterRegId;
      _exporterCountryCtrl.text = session.exporterCountry;
      _exporterCountryCodeCtrl.text = session.exporterCountryCode ?? '';
      _exporterAddressCtrl.text = session.exporterAddress ?? '';
      _exporterPhoneCtrl.text = session.exporterPhone ?? '';
      _exporterRegType = session.exporterRegType ?? 'Company Registration Number';
      _cargoxIdCtrl.text = session.cargoxId ?? '';
      _poNoCtrl.text = session.poNumber ?? '';
      _proformaNoCtrl.text = session.proformaInvoiceNo;
      _polCtrl.text = session.polName;
      _podCtrl.text = session.podName;
      _brokerNameCtrl.text = session.customsBrokerName ?? '';
      _brokerPhoneCtrl.text = session.customsBrokerPhone ?? '';
      _requestedDateCtrl.text = session.requestedDate ?? '';
      _selectedSubTab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم فتح طلب ACID (${session.acidCode}) للتعديل الكامل'), backgroundColor: AppTheme.cobalt),
    );
  }

  void _confirmDeleteAcidSession(AcidRegistrationModel session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 24),
            const SizedBox(width: 8),
            Text(context.l10n.confirmSoftDelete, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACID (${session.acidCode}) — (${session.acidNumber})'),
            const SizedBox(height: 10),
            Text(context.l10n.confirmSoftDelete, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(acidSessionsProvider.notifier).softDeleteAcidSession(session.acidId);
                await ref.read(importFilesProvider.notifier).fetchImportFiles();
                await ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ACID (${session.acidCode}) deleted successfully'),
                      backgroundColor: AppTheme.charcoal,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showErrorDetailsDialog(context, title: 'Error deleting ACID session', error: e);
                }
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMtsResultAsAcidSession({bool isDraft = false}) async {
    if (_parsedMtsData == null) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select import file first'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final acidNum = _parsedMtsData!['acid_number']?.toString().trim() ?? '';
      final payload = {
        'import_file_id': _selectedImportFileId,
        'importer_id': _selectedImporterId,
        'importer_name': _parsedMtsData!['importer_name']?.toString().trim() ?? _importerNameCtrl.text.trim(),
        'importer_tax_id': _parsedMtsData!['importer_tax_id']?.toString().trim() ?? _importerTaxIdCtrl.text.trim(),
        'importer_address': _parsedMtsData!['importer_address']?.toString().trim() ?? _importerAddressCtrl.text.trim(),
        'supplier_id': _selectedSupplierId,
        'exporter_name': _parsedMtsData!['exporter_name']?.toString().trim() ?? _exporterNameCtrl.text.trim(),
        'exporter_reg_type': _parsedMtsData!['exporter_reg_type']?.toString().trim() ?? 'Company Registration Number',
        'exporter_reg_id': _parsedMtsData!['exporter_reg_id']?.toString().trim() ?? _exporterRegIdCtrl.text.trim(),
        'exporter_country': _parsedMtsData!['exporter_country']?.toString().trim() ?? _exporterCountryCtrl.text.trim(),
        'exporter_country_code': _parsedMtsData!['exporter_country_code']?.toString().trim() ?? _exporterCountryCodeCtrl.text.trim(),
        'exporter_address': _parsedMtsData!['exporter_address']?.toString().trim() ?? _exporterAddressCtrl.text.trim(),
        'exporter_phone': _parsedMtsData!['exporter_phone']?.toString().trim() ?? _exporterPhoneCtrl.text.trim(),
        'cargox_id': _parsedMtsData!['cargox_id']?.toString().trim() ?? _cargoxIdCtrl.text.trim(),
        'po_id': _selectedPoId,
        'po_number': _poNoCtrl.text.trim(),
        'proforma_invoice_no': _parsedMtsData!['proforma_invoice_no']?.toString().trim() ?? _proformaNoCtrl.text.trim(),
        'proforma_invoice_date': _parsedMtsData!['proforma_invoice_date']?.toString().trim() ?? _proformaDateCtrl.text.trim(),
        'invoice_date': _parsedMtsData!['invoice_date']?.toString().trim(),
        'invoice_type': _parsedMtsData!['invoice_type']?.toString().trim() ?? _invoiceType,
        'pol_name': _parsedMtsData!['pol_name']?.toString().trim() ?? _polCtrl.text.trim(),
        'pod_name': _parsedMtsData!['pod_name']?.toString().trim() ?? _podCtrl.text.trim(),
        'customs_broker_id': _selectedBrokerId,
        'customs_broker_name': _brokerNameCtrl.text.trim(),
        'customs_broker_phone': _brokerPhoneCtrl.text.trim(),
        'requested_date': _parsedMtsData!['requested_date']?.toString().trim() ?? _requestedDateCtrl.text.trim(),
        'generated_date': _parsedMtsData!['generated_date']?.toString().trim(),
        'expiry_date': _parsedMtsData!['expiry_date']?.toString().trim(),
        'acid_number': acidNum.isNotEmpty ? acidNum : 'PENDING',
        'raw_nafeza_text': _rawMtsTextCtrl.text.trim(),
        'status': isDraft ? 'DRAFT' : (acidNum.isNotEmpty ? 'Issued' : 'Pending Issue'),
      };

      // Check if session exists or is in edit mode
      final sessions = ref.read(acidSessionsProvider).value ?? [];
      final existing = sessions.where((s) => s.importFileId == _selectedImportFileId && s.isActive).firstOrNull;
      final targetAcidId = _editingAcidSessionId ?? existing?.acidId;

      if (targetAcidId != null) {
        await ref.read(acidSessionsProvider.notifier).updateAcidSession(targetAcidId, payload);
      } else {
        await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);
      }

      await ref.read(importFilesProvider.notifier).fetchImportFiles();
      await ref.read(acidTrackerProvider.notifier).fetchAcidTracker();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft
                ? 'MTS draft saved successfully!'
                : 'ACID data certified and saved successfully!'),
            backgroundColor: isDraft ? AppTheme.charcoal : AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: isDraft ? 'Error saving draft' : 'Error saving ACID', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEditMtsDataDialog() {
    if (_parsedMtsData == null) return;

    final acidCtrl = TextEditingController(text: _parsedMtsData!['acid_number']?.toString() ?? '');
    final genDateCtrl = TextEditingController(text: _parsedMtsData!['generated_date']?.toString() ?? '');
    final expDateCtrl = TextEditingController(text: _parsedMtsData!['expiry_date']?.toString() ?? '');
    final reqDateCtrl = TextEditingController(text: _parsedMtsData!['requested_date']?.toString() ?? '');
    final impNameCtrl = TextEditingController(text: _parsedMtsData!['importer_name']?.toString() ?? '');
    final impTaxCtrl = TextEditingController(text: _parsedMtsData!['importer_tax_id']?.toString() ?? '');
    final impAddrCtrl = TextEditingController(text: _parsedMtsData!['importer_address']?.toString() ?? '');
    final expNameCtrl = TextEditingController(text: _parsedMtsData!['exporter_name']?.toString() ?? '');
    final expRegIdCtrl = TextEditingController(text: _parsedMtsData!['exporter_reg_id']?.toString() ?? '');
    final expCountryCtrl = TextEditingController(text: _parsedMtsData!['exporter_country']?.toString() ?? '');
    final cargoxCtrl = TextEditingController(text: _parsedMtsData!['cargox_id']?.toString() ?? '');
    final piCtrl = TextEditingController(text: _parsedMtsData!['proforma_invoice_no']?.toString() ?? '');
    final polCtrl = TextEditingController(text: _parsedMtsData!['pol_name']?.toString() ?? '');
    final podCtrl = TextEditingController(text: _parsedMtsData!['pod_name']?.toString() ?? '');
    String regType = _parsedMtsData!['exporter_reg_type']?.toString() ?? 'Company Registration Number';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 700,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppTheme.charcoal,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(context.l10n.editExtractedDataButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: acidCtrl,
                                decoration: InputDecoration(labelText: '${context.l10n.acidNumberCol} *', prefixIcon: const Icon(Icons.qr_code), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: reqDateCtrl,
                                decoration: InputDecoration(labelText: context.l10n.acidRequestDateLabel, prefixIcon: const Icon(Icons.event_available), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: genDateCtrl,
                                decoration: InputDecoration(labelText: context.l10n.issueDateCol, prefixIcon: const Icon(Icons.calendar_today), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: expDateCtrl,
                                decoration: InputDecoration(labelText: context.l10n.expiryDateCol, prefixIcon: const Icon(Icons.event_busy), border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: impNameCtrl,
                                decoration: InputDecoration(labelText: context.l10n.importerCompanyCol, prefixIcon: const Icon(Icons.business), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: impTaxCtrl,
                                decoration: InputDecoration(labelText: context.l10n.importerTaxIdLabel, prefixIcon: const Icon(Icons.badge), border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: expNameCtrl,
                                decoration: InputDecoration(labelText: context.l10n.foreignExporterCol, prefixIcon: const Icon(Icons.public), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: expRegIdCtrl,
                                decoration: InputDecoration(labelText: context.l10n.foreignExporterIdLabel, prefixIcon: const Icon(Icons.confirmation_number), border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SearchableDropdownField<String>(
                                labelText: context.l10n.regTypeLabel,
                                value: regType,
                                items: const [
                                  SearchableDropdownItem(value: 'Company Registration Number', label: 'Company Registration Number'),
                                  SearchableDropdownItem(value: 'Foreign Exporter Number (Nafeza)', label: 'Foreign Exporter Number (Nafeza)'),
                                  SearchableDropdownItem(value: 'Factory Registration', label: 'Factory Registration'),
                                  SearchableDropdownItem(value: 'VAT Number', label: 'VAT Number'),
                                  SearchableDropdownItem(value: 'Tax Number', label: 'Tax Number'),
                                  SearchableDropdownItem(value: 'Commercial Register', label: 'Commercial Register'),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => regType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: expCountryCtrl,
                                decoration: InputDecoration(labelText: context.l10n.countryOfOriginExportLabel, prefixIcon: const Icon(Icons.flag), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: cargoxCtrl,
                                decoration: InputDecoration(labelText: context.l10n.cargoxPlatformIdLabel, prefixIcon: const Icon(Icons.token), border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: piCtrl,
                                decoration: InputDecoration(labelText: context.l10n.proformaInvoiceNoLabel, prefixIcon: const Icon(Icons.receipt), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: polCtrl,
                                decoration: InputDecoration(labelText: context.l10n.portOfLoadingLabel, prefixIcon: const Icon(Icons.sailing), border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: podCtrl,
                                decoration: InputDecoration(labelText: context.l10n.portOfDischargeLabel, prefixIcon: const Icon(Icons.anchor), border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(context.l10n.cancel)),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() {
                            _parsedMtsData!['acid_number'] = acidCtrl.text.trim();
                            _parsedMtsData!['requested_date'] = reqDateCtrl.text.trim();
                            _parsedMtsData!['generated_date'] = genDateCtrl.text.trim();
                            _parsedMtsData!['expiry_date'] = expDateCtrl.text.trim();
                            _parsedMtsData!['importer_name'] = impNameCtrl.text.trim();
                            _parsedMtsData!['importer_tax_id'] = impTaxCtrl.text.trim();
                            _parsedMtsData!['importer_address'] = impAddrCtrl.text.trim();
                            _parsedMtsData!['exporter_name'] = expNameCtrl.text.trim();
                            _parsedMtsData!['exporter_reg_id'] = expRegIdCtrl.text.trim();
                            _parsedMtsData!['exporter_country'] = expCountryCtrl.text.trim();
                            _parsedMtsData!['exporter_reg_type'] = regType;
                            _parsedMtsData!['cargox_id'] = cargoxCtrl.text.trim();
                            _parsedMtsData!['proforma_invoice_no'] = piCtrl.text.trim();
                            _parsedMtsData!['pol_name'] = polCtrl.text.trim();
                            _parsedMtsData!['pod_name'] = podCtrl.text.trim();
                          });
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('MTS Extracted Data Updated'), backgroundColor: AppTheme.emerald),
                          );
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(context.l10n.save),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _codeSupplierFromMts() async {
    if (_parsedMtsData == null) return;
    final expName = _parsedMtsData!['exporter_name']?.toString().trim() ?? '';
    if (expName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المصدر الأجنبي غير موجود في بيانات نافذة'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    try {
      final existingSuppliers = ref.read(suppliersProvider).value ?? [];
      final existing = existingSuppliers.where((s) => s.companyName.toLowerCase() == expName.toLowerCase() || s.foreignExporterId == (_parsedMtsData!['exporter_reg_id']?.toString().trim() ?? '')).firstOrNull;

      final supplier = SupplierModel(
        supplierId: existing?.supplierId,
        supplierCode: existing?.supplierCode ?? 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        companyName: expName,
        supplierType: 'Manufacturer',
        registrationType: _parsedMtsData!['exporter_reg_type']?.toString().trim() ?? 'Company Registration Number',
        foreignExporterId: _parsedMtsData!['exporter_reg_id']?.toString().trim() ?? (existing?.foreignExporterId ?? 'EXP-SUP-001'),
        cargoxPlatformId: _parsedMtsData!['cargox_id']?.toString().trim() ?? existing?.cargoxPlatformId,
        foreignExporterCountry: _parsedMtsData!['exporter_country']?.toString().trim() ?? (existing?.foreignExporterCountry ?? 'China'),
        foreignExporterCountryCode: _parsedMtsData!['exporter_country_code']?.toString().trim() ?? (existing?.foreignExporterCountryCode ?? 'CN'),
        address: _parsedMtsData!['exporter_address']?.toString().trim() ?? (existing?.address ?? 'No.16 Kangsheng Road, Changshu, China'),
        phone: _parsedMtsData!['exporter_phone']?.toString().trim() ?? existing?.phone,
        isActive: true,
      );

      String? err;
      if (existing != null && existing.supplierId != null) {
        err = await ref.read(suppliersProvider.notifier).updateSupplier(existing.supplierId!, supplier);
      } else {
        err = await ref.read(suppliersProvider.notifier).createSupplier(supplier);
      }

      if (err != null) {
        if (mounted) {
          showErrorDetailsDialog(context, title: 'خطأ في تكويد المورد', error: err);
        }
        return;
      }

      await ref.read(suppliersProvider.notifier).fetchSuppliers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تكويد / تحديث المورد الأجنبي ($expName) بنوع تسجيل Company Registration Number بنجاح!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في تكويد المورد', error: e);
      }
    }
  }

  String _buildWhatsAppMessage() {
    final impName = _importerNameCtrl.text.trim().isNotEmpty ? _importerNameCtrl.text.trim() : '-';
    final impTax = _importerTaxIdCtrl.text.trim().isNotEmpty ? _importerTaxIdCtrl.text.trim() : '-';
    final impAddr = _importerAddressCtrl.text.trim().isNotEmpty ? _importerAddressCtrl.text.trim() : '-';
    final expName = _exporterNameCtrl.text.trim().isNotEmpty ? _exporterNameCtrl.text.trim() : '-';
    final expId = _exporterRegIdCtrl.text.trim().isNotEmpty ? _exporterRegIdCtrl.text.trim() : '-';
    final expCountry = _exporterCountryCtrl.text.trim().isNotEmpty ? _exporterCountryCtrl.text.trim() : '-';
    final expAddr = _exporterAddressCtrl.text.trim().isNotEmpty ? _exporterAddressCtrl.text.trim() : '-';
    final expPhone = _exporterPhoneCtrl.text.trim().isNotEmpty ? _exporterPhoneCtrl.text.trim() : '-';
    final cargox = _cargoxIdCtrl.text.trim().isNotEmpty ? _cargoxIdCtrl.text.trim() : '-';
    final piNo = _proformaNoCtrl.text.trim().isNotEmpty ? _proformaNoCtrl.text.trim() : '-';
    final piDate = _proformaDateCtrl.text.trim().isNotEmpty ? _proformaDateCtrl.text.trim() : '-';
    final poNo = _poNoCtrl.text.trim().isNotEmpty ? _poNoCtrl.text.trim() : '-';
    final pol = _polCtrl.text.trim().isNotEmpty ? _polCtrl.text.trim() : '-';
    final pod = _podCtrl.text.trim().isNotEmpty ? _podCtrl.text.trim() : '-';
    final reqDate = _requestedDateCtrl.text.trim().isNotEmpty ? _requestedDateCtrl.text.trim() : '-';

    return '''📋 *طلب استخراج رقم ACID جديد*
━━━━━━━━━━━━━━━━━━━━
🏢 *المستورد المصري:* $impName
🔢 *البطاقة الضريبية:* $impTax
📍 *العنوان المسجل:* $impAddr

🌍 *المصدر الأجنبي:* $expName
🆔 *المعرف الضريبي / نوعه:* $expId ($_exporterRegType)
🌐 *دولة المنشأ / التصدير:* $expCountry
📍 *عنوان المصدر:* $expAddr
📞 *هاتف المصدر:* $expPhone
🔑 *حساب كارجو إكس (CargoX ID):* $cargox

📄 *رقم الفاتورة المبدئية:* $piNo
📅 *تاريخ الفاتورة المبدئية:* $piDate
📑 *نوع الفاتورة:* $_invoiceType
📦 *أمر الشراء (PO):* $poNo
🚢 *ميناء الشحن (POL):* $pol
⚓ *ميناء الوصول (POD):* $pod
📅 *تاريخ تقديم الطلب:* $reqDate
━━━━━━━━━━━━━━━━━━━━
⚠️ *ملاحظة:* يرجى مراجعة الفاتورة المبدئية وسرعة موافاتنا برقم الـ ACID فور صدوره مع خالص الشكر.''';
  }

  String _buildEmailMessage() {
    final impName = _importerNameCtrl.text.trim().isNotEmpty ? _importerNameCtrl.text.trim() : 'Import';
    final piNo = _proformaNoCtrl.text.trim().isNotEmpty ? _proformaNoCtrl.text.trim() : '';
    final broker = _brokerNameCtrl.text.trim().isNotEmpty ? _brokerNameCtrl.text.trim() : 'مكتب التخليص الجمركي';

    return '''الموضوع: طلب إصدار رقم ACID - شحنة $impName - فاتورة $piNo

السيد المخلص الجمركي المحترم / $broker
تحية طيبة وبعد،،،

يرجى التكرم ببدء إجراءات طلب واستخراج رقم القيد الجمركي المبدئي (ACID) عبر منظومة نافذة للشحنة الموضحة بياناتها أدناه:

1. بيانات المستورد المصري:
   - اسم المستورد: ${_importerNameCtrl.text.trim()}
   - الرقم الضريبي: ${_importerTaxIdCtrl.text.trim()}
   - العنوان: ${_importerAddressCtrl.text.trim()}

2. بيانات المصدر الأجنبي:
   - اسم المصدر: ${_exporterNameCtrl.text.trim()}
   - نوع التسجيل والمعرف: ${_exporterRegIdCtrl.text.trim()} ($_exporterRegType)
   - دولة المنشأ: ${_exporterCountryCtrl.text.trim()}
   - عنوان المصدر: ${_exporterAddressCtrl.text.trim()}
   - هاتف المصدر: ${_exporterPhoneCtrl.text.trim()}
   - كود كارجو إكس (CargoX): ${_cargoxIdCtrl.text.trim()}

3. بيانات الفاتورة والشحن:
   - رقم الفاتورة المبدئية: ${_proformaNoCtrl.text.trim()}
   - تاريخ الفاتورة المبدئية: ${_proformaDateCtrl.text.trim()}
   - أمر الشراء: ${_poNoCtrl.text.trim()}
   - ميناء الشحن: ${_polCtrl.text.trim()}
   - ميناء الوصول: ${_podCtrl.text.trim()}

تجدون برفقه الفاتورة المبدئية للاطلاع والبدء في الإجراءات.
شاكرين لكم حسن تعاونكم الدائم.

قسم الاستيراد والتخليص الجمركي
Sorour Logistics ERP System''';
  }

  String _buildEnglishRequestMessage() {
    final impName = _importerNameCtrl.text.trim().isNotEmpty ? _importerNameCtrl.text.trim() : 'SCAS For Construction And Finishing';
    final impTax = _importerTaxIdCtrl.text.trim().isNotEmpty ? _importerTaxIdCtrl.text.trim() : '528153439';
    final impAddr = _importerAddressCtrl.text.trim().isNotEmpty ? _importerAddressCtrl.text.trim() : '44 St. 18, Maadi, Cairo, Egypt';
    final expName = _exporterNameCtrl.text.trim().isNotEmpty ? _exporterNameCtrl.text.trim() : 'Suzhou Yuheng Textile Co.,Ltd';
    final expId = _exporterRegIdCtrl.text.trim().isNotEmpty ? _exporterRegIdCtrl.text.trim() : '913205813141920259';
    final expCountry = _exporterCountryCtrl.text.trim().isNotEmpty ? _exporterCountryCtrl.text.trim() : 'China';
    final expAddr = _exporterAddressCtrl.text.trim().isNotEmpty ? _exporterAddressCtrl.text.trim() : 'No.16 Kangsheng Road, Changshu, Suzhou, China';
    final expPhone = _exporterPhoneCtrl.text.trim().isNotEmpty ? _exporterPhoneCtrl.text.trim() : '+86-512-52889988';
    final cargox = _cargoxIdCtrl.text.trim().isNotEmpty ? _cargoxIdCtrl.text.trim() : '5b1b827d-5840-4ad6-b692-c5f636881c0e';
    final piNo = _proformaNoCtrl.text.trim().isNotEmpty ? _proformaNoCtrl.text.trim() : 'YH20260730-6';
    final piDate = _proformaDateCtrl.text.trim().isNotEmpty ? _proformaDateCtrl.text.trim() : '2026-07-30';
    final poNo = _poNoCtrl.text.trim().isNotEmpty ? _poNoCtrl.text.trim() : '-';
    final pol = _polCtrl.text.trim().isNotEmpty ? _polCtrl.text.trim() : 'Changshu Port (China)';
    final pod = _podCtrl.text.trim().isNotEmpty ? _podCtrl.text.trim() : 'Alexandria Port (Egypt)';
    final reqDate = _requestedDateCtrl.text.trim().isNotEmpty ? _requestedDateCtrl.text.trim() : '2026-08-19';

    return '''📋 *Advance Cargo Information (ACID) Request*
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 *Egyptian Importer:* $impName
🔢 *Tax ID:* $impTax
📍 *Registered Address:* $impAddr

🌍 *Foreign Exporter / Supplier:* $expName
🆔 *Exporter Reg. ID:* $expId ($_exporterRegType)
🌐 *Country of Origin / Export:* $expCountry
📍 *Exporter Address:* $expAddr
📞 *Tel. / Mobile:* $expPhone
🔑 *CargoX Platform ID:* $cargox

📄 *Proforma Invoice No.:* $piNo
📅 *Proforma Invoice Date:* $piDate
📑 *Invoice Type:* $_invoiceType
📦 *Purchase Order (PO):* $poNo
🚢 *Port of Loading (POL):* $pol
⚓ *Port of Discharge (POD):* $pod
📅 *Request Date:* $reqDate
━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ *Important Note:* Please initiate the ACID issuance on the Nafeza (MTS) portal and provide us with the 19-digit ACID number upon generation. Thank you.''';
  }
}
