import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      titleAr: 'رصيد ومطابقة البضاعة في الطريق (GIT)',
      headerIcon: Icons.local_shipping,
      headerColor: AppTheme.emerald,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (_) {},
      body: gitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('خطأ في جلب بيانات البضاعة بالطريق: $err', style: const TextStyle(color: Colors.red)),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير رصيد البضاعة في الطريق (Goods In Transit Ledger - Detailed by PO)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'هذا التقرير يمثل رصيد البضائع المشحونة طبقاً للفواتير وقوائم التعبئة المعتمدة، ويتم تحديثه وخصم الكميات تلقائياً فور تأكيد الاستلام النهائي بالمخزن.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('تصدير Excel'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تصدير تقرير البضاعة في الطريق بنجاح'), backgroundColor: AppTheme.emerald),
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
                    Expanded(child: _buildMetricCard('الشحنات في الطريق', '$uniqueFiles شحنة', Icons.folder_open, Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('أوامر الشراء (POs)', '$uniquePos أمر شراء', Icons.receipt_long, Colors.purple)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('إجمالي العدد بالفاتورة', '${totalQty.toStringAsFixed(0)} قطعة', Icons.category, Colors.indigo)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('إجمالي الكراتين / الطرود', '$totalPkgs طرد', Icons.all_inbox, Colors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('عدد الحاويات النشطة', '$totalContainers حاوية', Icons.directions_boat, AppTheme.emerald)),
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
                              decoration: const InputDecoration(
                                hintText: 'بحث برقم الشحنة، أمر الشراء PO، كود أو اسم الصنف...',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedStatusFilter,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('جميع البضائع')),
                              DropdownMenuItem(value: 'In-Transit Only', child: Text('🟢 البضاعة في الطريق فقط (الرصيد الفعلي)')),
                              DropdownMenuItem(value: 'Delivered Only', child: Text('✅ الشحنات المستلمة بالمخزن فقط')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatusFilter = val);
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                            tooltip: 'تحديث الرصيد',
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
                        const Row(
                          children: [
                            Icon(Icons.table_chart_outlined, color: AppTheme.emerald, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'جدول رصيد البضاعة في الطريق تفصيلي لكل أمر شراء (GIT Inventory Breakdown)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (filteredItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('لا توجد بضائع في الطريق مطابقة لمعايير البحث حالياً.')),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: const [
                                DataColumn(label: Text('رقم ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('رقم أمر الشراء (PO)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('كود الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('اسم وبيان الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('العدد بالفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('عدد الكراتين / الطرود', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('عدد الحاويات ونوعها', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('تاريخ الاعتماد', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('حالة الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                  DataCell(Text('${item.invoicedQty.toStringAsFixed(0)} قطعة', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
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
                                        isDelivered ? 'تم الاستلام بالمخزن ✅' : '🟢 في الطريق (GIT)',
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
