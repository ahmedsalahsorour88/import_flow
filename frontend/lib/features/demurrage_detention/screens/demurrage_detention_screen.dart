import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/demurrage_model.dart';
import '../providers/demurrage_provider.dart';

class DemurrageDetentionScreen extends ConsumerStatefulWidget {
  const DemurrageDetentionScreen({super.key});

  @override
  ConsumerState<DemurrageDetentionScreen> createState() => _DemurrageDetentionScreenState();
}

class _DemurrageDetentionScreenState extends ConsumerState<DemurrageDetentionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  // Simulator Controllers
  final _simFormKey = GlobalKey<FormState>();
  String _simCarrier = 'MSC';
  String _simContainerType = '40ft High Cube';
  int _simContainersCount = 1;
  int _simDemFreeDays = 14;
  int _simDetFreeDays = 7;
  final int _simStorageFreeDays = 5;
  double _simExchangeRate = 50.0;
  DateTime _simDischargeDate = DateTime.now().subtract(const Duration(days: 16));
  DateTime? _simGateOutDate;
  DateTime? _simEmptyReturnDate;
  bool _isSimulating = false;

  final List<String> _carriersList = [
    'MSC',
    'Maersk',
    'CMA CGM',
    'COSCO',
    'Hapag-Lloyd',
    'ONE',
    'Evergreen',
    'Yang Ming',
  ];

  final List<String> _containerTypesList = [
    '20ft Standard',
    '40ft Standard',
    '40ft High Cube',
    '20ft Reefer',
    '40ft Reefer',
    '45ft High Cube',
  ];

  final List<String> _portsList = [
    'Alexandria Port',
    'Dekheila Port',
    'Damietta Port',
    'Port Said East',
    'Port Said West',
    'Sokhna Port',
    'Adabiya Port',
    'Cairo Dry Port (6th of October)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(demurrageProvider.notifier).loadInitialData();
      _runQuickSimulation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _runQuickSimulation() {
    setState(() => _isSimulating = true);
    final payload = {
      'carrier_name': _simCarrier,
      'container_type': _simContainerType,
      'containers_count': _simContainersCount,
      'demurrage_free_days': _simDemFreeDays,
      'detention_free_days': _simDetFreeDays,
      'port_storage_free_days': _simStorageFreeDays,
      'discharge_date': _formatDate(_simDischargeDate),
      if (_simGateOutDate != null) 'gate_out_date': _formatDate(_simGateOutDate!),
      if (_simEmptyReturnDate != null) 'empty_return_date': _formatDate(_simEmptyReturnDate!),
      'calculation_date': _formatDate(DateTime.now()),
      'currency': 'USD',
      'exchange_rate': _simExchangeRate,
    };

    ref.read(demurrageProvider.notifier).simulateCalculation(payload).then((_) {
      if (mounted) setState(() => _isSimulating = false);
    }).catchError((_) {
      if (mounted) setState(() => _isSimulating = false);
    });
  }

  String _formatDate(DateTime dt) => dt.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demurrageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'حاسبة ومتابعة فترات السماح وغرامات الحاويات والأرضيات (Demurrage & Detention)',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        actions: const [
          BackToDashboardButton(),
          SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'جلسات تتبع الحاويات الحية'),
            Tab(icon: Icon(Icons.calculate_outlined), text: 'محاكي وحاسبة الشرائح التصاعدية'),
            Tab(icon: Icon(Icons.policy_outlined), text: 'سياسات تعريفة الخطوط الملاحية'),
          ],
        ),
      ),
      body: state.isLoading && state.trackings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrackingsTab(state),
                _buildSimulatorTab(state),
                _buildPoliciesTab(state),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1: ACTIVE CONTAINER TRACKINGS
  // ===========================================================================
  Widget _buildTrackingsTab(DemurrageState state) {
    final filteredTrackings = state.trackings.where((t) {
      final matchesSearch = t.trackingCode.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          t.billOfLadingNo.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          t.carrierName.toLowerCase().contains(_searchController.text.toLowerCase());
      if (_selectedStatusFilter == 'All') return matchesSearch;
      return matchesSearch && t.status == _selectedStatusFilter;
    }).toList();

    final totalDemurrageEgp = state.trackings.fold<double>(0.0, (sum, t) => sum + t.totalCostEgp);
    final incurredCount = state.trackings.where((t) => t.status.contains('Incurred')).length;
    final activeCount = state.trackings.length;

    return RefreshIndicator(
      onRefresh: () => ref.read(demurrageProvider.notifier).loadInitialData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                _buildKpiCard(
                  'إجمالي الجلسات النشطة',
                  '$activeCount شحنة',
                  Icons.all_inbox_rounded,
                  AppTheme.cobalt,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  'شحنات بها غرامات سارية',
                  '$incurredCount شحنة',
                  Icons.warning_amber_rounded,
                  AppTheme.crimson,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  'إجمالي الغرامات المحسوبة',
                  '${totalDemurrageEgp.toStringAsFixed(0)} ج.م',
                  Icons.attach_money_rounded,
                  AppTheme.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Toolbar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'بحث برقم البوليصة أو كود التتبع أو الخط الملاحي...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: InputDecoration(
                          labelText: 'تصفية بالحالة',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                          DropdownMenuItem(value: 'Free Time Active', child: Text('فترة السماح سارية')),
                          DropdownMenuItem(value: 'Demurrage Incurred', child: Text('غرامة أرضيات سارية')),
                          DropdownMenuItem(value: 'Detention Incurred', child: Text('غرامة تأخير فارغ')),
                          DropdownMenuItem(value: 'Pushed to Settlement', child: Text('تم الترحيل للتسوية')),
                        ],
                        onChanged: (v) => setState(() => _selectedStatusFilter = v ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTrackingDialog(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('بدء تتبع شحنة جديدة', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trackings List / Table
            if (filteredTrackings.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('لا توجد جلسات تتبع مطابقة للبحث', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTrackings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _buildTrackingCard(filteredTrackings[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(DemurrageTrackingModel item) {
    Color statusColor = AppTheme.emerald;
    if (item.status.contains('Demurrage') || item.status.contains('Detention')) {
      statusColor = AppTheme.crimson;
    } else if (item.isPushedToSettlement) {
      statusColor = AppTheme.cobalt;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.trackingCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'بوليصة: ${item.billOfLadingNo}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Text('(${item.carrierName} - ${item.portName})', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn('تاريخ التفريغ (Discharge)', item.dischargeDate),
                ),
                Expanded(
                  child: _buildInfoColumn('خروج الميناء (Gate-Out)', item.gateOutDate ?? 'لم تخرج بعد'),
                ),
                Expanded(
                  child: _buildInfoColumn('إعادة الفارغ (Return)', item.emptyReturnDate ?? 'لم تُعد بعد'),
                ),
                Expanded(
                  child: _buildInfoColumn('عدد الحاويات', '${item.containers.length} حاوية'),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'إجمالي التكلفة التقديرية',
                    '${item.totalCostEgp.toStringAsFixed(2)} ج.م',
                    valueColor: item.totalCostEgp > 0 ? AppTheme.crimson : AppTheme.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showUpdateDatesDialog(context, item),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                  label: const Text('تحديث تواريخ الخروج والإعادة'),
                ),
                const SizedBox(width: 8),
                if (!item.isPushedToSettlement)
                  ElevatedButton.icon(
                    onPressed: () => _handlePushToSettlement(item),
                    icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
                    label: const Text('ترحيل للتسوية المالية (Landed Cost)', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('تم ترحيل المصروف للتسوية'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.charcoal, fontSize: 14),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: INTERACTIVE SIMULATOR & TIER CALCULATOR
  // ===========================================================================
  Widget _buildSimulatorTab(DemurrageState state) {
    final res = state.simulationResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Panel
          Expanded(
            flex: 5,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _simFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إعدادات ومحددات الحساب',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdownField<String>(
                        labelText: 'الخط الملاحي',
                        value: _simCarrier,
                        items: _carriersList
                            .map((c) => SearchableDropdownItem(value: c, label: c))
                            .toList(),
                        onChanged: (c) {
                          if (c != null) {
                            setState(() => _simCarrier = c);
                            _runQuickSimulation();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SearchableDropdownField<String>(
                        labelText: 'نوع الحاوية',
                        value: _simContainerType,
                        items: _containerTypesList
                            .map((t) => SearchableDropdownItem(value: t, label: t))
                            .toList(),
                        onChanged: (t) {
                          if (t != null) {
                            setState(() => _simContainerType = t);
                            _runQuickSimulation();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _simContainersCount.toString(),
                              decoration: const InputDecoration(labelText: 'عدد الحاويات', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'مطلوب' : null,
                              onChanged: (v) {
                                _simContainersCount = int.tryParse(v) ?? 1;
                                _runQuickSimulation();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _simExchangeRate.toString(),
                              decoration: const InputDecoration(labelText: 'سعر الصرف (ج.م/USD)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'مطلوب' : null,
                              onChanged: (v) {
                                _simExchangeRate = double.tryParse(v) ?? 50.0;
                                _runQuickSimulation();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('فترات السماح الممنوحة (Free Days)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _simDemFreeDays.toString(),
                              decoration: const InputDecoration(labelText: 'سماح الأرضيات بالميناء (يوم)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                _simDemFreeDays = int.tryParse(v) ?? 14;
                                _runQuickSimulation();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _simDetFreeDays.toString(),
                              decoration: const InputDecoration(labelText: 'سماح إعادة الفارغ (يوم)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                _simDetFreeDays = int.tryParse(v) ?? 7;
                                _runQuickSimulation();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('المحطات الزمنية (Operational Milestones)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        leading: const Icon(Icons.date_range, color: AppTheme.cobalt),
                        title: const Text('تاريخ تفريغ الحاويات من السفينة (Discharge)'),
                        subtitle: Text(_formatDate(_simDischargeDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _simDischargeDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _simDischargeDate = picked);
                            _runQuickSimulation();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        leading: const Icon(Icons.output_rounded, color: AppTheme.orange),
                        title: const Text('تاريخ خروج الحاوية من بوابة الميناء (Gate-Out)'),
                        subtitle: Text(_simGateOutDate != null ? _formatDate(_simGateOutDate!) : 'لم تخرج بعد (تحتسب حتى اليوم)'),
                        trailing: _simGateOutDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() => _simGateOutDate = null);
                                  _runQuickSimulation();
                                },
                              )
                            : const Icon(Icons.edit, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _simGateOutDate ?? _simDischargeDate,
                            firstDate: _simDischargeDate,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _simGateOutDate = picked);
                            _runQuickSimulation();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        leading: const Icon(Icons.keyboard_return_rounded, color: AppTheme.emerald),
                        title: const Text('تاريخ إعادة الحاوية الفارغة لساحة الخط (Return)'),
                        subtitle: Text(_simEmptyReturnDate != null ? _formatDate(_simEmptyReturnDate!) : 'لم تُعد بعد'),
                        trailing: _simEmptyReturnDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() => _simEmptyReturnDate = null);
                                  _runQuickSimulation();
                                },
                              )
                            : const Icon(Icons.edit, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _simEmptyReturnDate ?? (_simGateOutDate ?? _simDischargeDate),
                            firstDate: _simGateOutDate ?? _simDischargeDate,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _simEmptyReturnDate = picked);
                            _runQuickSimulation();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSimulating ? null : _runQuickSimulation,
                          icon: _isSimulating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('إعادة احتساب الغرامات الآن', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.charcoal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Result & Breakdown Panel
          Expanded(
            flex: 6,
            child: res == null
                ? const Center(child: Text('جاري تهيئة نتائج المحاكاة...'))
                : Column(
                    children: [
                      // Status Badge Alert
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusBadgeColor(res.statusBadge).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getStatusBadgeColor(res.statusBadge)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              res.statusBadge == 'SAFE'
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: _getStatusBadgeColor(res.statusBadge),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                res.countdownSummaryAr,
                                style: TextStyle(
                                  color: _getStatusBadgeColor(res.statusBadge),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cost Summary Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ملخص التكلفة الإجمالية للغرامات والأرضيات', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCostMetricCard(
                                      'غرامة أرضيات (Demurrage)',
                                      '${res.demurrageFeeFx.toStringAsFixed(2)} \$',
                                      '${res.demurrageDaysOverdue} يوم تأخير',
                                      AppTheme.crimson,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCostMetricCard(
                                      'غرامة تأخير فارغ (Detention)',
                                      '${res.detentionFeeFx.toStringAsFixed(2)} \$',
                                      '${res.detentionDaysOverdue} يوم تأخير',
                                      AppTheme.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCostMetricCard(
                                      'أرضيات الميناء (Storage)',
                                      '${res.storageFeeEgp.toStringAsFixed(2)} ج.م',
                                      '${res.storageDaysOverdue} يوم تأخير',
                                      AppTheme.cobalt,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('إجمالي التكلفة الشاملة المستحقة (Total EGP):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(
                                    '${res.totalCostEgp.toStringAsFixed(2)} جنيه مصري',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Itemized Breakdown Table
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تفاصيل الشرائح التصاعدية المطبقة (Tiered Breakdown)', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              DataTable(
                                columns: const [
                                  DataColumn(label: Text('البند')),
                                  DataColumn(label: Text('الأيام المستهلكة')),
                                  DataColumn(label: Text('أيام السماح')),
                                  DataColumn(label: Text('أيام الغرامة')),
                                  DataColumn(label: Text('قيمة الغرامة')),
                                ],
                                rows: res.breakdownDetails.map((b) {
                                  return DataRow(cells: [
                                    DataCell(Text(b['category']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text('${b['days_consumed']} يوم')),
                                    DataCell(Text('${b['free_days']} يوم')),
                                    DataCell(Text('${b['days_overdue']} يوم')),
                                    DataCell(Text(
                                      b['currency'] == 'EGP'
                                          ? '${b['fee_egp']} ج.م'
                                          : '${b['fee_fx']} ${b['currency']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: (b['days_overdue'] ?? 0) > 0 ? AppTheme.crimson : AppTheme.emerald,
                                      ),
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBadgeColor(String badge) {
    switch (badge) {
      case 'SAFE':
        return AppTheme.emerald;
      case 'WARNING':
        return AppTheme.orange;
      case 'DEMURRAGE_INCURRED':
      case 'DETENTION_INCURRED':
      case 'DEMURRAGE_AND_DETENTION_INCURRED':
      default:
        return AppTheme.crimson;
    }
  }

  Widget _buildCostMetricCard(String title, String amount, String days, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(days, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CARRIER TARIFF POLICIES
  // ===========================================================================
  Widget _buildPoliciesTab(DemurrageState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                    'سياسات وشرائح الخطوط الملاحية المعتمدة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                  ),
                  SizedBox(height: 4),
                  Text('جداول فترات السماح المتفق عليها والشرائح اليومية التصاعدية لكل خط ملاحي ونوع حاوية', style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPolicyDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة سياسة خط ملاحي جديدة', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.policies.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Text('لا توجد سياسات مضافة حالياً. يمكنك الضغط على "إضافة سياسة جديدة" أو استخدام السياسات الافتراضية.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.policies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final p = state.policies[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${p.carrierName} - ${p.containerType}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                            Text('العملة: ${p.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildInfoColumn('سماح الأرضيات', '${p.demurrageFreeDays} يوم')),
                            Expanded(child: _buildInfoColumn('سماح الفارغ', '${p.detentionFreeDays} يوم')),
                            Expanded(child: _buildInfoColumn('سماح تخزين الميناء', '${p.portStorageFreeDays} يوم')),
                            Expanded(child: _buildInfoColumn('رسم التخزين اليومي', '${p.portStorageDailyRateEgp} ج.م/يوم')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIALOGS & ACTIONS
  // ===========================================================================
  void _showAddTrackingDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String carrier = _carriersList.first;
    String port = _portsList.first;
    String blNo = '';
    String cNo = '';
    String cType = _containerTypesList.first;
    DateTime dischargeDate = DateTime.now().subtract(const Duration(days: 5));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('بدء تتبع شحنة وحاويات جديدة'),
          content: SizedBox(
            width: 550,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SearchableDropdownField<String>(
                      labelText: 'الخط الملاحي',
                      value: carrier,
                      items: _carriersList
                          .map((c) => SearchableDropdownItem(value: c, label: c))
                          .toList(),
                      onChanged: (c) => setDialogState(() => carrier = c ?? carrier),
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<String>(
                      labelText: 'ميناء الوصول',
                      value: port,
                      items: _portsList
                          .map((p) => SearchableDropdownItem(value: p, label: p))
                          .toList(),
                      onChanged: (p) => setDialogState(() => port = p ?? port),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'رقم بوليصة الشحن (B/L No)', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      onSaved: (v) => blNo = v ?? '',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'رقم الحاوية (مثال: MSCU1234567)', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                            onSaved: (v) => cNo = v ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SearchableDropdownField<String>(
                            labelText: 'نوع الحاوية',
                            value: cType,
                            items: _containerTypesList
                                .map((t) => SearchableDropdownItem(value: t, label: t))
                                .toList(),
                            onChanged: (t) => setDialogState(() => cType = t ?? cType),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      leading: const Icon(Icons.calendar_today, color: AppTheme.cobalt),
                      title: const Text('تاريخ تفريغ الحاويات بالميناء'),
                      subtitle: Text(_formatDate(dischargeDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dischargeDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => dischargeDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      formKey.currentState!.save();
                      setDialogState(() => isSaving = true);

                      final success = await ref.read(demurrageProvider.notifier).createTracking({
                        'carrier_name': carrier,
                        'port_name': port,
                        'bill_of_lading_no': blNo,
                        'discharge_date': _formatDate(dischargeDate),
                        'containers': [
                          {'container_no': cNo, 'container_type': cType}
                        ],
                        'currency': 'USD',
                        'exchange_rate': 50.0,
                      });

                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'تم بدء تتبع الشحنة بنجاح' : 'حدث خطأ أثناء الحفظ'),
                          backgroundColor: success ? AppTheme.emerald : AppTheme.crimson,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ وبدء التتبع', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDatesDialog(BuildContext context, DemurrageTrackingModel item) {
    DateTime? gateOut = item.gateOutDate != null ? DateTime.tryParse(item.gateOutDate!) : null;
    DateTime? emptyReturn = item.emptyReturnDate != null ? DateTime.tryParse(item.emptyReturnDate!) : null;
    final discharge = DateTime.tryParse(item.dischargeDate) ?? DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('تحديث تواريخ الشحنة (${item.trackingCode})'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const Icon(Icons.output, color: AppTheme.orange),
                  title: const Text('تاريخ خروج الحاوية من الميناء (Gate-Out)'),
                  subtitle: Text(gateOut != null ? _formatDate(gateOut!) : 'غير مسجل'),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: gateOut ?? discharge,
                      firstDate: discharge,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => gateOut = picked);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const Icon(Icons.keyboard_return, color: AppTheme.emerald),
                  title: const Text('تاريخ إعادة الحاوية الفارغة للخط (Return)'),
                  subtitle: Text(emptyReturn != null ? _formatDate(emptyReturn!) : 'غير مسجل'),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: emptyReturn ?? (gateOut ?? discharge),
                      firstDate: gateOut ?? discharge,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => emptyReturn = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final ok = await ref.read(demurrageProvider.notifier).updateTrackingDates(
                            item.trackingId,
                            gateOutDate: gateOut != null ? _formatDate(gateOut!) : null,
                            emptyReturnDate: emptyReturn != null ? _formatDate(emptyReturn!) : null,
                          );
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'تم تحديث التواريخ وإعادة احتساب الغرامات' : 'حدث خطأ أثناء التحديث'),
                          backgroundColor: ok ? AppTheme.emerald : AppTheme.crimson,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              child: const Text('حفظ وإعادة الاحتساب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePushToSettlement(DemurrageTrackingModel item) async {
    final res = await ref.read(demurrageProvider.notifier).pushToSettlement(
          item.trackingId,
          importFileId: item.importFileId ?? 1,
        );
    if (!mounted) return;
    if (res != null && res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'تم ترحيل المصروف بنجاح إلى ملف التسوية المالية'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الترحيل'), backgroundColor: AppTheme.crimson),
      );
    }
  }

  void _showAddPolicyDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String carrier = _carriersList.first;
    String cType = _containerTypesList.first;
    int demFree = 14;
    int detFree = 7;
    int storFree = 5;
    double storRate = 250.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة سياسة خط ملاحي جديدة'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<String>(
                    labelText: 'الخط الملاحي',
                    value: carrier,
                    items: _carriersList
                        .map((c) => SearchableDropdownItem(value: c, label: c))
                        .toList(),
                    onChanged: (c) => setDialogState(() => carrier = c ?? carrier),
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdownField<String>(
                    labelText: 'نوع الحاوية',
                    value: cType,
                    items: _containerTypesList
                        .map((t) => SearchableDropdownItem(value: t, label: t))
                        .toList(),
                    onChanged: (t) => setDialogState(() => cType = t ?? cType),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: demFree.toString(),
                          decoration: const InputDecoration(labelText: 'سماح الأرضيات (يوم)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => demFree = int.tryParse(v ?? '') ?? 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: detFree.toString(),
                          decoration: const InputDecoration(labelText: 'سماح الفارغ (يوم)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => detFree = int.tryParse(v ?? '') ?? 7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: storFree.toString(),
                          decoration: const InputDecoration(labelText: 'سماح تخزين الميناء (يوم)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => storFree = int.tryParse(v ?? '') ?? 5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: storRate.toString(),
                          decoration: const InputDecoration(labelText: 'رسم التخزين اليومي (ج.م)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => storRate = double.tryParse(v ?? '') ?? 250.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                final ok = await ref.read(demurrageProvider.notifier).createPolicy({
                  'carrier_name': carrier,
                  'container_type': cType,
                  'demurrage_free_days': demFree,
                  'detention_free_days': detFree,
                  'port_storage_free_days': storFree,
                  'port_storage_daily_rate_egp': storRate,
                  'currency': 'USD',
                });
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'تمت إضافة السياسة بنجاح' : 'حدث خطأ'),
                    backgroundColor: ok ? AppTheme.emerald : AppTheme.crimson,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              child: const Text('حفظ السياسة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
