import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/error_details_dialog.dart';

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
  final int initialIndex;
  const ShippingScenariosScreen({super.key, this.initialIndex = 0});

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
  int _editFormVersion = 0;
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
      _editFormVersion++;
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
      _expandedQuotes.clear();
      for (int i = 0; i < sess.items.length; i++) {
        _expandedQuotes[i] = true;
      }
    });
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📂 تم استدعاء وتحميل كافة بيانات الجلسة (${sess.sessionCode}) للتعديل وإعادة التفعيل!'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _resetFormForNewStudy() {
    setState(() {
      _editFormVersion++;
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
      _expandedQuotes.clear();
      _initDefaultItems();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _initDefaultItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(force: false);
    });
  }

  @override
  void didUpdateWidget(ShippingScenariosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  void _refreshData({bool force = false}) {
    ref.read(shippingScenariosProvider.notifier).fetchSessions();
    if (force || ref.read(projectsProvider).value == null) {
      ref.read(projectsProvider.notifier).fetchProjects();
    }
    if (force || ref.read(purchaseOrdersProvider).purchaseOrders.isEmpty) {
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    }
    if (force || ref.read(allPartnersProvider).value == null) {
      ref.read(allPartnersProvider.notifier).fetchPartners();
    }
    if (force || ref.read(partnersProvider).value == null) {
      ref.read(partnersProvider.notifier).fetchPartners();
    }
    if (force || ref.read(transportLocationsProvider).value == null) {
      ref.read(transportLocationsProvider.notifier).fetchLocations();
    }
    if (force || ref.read(importFilesProvider).value == null) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    if (force || ref.read(currenciesProvider).value == null) {
      ref.read(currenciesProvider.notifier).fetchCurrencies();
    }
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

    // 4 Previous fee columns
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

    // 3 New quotation fee items: DTHC, Storage per week, Extra day storage
    if (item.dthcApplicable) {
      total += convert(item.dthcPrice, item.dthcCurrency);
    }
    if (item.storagePerWeekApplicable) {
      total += convert(item.storagePerWeekPrice, item.storagePerWeekCurrency);
    }
    if (item.extraDayStorageApplicable) {
      total += convert(item.extraDayStoragePrice, item.extraDayStorageCurrency);
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
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Live Refresh (تحديث حي)',
            onPressed: () => _refreshData(force: true),
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
        final filePoIds = selectedFile.poIds ?? [];
        filteredPOs = poList.where((p) =>
            (p.poId != null && filePoIds.contains(p.poId)) ||
            (p.importFileId != null && p.importFileId == selectedFile.importFileId) ||
            (selectedFile.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == selectedFile.importFileCode)).toList();
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
            child: KeyedSubtree(
              key: ValueKey('evaluator_form_${_editingSessionId ?? "new"}_$_editFormVersion'),
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
                                  key: ValueKey('title_${_editingSessionId ?? "new"}_$_editFormVersion'),
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
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedImportFileId = v;
                                      if (v != null) {
                                        final importFiles = ref.read(importFilesProvider).value ?? [];
                                        final f = importFiles.where((file) => file.importFileId == v).firstOrNull;
                                        if (f != null) {
                                          final fCode = f.customFileNumber ?? f.importFileCode;
                                          _title = '[$fCode] ${f.companyName}';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Parameters Row 2 (Pick-up Address)
                          TextFormField(
                            key: ValueKey('pickup_addr_${_editingSessionId ?? "new"}_$_editFormVersion'),
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
                                  key: ValueKey('avg_form4_${_editingSessionId ?? "new"}_$_editFormVersion'),
                                  initialValue: _avgForm4Days.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Avg Form 4 Days (أيام نموذج 4)', isDense: true, suffixText: 'أيام'),
                                  onChanged: (v) => _avgForm4Days = int.tryParse(v) ?? 5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('avg_clearance_${_editingSessionId ?? "new"}_$_editFormVersion'),
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
                                    key: ValueKey('vessel_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
                                    initialValue: item.vesselName,
                                    decoration: const InputDecoration(labelText: 'Vessel Name *', isDense: true),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                    onChanged: (v) => _updateItem(idx, item.copyWith(vesselName: v.trim()), currenciesList),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('voyage_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
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
                                    key: ValueKey('delay_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
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
                                            key: ValueKey('freetime_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
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
                                     _buildCostRow(
                                       rowKey: 'dthc_$idx',
                                       title: '15. تفريغ ومناولة ميناء الوصول (DTHC)',
                                       applicable: item.dthcApplicable,
                                       price: item.dthcPrice,
                                       currency: item.dthcCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(dthcApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(dthcPrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(dthcCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'storagePerWeek_$idx',
                                       title: '16. أرضيات / تخزين لأول أسبوع (Storage per one week)',
                                       applicable: item.storagePerWeekApplicable,
                                       price: item.storagePerWeekPrice,
                                       currency: item.storagePerWeekCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekPrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'extraDayStorage_$idx',
                                       title: '17. أرضيات / تخزين لليوم الإضافي (Extra day storage)',
                                       applicable: item.extraDayStorageApplicable,
                                       price: item.extraDayStoragePrice,
                                       currency: item.extraDayStorageCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(extraDayStorageApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(extraDayStoragePrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(extraDayStorageCurrency: v), currenciesList),
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
        ),

          // Bottom Fixed Action Bar with 3 Standard ERP Action Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  // 1. Live Refresh Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.charcoal,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
                    label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _refreshData(force: true),
                  ),
                  const SizedBox(width: 8),

                  // 2. Clear Form & Start New
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.blueGrey),
                    label: const Text('تفريغ وبدء تسجيل جديد 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _resetFormForNewStudy,
                  ),
                  const SizedBox(width: 8),

                  // 3. Save Draft & Continue Later
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: AppTheme.cobalt,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.cobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 18, color: AppTheme.cobalt),
                    label: const Text('حفظ مؤقت ومتابعة لاحقة 💾', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : () => _saveEvaluationSession(context, currenciesList),
                  ),
                  const Spacer(),

                  // 4. Final Submit / Save Study
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      elevation: 2,
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _editingSessionId != null ? 'حفظ وتحديث دراسة الشحن 💾' : 'حفظ الدراسة والنتائج (Save Study) ✅',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isSaving ? null : () => _saveEvaluationSession(context, currenciesList),
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
              key: ValueKey('price_${rowKey}_${_editingSessionId ?? "new"}_$_editFormVersion'),
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
                    : ValueKey('qty_${rowKey}_${_editingSessionId ?? "new"}_$_editFormVersion'),
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
    final totalSessions = state.sessions.length;
    final activeSessions = state.sessions.where((s) => s.isActive).length;
    final avgTransitAll = totalSessions > 0
        ? state.sessions.fold<double>(0, (sum, s) => sum + s.avgExpectedTransitDays) / totalSessions
        : 0.0;
    final withRecommendation = state.sessions.where((s) => s.recommendedScenarioProvider != null && s.recommendedScenarioProvider!.isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Top Summary Cards ───────────────────────────────────────────────
        Container(
          color: AppTheme.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _histStatCard(
                icon: Icons.folder_copy_rounded,
                label: 'إجمالي الدراسات',
                value: '$totalSessions',
                color: AppTheme.cobalt,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.check_circle_rounded,
                label: 'نشطة',
                value: '$activeSessions',
                color: AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.schedule_rounded,
                label: 'متوسط ترانزيت',
                value: avgTransitAll > 0 ? '${avgTransitAll.toStringAsFixed(1)} يوم' : '-',
                color: Colors.purple.shade300,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.recommend_rounded,
                label: 'مع توصية',
                value: '$withRecommendation',
                color: Colors.orange.shade300,
              ),
              const Spacer(),
              // Force Refresh button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تحديث السجل', style: TextStyle(fontSize: 13)),
                onPressed: () => ref.read(shippingScenariosProvider.notifier).fetchSessions(),
              ),
            ],
          ),
        ),

        // Data Actions Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: MasterDataToolbarWidget(
            moduleEndpoint: 'shipping-evaluations',
            title: 'Shipping_Evaluations',
            onRefreshNeeded: () => ref.read(shippingScenariosProvider.notifier).fetchSessions(),
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
                    hintText: 'ابحث بكود الدراسة، العنوان، أو الملاحظات...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cobalt),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(shippingScenariosProvider.notifier).setSearchQuery('');
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
                    ref.read(shippingScenariosProvider.notifier).setSearchQuery(v.trim());
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
                      state.showInactive ? 'إظهار الملغية' : 'إخفاء الملغية',
                      style: TextStyle(
                        fontSize: 12,
                        color: state.showInactive ? AppTheme.crimson : Colors.grey.shade700,
                        fontWeight: state.showInactive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: state.showInactive,
                    selectedColor: AppTheme.crimson.withOpacity(0.12),
                    checkmarkColor: AppTheme.crimson,
                    onSelected: (val) => ref.read(shippingScenariosProvider.notifier).toggleShowInactive(val),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Sessions count chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.sessions.length} نتيجة',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                ),
              ),
            ],
          ),
        ),

        // ─── Data Table ──────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.cobalt),
                      SizedBox(height: 16),
                      Text('جارٍ تحميل سجل الدراسات...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : state.sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'لا توجد نتائج مطابقة للبحث'
                                : 'لا توجد دراسات محفوظة بعد',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بإنشاء دراسة جديدة من تبويب "Shipping Scenarios Evaluator"',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
                            columnSpacing: 20,
                            dividerThickness: 0.5,
                            headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                            columns: const [
                              DataColumn(label: SizedBox(
                                width: 168,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text('العمليات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )),
                              DataColumn(label: Text('📋 كود الدراسة')),
                              DataColumn(label: Text('📁 ملف الاستيراد')),
                              DataColumn(label: Text('📝 العنوان')),
                              DataColumn(label: Text('⏱️ متوسط الترانزيت')),
                              DataColumn(label: Text('🏭 موعد الوصول')),
                              DataColumn(label: Text('⭐ الخط الموصى به')),
                              DataColumn(label: Text('🔢 الخيارات')),
                              DataColumn(label: Text('🔗 أمر الشراء')),
                              DataColumn(label: Text('📅 CRD')),
                              DataColumn(label: Text('📍 الاستلام')),
                            ],
                            rows: state.sessions.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final sess = entry.value;
                              final isEven = idx.isEven;
                              final rowColor = !sess.isActive
                                  ? Colors.red.shade50
                                  : isEven
                                      ? Colors.white
                                      : Colors.grey.shade50;

                              return DataRow(
                                color: WidgetStateProperty.all(rowColor),
                                onSelectChanged: (_) => _showSessionDetailsDialog(context, sess),
                                cells: [
                                  // ⚡ 1. ACTIONS — أول عمود دائماً مرئي
                                  DataCell(
                                    RowActionsPill(
                                      onView: () => _showSessionDetailsDialog(context, sess),
                                      onEdit: () => _loadSessionForEditing(sess),
                                      onPrint: () => _showPrintReportDialog(context, sess),
                                      onDelete: () async {
                                        if (sess.isActive) {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Row(
                                                children: [
                                                  Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
                                                  SizedBox(width: 8),
                                                  Text('تأكيد الحذف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              content: Text(
                                                'هل أنت متأكد من حذف الدراسة "${sess.sessionCode}"؟\nيمكن استعادتها لاحقاً من قائمة "إظهار الملغية".',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('إلغاء'),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
                                                  icon: const Icon(Icons.delete_rounded, size: 16),
                                                  label: const Text('حذف'),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(shippingScenariosProvider.notifier).deleteSession(sess.sessionId!);
                                          }
                                        } else {
                                          await ref.read(shippingScenariosProvider.notifier).restoreSession(sess.sessionId!);
                                        }
                                      },
                                      viewTooltip: 'عرض التقييم والدراسة',
                                      editTooltip: 'تعديل دراسة الشحن',
                                      printTooltip: 'طباعة تقرير الدراسة',
                                      deleteTooltip: sess.isActive ? 'حذف الدراسة' : 'استعادة الدراسة',
                                    ),
                                  ),

                                  // 2. Study Code
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showSessionDetailsDialog(context, sess),
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
                                            if (!sess.isActive)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 4),
                                                child: Icon(Icons.block, size: 12, color: AppTheme.crimson),
                                              ),
                                            Text(
                                              sess.sessionCode,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: sess.isActive ? AppTheme.cobalt : AppTheme.crimson,
                                                fontSize: 12,
                                                decoration: sess.isActive ? TextDecoration.none : TextDecoration.lineThrough,
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
                                        sess.importFileCode ?? (sess.importFileId != null ? 'IMP-${sess.importFileId}' : '—'),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 4. Title
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        sess.title ?? 'Shipping Transit Study',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 5. Avg Transit
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${sess.avgExpectedTransitDays.toStringAsFixed(1)} يوم',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 6. Avg WH Arrival
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warehouse_rounded, size: 14, color: AppTheme.emerald.withOpacity(0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          sess.avgExpectedWarehouseArrivalDate ?? '—',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.emerald,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 7. Recommended Carrier
                                  DataCell(
                                    sess.recommendedScenarioProvider != null && sess.recommendedScenarioProvider!.isNotEmpty
                                        ? Container(
                                            constraints: const BoxConstraints(maxWidth: 150),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blue.shade600, Colors.blue.shade400],
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    sess.recommendedScenarioProvider!,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text('—', style: TextStyle(color: Colors.grey.shade400)),
                                  ),

                                  // 8. Options Count
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${sess.items.length} خيار',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 9. Linked PO / Project
                                  DataCell(
                                    sess.poNumber != null
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.receipt_long_rounded, size: 13, color: AppTheme.emerald),
                                              const SizedBox(width: 4),
                                              Text('PO: ${sess.poNumber}', style: const TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          )
                                        : sess.projectName != null
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.folder_special_rounded, size: 13, color: Colors.orange.shade600),
                                                  const SizedBox(width: 4),
                                                  Text('PRJ: ${sess.projectName}', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                                                ],
                                              )
                                            : Text('مستقل', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ),

                                  // 10. CRD Date
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(sess.cargoReadyDate, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),

                                  // 11. Pick-up Address
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        sess.pickUpAddress ?? '—',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  /// بطاقة إحصائية صغيرة في شريط الـ History
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

    String titleToSave = _title.trim();
    if (_selectedImportFileId != null) {
      final importFiles = ref.read(importFilesProvider).value ?? [];
      final f = importFiles.where((file) => file.importFileId == _selectedImportFileId).firstOrNull;
      if (f != null) {
        final fCode = f.customFileNumber ?? f.importFileCode;
        if (!titleToSave.startsWith('[$fCode]')) {
          titleToSave = '[$fCode] ${f.companyName}';
        }
      }
    }
    if (titleToSave.isEmpty) {
      titleToSave = 'دراسة تقييم خيارات الشحن (${DateTime.now().toString().substring(0, 10)})';
    }

    setState(() => _isSaving = true);

    bool ok = false;
    if (_editingSessionId != null) {
      final oldSession = ref.read(shippingScenariosProvider).sessions.where((s) => s.sessionId == _editingSessionId).firstOrNull;
      if (oldSession != null) {
        final List<FieldChangeItem> changes = [];

        // 1. General & Header Data
        if (FieldChangeItem.isDifferent(oldSession.title, titleToSave)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'عنوان دراسة الشحن',
            oldValue: oldSession.title,
            newValue: titleToSave,
          ));
        }

        final newCrd = _cargoReadyDate.toString().substring(0, 10);
        if (FieldChangeItem.isDifferent(oldSession.cargoReadyDate, newCrd)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'تاريخ جاهزية البضاعة (CRD)',
            oldValue: oldSession.cargoReadyDate,
            newValue: newCrd,
          ));
        }

        final newPickup = _pickUpAddress.trim().isNotEmpty ? _pickUpAddress.trim() : null;
        if (FieldChangeItem.isDifferent(oldSession.pickUpAddress, newPickup)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'موقع وعنوان الاستلام',
            oldValue: oldSession.pickUpAddress,
            newValue: newPickup,
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.avgForm4Days, _avgForm4Days)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'أيام إصدار نموذج 4 المتوقعة',
            oldValue: '${oldSession.avgForm4Days} يوم',
            newValue: '$_avgForm4Days يوم',
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.avgClearanceDays, _avgClearanceDays)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'أيام التخليص الجمركي المتوقعة',
            oldValue: '${oldSession.avgClearanceDays} يوم',
            newValue: '$_avgClearanceDays يوم',
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.importFileId, _selectedImportFileId)) {
          changes.add(FieldChangeItem(
            section: 'الربط التشغيلي',
            fieldName: 'ملف الاستيراد المرتبط',
            oldValue: oldSession.importFileCode ?? (oldSession.importFileId != null ? 'ID: ${oldSession.importFileId}' : null),
            newValue: _selectedImportFileId != null ? 'ID: $_selectedImportFileId' : null,
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.poId, _selectedPoId)) {
          changes.add(FieldChangeItem(
            section: 'الربط التشغيلي',
            fieldName: 'أمر الشراء المرتبط (PO)',
            oldValue: oldSession.poNumber ?? (oldSession.poId != null ? 'ID: ${oldSession.poId}' : null),
            newValue: _selectedPoId != null ? 'ID: $_selectedPoId' : null,
          ));
        }

        // 2. Shipping Options / Quotation Items
        if (oldSession.items.length != _evalItems.length) {
          changes.add(FieldChangeItem(
            section: 'عروض أسعار الشحن المقارنة',
            fieldName: 'عدد عروض الشحن المدرجة',
            oldValue: '${oldSession.items.length} عرض',
            newValue: '${_evalItems.length} عرض',
          ));
        } else {
          for (int i = 0; i < _evalItems.length; i++) {
            final o = oldSession.items[i];
            final n = _evalItems[i];
            final quoteTitle = 'عرض #${i + 1} (${n.providerName.isNotEmpty ? n.providerName : "ناقل"})';

            if (FieldChangeItem.isDifferent(o.providerName, n.providerName)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - وكيل الشحن (Forwarder)',
                oldValue: o.providerName,
                newValue: n.providerName,
              ));
            }
            if (FieldChangeItem.isDifferent(o.vesselName, n.vesselName)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - الخط الملاحي / الباخرة (Carrier / Vessel)',
                oldValue: o.vesselName,
                newValue: n.vesselName,
              ));
            }
            if (FieldChangeItem.isDifferent(o.sailingDate, n.sailingDate)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - تاريخ الإبحار (ETD)',
                oldValue: o.sailingDate,
                newValue: n.sailingDate,
              ));
            }
            if (FieldChangeItem.isDifferent(o.estimatedArrivalDate, n.estimatedArrivalDate)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - تاريخ الوصول المتوقع (ETA)',
                oldValue: o.estimatedArrivalDate,
                newValue: n.estimatedArrivalDate,
              ));
            }
            if (FieldChangeItem.isDifferent(o.freeTimeDays, n.freeTimeDays)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - أيام السماح (Free Time)',
                oldValue: '${o.freeTimeDays} يوم',
                newValue: '${n.freeTimeDays} يوم',
              ));
            }
            if (FieldChangeItem.isDifferent(o.totalQuotationAmount, n.totalQuotationAmount)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - إجمالي قيمة العرض (${n.quotationCurrency})',
                oldValue: '${o.totalQuotationAmount.toStringAsFixed(2)} ${o.quotationCurrency}',
                newValue: '${n.totalQuotationAmount.toStringAsFixed(2)} ${n.quotationCurrency}',
              ));
            }
            if (FieldChangeItem.isDifferent(o.isExcludedFromAverage, n.isExcludedFromAverage)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - استبعاد من المتوسط الحسابي',
                oldValue: o.isExcludedFromAverage ? 'مستبعد' : 'محتسب',
                newValue: n.isExcludedFromAverage ? 'مستبعد' : 'محتسب',
              ));
            }
          }
        }

        if (changes.isNotEmpty) {
          if (!context.mounted) return;
          final confirmed = await showChangeDiffConfirmationDialog(
            context,
            title: 'مراجعة وتأكيد تعديلات دراسة وعروض الشحن',
            itemReference: oldSession.sessionCode.isNotEmpty ? oldSession.sessionCode : titleToSave,
            changes: changes,
          );
          if (!confirmed) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final data = {
        'title': titleToSave,
        'cargo_ready_date': _cargoReadyDate.toString().substring(0, 10),
        if (_pickUpAddress.trim().isNotEmpty) 'pick_up_address': _pickUpAddress.trim(),
        'avg_form4_days': _avgForm4Days,
        'avg_clearance_days': _avgClearanceDays,
        if (_selectedImportFileId != null) 'import_file_id': _selectedImportFileId,
        if (_selectedPoId != null) 'po_id': _selectedPoId,
        if (_selectedProjectId != null) 'project_id': _selectedProjectId,
        'is_active': true,
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
      await showErrorDetailsDialog(
        context,
        title: '❌ تعذر حفظ دراسة وتقييم خيارات الشحن',
        error: err,
        onRetry: () async {
          await _saveEvaluationSession(context, currenciesList);
        },
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
    final List<CargoItem> baseCargoItems = [];
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

          baseCargoItems.add(CargoItem(
            itemId: '$itemCounter',
            length: lCm,
            width: wCm,
            height: hCm,
            weight: pl.grossWeightUnitKg > 0 ? pl.grossWeightUnitKg : (pl.totalGrossWeightKg / (pl.qtyPkg > 0 ? pl.qtyPkg : 1)),
            rotate: true,
            isStackable: pl.isStackable,
            packageType: pl.packageType,
          ));
          itemCounter++;
        }
      }
    }

    if (baseCargoItems.isEmpty) {
      baseCargoItems.add(CargoItem(
        itemId: '1',
        length: 120,
        width: 80,
        height: 100,
        weight: totalWeight > 0 ? totalWeight : 500.0,
        rotate: true,
        isStackable: true,
      ));
    }

    // Default active view mode: null = Actual/Mixed, true = All Stackable, false = All Non-Stackable
    bool? activeStackingMode = baseCargoItems.any((i) => !i.isStackable) ? null : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            // Compute plan dynamically based on the selected mode
            final plan = ContainerRequirementEngine.planShipment(
              baseCargoItems,
              forceStackable: activeStackingMode,
            );

            // Compute summary metrics for active plan
            final totalPkgs = baseCargoItems.length;
            final stackableInActive = activeStackingMode == true
                ? totalPkgs
                : (activeStackingMode == false ? 0 : baseCargoItems.where((c) => c.isStackable).length);
            final nonStackableInActive = totalPkgs - stackableInActive;

            final totalPlanWeight = plan.fold(0.0, (s, p) => s + p.totalWeight);
            final totalPlanVolume = plan.fold(0.0, (s, p) => s + p.totalVolume);

            // Determine container fleet text (e.g. 2 x 40HC or 2 x 40HC + 1 x 20GP)
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
                  const Expanded(
                    child: Text(
                      'مخطط ومحاكاة رص الحاويات (Visual 2.5D/3D Container Load Planner)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
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
                      'الأسطول المطلوب: $fleetSummaryText (${plan.length} حاوية)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 980,
                height: 640,
                child: Column(
                  children: [
                    // 1. Scenario / Stacking Mode Switcher (All 3 required states)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🔄 اختر سيناريو الرص للمعاينة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                          ),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('📦 1. بضائع تقبل الرص (All Stackable)'),
                                selected: activeStackingMode == true,
                                selectedColor: AppTheme.emerald,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == true ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = true);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('🚫 2. بضائع لا تقبل الرص (All Non-Stackable)'),
                                selected: activeStackingMode == false,
                                selectedColor: Colors.orange.shade800,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == false ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('🔀 3. مزيج يقبل ولا يقبل الرص (Mixed Stacking)'),
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
                              _buildLoadMetricPill('📦 إجمالي الطرود', '$totalPkgs طرد', AppTheme.cobalt),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('⚖️ إجمالي الوزن', '${totalPlanWeight.toStringAsFixed(0)} kg', AppTheme.charcoal),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('📐 إجمالي الحجم', '${totalPlanVolume.toStringAsFixed(3)} m³', Colors.orange.shade900),
                            ],
                          ),
                          Row(
                            children: [
                              _buildLoadMetricPill('✅ يقبل الرص', '$stackableInActive طرد', Colors.green.shade800),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('🚫 لا يقبل الرص', '$nonStackableInActive طرد', Colors.red.shade800),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Table summary of container loads
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
                          children: const [
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الحاوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الأصناف والطرود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الوزن المحمّل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('استغلال المساحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('توزيع الرص والسلامة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
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
                            final nonStackInThis = res.placedItems.where((p) => !p.item.isStackable).length;
                            if (nonStackInThis > 0) {
                              statusText = 'تحتوي على $nonStackInThis طرد غير قابل للرص مثبت على الأرضية';
                            } else {
                              statusText = 'رص متعدد الطبقات متوافق (${(res.totalVolume / res.spec.internalVolumeCbm * 100).toStringAsFixed(1)}%)';
                            }
                          }

                          final double spaceUtil = res.spec.internalVolumeCbm > 0 ? (res.totalVolume / res.spec.internalVolumeCbm) * 100 : 0.0;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  res.containerCode == 'FAILED' ? 'فشل الرص' : '$idx: ${res.spec.code}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(placedIds.isEmpty ? '-' : placedIds, style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(res.containerCode == 'FAILED' ? '-' : '${res.totalWeight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text('${spaceUtil.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusText.contains('فشل')
                                        ? Colors.red.shade800
                                        : (statusText.contains('غير قابل') ? Colors.brown.shade800 : Colors.green.shade800),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. Tab view or list for visual container layout drawings
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
                              child: Text(
                                'الأصناف التالية تفوق سعة حاويات الشحن: ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                                        'مخطط الحاوية #${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                      ),
                                      Row(
                                        children: [
                                          const Text('🪵 طبالي خشبية أرضية', style: TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                            child: Text('الأبعاد الداخلية: ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 10, color: AppTheme.cobalt)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Side View (Left Wall Removed) - High Fidelity Realistic Container
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
                  label: const Text('إغلاق المخطط'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildLoadMetricPill(String label, String value, Color color) {
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
