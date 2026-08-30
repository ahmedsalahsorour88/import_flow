import 'dart:math' as math;
import '../../projects/providers/projects_provider.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/container_requirement_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/cbm_calculator_model.dart';
import '../providers/cbm_calculator_provider.dart';

class SavedCbmRegistryTab extends ConsumerStatefulWidget {
  final void Function(CBMCalculationModel session) onLoadSession;
  final VoidCallback onSwitchToCalculator;

  const SavedCbmRegistryTab({
    super.key,
    required this.onLoadSession,
    required this.onSwitchToCalculator,
  });

  @override
  ConsumerState<SavedCbmRegistryTab> createState() => _SavedCbmRegistryTabState();
}

class _SavedCbmRegistryTabState extends ConsumerState<SavedCbmRegistryTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cbmCalculatorProvider);
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;

    return _buildSavedRegistryTab(context, state, importFiles, poList);
  }

  Widget _buildSavedRegistryTab(
    BuildContext context,
    CBMCalculatorState state,
    List projectsList,
    List poList,
  ) {
    final l = context.l10n;
    final totalCalcs = state.calculations.length;
    final activeCalcs = state.calculations.where((c) => c.isActive).length;
    final totalCbmAll = state.calculations.fold<double>(0, (sum, c) => sum + c.totalCbm);
    final totalWeightAll = state.calculations.fold<double>(0, (sum, c) => sum + c.totalGrossWeightKg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Top Summary Cards (Matching Shipping Study Style) ───────────────
        Container(
          color: AppTheme.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _histStatCard(
                icon: Icons.folder_copy_rounded,
                label: l.totalCalculationsMetric,
                value: '$totalCalcs',
                color: AppTheme.cobalt,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.check_circle_rounded,
                label: l.activeSessionsMetric,
                value: '$activeCalcs',
                color: AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.view_in_ar_rounded,
                label: l.totalCbmVolumeMetric,
                value: '${totalCbmAll.toStringAsFixed(2)} m³',
                color: Colors.orange.shade300,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.scale_rounded,
                label: l.totalGrossWeightRegistryMetric,
                value: '${totalWeightAll.toStringAsFixed(0)} kg',
                color: Colors.purple.shade300,
              ),
              const Spacer(),
              // Live Refresh button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.refreshRegistry, style: const TextStyle(fontSize: 13)),
                onPressed: () => ref.read(cbmCalculatorProvider.notifier).fetchCalculations(),
              ),
            ],
          ),
        ),

        // ─── Search & Filter Bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l.searchCalculationsHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cobalt),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(cbmCalculatorProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cobalt, width: 1.5)),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() {
                    ref.read(cbmCalculatorProvider.notifier).setSearchQuery(v.trim());
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  FilterChip(
                    avatar: Icon(
                      state.showInactive ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: state.showInactive ? AppTheme.crimson : Colors.grey,
                    ),
                    label: Text(
                      state.showInactive ? l.showDeleted : l.hideDeleted,
                      style: TextStyle(
                        fontSize: 12,
                        color: state.showInactive ? AppTheme.crimson : Colors.grey.shade700,
                        fontWeight: state.showInactive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: state.showInactive,
                    selectedColor: AppTheme.crimson.withOpacity(0.12),
                    checkmarkColor: AppTheme.crimson,
                    onSelected: (val) => ref.read(cbmCalculatorProvider.notifier).toggleShowInactive(val),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Results count chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.calculations.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                ),
              ),
            ],
          ),
        ),

        // ─── Data Table ──────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.cobalt),
                      const SizedBox(height: 16),
                      Text(l.loading, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : state.calculations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            l.noDataFound,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 48,
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 60,
                            horizontalMargin: 16,
                            columnSpacing: 18,
                            dividerThickness: 0.5,
                            headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                            columns: [
                              DataColumn(label: SizedBox(
                                width: 168,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(l.actionsCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )),
                              DataColumn(label: Text(l.calcCodeCol)),
                              DataColumn(label: Text(l.importFileIdLabel)),
                              DataColumn(label: Text(l.calculationSessionTitle)),
                              DataColumn(label: Text(l.totalCbmVolumeMetric)),
                              DataColumn(label: Text(l.volumetricWeight)),
                              DataColumn(label: Text(l.grossWeightMetric)),
                              DataColumn(label: Text(l.stackingCol)),
                              DataColumn(label: Text(l.shippingStrategyCol)),
                              DataColumn(label: Text(l.recommendedContainerCol)),
                              DataColumn(label: Text(l.linkPoProjectCol)),
                            ],
                            rows: state.calculations.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final calc = entry.value;
                              final isEven = idx.isEven;
                              final rowColor = !calc.isActive
                                  ? Colors.red.shade50
                                  : isEven
                                      ? Colors.white
                                      : Colors.grey.shade50;

                              return DataRow(
                                color: WidgetStateProperty.all(rowColor),
                                onSelectChanged: (_) => _showDetailDialog(context, calc),
                                cells: [
                                  // ⚡ 1. ACTIONS — أول عمود دائماً مرئي بواسطة RowActionsPill
                                  DataCell(
                                    RowActionsPill(
                                      onView: () => _showDetailDialog(context, calc),
                                      onEdit: () => widget.onLoadSession(calc),
                                      onPrint: () => _showPrintReportDialog(context, calc),
                                      onDelete: () async {
                                        if (calc.isActive) {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Row(
                                                children: [
                                                  const Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
                                                  const SizedBox(width: 8),
                                                  Text(l.confirmSoftDelete, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              content: Text(
                                                '${l.confirmDeleteCalcMessage} "${calc.calcCode} - ${calc.title}"?',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: Text(l.cancel),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
                                                  icon: const Icon(Icons.delete_rounded, size: 16),
                                                  label: Text(l.delete),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(cbmCalculatorProvider.notifier).deleteCalculation(calc.calcId!);
                                          }
                                        } else {
                                          await ref.read(cbmCalculatorProvider.notifier).restoreCalculation(calc.calcId!);
                                        }
                                      },
                                      viewTooltip: l.viewDetails,
                                      editTooltip: l.edit,
                                      printTooltip: l.exportPdf,
                                      deleteTooltip: calc.isActive ? l.delete : l.restore,
                                    ),
                                  ),


                                  // 2. Calc Code
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showDetailDialog(context, calc),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cobalt.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!calc.isActive)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 4),
                                                child: Icon(Icons.block, size: 12, color: AppTheme.crimson),
                                              ),
                                            Text(
                                              calc.calcCode,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: calc.isActive ? AppTheme.cobalt : AppTheme.crimson,
                                                fontSize: 12,
                                                decoration: calc.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3. Import File
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.charcoal.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        calc.importFileCode ?? (calc.importFileId != null ? 'IMP-${calc.importFileId}' : '—'),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 4. Title
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        calc.title ?? 'Calculation Session',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),

                                  // 5. Volume CBM
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Text(
                                        '${calc.totalCbm.toStringAsFixed(3)} m³',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 6. Air Chargeable Weight
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${calc.airChargeableWeightKg.toStringAsFixed(1)} kg',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 7. Gross Weight
                                  DataCell(
                                    Text('${calc.totalGrossWeightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),

                                  // 8. Stacking
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: calc.isStackable ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: calc.isStackable ? Colors.green.shade300 : Colors.red.shade300),
                                      ),
                                      child: Text(
                                        calc.isStackable ? '📦 يقبل الرص' : '🚫 لا يقبل',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: calc.isStackable ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 9. Shipping Recommendation
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(calc.recommendedShippingMethod ?? '-', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),

                                  // 10. Container Suggestion
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(calc.recommendedContainerType ?? '-', style: const TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),

                                  // 11. Linked PO / Project
                                  DataCell(
                                    Text(
                                      calc.poNumber != null
                                          ? 'PO: ${calc.poNumber}'
                                          : calc.projectName != null
                                              ? 'PRJ: ${calc.projectName}'
                                              : 'غير مرتبط',
                                      style: TextStyle(
                                        color: calc.poNumber != null ? AppTheme.emerald : Colors.grey,
                                        fontWeight: calc.poNumber != null ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  /// بطاقة إحصائية صغيرة في شريط ملخص السجل
  Widget _histStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE CALCULATION DIALOG
  // ---------------------------------------------------------------------------
  void _showDetailDialog(BuildContext context, CBMCalculationModel calc) {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final containerRec = ContainerRequirementEngine.calculate(
      totalCbm: calc.totalCbm,
      totalWeightKg: calc.totalGrossWeightKg,
      isStackable: calc.isStackable,
    );
    final dualRec = ContainerRequirementEngine.calculateBoth(
      totalCbm: calc.totalCbm,
      totalWeightKg: calc.totalGrossWeightKg,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.view_in_ar_rounded, color: AppTheme.cobalt, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.cbmSessionDetailsTitle(calc.calcCode),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: calc.isActive ? AppTheme.emerald.withOpacity(0.12) : AppTheme.crimson.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: calc.isActive ? AppTheme.emerald : AppTheme.crimson),
              ),
              child: Text(
                calc.isActive ? l.cbmSessionActiveBadge : l.cbmSessionCancelledBadge,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: calc.isActive ? AppTheme.emerald : AppTheme.crimson),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cobalt.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cobalt),
              ),
              child: Text(
                calc.poNumber != null
                    ? l.cbmSessionLinkedPo(calc.poNumber!)
                    : (calc.importFileCode != null ? l.cbmSessionImportFile(calc.importFileCode!) : l.cbmSessionStandalone),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 920,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Overview Card (Matching Shipping Evaluation Style)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc.title ?? l.calculationSessionTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                            ),
                            if (calc.notes != null && calc.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(l.cbmCargoNotes(calc.notes!), style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              l.cbmCreationDate(calc.createdAt != null ? calc.createdAt.toString().substring(0, 16) : "—"),
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (calc.importFileCode != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(l.cbmSessionImportFile(calc.importFileCode!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal)),
                              ),
                            if (calc.poNumber != null) ...[
                              const SizedBox(height: 4),
                              Text(l.cbmSessionLinkedPo(calc.poNumber!), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11)),
                            ],
                            const SizedBox(height: 4),
                            Text(l.cbmStrategy(calc.recommendedShippingMethod ?? "—"), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Metrics Strip Cards Row
                Text(l.cbmStandardMetricsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildDetailCardBadge(l.totalCbmVolumeMetric, '${calc.totalCbm.toStringAsFixed(4)} m³', Icons.view_in_ar_rounded, Colors.orange.shade800),
                    _buildDetailCardBadge(l.airChargeableWtMetric, '${calc.airChargeableWeightKg.toStringAsFixed(1)} KG', Icons.airplanemode_active, Colors.purple.shade700),
                    _buildDetailCardBadge(l.totalGrossWeightRegistryMetric, '${calc.totalGrossWeightKg.toStringAsFixed(1)} KG', Icons.scale_rounded, AppTheme.cobalt),
                    _buildDetailCardBadge(l.cargoStackingInstructions, calc.isStackable ? l.stackableOption : l.nonStackableOption, Icons.inventory_2_rounded, calc.isStackable ? AppTheme.emerald : Colors.orange.shade900),
                    _buildDetailCardBadge(l.shippingStrategyCol, calc.recommendedShippingMethod ?? '-', Icons.directions_boat_rounded, Colors.blue.shade700),
                    _buildDetailCardBadge(l.recommendedContainerCol, isArabic ? containerRec.recommendationSummary : containerRec.recommendationSummaryEn, Icons.local_shipping_rounded, Colors.brown.shade700),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Dual Container Matrix Comparison Box (Matching Container Comparison Style)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.compare_arrows_rounded, color: AppTheme.cobalt, size: 20),
                              const SizedBox(width: 6),
                              Text(l.cbmContainerComparisonTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              calc.isStackable ? l.cbmScenarioApprovedStackable : l.cbmScenarioApprovedNonStackable,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.06)),
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmScenarioHypothesisCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmScenarioStackableCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.emerald))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmScenarioNonStackableCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.orange))),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmRequiredContainerCount, style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${dualRec.stackableResult.requiredContainersCount} x ${dualRec.stackableResult.recommendedContainerCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${dualRec.nonStackableResult.requiredContainersCount} x ${dualRec.nonStackableResult.recommendedContainerCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange, fontSize: 11))),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmSpaceUtilizationPercent, style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${dualRec.stackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${dualRec.nonStackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // 4. Package Breakdown Section Header & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.packageMeasurementsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.view_in_ar, size: 16),
                      label: Text(l.visualLoadPlanSimulator, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _showVisualLoadPlanDialog(context, calc.items);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 5. Table of Packages
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(0.6),
                    1: FlexColumnWidth(1.8),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(2.0),
                    4: FlexColumnWidth(1.4),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.6),
                    7: FlexColumnWidth(1.6),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                      children: [
                        const Padding(padding: EdgeInsets.all(8), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.packageTypeCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.qtyCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.cbmPackageDimensionsCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.grossWtPerUnitCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.totalGrossWeightRegistryMetric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.stackingCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(l.cbmVolumeMetric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...calc.items.asMap().entries.map(
                      (entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final lineGross = item.quantity * item.grossWeightPerUnitKg;
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(item.packageType, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.quantity}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.lengthCm} x ${item.widthCm} x ${item.heightCm}', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.grossWeightPerUnitKg} kg', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${lineGross.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item.isStackable ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: item.isStackable ? Colors.green.shade300 : Colors.red.shade300),
                                ),
                                child: Text(
                                  item.isStackable ? l.stackableOption : l.nonStackableOption,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.isStackable ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.totalCbm.toStringAsFixed(4)} m³', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 11))),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.edit_note, size: 16),
            label: Text(l.cbmReopenInCalcBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onLoadSession(calc);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
            icon: const Icon(Icons.edit, size: 16),
            label: Text(l.cbmEditMetadataBtn),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showEditCalcDialog(context, calc);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, foregroundColor: Colors.white),
            icon: const Icon(Icons.link, size: 16),
            label: Text(l.cbmLinkToPoProjectBtn),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showLinkToPODialog(
                context,
                calc,
                ref.read(purchaseOrdersProvider).purchaseOrders,
                ref.read(projectsProvider).value ?? [],
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 16),
            label: Text(l.cbmPrintExportReportBtn),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showPrintReportDialog(context, calc);
            },
          ),
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(l.close)),
        ],
      ),
    );
  }

  Widget _buildDetailCardBadge(String title, String val, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCalcDialog(BuildContext context, CBMCalculationModel calc) {
    final l = context.l10n;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: calc.title ?? '');
    final notesCtrl = TextEditingController(text: calc.notes ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l.cbmEditMetadataDialogTitle(calc.calcCode)),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: l.cbmMetadataTitleLabel),
                  validator: (v) => v == null || v.trim().isEmpty ? l.requiredFieldValidation : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.cbmMetadataNotesLabel),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(l.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final ok = await ref.read(cbmCalculatorProvider.notifier).updateCalculation(
                  calc.calcId!,
                  {
                    'title': titleCtrl.text.trim(),
                    'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  },
                );
                if (ok && context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.cbmMetadataSavedSuccess)),
                  );
                }
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showPrintReportDialog(BuildContext context, CBMCalculationModel calc) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.print_outlined, color: AppTheme.emerald),
            const SizedBox(width: 8),
            Text(l.cbmPrintableReportTitle(calc.calcCode)),
          ],
        ),
        content: SizedBox(
          width: 780,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Official Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sorour Logistics ERP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
                          Text(l.cbmCalculatorTitle, style: const TextStyle(color: AppTheme.cobalt, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(l.cbmCalculatorSubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                            child: Text(calc.calcCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(height: 4),
                          Text(l.cbmCreationDate(calc.createdAt != null ? calc.createdAt.toString().substring(0, 10) : DateTime.now().toString().substring(0, 10)), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1.5),

                  // Session Metadata
                  Row(
                    children: [
                      Expanded(child: Text('${l.calculationSessionTitle}: ${calc.title ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      if (calc.poNumber != null)
                        Text(l.cbmSessionLinkedPo(calc.poNumber!), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 12)),
                    ],
                  ),
                  if (calc.notes != null && calc.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(l.cbmCargoNotes(calc.notes!), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  const SizedBox(height: 16),

                  // Summary Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildReportStat(l.totalCbmVolumeMetric, '${calc.totalCbm.toStringAsFixed(4)} m³', Colors.orange),
                        _buildReportStat(l.airChargeableWtMetric, '${calc.airChargeableWeightKg.toStringAsFixed(1)} kg', Colors.purple),
                        _buildReportStat(l.totalGrossWeightRegistryMetric, '${calc.totalGrossWeightKg.toStringAsFixed(1)} kg', AppTheme.cobalt),
                        _buildReportStat(l.cargoStackingInstructions, calc.isStackable ? l.stackableOption : l.nonStackableOption, Colors.teal),
                        _buildReportStat(l.shippingStrategyCol, calc.recommendedShippingMethod ?? '-', Colors.blue),
                        _buildReportStat(l.recommendedContainerCol, calc.recommendedContainerType ?? '-', Colors.brown),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Package Details Table
                  Text(l.packageMeasurementsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade400),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: AppTheme.cloudWhite),
                        children: [
                          const Padding(padding: EdgeInsets.all(6), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.packageTypeCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.qtyCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmPackageDimensionsCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.grossWtPerUnitCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.stackingCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.totalGrossWeightRegistryMetric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmVolumeMetric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                      ),
                      ...calc.items.asMap().entries.map(
                        (entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final lineGross = item.quantity * item.grossWeightPerUnitKg;
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(item.packageType, style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${item.quantity}', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${item.lengthCm}x${item.widthCm}x${item.heightCm}', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${item.grossWeightPerUnitKg} kg', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(item.isStackable ? l.stackableOption : l.nonStackableOption, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isStackable ? Colors.green.shade800 : Colors.red.shade800))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${lineGross.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${item.totalCbm.toStringAsFixed(4)} m³', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            icon: const Icon(Icons.download, size: 16),
            label: Text(l.cbmPrintDownloadCsvBtn),
            onPressed: () {
              _downloadCalcCSV(context, calc);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 16),
            label: Text(l.cbmPrintReportBtn),
            onPressed: () {
              _triggerReportPrint(context, calc);
            },
          ),
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(l.close)),
        ],
      ),
    );
  }

  Widget _buildReportStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _downloadCalcCSV(BuildContext context, CBMCalculationModel calc) {
    final buffer = StringBuffer();
    buffer.writeln('Sorour Logistics ERP - Cargo Volume & Weight Measurement Report');
    buffer.writeln('Calc Code,${calc.calcCode}');
    buffer.writeln('Title,${calc.title ?? ""}');
    buffer.writeln('Notes,${calc.notes ?? ""}');
    buffer.writeln('Total CBM,${calc.totalCbm}');
    buffer.writeln('Air Chargeable Weight (kg),${calc.airChargeableWeightKg}');
    buffer.writeln('Total Gross Weight (kg),${calc.totalGrossWeightKg}');
    buffer.writeln('Shipping Recommendation,${calc.recommendedShippingMethod ?? ""}');
    buffer.writeln('Cargo Stacking,${calc.isStackable ? "Stackable" : "Non-Stackable"}');
    buffer.writeln('');
    buffer.writeln('Pkg #,Package Type,Qty,Length (cm),Width (cm),Height (cm),Gross Wt/Unit (kg),Stacking,Line CBM (m3),Total Gross Wt (kg)');

    for (int i = 0; i < calc.items.length; i++) {
      final item = calc.items[i];
      final lineGross = item.quantity * item.grossWeightPerUnitKg;
      buffer.writeln('${i + 1},${item.packageType},${item.quantity},${item.lengthCm},${item.widthCm},${item.heightCm},${item.grossWeightPerUnitKg},${item.isStackable ? "Stackable" : "Non-Stackable"},${item.totalCbm},$lineGross');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ وتنزيل تقرير بيانات الجلسة ${calc.calcCode} بصيغة CSV بنجاح!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  void _triggerReportPrint(BuildContext context, CBMCalculationModel calc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جار إرسال التقرير ${calc.calcCode} للشاشة التفاعلية للطباعة والتصدير...'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _showLinkToPODialog(
    BuildContext context,
    CBMCalculationModel calc,
    List poList,
    List projectsList,
  ) {
    final l = context.l10n;
    int? selectedPoId = calc.poId;
    int? selectedProjectId = calc.projectId;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.cbmLinkPoDialogTitle(calc.calcCode)),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdownField<int?>(
                  value: selectedPoId,
                  labelText: l.cbmLinkSelectPoLabel,
                  searchHintText: l.cbmLinkSelectPoSearchHint,
                  items: [
                    SearchableDropdownItem<int?>(value: null, label: l.cbmSessionStandalone),
                    ...poList.map((po) => SearchableDropdownItem<int?>(
                          value: po.poId,
                          label: '${po.poNumber}${po.poReference != null && po.poReference!.isNotEmpty ? " - ${po.poReference}" : ""} (${po.projectName ?? "Project"})',
                          subtitle: po.supplierName,
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedPoId = v),
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<int?>(
                  value: selectedProjectId,
                  labelText: l.cbmLinkSelectProjectLabel,
                  searchHintText: l.cbmLinkSelectProjectSearchHint,
                  items: [
                    SearchableDropdownItem<int?>(value: null, label: l.cbmSessionStandalone),
                    ...projectsList.map((p) => SearchableDropdownItem<int?>(
                          value: p.projectId,
                          label: '${p.projectCode} - ${p.projectName}',
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedProjectId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(l.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
              onPressed: () async {
                final ok = await ref
                    .read(cbmCalculatorProvider.notifier)
                    .linkToPO(calc.calcId!, poId: selectedPoId, projectId: selectedProjectId);
                if (ok && context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.cbmLinkSavedSuccess)),
                  );
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showContainerComparisonDialog(BuildContext context, ContainerDualRecommendationResult dualRec, double totalCbm, double totalWeightKg) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppTheme.cobalt),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.cbmContainerComparisonTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${l.totalCbmVolumeMetric}: ${totalCbm.toStringAsFixed(2)} m³ | ${totalWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 750,
              height: 480,
              child: Column(
                children: [
                  Container(
                    color: AppTheme.charcoal,
                    child: TabBar(
                      indicatorColor: AppTheme.cobalt,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(icon: const Icon(Icons.layers), text: l.allStackableOption),
                        Tab(icon: const Icon(Icons.view_array), text: l.allNonStackableOption),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildComparisonTable(context, dualRec.stackableResult),
                        _buildComparisonTable(context, dualRec.nonStackableResult),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(l.close)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonTable(BuildContext context, ContainerRecommendationResult rec) {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rec.isStackable ? AppTheme.emerald.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade800),
            ),
            child: Text('${l.approvedRecommendation}: ${isArabic ? rec.recommendationSummary : rec.recommendationSummaryEn}', style: TextStyle(fontWeight: FontWeight.bold, color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade900)),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                children: [
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.containerSpecCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.cbmRequiredContainerCount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.cbmSpaceUtilizationPercent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.weightUtilizationCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.recommendationCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...rec.comparisonDetails.map((detail) {
                final spec = detail['spec'] as ContainerSpec;
                final int count = detail['reqCount'] as int;
                final double volUtil = detail['spaceUtil'] as double;
                final double weightUtil = detail['payloadUtil'] as double;
                final isBest = spec.code == rec.recommendedContainerCode;

                return TableRow(
                  decoration: isBest ? BoxDecoration(color: AppTheme.emerald.withOpacity(0.12)) : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spec.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isBest ? AppTheme.emerald : AppTheme.charcoal)),
                          Text('${l.cbmVolumeMetric}: ${spec.internalVolumeCbm} CBM | ${l.grossWtPerUnitCol}: ${spec.maxPayloadKg} kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$count x ${spec.code}', style: TextStyle(fontWeight: FontWeight.bold, color: isBest ? AppTheme.emerald : AppTheme.charcoal)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${volUtil.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: volUtil > 90 ? Colors.green : Colors.orange)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${weightUtil.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: weightUtil > 90 ? Colors.green : Colors.orange)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isBest
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.emerald, borderRadius: BorderRadius.circular(4)),
                              child: Text(l.bestOptionBadge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            )
                          : Text(l.viableAlternative, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _showVisualLoadPlanDialog(BuildContext context, List<CBMItemModel> quickItems) {
    final l = context.l10n;
    // 1. Convert CBMItemModel list to CargoItem list with individual stackability
    final List<CargoItem> cargoItems = [];
    int itemCounter = 1;

    for (final item in quickItems) {
      for (int q = 0; q < item.quantity; q++) {
        // Convert dimension to cm based on the unit
        double lCm = item.length;
        double wCm = item.width;
        double hCm = item.height;
        if (item.unit == 'mm') {
          lCm /= 10;
          wCm /= 10;
          hCm /= 10;
        } else if (item.unit == 'm') {
          lCm *= 100;
          wCm *= 100;
          hCm *= 100;
        }

        // Convert weight to kg based on unit
        final double weightKg = item.grossWeightPerUnitKg;

        cargoItems.add(CargoItem(
          itemId: '$itemCounter',
          length: lCm,
          width: wCm,
          height: hCm,
          weight: weightKg,
          rotate: true,
          isStackable: item.isStackable,
          packageType: item.packageType,
        ));
        itemCounter++;
      }
    }

    if (cargoItems.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.warning),
          content: Text(l.noDataFound),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
          ],
        ),
      );
      return;
    }

    // Default active view mode: null = Actual/Mixed, true = All Stackable, false = All Non-Stackable
    bool? activeStackingMode = cargoItems.any((i) => !i.isStackable) ? null : true;
    CargoOrientationPreference activeOrientationMode = CargoOrientationPreference.smartHybrid;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            // Compute plan dynamically based on the selected mode & orientation preference
            final plan = ContainerRequirementEngine.planShipment(
              cargoItems,
              forceStackable: activeStackingMode,
              forceOrientation: activeOrientationMode,
            );

            // Compute summary metrics for active plan
            final totalPkgs = cargoItems.length;
            final stackableInActive = activeStackingMode == true
                ? totalPkgs
                : (activeStackingMode == false ? 0 : cargoItems.where((c) => c.isStackable).length);
            final nonStackableInActive = totalPkgs - stackableInActive;

            final totalPlanWeight = plan.fold(0.0, (s, p) => s + p.totalWeight);
            final totalPlanVolume = plan.fold(0.0, (s, p) => s + p.totalVolume);

            // Determine container fleet text (e.g. 1 x 40HC or 1 x 40HC + 1 x 40GP)
            final Map<String, int> containerCounts = {};
            for (final p in plan) {
              if (p.containerCode != 'FAILED') {
                containerCounts[p.containerCode] = (containerCounts[p.containerCode] ?? 0) + 1;
              }
            }
            final fleetSummaryText = containerCounts.entries.map((e) => '${e.value} x ${e.key}').join(' + ');

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.view_in_ar, color: AppTheme.cobalt, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.cbmVisualPlannerTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.cobalt),
                    ),
                    child: Text(
                      '${l.requiredFleet}: $fleetSummaryText (${plan.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: math.min(1050.0, MediaQuery.of(context).size.width * 0.95),
                height: math.min(680.0, MediaQuery.of(context).size.height * 0.85),
                child: Column(
                  children: [
                    // 1. Scenario & Orientation Mode Switcher
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            l.chooseStackingScenario,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: Text(l.smartHybridOption),
                                selected: activeOrientationMode == CargoOrientationPreference.smartHybrid && activeStackingMode != false,
                                selectedColor: AppTheme.emerald,
                                labelStyle: TextStyle(
                                  color: activeOrientationMode == CargoOrientationPreference.smartHybrid && activeStackingMode != false ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setDialogState(() {
                                      activeOrientationMode = CargoOrientationPreference.smartHybrid;
                                      activeStackingMode = true;
                                    });
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: Text(l.flatOnlyOption),
                                selected: activeOrientationMode == CargoOrientationPreference.flatOnly && activeStackingMode != false,
                                selectedColor: Colors.blue.shade700,
                                labelStyle: TextStyle(
                                  color: activeOrientationMode == CargoOrientationPreference.flatOnly && activeStackingMode != false ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setDialogState(() {
                                      activeOrientationMode = CargoOrientationPreference.flatOnly;
                                      activeStackingMode = true;
                                    });
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: Text(l.allNonStackableOption),
                                selected: activeStackingMode == false,
                                selectedColor: Colors.orange.shade800,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == false ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setDialogState(() {
                                      activeStackingMode = false;
                                    });
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: Text(l.mixedStackingOption),
                                selected: activeStackingMode == null,
                                selectedColor: AppTheme.cobalt,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == null ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = null);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Metrics Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildMetricPill(l.packageMeasurementsTitle, '$totalPkgs', AppTheme.cobalt),
                              const SizedBox(width: 8),
                              _buildMetricPill(l.totalGrossWeightRegistryMetric, '${totalPlanWeight.toStringAsFixed(0)} kg', AppTheme.charcoal),
                              const SizedBox(width: 8),
                              _buildMetricPill(l.totalCbmVolumeMetric, '${totalPlanVolume.toStringAsFixed(3)} m³', Colors.orange.shade900),
                            ],
                          ),
                          Row(
                            children: [
                              _buildMetricPill(l.stackableOption, '$stackableInActive', Colors.green.shade800),
                              const SizedBox(width: 8),
                              _buildMetricPill(l.nonStackableOption, '$nonStackableInActive', Colors.red.shade800),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Table summary of container loads
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(2.4),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                          children: [
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.containerSpecCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.packageTypeCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.grossWtPerUnitCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.spaceUtilizationCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.cbmFloorAreaUtilization, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        ...plan.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final res = entry.value;
                          final placedIds = res.placedItems.map((p) => p.item.itemId).join(', ');
                          final totalPlacedCount = res.placedItems.length;

                          final double volSpaceUtil = res.spec.internalVolumeCbm > 0 ? (res.totalVolume / res.spec.internalVolumeCbm) * 100 : 0.0;
                          final double floorAreaM2 = res.placedItems.fold(0.0, (s, p) => s + p.item.floorAreaM2);
                          final double specFloorAreaM2 = (res.spec.internalLength * res.spec.internalWidth) / 10000;
                          final double floorUtil = specFloorAreaM2 > 0 ? (floorAreaM2 / specFloorAreaM2) * 100 : 0.0;

                          final bool hasNonStackable = res.placedItems.any((p) => !p.item.isStackable);
                          final double displaySpaceUtil = hasNonStackable ? math.max(volSpaceUtil, floorUtil) : volSpaceUtil;

                          String statusText = '';
                          if (res.containerCode == 'FAILED' || !res.fits) {
                            statusText = res.failureReason ?? l.operationFailed;
                          } else {
                            final nonStackInThis = res.placedItems.where((p) => !p.item.isStackable).length;
                            if (nonStackInThis > 0) {
                              statusText = '${l.nonStackableOption}: $nonStackInThis (${floorUtil.toStringAsFixed(1)}%)';
                            } else {
                              statusText = '${l.stackableOption} ($totalPlacedCount)';
                            }
                          }

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  res.containerCode == 'FAILED' ? l.operationFailed : '$idx: ${res.spec.code}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  placedIds.isEmpty ? '-' : '$placedIds ($totalPlacedCount)',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(res.containerCode == 'FAILED' ? '-' : '${res.totalWeight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  '${displaySpaceUtil.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusText.contains('فشل') || statusText.contains('Failed')
                                        ? Colors.red.shade800
                                        : (statusText.contains('غير قابل') || statusText.contains('Non-') ? Colors.brown.shade800 : Colors.green.shade800),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 3. Tab view or list for visual container layout drawings
                    Expanded(
                      child: ListView.builder(
                        itemCount: plan.length,
                        itemBuilder: (ctx, pIdx) {
                          final res = plan[pIdx];
                          if (res.containerCode == 'FAILED') {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          res.failureReason ?? l.operationFailed,
                                          style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (res.unplacedItems.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${l.packageMeasurementsTitle}: ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
                                            style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                      ),
                                      Row(
                                        children: [
                                          Text(l.cbmWoodenPalletsFloor, style: const TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                            child: Text('${l.cbmInternalDimensionsLabel} ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 10, color: AppTheme.cobalt)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Side View (Left Wall Removed) - Matches the Reference Image!
                                  Container(
                                    height: 190,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: ContainerLoadPlanPainter(plan: res, isTopView: false),
                                      child: Container(),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Top View (Roof Removed)
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: ContainerLoadPlanPainter(plan: res, isTopView: true),
                                      child: Container(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  label: Text(l.closePlan),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}




