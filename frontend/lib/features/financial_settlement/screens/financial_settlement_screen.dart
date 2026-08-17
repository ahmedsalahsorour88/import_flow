import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/financial_settlement_provider.dart';
import 'odoo_journal_entry_dialog.dart';

class FinancialSettlementScreen extends ConsumerStatefulWidget {
  const FinancialSettlementScreen({super.key});

  @override
  ConsumerState<FinancialSettlementScreen> createState() => _FinancialSettlementScreenState();
}

class _FinancialSettlementScreenState extends ConsumerState<FinancialSettlementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(financialSettlementProvider.notifier).fetchSettlements();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _FinancialSettlementFormDialog(),
    );
  }

  void _showOdooDialog(int settlementId, String settlementCode) {
    showDialog(
      context: context,
      builder: (context) => OdooJournalEntryDialog(
        settlementId: settlementId,
        settlementCode: settlementCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(financialSettlementProvider);

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.calculate_outlined,
        titleEn: 'Landed Cost Registry',
        titleAr: 'سجل تسويات تكلفة الوصول',
      ),
      const VerticalNavTabItem(
        icon: Icons.add_chart_outlined,
        titleEn: 'New Cost Settlement',
        titleAr: 'احتساب وتسوية تكلفة شحنة جديدة',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Comprehensive Landed Cost Engine',
      titleAr: 'التسوية المالية وتكلفة البند النهائي',
      headerIcon: Icons.calculate,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (index) {
        if (index == 1) {
          _showAddDialog();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث البيانات',
          onPressed: () => ref.read(financialSettlementProvider.notifier).fetchSettlements(),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'financial-settlement',
              title: 'Financial_Settlement',
              onRefreshNeeded: () => ref.read(financialSettlementProvider.notifier).fetchSettlements(),
            ),
            const SizedBox(height: 12),

            // Top Action Toolbar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showAddDialog(),
                      icon: const Icon(Icons.add_chart, color: Colors.white),
                      label: const Text('تسجيل فواتير مصاريف واحتساب Landed Cost جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث برقم تسوية LCS، المحاسب...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(financialSettlementProvider.notifier).fetchSettlements(search: val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settlement List Area
            Expanded(
              child: recordsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في جلب بيانات التسوية المالية: $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('لا توجد تسويات مالية أو احتساب Landed Cost مسجل حالياً.'));
                  }

                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, idx) {
                      final r = records[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(r.settlementCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                  ),
                                  const SizedBox(width: 12),
                                  () {
                                    final importFiles = ref.watch(importFilesProvider).value ?? [];
                                    final matchingFile = importFiles.where((f) => f.importFileId == r.importFileId).firstOrNull;
                                    final fileCode = matchingFile?.customFileNumber ?? matchingFile?.importFileCode ?? 'IMP-${r.importFileId}';
                                    final compName = matchingFile?.companyName ?? '';
                                    final fileTitle = compName.isNotEmpty ? '[$fileCode] $compName' : '[$fileCode]';
                                    return Text(fileTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal));
                                  }(),
                                  const SizedBox(width: 12),
                                  Text('المحاسب: ${r.accountantName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  const Spacer(),
                                  _buildStatusBadge(r.status),
                                ],
                              ),
                              const Divider(height: 20),

                              // KPI Metric Tiles
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetricTile('إجمالي الفاتورة (FOB EGP)', '${r.totalFobEgp.toStringAsFixed(2)} ج.م', Colors.black87),
                                  _buildMetricTile('إجمالي المصاريف والنولون', '${r.totalExpensesEgp.toStringAsFixed(2)} ج.م', AppTheme.orange),
                                  _buildMetricTile('التكلفة الشاملة (Landed Cost)', '${r.totalLandedCostEgp.toStringAsFixed(2)} ج.م', AppTheme.cobalt),
                                  _buildMetricTile('معامل التكلفة (Markup Factor)', '${r.averageMarkupFactor.toStringAsFixed(3)}x', AppTheme.emerald),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Expenses Table (BP-036 & BP-037)
                              const Text('1️⃣ فواتير ومصاريف الاستيراد المسجلة (Logistics & Customs Expenses):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 36,
                                  dataRowMaxHeight: 36,
                                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                  columns: const [
                                    DataColumn(label: Text('رقم الفاتورة')),
                                    DataColumn(label: Text('نوع البند / الفئة')),
                                    DataColumn(label: Text('المورد / مزود الخدمة')),
                                    DataColumn(label: Text('المبلغ الأجنبي')),
                                    DataColumn(label: Text('سعر الصرف')),
                                    DataColumn(label: Text('المبلغ بالجنيه EGP')),
                                    DataColumn(label: Text('قاعدة التوزيع')),
                                  ],
                                  rows: r.expenseInvoices.map((exp) {
                                    return DataRow(cells: [
                                      DataCell(Text(exp.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(exp.category)),
                                      DataCell(Text(exp.providerName)),
                                      DataCell(Text('${exp.amountFx.toStringAsFixed(2)} ${exp.currency}')),
                                      DataCell(Text('${exp.exchangeRate}')),
                                      DataCell(Text('${exp.amountEgp.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      DataCell(Chip(label: Text(exp.allocationRule, style: const TextStyle(fontSize: 10)), backgroundColor: Colors.grey.shade200)),
                                    ]);
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 16),
                              // Items Landed Cost Table (BP-038 & BP-039)
                              const Text('2️⃣ جدول تكلفة الوصول النهائية للوحدة الواحدة (Unit Landed Cost Breakdown):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emerald)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 36,
                                  dataRowMaxHeight: 40,
                                  headingRowColor: WidgetStateProperty.all(AppTheme.emerald.withOpacity(0.08)),
                                  columns: const [
                                    DataColumn(label: Text('كود الصنف')),
                                    DataColumn(label: Text('اسم الصنف')),
                                    DataColumn(label: Text('الكمية')),
                                    DataColumn(label: Text('سعر FOB للوحدة')),
                                    DataColumn(label: Text('نولون مخصص')),
                                    DataColumn(label: Text('جمارك مخصصة')),
                                    DataColumn(label: Text('تخليص مخصص')),
                                    DataColumn(label: Text('نقل مخصص')),
                                    DataColumn(label: Text('تكلفة الوصول للوحدة (Unit Landed Cost)')),
                                    DataColumn(label: Text('معامل الزيادة (Markup)')),
                                  ],
                                  rows: r.itemLandedCosts.map((itm) {
                                    return DataRow(cells: [
                                      DataCell(Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(itm.itemName)),
                                      DataCell(Text('${itm.qty}')),
                                      DataCell(Text('${itm.fobUnitEgp.toStringAsFixed(2)} ج.م')),
                                      DataCell(Text('${itm.allocatedFreightEgp.toStringAsFixed(2)} ج.م')),
                                      DataCell(Text('${itm.allocatedCustomsEgp.toStringAsFixed(2)} ج.م')),
                                      DataCell(Text('${itm.allocatedClearanceEgp.toStringAsFixed(2)} ج.م')),
                                      DataCell(Text('${itm.allocatedTransportEgp.toStringAsFixed(2)} ج.م')),
                                      DataCell(Text('${itm.unitLandedCostEgp.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13))),
                                      DataCell(Text('${itm.markupFactor.toStringAsFixed(3)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                    ]);
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.charcoal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.receipt_long, size: 16, color: Colors.amber),
                                    label: const Text('📒 تصدير قيد اليومية لـ Odoo / ERP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _showOdooDialog(r.settlementId, r.settlementCode),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                    icon: const Icon(Icons.autorenew, size: 16, color: Colors.white),
                                    label: const Text('إعادة احتساب التكاليف', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      ref.read(financialSettlementProvider.notifier).recalculateSettlement(r.settlementId);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  RowActionsPill(
                                    onView: () => _showOdooDialog(r.settlementId, r.settlementCode),
                                    onEdit: () {
                                      ref.read(financialSettlementProvider.notifier).recalculateSettlement(r.settlementId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('تمت إعادة توزيع التكاليف لسجل التسوية: ${r.settlementCode}'), backgroundColor: AppTheme.cobalt),
                                      );
                                    },
                                    onPrint: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('طباعة كشف ومطابقة التكلفة الشاملة Landed Cost: ${r.settlementCode} (إجمالي: ${r.totalLandedCostEgp.toStringAsFixed(2)} ج.م)'),
                                          backgroundColor: AppTheme.charcoal,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('حذف سجل التسوية'),
                                          content: const Text('هل أنت متأكد من نقل سجل التسوية المالية للمحذوفات؟'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: AppTheme.crimson))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(financialSettlementProvider.notifier).softDeleteSettlement(r.settlementId);
                                      }
                                    },
                                    viewTooltip: 'عرض تفاصيل التسوية',
                                    editTooltip: 'تعديل وإعادة احتساب',
                                    printTooltip: 'طباعة كشف Landed Cost',
                                    deleteTooltip: 'حذف سجل التسوية (Soft Delete)',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.cobalt;
    if (status == 'Calculated') color = AppTheme.emerald;
    if (status == 'Approved') color = AppTheme.cobalt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
    );
  }
}

// -----------------------------------------------------------------------------
// FORM DIALOG
// -----------------------------------------------------------------------------

class _FinancialSettlementFormDialog extends ConsumerStatefulWidget {
  const _FinancialSettlementFormDialog();

  @override
  ConsumerState<_FinancialSettlementFormDialog> createState() => _FinancialSettlementFormDialogState();
}

class _FinancialSettlementFormDialogState extends ConsumerState<_FinancialSettlementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;

  // Expense invoice fields
  final TextEditingController _invNoCtrl = TextEditingController(text: 'INV-LOG-01');
  String _category = 'Freight';
  final TextEditingController _providerCtrl = TextEditingController(text: 'Maersk Shipping Line');
  final TextEditingController _amountFxCtrl = TextEditingController(text: '1000');
  final TextEditingController _rateCtrl = TextEditingController(text: '50.0');
  String _allocationRule = 'Volume-Based';

  // Item fields
  final TextEditingController _itemCodeCtrl = TextEditingController(text: 'ITM-001');
  final TextEditingController _itemNameCtrl = TextEditingController(text: 'Imported Cargo Valves');
  final TextEditingController _qtyCtrl = TextEditingController(text: '100');
  final TextEditingController _fobUnitCtrl = TextEditingController(text: '500');

  bool _isLoading = false;

  @override
  void dispose() {
    _invNoCtrl.dispose();
    _providerCtrl.dispose();
    _amountFxCtrl.dispose();
    _rateCtrl.dispose();
    _itemCodeCtrl.dispose();
    _itemNameCtrl.dispose();
    _qtyCtrl.dispose();
    _fobUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return AlertDialog(
      title: const Text('تسجيل مصاريف وبنود شحنة لاحتساب Landed Cost'),
      content: SizedBox(
        width: 650,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdownField<int?>(
                  value: _selectedImportFileId,
                  labelText: 'ملف الشحنة الاستيرادية *',
                  searchHintText: 'ابحث عن ملف الشحنة بالرقم أو اسم الشركة...',
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                            subtitle: f.companyName,
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                  validator: (v) => v == null ? 'يرجى اختيار ملف الشحنة' : null,
                ),
                const SizedBox(height: 14),

                // Expense Invoice Setup
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('بيانات فاتورة المصروف (Logistics Invoice):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _invNoCtrl,
                        decoration: const InputDecoration(labelText: 'رقم الفاتورة *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: _category,
                        labelText: 'فئة المصروف *',
                        searchHintText: 'ابحث عن فئة المصروف...',
                        items: const [
                          SearchableDropdownItem(value: 'Freight', label: 'Freight (نولون شحن)'),
                          SearchableDropdownItem(value: 'Customs Duty', label: 'Customs Duty (ضرائب وجماك)'),
                          SearchableDropdownItem(value: 'Brokerage', label: 'Brokerage (أتعاب تخليص)'),
                          SearchableDropdownItem(value: 'Local Transport', label: 'Local Transport (نقل بري)'),
                          SearchableDropdownItem(value: 'Storage', label: 'Storage (أرضيات وتخزين)'),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _category = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _providerCtrl,
                        decoration: const InputDecoration(labelText: 'اسم مورد الخدمة *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _amountFxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: r'المبلغ ($)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سعر الصرف', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SearchableDropdownField<String>(
                  value: _allocationRule,
                  labelText: 'قاعدة توزيع المصروف على الأصناف *',
                  searchHintText: 'ابحث عن قاعدة التوزيع...',
                  items: const [
                    SearchableDropdownItem(value: 'Volume-Based', label: 'Volume-Based (حسب الحجم CBM)'),
                    SearchableDropdownItem(value: 'Value-Based', label: 'Value-Based (حسب القيمة FOB)'),
                    SearchableDropdownItem(value: 'Weight-Based', label: 'Weight-Based (حسب الوزن Gross Wt)'),
                    SearchableDropdownItem(value: 'Equal', label: 'Equal (بالتساوي)'),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _allocationRule = v);
                  },
                ),

                const SizedBox(height: 16),
                // Item Setup
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('بيانات صنف الشحنة (Item Line Details):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emerald)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemCodeCtrl,
                        decoration: const InputDecoration(labelText: 'كود الصنف', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _itemNameCtrl,
                        decoration: const InputDecoration(labelText: 'اسم الصنف', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية المستلمة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _fobUnitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سعر الفاتورة للوحدة (FOB EGP)', border: OutlineInputBorder()),
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
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal, side: BorderSide(color: Colors.grey.shade400)),
          onPressed: () => ref.read(financialSettlementProvider.notifier).fetchSettlements(),
          icon: const Icon(Icons.refresh, size: 16, color: AppTheme.cobalt),
          label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade800, side: BorderSide(color: Colors.grey.shade400)),
          onPressed: () {
            setState(() {
              _invNoCtrl.clear();
              _providerCtrl.clear();
              _amountFxCtrl.clear();
              _rateCtrl.text = '50.0';
            });
          },
          icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.blueGrey),
          label: const Text('تفريغ وبدء تسجيل جديد 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          label: const Text('حفظ وتوزيع بنود المصروف ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final fx = double.tryParse(_amountFxCtrl.text.trim()) ?? 0.0;
                      final rate = double.tryParse(_rateCtrl.text.trim()) ?? 1.0;
                      final expData = {
                        'invoice_no': _invNoCtrl.text.trim(),
                        'category': _category,
                        'provider_name': _providerCtrl.text.trim(),
                        'currency': 'USD',
                        'amount_fx': fx,
                        'exchange_rate': rate,
                        'amount_egp': fx * rate,
                        'allocation_rule': _allocationRule,
                      };

                      final itemData = {
                        'item_code': _itemCodeCtrl.text.trim(),
                        'item_name': _itemNameCtrl.text.trim(),
                        'qty': int.tryParse(_qtyCtrl.text.trim()) ?? 1,
                        'gross_weight_kg': 1000.0,
                        'cbm': 10.0,
                        'fob_unit_egp': double.tryParse(_fobUnitCtrl.text.trim()) ?? 0.0,
                      };

                      final payload = {
                        'import_file_id': _selectedImportFileId,
                        'expense_invoices': [expData],
                        'item_landed_costs': [itemData],
                      };

                      await ref.read(financialSettlementProvider.notifier).createSettlement(payload);
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ أثناء حفظ وحساب التسوية: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
        ),
      ],
    );
  }
}
