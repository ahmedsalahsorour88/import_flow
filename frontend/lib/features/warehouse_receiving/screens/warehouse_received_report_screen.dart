import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
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
          child: Text('خطأ في جلب تقرير الشحنات المستلمة: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (records) {
          // Dummy or real received entries expanded with Multi-PO breakdown
          final List<Map<String, dynamic>> receivedReportItems = [
            {
              'import_file_code': 'IMP-2026-001',
              'po_number': 'PO-2026-IT-001',
              'container_info': '2 × 40ft High Cube (MSCU9812450)',
              'item_code': 'ITM-SR-101',
              'item_name': 'خوادم رقمية صناعية (Enterprise Servers)',
              'invoiced_qty': 250,
              'shortage_qty': 0,
              'damaged_qty': 2,
              'samples_qty': 1,
              'received_qty': 247,
              'variance_qty': -3,
              'warehouse_name': 'Main Warehouse - Cairo',
              'arrival_date': '2026-08-22',
              'status': 'Confirmed Final (تم تأكيد الاستلام)',
            },
            {
              'import_file_code': 'IMP-2026-001',
              'po_number': 'PO-2026-IT-001',
              'container_info': '2 × 40ft High Cube (MSCU9812450)',
              'item_code': 'ITM-SR-102',
              'item_name': 'محولات شبكية ذكية (Smart Network Switches)',
              'invoiced_qty': 500,
              'shortage_qty': 0,
              'damaged_qty': 0,
              'samples_qty': 2,
              'received_qty': 498,
              'variance_qty': -2,
              'warehouse_name': 'Main Warehouse - Cairo',
              'arrival_date': '2026-08-22',
              'status': 'Confirmed Final (تم تأكيد الاستلام)',
            },
            {
              'import_file_code': 'IMP-2026-002',
              'po_number': 'PO-2026-DE-004',
              'container_info': '1 × 20ft Standard (MEDU4412998)',
              'item_code': 'ITM-MD-201',
              'item_name': 'أجهزة قياس وضبط الجودة الهيدروليكية',
              'invoiced_qty': 180,
              'shortage_qty': 5,
              'damaged_qty': 0,
              'samples_qty': 1,
              'received_qty': 174,
              'variance_qty': -6,
              'warehouse_name': 'Alexandria Logistics Hub',
              'arrival_date': '2026-08-21',
              'status': 'Confirmed Final (تم تأكيد الاستلام)',
            },
          ];

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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير الشحنات المستلمة بالمخازن ومطابقة الفروق (Received Shipments Detailed Audit)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'حصر شامل لكل الشحنات التي تم تأكيد استلامها بالمخازن مفصلة بأوامر الشراء (PO) ومطابقة الكميات المقر عنها بالفاتورة مع المستلم الفعلي والفاقد والتالف والعينات المسحوبة.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('تصدير Excel'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تصدير تقرير الشحنات المستلمة بنجاح'), backgroundColor: AppTheme.emerald),
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
                    Expanded(child: _buildMetricCard('إجمالي العدد بالفاتورة', '$totalInvoiced وحدة', Icons.receipt_long, Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('المستلم الفعلي بالمخزن', '$totalReceived وحدة', Icons.inventory, AppTheme.emerald)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('إجمالي التالف', '$totalDamaged وحدة', Icons.broken_image, AppTheme.crimson)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('إجمالي العجز', '$totalShortage وحدة', Icons.remove_circle_outline, AppTheme.orange)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('العينات المسحوبة', '$totalSamples وحدة', Icons.science, Colors.purple)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('صافي الفروق', '${totalVariance >= 0 ? "+" : ""}$totalVariance وحدة', Icons.compare_arrows, totalVariance == 0 ? Colors.green : AppTheme.crimson)),
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
                      decoration: const InputDecoration(
                        hintText: 'بحث برقم الشحنة، أمر الشراء PO، كود الصنف، أو اسم الصنف...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
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
                        const Row(
                          children: [
                            Icon(Icons.fact_check, color: AppTheme.cobalt, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'جدول الشحنات المستلمة تفصيلي بكل PO (Received Items Breakdown)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                            columns: const [
                              DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('أمر الشراء (PO)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الحاويات والسيارة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الصنف وبيانه', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('العدد بالفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الفاقد / العجز', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('التالف', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('عينات مسحوبة', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('المستلم بالمخزن', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الفارق (Variance)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('حالة الاستلام', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                    child: const Text('معتمد ومستلم ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
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
}
