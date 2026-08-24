import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/universal_entity_extractor_dialog.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/widgets/close_shipment_dialog.dart';
import '../../import_files/widgets/shipment_milestone_tracker.dart';
import '../../lifecycle_board/models/lifecycle_board_model.dart';
import '../../lifecycle_board/providers/lifecycle_board_provider.dart';
import '../../shipment_updates/providers/shipment_updates_provider.dart';
import '../../shipment_updates/widgets/shipment_update_dialog.dart';
import '../../smart_tasks/providers/smart_tasks_provider.dart';
import '../providers/operational_dashboard_provider.dart';

class OperationalDashboardScreen extends ConsumerStatefulWidget {
  const OperationalDashboardScreen({super.key});

  @override
  ConsumerState<OperationalDashboardScreen> createState() => _OperationalDashboardScreenState();
}

class _OperationalDashboardScreenState extends ConsumerState<OperationalDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _lifecyclePhases = [
    {
      'phase_id': 1,
      'name_ar': 'المرحلة 1: التخطيط والدراسات',
      'name_en': 'Phase 1: Planning & Studies',
      'color': Color(0xFF2980B9),
      'steps': [
        {'code': 'STEP_01', 'name_ar': '1. دراسات النولون', 'name_en': '1. Freight Studies'},
        {'code': 'STEP_02', 'name_ar': '2. الدراسات الجمركية', 'name_en': '2. Customs Studies'},
        {'code': 'STEP_03', 'name_ar': '3. اشتراطات الاستيراد', 'name_en': '3. Import Requirements'},
      ],
    },
    {
      'phase_id': 2,
      'name_ar': 'المرحلة 2: الاعتمادات والـ ACID',
      'name_en': 'Phase 2: Approvals & ACID',
      'color': Color(0xFF27AE60),
      'steps': [
        {'code': 'STEP_04', 'name_ar': '4. اعتماد الميزانية', 'name_en': '4. Budget Approval'},
        {'code': 'STEP_05', 'name_ar': '5. إصدار ACID نافذة', 'name_en': '5. Nafeza ACID Issue'},
      ],
    },
    {
      'phase_id': 3,
      'name_ar': 'المرحلة 3: الحجز وتدقيق المستندات',
      'name_en': 'Phase 3: Booking & Docs',
      'color': Color(0xFFE67E22),
      'steps': [
        {'code': 'STEP_06', 'name_ar': '6. تأكيد الحجز الملاحي', 'name_en': '6. Booking Confirmation'},
        {'code': 'STEP_07', 'name_ar': '7. تخصيص الحاويات', 'name_en': '7. Container Alloc.'},
        {'code': 'STEP_08', 'name_ar': '8. مراجعة المسودات', 'name_en': '8. Draft Review'},
        {'code': 'STEP_09', 'name_ar': '9. الاعتماد النهائي', 'name_en': '9. Final Approval'},
      ],
    },
    {
      'phase_id': 4,
      'name_ar': 'المرحلة 4: شحن CargoX والبنك',
      'name_en': 'Phase 4: CargoX & Banking',
      'color': Color(0xFF8E44AD),
      'steps': [
        {'code': 'STEP_10', 'name_ar': '10. رفع CargoX', 'name_en': '10. CargoX Upload'},
        {'code': 'STEP_11', 'name_ar': '11. أصول المستندات', 'name_en': '11. Original Docs'},
        {'code': 'STEP_12', 'name_ar': '12. نموذج 4 البنكي', 'name_en': '12. Bank Form 4'},
      ],
    },
    {
      'phase_id': 5,
      'name_ar': 'المرحلة 5: التخليص الجمركي والإفراج',
      'name_en': 'Phase 5: Clearance & Release',
      'color': Color(0xFFC0392B),
      'steps': [
        {'code': 'STEP_13', 'name_ar': '13. إقرار 46 ك.م', 'name_en': '13. Form 46 KM'},
        {'code': 'STEP_14', 'name_ar': '14. الكشف والتثمين', 'name_en': '14. Inspection & Val.'},
        {'code': 'STEP_15', 'name_ar': '15. سحب العينات', 'name_en': '15. Sample Drawing'},
        {'code': 'STEP_16', 'name_ar': '16. محضر المعاينة', 'name_en': '16. Inspection Report'},
        {'code': 'STEP_17', 'name_ar': '17. سداد الرسوم', 'name_en': '17. Duty Payment'},
        {'code': 'STEP_18', 'name_ar': '18. الأرضيات والحراسات', 'name_en': '18. Demurrage & Guard'},
      ],
    },
    {
      'phase_id': 6,
      'name_ar': 'المرحلة 6: المخازن والتسوية النهائية',
      'name_en': 'Phase 6: Storage & Settlement',
      'color': Color(0xFF16A085),
      'steps': [
        {'code': 'STEP_19', 'name_ar': '19. إذن إضافة المخازن', 'name_en': '19. Warehouse GRN'},
        {'code': 'STEP_20', 'name_ar': '20. تسوية التكلفة Landed', 'name_en': '20. Landed Cost Settlement'},
        {'code': 'STEP_21', 'name_ar': '21. إغلاق وأرشفة الملف', 'name_en': '21. File Archive & Close'},
      ],
    },
  ];

  static const List<String> _priorities = ['All', 'Low', 'Medium', 'High', 'Critical'];


  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(operationalDashboardProvider.notifier).fetchDashboard();
      ref.invalidate(lifecycleBoardSummaryProvider);
      ref.read(smartTasksProvider.notifier).fetchTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPriorityLabel(String p, AppLocalizations l) {
    switch (p) {
      case 'All':
        return l.priorityAll;
      case 'Low':
        return l.priorityLow;
      case 'Medium':
        return l.priorityMedium;
      case 'High':
        return l.priorityHigh;
      case 'Critical':
        return l.priorityCritical;
      default:
        return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(operationalDashboardProvider);
    final boardAsync = ref.watch(lifecycleBoardSummaryProvider);
    final notifier = ref.read(operationalDashboardProvider.notifier);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize, color: AppTheme.cobalt),
            const SizedBox(width: 10),
            Text(l.operationalDashboardTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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

            // 1. Shipment Lifecycle Operations Board Summary (6 Phases / 21 Steps)
            _buildLifecycleOperationsBoardSummary(context, ref, boardAsync, dashboardState, notifier),
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
                        Text(l.priority, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                        const SizedBox(height: 6),
                        ToggleButtons(
                          isSelected: _priorities.map((p) => dashboardState.selectedPriority == p).toList(),
                          onPressed: (index) => notifier.setPriority(_priorities[index]),
                          borderRadius: BorderRadius.circular(6),
                          selectedColor: Colors.white,
                          fillColor: AppTheme.cobalt,
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                          children: _priorities.map((p) => Text(_getPriorityLabel(p, l), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))).toList(),
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
                            Text(l.customsBrokerLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 240,
                              child: SearchableDropdownField<String>(
                                value: dashboardState.selectedBrokerName ?? 'All',
                                labelText: '',
                                items: [
                                  SearchableDropdownItem(value: 'All', label: l.allBrokers),
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
                        Text(l.quickSearchLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 260,
                          height: 38,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l.dashboardSearchHint,
                              prefixIcon: const Icon(Icons.search, size: 18),
                              isDense: true,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                      label: Text(l.resetFilters, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                            Text('${l.serverConnectionError} (${ApiConstants.serverUrl})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(l.serverConnectionHint, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                        onPressed: () => notifier.fetchDashboard(),
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                        label: Text(l.retry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                          '${l.matchingShipments}: $count ${l.shipmentCountUnit}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                        ),
                        Text(
                          '${l.lastUpdated}: $lastUpdated',
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
                              Text(l.noMatchingShipments, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
                              const SizedBox(height: 6),
                              Text(l.noMatchingShipmentsDesc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.resetFilters();
                                },
                                child: Text(l.clearFiltersShowAll, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final l = context.l10n;

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
                      Text('${l.currentPhase}: ${s.currentModule}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('${l.operationalStep}: ${s.currentStage}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l.customsBrokerLabel} ${s.brokerName ?? l.unassigned}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('${l.purchaseOrder} ${s.poNumber ?? l.unassigned}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
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
                        '🚫 ${l.closedShipment} [${s.closedAtPhase ?? s.currentModule}] — ${s.closureReason ?? s.currentStage}',
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
                  label: Text(l.recordDailyUpdate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                    label: Text(l.closeStopShipment, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final l = context.l10n;


    String nextStepTitle = isArabic ? 'متابعة الإجراءات التشغيلية' : 'Follow up operational procedures';
    String nextStepDesc = isArabic ? 'استكمال متطلبات المرحلة الحالية' : 'Complete requirements for the current phase';
    String responsible = isArabic ? 'فريق الاستيراد' : 'Import Team';
    int targetNavIndex = 1;
    IconData actionIcon = Icons.arrow_forward;

    final mod = s.currentModule.toString();
    if (mod.contains('Phase 1') || mod.contains('BP-001') || mod.contains('BP-007')) {
      nextStepTitle = isArabic ? 'P2: الاعتماد المالي وصرف الدفعة' : 'P2: Financial Approval & Payment';
      nextStepDesc = isArabic ? 'مراجعة الميزانية وإصدار طلب الصرف والتحويل البنكي للمورد' : 'Review budget, issue payment request and bank transfer to supplier';
      responsible = isArabic ? 'المدير المالي / الإدارة المالية' : 'Financial Manager';
      targetNavIndex = 8;
      actionIcon = Icons.monetization_on_outlined;
    } else if (mod.contains('Phase 2') || mod.contains('BP-012')) {
      nextStepTitle = isArabic ? 'P3: استخراج رقم ACID وتوثيق مستندات CargoX' : 'P3: Nafeza ACID & CargoX Docs';
      nextStepDesc = isArabic ? 'تسجيل الشحنة على نافذة واستخراج الـ ACID المكون من 19 رقماً' : 'Register shipment on Nafeza and obtain 19-digit ACID number';
      responsible = isArabic ? 'أخصائي الاستيراد / نافذة' : 'Import Specialist / Nafeza';
      targetNavIndex = 11;
      actionIcon = Icons.description_outlined;
    } else if (mod.contains('Phase 3') || mod.contains('BP-015') || mod.contains('BP-019')) {
      nextStepTitle = isArabic ? 'P4: حجز الشحن وتأكيد رص الحاويات B/L' : 'P4: Freight Booking & Container Alloc.';
      nextStepDesc = isArabic ? 'تأكيد حجز الباخرة مع الخط الملاحي وإصدار مسودة البوليصة وتأكيد الشحن' : 'Confirm vessel booking with carrier, issue draft B/L and confirm shipment';
      responsible = isArabic ? 'شركة الشحن / Freight Forwarder' : 'Freight Forwarder';
      targetNavIndex = 25;
      actionIcon = Icons.directions_boat_outlined;
    } else if (mod.contains('Phase 4')) {
      nextStepTitle = isArabic ? 'P5: تتبع الإبحار وتوثيق CargoX ومراقبة الوصول' : 'P5: Transit Tracking & CargoX';
      nextStepDesc = isArabic ? 'متابعة إبحار السفينة وتاريخ الـ ETA المتوقع واستلام مستندات الشاحن' : 'Monitor vessel transit, tracking ETA and receiving shipper documents';
      responsible = isArabic ? 'الناقل / المورد الأجنبي' : 'Carrier / Foreign Supplier';
      targetNavIndex = 26;
      actionIcon = Icons.sailing_outlined;
    } else if (mod.contains('Phase 5')) {
      nextStepTitle = isArabic ? 'P6: وصول التنويه Arrival Notice وقيد إقرار 46 جمارك' : 'P6: Arrival Notice & Declaration 46';
      nextStepDesc = isArabic ? 'استلام إخطار الوصول وتكليف المخلص الجمركي بفتح ملف الكشف الجمركي' : 'Receive arrival notice and assign broker for customs inspection file';
      responsible = isArabic ? 'المستخلص الجمركي (Customs Broker)' : 'Customs Broker';
      targetNavIndex = 23;
      actionIcon = Icons.receipt_long_outlined;
    } else if (mod.contains('Phase 6')) {
      nextStepTitle = isArabic ? 'P7: استكمال الكشف وسداد الرسوم وإصدار إذن الإفراج' : 'P7: Inspection & Duty Payment';
      nextStepDesc = isArabic ? 'متابعة المعاينة الجمركية وسحب العينات وسداد الضرائب والرسوم' : 'Follow up customs inspection, sampling and duty/tax payment';
      responsible = isArabic ? 'المستخلص الجمركي (Customs Broker)' : 'Customs Broker';
      targetNavIndex = 27;
      actionIcon = Icons.verified_user_outlined;
    } else if (mod.contains('Phase 7')) {
      nextStepTitle = isArabic ? 'P8: النقل الداخلي واستلام المخازن وتوليد إذن GRN' : 'P8: Inland Transport & GRN';
      nextStepDesc = isArabic ? 'تنسيق سيارات النقل واستلام البضاعة في المخازن وفحص الكميات والجودة' : 'Coordinate inland transport, receive goods in warehouse and verify quantities';
      responsible = isArabic ? 'أمين المخزن / إدارة المخازن' : 'Warehouse Custodian';
      targetNavIndex = 28;
      actionIcon = Icons.warehouse_outlined;
    } else if (mod.contains('Phase 8')) {
      nextStepTitle = isArabic ? 'P9: تسوية تكلفة الوصول الشاملة Landed Cost' : 'P9: Landed Cost Settlement';
      nextStepDesc = isArabic ? 'تجميع كافة الفواتير ومصاريف النولون والجمارك واحتساب التكلفة الفعلية' : 'Aggregate all invoices, freight and customs fees to calculate true landed cost';
      responsible = isArabic ? 'الحسابات والمراجعة المالية' : 'Finance & Auditing';
      targetNavIndex = 29;
      actionIcon = Icons.calculate_outlined;
    } else if (mod.contains('Phase 9')) {
      nextStepTitle = isArabic ? 'P10: مراجعة شروط الأرشفة وإغلاق الملف التاريخي' : 'P10: File Archive & Final Closure';
      nextStepDesc = isArabic ? 'التحقق من اكتمال كافة الفواتير والمستندات وإغلاق الملف نهائياً' : 'Verify completion of all documents and invoices, and permanently archive file';
      responsible = isArabic ? 'مدير الاستيراد (Import Manager)' : 'Import Manager';
      targetNavIndex = 30;
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
                    Text(l.nextStepAction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.cobalt)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text('${l.responsiblePerson}: $responsible', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
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
            label: Text(l.executeStepNow, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedTasksSection(ImportFileModel s) {
    final l = context.l10n;
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
              Text('${l.openShipmentTasks} (${linkedTasks.length} ${l.tasksCountUnit}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.charcoal)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => selectNavigationIndex(ref, 40),
                icon: const Icon(Icons.open_in_new, size: 12),
                label: Text(l.manageAllTasks, style: const TextStyle(fontSize: 11)),
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
                              content: Text('${l.taskCompletedSuccessfully}: ${t.title}'),
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
    final l = context.l10n;
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
        _buildKpiCard(l.kpiTodaysTasks, '$todaysTasksCount ${l.tasksCountUnit}', l.kpiTodaysTasksSub, Icons.today, AppTheme.cobalt),
        _buildKpiCard(l.kpiPendingTasks, '$pendingTasksCount ${l.tasksCountUnit}', l.kpiPendingTasksSub, Icons.pending_actions, AppTheme.orange),
        _buildKpiCard(l.kpiUpcomingShipments, '$upcomingShipmentsCount ${l.shipmentCountUnit}', l.kpiUpcomingShipmentsSub, Icons.near_me, AppTheme.emerald),
        _buildKpiCard(l.kpiArrivingThisWeek, '$arrivingThisWeekCount ${l.shipmentCountUnit}', l.kpiArrivingThisWeekSub, Icons.directions_boat, AppTheme.cobalt),
        _buildKpiCard(l.kpiEtaChanges, '$etaChangesCount', l.kpiEtaChangesSub, Icons.edit_calendar, Colors.purple),
        _buildKpiCard(l.kpiWaitingPayment, '$waitingForPaymentCount', l.kpiWaitingPaymentSub, Icons.monetization_on, AppTheme.crimson),
        _buildKpiCard(l.kpiWaitingForm4, '$waitingForForm4Count ${l.shipmentCountUnit}', l.kpiWaitingForm4Sub, Icons.account_balance, AppTheme.orange),
        _buildKpiCard(l.kpiPendingRequirements, '$pendingRequirementsCount ${l.shipmentCountUnit}', l.kpiPendingRequirementsSub, Icons.rule, AppTheme.crimson),
        _buildKpiCard(l.kpiHighPriorityAlerts, '$highPriorityAlertsCount', l.kpiHighPriorityAlertsSub, Icons.warning_amber, Colors.red.shade900),
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
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final l = context.l10n;
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
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.orange, size: 22),
                const SizedBox(width: 8),
                Text(l.riskAlertsCenter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
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
    final l = context.l10n;
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
                Text(l.dailyCheckinsLog, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  onPressed: () => ShipmentUpdateDialog.show(context),
                  icon: const Icon(Icons.add, size: 14, color: Colors.white),
                  label: Text(l.addDailyUpdate, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              Text(l.noDailyUpdates, style: const TextStyle(fontSize: 12, color: Colors.grey))
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
    final l = context.l10n;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Smart Extractor Header & Launch Buttons
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
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l.aiSmartExtractorTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, foregroundColor: Colors.white),
                        icon: const Icon(Icons.public, size: 16),
                        label: Text(l.smartExtractSupplier),
                        onPressed: () => UniversalEntityExtractorDialog.show(context, initialTarget: EntityTarget.supplier),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                        icon: const Icon(Icons.domain, size: 16),
                        label: Text(l.smartExtractCompany),
                        onPressed: () => UniversalEntityExtractorDialog.show(context, initialTarget: EntityTarget.company),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
                        icon: const Icon(Icons.handshake, size: 16),
                        label: Text(l.smartExtractPartner),
                        onPressed: () => UniversalEntityExtractorDialog.show(context, initialTarget: EntityTarget.partner),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                        icon: const Icon(Icons.account_balance, size: 16),
                        label: Text(l.smartExtractBank),
                        onPressed: () => UniversalEntityExtractorDialog.show(context, initialTarget: EntityTarget.bank),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.bolt, color: AppTheme.cobalt, size: 22),
                const SizedBox(width: 8),
                Text(
                  l.quickShortcutsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildQuickActionButton(
                  l.createNewProject,
                  Icons.assignment_outlined,
                  AppTheme.cobalt,
                  () => selectNavigationIndex(ref, 31), // Projects
                ),
                _buildQuickActionButton(
                  l.createNewImportFile,
                  Icons.folder_special_outlined,
                  AppTheme.emerald,
                  () => selectNavigationIndex(ref, 1), // Import Files
                ),
                _buildQuickActionButton(
                  l.createNewImportCompany,
                  Icons.domain_outlined,
                  AppTheme.orange,
                  () => selectNavigationIndex(ref, 32), // Import Companies
                ),
                _buildQuickActionButton(
                  l.createNewSupplier,
                  Icons.business_outlined,
                  AppTheme.charcoal,
                  () => selectNavigationIndex(ref, 33), // Foreign Suppliers
                ),
                _buildQuickActionButton(
                  l.createNewPartnerBank,
                  Icons.account_balance_outlined,
                  AppTheme.cobalt,
                  () => selectNavigationIndex(ref, 34), // Partners & Banks
                ),
                _buildQuickActionButton(
                  l.createNewCustomsTariff,
                  Icons.description_outlined,
                  AppTheme.orange,
                  () => selectNavigationIndex(ref, 36), // Customs Tariff
                ),
                _buildQuickActionButton(
                  l.createNewLocation,
                  Icons.location_on_outlined,
                  AppTheme.emerald,
                  () => selectNavigationIndex(ref, 37), // Ports & Locations
                ),
                _buildQuickActionButton(
                  l.createNewCurrency,
                  Icons.currency_exchange_outlined,
                  AppTheme.charcoal,
                  () => selectNavigationIndex(ref, 38), // Currencies
                ),
                _buildQuickActionButton(
                  l.createNewExchangeRate,
                  Icons.rate_review_outlined,
                  AppTheme.cobalt,
                  () => selectNavigationIndex(ref, 38), // Exchange Rates
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

  // ─── Operations Board Interactive Banner ────────────────────────
  Widget _buildStreamlitLauncherBanner() {
    final l = context.l10n;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l.interactiveOperationsBoardTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'NEW',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.interactiveOperationsBoardDesc,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
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
              label: Text(
                l.openInteractiveBoard,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Shipment Lifecycle Operations Board Summary (6 Phases / 21 Steps)
  // =========================================================================
  Widget _buildLifecycleOperationsBoardSummary(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LifecycleBoardSummaryModel> boardAsync,
    OperationalDashboardState dashboardState,
    OperationalDashboardNotifier notifier,
  ) {
    final l = context.l10n;

    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.view_kanban_outlined, color: AppTheme.cobalt, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.lifecycleBoardSummaryTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.charcoal),
                      ),
                      Text(
                        l.lifecycleBoardSummaryDesc,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (dashboardState.selectedPhase != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => notifier.togglePhase(dashboardState.selectedPhase!),
                      icon: const Icon(Icons.clear, size: 14, color: AppTheme.crimson),
                      label: Text('${l.clearFilter} (${dashboardState.selectedPhase})', style: const TextStyle(color: AppTheme.crimson, fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.crimson),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    selectNavigationIndex(ref, 48);
                  },
                  icon: const Icon(Icons.open_in_new, size: 15, color: Colors.white),
                  label: Text(l.fullOperationsBoardButton, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // 6 Phases & 21 Steps
            boardAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _buildDynamicLifecyclePhases(null, dashboardState, notifier),
              data: (boardData) => _buildDynamicLifecyclePhases(boardData, dashboardState, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicLifecyclePhases(
    LifecycleBoardSummaryModel? boardData,
    OperationalDashboardState dashboardState,
    OperationalDashboardNotifier notifier,
  ) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final l = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 3 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _lifecyclePhases.map((phaseMeta) {
            final int phaseId = phaseMeta['phase_id'];
            final String phaseName = isArabic ? phaseMeta['name_ar'] : phaseMeta['name_en'];
            final Color phaseColor = phaseMeta['color'];
            final List<Map<String, String>> steps = List<Map<String, String>>.from(phaseMeta['steps']);

            final matchingPhase = boardData?.phases.where((p) => p.phaseId == phaseId).firstOrNull;
            final int phaseActiveCount = matchingPhase?.totalActiveShipments ?? 0;
            final Map<String, int> stepCounts = matchingPhase?.stepCounts ?? {};

            final bool isPhaseSelected = dashboardState.selectedPhase == 'Phase $phaseId' || dashboardState.selectedPhase == 'P$phaseId';

            return Container(
              width: cardWidth.clamp(280.0, 480.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPhaseSelected ? phaseColor.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPhaseSelected ? phaseColor : Colors.grey.shade300,
                  width: isPhaseSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase Header
                  InkWell(
                    onTap: () => notifier.togglePhase('Phase $phaseId'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: phaseColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    phaseName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: isPhaseSelected ? phaseColor : AppTheme.charcoal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: phaseColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$phaseActiveCount ${l.shipmentCountUnit}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: phaseColor,
                              ),
                            ),
                          ),
                        ],

                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),

                  // Steps Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: steps.map((step) {
                      final String stepCode = step['code']!;
                      final String stepName = isArabic ? (step['name_ar'] ?? step['name'] ?? '') : (step['name_en'] ?? step['name'] ?? '');
                      final int count = stepCounts[stepCode] ?? 0;
                      final bool isStepSelected = dashboardState.selectedPhase == stepCode;

                      return InkWell(
                        onTap: () => notifier.togglePhase(stepCode),
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isStepSelected
                                ? phaseColor
                                : (count > 0 ? phaseColor.withOpacity(0.12) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isStepSelected
                                  ? phaseColor
                                  : (count > 0 ? phaseColor.withOpacity(0.4) : Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  stepName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isStepSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isStepSelected
                                        ? Colors.white
                                        : (count > 0 ? AppTheme.charcoal : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isStepSelected
                                      ? Colors.white.withOpacity(0.35)
                                      : (count > 0 ? phaseColor : Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

