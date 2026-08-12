import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';

import '../../external_service_providers/models/partner_model.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/shipping_scenario_model.dart';
import '../providers/shipping_scenarios_provider.dart';
import '../../currencies/models/currency_model.dart';
import '../../currencies/providers/currencies_provider.dart';

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
  String _pickUpAddress = '';
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

  // Track expanded quotes in UI
  final Map<int, bool> _expandedQuotes = {};

  void _loadSessionForEditing(ShippingEvaluationModel sess) {
    setState(() {
      _editingSessionId = sess.sessionId;
      _editingSessionCode = sess.sessionCode;
      _title = sess.title ?? '';
      _cargoReadyDate = DateTime.tryParse(sess.cargoReadyDate) ?? DateTime.now();
      _pickUpAddress = sess.pickUpAddress ?? '';
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
        content: Text('📂 تم استدعاء الجلسة ${sess.sessionCode} لإعادة الدراسة والتعديل!'),
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
      _pickUpAddress = '';
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
    ref.read(allPartnersProvider.notifier).fetchPartners();
    ref.read(transportLocationsProvider.notifier).fetchLocations();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(currenciesProvider.notifier).fetchCurrencies();
  }

  void _initDefaultItems() {
    final crd = _cargoReadyDate;
    _evalItems.clear();
    _evalItems.addAll([
      ShippingScenarioItemModel(
        providerName: 'COSCO Shipping',
        vesselName: 'COSCO UNIVERSE',
        voyageNumber: '042E',
        polName: 'Shanghai Port (ميناء شانغهاي)',
        podName: 'El Dekheila Port (ميناء الدخيلة)',
        sailingDate: crd.add(const Duration(days: 2)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 26)).toString().substring(0, 10),
        expectedLineDelayDays: 2,
        isRecommended: true,
        riskLevel: 'Low',
        notes: 'أقرب موعد إبحار وتوافر حاويات HQ في ميناء شانغهاي',
      ),
      ShippingScenarioItemModel(
        providerName: 'Maersk Line',
        vesselName: 'MAERSK MC-KINNEY MOLLER',
        voyageNumber: '2608W',
        polName: 'Ningbo-Zhoushan Port (ميناء نينغبو)',
        podName: 'Damietta Port (ميناء دمياط)',
        sailingDate: crd.add(const Duration(days: 5)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 32)).toString().substring(0, 10),
        expectedLineDelayDays: 4,
        isRecommended: false,
        riskLevel: 'Medium',
        notes: r'ترانزيت في بيرايوس مع تكلفة شحن أقل بمقدار $300',
      ),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double _calculateTotalQuoteValue(ShippingScenarioItemModel item, List<CurrencyModel> currencies) {
    double total = 0.0;
    final targetCurrency = item.quotationCurrency;
    
    double targetRate = 1.0;
    final mainCurr = currencies.where((c) => c.currencyCode == targetCurrency).firstOrNull;
    if (mainCurr != null) {
      targetRate = mainCurr.latestCommercialRate ?? 1.0;
    }

    double convert(double amount, String sourceCurrency) {
      if (sourceCurrency == targetCurrency) return amount;
      double sourceRate = 1.0;
      final srcCurr = currencies.where((c) => c.currencyCode == sourceCurrency).firstOrNull;
      if (srcCurr != null) {
        sourceRate = srcCurr.latestCommercialRate ?? 1.0;
      }
      return amount * (sourceRate / targetRate);
    }

    if (item.container40ftApplicable) {
      total += convert(item.container40ftPrice * item.container40ftQty, item.container40ftCurrency);
    }
    if (item.container20ftApplicable) {
      total += convert(item.container20ftPrice * item.container20ftQty, item.container20ftCurrency);
    }
    if (item.lclCbmApplicable) {
      total += convert(item.lclCbmPrice * item.lclCbmQty, item.lclCbmCurrency);
    }
    if (item.expressCourierApplicable) {
      total += convert(item.expressCourierPrice, item.expressCourierCurrency);
    }
    if (item.eurAtrApplicable) {
      total += convert(item.eurAtrPrice, item.eurAtrCurrency);
    }
    if (item.solasVgmApplicable) {
      total += convert(item.solasVgmPrice, item.solasVgmCurrency);
    }
    if (item.vgmNotificationApplicable) {
      // Sum container counts only if container type is applicable to fix calculation bugs
      final totalQty = (item.container40ftApplicable ? item.container40ftQty : 0) + 
                       (item.container20ftApplicable ? item.container20ftQty : 0);
      total += convert(item.vgmNotificationPrice * totalQty, item.vgmNotificationCurrency);
    }
    if (item.telexReleaseApplicable) {
      total += convert(item.telexReleasePrice, item.telexReleaseCurrency);
    }
    if (item.insuranceApplicable) {
      total += convert(item.insurancePrice, item.insuranceCurrency);
    }
    if (item.bookingCancellationApplicable) {
      total += convert(item.bookingCancellationPrice, item.bookingCancellationCurrency);
    }

    // 4 New fee columns
    if (item.ics2FilingFeeApplicable) {
      total += convert(item.ics2FilingFeePrice, item.ics2FilingFeeCurrency);
    }
    if (item.othersFeeApplicable) {
      total += convert(item.othersFeePrice, item.othersFeeCurrency);
    }
    if (item.documentFeesApplicable) {
      total += convert(item.documentFeesPrice, item.documentFeesCurrency);
    }
    if (item.waiverLetterFeeApplicable) {
      total += convert(item.waiverLetterFeePrice, item.waiverLetterFeeCurrency);
    }

    return total;
  }

  void _updateItem(int idx, ShippingScenarioItemModel updatedItem, List<CurrencyModel> currencies) {
    final rawTotal = _calculateTotalQuoteValue(updatedItem, currencies);
    final totalAmount = rawTotal.roundToDouble(); // Round to integer values to prevent decimals
    setState(() {
      _evalItems[idx] = updatedItem.copyWith(totalQuotationAmount: totalAmount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shippingScenariosProvider);
    final projectsState = ref.watch(projectsProvider);
    final poState = ref.watch(purchaseOrdersProvider);
    final partnersState = ref.watch(allPartnersProvider);
    final portsState = ref.watch(transportLocationsProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    final poList = poState.purchaseOrders;
    final projectsList = projectsState.value ?? [];
    final List<PartnerModel> partnersList = partnersState.value ?? [];
    final List<CurrencyModel> currenciesList = currenciesAsync.value ?? [];

    final List<PartnerModel> freightForwarders = partnersList.where((p) => p.partnerType.contains('Freight Forwarder')).toList();
    final List<PartnerModel> shippingLines = partnersList.where((p) => p.partnerType.contains('Shipping Line')).toList();
    final List<PartnerModel> customsBrokers = partnersList.where((p) => p.partnerType.contains('Customs Broker')).toList();
    final portsList = portsState.value ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.directions_boat, color: Colors.white),
            SizedBox(width: 10),
            Text('Shipping Scenarios & Quotes Evaluation (BP-007/8 سيناريو وعروض الشحن)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
          _buildEvaluatorTab(state, poList, projectsList, freightForwarders, shippingLines, customsBrokers, portsList, currenciesList),
          _buildHistoryRegistryTab(state, poList, projectsList),
        ],
      ),
    );
  }

  Widget _buildEvaluatorTab(
    ShippingScenariosState state,
    List<PurchaseOrderModel> poList,
    List projectsList,
    List<PartnerModel> freightForwarders,
    List<PartnerModel> shippingLines,
    List<PartnerModel> customsBrokers,
    List portsList,
    List<CurrencyModel> currenciesList,
  ) {
    final crd = _cargoReadyDate;

    // Calculate Scenario lead times
    final calculatedScenarios = _evalItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;

      final sDate = DateTime.tryParse(item.sailingDate) ?? crd;
      final etaDate = DateTime.tryParse(item.estimatedArrivalDate) ?? sDate.add(const Duration(days: 20));

      final vesselLeadTime = etaDate.difference(sDate).inDays;
      final readyDays = sDate.difference(crd).inDays;
      final totalDays = vesselLeadTime + readyDays + _avgForm4Days + _avgClearanceDays + item.expectedLineDelayDays;

      final expectedWhDate = crd.add(Duration(days: totalDays)).toString().substring(0, 10);

      return {
        'index': idx,
        'item': item,
        'vesselLeadTime': vesselLeadTime,
        'readyDays': readyDays,
        'totalDays': totalDays,
        'expectedWhDate': expectedWhDate,
      };
    }).toList();

    final validScenarios = calculatedScenarios.where((c) => !(c['item'] as ShippingScenarioItemModel).isExcludedFromAverage).toList();
    final avgTotalDays = validScenarios.isNotEmpty
        ? (validScenarios.fold<int>(0, (sum, c) => sum + (c['totalDays'] as int)) / validScenarios.length).round()
        : 0;
    final avgArrivalDate = validScenarios.isNotEmpty
        ? crd.add(Duration(days: avgTotalDays)).toString().substring(0, 10)
        : 'N/A';

    final recItemMap = calculatedScenarios.where((c) => (c['item'] as ShippingScenarioItemModel).isRecommended).firstOrNull;
    final recItem = recItemMap != null ? (recItemMap['item'] as ShippingScenarioItemModel) : null;

    final earliestItemMap = validScenarios.isNotEmpty
        ? validScenarios.reduce((a, b) => (a['totalDays'] as int) < (b['totalDays'] as int) ? a : b)
        : null;
    final latestItemMap = validScenarios.isNotEmpty
        ? validScenarios.reduce((a, b) => (a['totalDays'] as int) > (b['totalDays'] as int) ? a : b)
        : null;

    // Linked PO packing list metrics
    double totalCargoCbm = 0.0;
    double totalCargoWeightKg = 0.0;
    int linkedPlCount = 0;
    bool hasNonStackableItems = false;
    bool hasExplicitPackingList = false;

    List<PurchaseOrderModel> filteredPOs = [];
    if (_selectedImportFileId != null) {
      final importFiles = ref.watch(importFilesProvider).value ?? [];
      final selectedFile = importFiles.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
      if (selectedFile != null) {
        filteredPOs = poList.where((p) => p.importFileId == selectedFile.importFileId || p.importFileCode == selectedFile.importFileCode).toList();
      }
    } else if (_selectedPoId != null) {
      filteredPOs = poList.where((p) => p.poId == _selectedPoId).toList();
    }

    for (var po in filteredPOs) {
      if (po.packingListItems.isNotEmpty) {
        hasExplicitPackingList = true;
        linkedPlCount += po.packingListItems.length;
        for (var pl in po.packingListItems) {
          totalCargoCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
          totalCargoWeightKg += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
          if (!pl.isStackable) hasNonStackableItems = true;
        }
      }
    }

    final containerRec = ContainerRequirementEngine.calculate(
      totalCbm: totalCargoCbm,
      totalWeightKg: totalCargoWeightKg,
      isStackable: _isStackable,
    );

    final dualRec = ContainerRequirementEngine.calculateBoth(
      totalCbm: totalCargoCbm,
      totalWeightKg: totalCargoWeightKg,
    );

    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editingSessionId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ وضع التعديل نشط: أنت تقوم الآن بتعديل الدراسة رقم $_editingSessionCode (${_title.isNotEmpty ? _title : "بدون اسم"}). سيتم حفظ التعديلات على نفس الدراسة والمسمى.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 13),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: AppTheme.crimson),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('إلغاء التعديل والبدء من جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _resetFormForNewStudy();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔄 تم إلغاء وضع التعديل وتصفير الحقول لبدء دراسة جديدة.'),
                                  backgroundColor: AppTheme.charcoal,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Top Metrics Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'متوسط موعد التوصيل للمخزن (Avg WH Date)',
                          avgArrivalDate,
                          Icons.date_range,
                          AppTheme.emerald,
                          subtitle: 'خلال $avgTotalDays يوم من الجاهزية',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'أسرع خط ملاحي وصولاً (Earliest Line)',
                          earliestItemMap != null ? (earliestItemMap["item"] as ShippingScenarioItemModel).providerName : 'N/A',
                          Icons.speed,
                          AppTheme.cobalt,
                          subtitle: earliestItemMap != null ? 'تاريخ الوصول المتوقع: ${earliestItemMap["expectedWhDate"]}' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'أبطأ خط ملاحي وصولاً (Latest Line)',
                          latestItemMap != null ? (latestItemMap["item"] as ShippingScenarioItemModel).providerName : 'N/A',
                          Icons.warning_amber_rounded,
                          Colors.amber.shade900,
                          subtitle: latestItemMap != null ? 'تاريخ الوصول المتوقع: ${latestItemMap["expectedWhDate"]}' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'الخط الموصى به رسمياً (Recommended)',
                          recItem != null ? '${recItem.providerName} (${recItem.vesselName})' : 'لم يحدد بعد',
                          Icons.stars_rounded,
                          Colors.purple,
                          subtitle: recItemMap != null ? 'تاريخ التوصيل: ${recItemMap["expectedWhDate"]} (${recItemMap["totalDays"]} يوم)' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Study Main Settings Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚙️ Study Setup & Parameters (إعدادات ومعلمات الجلسة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                          const SizedBox(height: 12),

                          // Parameters Row 1
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('title_$_title'),
                                  initialValue: _title,
                                  decoration: const InputDecoration(labelText: 'Study Title (مسمى دراسة خيارات الشحن) *', hintText: 'مثال: دراسة شحن خطوط الشرق الأقصى - يوليو', isDense: true),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'عنوان الدراسة مطلوب' : null,
                                  onChanged: (v) => _title = v.trim(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _cargoReadyDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _cargoReadyDate = picked;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Cargo Ready Date (CRD) *', isDense: true),
                                    child: Text(_cargoReadyDate.toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImportFileId,
                                  labelText: 'Link Import File (ربط بملف استيراد)',
                                  items: [
                                    const SearchableDropdownItem<int?>(value: null, label: 'None / Standalone'),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedImportFileId = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Parameters Row 2 (Pick-up Address)
                          TextFormField(
                            key: ValueKey('pickup_addr_$_pickUpAddress'),
                            initialValue: _pickUpAddress,
                            decoration: const InputDecoration(
                              labelText: 'Pick-up Address (عنوان استلام البضاعة / مكان التجميع المصنعي)',
                              hintText: 'أدخل عنوان المصنع أو المدينة أو مكان استلام الشحنة في بلد المنشأ (e.g. Factory A, Industrial Zone, Shanghai)',
                              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.cobalt),
                              isDense: true,
                            ),
                            onChanged: (v) => _pickUpAddress = v.trim(),
                          ),
                          const SizedBox(height: 12),

                          // Parameters Row 3 (PO Link & Project Link)
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedPoId,
                                  labelText: 'Link Purchase Order (PO)',
                                  items: [
                                    const SearchableDropdownItem<int?>(value: null, label: 'None / Standalone'),
                                    ...poList.map((po) => SearchableDropdownItem<int?>(
                                          value: po.poId,
                                          label: '${po.poNumber} (${po.supplierName ?? "Supplier"})',
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedPoId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedProjectId,
                                  labelText: 'Link Project',
                                  items: [
                                    const SearchableDropdownItem<int?>(value: null, label: 'None / Unbound'),
                                    ...projectsList.map((p) => SearchableDropdownItem<int?>(
                                          value: p.projectId,
                                          label: '${p.projectCode} - ${p.projectName}',
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedProjectId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _avgForm4Days.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Avg Form 4 Days (أيام نموذج 4)', isDense: true, suffixText: 'أيام'),
                                  onChanged: (v) => _avgForm4Days = int.tryParse(v) ?? 5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _avgClearanceDays.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Avg Clearance Days (أيام التخليص)', isDense: true, suffixText: 'أيام'),
                                  onChanged: (v) => _avgClearanceDays = int.tryParse(v) ?? 7,
                                ),
                              ),
                            ],
                          ),

                          // Linked Packing List & Container Engine Section
                          if (_selectedImportFileId != null || _selectedPoId != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, color: Colors.purple, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '📦 إجمالي حمولة الملف المجمعة من قوائم التعبئة: ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                      ),
                                      Text(
                                        '${totalCargoCbm.toStringAsFixed(3)} m³ | ${totalCargoWeightKg.toStringAsFixed(0)} kg (${filteredPOs.length} أمر شراء | $linkedPlCount بند تعبئة)',
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
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.emerald,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                        icon: const Icon(Icons.view_in_ar, size: 14, color: Colors.white),
                                        label: const Text(
                                          'مخطط رص الحاويات (Load Plan)',
                                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _showVisualLoadPlanDialog(context, filteredPOs, totalCargoCbm, totalCargoWeightKg),
                                      ),
                                    ],
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
                      const Text('🚢 Shipping Carrier Options & Quotes (خيارات وعروض شحن الشركات مدمجة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('إضافة خيار شحن جديد'),
                        onPressed: () {
                          setState(() {
                            final defaultLineName = shippingLines.isNotEmpty ? shippingLines.first.partnerName : 'COSCO Shipping';
                            _evalItems.add(ShippingScenarioItemModel(
                              providerName: defaultLineName,
                              vesselName: 'VESSEL NEW',
                              polName: 'Shanghai Port (ميناء شانغهاي)',
                              podName: 'El Dekheila Port (ميناء الدخيلة)',
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

                    final isExpanded = _expandedQuotes[idx] ?? false;

                    // Automatically compute containers total count for displays
                    final currentContainersCount = (item.container40ftApplicable ? item.container40ftQty : 0) + 
                                                   (item.container20ftApplicable ? item.container20ftQty : 0);

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: item.isRecommended 
                              ? AppTheme.emerald 
                              : (item.isExcludedFromAverage ? Colors.grey.shade400 : Colors.blue.shade200), 
                          width: item.isRecommended ? 2 : 1
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Row 1: Freight Forwarder, Shipping Line, Vessel & Voyage
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
                                  child: SearchableDropdownField<int?>(
                                    value: item.providerId,
                                    labelText: 'وكيل الشحن / الناقل (Freight Forwarder)',
                                    items: [
                                      const SearchableDropdownItem<int?>(value: null, label: 'ادخال يدوياً / Custom'),
                                      ...freightForwarders.map((p) => SearchableDropdownItem<int?>(
                                            value: p.providerId,
                                            label: p.partnerName,
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final partner = freightForwarders.where((p) => p.providerId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        providerId: val,
                                        providerName: partner != null ? partner.partnerName : item.providerName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<String>(
                                    value: shippingLines.any((p) => p.partnerName == item.providerName) ? item.providerName : '',
                                    labelText: 'الخط الملاحي (Shipping Line) *',
                                    items: [
                                      const SearchableDropdownItem<String>(value: '', label: 'اختر الخط الملاحي (Select Line)'),
                                      ...shippingLines.map((p) => SearchableDropdownItem<String>(
                                            value: p.partnerName,
                                            label: p.partnerName,
                                          )),
                                    ],
                                    onChanged: (val) {
                                      if (val != null && val.isNotEmpty) {
                                        _updateItem(idx, item.copyWith(providerName: val), currenciesList);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: item.vesselName,
                                    decoration: const InputDecoration(labelText: 'Vessel Name *', isDense: true),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                    onChanged: (v) => _updateItem(idx, item.copyWith(vesselName: v.trim()), currenciesList),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.voyageNumber ?? '',
                                    decoration: const InputDecoration(labelText: 'Voyage #', isDense: true),
                                    onChanged: (v) => _updateItem(idx, item.copyWith(voyageNumber: v.trim()), currenciesList),
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
                                            _expandedQuotes.remove(idx);
                                          });
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 2: POL, POD & Customs Broker Selector
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: item.portOfLoadingId,
                                    labelText: 'ميناء السفر / التحميل (Port of Loading - POL)',
                                    items: [
                                      const SearchableDropdownItem<int?>(value: null, label: 'اختر ميناء السفر/التحميل (Select POL)'),
                                      ...portsList.map((p) => SearchableDropdownItem<int?>(
                                            value: p.locationId,
                                            label: '${p.unLocode} - ${p.locationName} (${p.country})',
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final selectedPort = portsList.where((p) => p.locationId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        portOfLoadingId: val,
                                        polName: selectedPort != null ? selectedPort.locationName : item.polName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: item.portOfDischargeId,
                                    labelText: 'ميناء الوصول / التفريغ (Port of Discharge - POD)',
                                    items: [
                                      const SearchableDropdownItem<int?>(value: null, label: 'اختر ميناء الوصول/التفريغ (Select POD)'),
                                      ...portsList.map((p) => SearchableDropdownItem<int?>(
                                            value: p.locationId,
                                            label: '${p.unLocode} - ${p.locationName} (${p.country})',
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final selectedPort = portsList.where((p) => p.locationId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        portOfDischargeId: val,
                                        podName: selectedPort != null ? selectedPort.locationName : item.podName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: item.customsBrokerId,
                                    labelText: 'المخلص الجمركي (Customs Broker)',
                                    items: [
                                      const SearchableDropdownItem<int?>(value: null, label: 'اختر المخلص الجمركي (Select Broker)'),
                                      ...customsBrokers.map((p) => SearchableDropdownItem<int?>(
                                            value: p.providerId,
                                            label: p.partnerName,
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final partner = customsBrokers.where((p) => p.providerId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        customsBrokerId: val,
                                        customsBrokerName: partner?.partnerName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 3: Sailing Date, ETA, Delays & Risk
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
                                        _updateItem(idx, item.copyWith(sailingDate: picked.toString().substring(0, 10)), currenciesList);
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
                                        _updateItem(idx, item.copyWith(estimatedArrivalDate: picked.toString().substring(0, 10)), currenciesList);
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
                                      _updateItem(idx, item.copyWith(expectedLineDelayDays: delay), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: item.riskLevel,
                                    labelText: 'Risk Level',
                                    items: const [
                                      SearchableDropdownItem(value: 'Low', label: 'Low Risk 🟢'),
                                      SearchableDropdownItem(value: 'Medium', label: 'Medium Risk 🟠'),
                                      SearchableDropdownItem(value: 'High', label: 'High Risk 🔴'),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        _updateItem(idx, item.copyWith(riskLevel: v), currenciesList);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilterChip(
                                  label: Text(item.isExcludedFromAverage ? 'Excluded from Avg 🚫' : 'Include in Avg ✅', style: TextStyle(fontSize: 11, color: item.isExcludedFromAverage ? Colors.red.shade800 : AppTheme.cobalt)),
                                  selected: item.isExcludedFromAverage,
                                  onSelected: (val) {
                                    _updateItem(idx, item.copyWith(isExcludedFromAverage: val), currenciesList);
                                  },
                                ),
                              ],
                            ),

                            // Live Calculation & Expand Quote buttons
                            if (calc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '📍 POL: ${item.polName ?? "غير محدد"} ➔ POD: ${item.podName ?? "غير محدد"} | Lead Time: ${calc["vesselLeadTime"]}d | WH Days: ${calc["totalDays"]}d',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => setState(() => _expandedQuotes[idx] = !isExpanded),
                                          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppTheme.cobalt),
                                          label: Text(
                                            isExpanded 
                                                ? 'إخفاء عرض السعر (Hide Quote)' 
                                                : 'تفاصيل عرض السعر (Edit Quote) [${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}]',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('Expected WH Arrival: ${calc["expectedWhDate"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Expandable Quotation Cost Form Section (BP-008 Integration)
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.request_quote, color: AppTheme.cobalt, size: 18),
                                        SizedBox(width: 6),
                                        Text('💰 تفاصيل عرض سعر شحن الشركة والناقل الملحق (Freight Quote Details)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    
                                    // Row A: Free time & Main Quote Currency
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.freeTimeDays.toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(labelText: 'Free Time days at destination (أيام الفري تايم في الوجهة)', isDense: true, suffixText: 'أيام'),
                                            onChanged: (v) {
                                              final ft = int.tryParse(v) ?? 14;
                                              _updateItem(idx, item.copyWith(freeTimeDays: ft), currenciesList);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SearchableDropdownField<String>(
                                            value: currenciesList.any((c) => c.currencyCode == item.quotationCurrency) ? item.quotationCurrency : (currenciesList.isNotEmpty ? currenciesList.first.currencyCode : 'USD'),
                                            labelText: 'Main Quote Currency (عملة المقارنة الأساسية للعرض)',
                                            items: currenciesList.map((c) => SearchableDropdownItem(
                                                  value: c.currencyCode,
                                                  label: '${c.currencyCode} - ${c.currencySymbol}',
                                                )).toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                _updateItem(idx, item.copyWith(quotationCurrency: v), currenciesList);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Table/Grid of Cost Items (Redesigned: inputs always visible, toggles at the right side)
                                    _buildCostRow(
                                      rowKey: 'container40ft_$idx',
                                      title: '1. شحن حاوية 40 قدم (Container 40ft)',
                                      applicable: item.container40ftApplicable,
                                      price: item.container40ftPrice,
                                      currency: item.container40ftCurrency,
                                      qty: item.container40ftQty.toDouble(),
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(container40ftApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(container40ftPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(container40ftCurrency: v), currenciesList),
                                      onQtyChanged: (v) => _updateItem(idx, item.copyWith(container40ftQty: v.toInt()), currenciesList),
                                      showQty: true,
                                      isIntegerQty: true,
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'container20ft_$idx',
                                      title: '2. شحن حاوية 20 قدم (Container 20ft)',
                                      applicable: item.container20ftApplicable,
                                      price: item.container20ftPrice,
                                      currency: item.container20ftCurrency,
                                      qty: item.container20ftQty.toDouble(),
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(container20ftApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(container20ftPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(container20ftCurrency: v), currenciesList),
                                      onQtyChanged: (v) => _updateItem(idx, item.copyWith(container20ftQty: v.toInt()), currenciesList),
                                      showQty: true,
                                      isIntegerQty: true,
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'lclCbm_$idx',
                                      title: '3. شحن CBM لشحنة LCL (LCL CBM Cost)',
                                      applicable: item.lclCbmApplicable,
                                      price: item.lclCbmPrice,
                                      currency: item.lclCbmCurrency,
                                      qty: item.lclCbmQty,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(lclCbmApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(lclCbmPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(lclCbmCurrency: v), currenciesList),
                                      onQtyChanged: (v) => _updateItem(idx, item.copyWith(lclCbmQty: v), currenciesList),
                                      showQty: true,
                                      isIntegerQty: false,
                                      currenciesList: currenciesList,
                                    ),
                                    
                                    // Total containers label
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Text(
                                        'إجمالي عدد الحاويات المطبقة للشحن = $currentContainersCount حاوية (تفصيل: 40ft: ${item.container40ftApplicable ? item.container40ftQty : 0} | 20ft: ${item.container20ftApplicable ? item.container20ftQty : 0})',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                      ),
                                    ),

                                    _buildCostRow(
                                      rowKey: 'expressCourier_$idx',
                                      title: '4. البريد السريع للمستندات (Express Courier)',
                                      applicable: item.expressCourierApplicable,
                                      price: item.expressCourierPrice,
                                      currency: item.expressCourierCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(expressCourierApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(expressCourierPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(expressCourierCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'eurAtr_$idx',
                                      title: '5. شهادة المنشأ (EUR.1 / ATR Certificate)',
                                      applicable: item.eurAtrApplicable,
                                      price: item.eurAtrPrice,
                                      currency: item.eurAtrCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(eurAtrApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(eurAtrPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(eurAtrCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'solasVgm_$idx',
                                      title: '6. مصاريف التحقق من الوزن (SOLAS/VGM Fees)',
                                      applicable: item.solasVgmApplicable,
                                      price: item.solasVgmPrice,
                                      currency: item.solasVgmCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(solasVgmApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(solasVgmPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(solasVgmCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'vgmNotification_$idx',
                                      title: '7. إخطار إقرار الوزن (VGM Notification Fee)',
                                      applicable: item.vgmNotificationApplicable,
                                      price: item.vgmNotificationPrice,
                                      currency: item.vgmNotificationCurrency,
                                      qty: currentContainersCount.toDouble(),
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(vgmNotificationApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(vgmNotificationPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(vgmNotificationCurrency: v), currenciesList),
                                      showQty: true,
                                      qtyReadOnly: true,
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'telexRelease_$idx',
                                      title: '8. إطلاق الفاكس الملاحي (Telex Release)',
                                      applicable: item.telexReleaseApplicable,
                                      price: item.telexReleasePrice,
                                      currency: item.telexReleaseCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(telexReleaseApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(telexReleasePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(telexReleaseCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'insurance_$idx',
                                      title: '9. بوليصة التأمين البحري (Insurance)',
                                      applicable: item.insuranceApplicable,
                                      price: item.insurancePrice,
                                      currency: item.insuranceCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(insuranceApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(insurancePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(insuranceCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'bookingCancellation_$idx',
                                      title: '10. غرامة إلغاء الحجز (Booking Cancellation)',
                                      applicable: item.bookingCancellationApplicable,
                                      price: item.bookingCancellationPrice,
                                      currency: item.bookingCancellationCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(bookingCancellationApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(bookingCancellationPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(bookingCancellationCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),

                                    // New Cost Rows
                                    _buildCostRow(
                                      rowKey: 'ics2FilingFee_$idx',
                                      title: '11. رسوم إيداع بيان الحمول الرقمية (ICS2 Filing Fee)',
                                      applicable: item.ics2FilingFeeApplicable,
                                      price: item.ics2FilingFeePrice,
                                      currency: item.ics2FilingFeeCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(ics2FilingFeeApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(ics2FilingFeePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(ics2FilingFeeCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'documentFees_$idx',
                                      title: '12. مصاريف المستندات الإضافية (Document Fees)',
                                      applicable: item.documentFeesApplicable,
                                      price: item.documentFeesPrice,
                                      currency: item.documentFeesCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(documentFeesApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(documentFeesPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(documentFeesCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'waiverLetterFee_$idx',
                                      title: '13. مصاريف خطاب التنازل (Waiver Letter / Transfer Fee)',
                                      applicable: item.waiverLetterFeeApplicable,
                                      price: item.waiverLetterFeePrice,
                                      currency: item.waiverLetterFeeCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(waiverLetterFeeApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(waiverLetterFeePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(waiverLetterFeeCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'othersFee_$idx',
                                      title: '14. مصاريف ومصاريف أخرى (Others)',
                                      applicable: item.othersFeeApplicable,
                                      price: item.othersFeePrice,
                                      currency: item.othersFeeCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(othersFeeApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(othersFeePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(othersFeeCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    
                                    const Divider(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cobalt.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            '💰 إجمالي قيمة هذا العرض (إجمالي كل البنود المطبقة بالأرقام الصحيحة):',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                          ),
                                          Text(
                                            '${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
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
                          const Text('📊 Side-by-Side Shipping Scenarios Comparison Matrix (جدول المقارنة التفصيلي مدمج النولون)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Carrier Provider')),
                                DataColumn(label: Text('Total Quote Cost')),
                                DataColumn(label: Text('Expected WH Arrival')),
                                DataColumn(label: Text('Total WH Days')),
                                DataColumn(label: Text('Customs Broker')),
                                DataColumn(label: Text('POL / POD')),
                                DataColumn(label: Text('Vessel / Voyage')),
                                DataColumn(label: Text('Sailing Date')),
                                DataColumn(label: Text('ETA Port')),
                                DataColumn(label: Text('Vessel Lead Time')),
                                DataColumn(label: Text('Free Time')),
                                DataColumn(label: Text('Delay Days')),
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
                                    DataCell(Text('${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                    DataCell(Text('${c["expectedWhDate"]}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                    DataCell(Text('${c["totalDays"]} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                    DataCell(Text(item.customsBrokerName ?? '-')),
                                    DataCell(Text('${item.polName ?? "-"} ➔ ${item.podName ?? "-"}', style: const TextStyle(fontSize: 11))),
                                    DataCell(Text('${item.vesselName} (${item.voyageNumber ?? "-"})')),
                                    DataCell(Text(item.sailingDate)),
                                    DataCell(Text(item.estimatedArrivalDate)),
                                    DataCell(Text('${c["vesselLeadTime"]} days')),
                                    DataCell(Text('${item.freeTimeDays} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                                    DataCell(Text('${item.expectedLineDelayDays} days')),
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
          ),

          // Bottom Fixed Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))],
              ),
              child: Row(
                children: [
                  if (_editingSessionId != null) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.charcoal,
                        side: const BorderSide(color: AppTheme.charcoal),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('إلغاء التعديل (Cancel Edit)'),
                      onPressed: _resetFormForNewStudy,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_editingSessionId != null ? 'حفظ تعديلات دراسة الشحن والعروض' : 'حفظ الدراسة والنتائج (Save Evaluation Study)'),
                      onPressed: _isSaving ? null : () => _saveEvaluationSession(context, currenciesList),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow({
    required String rowKey,
    required String title,
    required bool applicable,
    required double price,
    required String currency,
    double qty = 1.0,
    required ValueChanged<bool> onApplicableChanged,
    required ValueChanged<double> onPriceChanged,
    required ValueChanged<String> onCurrencyChanged,
    ValueChanged<double>? onQtyChanged,
    bool showQty = false,
    bool qtyReadOnly = false,
    bool isIntegerQty = true,
    required List<CurrencyModel> currenciesList,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Title
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Price field (always visible with stable key)
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('price_${rowKey}_${_editingSessionId ?? "new"}_${_selectedImportFileId ?? "none"}_${_selectedPoId ?? "none"}'),
              initialValue: price == 0.0 ? '' : price.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'سعر البند', isDense: true),
              onChanged: (v) {
                final p = double.tryParse(v) ?? 0.0;
                onPriceChanged(p);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Currency dropdown (always visible, dynamic list from DB)
          Expanded(
            flex: 2,
            child: SearchableDropdownField<String>(
              value: currenciesList.any((c) => c.currencyCode == currency) ? currency : (currenciesList.isNotEmpty ? currenciesList.first.currencyCode : 'USD'),
              labelText: 'العملة',
              items: currenciesList.map((c) => SearchableDropdownItem(
                    value: c.currencyCode,
                    label: '${c.currencyCode} (${c.currencySymbol})',
                  )).toList(),
              onChanged: (v) {
                if (v != null) {
                  onCurrencyChanged(v);
                }
              },
            ),
          ),
          if (showQty) ...[
            const SizedBox(width: 8),
            // Qty field (always visible when showQty is true with stable key)
            Expanded(
              flex: 2,
              child: TextFormField(
                key: qtyReadOnly
                    ? ValueKey('readonly_qty_${rowKey}_$qty')
                    : ValueKey('qty_${rowKey}_${_editingSessionId ?? "new"}_${_selectedImportFileId ?? "none"}_${_selectedPoId ?? "none"}'),
                readOnly: qtyReadOnly,
                initialValue: qty == 0.0 ? '' : (isIntegerQty ? qty.toInt().toString() : qty.toString()),
                keyboardType: TextInputType.numberWithOptions(decimal: !isIntegerQty),
                decoration: const InputDecoration(labelText: 'الكمية', isDense: true),
                onChanged: qtyReadOnly ? null : (v) {
                  final q = double.tryParse(v) ?? 0.0;
                  if (onQtyChanged != null) {
                    onQtyChanged(q);
                  }
                },
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Applicable switch (moved after inputs)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: applicable,
                activeColor: AppTheme.cobalt,
                onChanged: onApplicableChanged,
              ),
              Text(
                applicable ? 'مطبق' : 'غير مطبق',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: applicable ? AppTheme.emerald : Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Line total display (dynamically shows 0.0 if not applicable)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: applicable ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: applicable ? Colors.green.shade200 : Colors.red.shade200),
              ),
              child: Text(
                applicable 
                    ? '${(price * qty).toStringAsFixed(0)} $currency'
                    : '0.0 $currency',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 11, 
                  color: applicable ? AppTheme.emerald : Colors.red.shade900
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
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
                              DataColumn(label: Text('Pick-up Address')),
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
                                  DataCell(Text(sess.pickUpAddress ?? '-', style: const TextStyle(fontSize: 11))),
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, color: AppTheme.cobalt, size: 18),
                                          tooltip: 'عرض التقييم',
                                          onPressed: () => _showSessionDetailsDialog(context, sess),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                          tooltip: 'تعديل التقييم',
                                          onPressed: () => _loadSessionForEditing(sess),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.print, color: AppTheme.charcoal, size: 18),
                                          tooltip: 'طباعة التقرير',
                                          onPressed: () => _showPrintReportDialog(context, sess),
                                        ),
                                        IconButton(
                                          icon: Icon(sess.isActive ? Icons.delete : Icons.restore,
                                            color: sess.isActive ? AppTheme.crimson : Colors.green,
                                            size: 18,
                                          ),
                                          tooltip: sess.isActive ? 'إلغاء التفعيل' : 'استعادة التفعيل',
                                          onPressed: () async {
                                            if (sess.isActive) {
                                              await ref.read(shippingScenariosProvider.notifier).deleteSession(sess.sessionId!);
                                            } else {
                                              await ref.read(shippingScenariosProvider.notifier).restoreSession(sess.sessionId!);
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
      ],
    );
  }

  Future<void> _saveEvaluationSession(BuildContext context, List<CurrencyModel> currenciesList) async {
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

    // Client-side validation of shipping scenarios items
    final seen = <String>{};
    for (int i = 0; i < _evalItems.length; i++) {
      final item = _evalItems[i];
      if (item.providerName.isEmpty || item.providerName == 'Select Line') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1}: يرجى اختيار الخط الملاحي (Shipping Line)!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      final sDate = DateTime.tryParse(item.sailingDate);
      final etaDate = DateTime.tryParse(item.estimatedArrivalDate);

      if (sDate == null || etaDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): يرجى تحديد التواريخ بشكل صحيح!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      // Check date constraints: sailing date must be on or after CRD
      final crdDateOnly = DateTime(_cargoReadyDate.year, _cargoReadyDate.month, _cargoReadyDate.day);
      final sailingDateOnly = DateTime(sDate.year, sDate.month, sDate.day);
      if (sailingDateOnly.isBefore(crdDateOnly)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): تاريخ الإبحار (${item.sailingDate}) لا يمكن أن يكون قبل تاريخ جاهزية البضاعة (CRD: ${crdDateOnly.toString().substring(0, 10)})!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      // Check date constraints: ETA must be after sailing date
      if (!etaDate.isAfter(sDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): تاريخ الوصول (ETA: ${item.estimatedArrivalDate}) يجب أن يكون بعد تاريخ الإبحار (${item.sailingDate})!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      if (item.expectedLineDelayDays < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): أيام التأخير المتوقعة لا يمكن أن تكون سالبة!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      // Check duplicates (same Freight Forwarder, Shipping Line, Vessel, and Sailing Date)
      final key = '${item.providerId}_${item.providerName.trim().toLowerCase()}_${item.vesselName.trim().toLowerCase()}_${item.sailingDate}';
      if (seen.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): مكرر! يوجد خيار آخر بنفس شركة وكيل الشحن والخط الملاحي والرحلة وتاريخ الإبحار.'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }
      seen.add(key);
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
        if (_pickUpAddress.trim().isNotEmpty) 'pick_up_address': _pickUpAddress.trim(),
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
        pickUpAddress: _pickUpAddress.trim().isNotEmpty ? _pickUpAddress.trim() : null,
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
      // Find the newly saved study from provider state
      final freshState = ref.read(shippingScenariosProvider);
      final savedSess = freshState.sessions.firstWhere(
        (s) => s.title == titleToSave || s.sessionCode == _editingSessionCode,
        orElse: () => ShippingEvaluationModel(
          sessionCode: _editingSessionCode ?? 'NEW',
          title: titleToSave,
          cargoReadyDate: _cargoReadyDate.toString().substring(0, 10),
          items: _evalItems,
          recommendedScenarioProvider: _evalItems.firstWhere((i) => i.isRecommended, orElse: () => _evalItems.first).providerName,
        ),
      );

      _resetFormForNewStudy();
      _tabController.animateTo(1);

      // Instantly pop up the detailed Arabic/English results summary dialog per user instructions
      _showSaveSuccessReportDialog(context, savedSess);
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

  void _showSaveSuccessReportDialog(BuildContext context, ShippingEvaluationModel sess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.emerald, size: 28),
            SizedBox(width: 10),
            Text('🏆 تقرير نتائج دراسة الشحن والعروض المحفوظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 850,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رمز دراسة الشحن: ${sess.sessionCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('عنوان الدراسة: ${sess.title ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('تاريخ الجاهزية (CRD): ${sess.cargoReadyDate} | مكان الاستلام: ${sess.pickUpAddress ?? "غير محدد"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('📊 التقرير المقارن للخطوط والرحلات المقيمة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(1.1),
                    2: FlexColumnWidth(1.1),
                    3: FlexColumnWidth(1.1),
                    4: FlexColumnWidth(1.2),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.0),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('الناقل / الخط الملاحي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('تاريخ الإبحار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('الوصول للميناء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('إجمالي الأيام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('موعد المخزن المتوقع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('إجمالي قيمة العرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('الترشيح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...sess.items.map((item) {
                      return TableRow(
                        decoration: BoxDecoration(color: item.isRecommended ? Colors.green.shade50.withOpacity(0.5) : null),
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.providerName, style: TextStyle(fontWeight: item.isRecommended ? FontWeight.bold : FontWeight.normal, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.sailingDate, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.estimatedArrivalDate, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${item.expectedTotalDaysToWarehouse} يوم', style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.expectedWarehouseArrivalDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              item.isRecommended ? '🟢 موصى به' : (item.isExcludedFromAverage ? '🚫 مستبعد' : 'عادي'),
                              style: TextStyle(fontWeight: FontWeight.bold, color: item.isRecommended ? AppTheme.emerald : Colors.grey, fontSize: 10),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الخط الملاحي الموصى به رسميًا للربط والتعاقد: ${sess.recommendedScenarioProvider ?? "لم يحدد بعد"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'دراسة الشحن والأسعار ${sess.sessionCode}: ${sess.title}\nالخط الموصى به: ${sess.recommendedScenarioProvider}\nتاريخ وصول المخزن: ${sess.avgExpectedWarehouseArrivalDate}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 تم نسخ ملخص النتائج للحافظة!'), backgroundColor: AppTheme.cobalt),
              );
            },
            child: const Text('نسخ ملخص النتائج'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('موافق (تم الحفظ)'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetailsDialog(BuildContext context, ShippingEvaluationModel sess) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Shipping Transit Study Details (${sess.sessionCode})'),
        content: SizedBox(
          width: 950,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sess.title ?? 'Shipping Study', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('CRD Date: ${sess.cargoReadyDate} | Pick-up: ${sess.pickUpAddress ?? "N/A"} | Form 4: ${sess.avgForm4Days}d | Clearance: ${sess.avgClearanceDays}d', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 20),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Forwarder / Provider')),
                      DataColumn(label: Text('Total Cost')),
                      DataColumn(label: Text('Total WH Days')),
                      DataColumn(label: Text('Customs Broker')),
                      DataColumn(label: Text('Vessel')),
                      DataColumn(label: Text('POL ➔ POD')),
                      DataColumn(label: Text('Sailing')),
                      DataColumn(label: Text('ETA')),
                      DataColumn(label: Text('Free Time')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: sess.items.asMap().entries.map((e) {
                      final item = e.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('${e.key + 1}')),
                          DataCell(Text(item.providerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                          DataCell(Text('${item.expectedTotalDaysToWarehouse} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                          DataCell(Text(item.customsBrokerName ?? '-')),
                          DataCell(Text('${item.vesselName} (${item.voyageNumber ?? "-"})')),
                          DataCell(Text('${item.polName ?? "-"} ➔ ${item.podName ?? "-"}', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(item.sailingDate)),
                          DataCell(Text(item.estimatedArrivalDate)),
                          DataCell(Text('${item.freeTimeDays} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          DataCell(Text(item.isRecommended ? 'Recommended ⭐' : item.isExcludedFromAverage ? 'Excluded 🚫' : 'Normal')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showPrintReportDialog(BuildContext context, ShippingEvaluationModel sess) {
    final buffer = StringBuffer();
    buffer.writeln('=====================================================');
    buffer.writeln('ImportFlow ERP - Shipping Scenario & Quote Report (${sess.sessionCode})');
    buffer.writeln('Study Title: ${sess.title ?? "N/A"}');
    buffer.writeln('Cargo Ready Date: ${sess.cargoReadyDate} | Pick-up: ${sess.pickUpAddress ?? "N/A"}');
    buffer.writeln('Linked Import File: ${sess.importFileCode ?? "N/A"} | PO: ${sess.poNumber ?? "N/A"}');
    buffer.writeln('Avg Transit: ${sess.avgExpectedTransitDays} days | WH Arrival: ${sess.avgExpectedWarehouseArrivalDate ?? "N/A"}');
    buffer.writeln('Recommended Line: ${sess.recommendedScenarioProvider ?? "N/A"}');
    buffer.writeln('=====================================================\n');
    buffer.writeln('Provider,Shipping Line,Customs Broker,Vessel,Voyage,POL,POD,Sailing,ETA,Free Time,Delay,Total WH Days,Total Cost,Risk,Status');
    for (var item in sess.items) {
      buffer.writeln('"${item.providerName}","${item.providerName}","${item.customsBrokerName ?? "-"}","${item.vesselName}","${item.voyageNumber ?? "-"}","${item.polName ?? "-"}","${item.podName ?? "-"}","${item.sailingDate}","${item.estimatedArrivalDate}",${item.freeTimeDays},${item.expectedLineDelayDays},${item.expectedTotalDaysToWarehouse},"${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}","${item.riskLevel}","${item.isRecommended ? "Recommended" : item.isExcludedFromAverage ? "Excluded" : "Normal"}"');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ تم نسخ تقرير الدراسة والعروض للحافظة بنجاح! جاهز للطباعة (Ctrl+P)'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _showContainerComparisonDialog(
    BuildContext context,
    ContainerDualRecommendationResult dualRec,
    double cbm,
    double weightKg,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🚚 مقارنة حالة الرص القابل وغير القابل للرص (Dual Container Matrix)'),
        content: SizedBox(
          width: 650,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجمالي CBM الشحنة: ${cbm.toStringAsFixed(3)} m³ | إجمالي الوزن: ${weightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('الخاصية / Scenario', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('📦 قابل للرص (Stackable)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                      Padding(padding: EdgeInsets.all(8), child: Text('🚫 غير قابل للرص (Non-Stackable)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('نوع الحاوية الموصى بها')),
                      Padding(padding: const EdgeInsets.all(8), child: Text(dualRec.stackableResult.recommendedContainerCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(dualRec.nonStackableResult.recommendedContainerCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('عدد الحاويات المطلوبة')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.stackableResult.requiredContainersCount} حاويات', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.nonStackableResult.requiredContainersCount} حاويات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('نسبة استغلال حجم الحاوية')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.stackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.nonStackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showVisualLoadPlanDialog(BuildContext context, List<PurchaseOrderModel> pos, double totalCbm, double totalWeight) {
    final List<CargoItem> cargoItems = [];
    int itemCounter = 1;

    for (final po in pos) {
      for (final pl in po.packingListItems) {
        for (int q = 0; q < pl.qtyPkg.toInt(); q++) {
          double lCm = pl.lengthCm;
          double wCm = pl.widthCm;
          double hCm = pl.heightCm;
          if (pl.unit == 'mm') {
            lCm /= 10;
            wCm /= 10;
            hCm /= 10;
          } else if (pl.unit == 'm') {
            lCm *= 100;
            wCm *= 100;
            hCm *= 100;
          }

          cargoItems.add(CargoItem(
            itemId: '$itemCounter',
            length: lCm,
            width: wCm,
            height: hCm,
            weight: pl.grossWeightUnitKg,
            rotate: true,
          ));
          itemCounter++;
        }
      }
    }

    if (cargoItems.isEmpty) {
      cargoItems.add(CargoItem(
        itemId: 'Simulated Cargo',
        length: 120,
        width: 80,
        height: 100,
        weight: totalWeight > 0 ? totalWeight : 500.0,
        rotate: true,
      ));
    }

    final plan = ContainerRequirementEngine.planShipment(cargoItems);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.view_in_ar, color: AppTheme.emerald),
              SizedBox(width: 8),
              Text(
                'مخطط رص الحاويات للشحنة (Visual Load Planner)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 900,
            height: 600,
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(2.2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                      children: const [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('الحاوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('الأصناف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('إجمالي الوزن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('وصف حالة الامتلاء والتحذيرات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    ...plan.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final res = entry.value;
                      final placedIds = res.placedItems.map((p) => p.item.itemId).join(', ');
                      
                      String statusText = '';
                      if (res.containerCode == 'FAILED') {
                        statusText = 'فشل التحميل (طرود كبيرة الحجم/الوزن)';
                      } else {
                        final spaceUtil = (res.totalVolume / res.spec.internalVolumeCbm) * 100;
                        if (res.placedItems.any((p) => p.length >= 190 || p.width >= 190)) {
                          statusText = 'ممتلئة طوليًا (أبعاد الممر 190 سم تعوق الرص الجانبي)';
                        } else if (spaceUtil < 25) {
                          statusText = 'فاضية جدًا لسه (استغلال طول ومساحة ضعيف)';
                        } else {
                          statusText = 'استغلال جيد للمساحة (${spaceUtil.toStringAsFixed(1)}%)';
                        }
                      }

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              res.containerCode == 'FAILED' ? 'فشل الرص' : '$idx: ${res.spec.code}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(placedIds.isEmpty ? '-' : placedIds),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(res.containerCode == 'FAILED' ? '-' : '${res.totalWeight.toStringAsFixed(0)} kg'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusText.contains('ممتلئة')
                                    ? Colors.red.shade800
                                    : (statusText.contains('فاضية') ? Colors.amber.shade900 : Colors.green.shade800),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: plan.length,
                    itemBuilder: (ctx, pIdx) {
                      final res = plan[pIdx];
                      if (res.containerCode == 'FAILED') {
                        return Center(
                          child: Text(
                            'الأصناف التالية تفوق سعة حاويات الشحن: ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مخطط الحاوية #${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text('Top View - مسقط أفقي (Internal ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} cm)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 160,
                                          decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300)),
                                          child: CustomPaint(
                                            painter: ContainerLoadPlanPainter(plan: res, isTopView: true),
                                            child: Container(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text('Side View - مسقط جانبي (Internal ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 160,
                                          decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300)),
                                          child: CustomPaint(
                                            painter: ContainerLoadPlanPainter(plan: res, isTopView: false),
                                            child: Container(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}
