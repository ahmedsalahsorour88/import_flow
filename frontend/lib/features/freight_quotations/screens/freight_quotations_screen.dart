import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/freight_quotation_model.dart';
import '../providers/freight_quotations_provider.dart';

class FreightQuotationsScreen extends ConsumerStatefulWidget {
  const FreightQuotationsScreen({super.key});

  @override
  ConsumerState<FreightQuotationsScreen> createState() => _FreightQuotationsScreenState();
}

class _FreightQuotationsScreenState extends ConsumerState<FreightQuotationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController(text: 'طلب عرض سعر شحن حاويات لمعدات وآلات خط الإنتاج');
  final TextEditingController _cbmController = TextEditingController(text: '128.5');
  final TextEditingController _weightController = TextEditingController(text: '48500.0');
  final TextEditingController _notesController = TextEditingController();

  DateTime _crdDate = DateTime.now().add(const Duration(days: 15));
  String _shippingMethod = 'Ocean FCL';
  String _polName = 'Shanghai Port (CN SHA), China';
  String _podName = 'Alexandria Port (EG ALX), Egypt';
  int? _selectedImportFileId;
  int? _selectedPoId;
  int? _selectedProjectId;

  final List<FreightQuotationItemModel> _quotations = [];
  bool _isSaving = false;
  bool _isStackable = true;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(freightQuotationsProvider.notifier).fetchRFQs();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _cbmController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuotationDialog({
    String? prefillCarrierName,
    int? prefillProviderId,
    double? prefillOceanCost,
    double? prefillLocalCost,
    int? prefillTransitDays,
    int? prefillFreeDays,
    String? prefillRemarks,
  }) {
    final partnersState = ref.read(partnersProvider);
    final partnersList = partnersState.value ?? [];
    final carriersList = partnersList.where((p) => p.partnerType.contains('Shipping Line') || p.partnerType.contains('Freight')).toList();

    if (carriersList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة ناقلين بحريين (Shipping Lines) في دليل الشركاء أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Try to find matching carrier if prefill name provided
    int? matchedProviderId = prefillProviderId;
    String matchedProviderName = carriersList.first.partnerName;
    if (prefillProviderId != null) {
      final found = carriersList.where((c) => c.providerId == prefillProviderId).firstOrNull;
      if (found != null) matchedProviderName = found.partnerName;
    } else if (prefillCarrierName != null && prefillCarrierName.isNotEmpty) {
      final nameLower = prefillCarrierName.toLowerCase();
      final found = carriersList.where((c) => c.partnerName.toLowerCase().contains(nameLower) || nameLower.contains(c.partnerName.toLowerCase())).firstOrNull;
      if (found != null) {
        matchedProviderId = found.providerId;
        matchedProviderName = found.partnerName;
      } else {
        matchedProviderId = carriersList.first.providerId;
      }
    } else {
      matchedProviderId = carriersList.first.providerId;
    }

    showDialog(
      context: context,
      builder: (context) {
        int? selectedProviderId = matchedProviderId;
        String selectedProviderName = matchedProviderName;
        final vesselController = TextEditingController();
        final voyageController = TextEditingController();
        final oceanCostController = TextEditingController(text: prefillOceanCost != null ? prefillOceanCost.toStringAsFixed(0) : '3000.0');
        final localCostController = TextEditingController(text: prefillLocalCost != null ? prefillLocalCost.toStringAsFixed(0) : '400.0');
        final inlandCostController = TextEditingController(text: '0.0');
        final freeDaysController = TextEditingController(text: prefillFreeDays?.toString() ?? '14');
        final remarksController = TextEditingController(text: prefillRemarks ?? '');

        // Calculate arrival from transit days if available
        DateTime sailingDate = _crdDate.add(const Duration(days: 4));
        DateTime arrivalDate = prefillTransitDays != null
            ? sailingDate.add(Duration(days: prefillTransitDays))
            : sailingDate.add(const Duration(days: 24));

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.directions_boat, color: AppTheme.cobalt),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    prefillCarrierName != null ? 'مراجعة وتأكيد عرض السعر المستخرج' : 'إضافة عرض سعر ناقل / شركة شحن (Add Freight Quote)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (prefillCarrierName != null && prefillCarrierName.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cobalt.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(
                                '🤖 تم استخراج هذا العرض تلقائياً من النص. راجع البيانات قبل الإضافة.',
                                style: TextStyle(fontSize: 12, color: AppTheme.cobalt.withOpacity(0.8)),
                              )),
                            ],
                          ),
                        ),
                      SearchableDropdownField<int?>(
                        value: selectedProviderId,
                        labelText: 'شركة الشحن / الخط الملاحي *',
                        searchHintText: 'ابحث عن الشركة...',
                        items: carriersList.map((c) => SearchableDropdownItem<int?>(value: c.providerId, label: c.partnerName)).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final c = carriersList.firstWhere((p) => p.providerId == val);
                            setDialogState(() {
                              selectedProviderId = val;
                              selectedProviderName = c.partnerName;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: vesselController,
                              decoration: const InputDecoration(labelText: 'اسم السفينة (Vessel Name)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: voyageController,
                              decoration: const InputDecoration(labelText: 'رقم الرحلة (Voyage No)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: oceanCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'نولون البحر (Ocean Freight USD) *', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: localCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'المصاريف المحلية (USD)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: inlandCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'النقل الداخلي (USD)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: sailingDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d != null) setDialogState(() => sailingDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'تاريخ الإبحار (Sailing Date)', border: OutlineInputBorder()),
                                child: Text(sailingDate.toString().substring(0, 10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: arrivalDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d != null) setDialogState(() => arrivalDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'تاريخ الوصول (ETA Arrival)', border: OutlineInputBorder()),
                                child: Text(arrivalDate.toString().substring(0, 10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: freeDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'أيام السماح بالجمارك (Free Days)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(labelText: 'ملاحظات العرض', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                  onPressed: () {
                    final oceanCost = double.tryParse(oceanCostController.text.trim()) ?? 0.0;
                    final localCost = double.tryParse(localCostController.text.trim()) ?? 0.0;
                    final inlandCost = double.tryParse(inlandCostController.text.trim()) ?? 0.0;
                    final totalCost = oceanCost + localCost + inlandCost;
                    final transitDays = arrivalDate.difference(sailingDate).inDays;

                    setState(() {
                      _quotations.add(FreightQuotationItemModel(
                        providerId: selectedProviderId!,
                        providerName: selectedProviderName,
                        vesselName: vesselController.text.trim().isNotEmpty ? vesselController.text.trim() : null,
                        voyageNumber: voyageController.text.trim().isNotEmpty ? voyageController.text.trim() : null,
                        oceanFreightCost: oceanCost,
                        localChargesCost: localCost,
                        inlandCost: inlandCost,
                        totalCost: totalCost,
                        sailingDate: sailingDate.toString().substring(0, 10),
                        estimatedArrivalDate: arrivalDate.toString().substring(0, 10),
                        transitDays: transitDays > 0 ? transitDays : 1,
                        freeDaysAtPod: int.tryParse(freeDaysController.text.trim()) ?? 14,
                        remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('إضافة العرض', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ─── Text Paste Smart Extractor Dialog ───────────────────────────────────
  void _showTextExtractorDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _FreightTextExtractorDialog(
          onAddQuotation: ({
            required String carrierName,
            required double oceanCost,
            double? localCost,
            int? transitDays,
            int? freeDays,
            String? remarks,
          }) {
            _addQuotationDialog(
              prefillCarrierName: carrierName,
              prefillOceanCost: oceanCost,
              prefillLocalCost: localCost,
              prefillTransitDays: transitDays,
              prefillFreeDays: freeDays,
              prefillRemarks: remarks,
            );
          },
        );
      },
    );
  }


  Future<void> _saveRFQ() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quotations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة عرض سعر واحد على الأقل للمقارنة'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'title': _titleController.text.trim(),
        'shipping_method': _shippingMethod,
        'crd_date': _crdDate.toString().substring(0, 10),
        'pol_name': _polName,
        'pod_name': _podName,
        'import_file_id': _selectedImportFileId,
        'po_id': _selectedPoId,
        'project_id': _selectedProjectId,
        'total_cbm': double.tryParse(_cbmController.text.trim()) ?? 0.0,
        'total_gross_weight_kg': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'chargeable_weight_kg': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'notes': _notesController.text.trim(),
        'quotations': _quotations.map((q) => q.toJson()).toList(),
      };

      final created = await ref.read(freightQuotationsProvider.notifier).createRFQ(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم حفظ طلب مقارنة أسعار الشحن! كود الطلب: ${created.rfqCode}'), backgroundColor: AppTheme.emerald),
        );
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ تعذر حفظ طلب مقارنة أسعار الشحن',
          error: e,
          onRetry: () async {
            await _saveRFQ();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showRFQDetailsDialog(FreightRFQRequestModel rfq) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.directions_boat, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تفاصيل طلب عرض أسعار الشحن: ${rfq.rfqCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildStatusBadge(rfq.status),
            ],
          ),
          content: SizedBox(
            width: 750,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العنوان: ${rfq.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('وسيلة الشحن: ${rfq.shippingMethod} | CRD: ${rfq.crdDate}'),
                        const SizedBox(height: 4),
                        Text('من: ${rfq.polName} ➔ إلى: ${rfq.podName}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricBadge('أقل نولون شحن', '\$${rfq.lowestFreightCost}', Colors.green),
                      const SizedBox(width: 8),
                      _buildMetricBadge('متوسط نولون الشحن', '\$${rfq.averageFreightCost}', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMetricBadge('أسرع ترانزيت', '${rfq.fastestTransitDays} أيام', Colors.orange),
                      const SizedBox(width: 8),
                      _buildMetricBadge('العرض المعتمد', rfq.awardedProviderName ?? 'لم يعتمد بعد', AppTheme.cobalt),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('عروض أسعار الناقلين والمقارنة التفصيلية (Quotations List):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.05)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الخط الملاحي / السفينة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('إجمالي التكلفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الترانزيت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('أيام السماح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الحالة / القرار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...rfq.quotations.map(
                        (q) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  if (q.vesselName != null) Text('السفينة: ${q.vesselName}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('\$${q.totalCost}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${q.transitDays} يوم', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${q.freeDaysAtPod} يوم', style: const TextStyle(fontSize: 11))),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: q.isAwarded
                                  ? const Chip(label: Text('المعتمد 🎯', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: AppTheme.emerald)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                      onPressed: () async {
                                        final nav = Navigator.of(context);
                                        await ref.read(freightQuotationsProvider.notifier).awardQuotation(rfq.rfqId, q.quotationId!);
                                        nav.pop();
                                      },
                                      child: const Text('اعتماد هذا العرض', style: TextStyle(color: Colors.white, fontSize: 10)),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portsState = ref.watch(transportLocationsProvider);
    final rfqsState = ref.watch(freightQuotationsProvider);

    final portsList = portsState.value ?? [];

    final double lowestCost = _quotations.isNotEmpty ? _quotations.map((q) => q.totalCost).reduce((a, b) => a < b ? a : b) : 0.0;
    final int fastestTransit = _quotations.isNotEmpty ? _quotations.map((q) => q.transitDays).reduce((a, b) => a < b ? a : b) : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.directions_boat, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('إدارة ومقارنة عروض أسعار الشحن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.request_quote), text: 'Freight RFQ Evaluator (طلب ومقارنة العروض)'),
            Tab(icon: Icon(Icons.history), text: 'Saved RFQs History Log (سجل الطلبات المحفوظة)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FREIGHT RFQ EVALUATOR
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Metrics Header Bar
                  Row(
                    children: [
                      _buildMetricBadge('أقل سعر شحن متوفر', '\$$lowestCost', Colors.green),
                      const SizedBox(width: 12),
                      _buildMetricBadge('أسرع زمن ترانزيت', '$fastestTransit أيام', Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricBadge('عدد عروض الناقلين', '${_quotations.length}', Colors.grey),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: _isSaving ? null : _saveRFQ,
                        icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                        label: const Text('حفظ وتثبيت طلب مقارنة النولون', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // RFQ Configuration Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بيانات شحنة طلب عرض الأسعار (Freight RFQ Setup)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية)',
                                  searchHintText: 'ابحث عن ملف الشحنة...',
                                  items: [
                                    const SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- None / غير مرتبط بملف شحنة --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                        )),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedImportFileId = v;
                                      if (v != null) {
                                        final importFilesList = ref.read(importFilesProvider).value ?? [];
                                        final selectedFile = importFilesList.where((f) => f.importFileId == v).firstOrNull;
                                        if (selectedFile != null) {
                                          double calcCbm = 0.0;
                                          double calcWeight = 0.0;
                                          if (selectedFile.packingListsData.isNotEmpty) {
                                            for (var pl in selectedFile.packingListsData) {
                                              calcCbm += pl.cbm;
                                              calcWeight += pl.grossWeightKg;
                                            }
                                          }
                                          if (calcCbm == 0 && calcWeight == 0) {
                                            final allPOs = ref.read(purchaseOrdersProvider).purchaseOrders;
                                            final filePoIds = selectedFile.poIds ?? [];
                                            for (var po in allPOs) {
                                              if (filePoIds.contains(po.poId) || po.importFileId == selectedFile.importFileId) {
                                                if (po.packingListItems.isNotEmpty) {
                                                  for (var pl in po.packingListItems) {
                                                    calcCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
                                                    calcWeight += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
                                                  }
                                                } else {
                                                  calcCbm += po.totalCbm;
                                                  calcWeight += po.totalGrossWeightKg;
                                                }
                                              }
                                            }
                                          }
                                          if (calcCbm > 0) _cbmController.text = calcCbm.toStringAsFixed(2);
                                          if (calcWeight > 0) _weightController.text = calcWeight.toStringAsFixed(1);
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(labelText: 'عنوان طلب عرض الأسعار *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: _shippingMethod,
                                  labelText: 'وسيلة الشحن (Shipping Method) *',
                                  searchHintText: 'ابحث عن الوسيلة...',
                                  items: const [
                                    SearchableDropdownItem(value: 'Ocean FCL', label: 'Ocean FCL (شحن بحري كامل)'),
                                    SearchableDropdownItem(value: 'Ocean LCL', label: 'Ocean LCL (شحن بحري جزئي)'),
                                    SearchableDropdownItem(value: 'Air Freight', label: 'Air Freight (شحن جوي)'),
                                    SearchableDropdownItem(value: 'Inland Trucking', label: 'Inland Trucking (شحن بري)'),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _shippingMethod = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(context: context, initialDate: _crdDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                    if (d != null) setState(() => _crdDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'تاريخ جاهزية البضاعة (CRD) *', border: OutlineInputBorder()),
                                    child: Text(_crdDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: portsList.any((p) => p.locationName == _polName) ? _polName : (portsList.isNotEmpty ? portsList.first.locationName : _polName),
                                  labelText: 'ميناء التحميل (POL) *',
                                  searchHintText: 'ابحث عن ميناء التحميل...',
                                  items: portsList.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName)).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _polName = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: portsList.any((p) => p.locationName == _podName) ? _podName : (portsList.length > 1 ? portsList[1].locationName : _podName),
                                  labelText: 'ميناء الوصول (POD) *',
                                  searchHintText: 'ابحث عن ميناء الوصول...',
                                  items: portsList.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName)).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _podName = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cbmController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'إجمالي الحجم (CBM)', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'الوزن القائم (Gross Wt kg)', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                          // Container Recommendation Engine (MD-019.1 Banner)
                          Builder(builder: (context) {
                            final double curCbm = double.tryParse(_cbmController.text.trim()) ?? 0.0;
                            final double curWeight = double.tryParse(_weightController.text.trim()) ?? 0.0;
                            final dualRec = ContainerRequirementEngine.calculateBoth(totalCbm: curCbm, totalWeightKg: curWeight);
                            final containerRec = _isStackable ? dualRec.stackableResult : dualRec.nonStackableResult;

                            return Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 22),
                                      const SizedBox(width: 10),
                                      const Text(
                                        '🚚 نوع التحميل والتخزين (Cargo Stacking): ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                      ),
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '🚚 اقتراح أعداد وأنواع الحاويات التلقائي:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              containerRec.recommendationSummary,
                                              style: TextStyle(fontSize: 12, color: _isStackable ? Colors.blue.shade900 : Colors.orange.shade900, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.cobalt,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.table_chart, size: 14, color: Colors.white),
                                        label: const Text('مقارنة الحالتين (Matrix)', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showContainerComparisonDialog(context, dualRec, curCbm, curWeight),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quotations List Table
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('عروض أسعار الخطوط الملاحية والشركات المنافسة (Quotations List)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              const Spacer(),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.cobalt,
                                  side: const BorderSide(color: AppTheme.cobalt),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: _showTextExtractorDialog,
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('🤖 استخراج من نص / بريد'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: _addQuotationDialog,
                                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                                label: const Text('إضافة عرض سعر ناقل', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _quotations.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final q = _quotations[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(q.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          if (q.vesselName != null) Text('السفينة: ${q.vesselName} | الرحلة: ${q.voyageNumber ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text('نولون: \$${q.oceanFreightCost} + \$${q.localChargesCost}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text('الإجمالي: \$${q.totalCost}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text('ترانزيت: ${q.transitDays} يوم (${q.freeDaysAtPod} يوم سماح)', style: const TextStyle(fontSize: 11)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                                      onPressed: () => setState(() => _quotations.removeAt(index)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 2: SAVED RFQ HISTORY LOG
          rfqsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('❌ Error: $err')),
            data: (rfqs) {
              final filtered = rfqs.where((r) {
                final matchQuery = _searchQuery.isEmpty ||
                    r.rfqCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.polName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.podName.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchStatus = _statusFilter == 'All' || r.status == _statusFilter;
                return matchQuery && matchStatus;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Data Actions Toolbar
                    MasterDataToolbarWidget(
                      moduleEndpoint: 'freight-quotations',
                      title: 'Freight_Quotations',
                      onRefreshNeeded: () => ref.read(freightQuotationsProvider.notifier).fetchRFQs(),
                    ),
                    const SizedBox(height: 12),

                    // Search & Filter
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'البحث برقم طلب RFQ أو العنوان أو اسم الميناء...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdownField<String>(
                            value: _statusFilter,
                            labelText: 'تصفية حسب الحالة',
                            searchHintText: 'ابحث عن الحالة...',
                            items: const [
                              SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                              SearchableDropdownItem(value: 'Draft', label: 'Draft'),
                              SearchableDropdownItem(value: 'RFQ Issued', label: 'RFQ Issued'),
                              SearchableDropdownItem(value: 'Quotations Received', label: 'Quotations Received'),
                              SearchableDropdownItem(value: 'Awarded', label: 'Awarded'),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _statusFilter = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد طلبات عروض أسعار شحن مطابقة للبحث.'))
                          : SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                columns: const [
                                  DataColumn(label: Text('كود RFQ', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('عنوان الطلب والميناء', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('أقل سعر', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('أسرع ترانزيت', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('العرض المعتمد', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('⚡ العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((rfq) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(rfq.rfqCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.charcoal.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            rfq.importFileCode ?? (rfq.importFileId != null ? 'IMP-${rfq.importFileId}' : '-'),
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(rfq.title)),
                                      DataCell(Text('\$${rfq.lowestFreightCost}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      DataCell(Text('${rfq.fastestTransitDays} يوم')),
                                      DataCell(Text(rfq.awardedProviderName ?? 'لم يعتمد')),
                                      DataCell(_buildStatusBadge(rfq.status)),
                                      DataCell(
                                        RowActionsPill(
                                          onView: () => _showRFQDetailsDialog(rfq),
                                          onEdit: () => _showRFQDetailsDialog(rfq),
                                          onPrint: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('طباعة مقارنة وعروض أسعار الشحن: ${rfq.rfqCode} (${rfq.title})'),
                                                backgroundColor: AppTheme.charcoal,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          onDelete: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('تأكيد الإجراء'),
                                                content: Text('هل أنت متأكد من حذف أو إلغاء طلب عرض السعر (${rfq.rfqCode})؟'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                                    child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('تم حذف طلب عرض الأسعار بنجاح')),
                                              );
                                            }
                                          },
                                          deleteTooltip: 'حذف طلب عرض السعر',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Awarded') bg = Colors.green;
    if (status == 'Quotations Received') bg = Colors.blue;
    if (status == 'RFQ Issued') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
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
                      const Text('تحليل خيارات الحاويات وسيناريوهات التحميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Freight Text Extractor Dialog
// ─────────────────────────────────────────────────────────────────────────────

typedef _OnAddQuotationCallback = void Function({
  required String carrierName,
  required double oceanCost,
  double? localCost,
  int? transitDays,
  int? freeDays,
  String? remarks,
});

class _FreightTextExtractorDialog extends StatefulWidget {
  final _OnAddQuotationCallback onAddQuotation;

  const _FreightTextExtractorDialog({required this.onAddQuotation});

  @override
  State<_FreightTextExtractorDialog> createState() => _FreightTextExtractorDialogState();
}

class _FreightTextExtractorDialogState extends State<_FreightTextExtractorDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isExtracting = false;
  String? _error;
  List<Map<String, dynamic>> _extractedOptions = [];
  Map<String, dynamic>? _primaryExtracted;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _extractFromText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'يرجى لصق نص عرض السعر أولاً');
      return;
    }

    setState(() {
      _isExtracting = true;
      _error = null;
      _extractedOptions = [];
      _primaryExtracted = null;
    });

    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl.replaceAll('/api/v1', '')}/api/v1/smart-upload/parse-text/freight-quotation',
        data: FormData.fromMap({
          'raw_text': text,
          'save_session': false,
        }),
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final extracted = response.data['extracted_fields'] as Map<String, dynamic>? ?? {};
      final rateOptions = (extracted['rate_options'] as List<dynamic>?) ?? [];

      setState(() {
        _primaryExtracted = extracted;
        _extractedOptions = rateOptions.cast<Map<String, dynamic>>();
      });
    } on DioException catch (e) {
      setState(() => _error = 'خطأ في الاتصال بالسيرفر: ${e.message}');
    } catch (e) {
      setState(() => _error = 'خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _extractedOptions.isNotEmpty || _primaryExtracted != null;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.cobalt),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '🤖 استخراج عروض أسعار الشحن من نص / بريد إلكتروني',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الصق نص عرض السعر من البريد الإلكتروني للخط الملاحي (مثل WHL، MSC، Maersk، CMA CGM...) '
                        'وسيقوم النظام تلقائياً باستخراج بيانات النولون، الترانزيت، وأيام السماح.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Text Input Area
              TextField(
                controller: _textController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'نص عرض السعر / البريد الإلكتروني',
                  hintText: 'مثال:\nRoute: Shanghai - El Dekheila\nWHL: USD 3200/40HQ  BY WHL\nYML: USD 3000/40HQ  BY YML\nTransit time: 28 days direct\nFree time: 14 days FT\nLocal charges: USD 450/40HQ',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _textController.clear();
                            _extractedOptions = [];
                            _primaryExtracted = null;
                            _error = null;
                          }),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Error display
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.crimson, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.crimson, fontSize: 12))),
                    ],
                  ),
                ),

              // Results Section
              if (hasResults) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.emerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'تم استخراج ${_extractedOptions.isNotEmpty ? _extractedOptions.length : 1} عرض/عروض بنجاح',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.emerald),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Global info banner if available
                if (_primaryExtracted != null && (_primaryExtracted!['origin_port'] != null || _primaryExtracted!['destination_port'] != null))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.route, color: AppTheme.charcoal, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_primaryExtracted!['origin_port'] ?? '?'} ➜ ${_primaryExtracted!['destination_port'] ?? '?'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                        if (_primaryExtracted!['transit_days'] != null) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.timer, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text('${_primaryExtracted!['transit_days']} يوم ترانزيت', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                        if (_primaryExtracted!['currency'] != null) ...[
                          const SizedBox(width: 16),
                          Text('العملة: ${_primaryExtracted!['currency']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),

                // Extracted Rate Options Cards
                if (_extractedOptions.isNotEmpty)
                  ...(_extractedOptions.map((opt) => _buildOptionCard(opt)))
                else if (_primaryExtracted != null && _primaryExtracted!['freight_rate'] != null)
                  _buildOptionCard({
                    'carrier_name': _primaryExtracted!['carrier_name'] ?? 'Shipping Line',
                    'container_type': _primaryExtracted!['container_type'] ?? '40HQ',
                    'ocean_freight': _primaryExtracted!['freight_rate'],
                    'local_charges': _primaryExtracted!['local_charges'],
                    'transit_days': _primaryExtracted!['transit_days'],
                    'free_time_days': _primaryExtracted!['free_days_demurrage'],
                    'notes': null,
                  }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _isExtracting ? null : _extractFromText,
          icon: _isExtracting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.search, color: Colors.white),
          label: Text(
            _isExtracting ? 'جاري الاستخراج...' : '🔍 استخراج البيانات',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> opt) {
    final carrierName = (opt['carrier_name'] ?? 'Shipping Line').toString();
    final containerType = (opt['container_type'] ?? '40HQ').toString();
    final oceanFreight = (opt['ocean_freight'] as num?)?.toDouble() ?? 0.0;
    final localCharges = (opt['local_charges'] as num?)?.toDouble();
    final transitDays = opt['transit_days'] as int?;
    final freeDays = opt['free_time_days'] as int?;
    final notes = opt['notes']?.toString();
    final totalEst = (opt['total_estimated_cost'] as num?)?.toDouble() ?? oceanFreight + (localCharges ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Carrier Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_boat, color: AppTheme.cobalt, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        carrierName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(containerType, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notes, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Cost Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نولون: \$${oceanFreight.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                ),
                if (localCharges != null && localCharges > 0)
                  Text('مصاريف محلية: \$${localCharges.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  'الإجمالي التقديري: \$${totalEst.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Transit & Free Days
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transitDays != null)
                  Text('ترانزيت: $transitDays يوم', style: const TextStyle(fontSize: 12)),
                if (freeDays != null)
                  Text('سماح: $freeDays يوم', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Add Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAddQuotation(
                carrierName: carrierName,
                oceanCost: oceanFreight,
                localCost: localCharges,
                transitDays: transitDays,
                freeDays: freeDays,
                remarks: notes,
              );
            },
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            label: const Text('إضافة', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
