import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/extraction_progress_dialog.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/customs_clearance_quotation_model.dart';
import '../providers/customs_clearance_quotations_provider.dart';

class CustomsClearanceQuotationsScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const CustomsClearanceQuotationsScreen({super.key, this.embedded = false});

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

  // ── Smart AI Extractor State (Text & OCR) ──────────────────────────────
  bool _isClearanceExtractorExpanded = true;
  bool _isClearanceExtracting = false;
  final TextEditingController _rawClearanceQuoteCtrl = TextEditingController();
  Map<String, dynamic>? _extractedClearanceData;
  PlatformFile? _pickedClearanceFile;
  String? _clearanceExtractorError;

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
    _rawClearanceQuoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF4F6F8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.request_quote_rounded, color: AppTheme.cobalt, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n.clearanceQuotesEmbeddedTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.charcoal),
                    tooltip: l10n.refresh,
                    onPressed: () {
                      ref.invalidate(customsClearanceQuotationsProvider);
                      ref.invalidate(clearancePriceListProvider);
                      ref.invalidate(partnersProvider);
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l10n.clearanceQuotesSmartExtractorBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showSmartExtractorDialog(null),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.cobalt,
                indicatorWeight: 3,
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                    text: l10n.clearanceQuotesTabRfqs,
                  ),
                  Tab(
                    icon: const Icon(Icons.price_change_rounded, size: 18),
                    text: l10n.clearanceQuotesTabPriceLists,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRFQsTab(),
                  _buildPriceListsTab(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.request_quote_rounded, color: Colors.amber, size: 26),
            const SizedBox(width: 10),
            Text(
              l10n.clearanceQuotesScreenTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: l10n.refresh,
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
          tabs: [
            Tab(
              icon: const Icon(Icons.compare_arrows_rounded),
              text: l10n.clearanceQuotesTabRfqs,
            ),
            Tab(
              icon: const Icon(Icons.price_change_rounded),
              text: l10n.clearanceQuotesTabPriceLists,
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
    final l10n = context.l10n;
    final rfqsState = ref.watch(customsClearanceQuotationsProvider);

    return rfqsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.crimson),
            const SizedBox(height: 12),
            Text('${l10n.clearanceQuotesErrorLoadingRfqs} $e', style: const TextStyle(color: AppTheme.crimson)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
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
                        hintText: l10n.clearanceQuotesSearchHint,
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
                    items: [
                      DropdownMenuItem(value: 'ALL', child: Text(l10n.clearanceQuotesStatusAll)),
                      DropdownMenuItem(value: 'Draft', child: Text(l10n.clearanceQuotesStatusDraft)),
                      DropdownMenuItem(value: 'Quotations Received', child: Text(l10n.clearanceQuotesStatusReceived)),
                      DropdownMenuItem(value: 'Awarded', child: Text(l10n.clearanceQuotesStatusAwarded)),
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
                    label: Text(l10n.clearanceQuotesSmartExtractorBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    label: Text(l10n.clearanceQuotesCreateRfqBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showCreateRFQDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Smart AI Clearance Quotations Extractor (Text & OCR Box) ──
              _buildInlineClearanceQuotationsExtractorWidget(),
              const SizedBox(height: 8),

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
                              l10n.clearanceQuotesNoRfqsFound,
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
    final l10n = context.l10n;
    Color statusColor = Colors.grey;
    String statusDisplay = rfq.status;
    if (rfq.status == 'Awarded') {
      statusColor = AppTheme.emerald;
      statusDisplay = l10n.clearanceQuotesStatusAwarded;
    } else if (rfq.status == 'Quotations Received') {
      statusColor = AppTheme.cobalt;
      statusDisplay = l10n.clearanceQuotesStatusReceived;
    } else if (rfq.status == 'Draft') {
      statusDisplay = l10n.clearanceQuotesStatusDraft;
    }

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
                    statusDisplay,
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
                _buildInfoBadge(Icons.anchor_rounded, l10n.clearanceQuotesBadgePort, rfq.portName),
                _buildInfoBadge(Icons.local_shipping_rounded, l10n.clearanceQuotesBadgeShipmentType, '${rfq.shipmentType} (${rfq.containersCount})'),
                if (rfq.hsCode != null && rfq.hsCode!.isNotEmpty)
                  _buildInfoBadge(Icons.category_rounded, l10n.clearanceQuotesBadgeHsCode, rfq.hsCode!),
                _buildInfoBadge(Icons.scale_rounded, l10n.clearanceQuotesBadgeWeight, '${rfq.grossWeightKg} ${l10n.kgUnit}'),
                _buildInfoBadge(Icons.view_in_ar_rounded, l10n.clearanceQuotesBadgeVolume, '${rfq.cbm} ${l10n.cbmUnit}'),
                if (rfq.lowestClearanceCost > 0)
                  _buildInfoBadge(Icons.monetization_on_rounded, l10n.clearanceQuotesBadgeLowestCost, '${rfq.lowestClearanceCost.toStringAsFixed(2)} ${l10n.egpCurrency}', color: AppTheme.emerald),
                if (rfq.fastestTurnaroundDays > 0)
                  _buildInfoBadge(Icons.timer_rounded, l10n.clearanceQuotesBadgeFastestDuration, l10n.clearanceQuotesDaysCount(rfq.fastestTurnaroundDays), color: AppTheme.cobalt),
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
                      '${l10n.clearanceQuotesAwardedBannerPrefix} ${rfq.awardedProviderName}',
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
                  l10n.clearanceQuotesReceivedQuotesHeader(rfq.quotations.length),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6C5CE7)),
                      label: Text(l10n.clearanceQuotesSmartExtractQuoteBtn, style: const TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold, fontSize: 12)),
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
                      label: Text(l10n.clearanceQuotesAddManualQuoteBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                child: Text(l10n.clearanceQuotesNoQuotesYet, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: [
                    DataColumn(label: Text(l10n.clearanceQuotesColBroker, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColClearanceFee, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColInlandTransport, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColInspectionFee, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColPortExpenses, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColMiscellaneous, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColEstimatedTotal, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColDuration, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.clearanceQuotesColStatusActions, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                        DataCell(Text(l10n.clearanceQuotesDaysCount(q.estimatedTurnaroundDays))),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAwarded)
                              Chip(
                                avatar: const Icon(Icons.check, size: 14, color: Colors.white),
                                label: Text(l10n.clearanceQuotesStatusAwardedBadge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                                child: Text(l10n.clearanceQuotesAwardAndApproveBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
    final l10n = context.l10n;
    final priceListState = ref.watch(clearancePriceListProvider);

    return priceListState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.clearanceQuotesErrorLoadingPriceList} $e', style: const TextStyle(color: AppTheme.crimson))),
      data: (items) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.clearanceQuotesPriceListTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.clearanceQuotesPriceListSubtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.clearanceQuotesAddPriceItemBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddPriceItemDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(l10n.clearanceQuotesNoPriceItemsFound, style: TextStyle(color: Colors.grey.shade600)),
                      )
                    : Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: [
                                DataColumn(label: Text(l10n.clearanceQuotesColBroker, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.clearanceQuotesColPricePort, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.clearanceQuotesColPriceServiceType, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.clearanceQuotesColPriceContainerType, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.clearanceQuotesColPriceStandardRate, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.clearanceQuotesColPriceNotes, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l10n.clearanceQuotesColPriceDelete, style: const TextStyle(fontWeight: FontWeight.bold))),
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

  Future<void> _showCreateRFQDialog({
    String? initialBrokerName,
    String? initialPortName,
    double? initialClearanceFee,
    double? initialInspectionFee,
    double? initialPortExpenses,
    double? initialMiscFee,
  }) async {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(
      text: initialBrokerName != null ? 'طلب تخليص جمركي - $initialBrokerName' : l10n.clearanceQuotesDialogCreateRfqTitle,
    );
    final commodityCtrl = TextEditingController();
    final hsCodeCtrl = TextEditingController();
    final grossWeightCtrl = TextEditingController(text: '10000');
    final cbmCtrl = TextEditingController(text: '30');
    int containersCount = 1;
    String shipmentType = 'Ocean FCL (40HQ)';
    String portName = initialPortName ?? 'Alexandria Port';
    int? selectedImportFileId;

    final importFiles = ref.read(importFilesProvider).value ?? [];
    final locations = ref.read(transportLocationsProvider).value ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_task_rounded, color: AppTheme.emerald),
              const SizedBox(width: 10),
              Text(l10n.clearanceQuotesDialogCreateRfqTitle),
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
                      decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldRfqTitle, prefixIcon: const Icon(Icons.title_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.clearanceQuotesFieldRfqTitleRequired : null,
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<int>(
                      value: selectedImportFileId,
                      labelText: l10n.clearanceQuotesFieldLinkImportFile,
                      searchHintText: l10n.searchPlaceholder,
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
                      labelText: l10n.clearanceQuotesFieldClearancePort,
                      searchHintText: l10n.searchPlaceholder,
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
                          child: SearchableDropdownField<String>(
                            value: shipmentType,
                            labelText: l10n.clearanceQuotesFieldShipmentType,
                            items: const [
                              SearchableDropdownItem(value: 'Ocean FCL (40HQ)', label: 'Ocean FCL (40HQ)'),
                              SearchableDropdownItem(value: 'Ocean FCL (20GP)', label: 'Ocean FCL (20GP)'),
                              SearchableDropdownItem(value: 'Ocean LCL', label: 'Ocean LCL'),
                              SearchableDropdownItem(value: 'Air Freight', label: 'Air Freight'),
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
                            decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldContainersCount),
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
                            decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldGrossWeightKg),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cbmCtrl,
                            decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldCbm),
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
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              child: Text(l10n.clearanceQuotesSubmitCreateRfqBtn),
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
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddQuotationDialog(int rfqId, {Map<String, dynamic>? prefill}) async {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final partners = ref.read(partnersProvider).value?.where((p) => p.partnerType == 'Customs Broker' || p.partnerType == 'Freight Forwarder').toList() ?? [];

    int? selectedProviderId = prefill?['provider_id'] ?? (partners.isNotEmpty ? partners.first.partnerId : 1);
    String selectedProviderName = prefill?['provider_name'] ?? (partners.isNotEmpty ? partners.first.partnerName : l10n.clearanceQuotesColBroker);

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
            title: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppTheme.cobalt),
                const SizedBox(width: 10),
                Text(l10n.clearanceQuotesDialogAddQuoteTitle),
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
                        labelText: l10n.clearanceQuotesFieldCustomsBroker,
                        searchHintText: l10n.searchPlaceholder,
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
                              decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldClearanceFeeEgp),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: inlandFeeCtrl,
                              decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldInlandFeeEgp),
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
                              decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldInspectionFeeEgp),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: portExpCtrl,
                              decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldPortExpEgp),
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
                              decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldMiscFeeEgp),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: daysCtrl,
                              decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldEstimatedDays),
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
                            Text(l10n.clearanceQuotesTotalEstimatedQuoteLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${total.toStringAsFixed(2)} ${l10n.egpCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emerald)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(ctx)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                child: Text(l10n.clearanceQuotesSubmitSaveQuoteBtn),
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
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static const String _sampleClearanceQuoteText = '''
مقايسة وعرض أسعار تخليص جمركي
المخلص الجمركي: مكتب الأهرام للتخليص الجمركي
ميناء الوصول: ميناء الإسكندرية البحري (Alexandria Port)
نوع الحاوية: 40HQ - عدد 2 حاوية
أتعاب التخليص الجمركي: 3,500 جنيه
مصاريف الشحن والتفريغ: 1,800 جنيه
رسوم الفحص والعرض (صادرات وواردات): 2,400 جنيه
مصاريف نولون نقل داخلي للمصنع: 4,500 جنيه
المصروفات النثرية والوزن: 600 جنيه
إجمالي المقايسة التقديرية: 12,800 EGP
''';

  void _loadSampleClearanceQuote() {
    setState(() {
      _rawClearanceQuoteCtrl.text = _sampleClearanceQuoteText.trim();
      _clearanceExtractorError = null;
    });
  }

  Future<void> _extractClearanceFromText() async {
    final text = _rawClearanceQuoteCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى لصق أو كتابة نص مقايسة التخليص أولاً'), backgroundColor: AppTheme.orange),
      );
      return;
    }

    setState(() {
      _isClearanceExtracting = true;
      _clearanceExtractorError = null;
      _extractedClearanceData = null;
    });

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.20,
      status: 'جاري فحص وتحليل بنود مقايسة التخليص الجمركي...',
      stepLabel: 'المرحلة 1 من 3: معالجة النصوص',
      currentStep: 1,
    );

    ExtractionProgressDialog.show(
      context: context,
      title: 'استخراج مقايسة التخليص من النص',
      fileName: 'النص المنسوخ (${text.length} حرف)',
      controller: progressCtrl,
    );

    progressCtrl.startAutoAdvance(targetPercent: 0.90, duration: const Duration(seconds: 2));

    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse-text/clearance-quotation',
        data: FormData.fromMap({
          'raw_text': text,
          'save_session': false,
        }),
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      _processExtractedClearanceData(response.data);
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _clearanceExtractorError = 'خطأ في الاتصال بالخادم: ${e.message}');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _clearanceExtractorError = 'حدث خطأ أثناء الاستخراج: $e');
    } finally {
      if (mounted) setState(() => _isClearanceExtracting = false);
    }
  }

  Future<void> _extractClearanceFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'xlsx', 'xls', 'docx', 'doc', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
      final file = result.files.first;

      setState(() {
        _pickedClearanceFile = file;
        _isClearanceExtracting = true;
        _clearanceExtractorError = null;
        _extractedClearanceData = null;
      });

      final fileSizeFormatted = file.size > 1024 * 1024
          ? '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'
          : '${(file.size / 1024).toStringAsFixed(1)} KB';

      final progressCtrl = ExtractionProgressController();
      progressCtrl.update(
        percent: 0.15,
        status: 'جاري رفع الملف وقراءة المقايسة بالماسح الضوئي (OCR)...',
        stepLabel: 'المرحلة 1 من 4: رفع الملف',
        currentStep: 1,
      );

      ExtractionProgressDialog.show(
        context: context,
        title: 'استخراج مقايسة التخليص بالماسح الضوئي (OCR)',
        fileName: file.name,
        fileSize: fileSizeFormatted,
        controller: progressCtrl,
      );

      final dio = Dio();
      final multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      final formData = FormData.fromMap({
        'file': multipartFile,
        'module_name': 'clearance-quotation',
        'save_session': false,
      });

      final response = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/upload',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final uploadRatio = sent / total;
            final p = 0.15 + (uploadRatio * 0.35);
            progressCtrl.update(
              percent: p,
              status: 'جاري رفع الملف (${(uploadRatio * 100).round()}%)...',
              stepLabel: 'المرحلة 2 من 4: رفع الملف',
              currentStep: 2,
            );
            if (uploadRatio >= 0.99) {
              progressCtrl.startAutoAdvance(targetPercent: 0.92, duration: const Duration(seconds: 5));
            }
          }
        },
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      _processExtractedClearanceData(response.data);
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _clearanceExtractorError = 'خطأ في معالجة الملف بالـ OCR: ${e.message}');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _clearanceExtractorError = 'حدث خطأ أثناء معالجة المستند: $e');
    } finally {
      if (mounted) setState(() => _isClearanceExtracting = false);
    }
  }

  void _processExtractedClearanceData(dynamic data) {
    if (data == null) return;
    final extracted = (data['extracted_fields'] as Map<String, dynamic>?) ?? {};

    if (data['raw_text'] != null && (data['raw_text'] as String).isNotEmpty) {
      _rawClearanceQuoteCtrl.text = data['raw_text'] as String;
    }

    setState(() {
      _extractedClearanceData = extracted;
      if (extracted.isEmpty) {
        _clearanceExtractorError = 'لم يتم العثور على أية بيانات صالحة في النص/المستند المدخل.';
      }
    });

    if (extracted.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ تم بنجاح استخراج بيانات مقايسة التخليص الجمركي!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  Widget _buildInlineClearanceQuotationsExtractorWidget() {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Cobalt Gradient & Icons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6C5CE7), Colors.deepPurple.shade700],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Icon(Icons.bolt, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '(Clearance Quotation AI) استخراج وقراءة عروض ومقايسات التخليص الجمركي ⚡ ✨',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(_isClearanceExtractorExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _isClearanceExtractorExpanded ? 'طي الأداة' : 'توسيع الأداة',
                  onPressed: () => setState(() => _isClearanceExtractorExpanded = !_isClearanceExtractorExpanded),
                ),
              ],
            ),
          ),

          // Collapsible Body
          if (_isClearanceExtractorExpanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;

                      // Text Area
                      final textArea = Stack(
                        children: [
                          TextField(
                            controller: _rawClearanceQuoteCtrl,
                            maxLines: 5,
                            minLines: 4,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                            decoration: InputDecoration(
                              hintText: 'لصق نص رسالة أو مقايسة عرض أسعار التخليص الجمركي...\n(مثال: المخلص: الأهرام للتخليص | ميناء الإسكندرية | أتعاب التخليص: 3500 ج | الفحص: 2400 ج | إجمالي المقايسة: 12800 EGP)',
                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final d = await Clipboard.getData(Clipboard.kTextPlain);
                                    if (d != null && d.text != null && d.text!.isNotEmpty) {
                                      _rawClearanceQuoteCtrl.text = d.text!;
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.paste, size: 12, color: Colors.black87),
                                        SizedBox(width: 4),
                                        Text('لصق نص المقايسة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    _rawClearanceQuoteCtrl.clear();
                                    setState(() {
                                      _extractedClearanceData = null;
                                      _clearanceExtractorError = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.clear, size: 12, color: Colors.black54),
                                        SizedBox(width: 4),
                                        Text('تفريغ', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _loadSampleClearanceQuote,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      border: Border.all(color: Colors.purple.shade200),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 12, color: Color(0xFF6C5CE7)),
                                        SizedBox(width: 4),
                                        Text('نموذج تجريبي', style: TextStyle(fontSize: 11, color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      // Buttons
                      final actionButtons = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                            label: const Text('رفع مستند المقايسة 📄', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isClearanceExtracting ? null : _extractClearanceFromFile,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isClearanceExtracting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.bolt, size: 16, color: Colors.amber),
                            label: const Text('استخراج وتحليل المقايسة ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isClearanceExtracting ? null : _extractClearanceFromText,
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            textArea,
                            const SizedBox(height: 10),
                            actionButtons,
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: textArea),
                            const SizedBox(width: 14),
                            SizedBox(width: 220, child: actionButtons),
                          ],
                        );
                      }
                    },
                  ),

                  // Error
                  if (_clearanceExtractorError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_clearanceExtractorError!, style: TextStyle(color: Colors.red.shade800, fontSize: 11))),
                        ],
                      ),
                    ),
                  ],

                  // Extracted Result Card
                  if (_extractedClearanceData != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تم استخراج بيانات مقايسة التخليص بنجاح:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.add_circle_outline, size: 14, color: Colors.white),
                                label: const Text(
                                  '🚀 إنشاء طلب RFQ جديد بهذه البيانات',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                onPressed: () {
                                  _showCreateRFQDialog(
                                    initialBrokerName: _extractedClearanceData!['broker_name'] as String?,
                                    initialPortName: _extractedClearanceData!['port_name'] as String?,
                                    initialClearanceFee: (_extractedClearanceData!['clearance_fee'] as num?)?.toDouble(),
                                    initialInspectionFee: (_extractedClearanceData!['inspection_fee'] as num?)?.toDouble(),
                                    initialPortExpenses: (_extractedClearanceData!['port_expenses'] as num?)?.toDouble(),
                                    initialMiscFee: (_extractedClearanceData!['miscellaneous_fee'] as num?)?.toDouble(),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (_pickedClearanceFile != null)
                                Chip(
                                  avatar: const Icon(Icons.attach_file, size: 14, color: Color(0xFF6C5CE7)),
                                  label: Text('المستند: ${_pickedClearanceFile!.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.white,
                                ),
                              if (_extractedClearanceData!['broker_name'] != null)
                                Chip(
                                  avatar: const Icon(Icons.person, size: 14, color: AppTheme.cobalt),
                                  label: Text('المخلص: ${_extractedClearanceData!['broker_name']}', style: const TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.white,
                                ),
                              if (_extractedClearanceData!['port_name'] != null)
                                Chip(
                                  avatar: const Icon(Icons.location_on, size: 14, color: Colors.blue),
                                  label: Text('الميناء: ${_extractedClearanceData!['port_name']}', style: const TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.white,
                                ),
                              if (_extractedClearanceData!['clearance_fee'] != null)
                                Chip(
                                  label: Text('أتعاب التخليص: ${_extractedClearanceData!['clearance_fee']} EGP', style: const TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.white,
                                ),
                              if (_extractedClearanceData!['total_estimated_clearance_cost'] != null)
                                Chip(
                                  avatar: const Icon(Icons.monetization_on, size: 14, color: Colors.green),
                                  label: Text('الإجمالي التقديري: ${_extractedClearanceData!['total_estimated_clearance_cost']} EGP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                  backgroundColor: Colors.white,
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
        ],
      ),
    );
  }

  Future<void> _showSmartExtractorDialog(int? targetRfqId) async {
    final l10n = context.l10n;
    final textCtrl = TextEditingController();
    bool isExtracting = false;
    Map<String, dynamic>? extractedResult;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 10),
              Text(l10n.clearanceQuotesSmartExtractorDialogTitle),
            ],
          ),
          content: SizedBox(
            width: 750,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.clearanceQuotesSmartExtractorPrompt),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: l10n.clearanceQuotesSmartExtractorInputHint,
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
                      label: Text(isExtracting ? l10n.clearanceQuotesExtractingState : l10n.clearanceQuotesExtractFromTextBtn),
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
                                    SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: AppTheme.crimson),
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
                      label: Text(l10n.clearanceQuotesUploadDocBtn),
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
                              SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: AppTheme.crimson),
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
                            Text('${l10n.clearanceQuotesExtractedBrokerPrefix} ${extractedResult!['broker_name'] ?? l10n.clearanceQuotesColBroker}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${l10n.clearanceQuotesExtractedPortPrefix} ${extractedResult!['port_name'] ?? '-'} | ${l10n.clearanceQuotesExtractedContainerPrefix} ${extractedResult!['container_type'] ?? '-'}'),
                            Text('${l10n.clearanceQuotesExtractedTotalPrefix} ${extractedResult!['total_estimated_clearance_cost']} ${l10n.egpCurrency}', style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check),
                          label: Text(l10n.clearanceQuotesApplyExtractedQuoteBtn),
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
            TextButton(child: Text(l10n.close), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPriceItemDialog() async {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final partners = ref.read(partnersProvider).value?.where((p) => p.partnerType == 'Customs Broker' || p.partnerType == 'Freight Forwarder').toList() ?? [];
    final locations = ref.read(transportLocationsProvider).value ?? [];

    int selectedProviderId = partners.isNotEmpty ? partners.first.partnerId! : 1;
    String selectedProviderName = partners.isNotEmpty ? partners.first.partnerName : l10n.clearanceQuotesColBroker;
    String portName = locations.isNotEmpty ? locations.first.locationName : 'Alexandria Port';
    String category = l10n.clearanceQuotesCatClearanceFee;
    String containerType = '40HQ';
    final priceCtrl = TextEditingController(text: '3500');
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.clearanceQuotesDialogAddPriceItemTitle),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<int>(
                    value: selectedProviderId,
                    labelText: l10n.clearanceQuotesFieldCustomsBroker,
                    searchHintText: l10n.searchPlaceholder,
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
                    labelText: l10n.clearanceQuotesFieldClearancePort,
                    searchHintText: l10n.searchPlaceholder,
                    items: locations.map((l) => SearchableDropdownItem<String>(value: l.locationName, label: l.locationName)).toList(),
                    onChanged: (val) {
                      if (val != null) setDState(() => portName = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdownField<String>(
                    value: category,
                    labelText: l10n.clearanceQuotesFieldServiceCategory,
                    items: [
                      SearchableDropdownItem(value: l10n.clearanceQuotesCatClearanceFee, label: l10n.clearanceQuotesCatClearanceFee),
                      SearchableDropdownItem(value: l10n.clearanceQuotesCatInlandTransport, label: l10n.clearanceQuotesCatInlandTransport),
                      SearchableDropdownItem(value: l10n.clearanceQuotesCatInspectionFee, label: l10n.clearanceQuotesCatInspectionFee),
                      SearchableDropdownItem(value: l10n.clearanceQuotesCatPortCharges, label: l10n.clearanceQuotesCatPortCharges),
                    ],
                    onChanged: (val) {
                      if (val != null) setDState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SearchableDropdownField<String>(
                          value: containerType,
                          labelText: l10n.clearanceQuotesColPriceContainerType,
                          items: const [
                            SearchableDropdownItem(value: '40HQ', label: '40HQ'),
                            SearchableDropdownItem(value: '40GP', label: '40GP'),
                            SearchableDropdownItem(value: '20GP', label: '20GP'),
                            SearchableDropdownItem(value: 'LCL', label: 'LCL'),
                            SearchableDropdownItem(value: 'Air', label: 'Air'),
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
                          decoration: InputDecoration(labelText: l10n.clearanceQuotesFieldStandardPriceEgp),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.clearanceQuotesFieldStandardPriceRequired : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              child: Text(l10n.clearanceQuotesSubmitSavePriceItemBtn),
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
                  currency: l10n.egpCurrency,
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                );

                await ref.read(clearancePriceListProvider.notifier).createPriceItem(newItem);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _awardQuotation(int rfqId, int quotationId) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.emerald),
            const SizedBox(width: 8),
            Text(l10n.clearanceQuotesConfirmAwardTitle),
          ],
        ),
        content: Text(l10n.clearanceQuotesConfirmAwardContent),
        actions: [
          TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            child: Text(l10n.clearanceQuotesConfirmAwardBtn),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(customsClearanceQuotationsProvider.notifier).awardQuotation(rfqId, quotationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clearanceQuotesAwardSuccessSnackbar),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuotation(int quotationId) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearanceQuotesConfirmDeleteQuoteTitle),
        content: Text(l10n.clearanceQuotesConfirmDeleteQuoteContent),
        actions: [
          TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
            child: Text(l10n.delete),
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

/// Global helper to show the Smart Clearance Quotation Extractor dialog from any screen/tab
Future<void> showSmartClearanceExtractorDialog(
  BuildContext context,
  WidgetRef ref, {
  int? targetRfqId,
  Function(Map<String, dynamic> extracted)? onExtracted,
}) async {
  final l10n = AppLocalizations.of(context);
  final textCtrl = TextEditingController();
  bool isExtracting = false;
  Map<String, dynamic>? extractedResult;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF6C5CE7)),
            const SizedBox(width: 10),
            Text(l10n.clearanceQuotesSmartExtractorDialogTitle),
          ],
        ),
        content: SizedBox(
          width: 750,
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.clearanceQuotesSmartExtractorPrompt),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: l10n.clearanceQuotesSmartExtractorInputHint,
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
                    label: Text(isExtracting ? l10n.clearanceQuotesExtractingState : l10n.clearanceQuotesExtractFromTextBtn),
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
                              if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: AppTheme.crimson),
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
                    label: Text(l10n.clearanceQuotesUploadDocBtn),
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
                        if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: AppTheme.crimson),
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
                          Text('${l10n.clearanceQuotesExtractedBrokerPrefix} ${extractedResult!['broker_name'] ?? l10n.clearanceQuotesColBroker}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${l10n.clearanceQuotesExtractedPortPrefix} ${extractedResult!['port_name'] ?? '-'} | ${l10n.clearanceQuotesExtractedContainerPrefix} ${extractedResult!['container_type'] ?? '-'}'),
                          Text('${l10n.clearanceQuotesExtractedTotalPrefix} ${extractedResult!['total_estimated_clearance_cost']} ${l10n.egpCurrency}', style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                        icon: const Icon(Icons.check),
                        label: Text(l10n.clearanceQuotesUseExtractedQuoteBtn),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (onExtracted != null) {
                            onExtracted(extractedResult!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.clearanceQuotesExtractedSuccessToast(
                                  extractedResult!['broker_name'] ?? l10n.clearanceQuotesColBroker,
                                  extractedResult!['total_estimated_clearance_cost'] ?? 0,
                                )),
                                backgroundColor: Colors.green,
                              ),
                            );
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
          TextButton(child: Text(l10n.close), onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );
}
