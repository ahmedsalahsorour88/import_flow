import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../models/warehouse_receiving_model.dart';
import '../providers/warehouse_receiving_provider.dart';

class WarehouseReceivedReportScreen extends ConsumerStatefulWidget {
  const WarehouseReceivedReportScreen({super.key});

  @override
  ConsumerState<WarehouseReceivedReportScreen> createState() => _WarehouseReceivedReportScreenState();
}

class _WarehouseReceivedReportScreenState extends ConsumerState<WarehouseReceivedReportScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(warehouseReceivingProvider.notifier).fetchRecords();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final recordsAsync = ref.watch(warehouseReceivingProvider);

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.inventory_2_outlined,
        titleEn: 'Received Shipments Detailed Report',
        titleAr: 'تقرير الشحنات المستلمة بالمخزن تفصيلي',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'GRN-REP',
      titleEn: 'Warehouse Received Shipments & Audit Report',
      titleAr: 'تقرير الشحنات المستلمة بالمخزن تفصيلي ومطابقة الفروق',
      headerIcon: Icons.inventory_2_outlined,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (_) {},
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(l.whReportErrorFetchingData(err), style: const TextStyle(color: Colors.red)),
        ),
        data: (records) {
          // Real received entries expanded from warehouse receiving records
          final List<Map<String, dynamic>> receivedReportItems = [];

          // Also map any actual records from the provider
          for (var r in records) {
            for (var item in r.grnItems) {
              receivedReportItems.add({
                'import_file_code': 'IMP-${r.importFileId}',
                'po_number': 'PO-MAIN-${r.importFileId}',
                'container_info': '1 × 40ft HQ (${r.truckPlateNumber ?? "N/A"})',
                'item_code': item.itemCode,
                'item_name': item.itemName,
                'invoiced_qty': item.invoicedQty,
                'shortage_qty': item.shortageQty,
                'damaged_qty': item.damagedQty,
                'samples_qty': 0,
                'received_qty': item.acceptedQty,
                'variance_qty': item.acceptedQty - item.invoicedQty,
                'warehouse_name': r.warehouseName,
                'arrival_date': r.arrivalDatetime.substring(0, 10),
                'status': r.status,
              });
            }
          }

          final filtered = receivedReportItems.where((i) {
            if (_searchCtrl.text.trim().isEmpty) return true;
            final q = _searchCtrl.text.trim().toLowerCase();
            return (i['import_file_code'] as String).toLowerCase().contains(q) ||
                (i['po_number'] as String).toLowerCase().contains(q) ||
                (i['item_code'] as String).toLowerCase().contains(q) ||
                (i['item_name'] as String).toLowerCase().contains(q);
          }).toList();

          final totalInvoiced = filtered.fold<int>(0, (s, i) => s + (i['invoiced_qty'] as int));
          final totalReceived = filtered.fold<int>(0, (s, i) => s + (i['received_qty'] as int));
          final totalDamaged = filtered.fold<int>(0, (s, i) => s + (i['damaged_qty'] as int));
          final totalShortage = filtered.fold<int>(0, (s, i) => s + (i['shortage_qty'] as int));
          final totalSamples = filtered.fold<int>(0, (s, i) => s + (i['samples_qty'] as int));
          final totalVariance = filtered.fold<int>(0, (s, i) => s + (i['variance_qty'] as int));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assessment_outlined, color: Colors.indigo, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.whReportInfoBannerTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.whReportInfoBannerSubtitle,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: Text(l.whReportExportExcelBtn),
                        onPressed: () => _exportWarehouseReceivedReportCsv(context, records),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KPI Metrics Bar
                Row(
                  children: [
                    Expanded(child: _buildMetricCard(l.whReportKpiInvoicedQty, l.whReportUnitsValue(totalInvoiced), Icons.receipt_long, Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.whReportKpiReceivedQty, l.whReportUnitsValue(totalReceived), Icons.inventory, AppTheme.emerald)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.whReportKpiDamagedQty, l.whReportUnitsValue(totalDamaged), Icons.broken_image, AppTheme.crimson)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.whReportKpiShortageQty, l.whReportUnitsValue(totalShortage), Icons.remove_circle_outline, AppTheme.orange)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.whReportKpiSamplesQty, l.whReportUnitsValue(totalSamples), Icons.science, Colors.purple)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard(l.whReportKpiVarianceQty, '${totalVariance >= 0 ? "+" : ""}${l.whReportUnitsValue(totalVariance)}', Icons.compare_arrows, totalVariance == 0 ? Colors.green : AppTheme.crimson)),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: l.whReportSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Report Table
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
                            const Icon(Icons.fact_check, color: AppTheme.cobalt, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.whReportTableSectionHeader,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(l.whReportNoDataFound)),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: [
                                DataColumn(label: Text(l.whReportColImportFile, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColPoNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColContainerAndTruck, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColItemAndDescription, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColInvoicedQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColShortageQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColDamagedQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColSamplesQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColReceivedQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColVarianceQty, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(l.whReportColReceiptStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((item) {
                                final variance = item['variance_qty'] as int;
                                return DataRow(cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.charcoal.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(item['import_file_code'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                    ),
                                  ),
                                  DataCell(Text(item['po_number'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                  DataCell(Text(item['container_info'])),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item['item_code'], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                                        Text(item['item_name'], style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text('${item['invoiced_qty']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text('${item['shortage_qty']}', style: TextStyle(color: item['shortage_qty'] > 0 ? AppTheme.orange : Colors.black87, fontWeight: FontWeight.bold))),
                                  DataCell(Text('${item['damaged_qty']}', style: TextStyle(color: item['damaged_qty'] > 0 ? AppTheme.crimson : Colors.black87, fontWeight: FontWeight.bold))),
                                  DataCell(Text('${item['samples_qty']}', style: TextStyle(color: item['samples_qty'] > 0 ? Colors.purple : Colors.black87, fontWeight: FontWeight.bold))),
                                  DataCell(Text('${item['received_qty']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                  DataCell(
                                    Text(
                                      '${variance >= 0 ? "+" : ""}$variance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: variance == 0 ? Colors.green : (variance < 0 ? AppTheme.crimson : Colors.blue),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.shade300),
                                      ),
                                      child: Text(
                                        l.whReportStatusApprovedAndReceived,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
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
                Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), overflow: TextOverflow.ellipsis),
                Text(title, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportWarehouseReceivedReportCsv(BuildContext context, List<WarehouseReceivingModel> records) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('Sorour Logistics ERP — تقرير الشحنات المستلمة بالمخزن ومطابقة الفروق تفصيلي (Warehouse GRN Audit Report)');
    buffer.writeln('تاريخ التصدير,${DateTime.now().toIso8601String().split('T')[0]}');
    buffer.writeln('');
    buffer.writeln('رقم إذن الاستلام (GRN),المستودع,تاريخ ووقت الوصول,رقم الشاحنة,اسم السائق,رقم الرصاصة,سلامة الرصاص,إجمالي الفاتورة,إجمالي المستلم السليم,إجمالي العجز,إجمالي التالف,نوع الفارق,حالة الشحنة,اسم الفاحص');

    for (final r in records) {
      buffer.writeln(
        '${r.grnCode},'
        '"${r.warehouseName.replaceAll('"', '""')}",'
        '${r.arrivalDatetime},'
        '"${(r.truckPlateNumber ?? "-").replaceAll('"', '""')}",'
        '"${(r.driverName ?? "-").replaceAll('"', '""')}",'
        '"${(r.sealNumber ?? "-").replaceAll('"', '""')}",'
        '${r.sealIntact ? "سليم" : "غير سليم"},'
        '${r.totalInvoicedQty},'
        '${r.totalAcceptedQty},'
        '${r.totalShortageQty},'
        '${r.totalDamagedQty},'
        '"${r.discrepancyType}",'
        '"${r.status}",'
        '"${r.inspectorName.replaceAll('"', '""')}"',
      );

      if (r.grnItems.isNotEmpty) {
        for (final item in r.grnItems) {
          buffer.writeln('  -> صنف تفصيلي,كود: ${item.itemCode},اسم: "${item.itemName.replaceAll('"', '""')}",فاتورة: ${item.invoicedQty},سليم: ${item.acceptedQty},عجز: ${item.shortageQty},تالف: ${item.damagedQty},حجر صحي: ${item.quarantineFlag ? "نعم" : "لا"}');
        }
      }
    }

    final filename = 'Phase6_Warehouse_Received_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    await FileSaveHelper.saveText(
      context: context,
      textContent: buffer.toString(),
      defaultFileName: filename,
      dialogTitle: 'حفظ تقرير استلام المخزن بصيغة Excel / CSV',
      allowedExtensions: ['csv', 'xlsx'],
    );
  }
}

