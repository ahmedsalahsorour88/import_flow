import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
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

  String _getLocalizedCategory(BuildContext context, String cat) {
    switch (cat) {
      case 'Freight':
        return context.l10n.financialSettlementCategoryFreight;
      case 'Customs Duty':
        return context.l10n.financialSettlementCategoryCustomsDuty;
      case 'Brokerage':
        return context.l10n.financialSettlementCategoryBrokerage;
      case 'Local Transport':
        return context.l10n.financialSettlementCategoryLocalTransport;
      case 'Storage':
        return context.l10n.financialSettlementCategoryStorage;
      default:
        return cat;
    }
  }

  String _getLocalizedRule(BuildContext context, String rule) {
    switch (rule) {
      case 'Volume-Based':
        return context.l10n.financialSettlementRuleVolumeBased;
      case 'Value-Based':
        return context.l10n.financialSettlementRuleValueBased;
      case 'Weight-Based':
        return context.l10n.financialSettlementRuleWeightBased;
      case 'Equal':
        return context.l10n.financialSettlementRuleEqual;
      default:
        return rule;
    }
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
      stageCode: 'LCS-01',
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
          tooltip: context.l10n.financialSettlementRefreshTooltip,
          onPressed: () => ref.read(financialSettlementProvider.notifier).fetchSettlements(),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                      label: Text(context.l10n.financialSettlementNewSettlementBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.l10n.financialSettlementSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: const OutlineInputBorder(),
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
                error: (err, _) => Center(child: Text('${context.l10n.financialSettlementFetchError} $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return Center(child: Text(context.l10n.financialSettlementEmptyRecords));
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
                                  Text(context.l10n.financialSettlementAccountantLabel(r.accountantName), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  const Spacer(),
                                  _buildStatusBadge(context, r.status),
                                ],
                              ),
                              const Divider(height: 20),

                              // KPI Metric Tiles
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetricTile(context.l10n.financialSettlementMetricFobTotal, '${r.totalFobEgp.toStringAsFixed(2)} ج.م', Colors.black87),
                                  _buildMetricTile(context.l10n.financialSettlementMetricExpensesTotal, '${r.totalExpensesEgp.toStringAsFixed(2)} ج.م', AppTheme.orange),
                                  _buildMetricTile(context.l10n.financialSettlementMetricLandedCostTotal, '${r.totalLandedCostEgp.toStringAsFixed(2)} ج.م', AppTheme.cobalt),
                                  _buildMetricTile(context.l10n.financialSettlementMetricMarkupFactor, '${r.averageMarkupFactor.toStringAsFixed(3)}x', AppTheme.emerald),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Expenses Table (BP-036 & BP-037)
                              Text(context.l10n.financialSettlementExpensesSectionHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 36,
                                  dataRowMaxHeight: 36,
                                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                  columns: [
                                    DataColumn(label: Text(context.l10n.financialSettlementColInvoiceNo)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColCategory)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColProvider)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAmountFx)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColExchangeRate)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAmountEgp)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAllocationRule)),
                                  ],
                                  rows: r.expenseInvoices.map((exp) {
                                    return DataRow(cells: [
                                      DataCell(Text(exp.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(_getLocalizedCategory(context, exp.category))),
                                      DataCell(Text(exp.providerName)),
                                      DataCell(Text('${exp.amountFx.toStringAsFixed(2)} ${exp.currency}')),
                                      DataCell(Text('${exp.exchangeRate}')),
                                      DataCell(Text('${exp.amountEgp.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      DataCell(Chip(label: Text(_getLocalizedRule(context, exp.allocationRule), style: const TextStyle(fontSize: 10)), backgroundColor: Colors.grey.shade200)),
                                    ]);
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 16),
                              // Items Landed Cost Table (BP-038 & BP-039)
                              Text(context.l10n.financialSettlementItemsSectionHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emerald)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 36,
                                  dataRowMaxHeight: 40,
                                  headingRowColor: WidgetStateProperty.all(AppTheme.emerald.withOpacity(0.08)),
                                  columns: [
                                    DataColumn(label: Text(context.l10n.financialSettlementColItemCode)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColItemName)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColQty)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColFobUnit)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAllocatedFreight)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAllocatedCustoms)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAllocatedClearance)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColAllocatedTransport)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColUnitLandedCost)),
                                    DataColumn(label: Text(context.l10n.financialSettlementColMarkupFactor)),
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
                                    label: Text(context.l10n.financialSettlementExportOdooBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _showOdooDialog(r.settlementId, r.settlementCode),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                    icon: const Icon(Icons.autorenew, size: 16, color: Colors.white),
                                    label: Text(context.l10n.financialSettlementRecalculateBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                                        SnackBar(content: Text(context.l10n.financialSettlementRecalculateSuccessSnack(r.settlementCode)), backgroundColor: AppTheme.cobalt),
                                      );
                                    },
                                    onPrint: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(context.l10n.financialSettlementPrintSnack(r.settlementCode, r.totalLandedCostEgp.toStringAsFixed(2))),
                                          backgroundColor: AppTheme.charcoal,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    onDelete: () async {
                                      final l10n = context.l10n;
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: Text(l10n.financialSettlementDeleteTitle),
                                          content: Text(l10n.financialSettlementDeleteMessage),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.delete, style: const TextStyle(color: AppTheme.crimson))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(financialSettlementProvider.notifier).softDeleteSettlement(r.settlementId);
                                      }
                                    },
                                    viewTooltip: context.l10n.financialSettlementViewTooltip,
                                    editTooltip: context.l10n.financialSettlementEditTooltip,
                                    printTooltip: context.l10n.financialSettlementPrintTooltip,
                                    deleteTooltip: context.l10n.financialSettlementDeleteTooltip,
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

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color = AppTheme.cobalt;
    String label = status;
    if (status == 'Calculated') {
      color = AppTheme.emerald;
      label = context.l10n.financialSettlementStatusCalculated;
    } else if (status == 'Approved') {
      color = AppTheme.cobalt;
      label = context.l10n.financialSettlementStatusApproved;
    } else if (status == 'Draft') {
      color = AppTheme.orange;
      label = context.l10n.financialSettlementStatusDraft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
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
      title: Text(context.l10n.financialSettlementDialogTitle),
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
                  labelText: context.l10n.financialSettlementImportFileLabel,
                  searchHintText: context.l10n.financialSettlementImportFileSearchHint,
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                            subtitle: f.companyName,
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                  validator: (v) => v == null ? context.l10n.financialSettlementImportFileValidator : null,
                ),
                const SizedBox(height: 14),

                // Expense Invoice Setup
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(context.l10n.financialSettlementExpenseSectionHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _invNoCtrl,
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementInvoiceNoLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: _category,
                        labelText: context.l10n.financialSettlementCategoryLabel,
                        searchHintText: context.l10n.financialSettlementCategorySearchHint,
                        items: [
                          SearchableDropdownItem(value: 'Freight', label: context.l10n.financialSettlementCategoryFreight),
                          SearchableDropdownItem(value: 'Customs Duty', label: context.l10n.financialSettlementCategoryCustomsDuty),
                          SearchableDropdownItem(value: 'Brokerage', label: context.l10n.financialSettlementCategoryBrokerage),
                          SearchableDropdownItem(value: 'Local Transport', label: context.l10n.financialSettlementCategoryLocalTransport),
                          SearchableDropdownItem(value: 'Storage', label: context.l10n.financialSettlementCategoryStorage),
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
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementProviderNameLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _amountFxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementAmountFxLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementExchangeRateLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SearchableDropdownField<String>(
                  value: _allocationRule,
                  labelText: context.l10n.financialSettlementAllocationRuleLabel,
                  searchHintText: context.l10n.financialSettlementAllocationRuleSearchHint,
                  items: [
                    SearchableDropdownItem(value: 'Volume-Based', label: context.l10n.financialSettlementRuleVolumeBased),
                    SearchableDropdownItem(value: 'Value-Based', label: context.l10n.financialSettlementRuleValueBased),
                    SearchableDropdownItem(value: 'Weight-Based', label: context.l10n.financialSettlementRuleWeightBased),
                    SearchableDropdownItem(value: 'Equal', label: context.l10n.financialSettlementRuleEqual),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _allocationRule = v);
                  },
                ),

                const SizedBox(height: 16),
                // Item Setup
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(context.l10n.financialSettlementItemSectionHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emerald)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemCodeCtrl,
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementItemCodeLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _itemNameCtrl,
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementItemNameLabel, border: const OutlineInputBorder()),
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
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementQtyReceivedLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _fobUnitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.l10n.financialSettlementFobUnitPriceLabel, border: const OutlineInputBorder()),
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
          label: Text(context.l10n.financialSettlementLiveReloadBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          label: Text(context.l10n.financialSettlementResetFormBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          label: Text(context.l10n.financialSettlementSaveAndAllocateBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final l10n = context.l10n;
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
                      messenger.showSnackBar(SnackBar(content: Text(l10n.financialSettlementSaveError('$e')), backgroundColor: AppTheme.crimson));
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
