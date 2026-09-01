import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _topPhasesScrollController = ScrollController();

  final Map<String, String> _stepPhases = {
    'STEP_01': '1', 'STEP_02': '1', 'STEP_03': '1',
    'STEP_04': '2', 'STEP_05': '2',
    'STEP_06': '3', 'STEP_07': '3', 'STEP_08': '3', 'STEP_09': '3',
    'STEP_10': '4', 'STEP_11': '4', 'STEP_12': '4',
    'STEP_13': '5', 'STEP_14': '5', 'STEP_15': '5', 'STEP_16': '5', 'STEP_17': '5', 'STEP_18': '5',
    'STEP_19': '6', 'STEP_20': '6', 'STEP_21': '6',
  };

  @override
  void initState() {
    super.initState();
    _selectedStepCode = 'STEP_01';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(lifecycleBoardSummaryProvider);
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _topPhasesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final boardAsync = ref.watch(lifecycleBoardSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        elevation: 2,
        title: Row(
          children: [
            const Icon(Icons.view_kanban_outlined, color: AppTheme.cobalt, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lifecycleBoardTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.lifecycleBoardSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: l10n.refreshLiveBoardTooltip,
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
              Text(l10n.lifecycleBoardError(err.toString()), style: const TextStyle(color: AppTheme.crimson), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(lifecycleBoardSummaryProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
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
                        Row(
                          children: [
                            const Icon(Icons.layers_outlined, color: AppTheme.cobalt, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.majorPhasesHeader,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
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
                                l10n.totalActiveShipmentsCount(boardData.totalActiveFiles, boardData.allShipments.length),
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
                                label: Text(l10n.showAllPhasesBtn, style: const TextStyle(color: AppTheme.crimson, fontSize: 11)),
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
    final l10n = context.l10n;
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
                    child: Text(
                      l10n.lifecyclePhaseName(phase.phaseId, phase.titleAr, phase.titleEn),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                final localizedName = l10n.lifecycleStepName(stepCode);

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
                          child: Text(
                            localizedName,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isStepSelected || count > 0 ? FontWeight.bold : FontWeight.w500,
                              color: isStepSelected ? headerColor : AppTheme.charcoal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    final l10n = context.l10n;
    String selectedTitle = l10n.allShipmentsAllPhases;
    Color badgeColor = AppTheme.cobalt;

    if (_selectedStepCode != null) {
      selectedTitle = '${_selectedStepCode!}: ${l10n.lifecycleStepName(_selectedStepCode!)}';
      final phaseStr = _stepPhases[_selectedStepCode!];
      final phaseId = int.tryParse(phaseStr ?? '1') ?? 1;
      final p = phases.firstWhere((ph) => ph.phaseId == phaseId, orElse: () => phases[0]);
      badgeColor = _parseColor(p.colorHex);
    } else if (_selectedPhaseId != null) {
      final p = phases.firstWhere((ph) => ph.phaseId == _selectedPhaseId, orElse: () => phases[0]);
      selectedTitle = l10n.lifecyclePhaseName(p.phaseId, p.titleAr, p.titleEn);
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
                    l10n.shipmentsCountFormatted(filteredCount),
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
                hintText: l10n.searchLifecycleTableHint,
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
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            notificationPredicate: (notif) => notif.depth == 1,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 58,
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    columns: [
                      DataColumn(label: Text(l10n.colShipmentCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colPreviousStep, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colCurrentStep, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colNextStep, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colImportCompany, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colForeignSupplier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colPurchaseOrder, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colModeAndIncoterm, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colEstimatedValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colNotesAndActivities, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                      DataColumn(label: Text(l10n.colActionsAndAdvance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                    ],
                    rows: shipments.map((s) {
                      final phaseStr = _stepPhases[s.stepCode];
                      final phaseId = int.tryParse(phaseStr ?? '1') ?? 1;
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

                          // 2. Previous Step (المسار السابق)
                          DataCell(
                            s.previousStepCode != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, size: 12, color: AppTheme.emerald),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.lifecycleStepName(s.previousStepCode!),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text('—', style: TextStyle(color: Colors.grey.shade400)),
                          ),

                          // 3. Current Step (المسار الحالي)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: stepColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: stepColor, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, size: 13, color: stepColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    l10n.lifecycleStepName(s.stepCode),
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: stepColor),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 4. Next Step (المسار التالي)
                          DataCell(
                            s.nextStepCode != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.amber.shade700.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_circle_left_outlined, size: 12, color: Colors.amber.shade900),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.lifecycleStepName(s.nextStepCode!),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text('—', style: TextStyle(color: Colors.grey.shade400)),
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
                            Text(s.poNumber ?? l10n.notSpecifiedOption, style: const TextStyle(fontSize: 10.5)),
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
                                s.notes ?? l10n.notesUnderFollowupFallback,
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
                              label: Text(
                                l10n.executeAndAdvanceStepBtn,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              l10n.noShipmentsInStage,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 3),
            Text(
              l10n.noShipmentsInStageDesc,
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
