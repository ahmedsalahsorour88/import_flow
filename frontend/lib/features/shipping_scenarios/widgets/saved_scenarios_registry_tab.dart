import 'package:flutter/services.dart';
import '../../../core/utils/container_requirement_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../models/shipping_scenario_model.dart';
import '../providers/shipping_scenarios_provider.dart';

class SavedScenariosRegistryTab extends ConsumerStatefulWidget {
  final void Function(ShippingEvaluationModel session) onEditSession;
  final VoidCallback onSwitchToEvaluator;

  const SavedScenariosRegistryTab({
    super.key,
    required this.onEditSession,
    required this.onSwitchToEvaluator,
  });

  @override
  ConsumerState<SavedScenariosRegistryTab> createState() => _SavedScenariosRegistryTabState();
}

class _SavedScenariosRegistryTabState extends ConsumerState<SavedScenariosRegistryTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shippingScenariosProvider);
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;
    final projectsList = ref.watch(projectsProvider).value ?? [];

    return _buildHistoryRegistryTab(state, poList, projectsList);
  }

  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    final totalSessions = state.sessions.length;
    final activeSessions = state.sessions.where((s) => s.isActive).length;
    final avgTransitAll = totalSessions > 0
        ? state.sessions.fold<double>(0, (sum, s) => sum + s.avgExpectedTransitDays) / totalSessions
        : 0.0;
    final withRecommendation = state.sessions.where((s) => s.recommendedScenarioProvider != null && s.recommendedScenarioProvider!.isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Top Summary Cards ───────────────────────────────────────────────
        Container(
          color: AppTheme.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _histStatCard(
                icon: Icons.folder_copy_rounded,
                label: 'إجمالي الدراسات',
                value: '$totalSessions',
                color: AppTheme.cobalt,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.check_circle_rounded,
                label: 'نشطة',
                value: '$activeSessions',
                color: AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.schedule_rounded,
                label: 'متوسط ترانزيت',
                value: avgTransitAll > 0 ? '${avgTransitAll.toStringAsFixed(1)} يوم' : '-',
                color: Colors.purple.shade300,
              ),
              const SizedBox(width: 10),
              _histStatCard(
                icon: Icons.recommend_rounded,
                label: 'مع توصية',
                value: '$withRecommendation',
                color: Colors.orange.shade300,
              ),
              const Spacer(),
              // Force Refresh button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تحديث السجل', style: TextStyle(fontSize: 13)),
                onPressed: () => ref.read(shippingScenariosProvider.notifier).fetchSessions(),
              ),
            ],
          ),
        ),

        // Data Actions Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: MasterDataToolbarWidget(
            moduleEndpoint: 'shipping-evaluations',
            title: 'Shipping_Evaluations',
            onRefreshNeeded: () => ref.read(shippingScenariosProvider.notifier).fetchSessions(),
          ),
        ),

        // ─── Search & Filter Bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث بكود الدراسة، العنوان، أو الملاحظات...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cobalt),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(shippingScenariosProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cobalt, width: 1.5)),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() {
                    ref.read(shippingScenariosProvider.notifier).setSearchQuery(v.trim());
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  FilterChip(
                    avatar: Icon(
                      state.showInactive ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: state.showInactive ? AppTheme.crimson : Colors.grey,
                    ),
                    label: Text(
                      state.showInactive ? 'إظهار الملغية' : 'إخفاء الملغية',
                      style: TextStyle(
                        fontSize: 12,
                        color: state.showInactive ? AppTheme.crimson : Colors.grey.shade700,
                        fontWeight: state.showInactive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: state.showInactive,
                    selectedColor: AppTheme.crimson.withOpacity(0.12),
                    checkmarkColor: AppTheme.crimson,
                    onSelected: (val) => ref.read(shippingScenariosProvider.notifier).toggleShowInactive(val),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Sessions count chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.sessions.length} نتيجة',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                ),
              ),
            ],
          ),
        ),

        // ─── Data Table ──────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.cobalt),
                      SizedBox(height: 16),
                      Text('جارٍ تحميل سجل الدراسات...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : state.sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'لا توجد نتائج مطابقة للبحث'
                                : 'لا توجد دراسات محفوظة بعد',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'قم بإنشاء دراسة جديدة من تبويب "Shipping Scenarios Evaluator"',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 48,
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 60,
                            horizontalMargin: 16,
                            columnSpacing: 20,
                            dividerThickness: 0.5,
                            headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                            columns: const [
                              DataColumn(label: SizedBox(
                                width: 168,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text('العمليات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )),
                              DataColumn(label: Text('📋 كود الدراسة')),
                              DataColumn(label: Text('📁 ملف الاستيراد')),
                              DataColumn(label: Text('📝 العنوان')),
                              DataColumn(label: Text('⏱️ متوسط الترانزيت')),
                              DataColumn(label: Text('🏭 موعد الوصول')),
                              DataColumn(label: Text('⭐ الخط الموصى به')),
                              DataColumn(label: Text('🔢 الخيارات')),
                              DataColumn(label: Text('🔗 أمر الشراء')),
                              DataColumn(label: Text('📅 CRD')),
                              DataColumn(label: Text('📍 الاستلام')),
                            ],
                            rows: state.sessions.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final sess = entry.value;
                              final isEven = idx.isEven;
                              final rowColor = !sess.isActive
                                  ? Colors.red.shade50
                                  : isEven
                                      ? Colors.white
                                      : Colors.grey.shade50;

                              return DataRow(
                                color: WidgetStateProperty.all(rowColor),
                                onSelectChanged: (_) => _showSessionDetailsDialog(context, sess),
                                cells: [
                                  // ⚡ 1. ACTIONS — أول عمود دائماً مرئي
                                  DataCell(
                                    RowActionsPill(
                                      onView: () => _showSessionDetailsDialog(context, sess),
                                      onEdit: () => widget.onEditSession(sess),
                                      onPrint: () => _showPrintReportDialog(context, sess),
                                      onDelete: () async {
                                        if (sess.isActive) {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Row(
                                                children: [
                                                  Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
                                                  SizedBox(width: 8),
                                                  Text('تأكيد الحذف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              content: Text(
                                                'هل أنت متأكد من حذف الدراسة "${sess.sessionCode}"؟\nيمكن استعادتها لاحقاً من قائمة "إظهار الملغية".',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('إلغاء'),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
                                                  icon: const Icon(Icons.delete_rounded, size: 16),
                                                  label: const Text('حذف'),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(shippingScenariosProvider.notifier).deleteSession(sess.sessionId!);
                                          }
                                        } else {
                                          await ref.read(shippingScenariosProvider.notifier).restoreSession(sess.sessionId!);
                                        }
                                      },
                                      viewTooltip: 'عرض التقييم والدراسة',
                                      editTooltip: 'تعديل دراسة الشحن',
                                      printTooltip: 'طباعة تقرير الدراسة',
                                      deleteTooltip: sess.isActive ? 'حذف الدراسة' : 'استعادة الدراسة',
                                    ),
                                  ),

                                  // 2. Study Code
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showSessionDetailsDialog(context, sess),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cobalt.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!sess.isActive)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 4),
                                                child: Icon(Icons.block, size: 12, color: AppTheme.crimson),
                                              ),
                                            Text(
                                              sess.sessionCode,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: sess.isActive ? AppTheme.cobalt : AppTheme.crimson,
                                                fontSize: 12,
                                                decoration: sess.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3. Import File
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.charcoal.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sess.importFileCode ?? (sess.importFileId != null ? 'IMP-${sess.importFileId}' : '—'),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 4. Title
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        sess.title ?? 'Shipping Transit Study',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 5. Avg Transit
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${sess.avgExpectedTransitDays.toStringAsFixed(1)} يوم',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 6. Avg WH Arrival
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warehouse_rounded, size: 14, color: AppTheme.emerald.withOpacity(0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          sess.avgExpectedWarehouseArrivalDate ?? '—',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.emerald,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 7. Recommended Carrier
                                  DataCell(
                                    sess.recommendedScenarioProvider != null && sess.recommendedScenarioProvider!.isNotEmpty
                                        ? Container(
                                            constraints: const BoxConstraints(maxWidth: 150),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blue.shade600, Colors.blue.shade400],
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    sess.recommendedScenarioProvider!,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text('—', style: TextStyle(color: Colors.grey.shade400)),
                                  ),

                                  // 8. Options Count
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${sess.items.length} خيار',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 9. Linked PO / Project
                                  DataCell(
                                    sess.poNumber != null
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.receipt_long_rounded, size: 13, color: AppTheme.emerald),
                                              const SizedBox(width: 4),
                                              Text('PO: ${sess.poNumber}', style: const TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          )
                                        : sess.projectName != null
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.folder_special_rounded, size: 13, color: Colors.orange.shade600),
                                                  const SizedBox(width: 4),
                                                  Text('PRJ: ${sess.projectName}', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                                                ],
                                              )
                                            : Text('مستقل', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ),

                                  // 10. CRD Date
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(sess.cargoReadyDate, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),

                                  // 11. Pick-up Address
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        sess.pickUpAddress ?? '—',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  /// بطاقة إحصائية صغيرة في شريط الـ History
  Widget _histStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  void _showSessionDetailsDialog(BuildContext context, ShippingEvaluationModel sess) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Shipping Transit Study Details (${sess.sessionCode})'),
        content: SizedBox(
          width: 950,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sess.title ?? 'Shipping Study', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('CRD Date: ${sess.cargoReadyDate} | Pick-up: ${sess.pickUpAddress ?? "N/A"} | Form 4: ${sess.avgForm4Days}d | Clearance: ${sess.avgClearanceDays}d', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 20),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Forwarder / Provider')),
                      DataColumn(label: Text('Total Cost')),
                      DataColumn(label: Text('Total WH Days')),
                      DataColumn(label: Text('Customs Broker')),
                      DataColumn(label: Text('Vessel')),
                      DataColumn(label: Text('POL ➔ POD')),
                      DataColumn(label: Text('Sailing')),
                      DataColumn(label: Text('ETA')),
                      DataColumn(label: Text('Free Time')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: sess.items.asMap().entries.map((e) {
                      final item = e.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('${e.key + 1}')),
                          DataCell(Text(item.providerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                          DataCell(Text('${item.expectedTotalDaysToWarehouse} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                          DataCell(Text(item.customsBrokerName ?? '-')),
                          DataCell(Text('${item.vesselName} (${item.voyageNumber ?? "-"})')),
                          DataCell(Text('${item.polName ?? "-"} ➔ ${item.podName ?? "-"}', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(item.sailingDate)),
                          DataCell(Text(item.estimatedArrivalDate)),
                          DataCell(Text('${item.freeTimeDays} days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          DataCell(Text(item.isRecommended ? 'Recommended ⭐' : item.isExcludedFromAverage ? 'Excluded 🚫' : 'Normal')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showPrintReportDialog(BuildContext context, ShippingEvaluationModel sess) {
    final buffer = StringBuffer();
    buffer.writeln('=====================================================');
    buffer.writeln('ImportFlow ERP - Shipping Scenario & Quote Report (${sess.sessionCode})');
    buffer.writeln('Study Title: ${sess.title ?? "N/A"}');
    buffer.writeln('Cargo Ready Date: ${sess.cargoReadyDate} | Pick-up: ${sess.pickUpAddress ?? "N/A"}');
    buffer.writeln('Linked Import File: ${sess.importFileCode ?? "N/A"} | PO: ${sess.poNumber ?? "N/A"}');
    buffer.writeln('Avg Transit: ${sess.avgExpectedTransitDays} days | WH Arrival: ${sess.avgExpectedWarehouseArrivalDate ?? "N/A"}');
    buffer.writeln('Recommended Line: ${sess.recommendedScenarioProvider ?? "N/A"}');
    buffer.writeln('=====================================================\n');
    buffer.writeln('Provider,Shipping Line,Customs Broker,Vessel,Voyage,POL,POD,Sailing,ETA,Free Time,Delay,Total WH Days,Total Cost,Risk,Status');
    for (var item in sess.items) {
      buffer.writeln('"${item.providerName}","${item.providerName}","${item.customsBrokerName ?? "-"}","${item.vesselName}","${item.voyageNumber ?? "-"}","${item.polName ?? "-"}","${item.podName ?? "-"}","${item.sailingDate}","${item.estimatedArrivalDate}",${item.freeTimeDays},${item.expectedLineDelayDays},${item.expectedTotalDaysToWarehouse},"${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}","${item.riskLevel}","${item.isRecommended ? "Recommended" : item.isExcludedFromAverage ? "Excluded" : "Normal"}"');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ تم نسخ تقرير الدراسة والعروض للحافظة بنجاح! جاهز للطباعة (Ctrl+P)'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _showContainerComparisonDialog(
    BuildContext context,
    ContainerDualRecommendationResult dualRec,
    double cbm,
    double weightKg,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🚚 مقارنة حالة الرص القابل وغير القابل للرص (Dual Container Matrix)'),
        content: SizedBox(
          width: 650,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجمالي CBM الشحنة: ${cbm.toStringAsFixed(3)} m³ | إجمالي الوزن: ${weightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('الخاصية / Scenario', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('📦 قابل للرص (Stackable)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                      Padding(padding: EdgeInsets.all(8), child: Text('🚫 غير قابل للرص (Non-Stackable)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('نوع الحاوية الموصى بها')),
                      Padding(padding: const EdgeInsets.all(8), child: Text(dualRec.stackableResult.recommendedContainerCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(dualRec.nonStackableResult.recommendedContainerCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('عدد الحاويات المطلوبة')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.stackableResult.requiredContainersCount} حاويات', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.nonStackableResult.requiredContainersCount} حاويات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('نسبة استغلال حجم الحاوية')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.stackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.nonStackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showVisualLoadPlanDialog(BuildContext context, List<PurchaseOrderModel> pos, double totalCbm, double totalWeight) {
    final List<CargoItem> baseCargoItems = [];
    int itemCounter = 1;

    for (final po in pos) {
      for (final pl in po.packingListItems) {
        for (int q = 0; q < pl.qtyPkg.toInt(); q++) {
          double lCm = pl.lengthCm;
          double wCm = pl.widthCm;
          double hCm = pl.heightCm;
          if (pl.unit == 'mm') {
            lCm /= 10;
            wCm /= 10;
            hCm /= 10;
          } else if (pl.unit == 'm') {
            lCm *= 100;
            wCm *= 100;
            hCm *= 100;
          }

          baseCargoItems.add(CargoItem(
            itemId: '$itemCounter',
            length: lCm,
            width: wCm,
            height: hCm,
            weight: pl.grossWeightUnitKg > 0 ? pl.grossWeightUnitKg : (pl.totalGrossWeightKg / (pl.qtyPkg > 0 ? pl.qtyPkg : 1)),
            rotate: true,
            isStackable: pl.isStackable,
            packageType: pl.packageType,
          ));
          itemCounter++;
        }
      }
    }

    if (baseCargoItems.isEmpty) {
      baseCargoItems.add(CargoItem(
        itemId: '1',
        length: 120,
        width: 80,
        height: 100,
        weight: totalWeight > 0 ? totalWeight : 500.0,
        rotate: true,
        isStackable: true,
      ));
    }

    // Default active view mode: null = Actual/Mixed, true = All Stackable, false = All Non-Stackable
    bool? activeStackingMode = baseCargoItems.any((i) => !i.isStackable) ? null : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            // Compute plan dynamically based on the selected mode
            final plan = ContainerRequirementEngine.planShipment(
              baseCargoItems,
              forceStackable: activeStackingMode,
            );

            // Compute summary metrics for active plan
            final totalPkgs = baseCargoItems.length;
            final stackableInActive = activeStackingMode == true
                ? totalPkgs
                : (activeStackingMode == false ? 0 : baseCargoItems.where((c) => c.isStackable).length);
            final nonStackableInActive = totalPkgs - stackableInActive;

            final totalPlanWeight = plan.fold(0.0, (s, p) => s + p.totalWeight);
            final totalPlanVolume = plan.fold(0.0, (s, p) => s + p.totalVolume);

            // Determine container fleet text (e.g. 2 x 40HC or 2 x 40HC + 1 x 20GP)
            final Map<String, int> containerCounts = {};
            for (final p in plan) {
              if (p.containerCode != 'FAILED') {
                containerCounts[p.containerCode] = (containerCounts[p.containerCode] ?? 0) + 1;
              }
            }
            final fleetSummaryText = containerCounts.entries.map((e) => '${e.value} x ${e.key}').join(' + ');

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.view_in_ar, color: AppTheme.cobalt, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'مخطط ومحاكاة رص الحاويات (Visual 2.5D/3D Container Load Planner)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.cobalt),
                    ),
                    child: Text(
                      'الأسطول المطلوب: $fleetSummaryText (${plan.length} حاوية)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 980,
                height: 640,
                child: Column(
                  children: [
                    // 1. Scenario / Stacking Mode Switcher (All 3 required states)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🔄 اختر سيناريو الرص للمعاينة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                          ),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('📦 1. بضائع تقبل الرص (All Stackable)'),
                                selected: activeStackingMode == true,
                                selectedColor: AppTheme.emerald,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == true ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = true);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('🚫 2. بضائع لا تقبل الرص (All Non-Stackable)'),
                                selected: activeStackingMode == false,
                                selectedColor: Colors.orange.shade800,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == false ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('🔀 3. مزيج يقبل ولا يقبل الرص (Mixed Stacking)'),
                                selected: activeStackingMode == null,
                                selectedColor: AppTheme.cobalt,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == null ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = null);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Metrics Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildLoadMetricPill('📦 إجمالي الطرود', '$totalPkgs طرد', AppTheme.cobalt),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('⚖️ إجمالي الوزن', '${totalPlanWeight.toStringAsFixed(0)} kg', AppTheme.charcoal),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('📐 إجمالي الحجم', '${totalPlanVolume.toStringAsFixed(3)} m³', Colors.orange.shade900),
                            ],
                          ),
                          Row(
                            children: [
                              _buildLoadMetricPill('✅ يقبل الرص', '$stackableInActive طرد', Colors.green.shade800),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('🚫 لا يقبل الرص', '$nonStackableInActive طرد', Colors.red.shade800),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Table summary of container loads
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(2.4),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                          children: const [
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الحاوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الأصناف والطرود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الوزن المحمّل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('استغلال المساحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('توزيع الرص والسلامة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        ...plan.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final res = entry.value;
                          final placedIds = res.placedItems.map((p) => p.item.itemId).join(', ');

                          String statusText = '';
                          if (res.containerCode == 'FAILED') {
                            statusText = 'فشل التحميل (طرود كبيرة الحجم/الوزن)';
                          } else {
                            final nonStackInThis = res.placedItems.where((p) => !p.item.isStackable).length;
                            if (nonStackInThis > 0) {
                              statusText = 'تحتوي على $nonStackInThis طرد غير قابل للرص مثبت على الأرضية';
                            } else {
                              statusText = 'رص متعدد الطبقات متوافق (${(res.totalVolume / res.spec.internalVolumeCbm * 100).toStringAsFixed(1)}%)';
                            }
                          }

                          final double spaceUtil = res.spec.internalVolumeCbm > 0 ? (res.totalVolume / res.spec.internalVolumeCbm) * 100 : 0.0;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  res.containerCode == 'FAILED' ? 'فشل الرص' : '$idx: ${res.spec.code}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(placedIds.isEmpty ? '-' : placedIds, style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(res.containerCode == 'FAILED' ? '-' : '${res.totalWeight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text('${spaceUtil.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusText.contains('فشل')
                                        ? Colors.red.shade800
                                        : (statusText.contains('غير قابل') ? Colors.brown.shade800 : Colors.green.shade800),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. Tab view or list for visual container layout drawings
                    Expanded(
                      child: ListView.builder(
                        itemCount: plan.length,
                        itemBuilder: (ctx, pIdx) {
                          final res = plan[pIdx];
                          if (res.containerCode == 'FAILED') {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
                              child: Text(
                                'الأصناف التالية تفوق سعة حاويات الشحن: ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'مخطط الحاوية #${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                      ),
                                      Row(
                                        children: [
                                          const Text('🪵 طبالي خشبية أرضية', style: TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                            child: Text('الأبعاد الداخلية: ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 10, color: AppTheme.cobalt)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Side View (Left Wall Removed) - High Fidelity Realistic Container
                                  Container(
                                    height: 190,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: ContainerLoadPlanPainter(plan: res, isTopView: false),
                                      child: Container(),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Top View (Roof Removed)
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: ContainerLoadPlanPainter(plan: res, isTopView: true),
                                      child: Container(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  label: const Text('إغلاق المخطط'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildLoadMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
