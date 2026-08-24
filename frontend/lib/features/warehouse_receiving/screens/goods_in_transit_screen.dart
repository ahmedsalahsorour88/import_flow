import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../providers/goods_in_transit_provider.dart';

class GoodsInTransitScreen extends ConsumerStatefulWidget {
  const GoodsInTransitScreen({super.key});

  @override
  ConsumerState<GoodsInTransitScreen> createState() => _GoodsInTransitScreenState();
}

class _GoodsInTransitScreenState extends ConsumerState<GoodsInTransitScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'In-Transit Only';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final gitAsync = ref.watch(goodsInTransitProvider);

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.local_shipping_outlined,
        titleEn: 'Goods In Transit (GIT) Ledger',
        titleAr: 'رصيد البضاعة بالطريق وتتبع الشحنات',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'GIT-01',
      titleEn: 'Goods In Transit (GIT) Inventory Ledger',
      titleAr: 'رصيد ومطابقة البضاعة في الطريق',
      headerIcon: Icons.local_shipping,
      headerColor: AppTheme.emerald,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (_) {},
      body: gitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(l.gitErrorFetchingData(err), style: const TextStyle(color: Colors.red)),
        ),
        data: (allItems) {
          final filteredItems = allItems.where((item) {
            if (_selectedStatusFilter == 'In-Transit Only' && item.isDeliveredToWarehouse) {
              return false;
            }
            if (_selectedStatusFilter == 'Delivered Only' && !item.isDeliveredToWarehouse) {
              return false;
            }
            if (_searchCtrl.text.trim().isEmpty) return true;
            final q = _searchCtrl.text.trim().toLowerCase();
            return item.importFileCode.toLowerCase().contains(q) ||
                item.poNumber.toLowerCase().contains(q) ||
                item.itemCode.toLowerCase().contains(q) ||
                item.itemName.toLowerCase().contains(q);
          }).toList();

          final activeItems = allItems.where((i) => !i.isDeliveredToWarehouse).toList();
          final uniqueFiles = activeItems.map((i) => i.importFileCode).toSet().length;
          final uniquePos = activeItems.map((i) => i.poNumber).toSet().length;
          final totalQty = activeItems.fold<double>(0.0, (s, i) => s + i.invoicedQty);
          final totalPkgs = activeItems.fold<int>(0, (s, i) => s + i.packagesCount);
          final totalContainers = activeItems.fold<int>(0, (s, i) => s + i.containersCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.teal, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.gitInfoBannerTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.gitInfoBannerSubtitle,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: Text(l.gitExportExcelBtn),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.gitExportSuccessMsg), backgroundColor: AppTheme.emerald),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KPI Metrics Bar
                Row(
                  children: [
                    Expanded(child: _buildMetricCard(l.gitKpiInTransitShipments, l.gitKpiShipmentsValue(uniqueFiles), Icons.folder_open, Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.gitKpiPurchaseOrders, l.gitKpiPurchaseOrdersValue(uniquePos), Icons.receipt_long, Colors.purple)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.gitKpiInvoicedQuantity, l.gitKpiQuantityValue(totalQty.toStringAsFixed(0)), Icons.category, Colors.indigo)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.gitKpiPackagesCount, l.gitKpiPackagesValue(totalPkgs), Icons.all_inbox, Colors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.gitKpiActiveContainers, l.gitKpiContainersValue(totalContainers), Icons.directions_boat, AppTheme.emerald)),
                  ],
                ),
                const SizedBox(height: 16),

                // Search & Filter Bar
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 320,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: l.gitSearchHint,
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedStatusFilter,
                            underline: const SizedBox(),
                            items: [
                              DropdownMenuItem(value: 'All', child: Text(l.gitFilterAll)),
                              DropdownMenuItem(value: 'In-Transit Only', child: Text(l.gitFilterInTransitOnly)),
                              DropdownMenuItem(value: 'Delivered Only', child: Text(l.gitFilterDeliveredOnly)),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatusFilter = val);
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                            tooltip: l.gitRefreshTooltip,
                            onPressed: () => ref.read(goodsInTransitProvider.notifier).initLedger(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Goods In Transit Table
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.table_chart_outlined, color: AppTheme.emerald, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.gitTableSectionHeader,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (filteredItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(l.gitNoDataFound)),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: [
                                DataColumn(label: Text(l.gitColFileCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColPoNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColItemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColItemName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColInvoicedQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColPackagesCount, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColContainers, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColCertifiedDate, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.gitColLedgerStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredItems.map((item) {
                                final isDelivered = item.isDeliveredToWarehouse;
                                return DataRow(cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.charcoal.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(item.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                    ),
                                  ),
                                  DataCell(Text(item.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                  DataCell(Text(item.itemCode, style: const TextStyle(fontFamily: 'monospace'))),
                                  DataCell(Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(l.gitKpiQuantityValue(item.invoicedQty.toStringAsFixed(0)), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                  DataCell(Text('${item.packagesCount} ${item.packageType}')),
                                  DataCell(Text('${item.containersCount} × ${item.containerType}')),
                                  DataCell(Text(item.certifiedDate)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isDelivered ? Colors.green : Colors.teal).shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: (isDelivered ? Colors.green : Colors.teal).shade300),
                                      ),
                                      child: Text(
                                        isDelivered ? l.gitStatusDeliveredToWarehouse : l.gitStatusInTransit,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDelivered ? Colors.green.shade900 : Colors.teal.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color), overflow: TextOverflow.ellipsis),
                Text(title, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

