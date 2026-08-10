import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
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
    ),
  ];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cargo Measurement Engine (حاسبة الأحجام والوزن الجوي)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'BP-004: احتساب الـ CBM، الوزن الجوي المحاسبي Chargeable Wt، وتوصيات الحاويات ووسيلة الشحن',
                        style: TextStyle(color: AppTheme.cloudWhite, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.amber,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelColor: Colors.white70,
                  labelColor: Colors.amber,
                  tabs: const [
                    Tab(icon: Icon(Icons.speed), text: 'Quick Operational Calculator'),
                    Tab(icon: Icon(Icons.history), text: 'Saved Calculations History Log'),
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

    final modeRec = dualRec.modeRecommendation;
    String recMethod = modeRec.recommendedModeAr;
    String recContainer = modeRec.reasonAr;
    if (totalCbm >= 15.0) {
      recContainer = containerRec.recommendationSummary;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Live Results Summary Cards Header
          Row(
            children: [
              _buildResultCard('Total CBM Volume', '${totalCbm.toStringAsFixed(4)} m³', Icons.view_in_ar, Colors.orange),
              const SizedBox(width: 12),
              if (_quickShipmentMode == 'air') ...[
                _buildResultCard('Air Chargeable Wt', '${chargeableWt.toStringAsFixed(2)} KG', Icons.airplanemode_active, Colors.purple,
                    subtitle: 'Volumetric: ${totalVolumetricWt.toStringAsFixed(2)} kg'),
                const SizedBox(width: 12),
                _buildResultCard('Total Gross Weight', '${totalGrossWt.toStringAsFixed(2)} KG', Icons.scale, Colors.green),
                const SizedBox(width: 12),
              ],
              _buildResultCard('Recommended Shipping', recMethod, Icons.directions_boat, modeRec.isAirSuggested ? Colors.purple : (modeRec.isLclSuggested ? Colors.amber.shade900 : Colors.blue), subtitle: recContainer),
            ],
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
                        const Text('🚚 تعليمات التحميل (Cargo Stacking): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('📦 قابل للرص (Stackable)'),
                          selected: _isStackable,
                          selectedColor: AppTheme.cobalt,
                          labelStyle: TextStyle(color: _isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                          onSelected: (val) => setState(() => _isStackable = true),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('🚫 غير قابل للرص (Non-Stackable)'),
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
                          label: const Text('مقارنة الحالتين (Matrix)', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => _showContainerComparisonDialog(context, dualRec, totalCbm, totalGrossWt),
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
                          modeRec.reasonAr,
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
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_list_bulleted, color: AppTheme.cobalt),
                      SizedBox(width: 8),
                      Text(
                        'Cargo Package Measurements & Dimensions (أبعاد ووزن الطرود)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                              label: const Text('Air Freight (شحن جوي)'),
                              selected: _quickShipmentMode == 'air',
                              selectedColor: AppTheme.cobalt,
                              labelStyle: TextStyle(color: _quickShipmentMode == 'air' ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                              onSelected: (_) => setState(() => _quickShipmentMode = 'air'),
                            ),
                            const SizedBox(width: 4),
                            ChoiceChip(
                              label: const Text('Sea Freight (شحن بحري)'),
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
                        label: const Text('Add Package Line'),
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
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Session'),
                        onPressed: () => _showSaveCalcDialog(context, _quickItems),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Dynamic Line Items List
          Expanded(
            child: Card(
              elevation: 1,
              child: ListView.separated(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      ),
                      const SizedBox(width: 8),
                      // Package Type Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: item.packageType,
                          decoration: const InputDecoration(labelText: 'Package Type', isDense: true, border: OutlineInputBorder()),
                          items: ['Carton', 'Pallet', 'Wooden Crate', 'Drum', 'Bag', 'Loose Box']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
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
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Dimension Unit Selector (mm, cm, m)
                      SizedBox(
                        width: 90,
                        child: DropdownButtonFormField<String>(
                          value: item.unit,
                          decoration: const InputDecoration(labelText: 'Unit', isDense: true, border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'mm', child: Text('mm')),
                            DropdownMenuItem(value: 'cm', child: Text('cm')),
                            DropdownMenuItem(value: 'm', child: Text('m')),
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
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Quantity
                      Expanded(
                        child: TextFormField(
                          initialValue: item.quantity.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
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
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Length
                      Expanded(
                        child: TextFormField(
                          initialValue: item.length.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Length (${item.unit})', isDense: true, border: const OutlineInputBorder()),
                          onChanged: (v) {
                            final l = double.tryParse(v) ?? 0.0;
                            setState(() {
                              _quickItems[idx] = CBMItemModel(
                                packageType: item.packageType,
                                quantity: item.quantity,
                                length: l,
                                width: item.width,
                                height: item.height,
                                unit: item.unit,
                                grossWeightPerUnitKg: item.grossWeightPerUnitKg,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Width
                      Expanded(
                        child: TextFormField(
                          initialValue: item.width.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Width (${item.unit})', isDense: true, border: const OutlineInputBorder()),
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
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Height
                      Expanded(
                        child: TextFormField(
                          initialValue: item.height.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Height (${item.unit})', isDense: true, border: const OutlineInputBorder()),
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
                              );
                            });
                          },
                        ),
                      ),
                      if (_quickShipmentMode == 'air') ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.grossWeightPerUnitKg.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Gross Wt/Unit (kg)', isDense: true, border: OutlineInputBorder()),
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
                                );
                              });
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),

                      // Computed line outputs badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('CBM: ${itemCbm.toStringAsFixed(4)} m³', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          if (_quickShipmentMode == 'air') ...[
                            Text('Gross: ${itemGross.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Air Vol: ${itemVolWt.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, color: Colors.purple)),
                          ],
                        ],
                      ),
                      if (_quickItems.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal), overflow: TextOverflow.ellipsis),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: SAVED CALCULATIONS REGISTRY
  // ---------------------------------------------------------------------------
  Widget _buildSavedRegistryTab(
    BuildContext context,
    CBMCalculatorState state,
    List projectsList,
    List poList,
  ) {
    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by calculation code, title, or notes...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(cbmCalculatorProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => ref.read(cbmCalculatorProvider.notifier).setSearchQuery(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: state.showInactive,
                        onChanged: (v) => ref.read(cbmCalculatorProvider.notifier).toggleShowInactive(v ?? false),
                      ),
                      const Text('Show Inactive', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                    tooltip: 'Live Refresh',
                    onPressed: () => ref.read(cbmCalculatorProvider.notifier).fetchCalculations(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Saved Calculations Data Table
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.calculations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No Saved Calculation Sessions Found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              dataRowMaxHeight: 52,
                              columns: const [
                                DataColumn(label: Text('Calc Code')),
                                DataColumn(label: Text('Import File')),
                                DataColumn(label: Text('Title / Description')),
                                DataColumn(label: Text('Volume (CBM)')),
                                DataColumn(label: Text('Chargeable Wt')),
                                DataColumn(label: Text('Gross Wt')),
                                DataColumn(label: Text('Shipping Recommendation')),
                                DataColumn(label: Text('Container Suggestion')),
                                DataColumn(label: Text('Linked PO / Project')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: state.calculations.map((calc) {
                                return DataRow(
                                  onSelectChanged: (_) => _showCalcDetailsDialog(context, calc),
                                  cells: [
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showCalcDetailsDialog(context, calc),
                                        child: Text(calc.calcCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, decoration: TextDecoration.underline)),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.charcoal.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          calc.importFileCode ?? (calc.importFileId != null ? 'IMP-${calc.importFileId}' : '-'),
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(calc.title ?? 'Calculation Session', overflow: TextOverflow.ellipsis),
                                    ),
                                    DataCell(
                                      Text('${calc.totalCbm.toStringAsFixed(3)} m³', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ),
                                    DataCell(
                                      Text('${calc.airChargeableWeightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                                    ),
                                    DataCell(Text('${calc.totalGrossWeightKg.toStringAsFixed(1)} kg')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text(calc.recommendedShippingMethod ?? '-', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text(calc.recommendedContainerType ?? '-', style: const TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    DataCell(
                                      Text(calc.poNumber != null
                                          ? 'PO: ${calc.poNumber}'
                                          : calc.projectName != null
                                              ? 'PRJ: ${calc.projectName}'
                                              : 'Unbound / Standalone',
                                          style: TextStyle(
                                            color: calc.poNumber != null ? AppTheme.emerald : Colors.grey,
                                            fontWeight: calc.poNumber != null ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 11,
                                          )),
                                    ),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: AppTheme.charcoal, size: 20),
                                        tooltip: 'Actions',
                                        onSelected: (val) async {
                                          if (val == 'reopen') {
                                            setState(() {
                                              _quickShipmentMode = (calc.recommendedShippingMethod ?? '').contains('Air') ? 'air' : 'sea';
                                              if (calc.items.isNotEmpty) {
                                                _quickItems.clear();
                                                _quickItems.addAll(calc.items.map((i) => CBMItemModel(
                                                  packageType: i.packageType,
                                                  quantity: i.quantity,
                                                  length: i.lengthCm > 0 ? i.lengthCm : i.length,
                                                  width: i.widthCm > 0 ? i.widthCm : i.width,
                                                  height: i.heightCm > 0 ? i.heightCm : i.height,
                                                  unit: 'cm',
                                                  grossWeightPerUnitKg: i.grossWeightPerUnitKg,
                                                )));
                                              }
                                            });
                                            _tabController.animateTo(0);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Session ${calc.calcCode} loaded into Quick Calculator.')),
                                            );
                                          } else if (val == 'link') {
                                            _showLinkToPODialog(context, calc, poList, projectsList);
                                          } else if (val == 'view') {
                                            _showCalcDetailsDialog(context, calc);
                                          } else if (val == 'print') {
                                            _showPrintReportDialog(context, calc);
                                          } else if (val == 'delete_restore') {
                                            if (calc.isActive) {
                                              await ref.read(cbmCalculatorProvider.notifier).deleteCalculation(calc.calcId!);
                                            } else {
                                              await ref.read(cbmCalculatorProvider.notifier).restoreCalculation(calc.calcId!);
                                            }
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'reopen',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_note, color: AppTheme.cobalt, size: 18),
                                                SizedBox(width: 8),
                                                Text('Reopen in Calculator (إعادة فتح وتعديل)'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility_outlined, color: AppTheme.cobalt, size: 18),
                                                SizedBox(width: 8),
                                                Text('View Session Details (عرض التفاصيل)'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'print',
                                            child: Row(
                                              children: [
                                                Icon(Icons.print_outlined, color: AppTheme.emerald, size: 18),
                                                SizedBox(width: 8),
                                                Text('Print / Export Report (طباعة وتصدير)'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'link',
                                            child: Row(
                                              children: [
                                                Icon(Icons.link, color: AppTheme.cobalt, size: 18),
                                                SizedBox(width: 8),
                                                Text('Link to PO / Project'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete_restore',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  calc.isActive ? Icons.delete_outline : Icons.restore,
                                                  color: calc.isActive ? AppTheme.crimson : AppTheme.emerald,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(calc.isActive ? 'Deactivate' : 'Restore'),
                                              ],
                                            ),
                                          ),
                                        ],
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
        ),
      ],
    );
  }

  void _showSaveCalcDialog(BuildContext context, List<CBMItemModel> items) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: 'حساب قياسات شحنة جديد');
    final notesCtrl = TextEditingController();
    int? selectedImportFileId;
    final importFiles = ref.read(importFilesProvider).value ?? [];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Save Calculation Session (حفظ الجلسة التشغيلية)'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<int?>(
                    value: selectedImportFileId,
                    labelText: 'Import File (رقم ملف الشحنة)',
                    searchHintText: 'ابحث عن ملف الشحنة...',
                    items: [
                      const SearchableDropdownItem<int?>(
                        value: null,
                        label: '-- None / غير مرتبط بملف شحنة --',
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
                    decoration: const InputDecoration(labelText: 'Calculation Session Title *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes & Cargo Remarks'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final calc = CBMCalculationModel(
                    calcCode: '',
                    importFileId: selectedImportFileId,
                    title: titleCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    items: items,
                  );
                final ok = await ref.read(cbmCalculatorProvider.notifier).createCalculation(calc);
                if (ok && context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calculation session saved successfully.')),
                  );
                  _tabController.animateTo(1);
                } else if (context.mounted) {
                  final err = ref.read(cbmCalculatorProvider).errorMessage ?? 'Failed to save calculation session.';
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.crimson),
                  );
                }
              }
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    ),
    );
  }

  void _showCalcDetailsDialog(BuildContext context, CBMCalculationModel calc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calculate, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text('Calculation Details: ${calc.calcCode}'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(
                calc.poNumber != null ? 'Linked to PO: ${calc.poNumber}' : 'Standalone Session',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(calc.title ?? 'Calculation Session', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal)),
                      if (calc.notes != null && calc.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📝 Notes: ${calc.notes}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Badges Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildDetailCardBadge('Total CBM Volume', '${calc.totalCbm.toStringAsFixed(4)} m³', Icons.view_in_ar, Colors.orange),
                    _buildDetailCardBadge('Air Chargeable Weight', '${calc.airChargeableWeightKg.toStringAsFixed(1)} KG', Icons.airplanemode_active, Colors.purple),
                    _buildDetailCardBadge('Total Gross Weight', '${calc.totalGrossWeightKg.toStringAsFixed(1)} KG', Icons.scale, Colors.blue),
                    _buildDetailCardBadge('Shipping Strategy', calc.recommendedShippingMethod ?? '-', Icons.directions_boat, AppTheme.cobalt),
                    _buildDetailCardBadge('Container Type', calc.recommendedContainerType ?? '-', Icons.inventory, Colors.brown),
                  ],
                ),

                const Divider(height: 28),
                const Text('📦 Package Measurements & Dimensions Breakdown (تفاصيل طرود ومقاسات الشحنة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                const SizedBox(height: 10),

                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppTheme.cloudWhite),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Package Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('L x W x H (cm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Gross Wt/Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Line Volume CBM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Line Gross Wt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    ...calc.items.asMap().entries.map(
                      (entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final lineGross = item.quantity * item.grossWeightPerUnitKg;
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(item.packageType, style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.quantity}', style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.lengthCm} x ${item.widthCm} x ${item.heightCm}', style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.grossWeightPerUnitKg} kg', style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${item.totalCbm.toStringAsFixed(4)} m³', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text('${lineGross.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
            label: const Text('إعادة فتح وتعديل في الحاسبة', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _quickShipmentMode = (calc.recommendedShippingMethod ?? '').contains('Air') ? 'air' : 'sea';
                if (calc.items.isNotEmpty) {
                  _quickItems.clear();
                  _quickItems.addAll(calc.items.map((i) => CBMItemModel(
                    packageType: i.packageType,
                    quantity: i.quantity,
                    length: i.lengthCm > 0 ? i.lengthCm : i.length,
                    width: i.widthCm > 0 ? i.widthCm : i.width,
                    height: i.heightCm > 0 ? i.heightCm : i.height,
                    unit: 'cm',
                    grossWeightPerUnitKg: i.grossWeightPerUnitKg,
                  )));
                }
              });
              _tabController.animateTo(0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تحميل بيانات الجلسة ${calc.calcCode} للحاسبة للتعديل والحساب.')),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('تعديل البيانات (Edit Metadata)'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showEditCalcDialog(context, calc);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('طباعة / تصدير التقرير'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showPrintReportDialog(context, calc);
            },
          ),
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailCardBadge(String title, String val, IconData icon, Color color) {
    return Container(
      width: 220,
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
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: calc.title ?? '');
    final notesCtrl = TextEditingController(text: calc.notes ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Edit Session Details: ${calc.calcCode}'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Calculation Title *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes & Remarks'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
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
                    const SnackBar(content: Text('Calculation metadata updated successfully.')),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showPrintReportDialog(BuildContext context, CBMCalculationModel calc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.print_outlined, color: AppTheme.emerald),
            const SizedBox(width: 8),
            Text('Printable Cargo Measurement Report (${calc.calcCode})'),
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
                          const Text('ImportFlow ERP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
                          const Text('Cargo Measurement & Volume Calculation Report', style: TextStyle(color: AppTheme.cobalt, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('تقرير احتساب حجوم وأوزان الشحنات (BP-004)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
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
                          Text('Generated: ${calc.createdAt != null ? calc.createdAt.toString().substring(0, 10) : DateTime.now().toString().substring(0, 10)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1.5),

                  // Session Metadata
                  Row(
                    children: [
                      Expanded(child: Text('Title: ${calc.title ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      if (calc.poNumber != null)
                        Text('Linked PO: ${calc.poNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 12)),
                    ],
                  ),
                  if (calc.notes != null && calc.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Notes: ${calc.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  const SizedBox(height: 16),

                  // Summary Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildReportStat('Total Volume', '${calc.totalCbm.toStringAsFixed(4)} m³', Colors.orange),
                        _buildReportStat('Air Chargeable Wt', '${calc.airChargeableWeightKg.toStringAsFixed(1)} kg', Colors.purple),
                        _buildReportStat('Total Gross Wt', '${calc.totalGrossWeightKg.toStringAsFixed(1)} kg', AppTheme.cobalt),
                        _buildReportStat('Shipping Mode', calc.recommendedShippingMethod ?? '-', Colors.blue),
                        _buildReportStat('Container Type', calc.recommendedContainerType ?? '-', Colors.brown),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Package Details Table
                  const Text('Package Breakdown Table (جدول تفاصيل الطرود والقياسات)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade400),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: AppTheme.cloudWhite),
                        children: [
                          Padding(padding: EdgeInsets.all(6), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Package Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('L x W x H (cm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Gross Wt/Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Total Gross Wt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Line CBM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
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
            label: const Text('تنزيل ملف CSV Data'),
            onPressed: () {
              _downloadCalcCSV(context, calc);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('طباعة التقرير (Print Report)'),
            onPressed: () {
              _triggerReportPrint(context, calc);
            },
          ),
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
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
    buffer.writeln('ImportFlow ERP - Cargo Volume & Weight Measurement Report');
    buffer.writeln('Calc Code,${calc.calcCode}');
    buffer.writeln('Title,${calc.title ?? ""}');
    buffer.writeln('Notes,${calc.notes ?? ""}');
    buffer.writeln('Total CBM,${calc.totalCbm}');
    buffer.writeln('Air Chargeable Weight (kg),${calc.airChargeableWeightKg}');
    buffer.writeln('Total Gross Weight (kg),${calc.totalGrossWeightKg}');
    buffer.writeln('Shipping Recommendation,${calc.recommendedShippingMethod ?? ""}');
    buffer.writeln('Container Suggestion,${calc.recommendedContainerType ?? ""}');
    buffer.writeln('');
    buffer.writeln('Pkg #,Package Type,Qty,Length (cm),Width (cm),Height (cm),Gross Wt/Unit (kg),Line CBM (m3),Total Gross Wt (kg)');

    for (int i = 0; i < calc.items.length; i++) {
      final item = calc.items[i];
      final lineGross = item.quantity * item.grossWeightPerUnitKg;
      buffer.writeln('${i + 1},${item.packageType},${item.quantity},${item.lengthCm},${item.widthCm},${item.heightCm},${item.grossWeightPerUnitKg},${item.totalCbm},$lineGross');
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
    int? selectedPoId = calc.poId;
    int? selectedProjectId = calc.projectId;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Link Calculation (${calc.calcCode}) to Shipment / PO'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdownField<int?>(
                  value: selectedPoId,
                  labelText: 'Select Purchase Order (PO)',
                  searchHintText: 'ابحث عن أمر الشراء...',
                  items: [
                    const SearchableDropdownItem<int?>(value: null, label: 'None / Standalone'),
                    ...poList.map((po) => SearchableDropdownItem<int?>(
                          value: po.poId,
                          label: '${po.poNumber} (${po.projectName ?? "Project"})',
                          subtitle: po.supplierName,
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedPoId = v),
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<int?>(
                  value: selectedProjectId,
                  labelText: 'Select Project',
                  searchHintText: 'ابحث عن المشروع...',
                  items: [
                    const SearchableDropdownItem<int?>(value: null, label: 'None / Unbound'),
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
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
              onPressed: () async {
                final ok = await ref
                    .read(cbmCalculatorProvider.notifier)
                    .linkToPO(calc.calcId!, poId: selectedPoId, projectId: selectedProjectId);
                if (ok && context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calculation record linked successfully.')),
                  );
                }
              },
              child: const Text('Save Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContainerComparisonDialog(BuildContext context, ContainerDualRecommendationResult dualRec, double totalCbm, double totalWeightKg) {
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
                      const Text('تحليل خيارات الحاويات وسيناريوهات التحميل (MD-019.1 Matrix)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('إجمالي الشحنة: ${totalCbm.toStringAsFixed(2)} m³ | ${totalWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
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
                    child: const TabBar(
                      indicatorColor: AppTheme.cobalt,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(icon: Icon(Icons.layers), text: '📦 قابل للرص (Stackable)'),
                        Tab(icon: Icon(Icons.view_array), text: '🚫 غير قابل للرص - طبقة واحدة (Non-Stackable)'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildComparisonTable(dualRec.stackableResult),
                        _buildComparisonTable(dualRec.nonStackableResult),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonTable(ContainerRecommendationResult rec) {
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
            child: Text('التوصية المعتمدة: ${rec.recommendationSummary}', style: TextStyle(fontWeight: FontWeight.bold, color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade900)),
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
                children: const [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('نوع الحاوية (Spec)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('العدد المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('استغلال المساحة %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('استغلال الوزن %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('التوصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                          Text('السعة: ${spec.internalVolumeCbm} CBM | الحمولة: ${spec.maxPayloadKg} kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                              child: const Text('🌟 الخيار الأنسب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            )
                          : const Text('بديل قابل للتطبيق', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
}
