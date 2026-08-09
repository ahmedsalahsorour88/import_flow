import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';

class CustomsTariffScreen extends ConsumerStatefulWidget {
  const CustomsTariffScreen({super.key});

  @override
  ConsumerState<CustomsTariffScreen> createState() => _CustomsTariffScreenState();
}

class _CustomsTariffScreenState extends ConsumerState<CustomsTariffScreen> {
  final TextEditingController _searchController = TextEditingController();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customs Tariff / HS Code Master (MD-008)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Egyptian Customs Duty Rates, VAT, Schedule Taxes, Development Fees & Import Regulations',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Import Excel/CSV'),
                      onPressed: () => _handleExcelImport(context, ref),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('Duty Calculator'),
                      onPressed: () => _showDutyCalculatorDialog(context, ref),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add HS Code'),
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
                      ref.read(customsTariffSearchQueryProvider.notifier).state = val.trim();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by HS Code, Description, or Category...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(customsTariffSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text('Show Inactive', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Switch(
                      value: showInactive,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) {
                        ref.read(showInactiveCustomsTariffsProvider.notifier).state = val;
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
                minWidth: MediaQuery.of(context).size.width > 1100
                    ? MediaQuery.of(context).size.width - 300
                    : 950,
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(110),
                  1: FlexColumnWidth(3),
                  2: FixedColumnWidth(130),
                  3: FixedColumnWidth(180),
                  4: FixedColumnWidth(130),
                  5: FixedColumnWidth(80),
                  6: FixedColumnWidth(120),
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

                    // Description & Regulatory Authority
                    _cell(
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
                          : const Text('—', style: TextStyle(color: Colors.grey)),
                    ),

                    // Tax Rates Breakdown
                    _cell(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _rateBadge('Duty', '${tariff.customsDutyRate}%', AppTheme.cobalt),
                          _rateBadge('VAT', '${tariff.vatRate}%', AppTheme.emerald),
                          if (tariff.scheduleTaxRate > 0)
                            _rateBadge('Sched', '${tariff.scheduleTaxRate}%', AppTheme.crimson),
                          if (tariff.developmentFeeRate > 0)
                            _rateBadge('Dev', '${tariff.developmentFeeRate}%', AppTheme.orange),
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
                            icon: const Icon(Icons.calculate, color: AppTheme.emerald, size: 20),
                            tooltip: 'Calculate Customs Duty',
                            onPressed: () => _showDutyCalculatorDialog(context, ref, initialHsCode: tariff.hsCode),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 20),
                            tooltip: 'Edit Tariff',
                            onPressed: () => _showTariffDialog(context, ref, tariff: tariff),
                          ),
                          Tooltip(
                            message: tariff.isActive ? 'Deactivate Tariff' : 'Reactivate Tariff',
                            child: Switch(
                              value: tariff.isActive,
                              activeColor: AppTheme.emerald,
                              inactiveThumbColor: AppTheme.crimson,
                              onChanged: (_) async {
                                await ref
                                    .read(customsTariffProvider.notifier)
                                    .toggleActive(tariff.tariffId, tariff.isActive);
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
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
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
          color: active ? AppTheme.cobalt.withOpacity(0.4) : Colors.grey.shade300,
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
  // Add / Edit Customs Tariff Dialog
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
    final importFeeCtrl = TextEditingController(
        text: tariff?.importFeeRate.toString() ?? '0.00');

    final authCtrl =
        TextEditingController(text: tariff?.regulatoryAuthority ?? '');
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
              ? 'Add Customs Tariff (HS Code)'
              : 'Edit Customs Tariff - ${tariff.hsCode}'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 540,
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
                              labelText: 'HS Code *',
                              hintText: 'e.g. 8471.30.00',
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: catCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              hintText: 'e.g. Electronics',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'HS Description *'),
                      maxLines: 2,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Tax & Duty Rates (%)',
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
                            decoration: const InputDecoration(labelText: 'Import Duty % *'),
                            validator: (v) => (v == null || double.tryParse(v) == null)
                                ? 'Invalid'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: vatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'VAT % *'),
                            validator: (v) => (v == null || double.tryParse(v) == null)
                                ? 'Invalid'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: schedCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Schedule %'),
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
                            decoration: const InputDecoration(labelText: 'Dev Fee %'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: importFeeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Import Fee %'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Import Requirements & Regulatory',
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
                        const Text('Requires ACID', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: requiresCoo,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) =>
                              setDialogState(() => requiresCoo = val ?? false),
                        ),
                        const Text('Requires COO', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: requiresInspection,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) => setDialogState(
                              () => requiresInspection = val ?? false),
                        ),
                        const Text('Requires Inspection', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: authCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Regulatory Authority',
                        hintText: 'e.g. NTRA, GOEIC, EDA',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes'),
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
                child: const Text('Cancel')),
            ElevatedButton(
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
                        'customs_duty_rate':
                            double.parse(dutyCtrl.text.trim()),
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
                  : Text(tariff == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // Duty Calculator Interactive Modal
  // ==================================================

  void _showDutyCalculatorDialog(BuildContext context, WidgetRef ref,
      {String? initialHsCode}) {
    final hsCtrl = TextEditingController(text: initialHsCode ?? '8471.30.00');
    final cifCtrl = TextEditingController(text: '100000');
    final freightCtrl = TextEditingController(text: '5000');

    CustomsDutyBreakdownModel? breakdown;
    String? calcError;
    bool isCalculating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setCalcState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calculate, color: AppTheme.emerald),
              SizedBox(width: 8),
              Text('Egyptian Customs Duty Calculator'),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calculates Import Duty, VAT, Schedule Tax & Development Fees dynamically using HS Code tariff rates (AGENTS.md Section 7.2)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'HS Code *',
                            hintText: 'e.g. 8471.30.00',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: cifCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CIF Value (EGP) *',
                            hintText: 'e.g. 100000',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: freightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Freight (EGP)',
                            hintText: 'e.g. 5000',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      icon: isCalculating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt, size: 18),
                      label: const Text('Calculate Duties & Taxes'),
                      onPressed: isCalculating
                          ? null
                          : () async {
                              final hs = hsCtrl.text.trim();
                              final cif = double.tryParse(cifCtrl.text.trim()) ?? 0;
                              final freight = double.tryParse(freightCtrl.text.trim()) ?? 0;

                              if (hs.isEmpty || cif <= 0) {
                                setCalcState(() {
                                  calcError = 'Please enter a valid HS Code and positive CIF value.';
                                  breakdown = null;
                                });
                                return;
                              }

                              setCalcState(() {
                                isCalculating = true;
                                calcError = null;
                              });

                              try {
                                final res = await ref
                                    .read(customsTariffProvider.notifier)
                                    .estimateDuty(
                                      hsCode: hs,
                                      cifValue: cif,
                                      freight: freight,
                                    );
                                setCalcState(() {
                                  breakdown = res;
                                  isCalculating = false;
                                });
                              } catch (e) {
                                setCalcState(() {
                                  calcError = e.toString().replaceAll('Exception: ', '');
                                  isCalculating = false;
                                  breakdown = null;
                                });
                              }
                            },
                    ),
                  ),

                  if (calcError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.crimson.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(calcError!,
                            style: const TextStyle(color: AppTheme.crimson, fontSize: 12)),
                      ),
                    ),

                  if (breakdown != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Calculation Breakdown:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _calcRow('CIF Base Value', '${breakdown!.cifValue.toStringAsFixed(2)} EGP'),
                          _calcRow('Import Duty (${breakdown!.customsDutyRate}%)',
                              '${breakdown!.importDutyAmount.toStringAsFixed(2)} EGP'),
                          _calcRow('VAT Base (CIF + Duty + Freight)',
                              '${breakdown!.vatBase.toStringAsFixed(2)} EGP'),
                          _calcRow('VAT (${breakdown!.vatRate}%)',
                              '${breakdown!.vatAmount.toStringAsFixed(2)} EGP'),
                          if (breakdown!.scheduleTaxAmount > 0)
                            _calcRow('Schedule Tax (${breakdown!.scheduleTaxRate}%)',
                                '${breakdown!.scheduleTaxAmount.toStringAsFixed(2)} EGP'),
                          if (breakdown!.developmentFeeAmount > 0)
                            _calcRow('Development Fee (${breakdown!.developmentFeeRate}%)',
                                '${breakdown!.developmentFeeAmount.toStringAsFixed(2)} EGP'),
                          if (breakdown!.importFeeAmount > 0)
                            _calcRow('Import Fee (${breakdown!.importFeeRate}%)',
                                '${breakdown!.importFeeAmount.toStringAsFixed(2)} EGP'),
                          const Divider(),
                          _calcRow(
                            'Total Customs Taxes & Fees',
                            '${breakdown!.totalTaxesAndFees.toStringAsFixed(2)} EGP',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 13 : 12,
              color: isTotal ? AppTheme.charcoal : Colors.grey.shade800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 14 : 12,
              color: isTotal ? AppTheme.emerald : AppTheme.charcoal,
            ),
          ),
        ],
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
}
