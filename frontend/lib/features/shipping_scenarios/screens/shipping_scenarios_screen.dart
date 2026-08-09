import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../external_service_providers/models/partner_model.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/shipping_scenario_model.dart';
import '../providers/shipping_scenarios_provider.dart';

class ShippingScenariosScreen extends ConsumerStatefulWidget {
  const ShippingScenariosScreen({super.key});

  @override
  ConsumerState<ShippingScenariosScreen> createState() => _ShippingScenariosScreenState();
}

class _ShippingScenariosScreenState extends ConsumerState<ShippingScenariosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Evaluator Form State
  int? _editingSessionId;
  String? _editingSessionCode;
  String _title = '';
  DateTime _cargoReadyDate = DateTime.now().add(const Duration(days: 5));
  int? _selectedPolId;
  int? _selectedPodId;
  int _avgForm4Days = 5;
  int _avgClearanceDays = 7;
  int? _selectedImportFileId;
  int? _selectedPoId;
  int? _selectedProjectId;
  final String _sessionNotes = '';

  // Carrier Options List
  final List<ShippingScenarioItemModel> _evalItems = [];
  bool _isSaving = false;
  bool _isStackable = true;

  void _loadSessionForEditing(ShippingEvaluationModel sess) {
    setState(() {
      _editingSessionId = sess.sessionId;
      _editingSessionCode = sess.sessionCode;
      _title = sess.title ?? '';
      _cargoReadyDate = DateTime.tryParse(sess.cargoReadyDate) ?? DateTime.now();
      _selectedPolId = sess.portOfLoadingId;
      _selectedPodId = sess.portOfDischargeId;
      _avgForm4Days = sess.avgForm4Days;
      _avgClearanceDays = sess.avgClearanceDays;
      _selectedImportFileId = sess.importFileId;
      _selectedPoId = sess.poId;
      _selectedProjectId = sess.projectId;
      _evalItems.clear();
      _evalItems.addAll(sess.items);
    });
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📂 تم فتح الجلسة ${sess.sessionCode} لتعديل دراسة الشحن!'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _resetFormForNewStudy() {
    setState(() {
      _editingSessionId = null;
      _editingSessionCode = null;
      _title = '';
      _cargoReadyDate = DateTime.now().add(const Duration(days: 5));
      _selectedPolId = null;
      _selectedPodId = null;
      _avgForm4Days = 5;
      _avgClearanceDays = 7;
      _selectedImportFileId = null;
      _selectedPoId = null;
      _selectedProjectId = null;
      _initDefaultItems();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDefaultItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(shippingScenariosProvider.notifier).fetchSessions();
    ref.read(projectsProvider.notifier).fetchProjects();
    ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    ref.read(partnersProvider.notifier).fetchPartners();
    ref.read(transportLocationsProvider.notifier).fetchLocations();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
  }

  void _initDefaultItems() {
    final crd = _cargoReadyDate;
    _evalItems.clear();
    _evalItems.addAll([
      ShippingScenarioItemModel(
        providerName: 'COSCO Shipping',
        vesselName: 'COSCO UNIVERSE',
        voyageNumber: '042E',
        sailingDate: crd.add(const Duration(days: 2)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 26)).toString().substring(0, 10),
        expectedLineDelayDays: 2,
        isRecommended: true,
        riskLevel: 'Low',
        notes: 'أقرب موعد إبحار وتوافر حاويات HQ في ميناء شنغهاي',
      ),
      ShippingScenarioItemModel(
        providerName: 'Maersk Line',
        vesselName: 'MAERSK MC-KINNEY MOLLER',
        voyageNumber: '2608W',
        sailingDate: crd.add(const Duration(days: 5)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 32)).toString().substring(0, 10),
        expectedLineDelayDays: 4,
        isRecommended: false,
        riskLevel: 'Medium',
        notes: 'ترانزيت في بيرايوس مع تكلفة شحن أقل بمقدار \$300',
      ),
      ShippingScenarioItemModel(
        providerName: 'CMA CGM',
        vesselName: 'CMA CGM JACQUES SAADE',
        voyageNumber: '8819X',
        sailingDate: crd.add(const Duration(days: 12)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 48)).toString().substring(0, 10),
        expectedLineDelayDays: 7,
        isExcludedFromAverage: true,
        isRecommended: false,
        riskLevel: 'High',
        notes: 'تاريخ إبحار متأخر جداً ومخاطرة عالية بالتأخير بالميناء الوسيط - مستبعد من المتوسط',
      ),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shippingScenariosProvider);
    final projectsState = ref.watch(projectsProvider);
    final poState = ref.watch(purchaseOrdersProvider);
    final partnersState = ref.watch(partnersProvider);
    final portsState = ref.watch(transportLocationsProvider);

    final poList = poState.purchaseOrders;
    final projectsList = projectsState.value ?? [];
    final List<PartnerModel> partnersList = partnersState.value ?? [];
    final List<PartnerModel> shippingLines = partnersList.where((p) => p.partnerType.contains('Shipping Line') || p.partnerType.contains('Freight') || p.partnerType.contains('Broker') || p.partnerType.contains('Carrier')).toList();
    final portsList = portsState.value ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.directions_boat, color: Colors.white),
            SizedBox(width: 10),
            Text('Shipping Scenarios Evaluation (BP-007 تقييم سيناريوهات الشحن)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Live Refresh (تحديث حي)',
            onPressed: _refreshData,
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Shipping Scenarios Evaluator (دراسة وسيناريوهات الشحن)'),
            Tab(icon: Icon(Icons.history), text: 'Saved Evaluations Log (سجل الدراسات المحفوظة)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEvaluatorTab(poList, projectsList, shippingLines, portsList),
          _buildHistoryRegistryTab(state, poList, projectsList),
        ],
      ),
    );
  }

  Widget _buildEvaluatorTab(List poList, List projectsList, List<PartnerModel> shippingLines, List portsList) {
    // Dynamic Calculations Preview
    final crdStr = _cargoReadyDate.toString().substring(0, 10);
    final List<Map<String, dynamic>> calculatedScenarios = [];
    List<int> validTransitDays = [];

    for (int i = 0; i < _evalItems.length; i++) {
      final item = _evalItems[i];
      try {
        final sDate = DateTime.parse(item.sailingDate);
        final etaDate = DateTime.parse(item.estimatedArrivalDate);
        final crdDate = _cargoReadyDate;

        final vesselLeadTime = etaDate.difference(sDate).inDays;
        final readyDays = sDate.difference(crdDate).inDays;
        final totalDays = vesselLeadTime + readyDays + _avgForm4Days + _avgClearanceDays + item.expectedLineDelayDays;
        final expectedWhDate = crdDate.add(Duration(days: totalDays)).toString().substring(0, 10);

        final calcMap = {
          'index': i,
          'item': item,
          'vesselLeadTime': vesselLeadTime,
          'readyDays': readyDays,
          'totalDays': totalDays,
          'expectedWhDate': expectedWhDate,
        };
        calculatedScenarios.add(calcMap);

        if (!item.isExcludedFromAverage) {
          validTransitDays.add(totalDays);
        }
      } catch (_) {}
    }

    final double avgTransitDays = validTransitDays.isNotEmpty
        ? validTransitDays.reduce((a, b) => a + b) / validTransitDays.length
        : 0.0;
    final String avgWhDateStr = validTransitDays.isNotEmpty
        ? _cargoReadyDate.add(Duration(days: avgTransitDays.round())).toString().substring(0, 10)
        : '-';

    String earliestProvider = '-';
    String earliestDate = '-';
    String latestProvider = '-';
    String latestDate = '-';
    String recommendedProvider = '-';

    final includedList = calculatedScenarios.where((c) => !(c['item'] as ShippingScenarioItemModel).isExcludedFromAverage).toList();
    if (includedList.isNotEmpty) {
      includedList.sort((a, b) => (a['totalDays'] as int).compareTo(b['totalDays'] as int));
      earliestProvider = (includedList.first['item'] as ShippingScenarioItemModel).providerName;
      earliestDate = includedList.first['expectedWhDate'];

      latestProvider = (includedList.last['item'] as ShippingScenarioItemModel).providerName;
      latestDate = includedList.last['expectedWhDate'];

      final rec = calculatedScenarios.firstWhere(
        (c) => (c['item'] as ShippingScenarioItemModel).isRecommended,
        orElse: () => includedList.first,
      );
      recommendedProvider = '${(rec['item'] as ShippingScenarioItemModel).providerName} (${(rec['item'] as ShippingScenarioItemModel).vesselName})';
    }

    double totalCargoCbm = 0.0;
    double totalCargoWeightKg = 0.0;
    int linkedPoCount = 0;
    int linkedPlCount = 0;
    bool hasNonStackableItems = false;
    bool hasExplicitPackingList = false;

    if (_selectedImportFileId != null) {
      final matchingPOs = poList.where((p) => (p as PurchaseOrderModel).importFileId == _selectedImportFileId).cast<PurchaseOrderModel>().toList();
      linkedPoCount = matchingPOs.length;
      for (var po in matchingPOs) {
        if (po.packingListItems.isNotEmpty) {
          hasExplicitPackingList = true;
          linkedPlCount += po.packingListItems.length;
          for (var pl in po.packingListItems) {
            totalCargoCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
            totalCargoWeightKg += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
            if (!pl.isStackable) {
              hasNonStackableItems = true;
            }
          }
        } else {
          totalCargoCbm += po.totalCbm;
          totalCargoWeightKg += po.totalGrossWeightKg;
        }
      }
    } else if (_selectedPoId != null) {
      final po = poList.firstWhere((p) => (p as PurchaseOrderModel).poId == _selectedPoId, orElse: () => null) as PurchaseOrderModel?;
      if (po != null) {
        linkedPoCount = 1;
        if (po.packingListItems.isNotEmpty) {
          hasExplicitPackingList = true;
          linkedPlCount = po.packingListItems.length;
          for (var pl in po.packingListItems) {
            totalCargoCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
            totalCargoWeightKg += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
            if (!pl.isStackable) {
              hasNonStackableItems = true;
            }
          }
        } else {
          totalCargoCbm += po.totalCbm;
          totalCargoWeightKg += po.totalGrossWeightKg;
        }
      }
    }

    final dualRec = ContainerRequirementEngine.calculateBoth(totalCbm: totalCargoCbm, totalWeightKg: totalCargoWeightKg);
    final containerRec = _isStackable ? dualRec.stackableResult : dualRec.nonStackableResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.charcoal, AppTheme.cobalt]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingSessionId != null
                              ? 'Editing Shipping Study ($_editingSessionCode)'
                              : 'Shipping Scenarios & Transit Lead Time Evaluation (BP-007)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text('مقارنة خيارات الشحن والخطوط الملاحية وتوقع تاريخ وصول الشحنة للمخزن قبل تأكيد الحجز', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_editingSessionId != null) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('دراسة جديدة'),
                      onPressed: _resetFormForNewStudy,
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 18),
                    label: Text(_editingSessionId != null ? 'حفظ التعديلات' : 'حفظ الدراسة والنتائج', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : () => _saveEvaluationSession(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Metrics Badges Row
            Row(
              children: [
                Expanded(child: _buildMetricCard('متوسط مدة الترانزيت للمخزن', '${avgTransitDays.toStringAsFixed(1)} يوم', Icons.timer, AppTheme.cobalt)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('متوسط تاريخ الوصول المتوقع', avgWhDateStr, Icons.event_available, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('أقرب تاريخ وصول متوقع', earliestDate, Icons.flight_land, AppTheme.emerald, subtitle: earliestProvider)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('أبعد تاريخ وصول متوقع', latestDate, Icons.history_toggle_off, Colors.orange, subtitle: latestProvider)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('الرحلة/الخط الموصى به', recommendedProvider, Icons.thumb_up, Colors.blue)),
              ],
            ),
            const SizedBox(height: 20),

            // Shipment Parameters Card (Responsive & Overflow Free Layout)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📌 Shipment & Logistics Parameters (بيانات الشحنة والزمن الإداري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                              icon: const Icon(Icons.print, size: 14),
                              label: const Text('طباعة الدراسة (Print)'),
                              onPressed: () {
                                final currentSession = ShippingEvaluationModel(
                                  sessionCode: _editingSessionCode ?? 'DRAFT-STUDY',
                                  title: _title,
                                  cargoReadyDate: crdStr,
                                  portOfLoadingId: _selectedPolId,
                                  portOfDischargeId: _selectedPodId,
                                  avgForm4Days: _avgForm4Days,
                                  avgClearanceDays: _avgClearanceDays,
                                  importFileId: _selectedImportFileId,
                                  poId: _selectedPoId,
                                  projectId: _selectedProjectId,
                                  items: _evalItems,
                                  avgExpectedTransitDays: avgTransitDays,
                                  avgExpectedWarehouseArrivalDate: avgWhDateStr,
                                  earliestArrivalDate: earliestDate,
                                  earliestArrivalScenarioProvider: earliestProvider,
                                  latestArrivalDate: latestDate,
                                  latestArrivalScenarioProvider: latestProvider,
                                  recommendedScenarioProvider: recommendedProvider,
                                );
                                _showPrintReportDialog(context, currentSession);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Parameters Row 1
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: _title,
                            decoration: const InputDecoration(labelText: 'Study Title / Reference *', hintText: 'مثال: دراسة مقارنة خيارات شحن محولات الإسماعيلية', isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            onChanged: (v) => _title = v.trim(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _cargoReadyDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _cargoReadyDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Cargo Ready Date (CRD) *', isDense: true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(crdStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
                                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.cobalt),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int?>(
                            value: _selectedImportFileId,
                            decoration: const InputDecoration(labelText: 'Import File (ملف الشحنة)', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None / Standalone')),
                              ...(ref.watch(importFilesProvider).value ?? []).map((f) => DropdownMenuItem<int?>(
                                    value: f.importFileId,
                                    child: Text('[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedImportFileId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Parameters Row 2 (POL & POD)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedPolId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Port of Loading (POL)', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Select POL')),
                              ...portsList.map((p) => DropdownMenuItem<int?>(
                                    value: p.locationId,
                                    child: Text('${p.unLocode} - ${p.locationName}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedPolId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedPodId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Port of Discharge (POD)', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Select POD')),
                              ...portsList.map((p) => DropdownMenuItem<int?>(
                                    value: p.locationId,
                                    child: Text('${p.unLocode} - ${p.locationName}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedPodId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Parameters Row 3 (PO Link & Project Link)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedPoId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Link Purchase Order (PO)', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None / Standalone')),
                              ...poList.map((po) => DropdownMenuItem<int?>(
                                    value: po.poId,
                                    child: Text('${po.poNumber} (${po.supplierName ?? "Supplier"})', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedPoId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedProjectId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Link Project', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None / Unbound')),
                              ...projectsList.map((p) => DropdownMenuItem<int?>(
                                    value: p.projectId,
                                    child: Text('${p.projectCode} - ${p.projectName}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedProjectId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Parameters Row 3 (Form 4 & Clearance Days)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _avgForm4Days.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Avg Form 4 Days (أيام نموذج 4)', suffixText: 'أيام', isDense: true),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'Valid number required' : null,
                            onChanged: (v) => setState(() => _avgForm4Days = int.tryParse(v) ?? 5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _avgClearanceDays.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Avg Clearance Days (أيام التخليص)', suffixText: 'أيام', isDense: true),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'Valid number required' : null,
                            onChanged: (v) => setState(() => _avgClearanceDays = int.tryParse(v) ?? 7),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImportFileId != null || _selectedPoId != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 34),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '📦 إجمالي حمولة الملف المجمعة من قوائم التعبئة: ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                      ),
                                      Text(
                                        '${totalCargoCbm.toStringAsFixed(3)} m³ | ${totalCargoWeightKg.toStringAsFixed(0)} kg ($linkedPoCount أمر شراء | $linkedPlCount بند تعبئة)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  if (hasExplicitPackingList) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: hasNonStackableItems ? Colors.orange.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: hasNonStackableItems ? Colors.orange.shade300 : Colors.green.shade300),
                                      ),
                                      child: Text(
                                        hasNonStackableItems
                                            ? '⚠️ تعليمات قائمة التعبئة: تتضمن الشحنة طرود غير قابلة للرص (Non-Stackable Items Detected)'
                                            : '✅ تعليمات قائمة التعبئة: جميع الطرود قابلة للرص (All Items Stackable)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: hasNonStackableItems ? Colors.orange.shade900 : Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('🚚 نوع التحميل والتخزين (Cargo Stacking): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('📦 قابل للرص (Stackable)'),
                                        selected: _isStackable,
                                        selectedColor: AppTheme.cobalt,
                                        labelStyle: TextStyle(color: _isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                        onSelected: (val) => setState(() => _isStackable = true),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('🚫 غير قابل للرص (Non-Stackable)'),
                                        selected: !_isStackable,
                                        selectedColor: Colors.orange.shade800,
                                        labelStyle: TextStyle(color: !_isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                        onSelected: (val) => setState(() => _isStackable = false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      const Text('🚚 اقتراح الحاوية التلقائي (MD-019.1 Engine): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (_isStackable ? AppTheme.emerald : Colors.orange.shade800).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: _isStackable ? AppTheme.emerald : Colors.orange.shade800),
                                        ),
                                        child: Text(
                                          containerRec.recommendationSummary,
                                          style: TextStyle(fontWeight: FontWeight.bold, color: _isStackable ? AppTheme.emerald : Colors.orange.shade900, fontSize: 12),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade400)),
                                        child: Text(
                                          _isStackable
                                              ? 'بديل غير قابل للرص: ${dualRec.nonStackableResult.requiredContainersCount}x ${dualRec.nonStackableResult.recommendedContainerCode}'
                                              : 'بديل قابل للرص: ${dualRec.stackableResult.requiredContainersCount}x ${dualRec.stackableResult.recommendedContainerCode}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 11),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: const BorderSide(color: AppTheme.cobalt),
                                        ),
                                        icon: const Icon(Icons.table_chart, size: 14, color: AppTheme.cobalt),
                                        label: const Text('مقارنة الحالتين (Matrix)', style: TextStyle(fontSize: 11, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showContainerComparisonDialog(context, dualRec, totalCargoCbm, totalCargoWeightKg),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Carrier Options Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🚢 Shipping Carrier Options & Voyages (خيارات ورحلات شركات الشحن)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة خيار شحن جديد'),
                  onPressed: () {
                    setState(() {
                      final crd = _cargoReadyDate;
                      _evalItems.add(ShippingScenarioItemModel(
                        providerName: 'Shipping Line ${_evalItems.length + 1}',
                        vesselName: 'VESSEL NEW',
                        sailingDate: crd.add(const Duration(days: 3)).toString().substring(0, 10),
                        estimatedArrivalDate: crd.add(const Duration(days: 28)).toString().substring(0, 10),
                        expectedLineDelayDays: 2,
                      ));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Carrier Option Cards List
            ..._evalItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final calc = calculatedScenarios.firstWhere((c) => c['index'] == idx, orElse: () => {});

              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: item.isRecommended ? AppTheme.emerald : item.isExcludedFromAverage ? Colors.grey.shade400 : Colors.blue.shade200, width: item.isRecommended ? 2 : 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: item.isRecommended ? AppTheme.emerald : AppTheme.cobalt,
                            child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: item.providerId,
                              decoration: const InputDecoration(labelText: 'شركة الشحن / الناقل (Partners)', isDense: true),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('ادخال يدوياً / Custom')),
                                ...shippingLines.map((p) => DropdownMenuItem<int?>(
                                      value: p.providerId,
                                      child: Text(p.partnerName, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: (val) {
                                final partner = shippingLines.where((p) => p.providerId == val).firstOrNull;
                                setState(() {
                                  _evalItems[idx] = ShippingScenarioItemModel(
                                    itemId: item.itemId,
                                    providerId: val,
                                    providerName: partner != null ? partner.partnerName : item.providerName,
                                    vesselName: item.vesselName,
                                    voyageNumber: item.voyageNumber,
                                    sailingDate: item.sailingDate,
                                    estimatedArrivalDate: item.estimatedArrivalDate,
                                    expectedLineDelayDays: item.expectedLineDelayDays,
                                    isExcludedFromAverage: item.isExcludedFromAverage,
                                    isRecommended: item.isRecommended,
                                    riskLevel: item.riskLevel,
                                    notes: item.notes,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: ValueKey('prov_${idx}_${item.providerName}'),
                              initialValue: item.providerName,
                              decoration: const InputDecoration(labelText: 'Shipping Provider Name *', isDense: true),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              onChanged: (v) => _evalItems[idx] = ShippingScenarioItemModel(
                                itemId: item.itemId,
                                providerId: item.providerId,
                                providerName: v.trim(),
                                vesselName: item.vesselName,
                                voyageNumber: item.voyageNumber,
                                sailingDate: item.sailingDate,
                                estimatedArrivalDate: item.estimatedArrivalDate,
                                expectedLineDelayDays: item.expectedLineDelayDays,
                                isExcludedFromAverage: item.isExcludedFromAverage,
                                isRecommended: item.isRecommended,
                                riskLevel: item.riskLevel,
                                notes: item.notes,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.vesselName,
                              decoration: const InputDecoration(labelText: 'Vessel Name *', isDense: true),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              onChanged: (v) => _evalItems[idx] = ShippingScenarioItemModel(
                                providerName: item.providerName,
                                vesselName: v.trim(),
                                voyageNumber: item.voyageNumber,
                                sailingDate: item.sailingDate,
                                estimatedArrivalDate: item.estimatedArrivalDate,
                                expectedLineDelayDays: item.expectedLineDelayDays,
                                isExcludedFromAverage: item.isExcludedFromAverage,
                                isRecommended: item.isRecommended,
                                riskLevel: item.riskLevel,
                                notes: item.notes,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.voyageNumber ?? '',
                              decoration: const InputDecoration(labelText: 'Voyage #', isDense: true),
                              onChanged: (v) => _evalItems[idx] = ShippingScenarioItemModel(
                                providerName: item.providerName,
                                vesselName: item.vesselName,
                                voyageNumber: v.trim(),
                                sailingDate: item.sailingDate,
                                estimatedArrivalDate: item.estimatedArrivalDate,
                                expectedLineDelayDays: item.expectedLineDelayDays,
                                isExcludedFromAverage: item.isExcludedFromAverage,
                                isRecommended: item.isRecommended,
                                riskLevel: item.riskLevel,
                                notes: item.notes,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
                            onPressed: _evalItems.length <= 1
                                ? null
                                : () {
                                    setState(() {
                                      _evalItems.removeAt(idx);
                                    });
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final sDate = DateTime.tryParse(item.sailingDate) ?? DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: sDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _evalItems[idx] = ShippingScenarioItemModel(
                                      providerName: item.providerName,
                                      vesselName: item.vesselName,
                                      voyageNumber: item.voyageNumber,
                                      sailingDate: picked.toString().substring(0, 10),
                                      estimatedArrivalDate: item.estimatedArrivalDate,
                                      expectedLineDelayDays: item.expectedLineDelayDays,
                                      isExcludedFromAverage: item.isExcludedFromAverage,
                                      isRecommended: item.isRecommended,
                                      riskLevel: item.riskLevel,
                                      notes: item.notes,
                                    );
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Sailing Date *', isDense: true),
                                child: Text(item.sailingDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final etaDate = DateTime.tryParse(item.estimatedArrivalDate) ?? DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: etaDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _evalItems[idx] = ShippingScenarioItemModel(
                                      providerName: item.providerName,
                                      vesselName: item.vesselName,
                                      voyageNumber: item.voyageNumber,
                                      sailingDate: item.sailingDate,
                                      estimatedArrivalDate: picked.toString().substring(0, 10),
                                      expectedLineDelayDays: item.expectedLineDelayDays,
                                      isExcludedFromAverage: item.isExcludedFromAverage,
                                      isRecommended: item.isRecommended,
                                      riskLevel: item.riskLevel,
                                      notes: item.notes,
                                    );
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Estimated Arrival (ETA) *', isDense: true),
                                child: Text(item.estimatedArrivalDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.expectedLineDelayDays.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Expected Delay (Days)', isDense: true),
                              onChanged: (v) {
                                final delay = int.tryParse(v) ?? 0;
                                setState(() {
                                  _evalItems[idx] = ShippingScenarioItemModel(
                                    providerName: item.providerName,
                                    vesselName: item.vesselName,
                                    voyageNumber: item.voyageNumber,
                                    sailingDate: item.sailingDate,
                                    estimatedArrivalDate: item.estimatedArrivalDate,
                                    expectedLineDelayDays: delay,
                                    isExcludedFromAverage: item.isExcludedFromAverage,
                                    isRecommended: item.isRecommended,
                                    riskLevel: item.riskLevel,
                                    notes: item.notes,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: item.riskLevel,
                              decoration: const InputDecoration(labelText: 'Risk Level', isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'Low', child: Text('Low Risk 🟢')),
                                DropdownMenuItem(value: 'Medium', child: Text('Medium Risk 🟠')),
                                DropdownMenuItem(value: 'High', child: Text('High Risk 🔴')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _evalItems[idx] = ShippingScenarioItemModel(
                                      providerName: item.providerName,
                                      vesselName: item.vesselName,
                                      voyageNumber: item.voyageNumber,
                                      sailingDate: item.sailingDate,
                                      estimatedArrivalDate: item.estimatedArrivalDate,
                                      expectedLineDelayDays: item.expectedLineDelayDays,
                                      isExcludedFromAverage: item.isExcludedFromAverage,
                                      isRecommended: item.isRecommended,
                                      riskLevel: v,
                                      notes: item.notes,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilterChip(
                            label: Text(item.isExcludedFromAverage ? 'Excluded from Avg 🚫' : 'Include in Avg ✅', style: TextStyle(fontSize: 11, color: item.isExcludedFromAverage ? Colors.red.shade800 : AppTheme.cobalt)),
                            selected: item.isExcludedFromAverage,
                            onSelected: (val) {
                              setState(() {
                                _evalItems[idx] = ShippingScenarioItemModel(
                                  providerName: item.providerName,
                                  vesselName: item.vesselName,
                                  voyageNumber: item.voyageNumber,
                                  sailingDate: item.sailingDate,
                                  estimatedArrivalDate: item.estimatedArrivalDate,
                                  expectedLineDelayDays: item.expectedLineDelayDays,
                                  isExcludedFromAverage: val,
                                  isRecommended: item.isRecommended,
                                  riskLevel: item.riskLevel,
                                  notes: item.notes,
                                );
                              });
                            },
                          ),
                        ],
                      ),

                      // Live Calculation Badge Bar
                      if (calc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Vessel Lead Time: ${calc["vesselLeadTime"]} days | Ready Days: ${calc["readyDays"]} days | Total WH Days: ${calc["totalDays"]} days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              Text('🎯 Expected Warehouse Arrival: ${calc["expectedWhDate"]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Comparison Summary Table
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 Side-by-Side Shipping Scenarios Comparison Matrix (جدول المقارنة التفصيلي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Carrier Provider')),
                          DataColumn(label: Text('Vessel / Voyage')),
                          DataColumn(label: Text('Sailing Date')),
                          DataColumn(label: Text('ETA Port')),
                          DataColumn(label: Text('Vessel Lead Time')),
                          DataColumn(label: Text('Form 4 + Clearance')),
                          DataColumn(label: Text('Delay Days')),
                          DataColumn(label: Text('Total WH Days')),
                          DataColumn(label: Text('Expected WH Arrival')),
                          DataColumn(label: Text('Risk Level')),
                          DataColumn(label: Text('Avg Status')),
                        ],
                        rows: calculatedScenarios.map((c) {
                          final idx = c['index'] as int;
                          final item = c['item'] as ShippingScenarioItemModel;
                          return DataRow(
                            cells: [
                              DataCell(Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(item.providerName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                              DataCell(Text('${item.vesselName} (${item.voyageNumber ?? "-"})')),
                              DataCell(Text(item.sailingDate)),
                              DataCell(Text(item.estimatedArrivalDate)),
                              DataCell(Text('${c["vesselLeadTime"]} days')),
                              DataCell(Text('${_avgForm4Days + _avgClearanceDays} days')),
                              DataCell(Text('${item.expectedLineDelayDays} days')),
                              DataCell(Text('${c["totalDays"]} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                              DataCell(Text('${c["expectedWhDate"]}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.riskLevel == 'High' ? Colors.red.shade100 : item.riskLevel == 'Medium' ? Colors.orange.shade100 : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(item.riskLevel, style: TextStyle(color: item.riskLevel == 'High' ? Colors.red.shade900 : item.riskLevel == 'Medium' ? Colors.orange.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                              DataCell(Text(item.isExcludedFromAverage ? 'Excluded 🚫' : 'Included ✅', style: TextStyle(color: item.isExcludedFromAverage ? Colors.red : AppTheme.cobalt, fontSize: 11))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Study Code, Title, or Notes',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(shippingScenariosProvider.notifier).setSearchQuery(v.trim()),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Show Inactive'),
                selected: state.showInactive,
                onSelected: (val) => ref.read(shippingScenariosProvider.notifier).toggleShowInactive(val),
              ),
            ],
          ),
        ),

        // Data Table View
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.sessions.isEmpty
                  ? const Center(child: Text('No shipping evaluation studies found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            columns: const [
                              DataColumn(label: Text('Study Code')),
                              DataColumn(label: Text('Import File')),
                              DataColumn(label: Text('Title / Description')),
                              DataColumn(label: Text('CRD Date')),
                              DataColumn(label: Text('Avg Transit')),
                              DataColumn(label: Text('Avg WH Arrival')),
                              DataColumn(label: Text('Recommended Carrier')),
                              DataColumn(label: Text('Options Count')),
                              DataColumn(label: Text('Linked PO / Project')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: state.sessions.map((sess) {
                              return DataRow(
                                onSelectChanged: (_) => _showSessionDetailsDialog(context, sess),
                                cells: [
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showSessionDetailsDialog(context, sess),
                                      child: Text(sess.sessionCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, decoration: TextDecoration.underline)),
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
                                        sess.importFileCode ?? (sess.importFileId != null ? 'IMP-${sess.importFileId}' : '-'),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(sess.title ?? 'Shipping Transit Study', overflow: TextOverflow.ellipsis)),
                                  DataCell(Text(sess.cargoReadyDate)),
                                  DataCell(Text('${sess.avgExpectedTransitDays.toStringAsFixed(1)} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                  DataCell(Text(sess.avgExpectedWarehouseArrivalDate ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Text(sess.recommendedScenarioProvider ?? '-', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  DataCell(Text('${sess.items.length} options')),
                                  DataCell(Text(sess.poNumber != null ? 'PO: ${sess.poNumber}' : sess.projectName != null ? 'PRJ: ${sess.projectName}' : 'Standalone', style: TextStyle(color: sess.poNumber != null ? AppTheme.emerald : Colors.grey, fontSize: 11))),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          _loadSessionForEditing(sess);
                                        } else if (val == 'view') {
                                          _showSessionDetailsDialog(context, sess);
                                        } else if (val == 'print') {
                                          _showPrintReportDialog(context, sess);
                                        } else if (val == 'delete_restore') {
                                          if (sess.isActive) {
                                            await ref.read(shippingScenariosProvider.notifier).deleteSession(sess.sessionId!);
                                          } else {
                                            await ref.read(shippingScenariosProvider.notifier).restoreSession(sess.sessionId!);
                                          }
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit / Re-open Session (فتح وتعديل الجلسة)')),
                                        const PopupMenuItem(value: 'view', child: Text('View Details (عرض التفاصيل)')),
                                        const PopupMenuItem(value: 'print', child: Text('Print / Export Report (طباعة وتصدير)')),
                                        PopupMenuItem(value: 'delete_restore', child: Text(sess.isActive ? 'Deactivate' : 'Restore')),
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
      ],
    );
  }

  Future<void> _saveEvaluationSession(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى التأكد من استكمال كافة البيانات الإلزامية مثل عنوان الدراسة!'),
          backgroundColor: AppTheme.crimson,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    final titleToSave = _title.trim().isNotEmpty
        ? _title.trim()
        : 'دراسة تقييم خيارات الشحن (${DateTime.now().toString().substring(0, 10)})';

    setState(() => _isSaving = true);

    bool ok = false;
    if (_editingSessionId != null) {
      final data = {
        'title': titleToSave,
        'cargo_ready_date': _cargoReadyDate.toString().substring(0, 10),
        if (_selectedPolId != null) 'port_of_loading_id': _selectedPolId,
        if (_selectedPodId != null) 'port_of_discharge_id': _selectedPodId,
        'avg_form4_days': _avgForm4Days,
        'avg_clearance_days': _avgClearanceDays,
        if (_selectedImportFileId != null) 'import_file_id': _selectedImportFileId,
        if (_selectedPoId != null) 'po_id': _selectedPoId,
        if (_selectedProjectId != null) 'project_id': _selectedProjectId,
        'items': _evalItems.map((i) => i.toCreateJson()).toList(),
      };
      ok = await ref.read(shippingScenariosProvider.notifier).updateSession(_editingSessionId!, data);
    } else {
      final session = ShippingEvaluationModel(
        sessionCode: '',
        title: titleToSave,
        cargoReadyDate: _cargoReadyDate.toString().substring(0, 10),
        portOfLoadingId: _selectedPolId,
        portOfDischargeId: _selectedPodId,
        avgForm4Days: _avgForm4Days,
        avgClearanceDays: _avgClearanceDays,
        importFileId: _selectedImportFileId,
        poId: _selectedPoId,
        projectId: _selectedProjectId,
        notes: _sessionNotes,
        items: _evalItems,
      );
      ok = await ref.read(shippingScenariosProvider.notifier).createSession(session);
    }

    setState(() => _isSaving = false);

    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingSessionId != null ? '✅ تم حفظ تعديلات الجلسة $_editingSessionCode بنجاح!' : '✅ تم حفظ دراسة خيارات وسيناريوهات الشحن بنجاح!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
      _resetFormForNewStudy();
      _tabController.animateTo(1);
    } else if (!ok && context.mounted) {
      final err = ref.read(shippingScenariosProvider).errorMessage ?? 'فشلت عملية حفظ الدراسة والنتائج';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $err'),
          backgroundColor: AppTheme.crimson,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSessionDetailsDialog(BuildContext context, ShippingEvaluationModel sess) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Shipping Transit Study Details (${sess.sessionCode})'),
        content: SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sess.title ?? 'Shipping Study', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('CRD Date: ${sess.cargoReadyDate} | Form 4: ${sess.avgForm4Days}d | Clearance: ${sess.avgClearanceDays}d', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 20),

                // Metrics Badges
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard('Average Transit Days', '${sess.avgExpectedTransitDays.toStringAsFixed(1)} days', Icons.timer, AppTheme.cobalt),
                    _buildMetricCard('Average WH Arrival', sess.avgExpectedWarehouseArrivalDate ?? '-', Icons.event, Colors.purple),
                    _buildMetricCard('Earliest Arrival', sess.earliestArrivalDate ?? '-', Icons.flight_land, AppTheme.emerald, subtitle: sess.earliestArrivalScenarioProvider),
                    _buildMetricCard('Latest Arrival', sess.latestArrivalDate ?? '-', Icons.history_toggle_off, Colors.orange, subtitle: sess.latestArrivalScenarioProvider),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Options Breakdown Table', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppTheme.cloudWhite),
                      children: [
                        Padding(padding: EdgeInsets.all(6), child: Text('Carrier Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Vessel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Sailing Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('ETA Port', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Lead Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Total WH Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Expected WH Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...sess.items.map(
                      (i) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text(i.providerName, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${i.vesselName} (${i.voyageNumber ?? ""})', style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(i.sailingDate, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(i.estimatedArrivalDate, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${i.vesselLeadTimeDays}d', style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${i.expectedTotalDaysToWarehouse}d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(i.expectedWarehouseArrivalDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald))),
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
          OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('تعديل / فتح الجلسة'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _loadSessionForEditing(sess);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('طباعة / تصدير التقرير'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showPrintReportDialog(context, sess);
            },
          ),
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrintReportDialog(BuildContext context, ShippingEvaluationModel sess) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Print Shipping Evaluation Report (${sess.sessionCode})'),
        content: SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ImportFlow ERP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
                        Text('Shipping Scenarios Evaluation Report (BP-007)', style: TextStyle(color: AppTheme.cobalt, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(sess.sessionCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                  ],
                ),
                const Divider(height: 20),
                Text('Study Title: ${sess.title ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('CRD Date: ${sess.cargoReadyDate} | Form 4 Days: ${sess.avgForm4Days} | Clearance Days: ${sess.avgClearanceDays}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Avg Transit: ${sess.avgExpectedTransitDays.toStringAsFixed(1)} days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      Text('Avg WH Date: ${sess.avgExpectedWarehouseArrivalDate ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                      Text('Earliest Arrival: ${sess.earliestArrivalDate ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('تنزيل ملف CSV'),
            onPressed: () {
              final buffer = StringBuffer();
              buffer.writeln('ImportFlow ERP - Shipping Scenarios Evaluation Report');
              buffer.writeln('Study Code,${sess.sessionCode}');
              buffer.writeln('Title,${sess.title ?? ""}');
              buffer.writeln('Cargo Ready Date,${sess.cargoReadyDate}');
              buffer.writeln('Avg Expected Transit Days,${sess.avgExpectedTransitDays}');
              buffer.writeln('Avg Expected Warehouse Date,${sess.avgExpectedWarehouseArrivalDate ?? ""}');
              buffer.writeln('');
              buffer.writeln('Carrier Provider,Vessel,Voyage,Sailing Date,ETA Port,Vessel Lead Time,Total WH Days,Expected WH Date,Risk Level,Excluded');

              for (final i in sess.items) {
                buffer.writeln('${i.providerName},${i.vesselName},${i.voyageNumber ?? ""},${i.sailingDate},${i.estimatedArrivalDate},${i.vesselLeadTimeDays},${i.expectedTotalDaysToWarehouse},${i.expectedWarehouseArrivalDate},${i.riskLevel},${i.isExcludedFromAverage}');
              }

              Clipboard.setData(ClipboardData(text: buffer.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم نسخ وتنزيل تقرير الدراسة ${sess.sessionCode} بصيغة CSV بنجاح!'), backgroundColor: AppTheme.emerald),
              );
            },
          ),
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
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
                      const Text('تحليل خيارات ومواصفات الحاويات (MD-019.1 Engine Matrix)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

