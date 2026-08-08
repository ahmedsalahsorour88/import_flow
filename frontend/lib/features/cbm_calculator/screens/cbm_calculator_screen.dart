import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Cargo Measurement Engine (حاسبة الأحجام والوزن الجوي)',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'BP-004: احتساب الـ CBM، الوزن الجوي المحاسبي Chargeable Wt، وتوصيات الحاويات ووسيلة الشحن',
                      style: TextStyle(color: AppTheme.cloudWhite, fontSize: 12),
                    ),
                  ],
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
      final l_m = item.lengthM;
      final w_m = item.widthM;
      final h_m = item.heightM;
      final cbm = item.quantity * l_m * w_m * h_m;
      final volWt = (item.quantity * (l_m * 100.0) * (w_m * 100.0) * (h_m * 100.0)) / 6000.0;
      final gross = item.quantity * item.grossWeightPerUnitKg;

      totalCbm += cbm;
      totalVolumetricWt += volWt;
      totalGrossWt += gross;
    }

    final chargeableWt = totalGrossWt > totalVolumetricWt ? totalGrossWt : totalVolumetricWt;

    String recMethod = '';
    String recContainer = '';
    if (_quickShipmentMode == 'air' || (totalCbm <= 1.5 && totalGrossWt <= 300)) {
      recMethod = 'Air Freight (شحن جوي)';
      recContainer = 'Air Chargeable Wt: ${chargeableWt.toStringAsFixed(1)} kg';
    } else if (totalCbm <= 15.0) {
      recMethod = 'LCL Ocean Freight (شحن بحري تجميعي)';
      recContainer = 'LCL Consolidation Container';
    } else {
      recMethod = 'FCL Container (حاوية كاملة بحرية)';
      if (totalCbm <= 33.0) {
        recContainer = '1 x 20FT Standard Container (20\' ST)';
      } else if (totalCbm <= 67.0) {
        recContainer = '1 x 40FT Standard Container (40\' ST)';
      } else if (totalCbm <= 76.0) {
        recContainer = '1 x 40FT High Cube Container (40\' HC)';
      } else {
        final count = (totalCbm / 76.0).ceil();
        recContainer = '$count x 40FT High Cube Containers (40\' HC)';
      }
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
              _buildResultCard('Recommended Shipping', recMethod, Icons.directions_boat, Colors.blue, subtitle: recContainer),
            ],
          ),
          const SizedBox(height: 16),

          // Items Table Header & Add Row Action
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.format_list_bulleted, color: AppTheme.cobalt),
                  const SizedBox(width: 8),
                  const Text(
                    'Cargo Package Measurements & Dimensions (أبعاد ووزن الطرود)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                  ),
                  const SizedBox(width: 24),
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
                  const Spacer(),
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Calculation Session'),
                    onPressed: () => _showSaveCalcDialog(context, _quickItems),
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
                  final l_m = item.lengthM;
                  final w_m = item.widthM;
                  final h_m = item.heightM;
                  final itemCbm = item.quantity * l_m * w_m * h_m;
                  final itemVolWt = (item.quantity * (l_m * 100.0) * (w_m * 100.0) * (h_m * 100.0)) / 6000.0;
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
                        width: 80,
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
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
                                  cells: [
                                    DataCell(
                                      Text(calc.calcCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
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
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.link, color: AppTheme.cobalt, size: 20),
                                            tooltip: 'Link to Purchase Order / Project',
                                            onPressed: () => _showLinkToPODialog(context, calc, poList, projectsList),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.list_alt, color: AppTheme.cobalt, size: 20),
                                            tooltip: 'View Items Breakdown',
                                            onPressed: () => _showCalcDetailsDialog(context, calc),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              calc.isActive ? Icons.delete_outline : Icons.restore,
                                              color: calc.isActive ? AppTheme.crimson : AppTheme.emerald,
                                              size: 20,
                                            ),
                                            tooltip: calc.isActive ? 'Deactivate' : 'Restore',
                                            onPressed: () async {
                                              if (calc.isActive) {
                                                await ref.read(cbmCalculatorProvider.notifier).deleteCalculation(calc.calcId!);
                                              } else {
                                                await ref.read(cbmCalculatorProvider.notifier).restoreCalculation(calc.calcId!);
                                              }
                                            },
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

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Save Calculation Session (حفظ الجلسة التشغيلية)'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
    );
  }

  void _showCalcDetailsDialog(BuildContext context, CBMCalculationModel calc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Calculation Session Details: ${calc.calcCode}'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(calc.title ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (calc.notes != null) Text('Notes: ${calc.notes}', style: const TextStyle(color: Colors.grey)),
                const Divider(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _buildDetailTag('Total CBM', '${calc.totalCbm.toStringAsFixed(3)} m³'),
                    _buildDetailTag('Air Chargeable Wt', '${calc.airChargeableWeightKg.toStringAsFixed(1)} kg'),
                    _buildDetailTag('Total Gross Wt', '${calc.totalGrossWeightKg.toStringAsFixed(1)} kg'),
                    _buildDetailTag('Shipping Method', calc.recommendedShippingMethod ?? '-'),
                    _buildDetailTag('Container Type', calc.recommendedContainerType ?? '-'),
                  ],
                ),
                const Divider(height: 24),
                const Text('Package Measurements Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppTheme.cloudWhite),
                      children: [
                        Padding(padding: EdgeInsets.all(6), child: Text('Package', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('L x W x H (cm)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Gross Wt/Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Line CBM', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...calc.items.map(
                      (item) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text(item.packageType)),
                          Padding(padding: const EdgeInsets.all(6), child: Text(item.quantity.toString())),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${item.lengthCm} x ${item.widthCm} x ${item.heightCm}')),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${item.grossWeightPerUnitKg} kg')),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${item.totalCbm.toStringAsFixed(3)} m³', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailTag(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
      ],
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
                DropdownButtonFormField<int?>(
                  value: selectedPoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Purchase Order (PO)'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None / Standalone')),
                    ...poList.map((po) => DropdownMenuItem<int?>(
                          value: po.poId,
                          child: Text('${po.poNumber} (${po.projectName ?? "Project"})', overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedPoId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: selectedProjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Project'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None / Unbound')),
                    ...projectsList.map((p) => DropdownMenuItem<int?>(
                          value: p.projectId,
                          child: Text('${p.projectCode} - ${p.projectName}', overflow: TextOverflow.ellipsis),
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
}
