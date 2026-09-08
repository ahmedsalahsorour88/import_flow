import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../freight_booking/providers/freight_booking_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../providers/import_documentation_provider.dart';

class CustomsDeclarationAssessment {
  final String declarationNo;
  final String importFileCode;
  final String primaryNameWithCode;
  final String supplierName;
  final String companyName;
  final String acidNumber;
  final String form4Number;
  final String blNumber;
  final String hsCode;
  final String hsDescription;
  final double fobForeign;
  final String currency;
  final double exchangeRate;
  final double fobEgp;
  final double freightEgp;
  final double insuranceEgp;
  final double cifEgp;
  final double dutyRate;
  final double importDutyEgp;
  final double devRate;
  final double devFeeEgp;
  final double serviceRate;
  final double serviceFeeEgp;
  final double otherFeesEgp;
  final double vatRate;
  final double vatBaseEgp;
  final double vatEgp;
  final double totalDutiesEgp;
  final bool hasExemption;
  final String exemptionTitle;
  final String registrationDate;
  final String status;

  const CustomsDeclarationAssessment({
    required this.declarationNo,
    required this.importFileCode,
    required this.primaryNameWithCode,
    required this.supplierName,
    required this.companyName,
    required this.acidNumber,
    required this.form4Number,
    required this.blNumber,
    required this.hsCode,
    required this.hsDescription,
    required this.fobForeign,
    required this.currency,
    required this.exchangeRate,
    required this.fobEgp,
    required this.freightEgp,
    required this.insuranceEgp,
    required this.cifEgp,
    required this.dutyRate,
    required this.importDutyEgp,
    required this.devRate,
    required this.devFeeEgp,
    required this.serviceRate,
    required this.serviceFeeEgp,
    required this.otherFeesEgp,
    required this.vatRate,
    required this.vatBaseEgp,
    required this.vatEgp,
    required this.totalDutiesEgp,
    required this.hasExemption,
    required this.exemptionTitle,
    required this.registrationDate,
    required this.status,
  });
}

class CustomsDeclaration46Screen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const CustomsDeclaration46Screen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<CustomsDeclaration46Screen> createState() => _CustomsDeclaration46ScreenState();
}

class _CustomsDeclaration46ScreenState extends ConsumerState<CustomsDeclaration46Screen> {
  // Active Vertical Sub-Tab:
  // 0: Initial Declaration 46 Registration
  // 1: Declaration 46 Registry & Tracking
  int _selectedSubTab = 0;
  int? _selectedImportFileId;

  final _declarationFormKey = GlobalKey<FormState>();
  final TextEditingController _declaration46NoCtrl = TextEditingController(text: '46-EG-2026-');
  final TextEditingController _acidNumberCtrl = TextEditingController();
  final TextEditingController _form4NumberCtrl = TextEditingController();
  final TextEditingController _blNumberCtrl = TextEditingController();
  final TextEditingController _customsValueEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _importDutyEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _vatEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _otherFeesEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _totalDutyAndTaxesCtrl = TextEditingController(text: '0.00');
  final TextEditingController _submissionDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _notesCtrl = TextEditingController();

  // Compliance & HS Code Tariff States
  List<CustomsTariffModel> _matchedTariffs = [];
  bool _hasExemption = false;
  double _appliedDutyRate = 5.0;
  List<Map<String, dynamic>> _regulatoryApprovals = [];

