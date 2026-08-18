
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart' hide PackingListItemModel;
import '../../external_service_providers/providers/partners_provider.dart';
import '../../financial_approval/providers/financial_approval_provider.dart';
import '../../financial_approval/models/financial_approval_model.dart';
import '../../import_documentation/providers/import_documentation_provider.dart';
import '../../import_documentation/models/import_documentation_model.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_consultation/models/customs_consultation_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../projects/models/project_model.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/reopen_shipment_dialog.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/stop_shipment_dialog.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';
import '../widgets/close_shipment_dialog.dart';


class ImportFileDetailsDialog extends ConsumerStatefulWidget {
  final ImportFileModel file;
  final List<PurchaseOrderModel> linkedPOs;
  final Set<String> invoiceNumbers;
  final double totalPackingListCbm;
  final double totalPackingListWeight;
  final int totalPackingListsCount;
  final VoidCallback? onEditPressed;

  const ImportFileDetailsDialog({
    required this.file,
    required this.linkedPOs,
    required this.invoiceNumbers,
    required this.totalPackingListCbm,
    required this.totalPackingListWeight,
    required this.totalPackingListsCount,
    this.onEditPressed,
  });

  @override
  ConsumerState<ImportFileDetailsDialog> createState() => ImportFileDetailsDialogState();
}

