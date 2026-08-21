import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/customs_clearance_quotation_model.dart';
import '../providers/customs_clearance_quotations_provider.dart';

class CustomsClearanceQuotationsScreen extends ConsumerStatefulWidget {
  const CustomsClearanceQuotationsScreen({super.key});

  @override
  ConsumerState<CustomsClearanceQuotationsScreen> createState() =>
      _CustomsClearanceQuotationsScreenState();
}

class _CustomsClearanceQuotationsScreenState
    extends ConsumerState<CustomsClearanceQuotationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customsClearanceQuotationsProvider.notifier).fetchRFQs();
      ref.read(clearancePriceListProvider.notifier).fetchPriceList();
      ref.read(partnersProvider.notifier).fetchPartners();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(transportLocationsProvider.notifier).fetchLocations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.request_quote_rounded, color: Colors.amber, size: 26),
            SizedBox(width: 10),
            Text(
              'عروض ومقايسات التخليص الجمركي وقوائم الأسعار (Customs Clearance Quotations)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'إعادة تحميل وتحديث البيانات',
            onPressed: () {
              ref.invalidate(customsClearanceQuotationsProvider);
              ref.invalidate(clearancePriceListProvider);
              ref.invalidate(partnersProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.compare_arrows_rounded),
              text: 'طلب ومقارنة عروض التخليص الجمركي (RFQs & Evaluator)',
            ),
            Tab(
              icon: Icon(Icons.price_change_rounded),
              text: 'قوائم أسعار بنود التخليص الثابتة (Master Price Lists)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRFQsTab(),
          _buildPriceListsTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: RFQS & EVALUATOR
  // ===========================================================================

  Widget _buildRFQsTab() {
    final rfqsState = ref.watch(customsClearanceQuotationsProvider);

    return rfqsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.crimson),
            const SizedBox(height: 12),
            Text('خطأ في تحميل عروض التخليص: $e', style: const TextStyle(color: AppTheme.crimson)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () => ref.read(customsClearanceQuotationsProvider.notifier).fetchRFQs(),
            ),
          ],
        ),
      ),
      data: (rfqs) {
        final filtered = rfqs.where((r) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final matchesQuery = q.isEmpty ||
              r.rfqCode.toLowerCase().contains(q) ||
              r.title.toLowerCase().contains(q) ||
              r.portName.toLowerCase().contains(q);
          final matchesStatus = _selectedStatusFilter == 'ALL' || r.status == _selectedStatusFilter;
          return matchesQuery && matchesStatus;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              // Top Action & Filter Toolbar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'بحث بكود الطلب، العنوان، أو الميناء...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('جميع الحالات')),
                      DropdownMenuItem(value: 'Draft', child: Text('مسودة (Draft)')),
                      DropdownMenuItem(value: 'Quotations Received', child: Text('عروض مستلمة')),
                      DropdownMenuItem(value: 'Awarded', child: Text('معتمد ومُرسى (Awarded)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('🤖 استخراج ذكي لمقايسة تخليص', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showSmartExtractorDialog(null),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('إنشاء طلب عرض أسعار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showCreateRFQDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد طلبات عروض أسعار تخليص حالياً.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) => _buildRFQCard(filtered[idx]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRFQCard(CustomsClearanceRFQModel rfq) {
    Color statusColor = Colors.grey;
    if (rfq.status == 'Awarded') statusColor = AppTheme.emerald;
    if (rfq.status == 'Quotations Received') statusColor = AppTheme.cobalt;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rfq.rfqCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      rfq.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    rfq.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Cargo & Location Details Row
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _buildInfoBadge(Icons.anchor_rounded, 'الميناء:', rfq.portName),
                _buildInfoBadge(Icons.local_shipping_rounded, 'نوع الشحنة:', '${rfq.shipmentType} (${rfq.containersCount} حاوية)'),
                if (rfq.hsCode != null && rfq.hsCode!.isNotEmpty)
                  _buildInfoBadge(Icons.category_rounded, 'HS Code:', rfq.hsCode!),
                _buildInfoBadge(Icons.scale_rounded, 'الوزن:', '${rfq.grossWeightKg} كجم'),
                _buildInfoBadge(Icons.view_in_ar_rounded, 'الحجم:', '${rfq.cbm} CBM'),
                if (rfq.lowestClearanceCost > 0)
                  _buildInfoBadge(Icons.monetization_on_rounded, 'أقل عرض:', '${rfq.lowestClearanceCost.toStringAsFixed(2)} EGP', color: AppTheme.emerald),
                if (rfq.fastestTurnaroundDays > 0)
                  _buildInfoBadge(Icons.timer_rounded, 'أسرع مدة:', '${rfq.fastestTurnaroundDays} أيام', color: AppTheme.cobalt),
              ],
            ),

            if (rfq.status == 'Awarded' && rfq.awardedProviderName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.emerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'تم اعتماد وترسية التخليص الجمركي على: ${rfq.awardedProviderName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Competing Quotations Table / Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العروض المستلمة من المخلصين (${rfq.quotations.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6C5CE7)),
                      label: const Text('استخراج ذكي للعرض', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _showSmartExtractorDialog(rfq.rfqId),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة عرض يدوي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddQuotationDialog(rfq.rfqId),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (rfq.quotations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('لم يتم إدخال عروض أسعار لهذا الطلب بعد.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('المخلص الجمركي', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('أتعاب التخليص', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('النقل الداخلي', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('فحص وعرض', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('موانئ وتخزين', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('نثريات', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الإجمالي التقديري', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('المدة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الحالة / الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: rfq.quotations.map((q) {
                    final isAwarded = q.isAwarded;
                    return DataRow(
                      color: isAwarded ? WidgetStateProperty.all(AppTheme.emerald.withOpacity(0.06)) : null,
                      cells: [
                        DataCell(Text(q.providerName, style: TextStyle(fontWeight: isAwarded ? FontWeight.bold : FontWeight.normal))),
                        DataCell(Text('${q.clearanceFee.toStringAsFixed(0)} ${q.currency}')),
                        DataCell(Text('${q.inlandTransportFee.toStringAsFixed(0)} ${q.currency}')),
                        DataCell(Text('${q.inspectionFee.toStringAsFixed(0)} ${q.currency}')),
                        DataCell(Text('${q.portExpenses.toStringAsFixed(0)} ${q.currency}')),
                        DataCell(Text('${q.miscellaneousFee.toStringAsFixed(0)} ${q.currency}')),
                        DataCell(Text(
                          '${q.totalCost.toStringAsFixed(0)} ${q.currency}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isAwarded ? AppTheme.emerald : AppTheme.charcoal),
                        )),
                        DataCell(Text('${q.estimatedTurnaroundDays} أيام')),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAwarded)
                              const Chip(
                                avatar: Icon(Icons.check, size: 14, color: Colors.white),
                                label: Text('معتمد', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                backgroundColor: AppTheme.emerald,
                                padding: EdgeInsets.zero,
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text('ترسية واعتماد 🏆', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () => _awardQuotation(rfq.rfqId, q.quotationId!),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                              onPressed: () => _deleteQuotation(q.quotationId!),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 5),
        Text('$label ', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color ?? AppTheme.charcoal)),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: PRICE LISTS MASTER
  // ===========================================================================

  Widget _buildPriceListsTab() {
    final priceListState = ref.watch(clearancePriceListProvider);

    return priceListState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في تحميل قوائم الأسعار: $e', style: const TextStyle(color: AppTheme.crimson))),
      data: (items) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قوائم أسعار بنود التخليص والنقل الجمركي المعتمدة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                      SizedBox(height: 4),
                      Text('إدارة الأسعار المعيارية لكل مخلص جمركي وميناء وصول', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة بند لقائمة الأسعار', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddPriceItemDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('لا توجد بنود أسعار مسجلة بعد.', style: TextStyle(color: Colors.grey.shade600)),
                      )
                    : Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: const [
                                DataColumn(label: Text('المخلص الجمركي', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الميناء', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('نوع الخدمة', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('نوع الحاوية', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('السعر المعياري', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('حذف', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: items.map((item) {
                                return DataRow(cells: [
                                  DataCell(Text(item.providerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(item.portName)),
                                  DataCell(Text(item.serviceCategory)),
                                  DataCell(Text(item.containerType)),
                                  DataCell(Text('${item.unitPrice.toStringAsFixed(2)} ${item.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                  DataCell(Text(item.notes ?? '-')),
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                                    onPressed: () => ref.read(clearancePriceListProvider.notifier).deletePriceItem(item.priceItemId),
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DIALOGS & ACTIONS
  // ===========================================================================

  Future<void> _showCreateRFQDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: 'طلب عروض أسعار تخليص شحنة جديدة');
    final commodityCtrl = TextEditingController();
    final hsCodeCtrl = TextEditingController();
    final grossWeightCtrl = TextEditingController(text: '10000');
    final cbmCtrl = TextEditingController(text: '30');
    int containersCount = 1;
    String shipmentType = 'Ocean FCL (40HQ)';
    String portName = 'Alexandria Port (ميناء الإسكندرية)';
    int? selectedImportFileId;

    final importFiles = ref.read(importFilesProvider).value ?? [];
    final locations = ref.read(transportLocationsProvider).value ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: AppTheme.emerald),
              SizedBox(width: 10),
              Text('إنشاء طلب عرض أسعار تخليص جمركي (RFQ)'),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'عنوان الطلب *', prefixIcon: Icon(Icons.title_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<int>(
                      value: selectedImportFileId,
                      labelText: 'ربط بملف استيراد (اختياري)',
                      searchHintText: 'ابحث برقم الملف...',
                      items: importFiles
                          .map((f) => SearchableDropdownItem<int>(
                                value: f.importFileId,
                                label: '${f.importFileCode} - ${f.companyName}',
                              ))
                          .toList(),
                      onChanged: (val) {
                        setDState(() {
                          selectedImportFileId = val;
                          final match = importFiles.where((f) => f.importFileId == val).firstOrNull;
                          if (match != null) {
                            if (match.portOfDischarge != null && match.portOfDischarge!.isNotEmpty) {
                              portName = match.portOfDischarge!;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<String>(
                      value: portName,
                      labelText: 'ميناء التخليص الجمركي *',
                      searchHintText: 'ابحث عن الميناء...',
                      items: locations
                          .map((l) => SearchableDropdownItem<String>(
                                value: l.locationName,
                                label: l.locationName,
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDState(() => portName = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: shipmentType,
                            decoration: const InputDecoration(labelText: 'نوع الشحنة والحاوية *'),
                            items: const [
                              DropdownMenuItem(value: 'Ocean FCL (40HQ)', child: Text('Ocean FCL (40HQ)')),
                              DropdownMenuItem(value: 'Ocean FCL (20GP)', child: Text('Ocean FCL (20GP)')),
                              DropdownMenuItem(value: 'Ocean LCL', child: Text('Ocean LCL (مشترك)')),
                              DropdownMenuItem(value: 'Air Freight', child: Text('Air Freight (شحن جوي)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDState(() => shipmentType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: containersCount.toString(),
                            decoration: const InputDecoration(labelText: 'عدد الحاويات *'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => containersCount = int.tryParse(v) ?? 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: grossWeightCtrl,
                            decoration: const InputDecoration(labelText: 'الوزن القائم (كجم)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cbmCtrl,
                            decoration: const InputDecoration(labelText: 'الحجم (CBM)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              child: const Text('إنشاء الطلب'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newRfq = CustomsClearanceRFQModel(
                  rfqId: 0,
                  rfqCode: '',
                  title: titleCtrl.text.trim(),
                  portName: portName,
                  importFileId: selectedImportFileId,
                  commodityDescription: commodityCtrl.text.trim().isNotEmpty ? commodityCtrl.text.trim() : null,
                  hsCode: hsCodeCtrl.text.trim().isNotEmpty ? hsCodeCtrl.text.trim() : null,
                  shipmentType: shipmentType,
                  containersCount: containersCount,
                  packagesCount: 0,
                  grossWeightKg: double.tryParse(grossWeightCtrl.text) ?? 0.0,
                  cbm: double.tryParse(cbmCtrl.text) ?? 0.0,
                  status: 'Draft',
                  lowestClearanceCost: 0.0,
                  fastestTurnaroundDays: 0,
                  createdAt: '',
                );

                await ref.read(customsClearanceQuotationsProvider.notifier).createRFQ(newRfq);
                if (mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddQuotationDialog(int rfqId, {Map<String, dynamic>? prefill}) async {
    final formKey = GlobalKey<FormState>();
    final partners = ref.read(partnersProvider).value?.where((p) => p.partnerType == 'Customs Broker' || p.partnerType == 'Freight Forwarder').toList() ?? [];

    int? selectedProviderId = prefill?['provider_id'] ?? (partners.isNotEmpty ? partners.first.partnerId : 1);
    String selectedProviderName = prefill?['provider_name'] ?? (partners.isNotEmpty ? partners.first.partnerName : 'مكتب تخليص جمركي');

    final clearanceFeeCtrl = TextEditingController(text: prefill?['clearance_fee']?.toString() ?? '3000');
    final inlandFeeCtrl = TextEditingController(text: prefill?['inland_transport_fee']?.toString() ?? '6000');
    final inspectionFeeCtrl = TextEditingController(text: prefill?['inspection_fee']?.toString() ?? '1500');
    final portExpCtrl = TextEditingController(text: prefill?['port_expenses']?.toString() ?? '2000');
    final miscCtrl = TextEditingController(text: prefill?['miscellaneous_fee']?.toString() ?? '500');
    final daysCtrl = TextEditingController(text: prefill?['transit_clearance_days']?.toString() ?? '3');
    final remarksCtrl = TextEditingController(text: prefill?['notes']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          double total = (double.tryParse(clearanceFeeCtrl.text) ?? 0.0) +
              (double.tryParse(inlandFeeCtrl.text) ?? 0.0) +
              (double.tryParse(inspectionFeeCtrl.text) ?? 0.0) +
              (double.tryParse(portExpCtrl.text) ?? 0.0) +
              (double.tryParse(miscCtrl.text) ?? 0.0);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: AppTheme.cobalt),
                SizedBox(width: 10),
                Text('إضافة عرض أسعار مخلص جمركي'),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SearchableDropdownField<int>(
                        value: selectedProviderId,
                        labelText: 'المخلص الجمركي (Customs Broker) *',
                        searchHintText: 'ابحث عن المخلص الجمركي...',
                        items: partners
                            .map((p) => SearchableDropdownItem<int>(
                                  value: p.partnerId!,
                                  label: '${p.partnerName} (${p.partnerType})',
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDState(() {
                              selectedProviderId = val;
                              final match = partners.where((p) => p.partnerId == val).firstOrNull;
                              if (match != null) selectedProviderName = match.partnerName;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: clearanceFeeCtrl,
                              decoration: const InputDecoration(labelText: 'أتعاب التخليص الجمركي (EGP) *'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: inlandFeeCtrl,
                              decoration: const InputDecoration(labelText: 'النقل الداخلي للمصنع (EGP) *'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: inspectionFeeCtrl,
                              decoration: const InputDecoration(labelText: 'مصاريف فحص وعرض (EGP)'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: portExpCtrl,
                              decoration: const InputDecoration(labelText: 'رسوم موانئ وأرضيات (EGP)'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: miscCtrl,
                              decoration: const InputDecoration(labelText: 'نثريات ومصروفات إدارية (EGP)'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: daysCtrl,
                              decoration: const InputDecoration(labelText: 'مدة التخليص المقدرة (أيام) *'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.emerald),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الإجمالي التقديري للعرض:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${total.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emerald)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(child: const Text('إلغاء'), onPressed: () => Navigator.pop(ctx)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                child: const Text('حفظ العرض'),
                onPressed: () async {
                  final quote = CustomsClearanceQuotationItemModel(
                    providerId: selectedProviderId ?? 1,
                    providerName: selectedProviderName,
                    clearanceFee: double.tryParse(clearanceFeeCtrl.text) ?? 0.0,
                    inlandTransportFee: double.tryParse(inlandFeeCtrl.text) ?? 0.0,
                    inspectionFee: double.tryParse(inspectionFeeCtrl.text) ?? 0.0,
                    portExpenses: double.tryParse(portExpCtrl.text) ?? 0.0,
                    miscellaneousFee: double.tryParse(miscCtrl.text) ?? 0.0,
                    totalCost: total,
                    estimatedTurnaroundDays: int.tryParse(daysCtrl.text) ?? 3,
                    remarks: remarksCtrl.text.trim().isNotEmpty ? remarksCtrl.text.trim() : null,
                  );

                  await ref.read(customsClearanceQuotationsProvider.notifier).addQuotation(rfqId, quote);
                  if (mounted) Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSmartExtractorDialog(int? targetRfqId) async {
    final textCtrl = TextEditingController();
    bool isExtracting = false;
    Map<String, dynamic>? extractedResult;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF6C5CE7)),
              SizedBox(width: 10),
              Text('الاستخلاص الذكي لعروض أسعار ومقايسات التخليص'),
            ],
          ),
          content: SizedBox(
            width: 750,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الصق نص عرض السعر / الإيميل أو اختر ملف المقايسة لاستخلاص البنود آلياً:'),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'مثال:\nعرض أسعار تخليص جمركي من مكتب النسر...\nأتعاب التخليص: 3500 جنيه\nنقل داخلي: 7000 جنيه\nمصاريف فحص وعرض: 1500 جنيه...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
                      icon: isExtracting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.bolt_rounded),
                      label: Text(isExtracting ? 'جاري الاستخراج...' : 'استخراج فوري من النص'),
                      onPressed: isExtracting
                          ? null
                          : () async {
                              final text = textCtrl.text.trim();
                              if (text.isEmpty) return;
                              setDState(() => isExtracting = true);
                              try {
                                final dio = Dio();
                                final formData = FormData.fromMap({'raw_text': text});
                                final resp = await dio.post(
                                  '${ApiConstants.baseUrl}/smart-upload/parse-text/clearance-quotation',
                                  data: formData,
                                );
                                if (resp.statusCode == 200 && resp.data != null) {
                                  setDState(() {
                                    extractedResult = resp.data['extracted_fields'] as Map<String, dynamic>?;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('خطأ في الاستخراج: $e'), backgroundColor: AppTheme.crimson),
                                  );
                                }
                              } finally {
                                setDState(() => isExtracting = false);
                              }
                            },
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('رفع مستند PDF / Excel / Word'),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'xlsx', 'xls', 'docx', 'doc', 'png', 'jpg', 'jpeg', 'txt'],
                          withData: true,
                        );
                        if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
                        final file = result.files.first;

                        setDState(() => isExtracting = true);
                        try {
                          final dio = Dio();
                          final formData = FormData.fromMap({
                            'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
                          });
                          final resp = await dio.post(
                            '${ApiConstants.baseUrl}/smart-upload/parse/clearance-quotation',
                            data: formData,
                          );
                          if (resp.statusCode == 200 && resp.data != null) {
                            setDState(() {
                              extractedResult = resp.data['extracted_fields'] as Map<String, dynamic>?;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ في رفع الملف: $e'), backgroundColor: AppTheme.crimson),
                            );
                          }
                        } finally {
                          setDState(() => isExtracting = false);
                        }
                      },
                    ),
                  ],
                ),
                if (extractedResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.emerald),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المخلص المستخرج: ${extractedResult!['broker_name'] ?? 'مكتب تخليص'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('الميناء: ${extractedResult!['port_name'] ?? '-'} | الحاوية: ${extractedResult!['container_type'] ?? '-'}'),
                            Text('إجمالي التكلفة المقدرة: ${extractedResult!['total_estimated_clearance_cost']} EGP', style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check),
                          label: const Text('تطبيق وإضافة العرض'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final rfqs = ref.read(customsClearanceQuotationsProvider).value ?? [];
                            final rfqId = targetRfqId ?? (rfqs.isNotEmpty ? rfqs.first.rfqId : null);
                            if (rfqId != null) {
                              _showAddQuotationDialog(rfqId, prefill: extractedResult);
                            } else {
                              _showCreateRFQDialog();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text('إغلاق'), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPriceItemDialog() async {
    final formKey = GlobalKey<FormState>();
    final partners = ref.read(partnersProvider).value?.where((p) => p.partnerType == 'Customs Broker' || p.partnerType == 'Freight Forwarder').toList() ?? [];
    final locations = ref.read(transportLocationsProvider).value ?? [];

    int selectedProviderId = partners.isNotEmpty ? partners.first.partnerId! : 1;
    String selectedProviderName = partners.isNotEmpty ? partners.first.partnerName : 'مكتب تخليص';
    String portName = locations.isNotEmpty ? locations.first.locationName : 'Alexandria Port (ميناء الإسكندرية)';
    String category = 'Clearance Fee (أتعاب التخليص)';
    String containerType = '40HQ';
    final priceCtrl = TextEditingController(text: '3500');
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة بند لقائمة أسعار التخليص'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<int>(
                    value: selectedProviderId,
                    labelText: 'المخلص الجمركي *',
                    items: partners.map((p) => SearchableDropdownItem<int>(value: p.partnerId!, label: p.partnerName)).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDState(() {
                          selectedProviderId = val;
                          final m = partners.where((p) => p.partnerId == val).firstOrNull;
                          if (m != null) selectedProviderName = m.partnerName;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdownField<String>(
                    value: portName,
                    labelText: 'الميناء *',
                    items: locations.map((l) => SearchableDropdownItem<String>(value: l.locationName, label: l.locationName)).toList(),
                    onChanged: (val) {
                      if (val != null) setDState(() => portName = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'نوع بند الخدمة *'),
                    items: const [
                      DropdownMenuItem(value: 'Clearance Fee (أتعاب التخليص)', child: Text('Clearance Fee (أتعاب التخليص)')),
                      DropdownMenuItem(value: 'Inland Transport (النقل الداخلي)', child: Text('Inland Transport (النقل الداخلي)')),
                      DropdownMenuItem(value: 'Inspection Fee (فحص وعرض)', child: Text('Inspection Fee (فحص وعرض)')),
                      DropdownMenuItem(value: 'Port Charges (رسوم موانئ)', child: Text('Port Charges (رسوم موانئ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: containerType,
                          decoration: const InputDecoration(labelText: 'نوع الحاوية *'),
                          items: const [
                            DropdownMenuItem(value: '40HQ', child: Text('40HQ')),
                            DropdownMenuItem(value: '40GP', child: Text('40GP')),
                            DropdownMenuItem(value: '20GP', child: Text('20GP')),
                            DropdownMenuItem(value: 'LCL', child: Text('LCL')),
                            DropdownMenuItem(value: 'Air', child: Text('Air')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDState(() => containerType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(labelText: 'السعر المعياري (EGP) *'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'السعر مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(child: const Text('إلغاء'), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              child: const Text('حفظ البند'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newItem = ClearancePriceListItemModel(
                  priceItemId: 0,
                  providerId: selectedProviderId,
                  providerName: selectedProviderName,
                  portName: portName,
                  serviceCategory: category,
                  containerType: containerType,
                  unitPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                  currency: 'EGP',
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                );

                await ref.read(clearancePriceListProvider.notifier).createPriceItem(newItem);
                if (mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _awardQuotation(int rfqId, int quotationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppTheme.emerald),
            SizedBox(width: 8),
            Text('تأكيد اعتماد وترسية التخليص الجمركي'),
          ],
        ),
        content: const Text('هل أنت متأكد من رغبتك في اعتماد وترسية هذا العرض وتثبيته في منظومة تكاليف الشحنة؟'),
        actions: [
          TextButton(child: const Text('إلغاء'), onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            child: const Text('نعم، اعتماد العرض'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(customsClearanceQuotationsProvider.notifier).awardQuotation(rfqId, quotationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم اعتماد وترسية عرض التخليص الجمركي بنجاح!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuotation(int quotationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا العرض من المقارنة؟'),
        actions: [
          TextButton(child: const Text('إلغاء'), onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
            child: const Text('حذف'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(customsClearanceQuotationsProvider.notifier).deleteQuotation(quotationId);
    }
  }
}
