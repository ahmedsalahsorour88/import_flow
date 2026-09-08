import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/financial_settlement_model.dart';
import '../providers/financial_settlement_provider.dart';
import 'landed_cost_comparison_screen.dart';
import 'odoo_journal_entry_dialog.dart';

class FinancialSettlementScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  const FinancialSettlementScreen({super.key, this.initialSubTab = 0});

  @override
  ConsumerState<FinancialSettlementScreen> createState() => _FinancialSettlementScreenState();
}

class _FinancialSettlementScreenState extends ConsumerState<FinancialSettlementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late int _selectedTab;
  final Set<int> _visitedTabs = {};

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialSubTab;
    _visitedTabs.add(_selectedTab);
    Future.microtask(() {
      if (!ref.read(financialSettlementProvider).isLoading) {
        ref.read(financialSettlementProvider.notifier).fetchSettlements();
      }
      if (!ref.read(importFilesProvider).isLoading) {
        ref.read(importFilesProvider.notifier).fetchImportFiles();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FinancialSettlementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      setState(() {
        _selectedTab = widget.initialSubTab;
        _visitedTabs.add(_selectedTab);
      });
    }
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

  void _copySettlementRecordsTsv(
    BuildContext context,
    List<LandedCostSettlementModel> records,
    Map<int, dynamic> importFilesMap,
  ) {
    final l10n = context.l10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final currencyStr = l10n.financialSettlementCurrencyEgp;
    final buffer = StringBuffer();

    final headerList = isArabic
        ? [
            'كود التسوية',
            'ملف الشحنة',
            'المحاسب المسؤول',
            'الحالة',
            'إجمالي الفاتورة ($currencyStr)',
            'إجمالي المصاريف والنولون ($currencyStr)',
            'تكلفة الوصول الشاملة ($currencyStr)',
            'معامل الزيادة',
          ]
        : [
            'Settlement Code',
            'Import File',
            'Responsible Accountant',
            'Status',
            'Total FOB ($currencyStr)',
            'Total Expenses ($currencyStr)',
            'Total Landed Cost ($currencyStr)',
            'Markup Factor',
          ];
    buffer.writeln(headerList.join('\t'));

    for (final r in records) {
      final matchingFile = importFilesMap[r.importFileId];
      final fileCode = matchingFile?.primaryNameWithCode ?? 'IMP-${r.importFileId}';
      final compName = matchingFile?.companyName ?? '';
      final fileTitle = compName.isNotEmpty ? '$fileCode - $compName' : fileCode;

      String statusLabel = r.status;
      if (r.status == 'Calculated') {
        statusLabel = l10n.financialSettlementStatusCalculated;
      } else if (r.status == 'Approved') {
        statusLabel = l10n.financialSettlementStatusApproved;
      } else if (r.status == 'Draft') {
        statusLabel = l10n.financialSettlementStatusDraft;
      }

      buffer.writeln([
        r.settlementCode,
        fileTitle,
        r.accountantName,
        statusLabel,
        r.totalFobEgp.toStringAsFixed(2),
        r.totalExpensesEgp.toStringAsFixed(2),
        r.totalLandedCostEgp.toStringAsFixed(2),
        '${r.averageMarkupFactor.toStringAsFixed(3)}x',
      ].join('\t'));
    }

    CopyHelper.copy(
      context,
      buffer.toString(),
      customMessage: l10n.financialSettlementExportTsvSuccess,
    );
  }

  void _copySettlementBreakdownTsv(
    BuildContext context,
    LandedCostSettlementModel record,
    Map<int, dynamic> importFilesMap,
  ) {
    final l10n = context.l10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final currencyStr = l10n.financialSettlementCurrencyEgp;
    final buffer = StringBuffer();

    final matchingFile = importFilesMap[record.importFileId];
    final fileCode = matchingFile?.primaryNameWithCode ?? 'IMP-${record.importFileId}';
    final compName = matchingFile?.companyName ?? '';
    final fileTitle = compName.isNotEmpty ? '$fileCode - $compName' : fileCode;

    if (isArabic) {
      buffer.writeln('تقرير تفاصيل تكلفة الوصول وتوزيع المصاريف — ${record.settlementCode}');
      buffer.writeln('ملف الشحنة:\t$fileTitle\tالمحاسب المسؤول:\t${record.accountantName}');
      buffer.writeln('إجمالي الفاتورة:\t${record.totalFobEgp.toStringAsFixed(2)} $currencyStr\tإجمالي المصاريف:\t${record.totalExpensesEgp.toStringAsFixed(2)} $currencyStr');
      buffer.writeln('تكلفة الوصول الشاملة:\t${record.totalLandedCostEgp.toStringAsFixed(2)} $currencyStr\tمعامل التكلفة:\t${record.averageMarkupFactor.toStringAsFixed(3)}x');
      buffer.writeln('');
      buffer.writeln('=== فواتير المصاريف اللوجستية والجمركية ===');
      buffer.writeln([
        l10n.financialSettlementColInvoiceNo,
        l10n.financialSettlementColCategory,
        l10n.financialSettlementColProvider,
        l10n.financialSettlementColAmountFx,
        l10n.financialSettlementColExchangeRate,
        l10n.financialSettlementColAmountEgp,
        l10n.financialSettlementColAllocationRule,
      ].join('\t'));
    } else {
      buffer.writeln('Landed Cost & Expense Allocation Report — ${record.settlementCode}');
      buffer.writeln('Import File:\t$fileTitle\tAccountant:\t${record.accountantName}');
      buffer.writeln('Total FOB:\t${record.totalFobEgp.toStringAsFixed(2)} $currencyStr\tTotal Expenses:\t${record.totalExpensesEgp.toStringAsFixed(2)} $currencyStr');
      buffer.writeln('Total Landed Cost:\t${record.totalLandedCostEgp.toStringAsFixed(2)} $currencyStr\tAverage Markup:\t${record.averageMarkupFactor.toStringAsFixed(3)}x');
      buffer.writeln('');
      buffer.writeln('=== Recorded Logistics & Customs Expense Invoices ===');
      buffer.writeln([
        l10n.financialSettlementColInvoiceNo,
        l10n.financialSettlementColCategory,
        l10n.financialSettlementColProvider,
        l10n.financialSettlementColAmountFx,
        l10n.financialSettlementColExchangeRate,
        l10n.financialSettlementColAmountEgp,
        l10n.financialSettlementColAllocationRule,
      ].join('\t'));
    }

    for (final exp in record.expenseInvoices) {
      buffer.writeln([
        exp.invoiceNo,
        _getLocalizedCategory(context, exp.category),
        exp.providerName,
        '${exp.amountFx.toStringAsFixed(2)} ${exp.currency}',
        '${exp.exchangeRate}',
        '${exp.amountEgp.toStringAsFixed(2)} $currencyStr',
        _getLocalizedRule(context, exp.allocationRule),
      ].join('\t'));
    }

    buffer.writeln('');
    if (isArabic) {
      buffer.writeln('=== جدول تكلفة الوصول للأصناف وتوزيع المصاريف ===');
    } else {
      buffer.writeln('=== Item Landed Cost & Expense Allocation Schedule ===');
    }
    buffer.writeln([
      l10n.financialSettlementColItemCode,
      l10n.financialSettlementColItemName,
      l10n.financialSettlementColQty,
      l10n.financialSettlementColFobUnit,
      l10n.financialSettlementColAllocatedFreight,
      l10n.financialSettlementColAllocatedCustoms,
      l10n.financialSettlementColAllocatedClearance,
      l10n.financialSettlementColAllocatedTransport,
      l10n.financialSettlementColUnitLandedCost,
      l10n.financialSettlementColMarkupFactor,
    ].join('\t'));

    for (final itm in record.itemLandedCosts) {
      buffer.writeln([
        itm.itemCode,
        itm.itemName,
        '${itm.qty}',
        '${itm.fobUnitEgp.toStringAsFixed(2)} $currencyStr',
        '${itm.allocatedFreightEgp.toStringAsFixed(2)} $currencyStr',
        '${itm.allocatedCustomsEgp.toStringAsFixed(2)} $currencyStr',
        '${itm.allocatedClearanceEgp.toStringAsFixed(2)} $currencyStr',
        '${itm.allocatedTransportEgp.toStringAsFixed(2)} $currencyStr',
        '${itm.unitLandedCostEgp.toStringAsFixed(2)} $currencyStr',
        '${itm.markupFactor.toStringAsFixed(3)}x',
      ].join('\t'));
    }

    CopyHelper.copy(
      context,
      buffer.toString(),
      customMessage: l10n.financialSettlementCopyBreakdownSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(financialSettlementProvider);
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final importFilesMap = {for (final f in importFiles) f.importFileId: f};

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.calculate_outlined,
        titleEn: 'Landed Cost Registry',
        titleAr: 'سجل تسويات تكلفة الوصول وتوليد القيود',
      ),
      const VerticalNavTabItem(
        icon: Icons.analytics_outlined,
        titleEn: 'Estimated vs Actual Comparison',
        titleAr: 'مقارنة التكلفة التقديرية والفعلية',
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
      selectedIndex: _selectedTab,
      onTabSelected: (index) {
        if (index == 2) {
          _showAddDialog();
        } else {
          setState(() {
            _selectedTab = index;
            _visitedTabs.add(index);
          });
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: context.l10n.financialSettlementRefreshTooltip,
          onPressed: () {
            if (!ref.read(financialSettlementProvider).isLoading) {
              ref.read(financialSettlementProvider.notifier).fetchSettlements();
            }
          },
        ),
      ],
      body: IndexedStack(
        index: _selectedTab == 1 ? 1 : 0,
        children: [
          _buildRegistryView(context, recordsState, importFilesMap),
          _visitedTabs.contains(1)
              ? const LandedCostComparisonScreen(isEmbedded: true)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildRegistryView(
    BuildContext context,
    AsyncValue<List<LandedCostSettlementModel>> recordsState,
    Map<int, dynamic> importFilesMap,
  ) {
    final currencyStr = context.l10n.financialSettlementCurrencyEgp;

    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'financial-settlement',
              title: 'Financial_Settlement',
              onRefreshNeeded: () {
                if (!ref.read(financialSettlementProvider).isLoading) {
                  ref.read(financialSettlementProvider.notifier).fetchSettlements();
                }
              },
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () => _showAddDialog(),
                      icon: const Icon(Icons.add_chart, color: Colors.white),
                      label: Text(
                        context.l10n.financialSettlementNewSettlementBtn,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cobalt,
                        side: const BorderSide(color: AppTheme.cobalt),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.table_view, size: 18, color: AppTheme.cobalt),
                      label: Text(
                        context.l10n.financialSettlementExportTsvBtn,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      onPressed: () {
                        final records = recordsState.valueOrNull ?? [];
                        if (records.isNotEmpty) {
                          _copySettlementRecordsTsv(context, records, importFilesMap);
                        }
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.l10n.financialSettlementSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) {
                              return value.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(financialSettlementProvider.notifier)
                                            .fetchSettlements(search: '');
                                      },
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
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
                                    child: CopyableText(
                                      r.settlementCode,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  () {
                                    final matchingFile = importFilesMap[r.importFileId];
                                    final fileCode = matchingFile?.primaryNameWithCode ?? 'IMP-${r.importFileId}';
                                    final compName = matchingFile?.companyName ?? '';
                                    final fileTitle = compName.isNotEmpty ? '$fileCode - $compName' : fileCode;
                                    return CopyableText(
                                      fileTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                                    );
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
                                  _buildMetricTile(context.l10n.financialSettlementMetricFobTotal, '${r.totalFobEgp.toStringAsFixed(2)} $currencyStr', Colors.black87),
                                  _buildMetricTile(context.l10n.financialSettlementMetricExpensesTotal, '${r.totalExpensesEgp.toStringAsFixed(2)} $currencyStr', AppTheme.orange),
                                  _buildMetricTile(context.l10n.financialSettlementMetricLandedCostTotal, '${r.totalLandedCostEgp.toStringAsFixed(2)} $currencyStr', AppTheme.cobalt),
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
                                    final rowSummary = '${exp.invoiceNo}\t${_getLocalizedCategory(context, exp.category)}\t${exp.providerName}\t${exp.amountFx.toStringAsFixed(2)} ${exp.currency}\t${exp.exchangeRate}\t${exp.amountEgp.toStringAsFixed(2)} $currencyStr\t${_getLocalizedRule(context, exp.allocationRule)}';
                                    return DataRow(cells: [
                                      DataCell(CopyableTableCell(value: exp.invoiceNo, rowSummary: rowSummary, child: Text(exp.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)))),
                                      DataCell(CopyableTableCell(value: _getLocalizedCategory(context, exp.category), rowSummary: rowSummary, child: Text(_getLocalizedCategory(context, exp.category)))),
                                      DataCell(CopyableTableCell(value: exp.providerName, rowSummary: rowSummary, child: Text(exp.providerName))),
                                      DataCell(CopyableTableCell(value: '${exp.amountFx.toStringAsFixed(2)} ${exp.currency}', rowSummary: rowSummary, child: Text('${exp.amountFx.toStringAsFixed(2)} ${exp.currency}'))),
                                      DataCell(CopyableTableCell(value: '${exp.exchangeRate}', rowSummary: rowSummary, child: Text('${exp.exchangeRate}'))),
                                      DataCell(CopyableTableCell(value: '${exp.amountEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${exp.amountEgp.toStringAsFixed(2)} $currencyStr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)))),
                                      DataCell(CopyableTableCell(value: _getLocalizedRule(context, exp.allocationRule), rowSummary: rowSummary, child: Chip(label: Text(_getLocalizedRule(context, exp.allocationRule), style: const TextStyle(fontSize: 10)), backgroundColor: Colors.grey.shade200))),
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
                                    final rowSummary = '${itm.itemCode}\t${itm.itemName}\t${itm.qty}\t${itm.fobUnitEgp.toStringAsFixed(2)} $currencyStr\t${itm.allocatedFreightEgp.toStringAsFixed(2)} $currencyStr\t${itm.allocatedCustomsEgp.toStringAsFixed(2)} $currencyStr\t${itm.allocatedClearanceEgp.toStringAsFixed(2)} $currencyStr\t${itm.allocatedTransportEgp.toStringAsFixed(2)} $currencyStr\t${itm.unitLandedCostEgp.toStringAsFixed(2)} $currencyStr\t${itm.markupFactor.toStringAsFixed(3)}x';
                                    return DataRow(cells: [
                                      DataCell(CopyableTableCell(value: itm.itemCode, rowSummary: rowSummary, child: Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.bold)))),
                                      DataCell(CopyableTableCell(value: itm.itemName, rowSummary: rowSummary, child: Text(itm.itemName))),
                                      DataCell(CopyableTableCell(value: '${itm.qty}', rowSummary: rowSummary, child: Text('${itm.qty}'))),
                                      DataCell(CopyableTableCell(value: '${itm.fobUnitEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${itm.fobUnitEgp.toStringAsFixed(2)} $currencyStr'))),
                                      DataCell(CopyableTableCell(value: '${itm.allocatedFreightEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${itm.allocatedFreightEgp.toStringAsFixed(2)} $currencyStr'))),
                                      DataCell(CopyableTableCell(value: '${itm.allocatedCustomsEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${itm.allocatedCustomsEgp.toStringAsFixed(2)} $currencyStr'))),
                                      DataCell(CopyableTableCell(value: '${itm.allocatedClearanceEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${itm.allocatedClearanceEgp.toStringAsFixed(2)} $currencyStr'))),
                                      DataCell(CopyableTableCell(value: '${itm.allocatedTransportEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${itm.allocatedTransportEgp.toStringAsFixed(2)} $currencyStr'))),
                                      DataCell(CopyableTableCell(value: '${itm.unitLandedCostEgp.toStringAsFixed(2)} $currencyStr', rowSummary: rowSummary, child: Text('${itm.unitLandedCostEgp.toStringAsFixed(2)} $currencyStr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13)))),
                                      DataCell(CopyableTableCell(value: '${itm.markupFactor.toStringAsFixed(3)}x', rowSummary: rowSummary, child: Text('${itm.markupFactor.toStringAsFixed(3)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)))),
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
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.emerald,
                                      side: const BorderSide(color: AppTheme.emerald),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.copy_all, size: 16, color: AppTheme.emerald),
                                    label: Text(context.l10n.financialSettlementCopyBreakdownTsvBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _copySettlementBreakdownTsv(context, r, importFilesMap),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                    icon: const Icon(Icons.autorenew, size: 16, color: Colors.white),
                                    label: Text(context.l10n.financialSettlementRecalculateBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      ref.read(financialSettlementProvider.notifier).recalculateSettlement(r.settlementId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(context.l10n.financialSettlementRecalculateSuccessSnack(r.settlementCode)), backgroundColor: AppTheme.cobalt),
                                      );
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
                                    onPrint: () => _copySettlementBreakdownTsv(context, r, importFilesMap),
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
        CopyableText(
          val,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
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

  InputDecoration _buildCopyableInputDecoration(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.cobalt),
        tooltip: context.l10n.financialSettlementCopyFieldTooltip,
        onPressed: () => CopyHelper.copy(
          context,
          controller.text,
          customMessage: context.l10n.financialSettlementCopyFieldTooltip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];

    return AlertDialog(
      title: Text(context.l10n.financialSettlementDialogTitle),
      content: SizedBox(
        width: 650,
        child: SelectionArea(
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
                              label: '${f.primaryNameWithCode} - ${f.companyName}',
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
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementInvoiceNoLabel, _invNoCtrl),
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
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementProviderNameLabel, _providerCtrl),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _amountFxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementAmountFxLabel, _amountFxCtrl),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _rateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementExchangeRateLabel, _rateCtrl),
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
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementItemCodeLabel, _itemCodeCtrl),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _itemNameCtrl,
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementItemNameLabel, _itemNameCtrl),
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
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementQtyReceivedLabel, _qtyCtrl),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _fobUnitCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _buildCopyableInputDecoration(context, context.l10n.financialSettlementFobUnitPriceLabel, _fobUnitCtrl),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
