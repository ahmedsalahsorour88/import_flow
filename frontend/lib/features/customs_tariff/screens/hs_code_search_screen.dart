import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';

double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

int _numToInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

class HsCodeSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const HsCodeSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<HsCodeSearchScreen> createState() => _HsCodeSearchScreenState();
}

class _HsCodeSearchScreenState extends ConsumerState<HsCodeSearchScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _searchCtrl;
  CustomsTariffModel? _selectedTariff;
  late TabController _tabController;

  // Duty Estimator for Selected HS Code
  final _cifValueCtrl = TextEditingController(text: '10000');
  final _freightCtrl = TextEditingController(text: '1000');
  String _selectedOriginCountry = 'ITALY';
  CustomsDutyBreakdownModel? _dutyBreakdown;
  bool _isCalculating = false;

  final List<String> _quickQueries = [
    '8415820010',
    '3925900090',
    '0202300000',
    '1001990000',
    '1507100000',
    '1701999000',
    'تكييف',
    'لدائن',
    'لحوم',
    'قمح',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    _cifValueCtrl.dispose();
    _freightCtrl.dispose();
    super.dispose();
  }

  void _calculateDuty(CustomsTariffModel tariff) async {
    final cif = double.tryParse(_cifValueCtrl.text.trim()) ?? 0.0;
    final freight = double.tryParse(_freightCtrl.text.trim()) ?? 0.0;
    if (cif <= 0) return;

    setState(() => _isCalculating = true);
    try {
      final breakdown = await ref.read(customsTariffProvider.notifier).estimateDuty(
            hsCode: tariff.hsCode,
            cifValue: cif,
            freight: freight,
            originCountry: _selectedOriginCountry,
          );
      setState(() {
        _dutyBreakdown = breakdown;
        _isCalculating = false;
      });
    } catch (_) {
      setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tariffsAsync = ref.watch(customsTariffProvider);
    final allTariffs = tariffsAsync.value ?? [];

    final query = _searchCtrl.text.trim().toLowerCase().replaceAll('.', '');
    final filtered = query.isEmpty
        ? allTariffs
        : allTariffs.where((t) {
            final hsClean = t.hsCode.toLowerCase().replaceAll('.', '');
            final desc = t.hsDescription.toLowerCase();
            final cat = (t.customsCategory ?? '').toLowerCase();
            final auth = (t.regulatoryAuthority ?? '').toLowerCase();
            final note = (t.priorApprovalNote ?? '').toLowerCase();
            return hsClean.contains(query) ||
                desc.contains(query) ||
                cat.contains(query) ||
                auth.contains(query) ||
                note.contains(query);
          }).toList();

    // Auto-select first item if current selection is not in filtered list
    if (_selectedTariff == null && filtered.isNotEmpty) {
      _selectedTariff = filtered.first;
    } else if (_selectedTariff != null && !filtered.any((t) => t.tariffId == _selectedTariff!.tariffId)) {
      _selectedTariff = filtered.isNotEmpty ? filtered.first : null;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.saved_search, color: AppTheme.cobalt, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'محرك البحث الجمركي الشامل وتاريخ البند (HS Code Explorer & Updates)',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'استعلام لحظي عن بنود التعريفة الجمركية المصرية، الضرائب، الاتفاقيات التفضيلية، الاشتراطات الرقابية وسجل التعديلات.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                BackToDashboardButton(),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'ابحث برقم البند (HS Code) أو الوصف أو التصنيف أو كود المنشور (مثل: 8415820010، تكييف، ر6663)...',
                            prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'أمثلة سريعة للبحث:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _quickQueries.map((q) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(q, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: _searchCtrl.text == q
                                      ? AppTheme.cobalt.withOpacity(0.15)
                                      : Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color: _searchCtrl.text == q ? AppTheme.cobalt : Colors.black87,
                                    fontWeight: _searchCtrl.text == q ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.text = q;
                                    setState(() {});
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area: Left Master List / Right Detail 360° Explorer
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left List of Matching Tariffs
                  Container(
                    width: 340,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'نتائج البنود المطابقة',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.cobalt.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${filtered.length} بند',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.cobalt),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'لا يوجد بند يطابق "${_searchCtrl.text}"',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, idx) {
                                    final item = filtered[idx];
                                    final isSelected = _selectedTariff?.tariffId == item.tariffId;

                                    return ListTile(
                                      selected: isSelected,
                                      selectedTileColor: AppTheme.cobalt.withOpacity(0.08),
                                      title: Text(
                                        item.hsCode,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected ? AppTheme.cobalt : AppTheme.charcoal,
                                        ),
                                      ),
                                      subtitle: Text(
                                        item.hsDescription,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Text(
                                          'وارد: ${item.customsDutyRate}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedTariff = item;
                                          _dutyBreakdown = null;
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right 360° Detail & Updates Explorer
                  Expanded(
                    child: _selectedTariff == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('اختر بنداً جمركياً من القائمة لمعاينة تفاصيله الشاملة وسجل تحديثاته'),
                              ],
                            ),
                          )
                        : _buildDetailedExplorer(_selectedTariff!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedExplorer(CustomsTariffModel tariff) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.charcoal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tariff.hsCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tariff.hsDescription,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (tariff.customsCategory != null) ...[
                            Text(
                              'التصنيف: ${tariff.customsCategory}',
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            'ساري من: ${tariff.effectiveFrom.toIso8601String().split('T').first} ${tariff.effectiveTo != null ? "إلى ${tariff.effectiveTo!.toIso8601String().split('T').first}" : "(سجل معتمد)"}',
                            style: const TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _tabController.animateTo(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_edu, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'تحليل الاختلافات والتاريخ ➔',
                          style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.grey.shade100,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.cobalt,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: AppTheme.cobalt,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.calculate_outlined, size: 18), text: 'الضرائب والرسوم'),
                Tab(icon: Icon(Icons.public_outlined, size: 18), text: 'الاتفاقيات التفضيلية'),
                Tab(icon: Icon(Icons.account_balance_outlined, size: 18), text: 'الاشتراطات الرقابية'),
                Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: 'سجل التحديثات والتاريخ'),
                Tab(icon: Icon(Icons.point_of_sale_outlined, size: 18), text: 'حاسبة فورية للبند'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaxRatesTab(tariff),
                _buildAgreementsTab(tariff),
                _buildRegulatoryTab(tariff),
                _buildHistoryTab(tariff),
                _buildQuickCalculatorTab(tariff),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(CustomsTariffModel tariff) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(customsTariffProvider.notifier).fetchTariffHistory(tariff.hsCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cobalt));
        }

        final data = snapshot.data;
        final versions = (data?['versions'] as List?) ?? [];
        final auditLogs = (data?['audit_logs'] as List?) ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppTheme.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجل التعديلات والإصدارات التاريخية للبند الجمركي (${tariff.hsCode})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            versions.length > 1
                                ? 'يحتوي هذا البند على (${versions.length}) إصدارات تاريخية مسجلة بفترات سريان مختلفة.'
                                : 'البند معتمد بإصداره الأساسي الساري حالياً، ومسجل بنظام الحماية التاريخية من التعديل العشوائي.',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Text(
                        '${versions.length} إصدارات',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Version Timeline
              const Text(
                '📅 جدول الفترات وسريان الإصدارات (Tariff Versions Timeline):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 10),

              if (versions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text('لا توجد سجلات إصدارات سابقة مسجلة.'),
                  ),
                )
              else
                ...versions.map((ver) {
                  final isActive = ver['is_current_active'] == true;
                  final effFrom = ver['effective_from'] ?? '—';
                  final effTo = ver['effective_to'] ?? 'الآن (مستمر)';
                  final duty = ver['customs_duty_rate'] ?? 0.0;
                  final vat = ver['vat_rate'] ?? 0.0;
                  final sched = ver['schedule_tax_rate'] ?? 0.0;
                  final dev = ver['development_fee_rate'] ?? 0.0;
                  final agCount = ver['agreements_count'] ?? 0;
                  final createdAt = ver['created_at'] != null ? ver['created_at'].toString().split('T').first : '—';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isActive ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isActive ? AppTheme.emerald : Colors.grey.shade300,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    color: isActive ? Colors.white : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.check_circle : Icons.history_toggle_off,
                                    color: isActive ? AppTheme.emerald : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? 'الإصدار الحالي الساري (Active Live Version)' : 'إصدار تاريخي سابق (Archived Snapshot)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isActive ? AppTheme.emerald : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'تاريخ التسجيل: $createdAt',
                                  style: TextStyle(fontSize: 10, color: isActive ? Colors.green.shade800 : Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'فترة السريان والتطبيق: من $effFrom حتى $effTo',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الوصف المعتمد: ${ver['hs_description'] ?? '—'}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Chip(
                                label: Text('ضريبة الوارد: $duty%'),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Chip(
                                label: Text('القيمة المضافة: $vat%'),
                                backgroundColor: Colors.green.shade50,
                                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              if (sched > 0)
                                Chip(
                                  label: Text('ضريبة الجدول: $sched%'),
                                  backgroundColor: Colors.purple.shade50,
                                  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              if (dev > 0)
                                Chip(
                                  label: Text('رسم التنمية: $dev%'),
                                  backgroundColor: Colors.orange.shade50,
                                  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              Chip(
                                label: Text('الاتفاقيات المربوطة: $agCount'),
                                backgroundColor: Colors.teal.shade50,
                                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              // Section 1.5: Comparative Version Diffs Timeline
              if (versions.length > 1) ...[
                const SizedBox(height: 16),
                const Text(
                  '🔄 ملخص التغيرات بين الإصدارات التاريخية (Version Evolution & Diffs):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  List<Widget> diffWidgets = [];
                  for (int i = 0; i < versions.length - 1; i++) {
                    final newer = versions[i];
                    final older = versions[i + 1];

                    final newerDate = newer['effective_from'] ?? 'اليوم';
                    final olderDate = older['effective_from'] ?? 'البداية';

                    final nDuty = _numToDouble(newer['customs_duty_rate']);
                    final oDuty = _numToDouble(older['customs_duty_rate']);

                    final nVat = _numToDouble(newer['vat_rate']);
                    final oVat = _numToDouble(older['vat_rate']);

                    final nSched = _numToDouble(newer['schedule_tax_rate']);
                    final oSched = _numToDouble(older['schedule_tax_rate']);

                    final nAg = _numToInt(newer['agreements_count']);
                    final oAg = _numToInt(older['agreements_count']);

                    List<String> changeDetails = [];
                    if (nDuty != oDuty) {
                      changeDetails.add('ضريبة الوارد: تغيرت من $oDuty% إلى $nDuty%');
                    }
                    if (nVat != oVat) {
                      changeDetails.add('ضريبة القيمة المضافة: تغيرت من $oVat% إلى $nVat%');
                    }
                    if (nSched != oSched) {
                      changeDetails.add('ضريبة الجدول: تغيرت من $oSched% إلى $nSched%');
                    }
                    if (nAg != oAg) {
                      changeDetails.add('الاتفاقيات التفضيلية: تغير عدد الاتفاقيات من $oAg إلى $nAg اتفاقية');
                    }
                    if (changeDetails.isEmpty) {
                      changeDetails.add('تحديث بيانات وصفية وجهات رقابية واشتراطات مستندية للبند');
                    }

                    diffWidgets.add(
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.compare_arrows, color: AppTheme.cobalt, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'التعديل التاريخي: من إصدار ($olderDate) ➔ إلى إصدار ($newerDate)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...changeDetails.map((detail) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                      Expanded(
                                        child: Text(
                                          detail,
                                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(children: diffWidgets);
                }),
              ],

              const SizedBox(height: 20),

              // Section 2: Audit Logs Trail
              const Text(
                '🛡️ سجل تدقيق العمليات والتغييرات (System Audit Trail):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 10),

              if (auditLogs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text('لم تسجل عمليات تدقيق مباشرة بعد (البيانات منشأة آلياً).'),
                  ),
                )
              else
                ...auditLogs.map((log) {
                  final action = log['action'] ?? 'ACTIVITY';
                  final performedBy = log['performed_by'] ?? 'System';
                  final createdAt = log['created_at'] != null ? log['created_at'].toString().replaceFirst('T', ' ') : '—';
                  final summary = log['changes_summary'] ?? 'تم تنفيذ العملية';

                  Color actionColor = AppTheme.cobalt;
                  if (action == 'CREATE') actionColor = AppTheme.emerald;
                  if (action == 'UPDATE') actionColor = AppTheme.orange;
                  if (action == 'DELETE') actionColor = AppTheme.crimson;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: actionColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            action,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: actionColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'بواسطة: $performedBy • التاريخ: $createdAt',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxRatesTab(CustomsTariffModel tariff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تفاصيل نسب الضرائب والرسوم المقررة قانوناً:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _taxCard('ضريبة الوارد (Import Duty)', '${tariff.customsDutyRate}%', 'نسبة من القيمة الجمركية CIF', Colors.blue),
              _taxCard('ضريبة القيمة المضافة (VAT)', '${tariff.vatRate}%', 'نسبة من الوعاء الضريبي الشامل', Colors.green),
              _taxCard('ضريبة الجدول (Schedule Tax)', '${tariff.scheduleTaxRate}%', 'ضريبة إضافية حسب بند التعريفة', Colors.purple),
              _taxCard('رسم التنمية (Development Fee)', '${tariff.developmentFeeRate}%', 'رسم تنمية الموارد المالية', Colors.orange),
              _taxCard('رسم الوارد (Import Fee)', '${tariff.importFeeRate}%', 'رسم وارد نوعي/ثابت إن وجد', Colors.deepOrange),
              _taxCard('رسوم الخدمات الجمركية', '${tariff.customsServiceFeeRate}%', 'خدمات وفحص جمركي', Colors.teal),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.cobalt, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'قاعدة الاحتساب الجمركي المصري: يتم تطبيق ضريبة الوارد أولاً على إجمالي القيمة الجمركية (FOB + نولون + تأمين CIF)، ثم يتم حساب الوعاء الضريبي لضريبة القيمة المضافة = (CIF + ضريبة الوارد + أي رسوم نوعية).',
                    style: TextStyle(fontSize: 12, color: AppTheme.charcoal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taxCard(String title, String rate, String subtitle, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.shade900)),
          const SizedBox(height: 2),
          Text(rate, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.shade800)),
          Text(subtitle, style: TextStyle(fontSize: 9, color: color.shade700)),
        ],
      ),
    );
  }

  Widget _buildAgreementsTab(CustomsTariffModel tariff) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(customsTariffProvider.notifier).fetchAgreements(tariff.hsCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cobalt));
        }

        final agreements = snapshot.data ?? [];
        if (agreements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.policy_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text('لا توجد اتفاقيات تفضيلية مسجلة لهذا البند (يطبق النظام الأساسي العام).'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: agreements.length,
          itemBuilder: (context, idx) {
            final ag = agreements[idx];
            final prefRate = ag['preferential_duty_rate'] ?? 0.0;
            final isZero = prefRate == 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isZero ? Colors.green.shade100 : Colors.amber.shade100,
                  child: Icon(
                    Icons.handshake_outlined,
                    color: isZero ? AppTheme.emerald : AppTheme.orange,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      ag['agreement_name'] ?? 'اتفاقية تفضيلية',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    if (ag['publication_notice'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blueGrey.shade300),
                        ),
                        child: Text(
                          ag['publication_notice'],
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ag['required_document'] != null)
                        Text('المستند المطلوب: ${ag['required_document']}', style: const TextStyle(fontSize: 11)),
                      if (ag['conditions_note'] != null)
                        Text('الشروط: ${ag['conditions_note']}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isZero ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isZero ? Colors.green.shade300 : Colors.amber.shade300),
                  ),
                  child: Text(
                    isZero ? 'إعفاء كامل (0%)' : 'فئة مخفضة ($prefRate%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isZero ? Colors.green.shade800 : Colors.amber.shade900,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRegulatoryTab(CustomsTariffModel tariff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الاشتراطات والموافقات الرقابية المسبقة للإفراج:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 12),
          Row(
            children: [
              _reqChip('نظام التسجيل المسبق ACID', tariff.requiresAcid),
              const SizedBox(width: 8),
              _reqChip('شهادة المنشأ (COO)', tariff.requiresCoo),
              const SizedBox(width: 8),
              _reqChip('فحص المطابقة النوعي', tariff.requiresInspection),
            ],
          ),
          const SizedBox(height: 16),
          if (tariff.regulatoryAuthority != null && tariff.regulatoryAuthority!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الجهة الرقابية المعنية بالإفراج: ${tariff.regulatoryAuthority}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (tariff.priorApprovalNote != null && tariff.priorApprovalNote!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rule, color: AppTheme.orange, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'القرارات والمنشورات الرقابية المقيدة للبند (Decrees & Approvals):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tariff.priorApprovalNote!,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reqChip(String label, bool isRequired) {
    return Chip(
      avatar: Icon(
        isRequired ? Icons.check_circle : Icons.cancel,
        size: 16,
        color: isRequired ? AppTheme.emerald : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
          color: isRequired ? AppTheme.charcoal : Colors.grey.shade600,
        ),
      ),
      backgroundColor: isRequired ? AppTheme.emerald.withOpacity(0.1) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  Widget _buildQuickCalculatorTab(CustomsTariffModel tariff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('احتساب فوري للرسوم الجمركية والضرائب لهذا البند:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cifValueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'قيمة الشحنة CIF (بالدولار \$)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _freightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'قيمة النولون Freight (\$)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedOriginCountry,
                  decoration: const InputDecoration(
                    labelText: 'بلد المنشأ / الاتفاقية',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ITALY', child: Text('إيطاليا (الشراكة الأوروبية EUR.1)')),
                    DropdownMenuItem(value: 'GERMANY', child: Text('ألمانيا (الشراكة الأوروبية EUR.1)')),
                    DropdownMenuItem(value: 'CHINA', child: Text('الصين (النظام الأساسي العام)')),
                    DropdownMenuItem(value: 'TURKEY', child: Text('تركيا (اتفاقية التجارة الحرة)')),
                    DropdownMenuItem(value: 'BRAZIL', child: Text('البرازيل (اتفاقية الميركسور)')),
                    DropdownMenuItem(value: 'SERBIA', child: Text('صربيا (اتفاقية التجارة الحرة)')),
                    DropdownMenuItem(value: 'UK', child: Text('المملكة المتحدة (اتفاقية الشراكة)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedOriginCountry = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                icon: _isCalculating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.calculate, size: 18),
                label: const Text('احسب الرسوم'),
                onPressed: _isCalculating ? null : () => _calculateDuty(tariff),
              ),
            ],
          ),
          if (_dutyBreakdown != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إجمالي الضرائب والرسوم المستحقة: ${_dutyBreakdown!.totalTaxesAndFees.toStringAsFixed(2)} جنيه مصري',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      if (_dutyBreakdown!.conditionsNote != null && _dutyBreakdown!.conditionsNote!.isNotEmpty)
                        Chip(
                          label: Text('الملاحظة: ${_dutyBreakdown!.conditionsNote!}'),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ضريبة الوارد (${_dutyBreakdown!.customsDutyRate}%): ${_dutyBreakdown!.importDutyAmount.toStringAsFixed(2)} ج.م'),
                      Text('ضريبة القيمة المضافة (${_dutyBreakdown!.vatRate}%): ${_dutyBreakdown!.vatAmount.toStringAsFixed(2)} ج.م'),
                      Text('ضريبة الجدول: ${_dutyBreakdown!.scheduleTaxAmount.toStringAsFixed(2)} ج.م'),
                      Text('رسوم الخدمات: ${_dutyBreakdown!.customsServiceFeeAmount.toStringAsFixed(2)} ج.م'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
