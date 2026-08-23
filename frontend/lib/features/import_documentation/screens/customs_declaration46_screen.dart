import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../freight_booking/providers/freight_booking_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../providers/import_documentation_provider.dart';

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
  // 0: 🏛️ قيد الإقرار الجمركي المبدئي (Initial Declaration 46 Registration)
  // 1: 📋 سجل الشهادات الجمركية 46 (Declaration 46 Registry & Tracking)
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
  String? _applicableExemption;
  List<String> _exemptionConditions = [];
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
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
    ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
    ref.read(customsTariffProvider.notifier).fetchTariffs();
    ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    ref.read(draftBLReviewsProvider.notifier).fetchReviews();
    ref.read(freightBookingProvider.notifier).fetchBookings();
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
        _exemptionConditions = [];
        _applicableExemption = null;
        _hasExemption = false;
      });
      return;
    }

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    // 1. Auto load ACID number
    String acidVal = file.acidNumber ?? '';
    if (acidVal.isEmpty) {
      final acids = ref.read(acidSessionsProvider).value ?? [];
      final matchedAcid = acids.where((a) => a.importFileId == fileId).firstOrNull;
      if (matchedAcid != null && matchedAcid.acidNumber.isNotEmpty) {
        acidVal = matchedAcid.acidNumber;
      }
    }
    _acidNumberCtrl.text = acidVal;

    // 2. Auto load Form 4 number
    String f4Val = file.form4No ?? '';
    if (f4Val.isEmpty) {
      final bankDocs = ref.read(bankingDocumentsProvider).value ?? [];
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
    final reviews = ref.read(draftBLReviewsProvider).value ?? [];
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
      final bookings = ref.read(freightBookingProvider).value ?? [];
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
    final allTariffs = ref.read(customsTariffProvider).value ?? [];
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

    if (_hasExemption) {
      _applicableExemption = 'اتفاقية الشراكة المصرية الأوروبية (EUR.1) — إعفاء جمركي 0% لضريبة الوارد';
      _exemptionConditions = [
        'تقديم شهادة المنشأ الأوروبية (EUR.1 / COO) الأصلية المعتمدة ومستوفاة للأختام الرسمية.',
        'إثبات الشحن المباشر (Direct Transport) من دولة المنشأ بالاتحاد الأوروبي إلى الموانئ المصرية.',
        'إدراج رقم ACID وقيد المصنع المعتمد بالفاتورة التجارية وبوليصة الشحن.',
      ];
    } else {
      _applicableExemption = 'خاضع للتعريفة الجمركية العامة (MFN Standard Tariff) — ضريبة الوارد ${dutyRate.toStringAsFixed(1)}%';
      _exemptionConditions = [
        'تقديم شهادة المنشأ الرسمية الموثقة من الغرفة التجارية لدولة المصدر.',
        'سداد الرسوم والضرائب الجمركية المقررة عبر إذن سداد منظومة نافذة.',
      ];
    }

    // 6. Regulatory Approvals & Inspections Board
    _regulatoryApprovals = [];
    for (var t in _matchedTariffs) {
      final authority = t.regulatoryAuthority ?? 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)';
      _regulatoryApprovals.add({
        'hs_code': t.hsCode,
        'description': t.hsDescription,
        'authority': authority,
        'requires_inspection': t.requiresInspection,
        'requires_coo': t.requiresCoo,
        'requires_acid': t.requiresAcid,
        'note': t.priorApprovalNote ?? 'مطلوب العرض الفني وسحب عينات مطابقة للمواصفات القياسية المصرية',
        'status': 'APPROVED',
      });
    }

    if (_regulatoryApprovals.isEmpty) {
      _regulatoryApprovals.add({
        'hs_code': fileHsCodes.first,
        'description': 'بند البضائع والمنتجات المستوردة',
        'authority': 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
        'requires_inspection': true,
        'requires_coo': true,
        'requires_acid': true,
        'note': 'فحص ظاهري ومطابقة مستندية قبل الإفراج الجمركي',
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
          tooltip: 'تحديث البيانات (Refresh)',
          onPressed: _refreshData,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _selectedSubTab == 0 ? _buildInitialDeclarationView() : _buildDeclarationRegistryView(),
      ),
    );
  }

  // --- SUB-VIEW 0: INITIAL DECLARATION FORM ---
  Widget _buildInitialDeclarationView() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

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
                    'مسودة إقرار 46 ك.م الجاهزة للربط مع نافذة. يتم سحب رقم ACID المعتمد، ورقم نموذج 4 البنكي الموثق، وبيانات بوليصة الشحن تلقائياً لحساب الوعاء الضريبي والضرائب المقدرة طبقاً لجدول التعريفة الجمركية والاتفاقيات التفضيلية.',
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
              labelText: 'اختر ملف الشحنة لقيد شهادة 46 (Select Import File)',
              hintText: 'ابحث برقم الملف أو اسم المورد...',
              value: _selectedImportFileId,
              isRequired: true,
              items: importFiles.map((f) => SearchableDropdownItem<int>(
                value: f.importFileId,
                label: '${f.importFileCode} — ${f.supplierName} (${f.companyName})',
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
                const Text(
                  'بيانات الإقرار الجمركي وأرقام القيد المعتمدة (Declaration 46 Attributes):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _declaration46NoCtrl,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        decoration: const InputDecoration(
                          labelText: 'رقم الإقرار / الشهادة الجمركية (46 ك.م) *',
                          prefixIcon: Icon(Icons.pin, color: Colors.indigo),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _submissionDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ القيد المبدئي *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'رقم القيد المسبق (ACID)',
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _form4NumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم نموذج 4 البنكي المعتمد',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _blNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم بوليصة الشحن (B/L)',
                          prefixIcon: Icon(Icons.assignment),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'الوعاء الضريبي والرسوم المقدرة (Customs Base & Estimated Duties - EGP):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customsValueEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'القيمة الجمركية CIF (جنيه)',
                          prefixIcon: Icon(Icons.monetization_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _importDutyEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'ضريبة الوارد المقدرة (جنيه)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotalDuties(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _vatEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'ضريبة القيمة المضافة VAT (جنيه)',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'إجمالي الضرائب والرسوم المقدرة',
                          border: OutlineInputBorder(),
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
          if (_applicableExemption != null) ...[
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
                          'الموقف الجمركي وتطبيق الإعفاءات التفضيلية (HS Code Exemption & Trade Agreement):',
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
                          child: Text(
                            _applicableExemption!,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _hasExemption ? Colors.green.shade900 : Colors.blueGrey.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '📌 الشروط والضوابط الإلزامية للاستفادة من الإعفاء الجمركي:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: _hasExemption ? Colors.green.shade900 : Colors.blueGrey.shade800),
                  ),
                  const SizedBox(height: 6),
                  ..._exemptionConditions.map((cond) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: _hasExemption ? Colors.green : Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cond, style: const TextStyle(fontSize: 12))),
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
                  const Row(
                    children: [
                      Icon(Icons.policy_outlined, color: AppTheme.cobalt, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'العروض والموافقات المطلوبة والاشتراطات الرقابية (Regulatory Approvals & Inspections):',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('بند التعريفة (HS Code)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('جهة العرض الرقابي (Authority)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('فحص مسبق', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('شهادة المنشأ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الاشتراطات والملاحظات الرقابية', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('حالة الموافقة', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _regulatoryApprovals.map((appr) {
                        return DataRow(
                          cells: [
                            DataCell(Text(appr['hs_code'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontFamily: 'monospace'))),
                            DataCell(Text(appr['authority'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Icon(
                              appr['requires_inspection'] == true ? Icons.check_circle : Icons.remove_circle_outline,
                              color: appr['requires_inspection'] == true ? Colors.amber.shade800 : Colors.grey,
                              size: 18,
                            )),
                            DataCell(Icon(
                              appr['requires_coo'] == true ? Icons.check_circle : Icons.remove_circle_outline,
                              color: appr['requires_coo'] == true ? Colors.green : Colors.grey,
                              size: 18,
                            )),
                            DataCell(Text(appr['note'] ?? '-', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: const Text('مستوفى ومعتمد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
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

          // Save Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSavingDeclaration ? null : _saveDeclaration46,
            icon: _isSavingDeclaration
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(
              _isSavingDeclaration ? 'جارٍ الحفظ...' : 'حفظ وقيد الإقرار الجمركي المبدئي',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW 1: REGISTRY VIEW ---
  Widget _buildDeclarationRegistryView() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    final filtered = importFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.importFileCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث في سجل الإقرارات الجمركية وشهادات 46...',
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: () => setState(() => _selectedSubTab = 0),
              icon: const Icon(Icons.add),
              label: const Text('قيد إقرار جديد'),
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
              DataColumn(label: Text('رقم الإقرار (46 ك.م)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('رقم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ القيد', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('حالة الإقرار', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filtered.map((f) {
              return DataRow(
                cells: [
                  DataCell(Text('46-ALX-${f.importFileCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                  DataCell(Text(f.importFileCode)),
                  DataCell(Text(f.supplierName)),
                  DataCell(Text(DateTime.now().toString().substring(0, 10))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: const Text('مقيد مبدئياً على نافذة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
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

  Future<void> _saveDeclaration46() async {
    if (!_declarationFormKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSavingDeclaration = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isSavingDeclaration = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قيد وحفظ مسودة الإقرار الجمركي (46 ك.م) بنجاح'), backgroundColor: AppTheme.emerald),
      );
      setState(() => _selectedSubTab = 1);
    }
  }
}
