import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/financial_approval_model.dart';
import '../providers/financial_approval_provider.dart';
import '../services/financial_export_service.dart';

class SavedBudgetsRegistryTab extends ConsumerStatefulWidget {
  final void Function(ImportBudgetModel budget) onEditBudget;
  final VoidCallback onSwitchToForm;

  const SavedBudgetsRegistryTab({
    super.key,
    required this.onEditBudget,
    required this.onSwitchToForm,
  });

  @override
  ConsumerState<SavedBudgetsRegistryTab> createState() => _SavedBudgetsRegistryTabState();
}

class _SavedBudgetsRegistryTabState extends ConsumerState<SavedBudgetsRegistryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL'; // ALL, Approved, Pending Review, Draft

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(importBudgetsProvider);
    final budgetsList = budgetsState.value ?? [];

    return _buildHistoryRegistryTab(budgetsList);
  }

  Widget _buildHistoryRegistryTab(List<ImportBudgetModel> budgetsList) {
    final l = context.l10n;
    final totalBudgets = budgetsList.length;
    final approvedBudgets = budgetsList.where((b) => b.isActive && (b.budgetStatus.toLowerCase().contains('approved'))).length;
    final pendingBudgets = budgetsList.where((b) => b.isActive && (b.budgetStatus.toLowerCase().contains('pending') || b.budgetStatus.toLowerCase().contains('draft'))).length;
    final totalValueEgp = budgetsList.where((b) => b.isActive).fold<double>(0.0, (sum, b) => sum + b.totalBudgetEgp);

    final filtered = budgetsList.where((b) {
      if (!b.isActive) return false;
      final q = _searchController.text.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          b.budgetCode.toLowerCase().contains(q) ||
          b.title.toLowerCase().contains(q) ||
          (b.importFileCode != null && b.importFileCode!.toLowerCase().contains(q)) ||
          (b.approvedBy != null && b.approvedBy!.toLowerCase().contains(q));

      if (!matchQuery) return false;

      if (_selectedStatusFilter == 'Approved') {
        return b.budgetStatus.toLowerCase().contains('approved');
      } else if (_selectedStatusFilter == 'Pending') {
        return b.budgetStatus.toLowerCase().contains('pending') || b.budgetStatus.toLowerCase().contains('draft');
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Top Summary Charcoal Cards Banner ───────────────────────────────
        Container(
          color: AppTheme.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _histStatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: l.totalBudgetsMetric,
                value: '$totalBudgets',
                color: AppTheme.cobalt,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.verified_rounded,
                label: l.approvedBudgetsMetric,
                value: '$approvedBudgets',
                color: AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.hourglass_top_rounded,
                label: l.pendingBudgetsMetric,
                value: '$pendingBudgets',
                color: Colors.orange.shade300,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.monetization_on_outlined,
                label: l.totalValueEgpMetric,
                value: totalValueEgp > 1000000
                    ? '${(totalValueEgp / 1000000).toStringAsFixed(2)}M EGP'
                    : '${totalValueEgp.toStringAsFixed(0)} EGP',
                color: Colors.tealAccent.shade400,
              ),
              const Spacer(),
              // Force Live Refresh button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.refresh, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ref.read(importBudgetsProvider.notifier).fetchImportBudgets();
                  ref.read(importFilesProvider.notifier).fetchImportFiles();
                },
              ),
              const SizedBox(width: 8),
              // Create New Budget Shortcut
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                label: Text(l.importBudgetSetupTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: widget.onSwitchToForm,
              ),
            ],
          ),
        ),

        // ─── Filter & Search Toolbar ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Search input
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l.searchBudgetsHint,
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () => setState(() => _searchController.clear()),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.cobalt)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Filter Chips
              _buildFilterChip('${l.allStatuses} (${budgetsList.where((b) => b.isActive).length})', 'ALL'),
              const SizedBox(width: 6),
              _buildFilterChip('${l.approvedBudgetsMetric} ($approvedBudgets)', 'Approved'),
              const SizedBox(width: 6),
              _buildFilterChip('${l.pendingBudgetsMetric} ($pendingBudgets)', 'Pending'),

              const Spacer(),

              // Export All to Excel
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade800,
                  side: BorderSide(color: Colors.green.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.table_chart_outlined, size: 16, color: Colors.green),
                label: Text(l.exportExcel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final path = await FinancialExportService.exportBudgetsListToExcel(context: context, list: filtered);
                  if (path != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ $path'), backgroundColor: Colors.green),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // ─── List of Saved Budget Cards ──────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final budget = filtered[index];
                    return _buildBudgetCard(budget);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(ImportBudgetModel budget) {
    final isApproved = budget.budgetStatus.toLowerCase().contains('approved');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isApproved ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green.shade50.withOpacity(0.5) : Colors.orange.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
            ),
            child: Row(
              children: [
                // Code Container with Copy
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: budget.budgetCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('📋 تم نسخ كود الميزانية (${budget.budgetCode})'), backgroundColor: AppTheme.cobalt),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(budget.budgetCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, color: Colors.white70, size: 11),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Linked Import File Code
                if (budget.importFileCode != null || budget.importFileId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                    ),
                    child: Text(
                      budget.importFileCode ?? 'IMP-${budget.importFileId}',
                      style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                const SizedBox(width: 10),

                // Title
                Expanded(
                  child: Text(
                    budget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Status Badge
                _buildStatusBadge(budget.budgetStatus),
                const SizedBox(width: 10),

                // Row Actions Pill
                RowActionsPill(
                  onView: () => _showBudgetDetailsDialog(budget),
                  onEdit: () => widget.onEditBudget(budget),
                  onPrint: () => FinancialExportService.printOrSaveBudgetPdf(budget: budget),
                  onDelete: () => _confirmDeleteBudget(budget),
                ),
              ],
            ),
          ),

          // 2. Metrics 4-Box Grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildCostBox(
                      title: context.l10n.estimatedInvoiceValue,
                      foreignVal: '${budget.invoiceAmountForeign.toStringAsFixed(2)} ${budget.invoiceCurrency}',
                      egpVal: '${budget.invoiceAmountEgp.toStringAsFixed(2)} EGP',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.cobalt,
                    ),
                    const SizedBox(width: 10),
                    _buildCostBox(
                      title: context.l10n.estimatedFreightCost,
                      foreignVal: '${budget.freightCostForeign.toStringAsFixed(2)} ${budget.freightCurrency}',
                      egpVal: '${budget.freightCostEgp.toStringAsFixed(2)} EGP',
                      icon: Icons.directions_boat_outlined,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    _buildCostBox(
                      title: context.l10n.customsAndVatEstimate,
                      foreignVal: 'Customs',
                      egpVal: '${budget.customsDutiesEgp.toStringAsFixed(2)} EGP',
                      icon: Icons.account_balance_outlined,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 10),
                    _buildCostBox(
                      title: context.l10n.clearanceAndTransportEstimate,
                      foreignVal: context.l10n.customsBrokerLabel,
                      egpVal: '${budget.clearanceInlandEgp.toStringAsFixed(2)} EGP',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.teal.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grand Total Highlight Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.emerald.withOpacity(0.4), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppTheme.emerald, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${context.l10n.totalBudgetEgp}:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${budget.totalBudgetEgp.toStringAsFixed(2)} EGP',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emerald),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('${context.l10n.exchangeRateCol}: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          Text('${budget.exchangeRate.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          if (budget.approvedBy != null) ...[
                            const SizedBox(width: 16),
                            Text('Approved by: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            Text(budget.approvedBy!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Quick Action Buttons Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(9), bottomRight: Radius.circular(9)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                // 1. Details Modal
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('عرض التفاصيل', style: TextStyle(fontSize: 11)),
                  onPressed: () => _showBudgetDetailsDialog(budget),
                ),
                // 2. Edit & Load to Form
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.cobalt),
                  label: const Text('تعديل بالنموذج', style: TextStyle(fontSize: 11, color: AppTheme.cobalt)),
                  onPressed: () => widget.onEditBudget(budget),
                ),
                // 3. Print PDF
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.print_outlined, color: Colors.white, size: 14),
                  label: const Text('طباعة PDF', style: TextStyle(color: Colors.white, fontSize: 11)),
                  onPressed: () => FinancialExportService.printOrSaveBudgetPdf(budget: budget),
                ),
                // 4. Export Excel
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.table_chart, color: Colors.white, size: 14),
                  label: const Text('تصدير EXCEL', style: TextStyle(color: Colors.white, fontSize: 11)),
                  onPressed: () async {
                    final path = await FinancialExportService.exportBudgetToExcel(context: context, budget: budget);
                    if (path != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ تم تصدير الميزانية إلى Excel بنجاح: $path'), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
                // 5. WhatsApp
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                  label: const Text('واتساب', style: TextStyle(color: Colors.white, fontSize: 11)),
                  onPressed: () => _showWhatsAppShareDialog(budget),
                ),
                // 6. Email
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.email_outlined, color: Colors.white, size: 14),
                  label: const Text('إيميل', style: TextStyle(color: Colors.white, fontSize: 11)),
                  onPressed: () => _showEmailShareDialog(budget),
                ),
                // 7. Copy Summary
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('نسخ الملخص', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final text = FinancialExportService.generateBudgetWhatsAppText(budget);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 تم نسخ ملخص اعتماد الميزانية إلى الحافظة بنجاح'), backgroundColor: AppTheme.cobalt),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBox({
    required String title,
    required String foreignVal,
    required String egpVal,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              foreignVal,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              egpVal,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDetailsDialog(ImportBudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تفاصيل اعتماد الميزانية الاستيرادية: ${budget.budgetCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildStatusBadge(budget.budgetStatus),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                const SizedBox(height: 6),
                Text('ملف الشحنة: ${budget.importFileCode ?? (budget.importFileId != null ? "IMP-${budget.importFileId}" : "غير محدد")}'),
                if (budget.approvedBy != null) Text('المعتمد من: ${budget.approvedBy}'),
                Text('تاريخ التسجيل: ${budget.createdAt.split('T').first}'),
                const Divider(),
                const SizedBox(height: 8),

                // Detailed Table
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2.2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.8),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(padding: EdgeInsets.all(6), child: Text('بند التكلفة الاستيرادية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('القيمة بالعملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('العملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('المعادل EGP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(6), child: Text('فاتورة البضاعة (Commercial Invoice)', style: TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text(budget.invoiceAmountForeign.toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text(budget.invoiceCurrency, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('${budget.invoiceAmountEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(6), child: Text('النولون والشحن (Freight)', style: TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text(budget.freightCostForeign.toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text(budget.freightCurrency, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('${budget.freightCostEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(6), child: Text('الضرائب والجمارك والـ VAT', style: TextStyle(fontSize: 12))),
                        const Padding(padding: EdgeInsets.all(6), child: Text('-', style: TextStyle(fontSize: 12))),
                        const Padding(padding: EdgeInsets.all(6), child: Text('EGP', style: TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('${budget.customsDutiesEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(6), child: Text('أتعاب التخليص والنقل الداخلي', style: TextStyle(fontSize: 12))),
                        const Padding(padding: EdgeInsets.all(6), child: Text('-', style: TextStyle(fontSize: 12))),
                        const Padding(padding: EdgeInsets.all(6), child: Text('EGP', style: TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('${budget.clearanceInlandEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12))),
                      ],
                    ),
                    TableRow(
                      decoration: BoxDecoration(color: Colors.green.shade50),
                      children: [
                        const Padding(padding: EdgeInsets.all(6), child: Text('إجمالي الميزانية المعتمدة الكلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.emerald))),
                        const Padding(padding: EdgeInsets.all(6), child: Text('-', style: TextStyle(fontSize: 12))),
                        const Padding(padding: EdgeInsets.all(6), child: Text('EGP', style: TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('${budget.totalBudgetEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13))),
                      ],
                    ),
                  ],
                ),
                if (budget.notes != null && budget.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('ملاحظات وتوجيهات: ${budget.notes}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal),
            icon: const Icon(Icons.print, color: Colors.white, size: 16),
            label: const Text('طباعة المستند الرسمي PDF', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              FinancialExportService.printOrSaveBudgetPdf(budget: budget);
            },
          ),
        ],
      ),
    );
  }

  void _showWhatsAppShareDialog(ImportBudgetModel budget) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('مشاركة اعتماد الميزانية عبر WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم هاتف المستلم (مع كود الدولة مثل 2010...)',
                  hintText: '201012345678',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text('إرسال الآن', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final phone = phoneCtrl.text.trim().replaceAll('+', '').replaceAll(' ', '');
              final text = FinancialExportService.generateBudgetWhatsAppText(budget);
              final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
              FinancialExportService.launchUrlNative(url);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showEmailShareDialog(ImportBudgetModel budget) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: AppTheme.orange),
            SizedBox(width: 8),
            Text('إرسال اعتماد الميزانية عبر البريد الإلكتروني', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني للمستلم',
                  hintText: 'finance@company.com',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text('فتح تطبيق البريد', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final email = emailCtrl.text.trim();
              final subject = 'اعتماد ميزانية استيرادية: ${budget.budgetCode} - ${budget.title}';
              final body = FinancialExportService.generateBudgetWhatsAppText(budget);
              final url = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
              FinancialExportService.launchUrlNative(url);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteBudget(ImportBudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد حذف اعتماد الميزانية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من رغبتك في حذف اعتماد الميزانية (${budget.budgetCode} - ${budget.title})؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            label: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(importBudgetsProvider.notifier).softDeleteImportBudget(budget.budgetId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🗑️ تم حذف اعتماد الميزانية (${budget.budgetCode}) بنجاح'), backgroundColor: AppTheme.emerald),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ خطأ أثناء الحذف: $e'), backgroundColor: AppTheme.crimson),
          );
        }
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status.toLowerCase().contains('approved')) color = AppTheme.emerald;
    if (status.toLowerCase().contains('pending')) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppTheme.charcoal)),
      selected: isSelected,
      selectedColor: AppTheme.cobalt,
      backgroundColor: Colors.grey.shade100,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatusFilter = value);
      },
    );
  }

  Widget _histStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('لا توجد اعتمادات ميزانية مطابقة لمعايير البحث', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          const Text('قم بإنشاء ميزانية استيرادية جديدة أو تغيير فلاتر البحث', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            label: const Text('اعتماد ميزانية جديدة الآن ➕', style: TextStyle(color: Colors.white)),
            onPressed: widget.onSwitchToForm,
          ),
        ],
      ),
    );
  }
}
