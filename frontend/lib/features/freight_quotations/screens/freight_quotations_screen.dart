import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../external_service_providers/providers/partners_provider.dart';
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
  int? _selectedPoId;
  int? _selectedProjectId;

  final List<FreightQuotationItemModel> _quotations = [];
  bool _isSaving = false;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void _addQuotationDialog() {
    final partnersState = ref.watch(partnersProvider);
    final partnersList = partnersState.value ?? [];
    final carriersList = partnersList.where((p) => p.partnerType.contains('Shipping Line') || p.partnerType.contains('Freight')).toList();

    if (carriersList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة ناقلين بحريين (Shipping Lines) في دليل الشركاء أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        int? selectedProviderId = carriersList.first.providerId;
        String selectedProviderName = carriersList.first.partnerName;
        final vesselController = TextEditingController();
        final voyageController = TextEditingController();
        final oceanCostController = TextEditingController(text: '3000.0');
        final localCostController = TextEditingController(text: '400.0');
        final inlandCostController = TextEditingController(text: '250.0');
        final freeDaysController = TextEditingController(text: '14');
        final remarksController = TextEditingController();

        DateTime sailingDate = _crdDate.add(const Duration(days: 4));
        DateTime arrivalDate = sailingDate.add(const Duration(days: 24));

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة عرض سعر ناقل / شركة شحن (Add Freight Quote)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedProviderId,
                        decoration: const InputDecoration(labelText: 'شركة الشحن / الخط الملاحي *', border: OutlineInputBorder()),
                        items: carriersList.map((c) => DropdownMenuItem<int>(value: c.providerId, child: Text(c.partnerName))).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
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
            Text('إدارة ومقارنة عروض أسعار الشحن (BP-008 – Freight Quotations RFQ)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                                child: DropdownButtonFormField<String>(
                                  value: _shippingMethod,
                                  decoration: const InputDecoration(labelText: 'وسيلة الشحن (Shipping Method) *', border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: 'Ocean FCL', child: Text('Ocean FCL (شحن بحري كامل)')),
                                    DropdownMenuItem(value: 'Ocean LCL', child: Text('Ocean LCL (شحن بحري جزئي)')),
                                    DropdownMenuItem(value: 'Air Freight', child: Text('Air Freight (شحن جوي)')),
                                    DropdownMenuItem(value: 'Inland Trucking', child: Text('Inland Trucking (شحن بري)')),
                                  ],
                                  onChanged: (val) => setState(() => _shippingMethod = val!),
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
                                child: DropdownButtonFormField<String>(
                                  value: portsList.any((p) => p.locationName == _polName) ? _polName : (portsList.isNotEmpty ? portsList.first.locationName : _polName),
                                  decoration: const InputDecoration(labelText: 'ميناء التحميل (POL) *', border: OutlineInputBorder()),
                                  items: portsList.map((p) => DropdownMenuItem<String>(value: p.locationName, child: Text(p.locationName))).toList(),
                                  onChanged: (val) => setState(() => _polName = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: portsList.any((p) => p.locationName == _podName) ? _podName : (portsList.length > 1 ? portsList[1].locationName : _podName),
                                  decoration: const InputDecoration(labelText: 'ميناء الوصول (POD) *', border: OutlineInputBorder()),
                                  items: portsList.map((p) => DropdownMenuItem<String>(value: p.locationName, child: Text(p.locationName))).toList(),
                                  onChanged: (val) => setState(() => _podName = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cbmController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'إجمالي الحجم (CBM)', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'الوزن القائم (Gross Wt kg)', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
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
                        DropdownButton<String>(
                          value: _statusFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                            DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                            DropdownMenuItem(value: 'RFQ Issued', child: Text('RFQ Issued')),
                            DropdownMenuItem(value: 'Quotations Received', child: Text('Quotations Received')),
                            DropdownMenuItem(value: 'Awarded', child: Text('Awarded')),
                          ],
                          onChanged: (v) => setState(() => _statusFilter = v!),
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
                                  DataColumn(label: Text('عنوان الطلب والميناء', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('أقل سعر', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('أسرع ترانزيت', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('العرض المعتمد', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((rfq) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(rfq.rfqCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      DataCell(Text(rfq.title)),
                                      DataCell(Text('\$${rfq.lowestFreightCost}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      DataCell(Text('${rfq.fastestTransitDays} يوم')),
                                      DataCell(Text(rfq.awardedProviderName ?? 'لم يعتمد')),
                                      DataCell(_buildStatusBadge(rfq.status)),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.visibility, color: AppTheme.cobalt),
                                          onPressed: () => _showRFQDetailsDialog(rfq),
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
}
