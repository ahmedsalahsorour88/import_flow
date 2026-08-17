import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../models/lifecycle_board_model.dart';
import '../providers/lifecycle_board_provider.dart';
import '../widgets/step_action_dialog.dart';

class LifecycleBoardScreen extends ConsumerStatefulWidget {
  const LifecycleBoardScreen({super.key});

  @override
  ConsumerState<LifecycleBoardScreen> createState() => _LifecycleBoardScreenState();
}

class _LifecycleBoardScreenState extends ConsumerState<LifecycleBoardScreen> {
  String _searchQuery = '';
  String? _selectedStepCode;
  int? _selectedPhaseId;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _topPhasesScrollController = ScrollController();

  // Step definitions with English & Arabic names
  final Map<String, Map<String, String>> _stepMetadata = {
    'STEP_01': {'en': 'Freight Studies', 'ar': 'دراسات النولون', 'phase': '1'},
    'STEP_02': {'en': 'Customs Studies', 'ar': 'الدراسات الجمركية', 'phase': '1'},
    'STEP_03': {'en': 'Regulatory Reqs', 'ar': 'اشتراطات الاستيراد', 'phase': '1'},
    'STEP_04': {'en': 'Finance Approvals', 'ar': 'اعتماد الميزانية', 'phase': '2'},
    'STEP_05': {'en': 'ACID Operations', 'ar': 'إصدار ACID', 'phase': '2'},
    'STEP_06': {'en': 'Freight Booking', 'ar': 'تأكيد الحجز', 'phase': '3'},
    'STEP_07': {'en': 'Freight Allocations', 'ar': 'تخصيص الحاويات', 'phase': '3'},
    'STEP_08': {'en': 'Draft Docs Review', 'ar': 'مراجعة المسودات', 'phase': '3'},
    'STEP_09': {'en': 'Customs Approval', 'ar': 'الاعتماد النهائي', 'phase': '3'},
    'STEP_10': {'en': 'CargoX Upload', 'ar': 'رفع المستندات', 'phase': '4'},
    'STEP_11': {'en': 'Originals Collection', 'ar': 'أصول المستندات', 'phase': '4'},
    'STEP_12': {'en': 'Bank Form 4', 'ar': 'نموذج 4 البنكي', 'phase': '4'},
    'STEP_13': {'en': 'Declaration 46', 'ar': 'إقرار 46 ك.م', 'phase': '5'},
    'STEP_14': {'en': 'Clearance Follow-up', 'ar': 'الكشف والتثمين', 'phase': '5'},
    'STEP_15': {'en': 'Drawing Samples', 'ar': 'سحب العينات', 'phase': '5'},
    'STEP_16': {'en': 'Discrepancy / Damage', 'ar': 'محضر المعاينة', 'phase': '5'},
    'STEP_17': {'en': 'Final Calculation', 'ar': 'سداد الرسوم', 'phase': '5'},
    'STEP_18': {'en': 'Demurrage & Detention', 'ar': 'الأرضيات', 'phase': '5'},
    'STEP_19': {'en': 'Warehouse GRN', 'ar': 'إذن الإضافة', 'phase': '6'},
    'STEP_20': {'en': 'Landed Cost', 'ar': 'تسوية التكلفة', 'phase': '6'},
    'STEP_21': {'en': 'Final Closure', 'ar': 'إغلاق الملف', 'phase': '6'},
  };