class ImportFileDetailsDialogState extends ConsumerState<ImportFileDetailsDialog> {
  void _showVisualLoadPlanDialog(BuildContext context, List<PurchaseOrderModel> pos) {
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
      final fallbackWeight = widget.totalPackingListWeight > 0 ? widget.totalPackingListWeight : 500.0;
      baseCargoItems.add(CargoItem(
        itemId: '1',
        length: 120,
        width: 80,
        height: 100,
        weight: fallbackWeight,
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
                              _buildFileMetricPill('📦 إجمالي الطرود', '$totalPkgs طرد', AppTheme.cobalt),
                              const SizedBox(width: 8),
                              _buildFileMetricPill('⚖️ إجمالي الوزن', '${totalPlanWeight.toStringAsFixed(0)} kg', AppTheme.charcoal),
                              const SizedBox(width: 8),
                              _buildFileMetricPill('📐 إجمالي الحجم', '${totalPlanVolume.toStringAsFixed(3)} m³', Colors.orange.shade900),
                            ],
                          ),
                          Row(
                            children: [
                              _buildFileMetricPill('✅ يقبل الرص', '$stackableInActive طرد', Colors.green.shade800),
                              const SizedBox(width: 8),
                              _buildFileMetricPill('🚫 لا يقبل الرص', '$nonStackableInActive طرد', Colors.red.shade800),
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

  static Widget _buildFileMetricPill(String label, String value, Color color) {
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

  void _showContainerComparisonDialog(BuildContext context, ContainerDualRecommendationResult dualRec, double totalCbm, double totalWeightKg) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 3,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppTheme.cobalt),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تحليل خيارات الحاويات وسيناريوهات التحميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('إجمالي الشحنة: ${totalCbm.toStringAsFixed(2)} m³ | ${totalWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 820,
              height: 500,
              child: Column(
                children: [
                  Container(
                    color: AppTheme.charcoal,
                    child: const TabBar(
                      indicatorColor: AppTheme.cobalt,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(icon: Icon(Icons.layers), text: '📦 1. قابل للرص (Stackable)'),
                        Tab(icon: Icon(Icons.view_array), text: '🚫 2. غير قابل للرص (Non-Stackable)'),
                        Tab(icon: Icon(Icons.shuffle), text: '🔀 3. مزيج يقبل ولا يقبل (Mixed)'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildComparisonTable(dualRec.stackableResult),
                        _buildComparisonTable(dualRec.nonStackableResult),
                        _buildComparisonTable(dualRec.stackableResult),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonTable(ContainerRecommendationResult rec) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rec.isStackable ? AppTheme.emerald.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade800),
            ),
            child: Text('التوصية المعتمدة: ${rec.recommendationSummary}', style: TextStyle(fontWeight: FontWeight.bold, color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade900)),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppTheme.charcoal),
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('نوع الحاوية (Container Spec)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('العدد المطلوب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('السعة الفعالة CBM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('استغلال المساحة %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('استغلال الوزن %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...rec.comparisonDetails.map((detail) {
                final spec = detail['spec'] as ContainerSpec;
                final reqCount = detail['reqCount'] as int;
                final effVol = detail['effectiveVolumeCbm'] as double;
                final spaceUtil = detail['spaceUtil'] as double;
                final payloadUtil = detail['payloadUtil'] as double;
                final isBest = spec.code == rec.recommendedContainerCode;

                return TableRow(
                  decoration: BoxDecoration(color: isBest ? AppTheme.cobalt.withOpacity(0.08) : null),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          if (isBest) const Icon(Icons.star, color: Colors.amber, size: 16),
                          if (isBest) const SizedBox(width: 4),
                          Text('${spec.code} (${spec.name})', style: TextStyle(fontWeight: isBest ? FontWeight.bold : FontWeight.normal, color: isBest ? AppTheme.cobalt : AppTheme.charcoal)),
                        ],
                      ),
                    ),
                    Padding(padding: const EdgeInsets.all(8), child: Text('$reqCount حاوية', style: TextStyle(fontWeight: isBest ? FontWeight.bold : FontWeight.normal))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${effVol.toStringAsFixed(1)} m³')),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${spaceUtil.toStringAsFixed(1)}%', style: TextStyle(color: spaceUtil > 80 ? Colors.green : Colors.black, fontWeight: FontWeight.bold))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${payloadUtil.toStringAsFixed(1)}%', style: TextStyle(color: payloadUtil > 80 ? Colors.green : Colors.black, fontWeight: FontWeight.bold))),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final allPOs = ref.watch(purchaseOrdersProvider).purchaseOrders;
    final liveLinkedPOs = allPOs.where((p) =>
        (p.importFileId != null && p.importFileId == file.importFileId) ||
        (file.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == file.importFileCode) ||
        (file.poIds != null && p.poId != null && file.poIds!.contains(p.poId))).toList();
    final linkedPOs = liveLinkedPOs.isNotEmpty ? liveLinkedPOs : widget.linkedPOs;

    // Recalculate live CBM & Gross Weight & Packing List counts from the linked POs
    double liveCbm = 0.0;
    double liveWeight = 0.0;
    int livePlCount = 0;
    for (final po in linkedPOs) {
      if (po.packingListItems.isNotEmpty) {
        livePlCount += po.packingListItems.length;
        for (final pl in po.packingListItems) {
          liveCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
          liveWeight += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.qtyPkg * pl.grossWeightUnitKg));
        }
      } else {
        liveCbm += po.totalCbm;
        liveWeight += po.totalGrossWeightKg;
      }
    }

    final totalPackingListCbm = liveCbm > 0 ? liveCbm : widget.totalPackingListCbm;
    final totalPackingListWeight = liveWeight > 0 ? liveWeight : widget.totalPackingListWeight;
    final totalPackingListsCount = livePlCount > 0 ? livePlCount : widget.totalPackingListsCount;
    final invoiceNumbers = widget.invoiceNumbers;

    final dualRec = ContainerRequirementEngine.calculateBoth(
      totalCbm: totalPackingListCbm,
      totalWeightKg: totalPackingListWeight,
    );
    final modeRec = dualRec.modeRecommendation;

    final List<CargoItem> baseCargoItems = [];
    int itemCounter = 1;
    for (final po in linkedPOs) {
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
      final fallbackWeight = totalPackingListWeight > 0 ? totalPackingListWeight : 500.0;
      baseCargoItems.add(CargoItem(
        itemId: '1',
        length: 120,
        width: 80,
        height: 100,
        weight: fallbackWeight,
        rotate: true,
        isStackable: true,
      ));
    }

    // Run the 3 plans
    final planStackable = ContainerRequirementEngine.planShipment(baseCargoItems, forceStackable: true);
    final planNonStackable = ContainerRequirementEngine.planShipment(baseCargoItems, forceStackable: false);
    final planMixed = ContainerRequirementEngine.planShipment(baseCargoItems, forceStackable: null);

    // Helpers to compute fleet string and metrics
    String getFleetText(List<ContainerPackingResult> pList) {
      final Map<String, int> counts = {};
      for (final p in pList) {
        if (p.containerCode != 'FAILED') {
          counts[p.containerCode] = (counts[p.containerCode] ?? 0) + 1;
        }
      }
      return counts.isEmpty ? '1 x 40HC' : counts.entries.map((e) => '${e.value} x ${e.key}').join(' + ');
    }

    final stackableFleet = getFleetText(planStackable);
    final nonStackableFleet = getFleetText(planNonStackable);
    final mixedFleet = getFleetText(planMixed);

    final stackableTotalCapVol = planStackable.fold(0.0, (s, p) => s + p.spec.internalVolumeCbm);
    final stackableTotalCapPay = planStackable.fold(0.0, (s, p) => s + p.spec.maxPayloadKg);
    final stackableSpaceUtil = stackableTotalCapVol > 0 ? (planStackable.fold(0.0, (s, p) => s + p.totalVolume) / stackableTotalCapVol * 100) : 0.0;
    final stackablePayloadUtil = stackableTotalCapPay > 0 ? (planStackable.fold(0.0, (s, p) => s + p.totalWeight) / stackableTotalCapPay * 100) : 0.0;

    final nonStackableTotalCapVol = planNonStackable.fold(0.0, (s, p) => s + p.spec.internalVolumeCbm);
    final nonStackableTotalCapPay = planNonStackable.fold(0.0, (s, p) => s + p.spec.maxPayloadKg);
    final nonStackableSpaceUtil = nonStackableTotalCapVol > 0 ? (planNonStackable.fold(0.0, (s, p) => s + p.totalVolume) / nonStackableTotalCapVol * 100) : 0.0;
    final nonStackablePayloadUtil = nonStackableTotalCapPay > 0 ? (planNonStackable.fold(0.0, (s, p) => s + p.totalWeight) / nonStackableTotalCapPay * 100) : 0.0;

    final mixedTotalCapVol = planMixed.fold(0.0, (s, p) => s + p.spec.internalVolumeCbm);
    final mixedTotalCapPay = planMixed.fold(0.0, (s, p) => s + p.spec.maxPayloadKg);
    final mixedSpaceUtil = mixedTotalCapVol > 0 ? (planMixed.fold(0.0, (s, p) => s + p.totalVolume) / mixedTotalCapVol * 100) : 0.0;
    final mixedPayloadUtil = mixedTotalCapPay > 0 ? (planMixed.fold(0.0, (s, p) => s + p.totalWeight) / mixedTotalCapPay * 100) : 0.0;

    final mixedStackCount = baseCargoItems.where((i) => i.isStackable).length;
    final mixedNonStackCount = baseCargoItems.where((i) => !i.isStackable).length;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_special, color: AppTheme.cobalt, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل ملف الشحنة: ${file.customFileNumber ?? file.importFileCode} (${file.companyName})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'كود الشحنة الرسمي: ${file.importFileCode} | المورد: ${file.supplierName} | الحالة: ${file.status}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 920,
        height: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Metric Summary Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 ملخص الفواتير وأحجام التعبئة المرتبطة بملف الاستيراد:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'عدد الفواتير وأرقامها',
                            '${invoiceNumbers.length} فواتير',
                            subtitle: invoiceNumbers.isEmpty ? 'لا توجد فواتير' : invoiceNumbers.join(', '),
                            icon: Icons.receipt_long,
                            color: AppTheme.cobalt,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            'إجمالي الـ CBM من الباكينج ليست',
                            '${totalPackingListCbm.toStringAsFixed(3)} m³',
                            subtitle: 'مجموع الـ CBM من كافه الباكينج ليست',
                            icon: Icons.view_in_ar,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            'إجمالي الوزن القائم (Gross Wt)',
                            '${totalPackingListWeight.toStringAsFixed(0)} kg',
                            subtitle: 'مجموع الوزن من كافه الباكينج ليست',
                            icon: Icons.fitness_center,
                            color: AppTheme.emerald,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            'أوامر الشراء المرتبطة',
                            '${linkedPOs.length} POs',
                            subtitle: '$totalPackingListsCount قوائم تعبئة (Packing Lists)',
                            icon: Icons.shopping_bag,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ACID & Expiry Tracking Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: file.isCustomsReleased
                      ? Colors.green.shade50.withOpacity(0.5)
                      : (file.acidNumber != null ? Colors.blue.shade50.withOpacity(0.5) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: file.isCustomsReleased
                        ? Colors.green.shade300
                        : (file.acidNumber != null ? Colors.blue.shade300 : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: file.isCustomsReleased
                          ? AppTheme.emerald.withOpacity(0.15)
                          : (file.acidNumber != null ? AppTheme.cobalt.withOpacity(0.15) : Colors.grey.shade200),
                      child: Icon(
                        file.isCustomsReleased
                            ? Icons.verified_user
                            : (file.acidNumber != null ? Icons.hourglass_top : Icons.pending_actions),
                        color: file.isCustomsReleased
                            ? AppTheme.emerald
                            : (file.acidNumber != null ? AppTheme.cobalt : Colors.grey),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '📌 بيانات القيد الجمركي المبدئي (ACID Status & Expiry):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: file.isCustomsReleased
                                      ? AppTheme.emerald
                                      : (file.acidNumber != null ? AppTheme.cobalt : AppTheme.charcoal),
                                ),
                              ),
                              if (file.isCustomsReleased)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '✅ صُرفت من الجمرك (معفى من التنبيهات)',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else if (file.acidNumber != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade800,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '⏳ قيد التخليص والصرف',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (file.acidNumber != null && file.acidNumber!.isNotEmpty) ...[
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('رقم الـ ACID: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    SelectableText(
                                      file.acidNumber!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                    ),
                                  ],
                                ),
                                if (file.acidRequestDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('تاريخ الطلب: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(file.acidRequestDate!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                if (file.acidIssueDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('تاريخ الإصدار: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(file.acidIssueDate!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                if (file.acidExpiryDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('تاريخ الصلاحية: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(
                                        file.acidExpiryDate!,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                                      ),
                                    ],
                                  ),
                                if (file.acidExecutionDays != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green.shade300, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 12, color: AppTheme.emerald),
                                        const SizedBox(width: 4),
                                        Text(
                                          'أيام التنفيذ: ${file.acidExecutionDays} يوم',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            const Text(
                              'لم يتم استخراج رقم ACID بعد لهذا الملف. يمكنك بدء إجراءات طلب واستخراج الـ ACID من قسم نافذة والـ ACID.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                          if (file.form4No != null && file.form4No!.isNotEmpty) ...[
                            const Divider(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('نموذج 4 البنكي: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                                    SelectableText(file.form4No!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                                  ],
                                ),
                                if (file.form4RequestDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('تاريخ الطلب: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(file.form4RequestDate!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                if (file.form4ReceivedDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('تاريخ الاستلام: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(file.form4ReceivedDate!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.emerald)),
                                    ],
                                  ),
                                if (file.form4ExecutionDays != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.shade300, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.speed, size: 12, color: AppTheme.cobalt),
                                        const SizedBox(width: 4),
                                        Text(
                                          'أيام تنفيذ نموذج 4: ${file.form4ExecutionDays} يوم',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Linked Purchase Orders Table
              const Text(
                '🛒 قائمة أوامر الشراء التفصيلية المرتبطة بهذا الملف (Linked Purchase Orders):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 10),
              linkedPOs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text('لا توجد أوامر شراء مرتبطة بهذا الملف حالياً.'),
                    )
                  : Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(1.4),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1.8),
                        3: FlexColumnWidth(1.6),
                        4: FlexColumnWidth(1.4),
                        5: FlexColumnWidth(1.0),
                        6: FlexColumnWidth(1.5),
                        7: FlexColumnWidth(1.0),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: AppTheme.charcoal),
                          children: [
                            Padding(padding: EdgeInsets.all(8), child: Text('رقم أمر الشراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('رقم الفاتورة المبدئية PI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('المورد الأجنبي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('طريقة وشروط السداد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('قيمة الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('قوائم التعبئة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('CBM / الوزن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...linkedPOs.map((po) {
                          final poPlCbm = po.packingListItems.isNotEmpty
                              ? po.packingListItems.fold(0.0, (s, pl) => s + (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm))
                              : po.totalCbm;
                          final poPlWeight = po.packingListItems.isNotEmpty
                              ? po.packingListItems.fold(0.0, (s, pl) => s + (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg)))
                              : po.totalGrossWeightKg;
                          final plCount = po.packingListItems.length;

                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                              Padding(padding: const EdgeInsets.all(8), child: Text(po.proformaInvoiceNumber ?? '-')),
                              Padding(padding: const EdgeInsets.all(8), child: Text(po.supplierName ?? '-')),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                                  child: Text(po.paymentTerms ?? 'غير محدد', style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                              Padding(padding: const EdgeInsets.all(8), child: Text('$plCount بند تعبئة', style: const TextStyle(fontWeight: FontWeight.w600))),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${poPlCbm.toStringAsFixed(3)} m³ / ${poPlWeight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(8), child: Text(po.status, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt))),
                            ],
                          );
                        }),
                      ],
                    ),
              const SizedBox(height: 18),

              // CARGO STACKING & CONTAINER REQUIREMENT WIDGET (MD-019.1)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '🚚 نتائج احتمالات رص الحاويات وتوزيع الشحنة (Cargo Stacking Scenarios):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cobalt,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.table_chart, size: 14, color: Colors.white),
                              label: const Text(
                                'مقارنة الحالات (Matrix)',
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _showContainerComparisonDialog(
                                context,
                                dualRec,
                                totalPackingListCbm,
                                totalPackingListWeight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emerald,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.view_in_ar, size: 14, color: Colors.white),
                              label: const Text(
                                'مخطط رص الحاويات (Load Plan)',
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _showVisualLoadPlanDialog(context, linkedPOs),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3 Scenarios stacked under each other:
                    // 1. All Stackable
                    _buildScenarioResultCard(
                      title: '📦 الاحتمال الأول: بضائع تقبل الرص بالكامل (All Stackable Cargo)',
                      fleet: stackableFleet,
                      description: 'رص متعدد الطبقات (Multi-Layer Stacking) لكافة الطرود لاستغلال كامل ارتفاع وسعة الحاوية.',
                      badgeColor: AppTheme.emerald,
                      containerCount: planStackable.length,
                      spaceUtil: stackableSpaceUtil,
                      payloadUtil: stackablePayloadUtil,
                      detailsText: 'الأسطول الموصى به: $stackableFleet',
                    ),
                    const SizedBox(height: 8),

                    // 2. All Non-Stackable
                    _buildScenarioResultCard(
                      title: '🚫 الاحتمال الثاني: بضائع لا تقبل الرص (All Non-Stackable Cargo)',
                      fleet: nonStackableFleet,
                      description: 'إلزام وضع كافة الطرود على أرضية الحاوية فوق طبالي خشبية (z = 0) وحجز الفراغ الرأسي لمنع التلف.',
                      badgeColor: Colors.orange.shade800,
                      containerCount: planNonStackable.length,
                      spaceUtil: nonStackableSpaceUtil,
                      payloadUtil: nonStackablePayloadUtil,
                      detailsText: 'الأسطول الموصى به: $nonStackableFleet',
                    ),
                    const SizedBox(height: 8),

                    // 3. Mixed Stacking (Actual cargo composition)
                    _buildScenarioResultCard(
                      title: '🔀 الاحتمال الثالث: مزيج يقبل ولا يقبل الرص (Mixed Stacking Cargo)',
                      fleet: mixedFleet,
                      description: 'توزيع الشحنة الفعلي: $mixedNonStackCount طرد غير قابل للرص على الأرضية + $mixedStackCount طرد قابل للرص متعدد الطبقات.',
                      badgeColor: AppTheme.cobalt,
                      containerCount: planMixed.length,
                      spaceUtil: mixedSpaceUtil,
                      payloadUtil: mixedPayloadUtil,
                      detailsText: 'الأسطول الفعلي للشحنة: $mixedFleet',
                      isHighlighted: true,
                    ),

                    // SECTION: Saved Shipping Scenarios Evaluation Studies
                    const SizedBox(height: 14),
                    Consumer(
                      builder: (context, ref, child) {
                        final shippingState = ref.watch(shippingScenariosProvider);
                        final linkedStudies = shippingState.sessions.where((s) => s.importFileId == widget.file.importFileId).toList();

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.directions_boat, color: AppTheme.cobalt, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '🚢 دراسات وسيناريوهات الشحن المسجلة للشحنة (Saved Shipping Evaluation Studies)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (linkedStudies.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    'لا توجد دراسات تقييم شحن مسجلة لهذا الملف حالياً (يمكن إنشاؤها وربطها من شاشة سيناريوهات الشحن).',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 11.5),
                                  ),
                                )
                              else
                                Column(
                                  children: linkedStudies.map((s) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('كود الدراسة: ${s.sessionCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
                                              const SizedBox(width: 10),
                                              Expanded(child: Text(s.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: AppTheme.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                                child: Text('الخط الموصى به: ${s.recommendedScenarioProvider ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Mini report summary card for files
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('📅 موعد الوصول للمخزن المتوقع', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                          Text(s.avgExpectedWarehouseArrivalDate ?? 'غير محدد', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('⏱️ عدد أيام الجاهزية', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                          Text('${s.items.isNotEmpty ? s.items.first.readyForShippingDays : 0} يوم', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('⚡ أسرع خط وصولاً', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                          Text(s.earliestArrivalScenarioProvider ?? 'غير محدد', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                                          Text('وصول: ${s.earliestArrivalDate ?? ""}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('🐢 أبطأ خط وصولاً', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                          Text(s.latestArrivalScenarioProvider ?? 'غير محدد', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                                                          Text('وصول: ${s.latestArrivalDate ?? ""}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'CRD: ${s.cargoReadyDate} | مكان الاستلام: ${s.pickUpAddress ?? "غير محدد"} | متوسط مدة الترانزيت: ${s.avgExpectedTransitDays} يوم',
                                            style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                                          ),
                                          if (s.items.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: s.items.map((opt) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: opt.isRecommended ? Colors.green.shade50 : Colors.grey.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: opt.isRecommended ? Colors.green : Colors.grey.shade300),
                                                  ),
                                                  child: Text(
                                                    '${opt.providerName} (${opt.vesselName}) | POL: ${opt.polName ?? "-"} ➔ POD: ${opt.podName ?? "-"} | إبحار: ${opt.sailingDate} | وصول: ${opt.expectedWarehouseArrivalDate}',
                                                    style: TextStyle(fontSize: 10.5, fontWeight: opt.isRecommended ? FontWeight.bold : FontWeight.normal, color: AppTheme.charcoal),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Smart Recommendation Banner Box
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            modeRec.isAirSuggested
                                ? Icons.airplanemode_active
                                : (modeRec.isLclSuggested ? Icons.inventory : Icons.directions_boat),
                            color: modeRec.isAirSuggested
                                ? Colors.purple
                                : (modeRec.isLclSuggested ? Colors.amber.shade900 : AppTheme.cobalt),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚢 ${modeRec.reasonAr}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: modeRec.isAirSuggested
                                        ? Colors.purple.shade900
                                        : (modeRec.isLclSuggested ? Colors.amber.shade900 : AppTheme.charcoal),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الأسطول الموصى به للشحنة: $mixedFleet (${modeRec.recommendedModeAr})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (file.status != 'Closed' && widget.onEditPressed != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
            label: const Text('تعديل ملف الاستيراد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              widget.onEditPressed!();
            },
          ),
        if (file.status != 'Closed')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
            label: const Text('إغلاق وإيقاف الشحنة عند هذه المرحلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (c) => CloseShipmentDialog(
                  importFileId: file.importFileId,
                  importFileCode: file.customFileNumber ?? file.importFileCode,
                  currentPhaseName: file.currentStage,
                ),
              );
            },
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }

  Widget _buildScenarioResultCard({
    required String title,
    required String fleet,
    required String description,
    required Color badgeColor,
    required int containerCount,
    required double spaceUtil,
    required double payloadUtil,
    required String detailsText,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlighted ? badgeColor.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? badgeColor : Colors.grey.shade300,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: badgeColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  fleet,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: AppTheme.charcoal),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFileMetricPill('عدد الحاويات', '$containerCount حاوية', badgeColor),
              const SizedBox(width: 8),
              _buildFileMetricPill('استغلال المساحة والحجم', '${spaceUtil.toStringAsFixed(1)}%', Colors.orange.shade900),
              const SizedBox(width: 8),
              _buildFileMetricPill('استغلال الوزن', '${payloadUtil.toStringAsFixed(1)}%', AppTheme.charcoal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, {required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }
}
