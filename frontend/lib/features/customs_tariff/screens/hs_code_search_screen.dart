import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
    final l = context.l10n;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.saved_search, color: AppTheme.cobalt, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          l.hsExplorerTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.hsExplorerSubtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const BackToDashboardButton(),
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
                            hintText: l.hsSearchPlaceholder,
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
                      Text(
                        l.hsQuickSearchExamples,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
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
                            Text(
                              l.hsMatchingResultsHeader,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l.hsItemsCount(filtered.length),
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
                                        l.hsNoMatchingItemFound(_searchCtrl.text),
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
                                        l.hsDutyRateTag(item.customsDutyRate),
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
                              Text(l.hsSelectFromListPrompt),
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
    final l = context.l10n;

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
                              l.hsCategoryPrefix(tariff.customsCategory!),
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            '${l.hsEffectiveFromPrefix(tariff.effectiveFrom.toIso8601String().split('T').first)} ${tariff.effectiveTo != null ? l.hsEffectiveToPrefix(tariff.effectiveTo!.toIso8601String().split('T').first) : l.hsEffectiveActiveRecord}',
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_edu, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          l.hsDiffHistoryAction,
                          style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
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
              tabs: [
                Tab(icon: const Icon(Icons.calculate_outlined, size: 18), text: l.hsTabTaxRates),
                Tab(icon: const Icon(Icons.public_outlined, size: 18), text: l.hsTabAgreements),
                Tab(icon: const Icon(Icons.account_balance_outlined, size: 18), text: l.hsTabRegulatory),
                Tab(icon: const Icon(Icons.history_edu_outlined, size: 18), text: l.hsTabHistory),
                Tab(icon: const Icon(Icons.point_of_sale_outlined, size: 18), text: l.hsTabQuickCalculator),
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
    final l = context.l10n;

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
                            l.hsHistorySummaryTitle(tariff.hsCode),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            versions.length > 1
                                ? l.hsHistoryMultipleVersionsDesc(versions.length)
                                : l.hsHistorySingleVersionDesc,
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
                        l.hsVersionsCountTag(versions.length),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Version Timeline
              Text(
                l.hsTimelineSectionTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                  child: Center(
                    child: Text(l.hsNoHistoricalVersions),
                  ),
                )
              else
                ...versions.map((ver) {
                  final isActive = ver['is_current_active'] == true;
                  final effFrom = ver['effective_from'] ?? '—';
                  final effTo = ver['effective_to'] ?? l.hsDatePresentOngoing;
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
                                    isActive ? l.hsActiveLiveVersionBadge : l.hsArchivedSnapshotBadge,
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
                                  l.hsRegistrationDatePrefix(createdAt),
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
                                      l.hsValidityPeriodPrefix(effFrom, effTo),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l.hsApprovedDescPrefix(ver['hs_description'] ?? '—'),
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
                                label: Text('${l.hsTaxImportDutyTitle}: $duty%'),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Chip(
                                label: Text('${l.hsTaxVatTitle}: $vat%'),
                                backgroundColor: Colors.green.shade50,
                                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              if (sched > 0)
                                Chip(
                                  label: Text('${l.hsTaxScheduleTitle}: $sched%'),
                                  backgroundColor: Colors.purple.shade50,
                                  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              if (dev > 0)
                                Chip(
                                  label: Text('${l.hsTaxDevFeeTitle}: $dev%'),
                                  backgroundColor: Colors.orange.shade50,
                                  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              Chip(
                                label: Text(l.hsLinkedAgreementsTag(agCount)),
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
                Text(
                  l.hsVersionDiffsSummaryHeader,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  List<Widget> diffWidgets = [];
                  for (int i = 0; i < versions.length - 1; i++) {
                    final newer = versions[i];
                    final older = versions[i + 1];

                    final newerDate = newer['effective_from'] ?? l.hsDateToday;
                    final olderDate = older['effective_from'] ?? l.hsDateInitial;

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
                      changeDetails.add(l.hsDiffDutyChanged(oDuty, nDuty));
                    }
                    if (nVat != oVat) {
                      changeDetails.add(l.hsDiffVatChanged(oVat, nVat));
                    }
                    if (nSched != oSched) {
                      changeDetails.add(l.hsDiffScheduleChanged(oSched, nSched));
                    }
                    if (nAg != oAg) {
                      changeDetails.add(l.hsDiffAgreementsChanged(oAg, nAg));
                    }
                    if (changeDetails.isEmpty) {
                      changeDetails.add(l.hsDiffMetadataChanged);
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
                                  l.hsDiffTitle(olderDate, newerDate),
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
              Text(
                l.hsAuditTrailSectionTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                  child: Center(
                    child: Text(l.hsNoAuditLogsFound),
                  ),
                )
              else
                ...auditLogs.map((log) {
                  final action = log['action'] ?? 'ACTIVITY';
                  final performedBy = log['performed_by'] ?? 'System';
                  final createdAt = log['created_at'] != null ? log['created_at'].toString().replaceFirst('T', ' ') : '—';
                  final summary = log['changes_summary'] ?? l.hsActionExecuted;

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
                                l.hsAuditPerformedBy(performedBy, createdAt),
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
    final l = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.hsTaxRatesSectionHeader,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _taxCard(l.hsTaxImportDutyTitle, '${tariff.customsDutyRate}%', l.hsTaxImportDutySub, Colors.blue),
              _taxCard(l.hsTaxVatTitle, '${tariff.vatRate}%', l.hsTaxVatSub, Colors.green),
              _taxCard(l.hsTaxScheduleTitle, '${tariff.scheduleTaxRate}%', l.hsTaxScheduleSub, Colors.purple),
              _taxCard(l.hsTaxDevFeeTitle, '${tariff.developmentFeeRate}%', l.hsTaxDevFeeSub, Colors.orange),
              _taxCard(l.hsTaxImportFeeTitle, '${tariff.importFeeRate}%', l.hsTaxImportFeeSub, Colors.deepOrange),
              _taxCard(l.hsTaxServiceFeeTitle, '${tariff.customsServiceFeeRate}%', l.hsTaxServiceFeeSub, Colors.teal),
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
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.cobalt, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.hsEgyptianCalculationRule,
                    style: const TextStyle(fontSize: 12, color: AppTheme.charcoal),
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
    final l = context.l10n;

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
                Text(l.hsNoAgreementsFound),
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
                      ag['agreement_name'] ?? l.hsDefaultAgreementName,
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
                        Text(l.hsRequiredDocPrefix(ag['required_document']), style: const TextStyle(fontSize: 11)),
                      if (ag['conditions_note'] != null)
                        Text(l.hsConditionsPrefix(ag['conditions_note']),
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
                    isZero ? l.hsFullExemptionBadge : l.hsReducedRateBadge(prefRate),
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
    final l = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.hsRegulatorySectionHeader,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 12),
          Row(
            children: [
              _reqChip(l.hsReqAcidSystem, tariff.requiresAcid),
              const SizedBox(width: 8),
              _reqChip(l.hsReqCertificateOfOrigin, tariff.requiresCoo),
              const SizedBox(width: 8),
              _reqChip(l.hsReqQualityInspection, tariff.requiresInspection),
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
                      l.hsRegulatoryAuthorityPrefix(tariff.regulatoryAuthority!),
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
                  Row(
                    children: [
                      const Icon(Icons.rule, color: AppTheme.orange, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l.hsDecreesAndNotesHeader,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
    final l = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.hsCalculatorSectionHeader,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cifValueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.hsCifValueLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _freightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.hsFreightValueLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedOriginCountry,
                  decoration: InputDecoration(
                    labelText: l.hsOriginCountryLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(value: 'ITALY', child: Text(l.hsOriginItalyEur1)),
                    DropdownMenuItem(value: 'GERMANY', child: Text(l.hsOriginGermanyEur1)),
                    DropdownMenuItem(value: 'CHINA', child: Text(l.hsOriginChinaGeneral)),
                    DropdownMenuItem(value: 'TURKEY', child: Text(l.hsOriginTurkeyFta)),
                    DropdownMenuItem(value: 'BRAZIL', child: Text(l.hsOriginBrazilMercosur)),
                    DropdownMenuItem(value: 'SERBIA', child: Text(l.hsOriginSerbiaFta)),
                    DropdownMenuItem(value: 'UK', child: Text(l.hsOriginUkPartnership)),
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
                label: Text(l.hsCalculateDutyBtn),
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
                        l.hsTotalTaxesAndFeesDue(_dutyBreakdown!.totalTaxesAndFees.toStringAsFixed(2)),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      if (_dutyBreakdown!.conditionsNote != null && _dutyBreakdown!.conditionsNote!.isNotEmpty)
                        Chip(
                          label: Text(l.hsNotePrefix(_dutyBreakdown!.conditionsNote!)),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.hsImportDutyBreakdown(_dutyBreakdown!.customsDutyRate, _dutyBreakdown!.importDutyAmount.toStringAsFixed(2))),
                      Text(l.hsVatBreakdown(_dutyBreakdown!.vatRate, _dutyBreakdown!.vatAmount.toStringAsFixed(2))),
                      Text(l.hsScheduleBreakdown(_dutyBreakdown!.scheduleTaxAmount.toStringAsFixed(2))),
                      Text(l.hsServiceFeeBreakdown(_dutyBreakdown!.customsServiceFeeAmount.toStringAsFixed(2))),
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