  @override
  void initState() {
    super.initState();
    _selectedStepCode = 'STEP_01';
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _topPhasesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(lifecycleBoardSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.view_kanban_outlined, color: AppTheme.cobalt, size: 24),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipment Lifecycle Operations Board (6 Phases / 21 Steps)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'لوحة تتبع ومتابعة مراحل الشحنات التفاعلية المباشرة — اختيار المرحلة لعرض جدول الملفات',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث البيانات المباشرة',
            onPressed: () => ref.invalidate(lifecycleBoardSummaryProvider),
          ),
          const SizedBox(width: 8),
          const BackToDashboardButton(),
          const SizedBox(width: 12),
        ],
      ),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.crimson, size: 40),
              const SizedBox(height: 12),
              Text('حدث خطأ أثناء تحميل بيانات اللوحة: $err', style: const TextStyle(color: AppTheme.crimson)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(lifecycleBoardSummaryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (boardData) {
          final allShipments = boardData.allShipments;

          // Filter shipments for the lower 2/3 table
          final filteredShipments = allShipments.where((s) {
            final matchesStep = _selectedStepCode == null || s.stepCode == _selectedStepCode;
            final matchesPhase = _selectedPhaseId == null || _isStepInPhase(s.stepCode, _selectedPhaseId!, boardData.phases);

            final matchesSearch = _searchQuery.isEmpty ||
                s.importFileCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (s.poNumber != null && s.poNumber!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                (s.notes != null && s.notes!.toLowerCase().contains(_searchQuery.toLowerCase()));

            if (_selectedStepCode != null) {
              return matchesStep && matchesSearch;
            } else if (_selectedPhaseId != null) {
              return matchesPhase && matchesSearch;
            }
            return matchesSearch;
          }).toList();

          return Column(
            children: [
              // ─── UPPER 1/3: Compact 6 Phase Overview Cards ────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.layers_outlined, color: AppTheme.cobalt, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'المستويات الـ 6 الكبرى — اضغط على أي مرحلة لعرض وتحديث شحناتها بالجدول أدناه:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                              ),
                              child: Text(
                                'إجمالي الشحنات: ${boardData.totalActiveFiles} ملف (${boardData.allShipments.length} مرحلة)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.cobalt),
                              ),
                            ),
                            if (_selectedStepCode != null || _selectedPhaseId != null) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), visualDensity: VisualDensity.compact),
                                onPressed: () {
                                  setState(() {
                                    _selectedStepCode = null;
                                    _selectedPhaseId = null;
                                  });
                                },
                                icon: const Icon(Icons.clear_all, size: 14, color: AppTheme.crimson),
                                label: const Text('عرض كافة المراحل', style: TextStyle(color: AppTheme.crimson, fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // The 6 Phase Cards Row (Upper 1/3)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final cardWidth = availableWidth > 1150
                            ? (availableWidth - 50) / 6.0
                            : 185.0;

                        return Scrollbar(
                          controller: _topPhasesScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _topPhasesScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: boardData.phases.map((phase) {
                                return _buildPhaseTopCard(phase, cardWidth);
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.black12),

              // ─── LOWER 2/3: Interactive Shipment Data Table with Horizontal Scrollbar ─
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Top Filter Bar & Current Step Title
                        _buildTableTopBar(filteredShipments.length, boardData.phases),

                        // Scrollable Table Area with Horizontal Navigation Bar
                        Expanded(
                          child: filteredShipments.isEmpty
                              ? _buildEmptyState()
                              : _buildShipmentsTable(filteredShipments, boardData.phases),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Phase Top Card (Compact Upper 1/3) ────────────────────────────────────

  Widget _buildPhaseTopCard(PhaseSummaryModel phase, double width) {
    final headerColor = _parseColor(phase.colorHex);
    final isPhaseSelected = _selectedPhaseId == phase.phaseId && _selectedStepCode == null;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPhaseSelected ? headerColor : headerColor.withOpacity(0.35),
          width: isPhaseSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Phase Name & Total Count
          InkWell(
            onTap: () {
              setState(() {
                _selectedPhaseId = phase.phaseId;
                _selectedStepCode = null;
              });
            },
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.titleEn,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          phase.titleAr,
                          style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${phase.totalActiveShipments}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Steps list inside Phase
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
            child: Column(
              children: phase.stepCodes.map((stepCode) {
                final count = phase.stepCounts[stepCode] ?? 0;
                final isStepSelected = _selectedStepCode == stepCode;
                final meta = _stepMetadata[stepCode] ?? {'en': stepCode, 'ar': stepCode};

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStepCode = stepCode;
                      _selectedPhaseId = phase.phaseId;
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: isStepSelected
                          ? headerColor.withOpacity(0.18)
                          : count > 0
                              ? Colors.grey.shade50
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isStepSelected
                            ? headerColor
                            : count > 0
                                ? Colors.grey.shade300
                                : Colors.transparent,
                        width: isStepSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isStepSelected ? Icons.check_circle : (count > 0 ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                          size: 11,
                          color: isStepSelected
                              ? headerColor
                              : (count > 0 ? headerColor : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta['en']!,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isStepSelected || count > 0 ? FontWeight.bold : FontWeight.w500,
                                  color: isStepSelected ? headerColor : AppTheme.charcoal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                meta['ar']!,
                                style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: count > 0 ? headerColor.withOpacity(0.2) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: count > 0 ? headerColor : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Table Top Filter Bar ──────────────────────────────────────────────────

  Widget _buildTableTopBar(int filteredCount, List<PhaseSummaryModel> phases) {
    String selectedTitle = 'كافة الشحنات في جميع المراحل';
    Color badgeColor = AppTheme.cobalt;

    if (_selectedStepCode != null) {
      final meta = _stepMetadata[_selectedStepCode!];
      if (meta != null) {
        selectedTitle = '${_selectedStepCode!}: ${meta['en']} — ${meta['ar']}';
      }
      final phaseId = int.tryParse(meta?['phase'] ?? '1') ?? 1;
      final p = phases.firstWhere((ph) => ph.phaseId == phaseId, orElse: () => phases[0]);
      badgeColor = _parseColor(p.colorHex);
    } else if (_selectedPhaseId != null) {
      final p = phases.firstWhere((ph) => ph.phaseId == _selectedPhaseId, orElse: () => phases[0]);
      selectedTitle = '${p.titleEn} — ${p.titleAr}';
      badgeColor = _parseColor(p.colorHex);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list_alt, size: 15, color: badgeColor),
                const SizedBox(width: 5),
                Text(
                  selectedTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: badgeColor),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '$filteredCount شحنة',
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Search Field inside table
          SizedBox(
            width: 280,
            height: 32,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث بكود الشحنة، المورد، PO، أو الملاحظات...',
                hintStyle: const TextStyle(fontSize: 10.5),
                prefixIcon: const Icon(Icons.search, size: 15),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shipments Data Table with Horizontal Scrollbar ────────────────────────

  Widget _buildShipmentsTable(List<ShipmentStageCardModel> shipments, List<PhaseSummaryModel> phases) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 58,
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('كود الشحنة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('الخطوة الحالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('الشركة المستوردة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('أمر الشراء PO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('نوع الشحن والشرط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('القيمة التقديرية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('الملاحظات والأنشطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    DataColumn(label: Text('الإجراءات والترحيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  ],
                  rows: shipments.map((s) {
                    final phaseId = int.tryParse(_stepMetadata[s.stepCode]?['phase'] ?? '1') ?? 1;
                    final p = phases.firstWhere((ph) => ph.phaseId == phaseId, orElse: () => phases[0]);
                    final stepColor = _parseColor(p.colorHex);

                    return DataRow(
                      cells: [
                        // 1. File Code
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                            ),
                            child: Text(
                              s.importFileCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.cobalt),
                            ),
                          ),
                        ),

                        // 2. Step Name
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: stepColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: stepColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.stepNameEn, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: stepColor)),
                                Text(s.stepNameAr, style: TextStyle(fontSize: 9, color: stepColor.withOpacity(0.85))),
                              ],
                            ),
                          ),
                        ),

                        // 3. Company
                        DataCell(
                          Text(s.companyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                        ),

                        // 4. Supplier
                        DataCell(
                          Text(s.supplierName, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800)),
                        ),

                        // 5. PO Number
                        DataCell(
                          Text(s.poNumber ?? 'غير محدد', style: const TextStyle(fontSize: 10.5)),
                        ),

                        // 6. Mode & Incoterm
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${s.shipmentMode} | ${s.incotermCode}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            ),
                          ),
                        ),

                        // 7. Value
                        DataCell(
                          Text(
                            '${s.estimatedCost.toStringAsFixed(0)} ${s.estimatedCostCurrency}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11),
                          ),
                        ),

                        // 8. Notes
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              s.notes ?? 'قيد المتابعة التشغيلية',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // 9. Workstation Action Button
                        DataCell(
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: stepColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => StepActionDialog(
                                  shipment: s,
                                  allPhases: phases,
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_circle_outline, size: 13, color: Colors.white),
                            label: const Text(
                              'تنفيذ وترحيل الخطوة',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'لا توجد شحنات مسجلة حالياً في هذه المرحلة المحددة',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 3),
            Text(
              'يمكنك اختيار مرحلة أخرى من الأقسام بالأعلى أو إلغاء التصفية لعرض كافة الشحنات.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  bool _isStepInPhase(String stepCode, int phaseId, List<PhaseSummaryModel> phases) {
    try {
      final p = phases.firstWhere((ph) => ph.phaseId == phaseId);
      return p.stepCodes.contains(stepCode);
    } catch (_) {
      return false;
    }
  }

  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
