import '../widgets/po_form_dialog.dart';
import '../widgets/po_reconciliation_warning_dialog.dart';
import '../widgets/po_balance_ledger_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';

import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';

import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_files/models/import_file_model.dart' show ImportFileModel;
import '../../import_files/providers/import_files_provider.dart';
import '../../../core/performance/dispose_tracker.dart';
import '../../projects/providers/projects_provider.dart';
import '../models/purchase_order_model.dart';
import '../providers/purchase_orders_provider.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> with DisposeTrackerMixin<PurchaseOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final poState = ref.read(purchaseOrdersProvider);
      if (!poState.isLoading) {
        ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      }
      final prjState = ref.read(projectsProvider);
      if (!prjState.isLoading) {
        ref.read(projectsProvider.notifier).fetchProjects();
      }
      final filesState = ref.read(importFilesProvider);
      if (!filesState.isLoading) {
        ref.read(importFilesProvider.notifier).fetchImportFiles();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(purchaseOrdersProvider);
    final projectsList = ref.watch(projectsProvider).valueOrNull ?? [];

    final totalOrders = state.purchaseOrders.length;
    final totalFobSum = state.purchaseOrders.fold<double>(0.0, (sum, p) => sum + p.totalAmountFob);
    final totalCbmSum = state.purchaseOrders.fold<double>(0.0, (sum, p) => sum + p.totalCbm);
    final totalGrossSum = state.purchaseOrders.fold<double>(0.0, (sum, p) => sum + p.totalGrossWeightKg);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF141A22), const Color(0xFF1E293B)]
                    : [AppTheme.charcoal, AppTheme.cobalt],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.purchaseOrdersTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l.purchaseOrdersSubtitle,
                        style: const TextStyle(color: AppTheme.cloudWhite, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const BackToDashboardButton(),
                const SizedBox(width: 10),
                SmartUploadButton(
                  module: SmartUploadModule.purchaseOrder,
                  label: '🚀 ${l.smartInvoiceExtract}',
                  onDataExtracted: (result) {
                    final fields = result.extractedFields;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${fields['po_number'] ?? '-'}',
                        ),
                        backgroundColor: AppTheme.emerald,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    _showPODialog(context, null, initialExtractedFields: fields);
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(l.newPurchaseOrder, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showPODialog(context, null),
                ),
              ],
            ),
          ),

          // Summary Metrics Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSummaryMetric(l.totalOrdersMetric, '$totalOrders', Icons.receipt_long, Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryMetric(l.totalFobMetric, '\$${totalFobSum.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                const SizedBox(width: 12),
                _buildSummaryMetric(l.totalCargoCbmMetric, '${totalCbmSum.toStringAsFixed(2)} m³', Icons.view_in_ar, Colors.orange),
                const SizedBox(width: 12),
                _buildSummaryMetric(l.totalGrossWeightMetric, '${totalGrossSum.toStringAsFixed(1)} kg', Icons.scale, Colors.purple),
              ],
            ),
          ),

          // Data Actions Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MasterDataToolbarWidget(
              moduleEndpoint: 'purchase-orders',
              title: 'Purchase_Orders',
              onRefreshNeeded: () => ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders(),
            ),
          ),

          const SizedBox(height: 8),

          // Filter & Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l.searchByPoHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(purchaseOrdersProvider.notifier).setSearchQuery('');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => ref.read(purchaseOrdersProvider.notifier).setSearchQuery(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<int?>(
                        value: state.projectFilter,
                        labelText: l.filterByProject,
                        items: [
                          SearchableDropdownItem<int?>(value: null, label: l.allProjects),
                          ...projectsList.map((p) => SearchableDropdownItem<int?>(
                                value: p.projectId,
                                label: '${p.projectCode} - ${p.projectName}',
                              )),
                        ],
                        onChanged: (v) => ref.read(purchaseOrdersProvider.notifier).setProjectFilter(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<String?>(
                        value: state.statusFilter,
                        labelText: l.filterByStatus,
                        items: [
                          SearchableDropdownItem<String?>(value: null, label: l.allStatuses),
                          SearchableDropdownItem<String?>(value: 'Draft', label: l.statusDraft),
                          SearchableDropdownItem<String?>(value: 'Approved', label: l.statusPoApproved),
                          SearchableDropdownItem<String?>(value: 'In Transit', label: l.statusInTransit),
                          SearchableDropdownItem<String?>(value: 'Closed', label: l.statusClosed),
                        ],
                        onChanged: (v) => ref.read(purchaseOrdersProvider.notifier).setStatusFilter(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: state.showInactive,
                          onChanged: (v) => ref.read(purchaseOrdersProvider.notifier).toggleShowInactive(v ?? false),
                        ),
                        Text(l.showInactive, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                      tooltip: l.liveReload,
                      onPressed: () => ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Data Table / Loading
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.crimson),
                            const SizedBox(height: 12),
                            Text(state.errorMessage!, style: const TextStyle(color: AppTheme.crimson)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders(),
                              child: Text(l.retry),
                            ),
                          ],
                        ),
                      )
                    : state.purchaseOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(l.noDataFound, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          )
                        : _buildPOTable(context, state.purchaseOrders),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Card(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.transparent),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  CopyableText(
                    value,
                    showIcon: false,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations l) {
    switch (status.trim().toLowerCase()) {
      case 'draft':
        return l.statusDraft;
      case 'approved':
        return l.statusPoApproved;
      case 'in transit':
        return l.statusInTransit;
      case 'closed':
        return l.statusClosed;
      default:
        return status;
    }
  }

  Widget _buildPOTable(BuildContext context, List<PurchaseOrderModel> orders) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];

    final Map<int, ImportFileModel> filesById = {};
    final Map<String, ImportFileModel> filesByCode = {};
    for (final f in importFiles) {
      filesById[f.importFileId] = f;
      filesByCode[f.importFileCode] = f;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.darkSurface : AppTheme.charcoal),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              dataRowMaxHeight: 52,
              columns: [
                DataColumn(label: Text(l.poReferenceCol)),
                DataColumn(label: Text(l.invoiceDateCol)),
                DataColumn(label: Text(l.importFileCol)),
                DataColumn(label: Text(l.piNumberCol)),
                DataColumn(label: Text(l.projectsAndCostCenters)),
                DataColumn(label: Text(l.importingCompany)),
                DataColumn(label: Text(l.foreignSupplier)),
                DataColumn(label: Text(l.totalFobMetric)),
                DataColumn(label: Text(l.cbmAndGrossWeightCol)),
                DataColumn(label: Text(l.lifecycleBoard)),
                DataColumn(label: Text(l.actionsCol)),
              ],

              rows: orders.map((po) {
                final statusColor = po.status == 'Approved'
                    ? AppTheme.emerald
                    : po.status == 'In Transit'
                        ? AppTheme.cobalt
                        : po.status == 'Closed'
                            ? Colors.grey
                            : AppTheme.orange;

                final invoiceDateStr = po.orderDate != null
                    ? '${po.orderDate!.year}-${po.orderDate!.month.toString().padLeft(2, '0')}-${po.orderDate!.day.toString().padLeft(2, '0')}'
                    : '-';

                final matchedFile = (po.importFileId != null ? filesById[po.importFileId] : null) ??
                    (po.importFileCode != null ? filesByCode[po.importFileCode] : null);
                final fileName = matchedFile?.displayName ?? po.importFileCode ?? (po.importFileId != null ? 'IMP-${po.importFileId}' : '-');
                final fileCode = (matchedFile != null && matchedFile.displayName != matchedFile.importFileCode)
                    ? matchedFile.importFileCode
                    : (po.importFileCode ?? (po.importFileId != null ? 'IMP-${po.importFileId}' : ''));
                final amountStr = '${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}';
                final cbmWeightStr = '${po.totalCbm.toStringAsFixed(2)} m³ / ${po.totalGrossWeightKg.toStringAsFixed(0)} kg';
                final localizedStatus = _getStatusLabel(po.status, l);

                final rowSummary = [
                  po.displayName,
                  invoiceDateStr,
                  fileName,
                  po.proformaInvoiceNumber ?? '-',
                  po.projectName ?? 'PRJ-#${po.projectId}',
                  po.companyName ?? 'COMP-#${po.companyId}',
                  po.supplierName ?? 'SUP-#${po.supplierId}',
                  amountStr,
                  cbmWeightStr,
                  localizedStatus,
                ].join('\t');

                return DataRow(
                  onSelectChanged: (_) => _showPODetailsDialog(context, po),
                  cells: [
                    DataCell(
                      CopyableTableCell(
                        value: po.displayName,
                        rowSummary: rowSummary,
                        child: InkWell(
                          onTap: () => _showPODetailsDialog(context, po),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    po.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.cobalt,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.open_in_new, size: 14, color: AppTheme.cobalt),
                                ],
                              ),
                              if (po.poReference != null && po.poReference!.isNotEmpty && po.poReference != po.poNumber)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    po.poNumber,
                                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: invoiceDateStr,
                        rowSummary: rowSummary,
                        child: Text(invoiceDateStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: fileName,
                        rowSummary: rowSummary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                              ),
                              child: Text(
                                fileName,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                              ),
                            ),
                            if (fileCode.isNotEmpty && fileCode != fileName)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
                                child: Text(
                                  fileCode,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: po.proformaInvoiceNumber ?? '-',
                        rowSummary: rowSummary,
                        child: Text(po.proformaInvoiceNumber ?? '-'),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: po.projectName ?? 'PRJ-#${po.projectId}',
                        rowSummary: rowSummary,
                        child: Text(po.projectName ?? 'PRJ-#${po.projectId}'),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: po.companyName ?? 'COMP-#${po.companyId}',
                        rowSummary: rowSummary,
                        child: Text(po.companyName ?? 'COMP-#${po.companyId}'),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: po.supplierName ?? 'SUP-#${po.supplierId}',
                        rowSummary: rowSummary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(po.supplierName ?? 'SUP-#${po.supplierId}'),
                            if (po.countryOfOrigin != null && po.countryOfOrigin!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  po.countryOfOrigin!,
                                  style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: amountStr,
                        rowSummary: rowSummary,
                        child: Text(
                          amountStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: cbmWeightStr,
                        rowSummary: rowSummary,
                        child: Text(cbmWeightStr),
                      ),
                    ),
                    DataCell(
                      CopyableTableCell(
                        value: localizedStatus,
                        rowSummary: rowSummary,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            localizedStatus,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (po.poId != null)
                            IconButton(
                              icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.cobalt, size: 20),
                              tooltip: l.poBalanceLedgerTooltip,
                              onPressed: () => showPOBalanceLedgerDialog(
                                context,
                                ref,
                                poId: po.poId!,
                                poCode: po.poNumber,
                              ),
                            ),
                          RowActionsPill(
                            onView: () => _showPODetailsDialog(context, po),
                            onEdit: () => _showPODialog(context, po),
                            onPrint: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.printPoAndPackingList(po.displayName, po.poNumber)),
                                  backgroundColor: AppTheme.charcoal,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            onDelete: () async {
                              final isActive = po.isActive;
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l.confirmActionTitle),
                                  content: Text(isActive
                                      ? l.confirmDeactivatePo(po.displayName)
                                      : l.confirmRestorePo(po.displayName)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald),
                                      child: Text(isActive ? l.deactivateBtn : l.restore, style: const TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                if (po.isActive) {
                                  await ref.read(purchaseOrdersProvider.notifier).deletePurchaseOrder(po.poId!);
                                } else {
                                  await ref.read(purchaseOrdersProvider.notifier).restorePurchaseOrder(po.poId!);
                                }
                              }
                            },
                            deleteTooltip: po.isActive ? l.deactivatePoTooltip : l.restorePoTooltip,
                          ),
                        ],
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
  }

  void _showPODetailsDialog(BuildContext context, PurchaseOrderModel po) {
    final tariffs = ref.read(customsTariffProvider).valueOrNull ?? [];
    if (tariffs.isEmpty) {
      ref.read(customsTariffProvider.notifier).fetchTariffs();
    }
    final reconciliation = evaluatePOReconciliation(
      invoiceItems: po.items,
      packingItems: po.packingListItems,
      tariffs: tariffs,
    );
    final Set<String> mismatchedHsCodes = reconciliation.items
        .where((item) => !item.isMatched || item.isMissingInPacking || item.isMissingInInvoice)
        .map((item) => item.hsCode)
        .toSet();

    // Group packing list items by HS Code for the HS Summary Report
    final Map<String, Map<String, dynamic>> hsSummaryMap = {};
    for (final p in po.packingListItems) {
      final hs = p.hsCode.isNotEmpty ? p.hsCode : 'UNSPECIFIED';
      if (!hsSummaryMap.containsKey(hs)) {
        hsSummaryMap[hs] = {
          'hs_code': hs,
          'qty_pcs': 0.0,
          'qty_pkg': 0.0,
          'total_net': 0.0,
          'total_gross': 0.0,
          'total_cbm': 0.0,
        };
      }
      final double itemNet = (p.netWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.netWeightUnitKg) : p.totalNetWeightKg;
      final double itemGross = (p.grossWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.grossWeightUnitKg) : p.totalGrossWeightKg;
      final double itemCbm = p.calculatedCbm > 0 ? p.calculatedCbm : p.totalCbm;
      hsSummaryMap[hs]!['qty_pcs'] += p.qtyPcs;
      hsSummaryMap[hs]!['qty_pkg'] += p.qtyPkg;
      hsSummaryMap[hs]!['total_net'] += itemNet;
      hsSummaryMap[hs]!['total_gross'] += itemGross;
      hsSummaryMap[hs]!['total_cbm'] += itemCbm;
    }

    // Validation checks
    final List<String> validationErrors = [];
    final List<String> validationWarnings = [];
    for (int i = 0; i < po.packingListItems.length; i++) {
      final item = po.packingListItems[i];
      if (item.grossWeightUnitKg < item.netWeightUnitKg) {
        validationErrors.add('Item #${i + 1} (${item.itemCode}): Gross weight (${item.grossWeightUnitKg} kg) < Net weight (${item.netWeightUnitKg} kg)');
      }
      if (item.lengthCm <= 0 || item.widthCm <= 0 || item.heightCm <= 0) {
        validationWarnings.add('Item #${i + 1} (${item.itemCode}): Missing package dimensions; CBM calculated from unit specs.');
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final l = dialogCtx.l10n;
        final isArabic = Localizations.localeOf(dialogCtx).languageCode == 'ar';
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return SelectionArea(
          child: DefaultTabController(
            length: 2,
            child: AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : null,
            title: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppTheme.cobalt),
                const SizedBox(width: 8),
                Text(
                  '${l.purchaseOrdersTitle}: ${po.displayName} (${po.poNumber})',
                  style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 850,
              height: 550,
              child: Column(
                children: [
                  Container(
                    color: isDark ? AppTheme.darkCardBackground : Colors.grey.shade100,
                    child: TabBar(
                      labelColor: AppTheme.cobalt,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.cobalt,
                      tabs: [
                        Tab(icon: const Icon(Icons.receipt_long, size: 18), text: l.poLineItemsTab),
                        Tab(icon: const Icon(Icons.fact_check, size: 18), text: l.reviewPackingListTab),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Commercial PO Line Items
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Builder(builder: (context) {
                              final double palletPlanCbm = po.palletPlanItems.isNotEmpty
                                  ? po.palletPlanItems.fold<double>(
                                      0.0,
                                      (sum, p) => sum + (p.calculatedCbm > 0 ? p.calculatedCbm : (p.lengthCm * p.widthCm * p.heightCm / 1000000.0) * p.palletCount),
                                    )
                                  : (po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0
                                      ? (po.palletLengthCm * po.palletWidthCm * po.palletHeightCm / 1000000.0) * po.palletCount
                                      : (po.palletCount > 0 && po.totalCbm > 0 ? po.totalCbm : 0.0));
                              final double palletPlanGrossWeight = po.palletPlanItems.isNotEmpty
                                  ? po.palletPlanItems.fold<double>(
                                      0.0,
                                      (sum, p) => sum + (p.grossWeightPerPalletKg * p.palletCount),
                                    )
                                  : (po.palletCount > 0 && po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);
                              final int totalPalletCount = po.palletPlanItems.isNotEmpty
                                  ? po.palletPlanItems.fold<int>(0, (sum, p) => sum + p.palletCount)
                                  : po.palletCount;

                              final double effectivePackingListCbm = palletPlanCbm > 0
                                  ? palletPlanCbm
                                  : (po.totalCbm > 0
                                      ? po.totalCbm
                                      : (po.packingListItems.isNotEmpty
                                          ? po.packingListItems.fold(0.0, (sum, pl) => sum + (pl.calculatedCbm > 0 ? pl.calculatedCbm : pl.totalCbm))
                                          : 0.0));
                              final double effectivePackingListGrossWeight = palletPlanGrossWeight > 0
                                  ? palletPlanGrossWeight
                                  : (po.totalGrossWeightKg > 0
                                      ? po.totalGrossWeightKg
                                      : (po.packingListItems.isNotEmpty
                                          ? po.packingListItems.fold(0.0, (sum, pl) => sum + ((pl.grossWeightUnitKg > 0 && pl.qtyPkg > 0) ? (pl.grossWeightUnitKg * pl.qtyPkg) : pl.totalGrossWeightKg))
                                          : 0.0));
                              final double effectivePackingListNetWeight = po.totalNetWeightKg > 0
                                  ? po.totalNetWeightKg
                                  : (po.packingListItems.isNotEmpty
                                      ? po.packingListItems.fold(0.0, (sum, pl) => sum + ((pl.netWeightUnitKg > 0 && pl.qtyPkg > 0) ? (pl.netWeightUnitKg * pl.qtyPkg) : pl.totalNetWeightKg))
                                      : 0.0);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 10,
                                    children: [
                                      _buildDetailItem(l.projectsAndCostCenters, po.projectName ?? '-', isDark: isDark),
                                      _buildDetailItem(l.importingCompany, po.companyName ?? '-', isDark: isDark),
                                      _buildDetailItem(l.foreignSupplier, po.supplierName ?? '-', isDark: isDark),
                                      _buildDetailItem(l.countryOfOriginCol, po.countryOfOrigin ?? '-', isDark: isDark),
                                      _buildDetailItem(l.incotermsRules, po.incotermCode ?? '-', isDark: isDark),
                                      _buildDetailItem(l.currency, '${po.currencyCode ?? "USD"} (${l.exchangeRateLabel}: ${po.exchangeRate})', isDark: isDark),
                                      _buildDetailItem(l.paymentTermsLabel, po.paymentTerms ?? '-', isDark: isDark),
                                      _buildDetailItem(l.totalFobMetric, '${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}', isDark: isDark),
                                      _buildDetailItem(
                                        l.totalCargoCbmMetric,
                                        '${effectivePackingListCbm.toStringAsFixed(3)} m³${totalPalletCount > 0 ? " ($totalPalletCount)" : ""}',
                                        isDark: isDark,
                                      ),
                                      _buildDetailItem(
                                        l.grossWeightMetric,
                                        '${effectivePackingListGrossWeight.toStringAsFixed(1)} kg',
                                        isDark: isDark,
                                      ),
                                      _buildDetailItem(
                                        l.netWeightMetric,
                                        '${effectivePackingListNetWeight.toStringAsFixed(1)} kg',
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 16),
                                Text(l.poLineItemsBreakdown, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal)),
                                const SizedBox(height: 6),
                                Table(
                                  border: TableBorder.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.0),
                                    1: FlexColumnWidth(1.8),
                                    2: FlexColumnWidth(2.6),
                                    3: FlexColumnWidth(1.1),
                                    4: FlexColumnWidth(1.1),
                                    5: FlexColumnWidth(1.1),
                                    6: FlexColumnWidth(1.3),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.cloudWhite),
                                      children: [
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.itemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.mainDescription, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.descriptionAndHsCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.qtyUom, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.unitPrice, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.lineTotal, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text(l.volumeCbmPackingList, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                    ...po.items.map(
                                      (item) {
                                        double itemCbm = item.totalCbm;
                                        if (po.packingListItems.isNotEmpty) {
                                          final matchingPl = po.packingListItems.firstWhere(
                                            (pl) => (item.itemCode != null && pl.itemCode == item.itemCode) || (item.hsCode != null && pl.hsCode == item.hsCode),
                                            orElse: () => PackingListItemModel(hsCode: '', itemCode: ''),
                                          );
                                          if (matchingPl.itemCode.isNotEmpty) {
                                            itemCbm = matchingPl.totalCbm > 0 ? matchingPl.totalCbm : matchingPl.calculatedCbm;
                                          } else if (po.totalAmountFob > 0) {
                                            itemCbm = (item.totalPrice / po.totalAmountFob) * effectivePackingListCbm;
                                          }
                                        }

                                        final itemHs = item.hsCode ?? (item.tariffId != null && tariffs.any((t) => t.tariffId == item.tariffId) ? tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsCode : null);
                                        final isMismatched = itemHs != null && itemHs.isNotEmpty && mismatchedHsCodes.contains(itemHs);

                                        return TableRow(
                                          decoration: isMismatched ? BoxDecoration(color: Colors.red.shade50.withOpacity(0.3)) : null,
                                          children: [
                                            Padding(padding: const EdgeInsets.all(6), child: Text(item.itemCode ?? '-')),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                item.mainDescription?.isNotEmpty == true ? item.mainDescription! : '-',
                                                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.descriptionAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  if (item.countryOfOrigin != null && item.countryOfOrigin!.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text(l.itemOriginLabel(item.countryOfOrigin!), style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                                    ),
                                                  if (itemHs != null && itemHs.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: isMismatched
                                                          ? Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red.shade50,
                                                                borderRadius: BorderRadius.circular(4),
                                                                border: Border.all(color: Colors.red.shade400, width: 1.2),
                                                              ),
                                                              child: Wrap(
                                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                                spacing: 4,
                                                                children: [
                                                                  const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                                                                  Text(
                                                                    l.hsMismatchWarning('${item.dutyRate ?? 0}%', '${item.vatRate ?? 0}%'),
                                                                    style: TextStyle(color: Colors.red.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : Text(
                                                              'HS: $itemHs (${l.fieldImportDuty}: ${item.dutyRate ?? 0}% / ${l.fieldVatAmount}: ${item.vatRate ?? 0}%)',
                                                              style: const TextStyle(color: AppTheme.cobalt, fontSize: 11),
                                                            ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Padding(padding: const EdgeInsets.all(6), child: Text('${item.quantity} ${item.unitOfMeasure}')),
                                            Padding(padding: const EdgeInsets.all(6), child: Text('${po.currencyCode ?? "USD"} ${item.unitPrice.toStringAsFixed(2)}')),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                '${po.currencyCode ?? "USD"} ${item.totalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                '${itemCbm.toStringAsFixed(3)} m³',
                                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                        ),

                      // Tab 2: BP-003 Review Packing List
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reconciliation & Discrepancy Status Banner
                            if (po.packingListItems.isNotEmpty) ...[
                              if (reconciliation.hasDiscrepancy)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF382C10) : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade400),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            isArabic
                                                ? 'حالة مطابقة الفاتورة والباكينج: يوجد اختلافات في الكميات أو البنود الجمركية'
                                                : 'Invoice & Packing Reconciliation: Discrepancies found in quantities or HS codes',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.amber.shade200 : Colors.brown),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ...(isArabic ? reconciliation.discrepancySummaryList : (reconciliation.discrepancySummaryListEn.isNotEmpty ? reconciliation.discrepancySummaryListEn : reconciliation.discrepancySummaryList)).map(
                                        (d) => Padding(
                                          padding: const EdgeInsets.only(top: 2, left: 24),
                                          child: Text('• $d', style: TextStyle(fontSize: 11, color: isDark ? Colors.amber.shade100 : Colors.brown)),
                                        ),
                                      ),
                                      if (po.notes != null && po.notes!.contains('[مبررات اختلاف الفاتورة والباكينج]')) ...[
                                        const Divider(height: 14),
                                        Text(
                                          '${isArabic ? "المبرر المعتمد:" : "Approved Justification:"} ${po.notes!.split('[مبررات اختلاف الفاتورة والباكينج]:').last.trim()}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF14301D) : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isDark ? Colors.green.shade700 : Colors.green.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_outlined, color: Colors.green, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        isArabic
                                            ? 'مطابقة تامة: جميع بنود الفاتورة المبدئية متطابقة بالكامل مع بيان التعبئة في الأكواد الجمركية والكميات.'
                                            : 'Perfect Match: All proforma invoice line items match packing list in HS codes and quantities.',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                            ],

                            // Validation Status Banner
                            if (validationErrors.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF381414) : Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: isDark ? Colors.red.shade700 : Colors.red.shade300)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          isArabic ? 'أخطاء مطابقة قائمة التعبئة' : 'Packing List Validation Errors',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.redAccent : Colors.red),
                                        ),
                                      ],
                                    ),
                                    ...validationErrors.map((e) => Padding(padding: const EdgeInsets.only(top: 4, left: 24), child: Text('• $e', style: TextStyle(fontSize: 12, color: isDark ? Colors.red.shade200 : Colors.red)))),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF14301D) : Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: isDark ? Colors.green.shade700 : Colors.green.shade300)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      isArabic
                                          ? 'تم التحقق من قائمة التعبئة بنجاح — كافة الأوزان والكميات مطابقة'
                                          : 'Packing List Validation Passed — All weights and quantities verified.',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green),
                                    ),
                                  ],
                                ),
                              ),

                            if (validationWarnings.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF382C10) : Colors.amber.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade300)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: validationWarnings.map((w) => Text('⚠️ $w', style: TextStyle(fontSize: 11, color: isDark ? Colors.amber.shade200 : Colors.brown))).toList(),
                                ),
                              ),

                            if (po.palletPlanItems.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkCardBackground : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1), width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.pallet, color: AppTheme.cobalt, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          l.masterPalletPlanTitle,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cobalt.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            '🔢 ${l.totalPalletsMetric}: ${l.palletCountWithUnit(po.palletPlanItems.fold<int>(0, (sum, p) => sum + p.palletCount))}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            '📐 ${l.palletCbmWithUnit(po.palletPlanItems.fold<double>(0.0, (sum, p) => sum + (p.calculatedCbm > 0 ? p.calculatedCbm : (p.lengthCm * p.widthCm * p.heightCm / 1000000.0) * p.palletCount)).toStringAsFixed(3))}',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          icon: const Icon(Icons.view_in_ar_rounded, size: 15),
                                          label: Text(
                                            l.simulateAndLoad3d(po.palletPlanItems.fold<int>(0, (sum, p) => sum + p.palletCount)),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () => _showVisualLoadPlannerDialog(context, po),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Table(
                                      border: TableBorder.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.cloudWhite),
                                          children: [
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletTypeCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletCountCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletDimensionsCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletWeightCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletTotalWeightCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletVolumeCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                            Padding(padding: const EdgeInsets.all(6), child: Text(l.palletStackingInstructionsCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          ],
                                        ),
                                        ...po.palletPlanItems.map((pal) {
                                          final palCbm = pal.calculatedCbm > 0 ? pal.calculatedCbm : (pal.lengthCm * pal.widthCm * pal.heightCm / 1000000.0) * pal.palletCount;
                                          final palTotalWt = pal.grossWeightPerPalletKg * pal.palletCount;
                                          return TableRow(
                                            children: [
                                              Padding(padding: const EdgeInsets.all(6), child: Text(pal.palletType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                              Padding(padding: const EdgeInsets.all(6), child: Text('${pal.palletCount}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                                              Padding(padding: const EdgeInsets.all(6), child: Text('${pal.lengthCm.toStringAsFixed(0)} × ${pal.widthCm.toStringAsFixed(0)} × ${pal.heightCm.toStringAsFixed(0)} cm', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                              Padding(padding: const EdgeInsets.all(6), child: Text('${pal.grossWeightPerPalletKg.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                              Padding(padding: const EdgeInsets.all(6), child: Text('${palTotalWt.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                                              Padding(padding: const EdgeInsets.all(6), child: Text('${palCbm.toStringAsFixed(3)} m³', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))),
                                              Padding(
                                                padding: const EdgeInsets.all(6),
                                                child: Text(
                                                  pal.isStackable ? l.stackableOption : l.nonStackableOption,
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: pal.isStackable ? (isDark ? Colors.greenAccent : Colors.green.shade800) : Colors.orange.shade700),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            Text(l.poPackingListTabCount(po.packingListItems.length), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal)),
                            const SizedBox(height: 6),

                            if (po.packingListItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(l.noPackingEntriesYetDesc, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey)),
                              )
                            else
                              Table(
                                border: TableBorder.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                                columnWidths: const {
                                  0: FlexColumnWidth(1.6),
                                  1: FlexColumnWidth(1.1),
                                  2: FlexColumnWidth(1.6),
                                  3: FlexColumnWidth(0.9),
                                  4: FlexColumnWidth(0.9),
                                  5: FlexColumnWidth(0.9),
                                  6: FlexColumnWidth(1.3),
                                  7: FlexColumnWidth(1.0),
                                  8: FlexColumnWidth(1.0),
                                  9: FlexColumnWidth(1.0),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.cloudWhite),
                                    children: [
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.hsCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.itemCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.mainDescription, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.qtyPcsCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.qtyPkgCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.packageTypeCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.dimensionsCmCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.netWeightCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.grossWeightCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(l.cbmVolumeMetric, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                    ],
                                  ),
                                  ...po.packingListItems.map(
                                    (p) {
                                      final isMismatched = reconciliation.items.any((r) => r.hsCode == p.hsCode && !r.isMatched);
                                      return TableRow(
                                        decoration: isMismatched ? BoxDecoration(color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50.withOpacity(0.35)) : null,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: isMismatched
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF3B151E) : Colors.red.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.red.shade400, width: 1.1),
                                                    ),
                                                    child: Wrap(
                                                      crossAxisAlignment: WrapCrossAlignment.center,
                                                      spacing: 2,
                                                      children: [
                                                        const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.red),
                                                        Text(
                                                          p.hsCode.isNotEmpty ? p.hsCode : 'None',
                                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.redAccent : Colors.red.shade900),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Text(p.hsCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          ),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.itemCode, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.mainDescription ?? p.description ?? '-', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${p.qtyPcs}', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${p.qtyPkg}', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.packageType, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.lengthCm > 0 ? '${p.lengthCm}x${p.widthCm}x${p.heightCm}' : 'N/A', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(((p.netWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.netWeightUnitKg) : p.totalNetWeightKg).toStringAsFixed(1), style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(((p.grossWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.grossWeightUnitKg) : p.totalGrossWeightKg).toStringAsFixed(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${(p.calculatedCbm > 0 ? p.calculatedCbm : p.totalCbm).toStringAsFixed(3)} m³', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),

                            const SizedBox(height: 20),
                            Text('📊 ${l.summaryByHsCodeReport}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal)),
                            const SizedBox(height: 6),
                            Table(
                              border: TableBorder.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.cloudWhite),
                                  children: [
                                    Padding(padding: const EdgeInsets.all(6), child: Text(l.hsCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(l.qtyPcsCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(l.qtyPkgCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(l.totalNetWeightCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(l.totalGrossWeightCol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(l.totalCargoCbmMetric, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                  ],
                                ),
                                ...hsSummaryMap.values.map(
                                  (summary) {
                                    final summaryHs = '${summary['hs_code']}';
                                    final isMismatched = reconciliation.items.any((r) => r.hsCode == summaryHs && !r.isMatched);
                                    return TableRow(
                                      decoration: isMismatched ? BoxDecoration(color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50.withOpacity(0.35)) : null,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: isMismatched
                                              ? Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      summaryHs,
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.redAccent : Colors.red.shade900),
                                                    ),
                                                  ],
                                                )
                                              : Text(summaryHs, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                        ),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${summary['qty_pcs']}', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${summary['qty_pkg']}', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${(summary['total_net'] as double).toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${(summary['total_gross'] as double).toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${(summary['total_cbm'] as double).toStringAsFixed(3)} m³', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))),
                                      ],
                                    );
                                  },
                                ),
                              ],
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
          actions: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.cobalt,
                side: const BorderSide(color: AppTheme.cobalt),
              ),
              icon: const Icon(Icons.copy_all, size: 16),
              label: Text(
                l.copyAllData,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _copyPoDetailsToClipboard(dialogCtx, po, isArabic);
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l.editPurchaseOrder, style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showPODialog(context, po);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l.close),
            ),
          ],
        ),
      ),
    );
  },
);
}

  void _copyPoDetailsToClipboard(BuildContext context, PurchaseOrderModel po, bool isArabic) {
    final buffer = StringBuffer();
    buffer.writeln(isArabic ? '=== بيانات أمر الشراء / الفاتورة المبدئية ===' : '=== Purchase Order / Proforma Invoice Details ===');
    buffer.writeln('${isArabic ? "رقم أمر الشراء" : "PO Number"}: ${po.poNumber}');
    if (po.proformaInvoiceNumber != null && po.proformaInvoiceNumber!.isNotEmpty) {
      buffer.writeln('${isArabic ? "رقم الفاتورة المبدئية" : "Proforma Invoice"}: ${po.proformaInvoiceNumber}');
    }
    if (po.projectName != null && po.projectName!.isNotEmpty) {
      buffer.writeln('${isArabic ? "المشروع ومركز التكلفة" : "Project & Cost Center"}: ${po.projectName}');
    }
    if (po.companyName != null && po.companyName!.isNotEmpty) {
      buffer.writeln('${isArabic ? "الشركة المستوردة" : "Importing Company"}: ${po.companyName}');
    }
    if (po.supplierName != null && po.supplierName!.isNotEmpty) {
      buffer.writeln('${isArabic ? "المورد الأجنبي" : "Foreign Supplier"}: ${po.supplierName}');
    }
    if (po.countryOfOrigin != null && po.countryOfOrigin!.isNotEmpty) {
      buffer.writeln('${isArabic ? "بلد المنشأ" : "Country of Origin"}: ${po.countryOfOrigin}');
    }
    if (po.incotermCode != null && po.incotermCode!.isNotEmpty) {
      buffer.writeln('${isArabic ? "الشرط التجاري" : "Incoterms"}: ${po.incotermCode}');
    }
    buffer.writeln('${isArabic ? "العملة" : "Currency"}: ${po.currencyCode ?? "USD"} (${isArabic ? "سعر الصرف" : "FX Rate"}: ${po.exchangeRate})');
    if (po.paymentTerms != null && po.paymentTerms!.isNotEmpty) {
      buffer.writeln('${isArabic ? "شروط الدفع" : "Payment Terms"}: ${po.paymentTerms}');
    }
    buffer.writeln('${isArabic ? "إجمالي القيمة" : "Total Amount"}: ${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}');
    buffer.writeln('${isArabic ? "إجمالي الحجم CBM" : "Total CBM"}: ${po.totalCbm.toStringAsFixed(3)} m³');
    buffer.writeln('${isArabic ? "الوزن القائم / الصافي" : "Gross / Net Weight"}: ${po.totalGrossWeightKg.toStringAsFixed(1)} kg / ${po.totalNetWeightKg.toStringAsFixed(1)} kg');
    buffer.writeln();

    buffer.writeln(isArabic ? '--- بنود أمر الشراء والأكواد الجمركية ---' : '--- PO Line Items & HS Codes ---');
    buffer.writeln('Item Code\tMain Description\tDescription & HS Code\tQty / UOM\tUnit Price\tLine Total\tVolume CBM');
    for (final item in po.items) {
      buffer.writeln(
        '${item.itemCode ?? "-"}\t${item.mainDescription ?? "-"}\t${item.descriptionAr} (HS: ${item.hsCode ?? "-"})\t${item.quantity} ${item.unitOfMeasure}\t${po.currencyCode ?? "USD"} ${item.unitPrice.toStringAsFixed(2)}\t${po.currencyCode ?? "USD"} ${item.totalPrice.toStringAsFixed(2)}\t${item.totalCbm.toStringAsFixed(3)}',
      );
    }

    if (po.packingListItems.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(isArabic ? '--- بيان التعبئة (Packing List) ---' : '--- Packing List Items ---');
      buffer.writeln('HS Code\tItem Code\tDescription\tPackages\tPackage Type\tDimensions (cm)\tNet Weight (kg)\tGross Weight (kg)\tCBM');
      for (final pl in po.packingListItems) {
        final dims = pl.lengthCm > 0 ? '${pl.lengthCm}x${pl.widthCm}x${pl.heightCm}' : '-';
        final netWt = ((pl.netWeightUnitKg > 0 && pl.qtyPkg > 0) ? (pl.qtyPkg * pl.netWeightUnitKg) : pl.totalNetWeightKg).toStringAsFixed(1);
        final grossWt = ((pl.grossWeightUnitKg > 0 && pl.qtyPkg > 0) ? (pl.qtyPkg * pl.grossWeightUnitKg) : pl.totalGrossWeightKg).toStringAsFixed(1);
        final cbm = (pl.calculatedCbm > 0 ? pl.calculatedCbm : pl.totalCbm).toStringAsFixed(3);
        buffer.writeln(
          '${pl.hsCode}\t${pl.itemCode}\t${pl.description ?? pl.mainDescription ?? "-"}\t${pl.qtyPkg}\t${pl.packageType}\t$dims\t$netWt\t$grossWt\t$cbm',
        );
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l.copyAllPoDataSuccess,
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isDark = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        CopyableText(
          value,
          showIcon: false,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal),
        ),
      ],
    );
  }

  void _showVisualLoadPlannerDialog(BuildContext context, PurchaseOrderModel po) {
    final hasPalletPlan = po.palletPlanItems.isNotEmpty && po.palletPlanItems.any((p) => p.palletCount > 0);
    final hasSinglePallet = po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0;
    List<CargoItem> cargoItems = [];

    if (hasPalletPlan) {
      final double totalGross = po.packingListItems.fold<double>(
        0.0,
        (sum, p) => sum + (p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg)),
      );
      final int totalPallets = po.palletPlanItems.fold<int>(0, (sum, p) => sum + p.palletCount);
      final double defaultPalletWeight = totalPallets > 0 && totalGross > 0 ? (totalGross / totalPallets) : 137.5;

      int globalIdx = 1;
      for (final pLine in po.palletPlanItems) {
        final pL = pLine.lengthCm > 0 ? pLine.lengthCm : 120.0;
        final pW = pLine.widthCm > 0 ? pLine.widthCm : 80.0;
        final pH = pLine.heightCm > 0 ? pLine.heightCm : 150.0;
        final pWt = pLine.grossWeightPerPalletKg > 0 ? pLine.grossWeightPerPalletKg : defaultPalletWeight;

        for (int i = 0; i < pLine.palletCount; i++) {
          cargoItems.add(CargoItem(
            itemId: 'PLT-$globalIdx',
            length: pL,
            width: pW,
            height: pH,
            weight: pWt,
            isStackable: pLine.isStackable,
            rotate: true,
            packageType: pLine.palletType,
            description: 'بالتة #$globalIdx (${pLine.palletType})${pLine.isStackable ? "" : " [Floor Only]"}',
          ));
          globalIdx++;
        }
      }
    } else if (hasSinglePallet) {
      final double pWt = po.totalGrossWeightKg > 0 ? (po.totalGrossWeightKg / po.palletCount) : 137.5;
      for (int i = 0; i < po.palletCount; i++) {
        cargoItems.add(CargoItem(
          itemId: 'PLT-${i + 1}',
          length: po.palletLengthCm,
          width: po.palletWidthCm,
          height: po.palletHeightCm,
          weight: pWt,
          isStackable: po.isPalletStackable,
          rotate: true,
          packageType: po.palletType,
          description: 'بالتة #${i + 1} (${po.palletType})${po.isPalletStackable ? "" : " [Floor Only]"}',
        ));
      }
    } else if (po.packingListItems.isNotEmpty) {
      int globalIdx = 1;
      for (final p in po.packingListItems) {
        final lCm = p.unit == 'mm' ? p.lengthCm / 10.0 : (p.unit == 'm' ? p.lengthCm * 100.0 : p.lengthCm);
        final wCm = p.unit == 'mm' ? p.widthCm / 10.0 : (p.unit == 'm' ? p.widthCm * 100.0 : p.widthCm);
        final hCm = p.unit == 'mm' ? p.heightCm / 10.0 : (p.unit == 'm' ? p.heightCm * 100.0 : p.heightCm);
        final int count = p.qtyPkg > 0 ? p.qtyPkg.toInt() : 1;
        final double unitGrossWt = p.grossWeightUnitKg > 0
            ? p.grossWeightUnitKg
            : (p.totalGrossWeightKg > 0 ? (p.totalGrossWeightKg / count) : 10.0);

        for (int i = 0; i < count; i++) {
          cargoItems.add(CargoItem(
            itemId: '$globalIdx',
            length: lCm > 0 ? lCm : 100.0,
            width: wCm > 0 ? wCm : 80.0,
            height: hCm > 0 ? hCm : 60.0,
            weight: unitGrossWt,
            isStackable: p.isStackable,
            rotate: true,
            packageType: p.packageType,
            description: count > 1 ? '${p.itemCode} (طرد ${i + 1}/$count)' : p.itemCode,
          ));
          globalIdx++;
        }
      }
    }

    if (cargoItems.isEmpty) {
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noCargoOrPalletToSimulate)),
      );
      return;
    }

    bool? activeStackingMode = cargoItems.any((i) => !i.isStackable) ? null : true;
    bool isTopView = true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final l = dialogCtx.l10n;
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final plan = ContainerRequirementEngine.planShipment(
              cargoItems,
              forceStackable: activeStackingMode,
            );

            final totalPlanWeight = plan.fold(0.0, (s, p) => s + p.totalWeight);
            final totalPlanVolume = plan.fold(0.0, (s, p) => s + p.totalVolume);

            final Map<String, int> containerCounts = {};
            for (final p in plan) {
              if (p.containerCode != 'FAILED') {
                containerCounts[p.containerCode] = (containerCounts[p.containerCode] ?? 0) + 1;
              }
            }
            final fleetSummary = containerCounts.isEmpty
                ? l.noSuitableContainers
                : containerCounts.entries.map((e) => '${e.value} x ${e.key}').join(' + ');

            return Dialog(
              backgroundColor: isDark ? AppTheme.darkSurface : null,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: 1180,
                height: 780,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cobalt.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.view_in_ar_rounded, color: AppTheme.cobalt, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.containerLoadPlanTitle(po.displayName, po.poNumber),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal),
                              ),
                              Text(
                                l.containerLoadPlanMetrics(totalPlanVolume.toStringAsFixed(3), totalPlanWeight.toStringAsFixed(1), fleetSummary),
                                style: TextStyle(fontSize: 11.5, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment<bool>(value: true, label: Text(l.topView)),
                            ButtonSegment<bool>(value: false, label: Text(l.sideView)),
                          ],
                          selected: {isTopView},
                          onSelectionChanged: (set) => setDialogState(() => isTopView = set.first),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plan.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, idx) {
                          final cResult = plan[idx];
                          return Container(
                            width: 540,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCardBackground : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(l.containerIndexTitle(idx + 1, cResult.spec.name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                                    const Spacer(),
                                    Text(l.packagesOrPalletsCount(cResult.placedItems.length), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? AppTheme.darkTextPrimary : null)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                   child: CustomPaint(
                                     size: Size.infinite,
                                     painter: ContainerLoadPlanPainter(
                                       plan: cResult,
                                       isTopView: isTopView,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           );
                         },
                       ),
                     ),
                   ],
                 ),
               ),
             );
           },
         );
       },
     );
   }

  void _showPODialog(BuildContext context, PurchaseOrderModel? po, {Map<String, dynamic>? initialExtractedFields}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => POFormDialog(po: po, initialExtractedFields: initialExtractedFields),
    );
  }
}

// ==================================================
// PO & Packing List Reconciliation Helper & Dialog
// ==================================================
