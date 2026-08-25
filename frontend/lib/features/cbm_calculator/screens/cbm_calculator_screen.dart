import '../../projects/models/project_model.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../widgets/saved_cbm_registry_tab.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';

import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/utils/container_requirement_engine.dart';

import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/cbm_calculator_model.dart';
import '../providers/cbm_calculator_provider.dart';

class CBMCalculatorScreen extends ConsumerStatefulWidget {
  const CBMCalculatorScreen({super.key});

  @override
  ConsumerState<CBMCalculatorScreen> createState() => _CBMCalculatorScreenState();
}

class _CBMCalculatorScreenState extends ConsumerState<CBMCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Active Editing Session State
  int? _activeSessionId;
  String? _activeSessionCode;
  String? _activeSessionTitle;
  String? _activeSessionNotes;
  int? _activeSessionImportFileId;

  // Quick Calculator State
  String _quickShipmentMode = 'air';
  bool _isStackable = true;
  final List<CBMItemModel> _quickItems = [
    CBMItemModel(
      packageType: 'Carton',
      quantity: 10,
      length: 100,
      width: 50,
      height: 40,
      unit: 'cm',
      grossWeightPerUnitKg: 15,
      isStackable: true,
    ),
  ];

  final ScrollController _quickTabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(cbmCalculatorProvider.notifier).fetchCalculations();
      ref.read(projectsProvider.notifier).fetchProjects();
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _quickTabScrollController.dispose();
    super.dispose();
  }

  void _clearActiveSession() {
    setState(() {
      _activeSessionId = null;
      _activeSessionCode = null;
      _activeSessionTitle = null;
      _activeSessionNotes = null;
      _activeSessionImportFileId = null;
      _quickItems.clear();
      _quickItems.add(
        CBMItemModel(
          packageType: 'Carton',
          quantity: 10,
          length: 100,
          width: 50,
          height: 40,
          unit: 'cm',
          grossWeightPerUnitKg: 15,
          isStackable: true,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.newBlankSession)),
    );
  }

  void _loadSessionForEditing(CBMCalculationModel calc) {
    setState(() {
      _activeSessionId = calc.calcId;
      _activeSessionCode = calc.calcCode;
      _activeSessionTitle = calc.title;
      _activeSessionNotes = calc.notes;
      _activeSessionImportFileId = calc.importFileId;
      _isStackable = calc.isStackable;
      _quickShipmentMode = (calc.recommendedShippingMethod ?? '').toLowerCase().contains('air') ? 'air' : 'sea';

      _quickItems.clear();
      if (calc.items.isNotEmpty) {
        _quickItems.addAll(calc.items.map((i) => CBMItemModel(
              itemId: i.itemId,
              calcId: i.calcId,
              packageType: i.packageType.isNotEmpty ? i.packageType : 'Carton',
              quantity: i.quantity > 0 ? i.quantity : 1,
              length: i.length > 0 ? i.length : (i.lengthCm > 0 ? i.lengthCm : 100.0),
              width: i.width > 0 ? i.width : (i.widthCm > 0 ? i.widthCm : 80.0),
              height: i.height > 0 ? i.height : (i.heightCm > 0 ? i.heightCm : 60.0),
              unit: (i.unit.isNotEmpty) ? i.unit : 'cm',
              grossWeightPerUnitKg: i.grossWeightPerUnitKg,
              isStackable: i.isStackable,
            )));
      } else {
        _quickItems.add(
          CBMItemModel(
            packageType: 'Carton',
            quantity: 1,
            length: 100,
            width: 80,
            height: 60,
            unit: 'cm',
            grossWeightPerUnitKg: 20,
            isStackable: _isStackable,
          ),
        );
      }
    });
    _tabController.animateTo(0);
  }

  Future<void> _updateActiveSessionDirectly() async {
    if (_activeSessionId == null) return;
    final l = context.l10n;
    final payload = {
      'title': _activeSessionTitle ?? l.calculationSessionTitle,
      'import_file_id': _activeSessionImportFileId,
      'notes': _activeSessionNotes,
      'is_stackable': _isStackable,
      'items': _quickItems.map((i) => i.toCreateJson()).toList(),
    };
    final ok = await ref.read(cbmCalculatorProvider.notifier).updateCalculation(_activeSessionId!, payload);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.saveChangesInSession} [$_activeSessionCode]'),
          backgroundColor: AppTheme.emerald,
        ),
      );
      ref.read(cbmCalculatorProvider.notifier).fetchCalculations();
    } else if (mounted) {
      final err = ref.read(cbmCalculatorProvider).errorMessage ?? l.operationFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.crimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(cbmCalculatorProvider);
    final projectsList = ref.watch(projectsProvider).value ?? [];
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.charcoal, AppTheme.cobalt],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cbmCalculatorTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l.cbmCalculatorSubtitle,
                        style: const TextStyle(color: AppTheme.cloudWhite, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const BackToDashboardButton(),
                const SizedBox(width: 10),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.amber,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelColor: Colors.white70,
                  labelColor: Colors.amber,
                  tabs: [
                    Tab(icon: const Icon(Icons.speed), text: l.quickOperationalCalculatorTab),
                    Tab(icon: const Icon(Icons.history), text: l.savedCalculationsRegistryTab),
                  ],
                ),
              ],
            ),
          ),


          // Main View Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Interactive Standalone Calculator
                _buildQuickCalculatorTab(context),

                // Tab 2: Saved History Registry
                _buildSavedRegistryTab(context, state, projectsList, poList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: QUICK OPERATIONAL CALCULATOR
  // ---------------------------------------------------------------------------
  Widget _buildQuickCalculatorTab(BuildContext context) {
    final l = context.l10n;
    // Compute local totals
    double totalCbm = 0.0;
    double totalGrossWt = 0.0;
    double totalVolumetricWt = 0.0;

    for (var item in _quickItems) {
      final lM = item.lengthM;
      final wM = item.widthM;
      final hM = item.heightM;
      final cbm = item.quantity * lM * wM * hM;
      final volWt = (item.quantity * (lM * 100.0) * (wM * 100.0) * (hM * 100.0)) / 6000.0;
      final gross = item.quantity * item.grossWeightPerUnitKg;

      totalCbm += cbm;
      totalVolumetricWt += volWt;
      totalGrossWt += gross;
    }

    final chargeableWt = totalGrossWt > totalVolumetricWt ? totalGrossWt : totalVolumetricWt;

    final dualRec = ContainerRequirementEngine.calculateBoth(totalCbm: totalCbm, totalWeightKg: totalGrossWt);
    final containerRec = _isStackable ? dualRec.stackableResult : dualRec.nonStackableResult;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final modeRec = dualRec.modeRecommendation;
    String recMethod = isArabic ? modeRec.recommendedModeAr : modeRec.recommendedMode;
    String recContainer = isArabic ? modeRec.reasonAr : modeRec.reasonEn;
    if (totalCbm >= 15.0) {
      recContainer = isArabic ? containerRec.recommendationSummary : containerRec.recommendationSummaryEn;
    }

    return Scrollbar(
      controller: _quickTabScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _quickTabScrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Editing Session Banner (If editing a saved calculation)
            if (_activeSessionId != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, color: Colors.amber.shade900, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${l.activeEditSessionBanner}: [$_activeSessionCode] - ${_activeSessionTitle ?? ""}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown.shade900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.activeEditSessionHint,
                              style: TextStyle(fontSize: 11, color: Colors.brown.shade800),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text('${l.saveChangesInSession} [$_activeSessionCode]'),
                          onPressed: _updateActiveSessionDirectly,
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.charcoal,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l.newBlankSession),
                          onPressed: _clearActiveSession,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Live Results Summary Cards Header (Responsive LayoutBuilder)
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _buildResultCardItem(l.totalCbmVolumeMetric, '${totalCbm.toStringAsFixed(4)} m³', Icons.view_in_ar, Colors.orange),
                  if (_quickShipmentMode == 'air') ...[
                    _buildResultCardItem(l.airChargeableWtMetric, '${chargeableWt.toStringAsFixed(2)} KG', Icons.airplanemode_active, Colors.purple,
                        subtitle: '${l.volumetricWeight}: ${totalVolumetricWt.toStringAsFixed(2)} kg'),
                    _buildResultCardItem(l.grossWeightMetric, '${totalGrossWt.toStringAsFixed(2)} KG', Icons.scale, Colors.green),
                  ],
                  _buildResultCardItem(l.recommendedShippingMetric, recMethod, Icons.directions_boat,
                      modeRec.isAirSuggested ? Colors.purple : (modeRec.isLclSuggested ? Colors.amber.shade900 : Colors.blue),
                      subtitle: recContainer),
                ];

                if (constraints.maxWidth > 950) {
                  return Row(
                    children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: c))).toList(),
                  );
                } else {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cards
                        .map((c) => SizedBox(
                              width: (constraints.maxWidth - 16) / 2,
                              child: c,
                            ))
                        .toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Smart Mode & Cargo Stacking Skill Banner (MD-019.1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: modeRec.isAirSuggested
                    ? Colors.purple.shade50
                    : (modeRec.isLclSuggested ? Colors.amber.shade50 : AppTheme.cobalt.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: modeRec.isAirSuggested
                      ? Colors.purple.shade300
                      : (modeRec.isLclSuggested ? Colors.amber.shade300 : AppTheme.cobalt.withOpacity(0.3)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 22),
                          const SizedBox(width: 8),
                          Text(l.cargoStackingInstructions, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text(l.stackableOption),
                            selected: _isStackable,
                            selectedColor: AppTheme.cobalt,
                            labelStyle: TextStyle(color: _isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                            onSelected: (val) => setState(() => _isStackable = true),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text(l.nonStackableOption),
                            selected: !_isStackable,
                            selectedColor: Colors.orange.shade800,
                            labelStyle: TextStyle(color: !_isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                            onSelected: (val) => setState(() => _isStackable = false),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.table_chart, size: 14, color: Colors.white),
                            label: Text(l.compareContainersMatrix, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _showContainerComparisonDialog(context, dualRec, totalCbm, totalGrossWt),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emerald,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.view_in_ar, size: 14, color: Colors.white),
                            label: Text(l.visualLoadPlanSimulator, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _showVisualLoadPlanDialog(context, _quickItems),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          modeRec.isAirSuggested ? Icons.airplanemode_active : (modeRec.isLclSuggested ? Icons.inventory : Icons.directions_boat),
                          color: modeRec.isAirSuggested ? Colors.purple : (modeRec.isLclSuggested ? Colors.amber.shade900 : AppTheme.cobalt),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic ? modeRec.reasonAr : modeRec.reasonEn,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: modeRec.isAirSuggested ? Colors.purple.shade900 : (modeRec.isLclSuggested ? Colors.amber.shade900 : AppTheme.charcoal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Items Table Header & Add Row Action Card (Responsive Overflow-Free Layout)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_list_bulleted, color: AppTheme.cobalt),
                        const SizedBox(width: 8),
                        Text(
                          l.packageMeasurementsTitle,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Shipment Mode Selector (Air vs Sea)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChoiceChip(
                                label: Text(l.airFreightMode),
                                selected: _quickShipmentMode == 'air',
                                selectedColor: AppTheme.cobalt,
                                labelStyle: TextStyle(color: _quickShipmentMode == 'air' ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                                onSelected: (_) => setState(() => _quickShipmentMode = 'air'),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: Text(l.seaFreightMode),
                                selected: _quickShipmentMode == 'sea',
                                selectedColor: AppTheme.emerald,
                                labelStyle: TextStyle(color: _quickShipmentMode == 'sea' ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                                onSelected: (_) => setState(() => _quickShipmentMode = 'sea'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l.addPackageLine),
                          onPressed: () {
                            setState(() {
                              _quickItems.add(
                                CBMItemModel(
                                  packageType: 'Carton',
                                  quantity: 1,
                                  length: 100,
                                  width: 80,
                                  height: 60,
                                  unit: 'cm',
                                  grossWeightPerUnitKg: 20,
                                  isStackable: _isStackable,
                                ),
                              );
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: Text(_activeSessionId != null ? l.saveChanges : l.saveCalculationSession),
                          onPressed: () => _showSaveCalcDialog(context, _quickItems),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dynamic Line Items List (Horizontally & Vertically Scrollable with Explicit Scrollbar)
            Card(
              elevation: 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: _quickShipmentMode == 'air' ? 1220 : 1080,
                  ),
                  child: SizedBox(
                    width: math.max(
                      _quickShipmentMode == 'air' ? 1220.0 : 1080.0,
                      MediaQuery.of(context).size.width - 64,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Header Bar
                        Container(
                          color: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 160, child: Text(l.packageTypeCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 95, child: Text(l.unitCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 80, child: Text(l.qtyCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 100, child: Text(l.lengthCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 100, child: Text(l.widthCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 100, child: Text(l.heightCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 8),
                              SizedBox(width: 145, child: Text(l.stackingCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              if (_quickShipmentMode == 'air') ...[
                                const SizedBox(width: 8),
                                SizedBox(width: 120, child: Text(l.grossWtPerUnitCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              ],
                              const SizedBox(width: 14),
                              SizedBox(width: 140, child: Text(l.calculatedOutputsCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal))),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: _quickItems.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, idx) {
                            final item = _quickItems[idx];
                            final lM = item.lengthM;
                            final wM = item.widthM;
                            final hM = item.heightM;
                            final itemCbm = item.quantity * lM * wM * hM;
                            final itemVolWt = (item.quantity * (lM * 100.0) * (wM * 100.0) * (hM * 100.0)) / 6000.0;
                            final itemGross = item.quantity * item.grossWeightPerUnitKg;

                            return Row(
                              key: ValueKey('row_${idx}_${_activeSessionId}_${item.itemId}'),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text('#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                ),
                                const SizedBox(width: 8),
                                // Package Type Dropdown (width: 160)
                                SizedBox(
                                  width: 160,
                                  child: SearchableDropdownField<String>(
                                    key: ValueKey('type_${idx}_${item.packageType}_$_activeSessionId'),
                                    value: item.packageType,
                                    labelText: l.packageTypeCol,
                                    searchHintText: l.packageTypeCol,
                                    items: ['Carton', 'Pallet', 'Wooden Crate', 'Drum', 'Bag', 'Loose Box']
                                        .map((t) => SearchableDropdownItem<String>(value: t, label: t))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _quickItems[idx] = CBMItemModel(
                                            packageType: v,
                                            quantity: item.quantity,
                                            length: item.length,
                                            width: item.width,
                                            height: item.height,
                                            unit: item.unit,
                                            grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                            isStackable: item.isStackable,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Dimension Unit Selector (mm, cm, m) (width: 95)
                                SizedBox(
                                  width: 95,
                                  child: SearchableDropdownField<String>(
                                    key: ValueKey('unit_${idx}_${item.unit}_$_activeSessionId'),
                                    value: item.unit,
                                    labelText: l.unitCol,
                                    searchHintText: l.unitCol,
                                    items: const [
                                      SearchableDropdownItem<String>(value: 'mm', label: 'mm'),
                                      SearchableDropdownItem<String>(value: 'cm', label: 'cm'),
                                      SearchableDropdownItem<String>(value: 'm', label: 'm'),
                                    ],
                                    onChanged: (u) {
                                      if (u != null) {
                                        setState(() {
                                          _quickItems[idx] = CBMItemModel(
                                            packageType: item.packageType,
                                            quantity: item.quantity,
                                            length: item.length,
                                            width: item.width,
                                            height: item.height,
                                            unit: u,
                                            grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                            isStackable: item.isStackable,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity (width: 80)
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    key: ValueKey('qty_${idx}_${item.quantity}_$_activeSessionId'),
                                    initialValue: item.quantity.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(labelText: l.qtyCol, isDense: true, border: const OutlineInputBorder()),
                                    onChanged: (v) {
                                      final q = int.tryParse(v) ?? 1;
                                      setState(() {
                                        _quickItems[idx] = CBMItemModel(
                                          packageType: item.packageType,
                                          quantity: q,
                                          length: item.length,
                                          width: item.width,
                                          height: item.height,
                                          unit: item.unit,
                                          grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                          isStackable: item.isStackable,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Length (width: 100)
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    key: ValueKey('len_${idx}_${item.length}_$_activeSessionId'),
                                    initialValue: item.length.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(labelText: '${l.lengthCol} (${item.unit})', isDense: true, border: const OutlineInputBorder()),
                                    onChanged: (v) {
                                      final len = double.tryParse(v) ?? 0.0;
                                      setState(() {
                                        _quickItems[idx] = CBMItemModel(
                                          packageType: item.packageType,
                                          quantity: item.quantity,
                                          length: len,
                                          width: item.width,
                                          height: item.height,
                                          unit: item.unit,
                                          grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                          isStackable: item.isStackable,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Width (width: 100)
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    key: ValueKey('wid_${idx}_${item.width}_$_activeSessionId'),
                                    initialValue: item.width.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(labelText: '${l.widthCol} (${item.unit})', isDense: true, border: const OutlineInputBorder()),
                                    onChanged: (v) {
                                      final w = double.tryParse(v) ?? 0.0;
                                      setState(() {
                                        _quickItems[idx] = CBMItemModel(
                                          packageType: item.packageType,
                                          quantity: item.quantity,
                                          length: item.length,
                                          width: w,
                                          height: item.height,
                                          unit: item.unit,
                                          grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                          isStackable: item.isStackable,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Height (width: 100)
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    key: ValueKey('hei_${idx}_${item.height}_$_activeSessionId'),
                                    initialValue: item.height.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(labelText: '${l.heightCol} (${item.unit})', isDense: true, border: const OutlineInputBorder()),
                                    onChanged: (v) {
                                      final h = double.tryParse(v) ?? 0.0;
                                      setState(() {
                                        _quickItems[idx] = CBMItemModel(
                                          packageType: item.packageType,
                                          quantity: item.quantity,
                                          length: item.length,
                                          width: item.width,
                                          height: h,
                                          unit: item.unit,
                                          grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                          isStackable: item.isStackable,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Cargo Stacking Type (Stackable vs Non-Stackable) (width: 145)
                                SizedBox(
                                  width: 145,
                                  child: SearchableDropdownField<bool>(
                                    key: ValueKey('stack_${idx}_${item.isStackable}_$_activeSessionId'),
                                    value: item.isStackable,
                                    labelText: l.stackingCol,
                                    searchHintText: l.stackingCol,
                                    items: [
                                      SearchableDropdownItem<bool>(value: true, label: l.stackableOption),
                                      SearchableDropdownItem<bool>(value: false, label: l.nonStackableOption),
                                    ],
                                    onChanged: (st) {
                                      if (st != null) {
                                        setState(() {
                                          _quickItems[idx] = CBMItemModel(
                                            packageType: item.packageType,
                                            quantity: item.quantity,
                                            length: item.length,
                                            width: item.width,
                                            height: item.height,
                                            unit: item.unit,
                                            grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                                            isStackable: st,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                                if (_quickShipmentMode == 'air') ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 120,
                                    child: TextFormField(
                                      key: ValueKey('wt_${idx}_${item.grossWeightPerUnitKg}_$_activeSessionId'),
                                      initialValue: item.grossWeightPerUnitKg.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(labelText: l.grossWtPerUnitCol, isDense: true, border: const OutlineInputBorder()),
                                      onChanged: (v) {
                                        final gw = double.tryParse(v) ?? 0.0;
                                        setState(() {
                                          _quickItems[idx] = CBMItemModel(
                                            packageType: item.packageType,
                                            quantity: item.quantity,
                                            length: item.length,
                                            width: item.width,
                                            height: item.height,
                                            unit: item.unit,
                                            grossWeightPerUnitKg: gw,
                                            isStackable: item.isStackable,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 14),

                                // Computed line outputs badge (width: 140)
                                SizedBox(
                                  width: 140,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('CBM: ${itemCbm.toStringAsFixed(4)} m³', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                                      if (_quickShipmentMode == 'air') ...[
                                        Text('Gross: ${itemGross.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text('Air Vol: ${itemVolWt.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, color: Colors.purple)),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_quickItems.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
                                    tooltip: l.deleteRowTooltip,
                                    onPressed: () {
                                      setState(() {
                                        _quickItems.removeAt(idx);
                                      });
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCardItem(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: SAVED CALCULATIONS REGISTRY (سجل دراسة وحسابات الشحن)
  // ---------------------------------------------------------------------------

  void _showSaveCalcDialog(BuildContext context, List<CBMItemModel> items) {
    final l = context.l10n;
    final formKey = GlobalKey<FormState>();
    final isEditing = _activeSessionId != null;
    final titleCtrl = TextEditingController(text: isEditing ? (_activeSessionTitle ?? l.calculationSessionTitle) : l.calculationSessionTitle);
    final notesCtrl = TextEditingController(text: isEditing ? (_activeSessionNotes ?? '') : '');
    int? selectedImportFileId = isEditing ? _activeSessionImportFileId : null;
    final importFiles = ref.read(importFilesProvider).value ?? [];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_document : Icons.save_outlined, color: isEditing ? Colors.amber.shade900 : AppTheme.emerald),
              const SizedBox(width: 8),
              Text(isEditing ? '${l.saveChangesInSession} [$_activeSessionCode]' : l.saveCalculationSession),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Text(
                        l.activeEditSessionHint,
                        style: TextStyle(fontSize: 12, color: Colors.brown.shade900),
                      ),
                    ),
                  SearchableDropdownField<int?>(
                    value: selectedImportFileId,
                    labelText: l.importFileIdLabel,
                    searchHintText: l.importFileIdLabel,
                    items: [
                      SearchableDropdownItem<int?>(
                        value: null,
                        label: '-- ${l.allStatuses} --',
                      ),
                      ...importFiles.map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                            subtitle: f.companyName,
                          )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedImportFileId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: '${l.calculationSessionTitle} *'),
                    validator: (v) => v == null || v.trim().isEmpty ? l.requiredField : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l.notesAndCargoRemarks),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l.cancel),
            ),
            if (isEditing) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l.saveAsNewSession),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final calc = CBMCalculationModel(
                      calcCode: '',
                      importFileId: selectedImportFileId,
                      title: titleCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      isStackable: _isStackable,
                      items: items,
                    );
                    final ok = await ref.read(cbmCalculatorProvider.notifier).createCalculation(calc);
                    if (ok && context.mounted) {
                      Navigator.pop(dialogCtx);
                      _clearActiveSession();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.operationSuccessful)),
                      );
                      _tabController.animateTo(1);
                    } else if (context.mounted) {
                      final err = ref.read(cbmCalculatorProvider).errorMessage ?? l.operationFailed;
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: AppTheme.crimson),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                icon: const Icon(Icons.check, size: 16),
                label: Text('${l.saveChangesInSession} [$_activeSessionCode]'),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final payload = {
                      'title': titleCtrl.text.trim(),
                      'import_file_id': selectedImportFileId,
                      'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      'is_stackable': _isStackable,
                      'items': items.map((i) => i.toCreateJson()).toList(),
                    };
                    final ok = await ref.read(cbmCalculatorProvider.notifier).updateCalculation(_activeSessionId!, payload);
                    if (ok && context.mounted) {
                      Navigator.pop(dialogCtx);
                      setState(() {
                        _activeSessionTitle = titleCtrl.text.trim();
                        _activeSessionNotes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                        _activeSessionImportFileId = selectedImportFileId;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l.saveChangesInSession} [$_activeSessionCode]'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                      _tabController.animateTo(1);
                    } else if (context.mounted) {
                      final err = ref.read(cbmCalculatorProvider).errorMessage ?? l.operationFailed;
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: AppTheme.crimson),
                      );
                    }
                  }
                },
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                icon: const Icon(Icons.save, size: 16),
                label: Text(l.saveChanges),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final calc = CBMCalculationModel(
                      calcCode: '',
                      importFileId: selectedImportFileId,
                      title: titleCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      isStackable: _isStackable,
                      items: items,
                    );
                    final ok = await ref.read(cbmCalculatorProvider.notifier).createCalculation(calc);
                    if (ok && context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.operationSuccessful)),
                      );
                      _tabController.animateTo(1);
                    } else if (context.mounted) {
                      final err = ref.read(cbmCalculatorProvider).errorMessage ?? l.operationFailed;
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: AppTheme.crimson),
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CALCULATION DETAILS DIALOG (سجل وتفاصيل دراسة الحساب - تصميم مطابق لدراسة الشحن)
  // ---------------------------------------------------------------------------

  void _showContainerComparisonDialog(BuildContext context, ContainerDualRecommendationResult dualRec, double totalCbm, double totalWeightKg) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (context) {
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
                      Text(l.containerOptionsAnalysis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${l.totalShipmentSummary}: ${totalCbm.toStringAsFixed(2)} m³ | ${totalWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
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
                        Tab(icon: const Icon(Icons.layers), text: l.stackableOption),
                        Tab(icon: const Icon(Icons.view_array), text: l.nonStackableOption),
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
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
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
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.requiredCountCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(l.spaceUtilizationCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                          Text('${l.totalCbmVolumeMetric}: ${spec.internalVolumeCbm} CBM | Max: ${spec.maxPayloadKg} kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

    final l = context.l10n;
    if (cargoItems.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.cbmCalculatorTitle),
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
                      l.visualLoadPlanSimulator,
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
                              _buildMetricPill(l.qtyCol, '$totalPkgs', AppTheme.cobalt),
                              const SizedBox(width: 8),
                              _buildMetricPill(l.grossWeightMetric, '${totalPlanWeight.toStringAsFixed(0)} kg', AppTheme.charcoal),
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
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.grossWeightMetric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.spaceUtilizationCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(l.cargoStackingInstructions, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
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
                            statusText = res.failureReason ?? 'FAILED';
                          } else {
                            final nonStackInThis = res.placedItems.where((p) => !p.item.isStackable).length;
                            if (nonStackInThis > 0) {
                              statusText = '${l.nonStackableOption} ($nonStackInThis) - ${floorUtil.toStringAsFixed(1)}%';
                            } else {
                              statusText = '${l.stackableOption} ($totalPlacedCount)';
                            }
                          }

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  res.containerCode == 'FAILED' ? 'FAILED' : '$idx: ${res.spec.code}',
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
                                    color: statusText.contains('FAILED')
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
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
                                          res.failureReason ?? 'FAILED',
                                          style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        if (res.unplacedItems.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '# ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
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
                                        '${l.containerPlanTitle} #${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                            child: Text('${l.internalDimensions}: ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 10, color: AppTheme.cobalt)),
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

  Widget _buildSavedRegistryTab(
    BuildContext context,
    CBMCalculatorState state,
    List<ProjectModel> projectsList,
    List<PurchaseOrderModel> poList,
  ) {
    return SavedCbmRegistryTab(
      onLoadSession: _loadSessionForEditing,
      onSwitchToCalculator: () => _tabController.animateTo(0),
    );
  }
}