  String _searchQuery = '';
  bool _isSavingDeclaration = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
      if (_selectedImportFileId != null) {
        _onImportFileSelected(_selectedImportFileId);
      }
    });
  }

  void _refreshData() {
    if (!ref.read(importFilesProvider).isLoading) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    if (!ref.read(acidSessionsProvider).isLoading) {
      ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
    }
    if (!ref.read(bankingDocumentsProvider).isLoading) {
      ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
    }
    if (!ref.read(customsTariffProvider).isLoading) {
      ref.read(customsTariffProvider.notifier).fetchTariffs();
    }
    if (!ref.read(purchaseOrdersProvider).isLoading) {
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    }
    if (!ref.read(draftBLReviewsProvider).isLoading) {
      ref.read(draftBLReviewsProvider.notifier).fetchReviews();
    }
    if (!ref.read(freightBookingProvider).isLoading) {
      ref.read(freightBookingProvider.notifier).fetchBookings();
    }
  }

  @override
  void dispose() {
    _declaration46NoCtrl.dispose();
    _acidNumberCtrl.dispose();
    _form4NumberCtrl.dispose();
    _blNumberCtrl.dispose();
    _customsValueEgpCtrl.dispose();
    _importDutyEgpCtrl.dispose();
    _vatEgpCtrl.dispose();
    _otherFeesEgpCtrl.dispose();
    _totalDutyAndTaxesCtrl.dispose();
    _submissionDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onImportFileSelected(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) {
      _acidNumberCtrl.clear();
      _form4NumberCtrl.clear();
      _blNumberCtrl.clear();
      _customsValueEgpCtrl.text = '0.00';
      _importDutyEgpCtrl.text = '0.00';
      _vatEgpCtrl.text = '0.00';
      _otherFeesEgpCtrl.text = '0.00';
      _totalDutyAndTaxesCtrl.text = '0.00';
      setState(() {
        _matchedTariffs = [];
        _regulatoryApprovals = [];
        _hasExemption = false;
        _appliedDutyRate = 5.0;
      });
      return;
    }

    final files = ref.read(importFilesProvider).valueOrNull ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    // 1. Auto load ACID number
    String acidVal = file.acidNumber ?? '';
    if (acidVal.isEmpty) {
      final acids = ref.read(acidSessionsProvider).valueOrNull ?? [];
      final matchedAcid = acids.where((a) => a.importFileId == fileId).firstOrNull;
      if (matchedAcid != null && matchedAcid.acidNumber.isNotEmpty) {
        acidVal = matchedAcid.acidNumber;
      }
    }
    _acidNumberCtrl.text = acidVal;

    // 2. Auto load Form 4 number
    String f4Val = file.form4No ?? '';
    if (f4Val.isEmpty) {
      final bankDocs = ref.read(bankingDocumentsProvider).valueOrNull ?? [];
      final matchedF4 = bankDocs.where((d) => d.importFileId == fileId && d.docType == 'Form 4').firstOrNull;
      if (matchedF4 != null && matchedF4.docReferenceNumber != 'PENDING' && matchedF4.docReferenceNumber.isNotEmpty) {
        f4Val = matchedF4.docReferenceNumber;
      }
    }
    if (f4Val.isEmpty) {
      f4Val = file.swiftNo != null && file.swiftNo!.isNotEmpty ? 'F4-${file.swiftNo}' : 'F4-ALX-${file.importFileCode}';
    }
    _form4NumberCtrl.text = f4Val;

    // 3. Auto load B/L number
    String blVal = '';
    final reviews = ref.read(draftBLReviewsProvider).valueOrNull ?? [];
    final linkedReview = reviews.where((r) => r.importFileId == fileId).firstOrNull;
    if (linkedReview != null) {
      final extractedBl = linkedReview.draftExtractedData?['draft_bl_number'] ??
          linkedReview.draftExtractedData?['bl_number'] ??
          linkedReview.systemDataSnapshot?['draft_bl_number'] ??
          linkedReview.draftBlNumber;
      if (extractedBl != null && extractedBl.toString().trim().isNotEmpty) {
        blVal = extractedBl.toString().trim();
      }
    }
    if (blVal.isEmpty) {
      final bookings = ref.read(freightBookingProvider).valueOrNull ?? [];
      final linkedBooking = bookings.where((b) => b.importFileId == fileId).firstOrNull;
      if (linkedBooking != null) {
        blVal = linkedBooking.bookingConfirmationNo ?? linkedBooking.bookingCode;
      }
    }
    if (blVal.isEmpty) {
      blVal = file.customFileNumber != null && file.customFileNumber!.isNotEmpty
          ? file.customFileNumber!
          : 'MEDUST-${file.importFileCode}';
    }
    _blNumberCtrl.text = blVal;

    _declaration46NoCtrl.text = '46-ALX-${file.importFileCode}';

    // 4. Extract HS Codes and calculate Customs Base & Duties (from Customs Duty Estimator logic)
    final allTariffs = ref.read(customsTariffProvider).valueOrNull ?? [];
    List<String> fileHsCodes = [];
    final poState = ref.read(purchaseOrdersProvider);
    final linkedPos = poState.purchaseOrders.where((p) => p.importFileId == fileId).toList();
    for (var po in linkedPos) {
      for (var item in po.items) {
        if (item.hsCode != null && item.hsCode!.trim().isNotEmpty) {
          fileHsCodes.add(item.hsCode!.trim());
        }
      }
    }
    if (fileHsCodes.isEmpty) {
      fileHsCodes = ['8471.30.00', '8517.62.00'];
    }

    final matched = allTariffs.where((t) => fileHsCodes.any((c) => t.hsCode.contains(c) || c.contains(t.hsCode))).toList();
    _matchedTariffs = matched.isNotEmpty ? matched : (allTariffs.isNotEmpty ? [allTariffs.first] : []);

    final primaryTariff = _matchedTariffs.isNotEmpty ? _matchedTariffs.first : null;
    final dutyRate = primaryTariff != null ? primaryTariff.customsDutyRate : 5.0;
    _appliedDutyRate = dutyRate;
    final vatRate = primaryTariff != null ? primaryTariff.vatRate : 14.0;
    final devRate = primaryTariff != null ? primaryTariff.developmentFeeRate : 0.0;
    final serviceRate = primaryTariff != null ? primaryTariff.customsServiceFeeRate : 1.0;

    // Calculate CIF in EGP
    const exchangeRate = 50.7917;
    final fobForeign = file.estimatedCost > 0
        ? file.estimatedCost
        : (file.invoicesData.isNotEmpty
            ? file.invoicesData.fold<double>(0.0, (sum, i) => sum + i.amount)
            : 12500.0);
    final fobEgp = fobForeign * exchangeRate;
    final freightEgp = fobEgp * 0.02; // 2% freight base
    final insuranceEgp = fobEgp * 0.025; // 2.5% deemed insurance
    final cifEgp = fobEgp + freightEgp + insuranceEgp;

    // Calculate Duty and Taxes
    final importDutyEgp = cifEgp * (dutyRate / 100.0);
    final devFeeEgp = cifEgp * (devRate / 100.0);
    final serviceFeeEgp = cifEgp * (serviceRate / 100.0);
    final otherFeesEgp = devFeeEgp + serviceFeeEgp;
    final vatBaseEgp = cifEgp + importDutyEgp + otherFeesEgp;
    final vatEgp = vatBaseEgp * (vatRate / 100.0);
    final totalDutiesEgp = importDutyEgp + vatEgp + otherFeesEgp;

    _customsValueEgpCtrl.text = cifEgp.toStringAsFixed(2);
    _importDutyEgpCtrl.text = importDutyEgp.toStringAsFixed(2);
    _vatEgpCtrl.text = vatEgp.toStringAsFixed(2);
    _otherFeesEgpCtrl.text = otherFeesEgp.toStringAsFixed(2);
    _totalDutyAndTaxesCtrl.text = totalDutiesEgp.toStringAsFixed(2);

    // 5. Exemption & Preferential Tariff Status
    final bool isEuropeanOrExempt = dutyRate == 0.0 || (file.portOfLoading != null && (file.portOfLoading!.contains('IT') || file.portOfLoading!.contains('FR') || file.portOfLoading!.contains('DE') || file.portOfLoading!.contains('ES')));
    _hasExemption = isEuropeanOrExempt;

    // 6. Regulatory Approvals & Inspections Board
    _regulatoryApprovals = [];
    for (var t in _matchedTariffs) {
      _regulatoryApprovals.add({
        'hs_code': t.hsCode,
        'description': t.hsDescription,
        'authority': t.regulatoryAuthority,
        'requires_inspection': t.requiresInspection,
        'requires_coo': t.requiresCoo,
        'requires_acid': t.requiresAcid,
        'note': t.priorApprovalNote,
        'status': 'APPROVED',
      });
    }

    if (_regulatoryApprovals.isEmpty) {
      _regulatoryApprovals.add({
        'hs_code': fileHsCodes.first,
        'description': null,
        'authority': null,
        'requires_inspection': true,
        'requires_coo': true,
        'requires_acid': true,
        'note': null,
        'status': 'APPROVED',
      });
    }

    setState(() {});
  }

  void _calculateTotalDuties() {
    final duty = double.tryParse(_importDutyEgpCtrl.text) ?? 0.0;
    final vat = double.tryParse(_vatEgpCtrl.text) ?? 0.0;
    final other = double.tryParse(_otherFeesEgpCtrl.text) ?? 0.0;
    final total = duty + vat + other;
    _totalDutyAndTaxesCtrl.text = total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.assignment_outlined,
        titleEn: 'Initial Declaration 46 Form',
        titleAr: 'قيد الإقرار الجمركي المبدئي',
      ),
      const VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Declaration 46 Registry',
        titleAr: 'سجل شهادات 46 ومتابعتها',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Customs Declaration 46 Registration',
      titleAr: 'الإقرار الجمركي المبدئي وشهادة 46 ك.م',
      headerIcon: Icons.description_outlined,
      headerColor: Colors.indigo,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (index) => setState(() => _selectedSubTab = index),
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: _refreshData,
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.customsDeclRefreshTooltip,
          onPressed: _refreshData,
        ),
      ],
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _selectedSubTab == 0 ? _buildInitialDeclarationView(l) : _buildDeclarationRegistryView(l),
        ),
      ),
    );
  }

  // --- SUB-VIEW 0: INITIAL DECLARATION FORM ---
  Widget _buildInitialDeclarationView(AppLocalizations l) {
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];

    final String exemptionTitle = _hasExemption
        ? l.customsDeclEur1ExemptionTitle
        : l.customsDeclMfnExemptionTitle(_appliedDutyRate.toStringAsFixed(1));

    final List<String> exemptionConditions = _hasExemption
        ? [
            l.customsDeclEur1Condition1,
            l.customsDeclEur1Condition2,
            l.customsDeclEur1Condition3,
          ]
        : [
            l.customsDeclMfnCondition1,
            l.customsDeclMfnCondition2,
          ];

    return Form(
      key: _declarationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informational Alert
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.customsDeclInfoBanner,
                    style: TextStyle(color: Colors.indigo.shade900, fontSize: 13, height: 1.4),
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
              labelText: l.customsDeclSelectFileLabel,
              hintText: l.customsDeclSearchFileHint,
              value: _selectedImportFileId,
              isRequired: true,
              items: importFiles.map((f) => SearchableDropdownItem<int>(
                value: f.importFileId,
                label: '${f.primaryNameWithCode} — ${f.supplierName} (${f.companyName})',
              )).toList(),
              onChanged: _onImportFileSelected,
            ),
          ),
          const SizedBox(height: 20),

          // Form Fields Card 1: Declaration Attributes
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
                  l.customsDeclAttributesHeader,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _declaration46NoCtrl,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        decoration: InputDecoration(
                          labelText: l.customsDeclDeclarationNoLabel,
                          prefixIcon: const Icon(Icons.pin, color: Colors.indigo),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _declaration46NoCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? l.customsDeclRequiredField : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _submissionDateCtrl,
                        decoration: InputDecoration(
                          labelText: l.customsDeclSubmissionDateLabel,
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _submissionDateCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _acidNumberCtrl,
                        decoration: InputDecoration(
                          labelText: l.customsDeclAcidNumberLabel,
                          prefixIcon: const Icon(Icons.qr_code),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _acidNumberCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _form4NumberCtrl,
                        decoration: InputDecoration(
                          labelText: l.customsDeclForm4NumberLabel,
                          prefixIcon: const Icon(Icons.account_balance),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _form4NumberCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _blNumberCtrl,
                        decoration: InputDecoration(
                          labelText: l.customsDeclBlNumberLabel,
                          prefixIcon: const Icon(Icons.assignment),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _blNumberCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  l.customsDeclDutiesHeader,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customsValueEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l.customsDeclCifValueLabel,
                          prefixIcon: const Icon(Icons.monetization_on),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _customsValueEgpCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _importDutyEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l.customsDeclImportDutyLabel,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _importDutyEgpCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotalDuties(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _vatEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l.customsDeclVatLabel,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _vatEgpCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotalDuties(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _totalDutyAndTaxesCtrl,
                        readOnly: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson),
                        decoration: InputDecoration(
                          labelText: l.customsDeclTotalDutiesLabel,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: l.customsDeclCopyValueTooltip,
                            onPressed: () => CopyHelper.copy(context, _totalDutyAndTaxesCtrl.text),
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Exemption & Trade Agreement Card
          if (_selectedImportFileId != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _hasExemption ? Colors.green.shade50 : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hasExemption ? Colors.green.shade400 : Colors.blueGrey.shade300, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_hasExemption ? Icons.verified : Icons.info_outline, color: _hasExemption ? Colors.green.shade800 : Colors.blueGrey.shade800, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.customsDeclExemptionHeader,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _hasExemption ? Colors.green.shade900 : Colors.blueGrey.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _hasExemption ? Colors.green.shade300 : Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer, size: 18, color: _hasExemption ? Colors.green : AppTheme.cobalt),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CopyableText(
                            exemptionTitle,
                            isSelectable: false,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _hasExemption ? Colors.green.shade900 : Colors.blueGrey.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.customsDeclExemptionConditionsHeader,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: _hasExemption ? Colors.green.shade900 : Colors.blueGrey.shade800),
                  ),
                  const SizedBox(height: 6),
                  ...exemptionConditions.map((cond) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: _hasExemption ? Colors.green : Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(child: CopyableText(cond, isSelectable: false, style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Regulatory Approvals, Inspections & Prior Approvals Card
          if (_regulatoryApprovals.isNotEmpty) ...[
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
                      const Icon(Icons.policy_outlined, color: AppTheme.cobalt, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.customsDeclRegulatoryHeader,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: [
                        DataColumn(label: Text(l.customsDeclColHsCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l.customsDeclColAuthority, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l.customsDeclColInspection, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l.customsDeclColCoo, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l.customsDeclColRequirements, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l.customsDeclColApprovalStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _regulatoryApprovals.map((appr) {
                        final String hsCode = appr['hs_code'] ?? '-';
                        final String authorityText = (appr['authority'] != null && appr['authority'].toString().trim().isNotEmpty)
                            ? appr['authority'].toString()
                            : l.customsDeclDefaultAuthority;
                        final String inspectionText = appr['requires_inspection'] == true ? l.customsDeclColInspection : '-';
                        final String cooText = appr['requires_coo'] == true ? l.customsDeclColCoo : '-';
                        final String noteText = (appr['note'] != null && appr['note'].toString().trim().isNotEmpty)
                            ? appr['note'].toString()
                            : (appr['requires_inspection'] == true ? l.customsDeclDefaultNote : l.customsDeclVisualInspectionNote);
                        final String statusText = l.customsDeclStatusFulfilled;
                        final String rowSummary = '$hsCode\t$authorityText\t$inspectionText\t$cooText\t$noteText\t$statusText';

                        return DataRow(
                          cells: [
                            DataCell(
                              CopyableTableCell(
                                value: hsCode,
                                rowSummary: rowSummary,
                                child: Text(hsCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontFamily: 'monospace')),
                              ),
                            ),
                            DataCell(
                              CopyableTableCell(
                                value: authorityText,
                                rowSummary: rowSummary,
                                child: Text(authorityText, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            DataCell(
                              CopyableTableCell(
                                value: inspectionText,
                                rowSummary: rowSummary,
                                child: Icon(
                                  appr['requires_inspection'] == true ? Icons.check_circle : Icons.remove_circle_outline,
                                  color: appr['requires_inspection'] == true ? Colors.amber.shade800 : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                            DataCell(
                              CopyableTableCell(
                                value: cooText,
                                rowSummary: rowSummary,
                                child: Icon(
                                  appr['requires_coo'] == true ? Icons.check_circle : Icons.remove_circle_outline,
                                  color: appr['requires_coo'] == true ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                            DataCell(
                              CopyableTableCell(
                                value: noteText,
                                rowSummary: rowSummary,
                                child: Text(noteText, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            DataCell(
                              CopyableTableCell(
                                value: statusText,
                                rowSummary: rowSummary,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Text(statusText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action Buttons (Save, Preview Summary, Export TSV)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSavingDeclaration ? null : () => _saveDeclaration46(l),
                icon: _isSavingDeclaration
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _isSavingDeclaration ? l.customsDeclSavingProgress : l.customsDeclSaveButton,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.visibility_outlined, color: Colors.indigo),
                label: Text(l.customsDeclPrintPreviewButton, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                onPressed: () => _showDeclarationSummaryDialog(l),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  side: const BorderSide(color: AppTheme.flatEmerald),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.table_chart_outlined, color: AppTheme.flatEmerald),
                label: Text(l.customsDeclExportTsvButton, style: const TextStyle(color: AppTheme.flatEmerald, fontWeight: FontWeight.bold)),
                onPressed: () => _copyDeclarationAsTsv(l),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW 1: REGISTRY & TARIFF ASSESSMENT VIEW (SCREEN 24) ---
  CustomsDeclarationAssessment _calculateAssessment(
    dynamic file,
    AppLocalizations l, {
    List<dynamic>? cachedAcids,
    List<dynamic>? cachedBankDocs,
    List<dynamic>? cachedReviews,
    List<dynamic>? cachedBookings,
    List<CustomsTariffModel>? cachedTariffs,
    List<dynamic>? cachedPos,
  }) {
    final int fileId = file.importFileId;
    final String declNo = '46-ALX-${file.importFileCode}';

    // 1. ACID
    String acidVal = file.acidNumber ?? '';
    if (acidVal.isEmpty) {
      final acids = cachedAcids ?? ref.read(acidSessionsProvider).valueOrNull ?? [];
      final matchedAcid = acids.where((a) => a.importFileId == fileId).firstOrNull;
      if (matchedAcid != null && matchedAcid.acidNumber.isNotEmpty) {
        acidVal = matchedAcid.acidNumber;
      }
    }
    if (acidVal.isEmpty) acidVal = '46-ACID-${file.importFileCode}';

    // 2. Form 4
    String f4Val = file.form4No ?? '';
    if (f4Val.isEmpty) {
      final bankDocs = cachedBankDocs ?? ref.read(bankingDocumentsProvider).valueOrNull ?? [];
      final matchedF4 = bankDocs.where((d) => d.importFileId == fileId && d.docType == 'Form 4').firstOrNull;
      if (matchedF4 != null && matchedF4.docReferenceNumber != 'PENDING' && matchedF4.docReferenceNumber.isNotEmpty) {
        f4Val = matchedF4.docReferenceNumber;
      }
    }
    if (f4Val.isEmpty) {
      f4Val = file.swiftNo != null && file.swiftNo!.isNotEmpty ? 'F4-${file.swiftNo}' : 'F4-ALX-${file.importFileCode}';
    }

    // 3. B/L
    String blVal = '';
    final reviews = cachedReviews ?? ref.read(draftBLReviewsProvider).valueOrNull ?? [];
    final linkedReview = reviews.where((r) => r.importFileId == fileId).firstOrNull;
    if (linkedReview != null) {
      final extractedBl = linkedReview.draftExtractedData?['draft_bl_number'] ??
          linkedReview.draftExtractedData?['bl_number'] ??
          linkedReview.systemDataSnapshot?['draft_bl_number'] ??
          linkedReview.draftBlNumber;
      if (extractedBl != null && extractedBl.toString().trim().isNotEmpty) {
        blVal = extractedBl.toString().trim();
      }
    }
    if (blVal.isEmpty) {
      final bookings = cachedBookings ?? ref.read(freightBookingProvider).valueOrNull ?? [];
      final linkedBooking = bookings.where((b) => b.importFileId == fileId).firstOrNull;
      if (linkedBooking != null) {
        blVal = linkedBooking.bookingConfirmationNo ?? linkedBooking.bookingCode;
      }
    }
    if (blVal.isEmpty) {
      blVal = file.customFileNumber != null && file.customFileNumber!.isNotEmpty
          ? file.customFileNumber!
          : 'MEDUST-${file.importFileCode}';
    }

    // 4. HS Codes and Tariffs
    final allTariffs = cachedTariffs ?? ref.read(customsTariffProvider).valueOrNull ?? [];
    List<String> fileHsCodes = [];
    final linkedPos = (cachedPos != null)
        ? cachedPos.where((p) => p.importFileId == fileId).toList()
        : ref.read(purchaseOrdersProvider).purchaseOrders.where((p) => p.importFileId == fileId).toList();
    for (var po in linkedPos) {
      for (var item in po.items) {
        if (item.hsCode != null && item.hsCode!.trim().isNotEmpty) {
          fileHsCodes.add(item.hsCode!.trim());
        }
      }
    }
    if (fileHsCodes.isEmpty) {
      fileHsCodes = ['8471.30.00', '8517.62.00'];
    }

    final matched = allTariffs.where((t) => fileHsCodes.any((c) => t.hsCode.contains(c) || c.contains(t.hsCode))).toList();
    final primaryTariff = matched.isNotEmpty ? matched.first : (allTariffs.isNotEmpty ? allTariffs.first : null);

    final String hsCode = primaryTariff?.hsCode ?? fileHsCodes.first;
    final String hsDesc = primaryTariff?.hsDescription ?? l.customsDeclDefaultItemDesc;
    final double dutyRate = primaryTariff != null ? primaryTariff.customsDutyRate : 5.0;
    final double vatRate = primaryTariff != null ? primaryTariff.vatRate : 14.0;
    final double devRate = primaryTariff != null ? primaryTariff.developmentFeeRate : 0.0;
    final double serviceRate = primaryTariff != null ? primaryTariff.customsServiceFeeRate : 1.0;

    // CIF in EGP
    const exchangeRate = 50.7917;
    final double fobForeign = file.estimatedCost > 0
        ? file.estimatedCost
        : (file.invoicesData.isNotEmpty
            ? file.invoicesData.fold<double>(0.0, (sum, i) => sum + i.amount)
            : 12500.0);
    final String currency = (file.estimatedCostCurrency != null && file.estimatedCostCurrency.toString().trim().isNotEmpty)
        ? file.estimatedCostCurrency.toString()
        : 'USD';
    final double fobEgp = fobForeign * exchangeRate;
    final double freightEgp = fobEgp * 0.02;
    final double insuranceEgp = fobEgp * 0.025;
    final double cifEgp = fobEgp + freightEgp + insuranceEgp;

    // Duties & Taxes
    final double importDutyEgp = cifEgp * (dutyRate / 100.0);
    final double devFeeEgp = cifEgp * (devRate / 100.0);
    final double serviceFeeEgp = cifEgp * (serviceRate / 100.0);
    final double otherFeesEgp = devFeeEgp + serviceFeeEgp;
    final double vatBaseEgp = cifEgp + importDutyEgp + otherFeesEgp;
    final double vatEgp = vatBaseEgp * (vatRate / 100.0);
    final double totalDutiesEgp = importDutyEgp + vatEgp + otherFeesEgp;

    // Exemption
    final bool isEuropeanOrExempt = dutyRate == 0.0 ||
        (file.portOfLoading != null &&
            (file.portOfLoading!.contains('IT') ||
                file.portOfLoading!.contains('FR') ||
                file.portOfLoading!.contains('DE') ||
                file.portOfLoading!.contains('ES')));
    final String exemptionTitle = isEuropeanOrExempt
        ? l.customsDeclEur1ExemptionTitle
        : l.customsDeclMfnExemptionTitle(dutyRate.toStringAsFixed(1));

    return CustomsDeclarationAssessment(
      declarationNo: declNo,
      importFileCode: file.importFileCode,
      primaryNameWithCode: file.primaryNameWithCode,
      supplierName: file.supplierName,
      companyName: file.companyName,
      acidNumber: acidVal,
      form4Number: f4Val,
      blNumber: blVal,
      hsCode: hsCode,
      hsDescription: hsDesc,
      fobForeign: fobForeign,
      currency: currency,
      exchangeRate: exchangeRate,
      fobEgp: fobEgp,
      freightEgp: freightEgp,
      insuranceEgp: insuranceEgp,
      cifEgp: cifEgp,
      dutyRate: dutyRate,
      importDutyEgp: importDutyEgp,
      devRate: devRate,
      devFeeEgp: devFeeEgp,
      serviceRate: serviceRate,
      serviceFeeEgp: serviceFeeEgp,
      otherFeesEgp: otherFeesEgp,
      vatRate: vatRate,
      vatBaseEgp: vatBaseEgp,
      vatEgp: vatEgp,
      totalDutiesEgp: totalDutiesEgp,
      hasExemption: isEuropeanOrExempt,
      exemptionTitle: exemptionTitle,
      registrationDate: DateTime.now().toString().substring(0, 10),
      status: l.customsDeclStatusRegisteredNafeza,
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  CopyableText(
                    value,
                    isSelectable: false,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeclarationRegistryView(AppLocalizations l) {
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final acids = ref.watch(acidSessionsProvider).valueOrNull ?? [];
    final bankDocs = ref.watch(bankingDocumentsProvider).valueOrNull ?? [];
    final reviews = ref.watch(draftBLReviewsProvider).valueOrNull ?? [];
    final bookings = ref.watch(freightBookingProvider).valueOrNull ?? [];
    final allTariffs = ref.watch(customsTariffProvider).valueOrNull ?? [];
    final pos = ref.watch(purchaseOrdersProvider).purchaseOrders;

    final filtered = importFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.importFileCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.primaryNameWithCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final assessments = filtered.map((f) => _calculateAssessment(
      f,
      l,
      cachedAcids: acids,
      cachedBankDocs: bankDocs,
      cachedReviews: reviews,
      cachedBookings: bookings,
      cachedTariffs: allTariffs,
      cachedPos: pos,
    )).toList();

    final totalCif = assessments.fold<double>(0.0, (sum, a) => sum + a.cifEgp);
    final totalDuties = assessments.fold<double>(0.0, (sum, a) => sum + a.totalDutiesEgp);
    final totalExemptions = assessments.where((a) => a.hasExemption).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Metrics Row
        Row(
          children: [
            _buildMetricCard(
              title: l.customsDeclMetricTotalDeclarations,
              value: assessments.length.toString(),
              icon: Icons.assignment_turned_in_outlined,
              color: Colors.indigo,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: l.customsDeclMetricTotalCif,
              value: '${totalCif.toStringAsFixed(2)} EGP',
              icon: Icons.monetization_on_outlined,
              color: AppTheme.cobalt,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: l.customsDeclMetricTotalDuties,
              value: '${totalDuties.toStringAsFixed(2)} EGP',
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.crimson,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: l.customsDeclMetricExemptions,
              value: totalExemptions.toString(),
              icon: Icons.verified_outlined,
              color: AppTheme.flatEmerald,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Search and Actions Toolbar
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: l.customsDeclRegistrySearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(width: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: const BorderSide(color: AppTheme.flatEmerald),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _exportRegistryTsv(assessments, l),
              icon: const Icon(Icons.table_view_outlined, color: AppTheme.flatEmerald),
              label: Text(l.customsDeclExportRegistryTsv, style: const TextStyle(color: AppTheme.flatEmerald, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: () => setState(() => _selectedSubTab = 0),
              icon: const Icon(Icons.add),
              label: Text(l.customsDeclRegisterNewButton),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Enhanced DataTable with Assessment & Actions
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
                DataColumn(label: Text(l.customsDeclColDeclarationNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclColFileNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclColSupplier, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclColHsCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclCifValueLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclTotalDutiesLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclColDeclarationStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l.customsDeclColActions, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: assessments.map((a) {
                final rowSummary = '${a.declarationNo}\t${a.primaryNameWithCode}\t${a.supplierName}\t${a.hsCode}\t${a.cifEgp.toStringAsFixed(2)}\t${a.totalDutiesEgp.toStringAsFixed(2)}\t${a.registrationDate}\t${a.status}';

                return DataRow(
                  cells: [
                    DataCell(
                      CopyableTableCell(
                        value: a.declarationNo,
                        rowSummary: rowSummary,
                        child: Text(a.declarationNo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: a.primaryNameWithCode,
                        rowSummary: rowSummary,
                        child: Text(a.primaryNameWithCode),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: a.supplierName,
                        rowSummary: rowSummary,
                        child: Text(a.supplierName),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: a.hsCode,
                        rowSummary: rowSummary,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blueGrey.shade200),
                          ),
                          child: Text(a.hsCode, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12)),
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: a.cifEgp.toStringAsFixed(2),
                        rowSummary: rowSummary,
                        child: Text('${a.cifEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.cobalt)),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: a.totalDutiesEgp.toStringAsFixed(2),
                        rowSummary: rowSummary,
                        child: Text('${a.totalDutiesEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: a.status,
                        rowSummary: rowSummary,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Text(a.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.analytics_outlined, color: Colors.indigo),
                        tooltip: l.customsDeclViewAssessmentTooltip,
                        onPressed: () => _showTariffAssessmentDialog(a, l),
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

  void _showTariffAssessmentDialog(CustomsDeclarationAssessment a, AppLocalizations l) {
    final assessmentSummaryText = '''
==================================================
${l.customsDeclAssessmentTitle}
${a.declarationNo} — ${a.primaryNameWithCode}
==================================================
[${l.customsDeclShipmentParticularsHeader}]
${l.customsDeclColDeclarationNo}: ${a.declarationNo}
${l.customsDeclColFileNumber}: ${a.primaryNameWithCode}
${l.customsDeclColSupplier}: ${a.supplierName}
${l.customsDeclAcidNumberLabel}: ${a.acidNumber}
${l.customsDeclForm4NumberLabel}: ${a.form4Number}
${l.customsDeclBlNumberLabel}: ${a.blNumber}
${l.customsDeclColRegistrationDate}: ${a.registrationDate}
--------------------------------------------------
[${l.customsDeclValuationBreakdownHeader}]
${l.customsDeclFxRateLabel}: ${a.exchangeRate.toStringAsFixed(4)}
${l.customsDeclFobForeignLabel}: ${a.fobForeign.toStringAsFixed(2)} ${a.currency} (${a.fobEgp.toStringAsFixed(2)} EGP)
${l.customsDeclFreightEgpLabel}: ${a.freightEgp.toStringAsFixed(2)} EGP
${l.customsDeclInsuranceEgpLabel}: ${a.insuranceEgp.toStringAsFixed(2)} EGP
${l.customsDeclCifTotalEgpLabel}: ${a.cifEgp.toStringAsFixed(2)} EGP
--------------------------------------------------
[${l.customsDeclTariffTaxesHeader}]
${l.customsDeclColHsCode}: ${a.hsCode} (${a.hsDescription})
${l.customsDeclImportDutyRateLabel} (${a.dutyRate.toStringAsFixed(1)}%): ${a.importDutyEgp.toStringAsFixed(2)} EGP
${l.customsDeclCustomsServicesFeeLabel} (${a.serviceRate.toStringAsFixed(1)}%): ${a.serviceFeeEgp.toStringAsFixed(2)} EGP
${a.devRate > 0 ? '${l.customsDeclDevFeeLabel} (${a.devRate.toStringAsFixed(1)}%): ${a.devFeeEgp.toStringAsFixed(2)} EGP\n' : ''}${l.customsDeclVatBaseLabel}: ${a.vatBaseEgp.toStringAsFixed(2)} EGP
${l.customsDeclVatRateLabel} (${a.vatRate.toStringAsFixed(1)}%): ${a.vatEgp.toStringAsFixed(2)} EGP
${l.customsDeclTotalDutiesLabel}: ${a.totalDutiesEgp.toStringAsFixed(2)} EGP
--------------------------------------------------
[${l.customsDeclExemptionHeader}]
${a.exemptionTitle}
==================================================
''';

    final tsvText = [
      [
        l.customsDeclColDeclarationNo,
        l.customsDeclColFileNumber,
        l.customsDeclColSupplier,
        l.customsDeclAcidNumberLabel,
        l.customsDeclForm4NumberLabel,
        l.customsDeclBlNumberLabel,
        l.customsDeclColHsCode,
        l.customsDeclFobForeignLabel,
        l.customsDeclFreightEgpLabel,
        l.customsDeclInsuranceEgpLabel,
        l.customsDeclCifTotalEgpLabel,
        l.customsDeclImportDutyRateLabel,
        l.customsDeclCustomsServicesFeeLabel,
        l.customsDeclDevFeeLabel,
        l.customsDeclVatBaseLabel,
        l.customsDeclVatRateLabel,
        l.customsDeclTotalDutiesLabel,
        l.customsDeclExemptionHeader,
      ].join('\t'),
      [
        a.declarationNo,
        a.primaryNameWithCode,
        a.supplierName,
        a.acidNumber,
        a.form4Number,
        a.blNumber,
        a.hsCode,
        '${a.fobForeign.toStringAsFixed(2)} ${a.currency}',
        a.freightEgp.toStringAsFixed(2),
        a.insuranceEgp.toStringAsFixed(2),
        a.cifEgp.toStringAsFixed(2),
        a.importDutyEgp.toStringAsFixed(2),
        a.serviceFeeEgp.toStringAsFixed(2),
        a.devFeeEgp.toStringAsFixed(2),
        a.vatBaseEgp.toStringAsFixed(2),
        a.vatEgp.toStringAsFixed(2),
        a.totalDutiesEgp.toStringAsFixed(2),
        a.exemptionTitle,
      ].join('\t')
    ].join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.customsDeclAssessmentTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Text(
                a.declarationNo,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SelectionArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.customsDeclAssessmentSubtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),

                  // 1. Shipment Particulars Card
                  _buildAssessmentCard(
                    title: l.customsDeclShipmentParticularsHeader,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.indigo,
                    children: [
                      _buildAssessmentRow(l.customsDeclColDeclarationNo, a.declarationNo),
                      _buildAssessmentRow(l.customsDeclColFileNumber, a.primaryNameWithCode),
                      _buildAssessmentRow(l.customsDeclColSupplier, a.supplierName),
                      _buildAssessmentRow(l.customsDeclAcidNumberLabel, a.acidNumber),
                      _buildAssessmentRow(l.customsDeclForm4NumberLabel, a.form4Number),
                      _buildAssessmentRow(l.customsDeclBlNumberLabel, a.blNumber),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Valuation Breakdown Card (CIF)
                  _buildAssessmentCard(
                    title: l.customsDeclValuationBreakdownHeader,
                    icon: Icons.monetization_on_outlined,
                    color: AppTheme.cobalt,
                    children: [
                      _buildAssessmentRow(l.customsDeclFxRateLabel, '${a.exchangeRate.toStringAsFixed(4)} EGP/USD'),
                      _buildAssessmentRow(l.customsDeclFobForeignLabel, '${a.fobForeign.toStringAsFixed(2)} ${a.currency} (${a.fobEgp.toStringAsFixed(2)} EGP)'),
                      _buildAssessmentRow(l.customsDeclFreightEgpLabel, '${a.freightEgp.toStringAsFixed(2)} EGP'),
                      _buildAssessmentRow(l.customsDeclInsuranceEgpLabel, '${a.insuranceEgp.toStringAsFixed(2)} EGP'),
                      const Divider(height: 16),
                      _buildAssessmentRow(l.customsDeclCifTotalEgpLabel, '${a.cifEgp.toStringAsFixed(2)} EGP', isBold: true, valueColor: AppTheme.cobalt),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Tariff Taxes & Duties Card (MD-008 Engine)
                  _buildAssessmentCard(
                    title: l.customsDeclTariffTaxesHeader,
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.crimson,
                    children: [
                      _buildAssessmentRow(l.customsDeclColHsCode, '${a.hsCode} (${a.hsDescription})'),
                      _buildAssessmentRow('${l.customsDeclImportDutyRateLabel} (${a.dutyRate.toStringAsFixed(1)}%)', '${a.importDutyEgp.toStringAsFixed(2)} EGP'),
                      _buildAssessmentRow('${l.customsDeclCustomsServicesFeeLabel} (${a.serviceRate.toStringAsFixed(1)}%)', '${a.serviceFeeEgp.toStringAsFixed(2)} EGP'),
                      if (a.devRate > 0)
                        _buildAssessmentRow('${l.customsDeclDevFeeLabel} (${a.devRate.toStringAsFixed(1)}%)', '${a.devFeeEgp.toStringAsFixed(2)} EGP'),
                      _buildAssessmentRow(l.customsDeclVatBaseLabel, '${a.vatBaseEgp.toStringAsFixed(2)} EGP'),
                      _buildAssessmentRow('${l.customsDeclVatRateLabel} (${a.vatRate.toStringAsFixed(1)}%)', '${a.vatEgp.toStringAsFixed(2)} EGP'),
                      const Divider(height: 16),
                      _buildAssessmentRow(l.customsDeclTotalDutiesLabel, '${a.totalDutiesEgp.toStringAsFixed(2)} EGP', isBold: true, valueColor: AppTheme.crimson),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Exemption & Trade Agreement Card
                  _buildAssessmentCard(
                    title: l.customsDeclExemptionHeader,
                    icon: a.hasExemption ? Icons.verified : Icons.info_outline,
                    color: a.hasExemption ? AppTheme.flatEmerald : Colors.blueGrey,
                    children: [
                      _buildAssessmentRow(l.customsDeclExemptionHeader, a.exemptionTitle, isBold: true, valueColor: a.hasExemption ? AppTheme.flatEmerald : Colors.blueGrey.shade800),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              CopyHelper.copy(context, assessmentSummaryText, customMessage: l.customsDeclAssessmentCopySuccess);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.customsDeclCopySummarySuccess),
          ),
          TextButton.icon(
            onPressed: () {
              CopyHelper.copy(context, tsvText, customMessage: l.customsDeclExportSuccess);
            },
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: Text(l.customsDeclExportTsvButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.customsDeclCloseDialog),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAssessmentRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CopyableText(
                    value,
                    isSelectable: false,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                      color: valueColor ?? Colors.grey.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeclarationSummaryDialog(AppLocalizations l) {
    final files = ref.read(importFilesProvider).valueOrNull ?? [];
    final file = files.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;

    final declSummaryText = '''
==================================================
${l.customsDeclPreviewTitle}
==================================================
${l.customsDeclColDeclarationNo}: ${_declaration46NoCtrl.text}
${l.customsDeclSubmissionDateLabel.replaceAll('*', '').trim()}: ${_submissionDateCtrl.text}
${l.customsDeclColFileNumber}: ${file?.primaryNameWithCode ?? '-'}
${l.customsDeclColSupplier}: ${file?.supplierName ?? '-'}
${l.customsDeclAcidNumberLabel}: ${_acidNumberCtrl.text}
${l.customsDeclForm4NumberLabel}: ${_form4NumberCtrl.text}
${l.customsDeclBlNumberLabel}: ${_blNumberCtrl.text}
--------------------------------------------------
${l.customsDeclDutiesHeader}
${l.customsDeclCifValueLabel}: ${_customsValueEgpCtrl.text}
${l.customsDeclImportDutyLabel}: ${_importDutyEgpCtrl.text}
${l.customsDeclVatLabel}: ${_vatEgpCtrl.text}
${l.customsDeclTotalDutiesLabel}: ${_totalDutyAndTaxesCtrl.text}
--------------------------------------------------
${l.customsDeclExemptionHeader}
${_hasExemption ? l.customsDeclEur1ExemptionTitle : l.customsDeclMfnExemptionTitle(_appliedDutyRate.toStringAsFixed(1))}
==================================================
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.customsDeclPreviewTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SelectionArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  declSummaryText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              CopyHelper.copy(context, declSummaryText, customMessage: l.customsDeclCopySummarySuccess);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.customsDeclCopySummarySuccess),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.customsDeclCloseDialog),
          ),
        ],
      ),
    );
  }

  void _copyDeclarationAsTsv(AppLocalizations l) {
    final files = ref.read(importFilesProvider).valueOrNull ?? [];
    final file = files.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;

    final headers = [
      l.customsDeclColDeclarationNo,
      l.customsDeclSubmissionDateLabel.replaceAll('*', '').trim(),
      l.customsDeclColFileNumber,
      l.customsDeclColSupplier,
      l.customsDeclAcidNumberLabel,
      l.customsDeclForm4NumberLabel,
      l.customsDeclBlNumberLabel,
      l.customsDeclCifValueLabel,
      l.customsDeclImportDutyLabel,
      l.customsDeclVatLabel,
      l.customsDeclTotalDutiesLabel,
      l.customsDeclExemptionHeader.replaceAll(':', '').trim(),
    ].join('\t');

    final values = [
      _declaration46NoCtrl.text,
      _submissionDateCtrl.text,
      file?.primaryNameWithCode ?? '-',
      file?.supplierName ?? '-',
      _acidNumberCtrl.text,
      _form4NumberCtrl.text,
      _blNumberCtrl.text,
      _customsValueEgpCtrl.text,
      _importDutyEgpCtrl.text,
      _vatEgpCtrl.text,
      _totalDutyAndTaxesCtrl.text,
      _hasExemption ? l.customsDeclEur1ExemptionTitle : l.customsDeclMfnExemptionTitle(_appliedDutyRate.toStringAsFixed(1)),
    ].join('\t');

    final tsv = '$headers\n$values';
    CopyHelper.copy(context, tsv, customMessage: l.customsDeclExportSuccess);
  }

  void _exportRegistryTsv(List<CustomsDeclarationAssessment> items, AppLocalizations l) {
    final headerRow = [
      l.customsDeclColDeclarationNo,
      l.customsDeclColFileNumber,
      l.customsDeclColSupplier,
      l.customsDeclColHsCode,
      l.customsDeclCifValueLabel,
      l.customsDeclImportDutyLabel,
      l.customsDeclVatLabel,
      l.customsDeclTotalDutiesLabel,
      l.customsDeclColRegistrationDate,
      l.customsDeclColDeclarationStatus,
    ].join('\t');

    final dataRows = items.map((a) {
      return '${a.declarationNo}\t${a.primaryNameWithCode}\t${a.supplierName}\t${a.hsCode}\t${a.cifEgp.toStringAsFixed(2)}\t${a.importDutyEgp.toStringAsFixed(2)}\t${a.vatEgp.toStringAsFixed(2)}\t${a.totalDutiesEgp.toStringAsFixed(2)}\t${a.registrationDate}\t${a.status}';
    }).toList();

    final tsv = [headerRow, ...dataRows].join('\n');
    CopyHelper.copy(context, tsv, customMessage: l.customsDeclCopyAllSuccess);
  }

  Future<void> _saveDeclaration46(AppLocalizations l) async {
    if (!_declarationFormKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.customsDeclSelectFileWarning), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSavingDeclaration = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isSavingDeclaration = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.customsDeclSaveSuccess), backgroundColor: AppTheme.emerald),
      );
      setState(() => _selectedSubTab = 1);
    }
  }
}
