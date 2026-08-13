import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';
import '../services/customs_pdf_service.dart';

class CustomsTariffScreen extends ConsumerStatefulWidget {
  const CustomsTariffScreen({super.key});

  @override
  ConsumerState<CustomsTariffScreen> createState() =>
      _CustomsTariffScreenState();
}

class _CustomsTariffScreenState extends ConsumerState<CustomsTariffScreen> {
  final TextEditingController _searchController = TextEditingController();

  double _numToDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customsTariffProvider.notifier).fetchTariffs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tariffsAsync = ref.watch(customsTariffProvider);
    final showInactive = ref.watch(showInactiveCustomsTariffsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customs Tariff / HS Code Master (MD-008)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Egyptian Customs Duty Rates, VAT, Schedule Taxes, Development Fees & Import Regulations',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    const BackToDashboardButton(),
                    ElevatedButton.icon(

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Import Excel/CSV'),
                      onPressed: () => _handleExcelImport(context, ref),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('Duty Calculator'),
                      onPressed: () => _showDutyCalculatorDialog(context, ref),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ إضافة بند (Add HS Code)'),
                      onPressed: () => _showTariffDialog(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Filter Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref
                          .read(customsTariffSearchQueryProvider.notifier)
                          .state = val.trim();
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search by HS Code, Description, or Category...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(customsTariffSearchQueryProvider
                                        .notifier)
                                    .state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text('Show Inactive',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Switch(
                      value: showInactive,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) {
                        ref
                            .read(showInactiveCustomsTariffsProvider.notifier)
                            .state = val;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Area
            Expanded(
              child: tariffsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.cobalt),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tariffs) {
                  if (tariffs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Customs Tariffs found.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  return _buildTariffTable(context, ref, tariffs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Electronics':
        return AppTheme.cobalt;
      case 'Automotive':
      case 'Automotive Parts':
        return AppTheme.orange;
      case 'Pharmaceuticals':
        return AppTheme.emerald;
      case 'Agriculture & Food':
        return const Color(0xFF27AE60);
      case 'Luxury Goods':
        return AppTheme.crimson;
      case 'Home Appliances':
        return const Color(0xFF8E44AD);
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildTariffTable(
      BuildContext context, WidgetRef ref, List<CustomsTariffModel> tariffs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width > 1200
                    ? MediaQuery.of(context).size.width - 250
                    : 1150,
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(110),
                  1: FlexColumnWidth(3),
                  2: FixedColumnWidth(130),
                  3: FixedColumnWidth(180),
                  4: FixedColumnWidth(130),
                  5: FixedColumnWidth(80),
                  6: FixedColumnWidth(220),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.charcoal),
                    children: [
                      'HS Code',
                      'Description & Authority',
                      'Category',
                      'Tax Rates Breakdown',
                      'Requirements',
                      'Status',
                      'Actions'
                    ]
                        .map((h) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Text(
                                h,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  // Data Rows
                  ...tariffs.asMap().entries.map((entry) {
                    final tariff = entry.value;
                    final isEven = entry.key % 2 == 0;
                    final catColor = _getCategoryColor(tariff.customsCategory);

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : Colors.grey.shade50,
                      ),
                      children: [
                        // HS Code Badge
                        _cell(
                          child: InkWell(
                            onTap: () =>
                                _showNafezaDetailsDialog(context, ref, tariff),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppTheme.cobalt.withOpacity(0.3)),
                              ),
                              child: Text(
                                tariff.hsCode,
                                style: const TextStyle(
                                  color: AppTheme.cobalt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Description & Regulatory Authority
                        _cell(
                          child: InkWell(
                            onTap: () =>
                                _showNafezaDetailsDialog(context, ref, tariff),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tariff.hsDescription,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.charcoal,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (tariff.regulatoryAuthority != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Gov: ${tariff.regulatoryAuthority}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Category
                        _cell(
                          child: tariff.customsCategory != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    tariff.customsCategory!,
                                    style: TextStyle(
                                      color: catColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : const Text('—',
                                  style: TextStyle(color: Colors.grey)),
                        ),

                        // Tax Rates Breakdown
                        _cell(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _rateBadge('Duty', '${tariff.customsDutyRate}%',
                                  AppTheme.cobalt),
                              _rateBadge('VAT', '${tariff.vatRate}%',
                                  AppTheme.emerald),
                              if (tariff.scheduleTaxRate > 0)
                                _rateBadge(
                                    'Sched',
                                    '${tariff.scheduleTaxRate}%',
                                    AppTheme.crimson),
                              if (tariff.developmentFeeRate > 0)
                                _rateBadge(
                                    'Dev',
                                    '${tariff.developmentFeeRate}%',
                                    AppTheme.orange),
                            ],
                          ),
                        ),

                        // Requirements (COO, Inspection, ACID)
                        _cell(
                          child: Row(
                            children: [
                              _reqIcon('ACID', tariff.requiresAcid),
                              const SizedBox(width: 4),
                              _reqIcon('COO', tariff.requiresCoo),
                              const SizedBox(width: 4),
                              _reqIcon('INSP', tariff.requiresInspection),
                            ],
                          ),
                        ),

                        // Status
                        _cell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tariff.isActive
                                  ? AppTheme.emerald.withOpacity(0.1)
                                  : AppTheme.crimson.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tariff.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: tariff.isActive
                                    ? AppTheme.emerald
                                    : AppTheme.crimson,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),

                        // Actions
                        _cell(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.article_outlined,
                                    color: AppTheme.cobalt, size: 20),
                                tooltip: 'تفاصيل البند (Nafeza Details)',
                                onPressed: () => _showNafezaDetailsDialog(
                                    context, ref, tariff),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calculate,
                                    color: AppTheme.emerald, size: 20),
                                tooltip: 'Calculate Customs Duty',
                                onPressed: () => _showDutyCalculatorDialog(
                                    context, ref,
                                    initialHsCode: tariff.hsCode),
                              ),
                              IconButton(
                                icon: const Icon(Icons.verified_user_outlined,
                                    color: Colors.blueGrey, size: 20),
                                tooltip: 'Manual Audit / Verify Tariff',
                                onPressed: () => _showVerifyTariffDialog(
                                    context, ref, tariff),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.grey, size: 20),
                                tooltip: 'Edit Tariff',
                                onPressed: () => _showTariffDialog(context, ref,
                                    tariff: tariff),
                              ),
                              Tooltip(
                                message: tariff.isActive
                                    ? 'Deactivate Tariff'
                                    : 'Reactivate Tariff',
                                child: Switch(
                                  value: tariff.isActive,
                                  activeColor: AppTheme.emerald,
                                  inactiveThumbColor: AppTheme.crimson,
                                  onChanged: (_) async {
                                    await ref
                                        .read(customsTariffProvider.notifier)
                                        .toggleActive(
                                            tariff.tariffId, tariff.isActive);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rateBadge(String label, String rate, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $rate',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _reqIcon(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppTheme.cobalt.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color:
              active ? AppTheme.cobalt.withOpacity(0.4) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: active ? AppTheme.cobalt : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => TableRowInkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );

  // ==================================================
  // Add / Edit Customs Tariff Dialog (MD-008)
  // ==================================================

  void _showTariffDialog(BuildContext context, WidgetRef ref,
      {CustomsTariffModel? tariff}) {
    final hsCtrl = TextEditingController(text: tariff?.hsCode ?? '');
    final descCtrl = TextEditingController(text: tariff?.hsDescription ?? '');
    final catCtrl = TextEditingController(text: tariff?.customsCategory ?? '');

    final dutyCtrl = TextEditingController(
        text: tariff?.customsDutyRate.toString() ?? '0.00');
    final vatCtrl =
        TextEditingController(text: tariff?.vatRate.toString() ?? '14.00');
    final schedCtrl = TextEditingController(
        text: tariff?.scheduleTaxRate.toString() ?? '0.00');
    final devCtrl = TextEditingController(
        text: tariff?.developmentFeeRate.toString() ?? '0.00');
    final importFeeCtrl =
        TextEditingController(text: tariff?.importFeeRate.toString() ?? '0.00');

    final authCtrl =
        TextEditingController(text: tariff?.regulatoryAuthority ?? '');
    final priorApprovalCtrl =
        TextEditingController(text: tariff?.priorApprovalNote ?? '');
    final notesCtrl = TextEditingController(text: tariff?.notes ?? '');

    bool requiresCoo = tariff?.requiresCoo ?? false;
    bool requiresInspection = tariff?.requiresInspection ?? false;
    bool requiresAcid = tariff?.requiresAcid ?? true;

    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tariff == null
              ? 'إضافة بند جمركي جديد (Add HS Code MD-008)'
              : 'تعديل بند جمركي - ${tariff.hsCode}'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: hsCtrl,
                            enabled: tariff == null,
                            decoration: const InputDecoration(
                              labelText: 'رقم البند (HS Code) *',
                              hintText: 'مثال: 8415820010 أو 8471.30.00',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'مطلوب إدخال رقم البند'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: catCtrl,
                            decoration: const InputDecoration(
                              labelText: 'التصنيف الجمركي (Category)',
                              hintText: 'مثال: أجهزة تكييف / إلكترونيات',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'نص / وصف البند الجمركي (HS Description) *',
                      ),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'مطلوب إدخال نص البند'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('نسب الضرائب والرسوم (%) :',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dutyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'ضريبة الوارد % *'),
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null)
                                    ? 'غير صحيح'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: vatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'ضريبة القيمة المضافة % *'),
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null)
                                    ? 'غير صحيح'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: schedCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'ضريبة الجدول %'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: devCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'رسم التنمية %'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: importFeeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'رسم الوارد %'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('اشتراطات المستندات والإفراج الرقابي :',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal)),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: requiresAcid,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) =>
                              setDialogState(() => requiresAcid = val ?? true),
                        ),
                        const Text('يتطلب ACID',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: requiresCoo,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) =>
                              setDialogState(() => requiresCoo = val ?? false),
                        ),
                        const Text('يتطلب شهادة منشأ (COO)',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: requiresInspection,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) => setDialogState(
                              () => requiresInspection = val ?? false),
                        ),
                        const Text('يتطلب فحص مطابقة',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: authCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الجهة الرقابية المختصة',
                        hintText:
                            'مثال: الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priorApprovalCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'المستندات، الأعمال، والاشتراطات الرقابية المسبقة',
                        hintText:
                            'مثال: لا يصرح باستيراد الصنف إلا بموافقة مختومة بخاتم شعار الجمهورية أو تسجيل المصانع 43',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات إضافية / قيود الجمرك',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);

                      final data = {
                        'hs_code': hsCtrl.text.trim(),
                        'hs_description': descCtrl.text.trim(),
                        'customs_category': catCtrl.text.trim().isEmpty
                            ? null
                            : catCtrl.text.trim(),
                        'customs_duty_rate': double.parse(dutyCtrl.text.trim()),
                        'vat_rate': double.parse(vatCtrl.text.trim()),
                        'schedule_tax_rate':
                            double.parse(schedCtrl.text.trim()),
                        'development_fee_rate':
                            double.parse(devCtrl.text.trim()),
                        'import_fee_rate':
                            double.parse(importFeeCtrl.text.trim()),
                        'requires_coo': requiresCoo,
                        'requires_inspection': requiresInspection,
                        'requires_acid': requiresAcid,
                        'regulatory_authority': authCtrl.text.trim().isEmpty
                            ? null
                            : authCtrl.text.trim(),
                        'prior_approval_note':
                            priorApprovalCtrl.text.trim().isEmpty
                                ? null
                                : priorApprovalCtrl.text.trim(),
                        'notes': notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      };

                      String? error;
                      if (tariff == null) {
                        error = await ref
                            .read(customsTariffProvider.notifier)
                            .createTariff(data);
                      } else {
                        error = await ref
                            .read(customsTariffProvider.notifier)
                            .updateTariff(tariff.tariffId, data);
                      }

                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(error),
                              backgroundColor: AppTheme.crimson));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tariff == null
                                  ? 'تمت إضافة البند الجمركي بنجاح!'
                                  : 'تم تحديث البند الجمركي بنجاح!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                          Navigator.pop(ctx);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(tariff == null ? 'إضافة البند' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Nafeza Official Detail Modal ("تفاصيل البند") matching user screenshot
  // ==================================================

  void _showNafezaDetailsDialog(
      BuildContext context, WidgetRef ref, CustomsTariffModel tariff) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ref
                .read(customsTariffProvider.notifier)
                .fetchAgreements(tariff.hsCode),
            builder: (context, snapshot) {
              final agreements = snapshot.data ?? [];
              final isLoadingAgreements =
                  snapshot.connectionState == ConnectionState.waiting;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header matching Screenshot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.article_outlined,
                              color: AppTheme.charcoal, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'تفاصيل البند',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Code & Description Section
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: AppTheme.charcoal, fontSize: 14),
                              children: [
                                const TextSpan(
                                  text: 'رقم البند : ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                TextSpan(
                                  text: tariff.hsCode,
                                  style: const TextStyle(
                                    color: AppTheme.cobalt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: AppTheme.charcoal, fontSize: 14),
                              children: [
                                const TextSpan(
                                  text: 'نص البند : ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                TextSpan(
                                  text: tariff.hsDescription,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 20, thickness: 1),

                          // Taxes Breakdown Section matching Screenshot
                          const Text(
                            'الضرائب :',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _taxDetailRow('ضريبة الوارد',
                                    '${tariff.customsDutyRate.toStringAsFixed(3)} %'),
                                _taxDetailRow('ضريبة الجدول',
                                    '${tariff.scheduleTaxRate.toStringAsFixed(3)} %'),
                                _taxDetailRow('ضريبة قيمة مضافة',
                                    '${tariff.vatRate.toStringAsFixed(3)} %'),
                                if (tariff.developmentFeeRate > 0)
                                  _taxDetailRow('رسم التنمية',
                                      '${tariff.developmentFeeRate.toStringAsFixed(3)} %'),
                                if (tariff.importFeeRate > 0)
                                  _taxDetailRow('رسم الوارد',
                                      '${tariff.importFeeRate.toStringAsFixed(3)} %'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 20, thickness: 1),

                          // Rules, Trade Agreements & Regulatory Notes matching Screenshot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'المستندات والأعمال :',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              if (isLoadingAgreements)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.cobalt),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Items List with Blue Left/Right Vertical Border matching Nafeza UI in screenshot
                          _buildNafezaRulesList(tariff, agreements),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Modal Footer Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.cobalt,
                            side: const BorderSide(color: AppTheme.cobalt),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.handshake_outlined, size: 18),
                          label: const Text('إضافة اتفاقية تفضيلية'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddAgreementDialog(
                                context, ref, tariff.hsCode);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل البند'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showTariffDialog(context, ref, tariff: tariff);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _taxDetailRow(String label, String rateStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          Text(
            rateStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.cobalt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNafezaRulesList(
      CustomsTariffModel tariff, List<Map<String, dynamic>> agreements) {
    final List<String> rules = [];

    // Preferential Agreements from Database
    for (final ag in agreements) {
      final name = ag['agreement_name'] ?? 'اتفاقية تجارية';
      final red = (ag['reduction_percentage'] as num?)?.toDouble() ?? 1.0;
      final pctStr = (red * 100).toStringAsFixed(0);
      final cond = ag['conditions_note'] != null &&
              ag['conditions_note'].toString().isNotEmpty
          ? ' - ${ag['conditions_note']}'
          : '';
      rules.add('ر ${ag['agreement_id'] ?? 6722} - $name تخفيض $pctStr%$cond');
    }

    // Prior Approval Note & Regulatory Conditions matching screenshot
    if (tariff.priorApprovalNote != null &&
        tariff.priorApprovalNote!.isNotEmpty) {
      rules.add('ق 4518 - ${tariff.priorApprovalNote}');
    } else if (tariff.regulatoryAuthority != null &&
        tariff.regulatoryAuthority!.isNotEmpty) {
      rules.add(
          'ق 4518 - لا يصرح باستيراد صنف إلا بموافقة مختومة بخاتم شعار الجمهورية من ${tariff.regulatoryAuthority}');
    }

    // Standard Nafeza Inspection Rule if required
    if (tariff.requiresInspection) {
      rules.add(
          'ق 4547 - يشترط للإفراج عن الصنف وارد تجار أن يكون إنتاج مصانع مسجلة من شركات مالكة للعلامة أو مطبقاً للائحة الفحص المعتمدة');
    }

    // General VAT Rule matching screenshot (ر 7042 - يحصل ضريبة قيمة مضافة بمقدار14% [عام])
    rules.add(
        'ر 7042 - يحصل ضريبة قيمة مضافة بمقدار ${tariff.vatRate.toStringAsFixed(0)}% [عام]');

    // Additional Notes
    if (tariff.notes != null && tariff.notes!.isNotEmpty) {
      rules.add('ق 9994 - ${tariff.notes}');
    }

    return Column(
      children: rules.map((ruleText) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            border: Border(
              right: BorderSide(color: Color(0xFF1B65A8), width: 3.5),
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              ruleText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2C3E50),
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================================================
  // Add Preferential Trade Agreement Dialog
  // ==================================================

  void _showAddAgreementDialog(
      BuildContext context, WidgetRef ref, String hsCode) {
    final nameCtrl = TextEditingController();
    final countriesCtrl = TextEditingController(text: 'EG,EU,TR,JO,TN,MA,GB');
    final pctCtrl = TextEditingController(text: '100');
    final notesCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('إضافة اتفاقية تفضيلية للبند $hsCode'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الاتفاقية *',
                      hintText: 'مثال: اتفاقية الشراكة المصرية الأوروبية EU',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'مطلوب إدخال اسم الاتفاقية'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: countriesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'دول المنشأ المعنية *',
                      hintText: 'رموز الدول بالفواصل e.g. JO,TN,MA,EU',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'مطلوب إدخال دول المنشأ'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: pctCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'نسبة التخفيض الجمركي % *',
                      hintText: '100 للإعفاء الكامل، 10 للتخفيض 10%',
                    ),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'رقم غير صحيح'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'شروط وملاحظات الإفراج التفضيلية',
                      hintText: 'مثال: مصحوبة بفرام 1 أو شهادة EUR.1',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);

                      final pctVal = double.parse(pctCtrl.text.trim()) / 100.0;
                      final data = {
                        'hs_code': hsCode,
                        'agreement_name': nameCtrl.text.trim(),
                        'reduction_type': pctVal >= 1.0
                            ? 'full_duty_exemption'
                            : 'percentage_of_duty',
                        'reduction_percentage': pctVal,
                        'origin_countries': countriesCtrl.text.trim(),
                        'conditions_note': notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      };

                      final error = await ref
                          .read(customsTariffProvider.notifier)
                          .createPreferentialAgreement(data);

                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(error),
                                backgroundColor: AppTheme.crimson),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('تمت إضافة الاتفاقية التفضيلية بنجاح!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                          Navigator.pop(ctx);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ الاتفاقية'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDutyCalculatorDialog(BuildContext context, WidgetRef ref,
      {String? initialHsCode}) {
    String selectedCurrency = 'USD';
    String selectedFreightCurrency = 'USD';

    final Map<String, double> defaultExchangeRates = {
      'USD': 50.7917,
      'EUR': 55.2000,
      'GBP': 64.5000,
      'CNY': 7.1000,
      'SAR': 13.5400,
      'AED': 13.8200,
      'EGP': 1.0000,
    };

    final exchangeRateCtrl = TextEditingController(text: '50.7917');
    final totalInvoiceFcCtrl = TextEditingController(text: '11736.40');
    final insuranceCtrl = TextEditingController(text: '14902.793');
    final deemedInsuranceCtrl = TextEditingController(text: '0.00');
    final freightForeignCtrl = TextEditingController(text: '234.72');
    final freightExchangeRateCtrl = TextEditingController(text: '50.7917');
    final multiFreightCtrl = TextEditingController(text: '11922.234');
    final deemedFreightCtrl = TextEditingController(text: '0.00');
    final additionalFeesCtrl = TextEditingController(text: '1329.50');
    final declaredCifCtrl = TextEditingController(text: '623000.00');

    String insuranceType = 'actual';
    String freightType = 'actual';

    double computeTotalInvoiceFc(List<Map<String, dynamic>> lines) {
      double total = 0;
      for (final m in lines) {
        final val = double.tryParse(
                (m['value'] as TextEditingController).text.trim()) ??
            0;
        total += val;
      }
      return total;
    }

    double computeTotalFobEgp(List<Map<String, dynamic>> lines) {
      final rate = double.tryParse(exchangeRateCtrl.text.trim()) ?? 50.7917;
      return computeTotalInvoiceFc(lines) * rate;
    }

    void recalcDeemedInsurance(
        StateSetter setState, List<Map<String, dynamic>> lines) {
      if (insuranceType != 'deemed') return;
      final deemed = computeTotalFobEgp(lines) * 0.025;
      setState(() {
        deemedInsuranceCtrl.text = deemed.toStringAsFixed(3);
        insuranceCtrl.text = '0.00';
      });
    }

    void recalcDeemedFreight(
        StateSetter setState, List<Map<String, dynamic>> lines) {
      if (freightType != 'deemed') return;
      final deemed = computeTotalFobEgp(lines) * 0.020;
      setState(() {
        deemedFreightCtrl.text = deemed.toStringAsFixed(3);
        multiFreightCtrl.text = '0.00';
      });
    }

    void syncCalculatedFields(
        StateSetter setState, List<Map<String, dynamic>> lines) {
      final totalFc = computeTotalInvoiceFc(lines);
      final rate = double.tryParse(exchangeRateCtrl.text.trim()) ?? 50.7917;
      final fobEgp = totalFc * rate;

      if (insuranceType == 'deemed') {
        final deemedIns = fobEgp * 0.025;
        deemedInsuranceCtrl.text = deemedIns.toStringAsFixed(3);
        insuranceCtrl.text = '0.00';
      }

      if (freightType == 'deemed') {
        final deemedFrt = fobEgp * 0.020;
        deemedFreightCtrl.text = deemedFrt.toStringAsFixed(3);
        multiFreightCtrl.text = '0.00';
      } else {
        final fAmt = double.tryParse(freightForeignCtrl.text.trim()) ?? 0;
        final fRate = selectedFreightCurrency == 'EGP'
            ? 1.0
            : (double.tryParse(freightExchangeRateCtrl.text.trim()) ?? rate);
        final calcFrtEgp = fAmt * fRate;
        multiFreightCtrl.text = calcFrtEgp.toStringAsFixed(3);
      }

      final actualIns = double.tryParse(insuranceCtrl.text.trim()) ?? 0;
      final deemedIns = double.tryParse(deemedInsuranceCtrl.text.trim()) ?? 0;
      final effectiveIns = insuranceType == 'deemed' ? deemedIns : actualIns;

      final actualFrt = double.tryParse(multiFreightCtrl.text.trim()) ?? 0;
      final deemedFrt = double.tryParse(deemedFreightCtrl.text.trim()) ?? 0;
      final effectiveFrt = freightType == 'deemed' ? deemedFrt : actualFrt;

      final calculatedCifEgp = fobEgp + effectiveIns + effectiveFrt;

      setState(() {
        totalInvoiceFcCtrl.text = totalFc.toStringAsFixed(2);
        declaredCifCtrl.text = calculatedCifEgp.toStringAsFixed(2);
      });
    }

    List<Map<String, dynamic>> multiLines = [
      {
        'hs': TextEditingController(text: initialHsCode ?? '8536.41.00'),
        'value': TextEditingController(text: '607.6'),
        'inspection': TextEditingController(text: '0.00'),
        'origin': 'CN',
        'exemption': null,
      },
      {
        'hs': TextEditingController(text: '8537.10.90'),
        'value': TextEditingController(text: '4371.2'),
        'inspection': TextEditingController(text: '8514.81'),
        'origin': 'TR',
        'exemption': null,
      },
      {
        'hs': TextEditingController(text: '8537.10.90'),
        'value': TextEditingController(text: '6757.6'),
        'inspection': TextEditingController(text: '69772.09'),
        'origin': 'DE',
        'exemption': null,
      },
    ];

    Map<String, dynamic>? multiResult;
    String? multiError;
    bool isMultiCalculating = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setCalcState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calculate, color: AppTheme.emerald),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Egyptian Customs Duty Calculator (حاسبة الجمارك المصرية — منصة نافذة)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 860,
            height: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حساب الجمارك لشحنة متعددة الأصناف وفق نموذج منصة نافذة (Nafeza Statement)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.downloading, size: 14),
                        label: const Text(
                            'تحميل مثال نافذة الفعلي (2026-612-1-94731)',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setCalcState(() {
                            selectedCurrency = 'USD';
                            selectedFreightCurrency = 'USD';
                            exchangeRateCtrl.text = '50.7917';
                            insuranceCtrl.text = '14902.793';
                            deemedInsuranceCtrl.text = '0.00';
                            insuranceType = 'actual';
                            freightForeignCtrl.text = '234.72';
                            multiFreightCtrl.text = '11922.234';
                            deemedFreightCtrl.text = '0.00';
                            freightType = 'actual';
                            additionalFeesCtrl.text = '1329.50';
                            multiLines = [
                              {
                                'hs': TextEditingController(text: '8536.41.00'),
                                'value': TextEditingController(text: '607.6'),
                                'inspection':
                                    TextEditingController(text: '0.00'),
                                'origin': 'CN',
                                'exemption': null,
                              },
                              {
                                'hs': TextEditingController(text: '8537.10.90'),
                                'value': TextEditingController(text: '4371.2'),
                                'inspection':
                                    TextEditingController(text: '8514.81'),
                                'origin': 'TR',
                                'exemption': null,
                              },
                              {
                                'hs': TextEditingController(text: '8537.10.90'),
                                'value': TextEditingController(text: '6757.6'),
                                'inspection':
                                    TextEditingController(text: '69772.09'),
                                'origin': 'DE',
                                'exemption': null,
                              },
                            ];
                            syncCalculatedFields(setCalcState, multiLines);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header Inputs Grid - Row 1: Invoice Currency + Exchange Rate + Total FC Auto-Calc
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SearchableDropdownField<String>(
                          value: selectedCurrency,
                          labelText: 'عملة الفاتورة *',
                          searchHintText: 'ابحث عن عملة الفاتورة...',
                          items: const [
                            SearchableDropdownItem(
                                value: 'USD', label: 'USD - دولار (\$)'),
                            SearchableDropdownItem(
                                value: 'EUR', label: 'EUR - يورو (€)'),
                            SearchableDropdownItem(
                                value: 'GBP', label: 'GBP - إسترليني (£)'),
                            SearchableDropdownItem(
                                value: 'CNY', label: 'CNY - يوان (¥)'),
                            SearchableDropdownItem(
                                value: 'SAR', label: 'SAR - ريال (ر.س)'),
                            SearchableDropdownItem(
                                value: 'AED', label: 'AED - درهم (د.إ)'),
                            SearchableDropdownItem(
                                value: 'EGP', label: 'EGP - جنيه (ج.م)'),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setCalcState(() {
                              selectedCurrency = val;
                              if (freightType == 'actual' &&
                                  selectedFreightCurrency == 'USD') {
                                selectedFreightCurrency = val;
                              }
                              exchangeRateCtrl.text =
                                  (defaultExchangeRates[val] ?? 50.7917)
                                      .toStringAsFixed(4);
                              syncCalculatedFields(setCalcState, multiLines);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: exchangeRateCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              syncCalculatedFields(setCalcState, multiLines),
                          decoration: InputDecoration(
                            labelText: 'سعر التحويل (EGP/$selectedCurrency) *',
                            hintText: '50.7917',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: totalInvoiceFcCtrl,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText:
                                'إجمالي قيمة الفاتورة المقر عنها ($selectedCurrency)',
                            helperText: 'حاصل جمع قيم جميع السطور بالعملة',
                            helperStyle: const TextStyle(fontSize: 9),
                            isDense: true,
                            filled: true,
                            fillColor: AppTheme.cobalt.withOpacity(0.08),
                            suffixIcon: const Icon(Icons.calculate_outlined,
                                size: 16, color: AppTheme.cobalt),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Header Inputs Grid - Row 2: Declared CIF EGP + Additional Fees EGP
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: declaredCifCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'إجمالي القيمة المقرة CIF (EGP)',
                            helperText:
                                'محسوبة تلقائياً: (FOB + تأمين + نولون)',
                            helperStyle: TextStyle(fontSize: 9),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: additionalFeesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'رسوم أساسية/إضافية (EGP)',
                            hintText: '1329.50',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Insurance Interactive Row ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (insuranceType == 'deemed'
                              ? AppTheme.orange
                              : AppTheme.cobalt)
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (insuranceType == 'deemed'
                                ? AppTheme.orange
                                : AppTheme.cobalt)
                            .withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              insuranceType == 'actual'
                                  ? Icons.verified_outlined
                                  : Icons.auto_fix_high,
                              size: 14,
                              color: insuranceType == 'actual'
                                  ? AppTheme.cobalt
                                  : AppTheme.orange,
                            ),
                            const SizedBox(width: 6),
                            const Text('التأمين:',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.charcoal)),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('فعلي ✔',
                                  style: TextStyle(fontSize: 11)),
                              selected: insuranceType == 'actual',
                              selectedColor: AppTheme.cobalt.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  insuranceType = 'actual';
                                  deemedInsuranceCtrl.text = '0.00';
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('حكمي 2.5% ⚡',
                                  style: TextStyle(fontSize: 11)),
                              selected: insuranceType == 'deemed',
                              selectedColor: AppTheme.orange.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  insuranceType = 'deemed';
                                  insuranceCtrl.text = '0.00';
                                  recalcDeemedInsurance(
                                      setCalcState, multiLines);
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (insuranceType == 'actual') ...[
                              Expanded(
                                child: TextField(
                                  controller: insuranceCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => syncCalculatedFields(
                                      setCalcState, multiLines),
                                  decoration: const InputDecoration(
                                    labelText: 'مبلغ التأمين الفعلي (EGP)',
                                    hintText: '14902.793',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: TextField(
                                  controller: deemedInsuranceCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'التأمين الحكمي المحتسب (EGP) — 2.5% من إجمالي FOB',
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppTheme.orange.withOpacity(0.08),
                                    suffixIcon: const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: AppTheme.orange),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: insuranceCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'التأمين الفعلي (EGP) — يُضبط صفراً',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.08),
                                    helperText: 'صفر لتجنب الاحتساب المزدوج',
                                    helperStyle: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Freight Interactive Row (Foreign Currency & Amount) ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (freightType == 'deemed'
                              ? AppTheme.orange
                              : AppTheme.cobalt)
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (freightType == 'deemed'
                                ? AppTheme.orange
                                : AppTheme.cobalt)
                            .withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              freightType == 'actual'
                                  ? Icons.local_shipping_outlined
                                  : Icons.auto_fix_high,
                              size: 14,
                              color: freightType == 'actual'
                                  ? AppTheme.cobalt
                                  : AppTheme.orange,
                            ),
                            const SizedBox(width: 6),
                            const Text('النولون:',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.charcoal)),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('فعلي ✔',
                                  style: TextStyle(fontSize: 11)),
                              selected: freightType == 'actual',
                              selectedColor: AppTheme.cobalt.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  freightType = 'actual';
                                  deemedFreightCtrl.text = '0.00';
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('حكمي 2.0% ⚡',
                                  style: TextStyle(fontSize: 11)),
                              selected: freightType == 'deemed',
                              selectedColor: AppTheme.orange.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  freightType = 'deemed';
                                  multiFreightCtrl.text = '0.00';
                                  recalcDeemedFreight(setCalcState, multiLines);
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (freightType == 'actual') ...[
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: selectedFreightCurrency,
                                  labelText: 'عملة النولون الفعلي *',
                                  searchHintText: 'ابحث عن عملة النولون...',
                                  items: const [
                                    SearchableDropdownItem(
                                        value: 'USD',
                                        label: 'USD - دولار (\$)'),
                                    SearchableDropdownItem(
                                        value: 'EUR', label: 'EUR - يورو (€)'),
                                    SearchableDropdownItem(
                                        value: 'GBP',
                                        label: 'GBP - إسترليني (£)'),
                                    SearchableDropdownItem(
                                        value: 'CNY', label: 'CNY - يوان (¥)'),
                                    SearchableDropdownItem(
                                        value: 'SAR',
                                        label: 'SAR - ريال (ر.س)'),
                                    SearchableDropdownItem(
                                        value: 'AED',
                                        label: 'AED - درهم (د.إ)'),
                                    SearchableDropdownItem(
                                        value: 'EGP',
                                        label: 'EGP - جنيه (ج.م)'),
                                  ],
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setCalcState(() {
                                      selectedFreightCurrency = val;
                                      freightExchangeRateCtrl.text =
                                          (defaultExchangeRates[val] ?? 50.7917)
                                              .toStringAsFixed(4);
                                      syncCalculatedFields(
                                          setCalcState, multiLines);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: freightForeignCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => syncCalculatedFields(
                                      setCalcState, multiLines),
                                  decoration: InputDecoration(
                                    labelText:
                                        'مبلغ النولون ($selectedFreightCurrency) *',
                                    hintText: '234.72',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (selectedFreightCurrency != 'EGP') ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: freightExchangeRateCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => syncCalculatedFields(
                                        setCalcState, multiLines),
                                    decoration: const InputDecoration(
                                      labelText: 'معامل تحويل عملة النولون *',
                                      hintText: '50.7917',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: multiFreightCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'إجمالي النولون الفعلي (EGP)',
                                    helperText: selectedFreightCurrency == 'EGP'
                                        ? 'نولون بالجنيه'
                                        : '= النولون ($selectedFreightCurrency) × معامل التحويل',
                                    helperStyle: const TextStyle(fontSize: 9),
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppTheme.cobalt.withOpacity(0.08),
                                    suffixIcon: const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: AppTheme.cobalt),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: TextField(
                                  controller: deemedFreightCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'النولون الحكمي المحتسب (EGP) — 2.0% من إجمالي FOB',
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppTheme.orange.withOpacity(0.08),
                                    suffixIcon: const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: AppTheme.orange),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: multiFreightCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'النولون الفعلي (EGP) — يُضبط صفراً',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.08),
                                    helperText: 'صفر لتجنب الاحتساب المزدوج',
                                    helperStyle: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lines Table Title & Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سطور الفاتورة (Invoice Line Items):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                            fontSize: 13),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة صنف +',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setCalcState(() {
                            multiLines.add({
                              'hs': TextEditingController(text: '8471.30.00'),
                              'value': TextEditingController(text: '1000.00'),
                              'inspection': TextEditingController(text: '0.00'),
                              'origin': 'CN',
                              'exemption': null,
                            });
                            syncCalculatedFields(setCalcState, multiLines);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Multi-Lines Input List
                  ...multiLines.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    final registeredTariffs =
                        ref.watch(customsTariffProvider).value ?? [];
                    final hsDropdownItems = registeredTariffs
                        .map((t) => SearchableDropdownItem<String>(
                              value: t.hsCode,
                              label: '[${t.hsCode}] ${t.hsDescription}',
                              subtitle:
                                  'الوارد: ${t.customsDutyRate}% | ض.م: ${t.vatRate}%',
                            ))
                        .toList();

                    final currentHs =
                        (m['hs'] as TextEditingController).text.trim();
                    final matchedTariff = registeredTariffs
                        .cast<CustomsTariffModel?>()
                        .firstWhere(
                          (t) =>
                              t != null &&
                              (t.hsCode == currentHs ||
                                  t.hsCode.replaceAll('.', '') ==
                                      currentHs.replaceAll('.', '')),
                          orElse: () => null,
                        );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.cobalt,
                                child: Text('${idx + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: SearchableDropdownField<String>(
                                  value: currentHs.isEmpty ? null : currentHs,
                                  labelText:
                                      'HS Code (بند التعريفة الجمركية) *',
                                  searchHintText:
                                      'ابحث برقم البند أو الوصف الجمركي...',
                                  items: [
                                    if (currentHs.isNotEmpty &&
                                        !registeredTariffs
                                            .any((t) => t.hsCode == currentHs))
                                      SearchableDropdownItem<String>(
                                        value: currentHs,
                                        label: currentHs,
                                        subtitle: 'بند غير مسجل / حرة',
                                      ),
                                    ...hsDropdownItems,
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setCalcState(() {
                                        (m['hs'] as TextEditingController)
                                            .text = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller:
                                      m['value'] as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => syncCalculatedFields(
                                      setCalcState, multiLines),
                                  decoration: InputDecoration(
                                    labelText: 'القيمة ($selectedCurrency)',
                                    hintText: '1000',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: m['origin'] as String?,
                                  labelText: 'المنشأ',
                                  searchHintText: 'ابحث عن بلد المنشأ...',
                                  items: const [
                                    SearchableDropdownItem(
                                        value: 'CN', label: 'الصين - CN'),
                                    SearchableDropdownItem(
                                        value: 'TR',
                                        label: 'تركيا (اتفاقية) - TR'),
                                    SearchableDropdownItem(
                                        value: 'DE',
                                        label: 'ألمانيا (شراكة) - DE'),
                                    SearchableDropdownItem(
                                        value: 'IT',
                                        label: 'إيطاليا (شراكة) - IT'),
                                    SearchableDropdownItem(
                                        value: 'EG', label: 'مصر - EG'),
                                    SearchableDropdownItem(
                                        value: 'GB',
                                        label: 'المملكة المتحدة - GB'),
                                    SearchableDropdownItem(
                                        value: 'US', label: 'أمريكا - US'),
                                    SearchableDropdownItem(
                                        value: 'IN', label: 'الهند - IN'),
                                    SearchableDropdownItem(
                                        value: 'BR',
                                        label: 'البرازيل (ميركوسور) - BR'),
                                    SearchableDropdownItem(
                                        value: 'RS',
                                        label: 'صربيا (اتفاقية) - RS'),
                                    SearchableDropdownItem(
                                        value: 'CH',
                                        label: 'سويسرا (إفتا) - CH'),
                                  ],
                                  onChanged: (val) {
                                    setCalcState(() {
                                      m['origin'] = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String?>(
                                  value: m['exemption'] as String?,
                                  labelText: 'الإعفاء',
                                  searchHintText: 'ابحث عن كود الإعفاء...',
                                  items: const [
                                    SearchableDropdownItem(
                                        value: null, label: 'لا يوجد إعفاء'),
                                    SearchableDropdownItem(
                                        value: 'INV-LAW-EXEMPT-01',
                                        label: 'قانون الاستثمار (100%)'),
                                    SearchableDropdownItem(
                                        value: 'FREEZONE-EXEMPT-02',
                                        label: 'منطقة حرة (100%)'),
                                    SearchableDropdownItem(
                                        value: 'DIPLO-EXEMPT-03',
                                        label: 'إعفاء دبلوماسي (100%)'),
                                    SearchableDropdownItem(
                                        value: 'PARTIAL-50-EXEMPT',
                                        label: 'إعفاء جزئي (50%)'),
                                  ],
                                  onChanged: (val) {
                                    setCalcState(() {
                                      m['exemption'] = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller:
                                      m['inspection'] as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'خدمات جمركية (EGP)',
                                    hintText: '0.00',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (multiLines.length > 1) ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 18),
                                  onPressed: () {
                                    setCalcState(() {
                                      multiLines.removeAt(idx);
                                      syncCalculatedFields(
                                          setCalcState, multiLines);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                          if (matchedTariff != null &&
                              (matchedTariff.priorApprovalNote ?? '')
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.amber.shade700),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Colors.amber.shade900,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '⚠️ تنبيه إعفاء وشروط مستندية مطلوبة للمورد الخارجي (HS Code: ${matchedTariff.hsCode}):',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• توجد اتفاقيات وشروط مستندية يجب طلب استيفائها من المورد الخارجي (مثل شهادة EUR.1 الأصلي أو منشأ الميركسور) قبل تطبيق الإعفاء الجمركي:',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    matchedTariff.priorApprovalNote!,
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.charcoal,
                                        height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Submit Calculation Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: isMultiCalculating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt, size: 20),
                      label: const Text(
                        'حساب إجمالي الجمارك والإقرار الرسمي (Calculate Nafeza Duties)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: isMultiCalculating
                          ? null
                          : () async {
                              final rate = double.tryParse(
                                      exchangeRateCtrl.text.trim()) ??
                                  50.7917;

                              final bool isDeemedInsurance =
                                  insuranceType == 'deemed';
                              final double actualIns = isDeemedInsurance
                                  ? 0.0
                                  : (double.tryParse(
                                          insuranceCtrl.text.trim()) ??
                                      0);

                              final bool isDeemedFreight =
                                  freightType == 'deemed';
                              final double actualFrt = isDeemedFreight
                                  ? 0.0
                                  : (double.tryParse(
                                          multiFreightCtrl.text.trim()) ??
                                      0);

                              final add = double.tryParse(
                                      additionalFeesCtrl.text.trim()) ??
                                  0;
                              final decCif =
                                  double.tryParse(declaredCifCtrl.text.trim());

                              final linesData = <Map<String, dynamic>>[];
                              for (int i = 0; i < multiLines.length; i++) {
                                final m = multiLines[i];
                                linesData.add({
                                  'line_no': i + 1,
                                  'hs_code': (m['hs'] as TextEditingController)
                                      .text
                                      .trim(),
                                  'value_fc': double.tryParse(
                                          (m['value'] as TextEditingController)
                                              .text
                                              .trim()) ??
                                      0,
                                  'inspection_fee_egp': double.tryParse(
                                          (m['inspection']
                                                  as TextEditingController)
                                              .text
                                              .trim()) ??
                                      0,
                                  'origin_country': m['origin'],
                                  'exemption_code': m['exemption'],
                                });
                              }

                              setCalcState(() {
                                isMultiCalculating = true;
                                multiError = null;
                              });

                              try {
                                final payload = {
                                  'currency': selectedCurrency,
                                  'exchange_rate': rate,
                                  'insurance_egp': actualIns,
                                  'freight_egp': actualFrt,
                                  'freight_currency': selectedFreightCurrency,
                                  'freight_foreign_amount': double.tryParse(
                                          freightForeignCtrl.text.trim()) ??
                                      0,
                                  'freight_exchange_rate': double.tryParse(
                                          freightExchangeRateCtrl.text
                                              .trim()) ??
                                      rate,
                                  'has_insurance_document': !isDeemedInsurance,
                                  'has_freight_document': !isDeemedFreight,
                                  'additional_fees_egp': add,
                                  if (decCif != null && decCif > 0)
                                    'cif_declared_total_egp': decCif,
                                  'lines': linesData,
                                };

                                final res = await ref
                                    .read(customsTariffProvider.notifier)
                                    .estimateMultiItemDuty(payload);

                                setCalcState(() {
                                  multiResult = res;
                                  isMultiCalculating = false;
                                });
                              } catch (e) {
                                setCalcState(() {
                                  multiError = e
                                      .toString()
                                      .replaceAll('Exception: ', '');
                                  isMultiCalculating = false;
                                  multiResult = null;
                                });
                              }
                            },
                    ),
                  ),

                  if (multiError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(multiError!,
                                  style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (multiResult != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('نتيجة حساب الشحنة (Nafeza Statement Result):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                            fontSize: 13)),
                    const SizedBox(height: 8),

                    // Multi-Item Line Items Results Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowHeight: 32,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 32,
                        headingRowColor: WidgetStateProperty.all(
                            AppTheme.charcoal.withOpacity(0.05)),
                        columns: const [
                          DataColumn(label: Text('سطر')),
                          DataColumn(label: Text('HS Code')),
                          DataColumn(label: Text('المنشأ / الاتفاقية')),
                          DataColumn(label: Text('CIF (EGP)')),
                          DataColumn(label: Text('جمرك')),
                          DataColumn(label: Text('ض.جدول')),
                          DataColumn(label: Text('أ.ن.ص (1%)')),
                          DataColumn(label: Text('VAT (14%)')),
                          DataColumn(
                              label: Text('ملاحظات الإعفاء والاتفاقيات')),
                        ],
                        rows: (multiResult!['lines'] as List).map((l) {
                          return DataRow(cells: [
                            DataCell(Text('#${l['line_no']}')),
                            DataCell(Text(l['hs_code'].toString())),
                            DataCell(Text(
                                l['preferential_agreement_applied'] != null
                                    ? '${l['origin_country']} (تفضيل 0%)'
                                    : '${l['origin_country'] ?? "-"}')),
                            DataCell(Text('${l['cif_value_egp']} EGP')),
                            DataCell(Text(
                                '${l['duty_egp']} EGP (${l['customs_duty_rate']}%)')),
                            DataCell(Text('${l['schedule_tax_egp']} EGP')),
                            DataCell(Text(
                                '${l['customs_service_fee_egp']} EGP (1%)')),
                            DataCell(Text('${l['vat_egp']} EGP')),
                            DataCell(Text(
                                l['exemption_applied_details'] ??
                                    l['preferential_agreement_applied'] ??
                                    'خاضع بالكامل',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: (l['exemption_applied_details'] !=
                                                null ||
                                            l['preferential_agreement_applied'] !=
                                                null)
                                        ? AppTheme.emerald
                                        : Colors.black87))),
                          ]);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),

                    // ── Nafeza Statement Fee Codes Breakdown Table (Matching Image #3 Layout) ──
                    if (multiResult!['fee_codes_breakdown'] != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.cobalt.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header Bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.12),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(9)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.receipt_long,
                                          color: AppTheme.cobalt, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'تفاصيل بنود التحصيل والإقرارات الرسمية (Nafeza Statement Fee Breakdown)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.cobalt,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'إجمالي البيان: ${_numToDouble(multiResult!['fee_codes_breakdown']['grand_total']).toStringAsFixed(2)} EGP',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.cobalt,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Grouped Fee Items (Matching Nafeza Official PDF layout in Image #3)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  ...((multiResult!['fee_codes_breakdown']
                                                  ['group_items']
                                              as Map<String, dynamic>? ??
                                          {})
                                      .entries
                                      .map((groupEntry) {
                                    final groupName = groupEntry.key;
                                    final itemsList =
                                        groupEntry.value as List<dynamic>? ??
                                            [];
                                    final groupSum =
                                        (multiResult!['fee_codes_breakdown']
                                                        ['by_group']
                                                    as Map<String, dynamic>? ??
                                                {})[groupName] ??
                                            0.0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: [
                                          // Group Subheader Bar
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            color: Colors.blueGrey.shade100
                                                .withOpacity(0.4),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('تحصيل $groupName',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppTheme.charcoal)),
                                                Text(
                                                    '${_numToDouble(groupSum).toStringAsFixed(2)} ج.م',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppTheme.charcoal)),
                                              ],
                                            ),
                                          ),
                                          // Group Items List
                                          ...itemsList.map((item) {
                                            final itemMap =
                                                item as Map<String, dynamic>;
                                            final code =
                                                itemMap['code']?.toString() ??
                                                    '';
                                            final name = itemMap['name_ar']
                                                    ?.toString() ??
                                                '';
                                            final calcType =
                                                itemMap['calculation_type']
                                                        ?.toString() ??
                                                    'flat';
                                            final amt = _numToDouble(
                                                itemMap['calculated_amount']);
                                            final typeLabel = calcType == 'flat'
                                                ? 'قطعي'
                                                : (calcType == 'reference'
                                                    ? 'مرجعي'
                                                    : 'مشتق');

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text('[$code]',
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'monospace')),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(name,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                  ),
                                                  Text(typeLabel,
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors
                                                              .grey.shade600)),
                                                  const SizedBox(width: 14),
                                                  SizedBox(
                                                    width: 95,
                                                    child: Text(
                                                        '${amt.toStringAsFixed(2)} ج.م',
                                                        textAlign:
                                                            TextAlign.end,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  })),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Action Buttons: Print Statement & Download PDF
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.charcoal,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('طباعة التقرير 🖨️',
                                style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final rate = double.tryParse(
                                      exchangeRateCtrl.text.trim()) ??
                                  50.7917;
                              final totalFc = computeTotalInvoiceFc(multiLines);
                              final fobEgp = totalFc * rate;
                              final insEgp = (insuranceType == 'deemed')
                                  ? (double.tryParse(
                                          deemedInsuranceCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          insuranceCtrl.text.trim()) ??
                                      0);
                              final frtEgp = (freightType == 'deemed')
                                  ? (double.tryParse(
                                          deemedFreightCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          multiFreightCtrl.text.trim()) ??
                                      0);
                              final addEgp = double.tryParse(
                                      additionalFeesCtrl.text.trim()) ??
                                  0;
                              final cifEgp = double.tryParse(
                                      declaredCifCtrl.text.trim()) ??
                                  (fobEgp + insEgp + frtEgp);

                              await CustomsPdfService.printStatement(
                                currency: selectedCurrency,
                                exchangeRate: rate,
                                totalFobFc: totalFc,
                                totalFobEgp: fobEgp,
                                insuranceEgp: insEgp,
                                freightEgp: frtEgp,
                                additionalFeesEgp: addEgp,
                                totalCifEgp: cifEgp,
                                insuranceMode: insuranceType == 'deemed'
                                    ? 'حكمي 2.5%'
                                    : 'فعلي',
                                freightMode: freightType == 'deemed'
                                    ? 'حكمي 2.0%'
                                    : 'فعلي',
                                result: multiResult!,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('تنزيل PDF 📄',
                                style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final rate = double.tryParse(
                                      exchangeRateCtrl.text.trim()) ??
                                  50.7917;
                              final totalFc = computeTotalInvoiceFc(multiLines);
                              final fobEgp = totalFc * rate;
                              final insEgp = (insuranceType == 'deemed')
                                  ? (double.tryParse(
                                          deemedInsuranceCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          insuranceCtrl.text.trim()) ??
                                      0);
                              final frtEgp = (freightType == 'deemed')
                                  ? (double.tryParse(
                                          deemedFreightCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          multiFreightCtrl.text.trim()) ??
                                      0);
                              final addEgp = double.tryParse(
                                      additionalFeesCtrl.text.trim()) ??
                                  0;
                              final cifEgp = double.tryParse(
                                      declaredCifCtrl.text.trim()) ??
                                  (fobEgp + insEgp + frtEgp);

                              final savedPath =
                                  await CustomsPdfService.downloadPdf(
                                currency: selectedCurrency,
                                exchangeRate: rate,
                                totalFobFc: totalFc,
                                totalFobEgp: fobEgp,
                                insuranceEgp: insEgp,
                                freightEgp: frtEgp,
                                additionalFeesEgp: addEgp,
                                totalCifEgp: cifEgp,
                                insuranceMode: insuranceType == 'deemed'
                                    ? 'حكمي 2.5%'
                                    : 'فعلي',
                                freightMode: freightType == 'deemed'
                                    ? 'حكمي 2.0%'
                                    : 'فعلي',
                                result: multiResult!,
                              );

                              if (savedPath != null && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'تم حفظ البيان بصيغة PDF بنجاح:\n$savedPath'),
                                    backgroundColor: AppTheme.emerald,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _handleExcelImport(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Importing Customs Tariff Dataset...'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final summary = await ref
              .read(customsTariffProvider.notifier)
              .uploadExcelTariffs(file.bytes!, file.name);

          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            final imported = summary?['imported'] ?? 0;
            final updated = summary?['updated'] ?? 0;
            final total = summary?['total_processed'] ?? 0;

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.emerald),
                    SizedBox(width: 8),
                    Text('Import Completed'),
                  ],
                ),
                content: Text(
                  'Successfully processed $total HS Codes!\n'
                  '• New Tariffs Created: $imported\n'
                  '• Existing Tariffs Updated: $updated',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    }
  }

  void _showVerifyTariffDialog(
      BuildContext context, WidgetRef ref, CustomsTariffModel tariff) {
    final formKey = GlobalKey<FormState>();
    final verifiedByController =
        TextEditingController(text: tariff.verifiedBy ?? 'System Admin');
    final sourceUrlController = TextEditingController(
        text: tariff.sourceUrl ??
            'https://www.nafeza.gov.eg/ar/tarrif?code=${tariff.hsCode}');
    final priorApprovalNoteController =
        TextEditingController(text: tariff.priorApprovalNote ?? '');
    final dutyRateController =
        TextEditingController(text: tariff.customsDutyRate.toString());
    final vatRateController =
        TextEditingController(text: tariff.vatRate.toString());
    final scheduleTaxRateController =
        TextEditingController(text: tariff.scheduleTaxRate.toString());

    String confidence = tariff.confidence ?? 'verified_manual';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verify HS Code & Audit Metadata (${tariff.hsCode})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 550,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Addendum 3 Manual Verification Protocol:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.charcoal),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Live web queries forbidden. All data stored internally.\n'
                            '• Modifying tax rates archives the current version today and creates a new active version.\n'
                            '• Historical estimates keep their exact snapshot rate.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: verifiedByController,
                      decoration: const InputDecoration(
                        labelText: 'Verified By (Auditor Name) *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Auditor name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sourceUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Nafeza Source URL Reference',
                        prefixIcon: Icon(Icons.link),
                        hintText:
                            'https://www.nafeza.gov.eg/ar/tarrif?code=...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<String>(
                      value: confidence,
                      labelText: 'Confidence Level',
                      searchHintText: 'ابحث عن حالة التوثيق...',
                      items: const [
                        SearchableDropdownItem(
                            value: 'verified_manual',
                            label: 'Manual Audit (Verified)'),
                        SearchableDropdownItem(
                            value: 'verified_official_gazette',
                            label: 'Official Gazette Decree'),
                        SearchableDropdownItem(
                            value: 'draft', label: 'Draft / Unverified'),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => confidence = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priorApprovalNoteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Prior Approval / Special Conditions Note',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tax Rates Verification:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dutyRateController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Duty Rate %'),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: vatRateController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'VAT Rate %'),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: scheduleTaxRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Schedule Tax %'),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: const Text('Confirm Verification'),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);

                      final error = await ref
                          .read(customsTariffProvider.notifier)
                          .verifyTariff(
                        tariff.hsCode,
                        {
                          'verified_by': verifiedByController.text.trim(),
                          'source_url': sourceUrlController.text.trim(),
                          'confidence': confidence,
                          'prior_approval_note':
                              priorApprovalNoteController.text.trim().isEmpty
                                  ? null
                                  : priorApprovalNoteController.text.trim(),
                          'customs_duty_rate':
                              double.parse(dutyRateController.text),
                          'vat_rate': double.parse(vatRateController.text),
                          'schedule_tax_rate':
                              double.parse(scheduleTaxRateController.text),
                        },
                      );

                      setState(() => isLoading = false);
                      if (context.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(error),
                                backgroundColor: AppTheme.crimson),
                          );
                        } else {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'HS Code ${tariff.hsCode} successfully verified!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
