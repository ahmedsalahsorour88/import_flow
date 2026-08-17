import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../import_files/models/import_file_model.dart';

import '../../import_files/widgets/close_shipment_dialog.dart';
import '../../import_files/widgets/shipment_milestone_tracker.dart';
import '../../smart_tasks/providers/smart_tasks_provider.dart';
import '../../shipment_updates/providers/shipment_updates_provider.dart';
import '../../shipment_updates/widgets/shipment_update_dialog.dart';
import '../providers/operational_dashboard_provider.dart';

class OperationalDashboardScreen extends ConsumerStatefulWidget {
  const OperationalDashboardScreen({super.key});

  @override
  ConsumerState<OperationalDashboardScreen> createState() => _OperationalDashboardScreenState();
}

class _OperationalDashboardScreenState extends ConsumerState<OperationalDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _phases = [
    {'id': 'Phase 1', 'name': 'P1: التخطيط والجدوى'},
    {'id': 'Phase 2', 'name': 'P2: الموافقة المالية'},
    {'id': 'Phase 3', 'name': 'P3: المستندات والـ ACID'},
    {'id': 'Phase 4', 'name': 'P4: حجز الشحن'},
    {'id': 'Phase 5', 'name': 'P5: الشحن و CargoX'},
    {'id': 'Phase 6', 'name': 'P6: التعريفة والجمرك'},
    {'id': 'Phase 7', 'name': 'P7: التخليص والسداد'},
    {'id': 'Phase 8', 'name': 'P8: استلام المخازن'},
    {'id': 'Phase 9', 'name': 'P9: التسوية المالية'},
    {'id': 'Phase 10', 'name': 'P10: إغلاق الملف'},
  ];

  static const List<String> _priorities = ['All', 'Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(operationalDashboardProvider);
    final notifier = ref.read(operationalDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('Operational Workspace Dashboard (2.9)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => notifier.fetchDashboard(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Executive KPI Summary Cards & Risk Alerts
            dashboardState.data.when(
              loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
              data: (data) => Column(
                children: [
                  _buildKpiCardsBar(data),
                  const SizedBox(height: 16),
                  _buildStreamlitLauncherBanner(),
                  const SizedBox(height: 16),
                  _buildQuickActionsBar(),
                  const SizedBox(height: 16),
                  _buildRiskAlertsBanner(data.shipments),
                  const SizedBox(height: 16),
                  _buildDailyCheckinsCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // 1. Phase 1 -> Phase 10 Pipeline Bar (Single-select interactive segment)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تصفية حسب مراحل الشحنة العشر (Phase 1 → Phase 10):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                        if (dashboardState.selectedPhase != null)
                          TextButton.icon(
                            onPressed: () => notifier.togglePhase(dashboardState.selectedPhase!),
                            icon: const Icon(Icons.clear, size: 14, color: AppTheme.crimson),
                            label: const Text('إلغاء تحديد المرحلة', style: TextStyle(color: AppTheme.crimson, fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _phases.map((p) {
                          final phaseId = p['id']!;
                          final isSelected = dashboardState.selectedPhase == phaseId;

                          int phaseCount = 0;
                          dashboardState.data.whenData((d) {
                            phaseCount = d.phaseCounts[phaseId] ?? 0;
                          });

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => notifier.togglePhase(phaseId),
                                borderRadius: BorderRadius.circular(6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.cobalt : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isSelected ? AppTheme.cobalt : Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        p['name']!,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppTheme.charcoal,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withOpacity(0.25) : AppTheme.cobalt.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$phaseCount',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.cobalt),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Control Bar (Priority Button Group, Customs Broker Dropdown & Debounced Search)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Priority Button Group
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الأولوية (Priority):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                        const SizedBox(height: 6),
                        ToggleButtons(
                          isSelected: _priorities.map((p) => dashboardState.selectedPriority == p).toList(),
                          onPressed: (index) => notifier.setPriority(_priorities[index]),
                          borderRadius: BorderRadius.circular(6),
                          selectedColor: Colors.white,
                          fillColor: AppTheme.cobalt,
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                          children: _priorities.map((p) => Text(p == 'All' ? 'الكل' : p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))).toList(),
                        ),
                      ],
                    ),

                    // Customs Broker Dynamic Select Dropdown
                    dashboardState.data.when(
                      loading: () => const SizedBox(width: 200, child: LinearProgressIndicator()),
                      error: (_, __) => const SizedBox(),
                      data: (data) {
                        final brokers = data.availableBrokers;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المخلص الجمركي (Customs Broker):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 240,
                              child: SearchableDropdownField<String>(
                                value: dashboardState.selectedBrokerName ?? 'All',
                                labelText: '',
                                items: [
                                  const SearchableDropdownItem(value: 'All', label: 'جميع المخلصين (All Brokers)'),
                                  ...brokers.map((b) => SearchableDropdownItem(value: b.brokerName, label: b.brokerName)),
                                ],
                                onChanged: (val) => notifier.setBroker(val),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Debounced Search Input (200-300ms)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('بحث سريع (Search):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 260,
                          height: 38,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'كود الشحنة، PO، المورد...',
                              prefixIcon: Icon(Icons.search, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) => notifier.setSearchQuery(val),
                          ),
                        ),
                      ],
                    ),

                    // Reset Filters Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                      onPressed: () {
                        _searchController.clear();
                        notifier.resetFilters();
                      },
                      icon: const Icon(Icons.restart_alt, size: 16, color: Colors.white),
                      label: const Text('إعادة ضبط الفلاتر', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Results Header & Table Data Area
            dashboardState.data.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (err, _) => Card(
                elevation: 1,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: AppTheme.crimson, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تعذر الاتصال بسيرفر الخادم (127.0.0.1:8000)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('يرجى التأكد من تشغيل خادم الباك إند (FastAPI Backend Server) أو الضغط على زر إعادة المحاولة.', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                        onPressed: () => notifier.fetchDashboard(),
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                        label: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (dashboardData) {
                final shipments = dashboardData.shipments;
                final count = dashboardData.shipmentCount;
                final dt = DateTime.tryParse(dashboardData.lastUpdatedAt) ?? DateTime.now();
                final lastUpdated = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

                return Column(
                  children: [
                    // Shipment Count & Timestamp Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عدد الشحنات المطابقة: $count شحنة',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                        ),
                        Text(
                          'آخر تحديث للبيانات: $lastUpdated',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Empty State vs Table
                    if (shipments.isEmpty)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('لا توجد شحنات مطابقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
                              const SizedBox(height: 6),
                              Text('لم يتم العثور على أي شحنات تطابق خيارات التصفية الحالية (AND combination).', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.resetFilters();
                                },
                                child: const Text('إلغاء الفلاتر وعرض الكل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: shipments.length,
                        itemBuilder: (context, idx) {
                          final s = shipments[idx];
                          return _buildShipmentCard(s);
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentCard(ImportFileModel s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(s.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                ),
                const SizedBox(width: 10),
                Text(s.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Text('→ ${s.supplierName}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const Spacer(),
                _buildPriorityBadge(s.priority),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المرحلة الحالية: ${s.currentModule}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('الخطوة التشغيلية: ${s.currentStage}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المخلص الجمركي: ${s.brokerName ?? "غير محدد"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('أمر الشراء: ${s.poNumber ?? "غير محدد"}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${s.progressPercent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 14)),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(value: s.progressPercent / 100.0, backgroundColor: Colors.grey.shade200, color: AppTheme.emerald),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Milestone Progress Tracker (Feature 2.6)
            ShipmentMilestoneTracker(importFile: s),

            // 🎯 Next Step & Target Action Card
            _buildNextStepCard(s),

            // 📋 Linked Smart Tasks TO-DO List
            _buildLinkedTasksSection(s),

            if (s.status == 'Closed' || s.closureReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: AppTheme.crimson, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🚫 شحنة مغلقة [مرحلة الإيقاف: ${s.closedAtPhase ?? s.currentModule}] — السبب: ${s.closureReason ?? s.currentStage}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cobalt,
                    side: const BorderSide(color: AppTheme.cobalt),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.post_add_rounded, size: 14),
                  label: const Text('تسجيل تحديث يومي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => ShipmentUpdateDialog.show(
                    context,
                    initialFileId: s.importFileId,
                    initialFileCode: s.customFileNumber ?? s.importFileCode,
                    initialTargetPhase: s.currentModule,
                  ),
                ),
                const SizedBox(width: 8),
                if (s.status != 'Closed')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.white),
                    label: const Text('إغلاق وإيقاف الشحنة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final closed = await showDialog<bool>(
                        context: context,
                        builder: (c) => CloseShipmentDialog(
                          importFileId: s.importFileId,
                          importFileCode: s.customFileNumber ?? s.importFileCode,
                          currentPhaseName: s.currentModule,
                        ),
                      );
                      if (closed == true) {
                        ref.read(operationalDashboardProvider.notifier).fetchDashboard();
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepCard(ImportFileModel s) {
    if (s.status == 'Closed') return const SizedBox.shrink();

    String nextStepTitle = 'متابعة الإجراءات التشغيلية';
    String nextStepDesc = 'استكمال متطلبات المرحلة الحالية';
    String responsible = 'فريق الاستيراد';
    int targetNavIndex = 1;
    IconData actionIcon = Icons.arrow_forward;

    final mod = s.currentModule.toString();
    if (mod.contains('Phase 1') || mod.contains('BP-001') || mod.contains('BP-007')) {
      nextStepTitle = 'P2: الاعتماد المالي وصرف الدفعة';
      nextStepDesc = 'مراجعة الميزانية وإصدار طلب الصرف والتحويل البنكي للمورد';
      responsible = 'المدير المالي / الإدارة المالية';
      targetNavIndex = 8;
      actionIcon = Icons.monetization_on_outlined;
    } else if (mod.contains('Phase 2') || mod.contains('BP-012')) {
      nextStepTitle = 'P3: استخراج رقم ACID وتوثيق مستندات CargoX';
      nextStepDesc = 'تسجيل الشحنة على نافذة واستخراج الـ ACID المكون من 19 رقماً';
      responsible = 'أخصائي الاستيراد / نافذة';
      targetNavIndex = 11;
      actionIcon = Icons.description_outlined;
    } else if (mod.contains('Phase 3') || mod.contains('BP-015') || mod.contains('BP-019')) {
      nextStepTitle = 'P4: حجز الشحن وتأكيد رص الحاويات B/L';
      nextStepDesc = 'تأكيد حجز الباخرة مع الخط الملاحي وإصدار مسودة البوليصة وتأكيد الشحن';
      responsible = 'شركة الشحن / Freight Forwarder';
      targetNavIndex = 15;
      actionIcon = Icons.directions_boat_outlined;
    } else if (mod.contains('Phase 4')) {
      nextStepTitle = 'P5: تتبع الإبحار وتوثيق CargoX ومراقبة الوصول';
      nextStepDesc = 'متابعة إبحار السفينة وتاريخ الـ ETA المتوقع واستلام مستندات الشاحن';
      responsible = 'الناقل / المورد الأجنبي';
      targetNavIndex = 16;
      actionIcon = Icons.sailing_outlined;
    } else if (mod.contains('Phase 5')) {
      nextStepTitle = 'P6: وصول التنويه Arrival Notice وقيد إقرار 46 جمارك';
      nextStepDesc = 'استلام إخطار الوصول وتكليف المخلص الجمركي بفتح ملف الكشف الجمركي';
      responsible = 'المستخلص الجمركي (Customs Broker)';
      targetNavIndex = 17;
      actionIcon = Icons.receipt_long_outlined;
    } else if (mod.contains('Phase 6')) {
      nextStepTitle = 'P7: استكمال الكشف وسداد الرسوم وإصدار إذن الإفراج';
      nextStepDesc = 'متابعة المعاينة الجمركية وسحب العينات وسداد الضرائب والرسوم';
      responsible = 'المستخلص الجمركي (Customs Broker)';
      targetNavIndex = 17;
      actionIcon = Icons.verified_user_outlined;
    } else if (mod.contains('Phase 7')) {
      nextStepTitle = 'P8: النقل الداخلي واستلام المخازن وتوليد إذن GRN';
      nextStepDesc = 'تنسيق سيارات النقل واستلام البضاعة في المخازن وفحص الكميات والجودة';
      responsible = 'أمين المخزن / إدارة المخازن';
      targetNavIndex = 18;
      actionIcon = Icons.warehouse_outlined;
    } else if (mod.contains('Phase 8')) {
      nextStepTitle = 'P9: تسوية تكلفة الوصول الشاملة Landed Cost';
      nextStepDesc = 'تجميع كافة الفواتير ومصاريف النولون والجمارك واحتساب التكلفة الفعلية';
      responsible = 'الحسابات والمراجعة المالية';
      targetNavIndex = 19;
      actionIcon = Icons.calculate_outlined;
    } else if (mod.contains('Phase 9')) {
      nextStepTitle = 'P10: مراجعة شروط الأرشفة وإغلاق الملف التاريخي';
      nextStepDesc = 'التحقق من اكتمال كافة الفواتير والمستندات وإغلاق الملف نهائياً';
      responsible = 'مدير الاستيراد (Import Manager)';
      targetNavIndex = 20;
      actionIcon = Icons.archive_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cobalt.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cobalt,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(actionIcon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎯 النقطة التالية والإجراء القادم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.cobalt)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text('المسؤول: $responsible', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(nextStepTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal)),
                Text(nextStepDesc, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cobalt,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => selectNavigationIndex(ref, targetNavIndex),
            icon: const Icon(Icons.bolt, size: 14, color: Colors.white),
            label: const Text('تنفيذ الخطوة الآن', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedTasksSection(ImportFileModel s) {
    final tasksState = ref.watch(smartTasksProvider);
    final linkedTasks = tasksState.tasks.where((t) => t.importFileId == s.importFileId && t.status != 'Completed').toList();
    if (linkedTasks.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: AppTheme.charcoal, size: 16),
              const SizedBox(width: 6),
              Text('مهام الـ TO-DO المفتوحة للشحنة (${linkedTasks.length} مهام):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.charcoal)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => selectNavigationIndex(ref, 30),
                icon: const Icon(Icons.open_in_new, size: 12),
                label: const Text('إدارة كل المهام', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...linkedTasks.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: t.status == 'Completed',
                    visualDensity: VisualDensity.compact,
                    activeColor: AppTheme.emerald,
                    onChanged: (val) async {
                      if (val == true) {
                        await ref.read(smartTasksProvider.notifier).updateTask(t.taskId, {'status': 'Completed'});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ تم إنجاز المهمة بنجاح: ${t.title}'),
                              backgroundColor: AppTheme.emerald,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (t.priority == 'Critical')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Critical', style: TextStyle(color: Colors.red, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    t.dueDate ?? '',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKpiCardsBar(dynamic data) {
    final tasksState = ref.watch(smartTasksProvider);
    final m = tasksState.metrics;

    final todaysTasksCount = m?.todaysTasks ?? 0;
    final pendingTasksCount = m?.pendingTasks ?? 0;
    final upcomingShipmentsCount = data.shipments.where((s) => s.status != 'Closed').length;
    final arrivingThisWeekCount = data.shipments.where((s) => s.requiredEta != null || s.currentModule.toString().contains('Phase 5')).length;
    final etaChangesCount = data.shipments.where((s) => s.requiredEta != null).length;
    final waitingForPaymentCount = data.shipments.where((s) => s.currentModule.toString().contains('Phase 2')).length;
    final waitingForForm4Count = data.shipments.where((s) => s.form4No == null || s.form4No.toString().isEmpty).length;
    final pendingRequirementsCount = data.shipments.where((s) => s.acidNumber == null || s.form46No == null).length;
    final highPriorityAlertsCount = data.shipments.where((s) => s.priority == 'High' || s.priority == 'Critical').length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildKpiCard("Today's Tasks", '$todaysTasksCount مهام', 'المهام المطلوب تنفيذها اليوم', Icons.today, AppTheme.cobalt),
        _buildKpiCard("Pending Tasks", '$pendingTasksCount مهام', 'المهام التي لم يتم الانتهاء منها', Icons.pending_actions, AppTheme.orange),
        _buildKpiCard("Upcoming Shipments", '$upcomingShipmentsCount شحنات', 'متوقع وصولها القادم', Icons.near_me, AppTheme.emerald),
        _buildKpiCard("Arriving This Week", '$arrivingThisWeekCount شحنات', 'وصول بالأسبوع الحالي', Icons.directions_boat, AppTheme.cobalt),
        _buildKpiCard("ETA Changes", '$etaChangesCount تعديلات', 'تم تعديل موعد وصولها', Icons.edit_calendar, Colors.purple),
        _buildKpiCard("Waiting For Payment", '$waitingForPaymentCount متوقفة', 'موافقات مالية معلقة (Phase 2)', Icons.monetization_on, AppTheme.crimson),
        _buildKpiCard("Waiting For Form 4", '$waitingForForm4Count شحنات', 'إجراءات نموذج 4 بنك مصر', Icons.account_balance, AppTheme.orange),
        _buildKpiCard("Pending Requirements", '$pendingRequirementsCount شحنات', 'مستندات وموافقات غير مكتملة', Icons.rule, AppTheme.crimson),
        _buildKpiCard("High Priority Alerts", '$highPriorityAlertsCount تنبيهات', 'أولوية عالي / حرج (Critical)', Icons.warning_amber, Colors.red.shade900),
      ],
    );
  }

  Widget _buildKpiCard(String title, String mainValue, String subtitle, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(mainValue, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskAlertsBanner(List<dynamic> shipments) {
    final criticals = shipments.where((s) => s.priority == 'Critical' || s.priority == 'High').toList();
    if (criticals.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.amber.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.orange, size: 22),
                SizedBox(width: 8),
                Text('مركز التنبيهات والمخاطر التشغيلية (Risk & Escalation Center):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: criticals.take(4).map((s) {
                return Chip(
                  avatar: const Icon(Icons.warning, color: AppTheme.crimson, size: 14),
                  label: Text('${s.importFileCode} — ${s.currentStage}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.amber.shade200)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    if (priority == 'High') {
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade900;
    } else if (priority == 'Critical') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    } else if (priority == 'Medium') {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(priority, style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 11)),
    );
  }

  Widget _buildDailyCheckinsCard() {
    final updatesState = ref.watch(shipmentUpdatesProvider);
    final logs = updatesState.logs;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.published_with_changes, color: AppTheme.cobalt, size: 22),
                const SizedBox(width: 8),
                const Text('سجل التحديثات التشغيلية واليومية المباشرة (Daily Check-ins & Live Log):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  onPressed: () => ShipmentUpdateDialog.show(context),
                  icon: const Icon(Icons.add, size: 14, color: Colors.white),
                  label: const Text('إضافة تحديث يومي', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              const Text('لا توجد تحديثات يومية مسجلة اليوم.', style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: logs.take(5).map((l) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    width: 260,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(l.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
                            const Spacer(),
                            Text(l.logDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${l.targetPhase} — ${l.updateCategory}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal)),
                        const SizedBox(height: 4),
                        Text(l.note, style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Actions & Registration Shortcuts Bar ───────────────────────────

  Widget _buildQuickActionsBar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: AppTheme.cobalt, size: 22),
                SizedBox(width: 8),
                Text(
                  'روابط الاختصارات السريعة لإنشاء وإدخال السجلات (Quick Create & Register Shortcuts):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildQuickActionButton(
                  'إنشاء مشروع جديد',
                  Icons.assignment_outlined,
                  AppTheme.cobalt,
                  () => selectNavigationIndex(ref, 21), // Projects
                ),
                _buildQuickActionButton(
                  'إنشاء ملف استيرادي',
                  Icons.folder_special_outlined,
                  AppTheme.emerald,
                  () => selectNavigationIndex(ref, 1), // Import Files
                ),
                _buildQuickActionButton(
                  'إنشاء شركة مستوردة',
                  Icons.domain_outlined,
                  AppTheme.orange,
                  () => selectNavigationIndex(ref, 22), // Import Companies
                ),
                _buildQuickActionButton(
                  'إنشاء مورد خارجي',
                  Icons.business_outlined,
                  AppTheme.charcoal,
                  () => selectNavigationIndex(ref, 23), // Foreign Suppliers
                ),
                _buildQuickActionButton(
                  'إنشاء بنك / شريك',
                  Icons.account_balance_outlined,
                  AppTheme.cobalt,
                  () => selectNavigationIndex(ref, 24), // Partners & Banks
                ),
                _buildQuickActionButton(
                  'إدخال تعريفة جمركية',
                  Icons.description_outlined,
                  AppTheme.orange,
                  () => selectNavigationIndex(ref, 26), // Customs Tariff
                ),
                _buildQuickActionButton(
                  'إدخال موانئ ومواقع',
                  Icons.location_on_outlined,
                  AppTheme.emerald,
                  () => selectNavigationIndex(ref, 27), // Ports & Locations
                ),
                _buildQuickActionButton(
                  'إدخال عملة جديدة',
                  Icons.currency_exchange_outlined,
                  AppTheme.charcoal,
                  () => selectNavigationIndex(ref, 28), // Currencies
                ),
                _buildQuickActionButton(
                  'تعديل سعر صرف جديد',
                  Icons.rate_review_outlined,
                  AppTheme.cobalt,
                  () => selectNavigationIndex(ref, 28), // Exchange Rates
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 10, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  // ─── Streamlit Operations Board Interactive Banner ────────────────────────
  Widget _buildStreamlitLauncherBanner() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cobalt.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cobalt.withOpacity(0.4)),
              ),
              child: const Icon(Icons.dashboard_customize_outlined, color: AppTheme.cobalt, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'لوحة تتبع ومراحل الشحنات التفاعلية (Native 6-Phase Operations Board)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'NEW',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    'لوحة بصرية متكاملة مدمجة داخل البرنامج (6 مراحل كبرى — 21 خطوة تشغيلية) تدعم تتبع وتعدد المراحل النشطة ونقل الشحنات لحظياً.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => selectNavigationIndex(ref, 48), // Native Lifecycle Board Screen
              icon: const Icon(Icons.launch, size: 16, color: Colors.white),
              label: const Text(
                'فتح لوحة المراحل التفاعلية',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

