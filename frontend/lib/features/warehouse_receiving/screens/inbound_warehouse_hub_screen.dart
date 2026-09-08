import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/goods_in_transit_provider.dart';
import '../providers/warehouse_receiving_provider.dart';
import 'goods_in_transit_screen.dart';
import 'warehouse_received_report_screen.dart';
import 'warehouse_receiving_screen.dart';

/// Phase 6 — Inbound Logistics & Warehouse Hub (مركز الاستلام والمخازن والبضاعة بالطريق)
///
/// Consolidation of:
///   - Tab 0: Goods In Transit (GIT) Inventory Ledger (رصيد ومطابقة البضاعة في الطريق)
///   - Tab 1: Warehouse Receiving GRN & Inspection (استلام المخازن وأذون الإضافة)
///   - Tab 2: Received Shipments & Audit Report (تقرير ومطابقة الشحنات المستلمة)
class InboundWarehouseHubScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const InboundWarehouseHubScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<InboundWarehouseHubScreen> createState() =>
      _InboundWarehouseHubScreenState();
}

class _InboundWarehouseHubScreenState
    extends ConsumerState<InboundWarehouseHubScreen> {
  late int _selectedSubTab;
  final Set<int> _visitedSubTabs = {};

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _visitedSubTabs.add(_selectedSubTab);
    Future.microtask(_refreshData);
  }

  @override
  void didUpdateWidget(covariant InboundWarehouseHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      setState(() {
        _selectedSubTab = widget.initialSubTab;
        _visitedSubTabs.add(_selectedSubTab);
      });
    }
  }

  void _refreshData() {
    if (!ref.read(warehouseReceivingProvider).isLoading) {
      ref.read(warehouseReceivingProvider.notifier).fetchRecords();
    }
    ref.read(goodsInTransitProvider.notifier).initLedger();
    if (!ref.read(importFilesProvider).isLoading) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.local_shipping_outlined,
        titleEn: 'Goods In Transit (GIT) Ledger',
        titleAr: 'رصيد ومطابقة البضاعة في الطريق',
      ),
      const VerticalNavTabItem(
        icon: Icons.inventory_outlined,
        titleEn: 'Warehouse Receiving & GRN',
        titleAr: 'استلام المخازن وأذون الإضافة',
      ),
      const VerticalNavTabItem(
        icon: Icons.inventory_2_outlined,
        titleEn: 'Received Shipments Audit Report',
        titleAr: 'تقرير ومطابقة الشحنات المستلمة',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'INBOUND-01',
      titleEn: 'Inbound Logistics & Warehouse Hub',
      titleAr: 'مركز الاستلام والمخازن والبضاعة بالطريق',
      headerIcon: Icons.warehouse_outlined,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (idx) => setState(() {
        _selectedSubTab = idx;
        _visitedSubTabs.add(idx);
      }),
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.refreshDataTooltip,
          onPressed: _refreshData,
        ),
      ],
      body: SelectionArea(child: _buildCurrentTab()),
    );
  }

  Widget _buildCurrentTab() {
    return IndexedStack(
      index: _selectedSubTab,
      children: [
        _visitedSubTabs.contains(0)
            ? const GoodsInTransitScreen(
                key: ValueKey('inbound_hub_git_screen'),
                isEmbedded: true,
              )
            : const SizedBox.shrink(),
        _visitedSubTabs.contains(1)
            ? const WarehouseReceivingScreen(
                key: ValueKey('inbound_hub_grn_screen'),
                isEmbedded: true,
              )
            : const SizedBox.shrink(),
        _visitedSubTabs.contains(2)
            ? const WarehouseReceivedReportScreen(
                key: ValueKey('inbound_hub_rep_screen'),
                isEmbedded: true,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
