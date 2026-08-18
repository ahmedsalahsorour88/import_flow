import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';

import '../../currencies/models/currency_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/purchase_order_model.dart';
import '../providers/purchase_orders_provider.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      ref.read(projectsProvider.notifier).fetchProjects();
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      ref.read(incotermsProvider.notifier).fetchIncoterms();
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      ref.read(customsTariffProvider.notifier).fetchTariffs();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrdersProvider);
    final projectsList = ref.watch(projectsProvider).value ?? [];

    final totalOrders = state.purchaseOrders.length;
    final totalFobSum = state.purchaseOrders.fold<double>(0.0, (sum, p) => sum + p.totalAmountFob);
    final totalCbmSum = state.purchaseOrders.fold<double>(0.0, (sum, p) => sum + p.totalCbm);
    final totalGrossSum = state.purchaseOrders.fold<double>(0.0, (sum, p) => sum + p.totalGrossWeightKg);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.charcoal, AppTheme.cobalt],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Orders & Proforma Invoices (أوامر الشراء والفواتير المبدئية)',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'المرحلة الأولى: إدارة وتسجيل أوامر الشراء، الفواتير المبدئية، وحساب الـ CBM والأوزان الإجمالية',
                        style: TextStyle(color: AppTheme.cloudWhite, fontSize: 11),
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
                  label: '🚀 استخراج الفاتورة والتعبئة الذكي',
                  onDataExtracted: (result) {
                    final fields = result.extractedFields;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم استخراج بيانات أمر الشراء بنجاح (${fields['po_number'] ?? 'بدون رقم'}) — جاري تعبئة أمر الشراء تلقائياً...',
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
                  label: const Text('New Purchase Order', style: TextStyle(fontWeight: FontWeight.bold)),
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
                _buildSummaryMetric('Total POs', '$totalOrders Order(s)', Icons.receipt_long, Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryMetric('Total PI/PO Amount', '\$${totalFobSum.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                const SizedBox(width: 12),
                _buildSummaryMetric('Total Cargo CBM', '${totalCbmSum.toStringAsFixed(2)} CBM', Icons.view_in_ar, Colors.orange),
                const SizedBox(width: 12),
                _buildSummaryMetric('Total Gross Weight', '${totalGrossSum.toStringAsFixed(1)} KG', Icons.scale, Colors.purple),
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
                          hintText: 'Search by PO Number, PI Number, or Notes...',
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
                        labelText: 'Filter by Project',
                        items: [
                          const SearchableDropdownItem<int?>(value: null, label: 'All Projects'),
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
                        labelText: 'Filter by Status',
                        items: const [
                          SearchableDropdownItem<String?>(value: null, label: 'All Statuses'),
                          SearchableDropdownItem<String?>(value: 'Draft', label: 'Draft'),
                          SearchableDropdownItem<String?>(value: 'Approved', label: 'Approved'),
                          SearchableDropdownItem<String?>(value: 'In Transit', label: 'In Transit'),
                          SearchableDropdownItem<String?>(value: 'Closed', label: 'Closed'),
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
                        const Text('Show Inactive', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                      tooltip: 'Live Refresh',
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
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state.purchaseOrders.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No Purchase Orders Found', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
    return Expanded(
      child: Card(
        elevation: 2,
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
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPOTable(BuildContext context, List<PurchaseOrderModel> orders) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              dataRowMaxHeight: 52,
              columns: const [
                DataColumn(label: Text('PO Reference')),
                DataColumn(label: Text('Invoice Date')),
                DataColumn(label: Text('Import File')),
                DataColumn(label: Text('PI Number')),
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('Company')),
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('PI/PO Amount')),
                DataColumn(label: Text('CBM / Weight')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
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

                return DataRow(
                  onSelectChanged: (_) => _showPODetailsDialog(context, po),
                  cells: [
                    DataCell(
                      InkWell(
                        onTap: () => _showPODetailsDialog(context, po),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              po.poNumber,
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
                      ),
                    ),
                    DataCell(Text(invoiceDateStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.charcoal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          po.importFileCode ?? (po.importFileId != null ? 'IMP-${po.importFileId}' : '-'),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(Text(po.proformaInvoiceNumber ?? '-')),
                    DataCell(Text(po.projectName ?? 'PRJ-#${po.projectId}')),
                    DataCell(Text(po.companyName ?? 'COMP-#${po.companyId}')),
                    DataCell(
                      Column(
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
                    DataCell(
                      Text(
                        '${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    DataCell(
                      Text('${po.totalCbm.toStringAsFixed(2)} m³ / ${po.totalGrossWeightKg.toStringAsFixed(0)} kg'),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          po.status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      RowActionsPill(
                        onView: () => _showPODetailsDialog(context, po),
                        onEdit: () => _showPODialog(context, po),
                        onPrint: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('طباعة أمر الشراء وقائمة التعبئة: ${po.poNumber} (${po.proformaInvoiceNumber ?? ""})'),
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
                              title: const Text('تأكيد الإجراء'),
                              content: Text(isActive
                                  ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل أمر الشراء (${po.poNumber})؟'
                                  : 'هل أنت متأكد من استعادة أمر الشراء (${po.poNumber})؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald),
                                  child: Text(isActive ? 'إيقاف التفعيل' : 'استعادة', style: const TextStyle(color: Colors.white)),
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
                        deleteTooltip: po.isActive ? 'إيقاف تفعيل أمر الشراء (Deactivate)' : 'استعادة أمر الشراء (Restore)',
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
    final tariffs = ref.read(customsTariffProvider).value ?? [];
    final reconciliation = _evaluateReconciliation(
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
      builder: (dialogCtx) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.inventory_2, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Text('PO & Packing List Details: ${po.poNumber} (${po.proformaInvoiceNumber ?? "No PI"})'),
            ],
          ),
          content: SizedBox(
            width: 850,
            height: 550,
            child: Column(
              children: [
                Container(
                  color: Colors.grey.shade100,
                  child: const TabBar(
                    labelColor: AppTheme.cobalt,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.cobalt,
                    tabs: [
                      Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'PO Line Items (الفاتورة المبدئية)'),
                      Tab(icon: Icon(Icons.fact_check, size: 18), text: 'Review Packing List (بيان التعبئة والوزن)'),
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
                            final double effectivePackingListCbm = po.packingListItems.isNotEmpty
                                ? po.packingListItems.fold(0.0, (sum, pl) => sum + (pl.calculatedCbm > 0 ? pl.calculatedCbm : pl.totalCbm))
                                : po.totalCbm;
                            final double effectivePackingListGrossWeight = po.packingListItems.isNotEmpty
                                ? po.packingListItems.fold(0.0, (sum, pl) => sum + ((pl.grossWeightUnitKg > 0 && pl.qtyPkg > 0) ? (pl.grossWeightUnitKg * pl.qtyPkg) : pl.totalGrossWeightKg))
                                : po.totalGrossWeightKg;
                            final double effectivePackingListNetWeight = po.packingListItems.isNotEmpty
                                ? po.packingListItems.fold(0.0, (sum, pl) => sum + ((pl.netWeightUnitKg > 0 && pl.qtyPkg > 0) ? (pl.netWeightUnitKg * pl.qtyPkg) : pl.totalNetWeightKg))
                                : po.totalNetWeightKg;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 10,
                                  children: [
                                    _buildDetailItem('Project', po.projectName ?? '-'),
                                    _buildDetailItem('Company', po.companyName ?? '-'),
                                    _buildDetailItem('Supplier', po.supplierName ?? '-'),
                                    _buildDetailItem('Country of Origin (بلد المنشأ)', po.countryOfOrigin ?? '-'),
                                    _buildDetailItem('Incoterm', po.incotermCode ?? '-'),
                                    _buildDetailItem('Currency & Rate', '${po.currencyCode ?? "USD"} (Exchange: ${po.exchangeRate})'),
                                    _buildDetailItem('Payment Terms', po.paymentTerms ?? '-'),
                                    _buildDetailItem('Total PI/PO Amount', '${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}'),
                                    _buildDetailItem('Total Volume (Packing List)', '${effectivePackingListCbm.toStringAsFixed(3)} CBM'),
                                    _buildDetailItem('Gross / Net Weight (Packing List)', '${effectivePackingListGrossWeight.toStringAsFixed(1)} kg / ${effectivePackingListNetWeight.toStringAsFixed(1)} kg'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text('PO Line Items Breakdown (بنود الفاتورة المبدئية والأكواد الجمركية)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                const SizedBox(height: 6),
                                Table(
                                  border: TableBorder.all(color: Colors.grey.shade300),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.2),
                                    1: FlexColumnWidth(3.0),
                                    2: FlexColumnWidth(1.2),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(1.2),
                                    5: FlexColumnWidth(1.5),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(color: AppTheme.cloudWhite),
                                      children: [
                                        Padding(padding: EdgeInsets.all(6), child: Text('Item Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(6), child: Text('Description & HS Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(6), child: Text('Qty / UOM', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(6), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(6), child: Text('Line Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(6), child: Text('Volume CBM (Packing List)', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.descriptionAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  if (item.countryOfOrigin != null && item.countryOfOrigin!.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text('المنشأ: ${item.countryOfOrigin}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
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
                                                                    'HS: $itemHs (Duty: ${item.dutyRate ?? 0}% / VAT: ${item.vatRate ?? 0}%)',
                                                                    style: TextStyle(color: Colors.red.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(2)),
                                                                    child: Text('⚠️ عدم تطابق', style: TextStyle(color: Colors.red.shade900, fontSize: 9, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : Text(
                                                              'HS: $itemHs (Duty: ${item.dutyRate ?? 0}% / VAT: ${item.vatRate ?? 0}%)',
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
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.shade400),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'حالة مطابقة الفاتورة والباكينج: يوجد اختلافات في الكميات أو البنود الجمركية',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ...reconciliation.discrepancySummaryList.map(
                                        (d) => Padding(
                                          padding: const EdgeInsets.only(top: 2, left: 24),
                                          child: Text('• $d', style: const TextStyle(fontSize: 11, color: Colors.brown)),
                                        ),
                                      ),
                                      if (po.notes != null && po.notes!.contains('[مبررات اختلاف الفاتورة والباكينج]')) ...[
                                        const Divider(height: 14),
                                        Text(
                                          'المبرر المعتمد: ${po.notes!.split('[مبررات اختلاف الفاتورة والباكينج]:').last.trim()}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal),
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
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified_outlined, color: Colors.green, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'مطابقة تامة: جميع بنود الفاتورة المبدئية متطابقة بالكامل مع بيان التعبئة في الأكواد الجمركية والكميات.',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
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
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade300)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 18),
                                        SizedBox(width: 6),
                                        Text('Packing List Validation Errors (أخطاء مطابقة الوزن والعبوات)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                    ...validationErrors.map((e) => Padding(padding: const EdgeInsets.only(top: 4, left: 24), child: Text('• $e', style: const TextStyle(fontSize: 12, color: Colors.red)))),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade300)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                    SizedBox(width: 6),
                                    Text('Packing List Validation Passed — All weights and quantities verified.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ),

                            if (validationWarnings.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade300)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: validationWarnings.map((w) => Text('⚠️ $w', style: const TextStyle(fontSize: 11, color: Colors.brown))).toList(),
                                ),
                              ),

                            const Text('Packing List Breakdown (تفاصيل طرود ومقاسات الشحنة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                            const SizedBox(height: 6),

                            if (po.packingListItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No detailed packing list items recorded yet. Click "Edit PO & Packing List" to add packing details.', style: TextStyle(color: Colors.grey)),
                              )
                            else
                              Table(
                                border: TableBorder.all(color: Colors.grey.shade300),
                                columnWidths: const {
                                  0: FlexColumnWidth(1.8),
                                  1: FlexColumnWidth(1.2),
                                  2: FlexColumnWidth(1.0),
                                  3: FlexColumnWidth(1.0),
                                  4: FlexColumnWidth(1.0),
                                  5: FlexColumnWidth(1.4),
                                  6: FlexColumnWidth(1.1),
                                  7: FlexColumnWidth(1.1),
                                  8: FlexColumnWidth(1.1),
                                },
                                children: [
                                  const TableRow(
                                    decoration: BoxDecoration(color: AppTheme.cloudWhite),
                                    children: [
                                      Padding(padding: EdgeInsets.all(6), child: Text('HS Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Item Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Qty PCS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Qty PKG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Pkg Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Dimensions (cm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Net Wt (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('Gross Wt (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      Padding(padding: EdgeInsets.all(6), child: Text('CBM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    ],
                                  ),
                                  ...po.packingListItems.map(
                                    (p) {
                                      final isMismatched = reconciliation.items.any((r) => r.hsCode == p.hsCode && !r.isMatched);
                                      return TableRow(
                                        decoration: isMismatched ? BoxDecoration(color: Colors.red.shade50.withOpacity(0.35)) : null,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: isMismatched
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
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
                                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Text(p.hsCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          ),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.itemCode, style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${p.qtyPcs}', style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${p.qtyPkg}', style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.packageType, style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(p.lengthCm > 0 ? '${p.lengthCm}x${p.widthCm}x${p.heightCm}' : 'N/A', style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${((p.netWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.netWeightUnitKg) : p.totalNetWeightKg).toStringAsFixed(1)}', style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${((p.grossWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.grossWeightUnitKg) : p.totalGrossWeightKg).toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text('${(p.calculatedCbm > 0 ? p.calculatedCbm : p.totalCbm).toStringAsFixed(3)} m³', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),

                            const SizedBox(height: 20),
                            const Text('📊 Report: Packing List Summary By HS Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                            const SizedBox(height: 6),
                            Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: AppTheme.cloudWhite),
                                  children: [
                                    Padding(padding: EdgeInsets.all(6), child: Text('HS Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Qty PCS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Qty PKG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Total Net Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Total Gross Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Total CBM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  ],
                                ),
                                ...hsSummaryMap.values.map(
                                  (summary) {
                                    final summaryHs = '${summary['hs_code']}';
                                    final isMismatched = reconciliation.items.any((r) => r.hsCode == summaryHs && !r.isMatched);
                                    return TableRow(
                                      decoration: isMismatched ? BoxDecoration(color: Colors.red.shade50.withOpacity(0.35)) : null,
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
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                                    ),
                                                  ],
                                                )
                                              : Text(summaryHs, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                        ),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${summary['qty_pcs']}', style: const TextStyle(fontSize: 11))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${summary['qty_pkg']}', style: const TextStyle(fontSize: 11))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${(summary['total_net'] as double).toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11))),
                                        Padding(padding: const EdgeInsets.all(6), child: Text('${(summary['total_gross'] as double).toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('تعديل أمر الشراء (Edit PO)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showPODialog(context, po);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
      ],
    );
  }

  void _showPODialog(BuildContext context, PurchaseOrderModel? po, {Map<String, dynamic>? initialExtractedFields}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _PODialogWidget(po: po, initialExtractedFields: initialExtractedFields),
    );
  }
}

// ==================================================
// PO & Packing List Reconciliation Helper & Dialog
// ==================================================

class POReconciliationItem {
  final String hsCode;
  final double invoiceQty;
  final double packingQty;
  final double difference; // packingQty - invoiceQty
  final bool isMatched;
  final bool isMissingInPacking;
  final bool isMissingInInvoice;

  POReconciliationItem({
    required this.hsCode,
    required this.invoiceQty,
    required this.packingQty,
    required this.difference,
    required this.isMatched,
    this.isMissingInPacking = false,
    this.isMissingInInvoice = false,
  });
}

class POReconciliationReport {
  final bool hasDiscrepancy;
  final double totalInvoiceQty;
  final double totalPackingQty;
  final double totalDifference;
  final List<POReconciliationItem> items;
  final List<String> discrepancySummaryList;

  POReconciliationReport({
    required this.hasDiscrepancy,
    required this.totalInvoiceQty,
    required this.totalPackingQty,
    required this.totalDifference,
    required this.items,
    required this.discrepancySummaryList,
  });
}

POReconciliationReport _evaluateReconciliation({
  required List<POLineItemModel> invoiceItems,
  required List<PackingListItemModel> packingItems,
  required List<CustomsTariffModel> tariffs,
}) {
  if (packingItems.isEmpty) {
    return POReconciliationReport(
      hasDiscrepancy: false,
      totalInvoiceQty: invoiceItems.fold(0.0, (s, i) => s + i.quantity),
      totalPackingQty: 0.0,
      totalDifference: 0.0,
      items: [],
      discrepancySummaryList: [],
    );
  }

  final Map<String, double> invoiceHsMap = {};
  double totalInv = 0.0;
  for (final item in invoiceItems) {
    totalInv += item.quantity;
    String hs = 'بدون بند جمركي (Unassigned)';
    if (item.tariffId != null) {
      final match = tariffs.cast<CustomsTariffModel?>().firstWhere(
        (t) => t?.tariffId == item.tariffId,
        orElse: () => null,
      );
      if (match != null && match.hsCode.isNotEmpty) {
        hs = match.hsCode;
      }
    } else if (item.hsCode != null && item.hsCode!.isNotEmpty) {
      hs = item.hsCode!;
    }
    invoiceHsMap[hs] = (invoiceHsMap[hs] ?? 0.0) + item.quantity;
  }

  final Map<String, double> packingHsMap = {};
  double totalPkg = 0.0;
  for (final p in packingItems) {
    totalPkg += p.qtyPcs;
    final hs = p.hsCode.isNotEmpty ? p.hsCode : 'بدون بند جمركي (Unassigned)';
    packingHsMap[hs] = (packingHsMap[hs] ?? 0.0) + p.qtyPcs;
  }

  final Set<String> allHs = {...invoiceHsMap.keys, ...packingHsMap.keys};
  final List<POReconciliationItem> items = [];
  final List<String> warnings = [];
  bool hasDiscrepancy = false;

  for (final hs in allHs) {
    final invQty = invoiceHsMap[hs] ?? 0.0;
    final pkgQty = packingHsMap[hs] ?? 0.0;
    final diff = pkgQty - invQty;
    final matched = (diff.abs() < 0.001);

    final isMissingInPkg = (invQty > 0 && pkgQty == 0);
    final isMissingInInv = (pkgQty > 0 && invQty == 0);

    if (isMissingInPkg) {
      hasDiscrepancy = true;
      warnings.add('البند الجمركي $hs موجود بالفاتورة (كمية: $invQty) وغير موجود ببيان التعبئة');
    } else if (isMissingInInv) {
      hasDiscrepancy = true;
      warnings.add('البند الجمركي $hs موجود ببيان التعبئة (كمية: $pkgQty) وغير موجود بالفاتورة');
    } else if (!matched) {
      hasDiscrepancy = true;
      warnings.add('البند الجمركي $hs: كمية الفاتورة ($invQty) تختلف عن كمية الباكينج ($pkgQty) بفارق ($diff)');
    }

    items.add(
      POReconciliationItem(
        hsCode: hs,
        invoiceQty: invQty,
        packingQty: pkgQty,
        difference: diff,
        isMatched: matched,
        isMissingInPacking: isMissingInPkg,
        isMissingInInvoice: isMissingInInv,
      ),
    );
  }

  final totalDiff = totalPkg - totalInv;
  if (totalDiff.abs() > 0.001) {
    hasDiscrepancy = true;
    warnings.add('إجمالي عدد القطع: الفاتورة ($totalInv) والباكينج ($totalPkg) بفارق ($totalDiff)');
  }

  return POReconciliationReport(
    hasDiscrepancy: hasDiscrepancy,
    totalInvoiceQty: totalInv,
    totalPackingQty: totalPkg,
    totalDifference: totalDiff,
    items: items,
    discrepancySummaryList: warnings,
  );
}

class _ReconciliationWarningDialog extends StatefulWidget {
  final POReconciliationReport report;

  const _ReconciliationWarningDialog({required this.report});

  @override
  State<_ReconciliationWarningDialog> createState() => _ReconciliationWarningDialogState();
}

class _ReconciliationWarningDialogState extends State<_ReconciliationWarningDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تنبيه: عدم تطابق بين الفاتورة المبدئية وبيان التعبئة',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Packing List & Commercial Invoice Discrepancy Alert',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 750,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text('إجمالي قطع الفاتورة', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${report.totalInvoiceQty.toStringAsFixed(1)} PCS', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text('إجمالي قطع الباكينج', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${report.totalPackingQty.toStringAsFixed(1)} PCS', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: report.totalDifference != 0 ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: report.totalDifference != 0 ? Colors.red.shade300 : Colors.green.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text('فارق الكمية الكلي', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '${report.totalDifference > 0 ? "+" : ""}${report.totalDifference.toStringAsFixed(1)} PCS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: report.totalDifference != 0 ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'جدول المقارنة التفصيلي حسب البند الجمركي (HS Code Breakdown):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 8),

              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(2.0),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppTheme.cloudWhite),
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('البند الجمركي (HS Code)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الفاتورة (Qty)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الباكينج (Qty)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الفارق (Diff)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('الحالة (Status)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  ...report.items.map((item) {
                    Color rowBg = Colors.white;
                    Color statusColor = Colors.green;
                    String statusText = 'متطابق (Matched)';

                    if (item.isMissingInPacking) {
                      rowBg = Colors.red.shade50.withOpacity(0.5);
                      statusColor = Colors.red.shade700;
                      statusText = 'غير موجود بالباكينج';
                    } else if (item.isMissingInInvoice) {
                      rowBg = Colors.amber.shade50.withOpacity(0.5);
                      statusColor = Colors.amber.shade900;
                      statusText = 'غير موجود بالفاتورة';
                    } else if (!item.isMatched) {
                      rowBg = Colors.orange.shade50.withOpacity(0.5);
                      statusColor = Colors.deepOrange;
                      statusText = 'اختلاف بالكمية';
                    }

                    return TableRow(
                      decoration: BoxDecoration(color: rowBg),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item.hsCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${item.invoiceQty}', style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${item.packingQty}', style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${item.difference > 0 ? "+" : ""}${item.difference}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.difference != 0 ? Colors.red.shade700 : Colors.green,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Discrepancy Bullet points
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.brown, size: 16),
                        SizedBox(width: 6),
                        Text('أسباب عدم التطابق المرصودة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...report.discrepancySummaryList.map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(top: 2, left: 16),
                        child: Text('• $msg', style: const TextStyle(fontSize: 11, color: Colors.brown)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mandatory Justification Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'لإتمام الحفظ، يجب توضيح سبب الاستمرار وتبرير الفروقات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'سبب الاستمرار وتبرير الاختلاف (Discrepancy Justification Reason) *',
                        hintText: 'مثال: كل قطعة بالفاتورة تتكون من كرتونتين مكملتين في بيان التعبئة، أو شحنة مجزأة...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber.shade800, width: 2)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يجب إدخال سبب وتبرير استمرار الحفظ رغم وجود الاختلاف.';
                        }
                        if (val.trim().length < 5) {
                          return 'الرجاء إدخال تبرير واضح ومفصل (5 أحرف على الأقل).';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('الرجوع للتعديل (Back to Edit)'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context, null),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('الاستمرار وحفظ أمر الشراء (Continue & Save)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _reasonCtrl.text.trim());
            }
          },
        ),
      ],
    );
  }
}
class _PODialogWidget extends ConsumerStatefulWidget {
  final PurchaseOrderModel? po;
  final Map<String, dynamic>? initialExtractedFields;

  const _PODialogWidget({this.po, this.initialExtractedFields});

  @override
  ConsumerState<_PODialogWidget> createState() => _PODialogWidgetState();
}

class _PODialogWidgetState extends ConsumerState<_PODialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _piCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _selectedOrderDate;
  int? _selectedImportFileId;
  int? _selectedProjectId;
  int? _selectedCompanyId;
  int? _selectedSupplierId;
  int? _selectedIncotermId;
  int? _selectedCurrencyId;
  String? _selectedCountryOfOrigin;
  late String _selectedStatus;
  late String _selectedPaymentTerms;

  static const List<Map<String, String>> countryOptions = [
    {'code': 'CN', 'name': 'CN - الصين (China)'},
    {'code': 'DE', 'name': 'DE - ألمانيا (Germany)'},
    {'code': 'IT', 'name': 'IT - إيطاليا (Italy)'},
    {'code': 'TR', 'name': 'TR - تركيا (Turkey)'},
    {'code': 'FR', 'name': 'FR - فرنسا (France)'},
    {'code': 'ES', 'name': 'ES - إسبانيا (Spain)'},
    {'code': 'GB', 'name': 'GB - المملكة المتحدة (United Kingdom)'},
    {'code': 'US', 'name': 'US - الولايات المتحدة الأمريكية (USA)'},
    {'code': 'BR', 'name': 'BR - البرازيل (Brazil)'},
    {'code': 'AR', 'name': 'AR - الأرجنتين (Argentina)'},
    {'code': 'IN', 'name': 'IN - الهند (India)'},
    {'code': 'JP', 'name': 'JP - اليابان (Japan)'},
    {'code': 'KR', 'name': 'KR - كوريا الجنوبية (South Korea)'},
    {'code': 'SA', 'name': 'SA - المملكة العربية السعودية (Saudi Arabia)'},
    {'code': 'AE', 'name': 'AE - الإمارات العربية المتحدة (UAE)'},
    {'code': 'JO', 'name': 'JO - الأردن (Jordan)'},
    {'code': 'MA', 'name': 'MA - المغرب (Morocco)'},
    {'code': 'TN', 'name': 'TN - تونس (Tunisia)'},
    {'code': 'LB', 'name': 'LB - لبنان (Lebanon)'},
    {'code': 'NL', 'name': 'NL - هولندا (Netherlands)'},
    {'code': 'BE', 'name': 'BE - بلجيكا (Belgium)'},
    {'code': 'AT', 'name': 'AT - النمسا (Austria)'},
    {'code': 'PL', 'name': 'PL - بولندا (Poland)'},
    {'code': 'SE', 'name': 'SE - السويد (Sweden)'},
    {'code': 'CH', 'name': 'CH - سويسرا (Switzerland)'},
    {'code': 'RU', 'name': 'RU - روسيا (Russia)'},
    {'code': 'VN', 'name': 'VN - فيتنام (Vietnam)'},
    {'code': 'TH', 'name': 'TH - تايلاند (Thailand)'},
    {'code': 'MY', 'name': 'MY - ماليزيا (Malaysia)'},
    {'code': 'ID', 'name': 'ID - إندونيسيا (Indonesia)'},
    {'code': 'EG', 'name': 'EG - مصر (Egypt)'},
  ];

  late List<POLineItemModel> _dialogItems;
  late List<PackingListItemModel> _dialogPackingItems;
  bool _isSubmitting = false;

  Future<CustomsTariffModel?> _showHsCodeSearchPicker(BuildContext context, List<CustomsTariffModel> tariffs) async {
    return showDialog<CustomsTariffModel?>(
      context: context,
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = tariffs.where((t) {
              final query = search.trim().toLowerCase();
              if (query.isEmpty) return true;
              return t.hsCode.toLowerCase().contains(query) ||
                  t.hsDescription.toLowerCase().contains(query) ||
                  (t.customsCategory?.toLowerCase().contains(query) ?? false);
            }).toList();

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.cobalt),
                  SizedBox(width: 8),
                  Text('اختيار البند الجمركي (Customs Tariff / HS Code)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم البند الجمركي أو الوصف (مثال: 8415 أو تكييف)...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                        suffixIcon: search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setDialogState(() => search = ''),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد نتائج مطابقة لمفتاح البحث'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final item = filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cobalt.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.hsCode,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.hsDescription,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'الفئة: ${item.customsCategory ?? "عام"} | جمارك: ${item.customsDutyRate}% | قيمة مضافة: ${item.vatRate}% | رسم تنمية: ${item.developmentFeeRate}%',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(ctx, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateExchangeRateFromCurrency(int? currencyId, List<CurrencyModel> currencies) {
    if (currencyId == null) return;
    final curr = currencies.where((c) => c.currencyId == currencyId).firstOrNull;
    if (curr == null) return;
    if (curr.isBaseCurrency || curr.currencyCode == 'EGP') {
      _rateCtrl.text = '1.0';
      return;
    }

    double? foundRate;
    if (curr.exchangeRates != null && curr.exchangeRates!.isNotEmpty) {
      final orderDateStr = _selectedOrderDate.toString().substring(0, 10);
      final sortedRates = List.from(curr.exchangeRates!)
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      final matching = sortedRates.firstWhere(
        (r) => r.effectiveDate.compareTo(orderDateStr) <= 0,
        orElse: () => sortedRates.first,
      );
      foundRate = matching.commercialRate;
    }

    foundRate ??= curr.latestCommercialRate;
    if (foundRate != null && foundRate > 0) {
      _rateCtrl.text = foundRate.toString();
    }
  }

  DateTime _parseFlexDate(String? rawStr) {
    if (rawStr == null || rawStr.trim().isEmpty) return DateTime.now();
    final s = rawStr.trim();
    final parsedIso = DateTime.tryParse(s);
    if (parsedIso != null) return parsedIso;

    final parts = s.split(RegExp(r'[/-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]) ?? 1;
      final p1 = int.tryParse(parts[1]) ?? 1;
      final p2 = int.tryParse(parts[2]) ?? DateTime.now().year;
      if (p2 > 1000) {
        return DateTime(p2, p1, p0);
      } else if (p0 > 1000) {
        return DateTime(p0, p1, p2);
      }
    }
    return DateTime.now();
  }

  void _applyExtractedFieldsToState(Map<String, dynamic> ext) {
    setState(() {
      final poNum = ext['po_number']?.toString() ?? ext['proforma_invoice_number']?.toString();
      if (poNum != null && poNum.isNotEmpty) {
        _piCtrl.text = poNum;
      }
      final dateStr = (ext['order_date'] ?? ext['po_date'] ?? ext['date'])?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        _selectedOrderDate = _parseFlexDate(dateStr);
      }

      final rawTerms = ext['payment_terms']?.toString();
      if (rawTerms != null) {
        if (rawTerms.contains('LC') || rawTerms.contains('اعتماد') || rawTerms.contains('CREDIT')) {
          _selectedPaymentTerms = 'Letter of Credit / LC';
        } else if (rawTerms.contains('SWIFT') || rawTerms.contains('Cash') || rawTerms.contains('سويفت') || rawTerms.contains('T/T')) {
          _selectedPaymentTerms = 'Cash in Advance / SWIFT';
        }
      }

      if (ext['items'] is List && (ext['items'] as List).isNotEmpty) {
        final itemList = ext['items'] as List;
        _dialogItems = itemList.map((raw) {
          final i = Map<String, dynamic>.from(raw as Map);
          final qty = (i['quantity'] as num?)?.toDouble() ?? 100.0;
          final price = (i['unit_price'] as num?)?.toDouble() ?? 10.0;
          final desc = i['description']?.toString() ?? 'بند استيرادي رئيسي';
          final code = i['item_code']?.toString() ?? 'ITEM-001';
          return POLineItemModel(
            itemCode: code,
            descriptionAr: desc,
            descriptionEn: desc,
            quantity: qty > 0 ? qty : 100.0,
            unitPrice: price > 0 ? price : 10.0,
            cbmPerUnit: (i['cbm_per_unit'] as num?)?.toDouble() ?? 0.1,
            grossWeightKg: (i['gross_weight_kg'] as num?)?.toDouble() ?? 5.0,
            netWeightKg: (i['net_weight_kg'] as num?)?.toDouble() ?? 4.5,
          );
        }).toList();
      }

      if (ext['packing_list_items'] is List && (ext['packing_list_items'] as List).isNotEmpty) {
        final packingList = ext['packing_list_items'] as List;
        _dialogPackingItems = packingList.map((raw) {
          final p = Map<String, dynamic>.from(raw as Map);
          return PackingListItemModel(
            hsCode: p['hs_code']?.toString() ?? '',
            itemCode: p['item_code']?.toString() ?? 'ITEM-001',
            qtyPcs: (p['qty_pcs'] as num?)?.toDouble() ?? 1.0,
            qtyPkg: (p['qty_pkg'] as num?)?.toDouble() ?? 1.0,
            packageType: p['package_type']?.toString() ?? 'Pallet',
            lengthCm: (p['length_cm'] as num?)?.toDouble() ?? 110.0,
            widthCm: (p['width_cm'] as num?)?.toDouble() ?? 110.0,
            heightCm: (p['height_cm'] as num?)?.toDouble() ?? 106.0,
            grossWeightUnitKg: (p['gross_weight_unit_kg'] as num?)?.toDouble() ?? 646.0,
            netWeightUnitKg: (p['net_weight_unit_kg'] as num?)?.toDouble() ?? 626.0,
            isStackable: p['is_stackable'] as bool? ?? true,
          );
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final po = widget.po;
    final ext = widget.initialExtractedFields;

    _selectedOrderDate = po?.orderDate ??
        (ext != null ? _parseFlexDate((ext['order_date'] ?? ext['po_date'] ?? ext['date'])?.toString()) : DateTime.now());

    final defaultPiNumber = po?.proformaInvoiceNumber ??
        (ext != null ? (ext['po_number'] ?? ext['proforma_invoice_number'])?.toString() : null) ?? '';
    _piCtrl = TextEditingController(text: defaultPiNumber);
    _rateCtrl = TextEditingController(text: (po?.exchangeRate ?? 1.0).toString());
    _notesCtrl = TextEditingController(text: po?.notes ?? '');
    _selectedStatus = po?.status ?? 'Draft';

    final rawTerms = po?.paymentTerms ?? (ext != null ? ext['payment_terms']?.toString() : null);
    if (rawTerms != null && (rawTerms.contains('LC') || rawTerms.contains('اعتماد') || rawTerms.contains('CREDIT'))) {
      _selectedPaymentTerms = 'Letter of Credit / LC';
    } else if (rawTerms != null && (rawTerms.contains('SWIFT') || rawTerms.contains('Cash') || rawTerms.contains('سويفت') || rawTerms.contains('T/T') || rawTerms.contains('CHK') || rawTerms.contains('DBT'))) {
      _selectedPaymentTerms = 'Cash in Advance / SWIFT';
    } else {
      _selectedPaymentTerms = rawTerms ?? 'Cash in Advance / SWIFT';
    }

    _selectedImportFileId = po?.importFileId;
    _selectedProjectId = po?.projectId;
    _selectedCompanyId = po?.companyId;
    _selectedSupplierId = po?.supplierId;
    _selectedIncotermId = po?.incotermId;
    _selectedCurrencyId = po?.currencyId;
    _selectedCountryOfOrigin = po?.countryOfOrigin;

    if (po != null && po.items.isNotEmpty) {
      _dialogItems = po.items.map((i) => POLineItemModel(
            itemCode: i.itemCode,
            descriptionAr: i.descriptionAr,
            descriptionEn: i.descriptionEn,
            countryOfOrigin: i.countryOfOrigin,
            tariffId: i.tariffId,
            quantity: i.quantity,
            unitOfMeasure: i.unitOfMeasure,
            unitPrice: i.unitPrice,
            cbmPerUnit: i.cbmPerUnit,
            grossWeightKg: i.grossWeightKg,
            netWeightKg: i.netWeightKg,
          )).toList();
    } else if (ext != null && ext['items'] is List && (ext['items'] as List).isNotEmpty) {
      final itemList = ext['items'] as List;
      _dialogItems = itemList.map((raw) {
        final i = Map<String, dynamic>.from(raw as Map);
        final qty = (i['quantity'] as num?)?.toDouble() ?? 100.0;
        final price = (i['unit_price'] as num?)?.toDouble() ?? 10.0;
        final desc = i['description']?.toString() ?? 'بند استيرادي رئيسي';
        final code = i['item_code']?.toString() ?? 'ITEM-001';
        return POLineItemModel(
          itemCode: code,
          descriptionAr: desc,
          descriptionEn: desc,
          quantity: qty > 0 ? qty : 100.0,
          unitPrice: price > 0 ? price : 10.0,
          cbmPerUnit: (i['cbm_per_unit'] as num?)?.toDouble() ?? 0.1,
          grossWeightKg: (i['gross_weight_kg'] as num?)?.toDouble() ?? 5.0,
          netWeightKg: (i['net_weight_kg'] as num?)?.toDouble() ?? 4.5,
        );
      }).toList();
    } else {
      _dialogItems = [
        POLineItemModel(
          descriptionAr: 'بند استيرادي رئيسي 1',
          quantity: 100,
          unitPrice: 10,
          cbmPerUnit: 0.1,
        )
      ];
    }

    if (po != null && po.packingListItems.isNotEmpty) {
      _dialogPackingItems = po.packingListItems.map((p) => PackingListItemModel(
            hsCode: p.hsCode,
            itemCode: p.itemCode,
            qtyPcs: p.qtyPcs,
            qtyPkg: p.qtyPkg,
            packageType: p.packageType,
            lengthCm: p.lengthCm,
            widthCm: p.widthCm,
            heightCm: p.heightCm,
            netWeightUnitKg: p.netWeightUnitKg,
            grossWeightUnitKg: p.grossWeightUnitKg,
            isStackable: p.isStackable,
          )).toList();
    } else if (ext != null && ext['packing_list_items'] is List && (ext['packing_list_items'] as List).isNotEmpty) {
      final packingList = ext['packing_list_items'] as List;
      _dialogPackingItems = packingList.map((raw) {
        final p = Map<String, dynamic>.from(raw as Map);
        return PackingListItemModel(
          hsCode: p['hs_code']?.toString() ?? '',
          itemCode: p['item_code']?.toString() ?? 'ITEM-001',
          qtyPcs: (p['qty_pcs'] as num?)?.toDouble() ?? 1.0,
          qtyPkg: (p['qty_pkg'] as num?)?.toDouble() ?? 1.0,
          packageType: p['package_type']?.toString() ?? 'Pallet',
          lengthCm: (p['length_cm'] as num?)?.toDouble() ?? 110.0,
          widthCm: (p['width_cm'] as num?)?.toDouble() ?? 110.0,
          heightCm: (p['height_cm'] as num?)?.toDouble() ?? 106.0,
          grossWeightUnitKg: (p['gross_weight_unit_kg'] as num?)?.toDouble() ?? 646.0,
          netWeightUnitKg: (p['net_weight_unit_kg'] as num?)?.toDouble() ?? 626.0,
          isStackable: p['is_stackable'] as bool? ?? true,
        );
      }).toList();
    } else {
      _dialogPackingItems = _dialogItems.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return PackingListItemModel(
          hsCode: item.hsCode ?? '',
          itemCode: item.itemCode ?? 'ITEM-${(idx + 1).toString().padLeft(3, '0')}',
          qtyPcs: item.quantity,
          qtyPkg: (item.quantity > 0 ? (item.quantity / 10).ceilToDouble() : 10.0),
          packageType: 'Carton',
          lengthCm: 50.0,
          widthCm: 40.0,
          heightCm: 30.0,
          netWeightUnitKg: item.netWeightKg > 0 ? item.netWeightKg : 5.0,
          grossWeightUnitKg: item.grossWeightKg > 0 ? item.grossWeightKg : 6.0,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _piCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? [];
    final companies = ref.watch(importCompaniesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];
    final incoterms = ref.watch(incotermsProvider).value ?? [];
    final currencies = ref.watch(currenciesProvider).value ?? [];
    final tariffs = ref.watch(customsTariffProvider).value ?? [];
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    final isLoadingMaster = projects.isEmpty || companies.isEmpty || suppliers.isEmpty || incoterms.isEmpty || currencies.isEmpty;

    final reconciliation = _evaluateReconciliation(
      invoiceItems: _dialogItems,
      packingItems: _dialogPackingItems,
      tariffs: tariffs,
    );
    final Set<String> mismatchedHsCodes = reconciliation.items
        .where((item) => !item.isMatched || item.isMissingInPacking || item.isMissingInInvoice)
        .map((item) => item.hsCode)
        .toSet();

    final ext = widget.initialExtractedFields;
    if (widget.po == null && ext != null) {
      if (_selectedCurrencyId == null && currencies.isNotEmpty) {
        final extCurr = (ext['currency'] ?? ext['currency_code'] ?? '').toString().trim().toUpperCase();
        if (extCurr.isNotEmpty) {
          final matchedCurr = currencies.where((c) => c.currencyCode.toUpperCase() == extCurr).firstOrNull;
          if (matchedCurr != null) {
            _selectedCurrencyId = matchedCurr.currencyId;
            _updateExchangeRateFromCurrency(_selectedCurrencyId, currencies);
          }
        }
      }

      if (_selectedIncotermId == null && incoterms.isNotEmpty) {
        final extInco = (ext['incoterms'] ?? ext['incoterm'] ?? '').toString().trim().toUpperCase();
        if (extInco.isNotEmpty) {
          final matchedInco = incoterms.where((i) => i.incotermCode.toUpperCase() == extInco || extInco.contains(i.incotermCode.toUpperCase())).firstOrNull;
          if (matchedInco != null) {
            _selectedIncotermId = matchedInco.incotermId;
          }
        }
      }

      if (_selectedSupplierId == null && suppliers.isNotEmpty) {
        final extSupp = (ext['supplier_name'] ?? ext['supplier'] ?? '').toString().trim().toLowerCase();
        if (extSupp.isNotEmpty) {
          final matchedSupp = suppliers.where((s) {
            final sName = s.companyName.toLowerCase();
            return sName.contains(extSupp) || extSupp.contains(sName);
          }).firstOrNull;
          if (matchedSupp != null) {
            _selectedSupplierId = matchedSupp.supplierId;
          }
        }
      }

      if (_selectedCountryOfOrigin == null) {
        final extCountry = (ext['country_of_origin'] ?? ext['country'] ?? '').toString().trim().toUpperCase();
        if (extCountry.isNotEmpty) {
          final matchedCty = countryOptions.where((c) => c['code'] == extCountry || c['name']!.toUpperCase().contains(extCountry)).firstOrNull;
          if (matchedCty != null) {
            _selectedCountryOfOrigin = matchedCty['code'];
          }
        }
      }
    }

    if (_selectedProjectId == null && projects.isNotEmpty) {
      _selectedProjectId = projects.first.projectId;
    } else if (_selectedProjectId != null && !projects.any((p) => p.projectId == _selectedProjectId)) {
      _selectedProjectId = projects.isNotEmpty ? projects.first.projectId : null;
    }

    if (_selectedCompanyId == null && companies.isNotEmpty) {
      _selectedCompanyId = companies.first.companyId;
    } else if (_selectedCompanyId != null && !companies.any((c) => c.companyId == _selectedCompanyId)) {
      _selectedCompanyId = companies.isNotEmpty ? companies.first.companyId : null;
    }

    if (_selectedSupplierId == null && suppliers.isNotEmpty) {
      _selectedSupplierId = suppliers.first.supplierId;
    } else if (_selectedSupplierId != null && !suppliers.any((s) => s.supplierId == _selectedSupplierId)) {
      _selectedSupplierId = suppliers.isNotEmpty ? suppliers.first.supplierId : null;
    }

    if (_selectedIncotermId == null && incoterms.isNotEmpty) {
      _selectedIncotermId = incoterms.first.incotermId;
    } else if (_selectedIncotermId != null && !incoterms.any((i) => i.incotermId == _selectedIncotermId)) {
      _selectedIncotermId = incoterms.isNotEmpty ? incoterms.first.incotermId : null;
    }

    if (_selectedCurrencyId == null && currencies.isNotEmpty) {
      _selectedCurrencyId = currencies.first.currencyId;
    } else if (_selectedCurrencyId != null && !currencies.any((c) => c.currencyId == _selectedCurrencyId)) {
      _selectedCurrencyId = currencies.isNotEmpty ? currencies.first.currencyId : null;
    }

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Container(
          decoration: const BoxDecoration(
            color: AppTheme.charcoal,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.po == null ? 'Create New Purchase Order (أمر شراء جديد)' : 'Edit Purchase Order (${widget.po!.poNumber})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SmartUploadButton(
                      module: SmartUploadModule.purchaseOrder,
                      compact: true,
                      label: '🚀 رفع واستخراج المستندات (Invoice + Packing List)',
                      onDataExtracted: (result) {
                        _applyExtractedFieldsToState(result.extractedFields);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت تعبئة بيانات أمر الشراء وكشف التعبئة بنجاح!'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: AppTheme.emerald,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppTheme.emerald,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.list_alt, size: 18),
                    text: 'Commercial Header & Items (${_dialogItems.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    text: 'Packing List (${_dialogPackingItems.length})',
                  ),
                ],
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 850,
          height: 520,
          child: isLoadingMaster
              ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل البيانات المرجعية...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: TabBarView(
                    children: [
                      // Tab 1: Commercial Header & Line Items
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SearchableDropdownField<int?>(
                              value: _selectedImportFileId,
                              labelText: 'Import File (ملف الشحنة الاستيرادية)',
                              items: [
                                const SearchableDropdownItem<int?>(
                                  value: null,
                                  label: '-- None / غير مرتبط بملف شحنة --',
                                ),
                                ...importFiles.map((f) => SearchableDropdownItem<int?>(
                                      value: f.importFileId,
                                      label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                    )),
                              ],
                              onChanged: (v) => setState(() => _selectedImportFileId = v),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _piCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Proforma Invoice # (رقم الفاتورة المبدئية)',
                                      hintText: 'e.g. PI-2026-991',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedOrderDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _selectedOrderDate = picked;
                                          _updateExchangeRateFromCurrency(_selectedCurrencyId, currencies);
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Invoice Date (تاريخ الفاتورة) *',
                                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.cobalt),
                                      ),
                                      child: Text(
                                        '${_selectedOrderDate.year}-${_selectedOrderDate.month.toString().padLeft(2, '0')}-${_selectedOrderDate.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedProjectId,
                                    labelText: 'Project *',
                                    items: projects
                                        .map((p) => SearchableDropdownItem<int?>(
                                              value: p.projectId,
                                              label: '${p.projectCode} (${p.projectName})',
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedProjectId = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedCompanyId,
                                    labelText: 'Importing Company *',
                                    items: companies
                                        .map((c) => SearchableDropdownItem<int?>(
                                              value: c.companyId,
                                              label: c.importerName,
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedCompanyId = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedSupplierId,
                                    labelText: 'Supplier *',
                                    items: suppliers
                                        .map((s) => SearchableDropdownItem<int?>(
                                              value: s.supplierId,
                                              label: s.companyName,
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedSupplierId = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedIncotermId,
                                    labelText: 'Incoterm *',
                                    items: incoterms
                                        .map((i) => SearchableDropdownItem<int?>(
                                              value: i.incotermId,
                                              label: '${i.incotermCode} (${i.incotermName})',
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedIncotermId = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedCurrencyId,
                                    labelText: 'Currency *',
                                    items: currencies
                                        .map((c) => SearchableDropdownItem<int?>(
                                              value: c.currencyId,
                                              label: '${c.currencyCode} (${c.currencyName})',
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedCurrencyId = v;
                                          _updateExchangeRateFromCurrency(v, currencies);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<String?>(
                                    value: _selectedCountryOfOrigin,
                                    labelText: 'Country of Origin (بلد المنشأ العام)',
                                    items: [
                                      const SearchableDropdownItem<String?>(
                                        value: null,
                                        label: '-- غير محدد (Auto / غير محدد) --',
                                      ),
                                      ...countryOptions.map((c) => SearchableDropdownItem<String?>(
                                            value: c['name'],
                                            label: c['name']!,
                                          )),
                                    ],
                                    onChanged: (v) => setState(() => _selectedCountryOfOrigin = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: _selectedStatus,
                                    labelText: 'Status',
                                    items: ['Draft', 'Approved', 'In Transit', 'Closed', 'Cancelled']
                                        .map((s) => SearchableDropdownItem<String>(value: s, label: s))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedStatus = v ?? 'Draft'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _rateCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Exchange Rate (سعر الصرف)',
                                      helperText: '⚡ يستدعى آلياً حسب تاريخ الفاتورة والعملة',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: ['Cash in Advance / SWIFT', 'Letter of Credit / LC', 'CAD / Cash Against Documents', 'Open Account / Deferred Payment'].contains(_selectedPaymentTerms)
                                        ? _selectedPaymentTerms
                                        : 'Cash in Advance / SWIFT',
                                    labelText: 'Payment Terms (شروط الدفع) *',
                                    items: const [
                                      SearchableDropdownItem(
                                        value: 'Cash in Advance / SWIFT',
                                        label: 'Cash in Advance / SWIFT (تحويل سويفت مقدم)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'Letter of Credit / LC',
                                        label: 'Letter of Credit / LC (اعتماد مستندي)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'CAD / Cash Against Documents',
                                        label: 'CAD / Cash Against Documents (تحصيل مستندي)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'Open Account / Deferred Payment',
                                        label: 'Open Account / Deferred Payment (حساب مفتوح / آجل)',
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _selectedPaymentTerms = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Line Items Header & Add Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PO Line Items (بنود الفاتورة المبدئية) *',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Item'),
                                  onPressed: () {
                                    setState(() {
                                      _dialogItems.add(
                                        POLineItemModel(
                                          descriptionAr: 'بند جديد ${_dialogItems.length + 1}',
                                          quantity: 1,
                                          unitPrice: 0,
                                          countryOfOrigin: _selectedCountryOfOrigin,
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Dynamic Line Items List
                            ..._dialogItems.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final itemHs = item.hsCode ?? (item.tariffId != null && tariffs.any((t) => t.tariffId == item.tariffId) ? tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsCode : '');
                              final isMismatched = itemHs.isNotEmpty && mismatchedHsCodes.contains(itemHs);

                              return Card(
                                color: isMismatched ? Colors.red.shade50.withOpacity(0.4) : Colors.grey.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isMismatched ? Colors.red.shade300 : Colors.grey.shade300,
                                    width: isMismatched ? 1.5 : 1.0,
                                  ),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              initialValue: item.itemCode,
                                              decoration: const InputDecoration(labelText: 'Item Code (كود البند)', isDense: true),
                                              onChanged: (v) => _dialogItems[idx] = _dialogItems[idx].copyWith(itemCode: v.trim().isEmpty ? null : v.trim()),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: TextFormField(
                                              initialValue: item.descriptionAr,
                                              decoration: const InputDecoration(labelText: 'Arabic Description *', isDense: true),
                                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                              onChanged: (v) => _dialogItems[idx] = _dialogItems[idx].copyWith(descriptionAr: v),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: InkWell(
                                              onTap: () async {
                                                final picked = await _showHsCodeSearchPicker(context, tariffs);
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(
                                                    tariffId: picked?.tariffId,
                                                    hsCode: picked?.hsCode,
                                                  );
                                                });
                                              },
                                              child: InputDecorator(
                                                decoration: InputDecoration(
                                                  labelText: 'Customs Tariff / HS Code (بحث 🔍)',
                                                  isDense: true,
                                                  suffixIcon: isMismatched ? const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16) : null,
                                                ),
                                                child: Text(
                                                  item.tariffId != null
                                                      ? (tariffs.any((t) => t.tariffId == item.tariffId)
                                                          ? '${tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsCode} - ${tariffs.firstWhere((t) => t.tariffId == item.tariffId).hsDescription}'
                                                          : (item.hsCode ?? 'ID #${item.tariffId}'))
                                                      : (item.hsCode != null && item.hsCode!.isNotEmpty ? item.hsCode! : 'None / General'),
                                                  style: TextStyle(
                                                    fontWeight: (item.tariffId != null || (item.hsCode != null && item.hsCode!.isNotEmpty)) ? FontWeight.bold : FontWeight.normal,
                                                    color: isMismatched ? Colors.red.shade900 : ((item.tariffId != null || (item.hsCode != null && item.hsCode!.isNotEmpty)) ? AppTheme.cobalt : Colors.grey.shade700),
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: SearchableDropdownField<String?>(
                                              value: item.countryOfOrigin ?? _selectedCountryOfOrigin,
                                              labelText: 'بلد المنشأ للبند',
                                              searchHintText: 'ابحث عن بلد المنشأ...',
                                              items: [
                                                const SearchableDropdownItem<String?>(value: null, label: '-- الافتراضي --'),
                                                ...countryOptions.map((c) => SearchableDropdownItem<String?>(
                                                      value: c['name'],
                                                      label: c['name']!,
                                                    )),
                                              ],
                                              onChanged: (v) {
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(countryOfOrigin: v);
                                                });
                                              },
                                            ),
                                          ),
                                          if (_dialogItems.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.crimson, size: 20),
                                              onPressed: () => setState(() => _dialogItems.removeAt(idx)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item.quantity.toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(labelText: 'Qty (العدد)', isDense: true),
                                              onChanged: (v) {
                                                final q = double.tryParse(v) ?? 1.0;
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(quantity: q);
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item.unitPrice.toString(),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(labelText: 'Unit Price (سعر الوحده)', isDense: true),
                                              onChanged: (v) {
                                                final p = double.tryParse(v) ?? 0.0;
                                                setState(() {
                                                  _dialogItems[idx] = _dialogItems[idx].copyWith(unitPrice: p);
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.green.shade300),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const Text('Line Total (إجمالي السطر)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                Text(
                                                  '${currencies.firstWhere((c) => c.currencyId == _selectedCurrencyId, orElse: () => CurrencyModel(currencyId: 0, currencyCode: 'USD', currencyName: 'USD', currencySymbol: '\$')).currencyCode} ${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'PO Notes & Instructions'),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: BP-003 Dynamic Detailed Packing List
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, right: 4),
                        child: SizedBox(
                          height: 480,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Packing List Entries (بيان التعبئة والطرود والأبعاد) *',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                  ),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.auto_fix_high, size: 16),
                                        label: const Text('تعبئة تلقائية من الفاتورة', style: TextStyle(fontSize: 12)),
                                        onPressed: () {
                                          if (_dialogItems.isEmpty) return;
                                          setState(() {
                                            _dialogPackingItems.clear();
                                            for (int i = 0; i < _dialogItems.length; i++) {
                                              final item = _dialogItems[i];
                                              String itemHsCode = '';
                                              if (item.hsCode != null && item.hsCode!.isNotEmpty) {
                                                itemHsCode = item.hsCode!;
                                              } else if (item.tariffId != null) {
                                                final matchingTariff = tariffs.cast<CustomsTariffModel?>().firstWhere(
                                                      (t) => t?.tariffId == item.tariffId,
                                                      orElse: () => null,
                                                    );
                                                if (matchingTariff != null && matchingTariff.hsCode.isNotEmpty) {
                                                  itemHsCode = matchingTariff.hsCode;
                                                }
                                              }
                                              _dialogPackingItems.add(
                                                PackingListItemModel(
                                                  hsCode: itemHsCode,
                                                  itemCode: item.itemCode ?? 'ITEM-${(i + 1).toString().padLeft(3, '0')}',
                                                  qtyPcs: item.quantity > 0 ? item.quantity : 100.0,
                                                  qtyPkg: (item.quantity > 0 ? (item.quantity / 10).ceilToDouble() : 10.0),
                                                  packageType: 'Carton',
                                                  lengthCm: 50.0,
                                                  widthCm: 40.0,
                                                  heightCm: 30.0,
                                                  netWeightUnitKg: item.netWeightKg > 0 ? item.netWeightKg : 5.0,
                                                  grossWeightUnitKg: item.grossWeightKg > 0 ? item.grossWeightKg : 6.0,
                                                ),
                                              );
                                            }
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تمت التعبئة التلقائية لـ ${_dialogPackingItems.length} طرود من بنود الفاتورة المبدئية!'),
                                              backgroundColor: AppTheme.emerald,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.view_in_ar_rounded, size: 16),
                                        label: const Text('محاكاة ورص الحاويات 3D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showPoVisualLoadPlannerDialog(context, _dialogPackingItems),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.playlist_add, size: 18, color: AppTheme.emerald),
                                        label: const Text('Add Packing Entry', style: TextStyle(color: AppTheme.emerald)),
                                        onPressed: () {
                                          String defaultHs = '';
                                          if (_dialogItems.isNotEmpty) {
                                            final first = _dialogItems.first;
                                            if (first.hsCode != null && first.hsCode!.isNotEmpty) {
                                              defaultHs = first.hsCode!;
                                            } else if (first.tariffId != null) {
                                              final match = tariffs.cast<CustomsTariffModel?>().firstWhere((t) => t?.tariffId == first.tariffId, orElse: () => null);
                                              if (match != null) defaultHs = match.hsCode;
                                            }
                                          }
                                          setState(() {
                                            _dialogPackingItems.add(
                                              PackingListItemModel(
                                                hsCode: defaultHs,
                                                itemCode: 'ITEM-00${_dialogPackingItems.length + 1}',
                                                qtyPcs: 10,
                                                qtyPkg: 1,
                                                packageType: 'Carton',
                                                lengthCm: 50,
                                                widthCm: 40,
                                                heightCm: 30,
                                                netWeightUnitKg: 5,
                                                grossWeightUnitKg: 6,
                                              ),
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Expanded(
                                child: _dialogPackingItems.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'لم يتم إضافة بنود تعبئة بعد',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'انقر فوق "تعبئة تلقائية من الفاتورة" لإنشاء قائمة التعبئة آلياً أو "Add Packing Entry"',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _dialogPackingItems.length,
                                        itemBuilder: (context, idx) {
                                          final p = _dialogPackingItems[idx];
                                          final isMismatched = p.hsCode.isNotEmpty && mismatchedHsCodes.contains(p.hsCode);

                                          return Card(
                                            key: ValueKey('packing_card_${idx}_${p.itemCode}'),
                                            color: isMismatched ? Colors.red.shade50.withOpacity(0.4) : Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: isMismatched ? Colors.red.shade400 : Colors.blue.shade200,
                                                width: isMismatched ? 1.5 : 1.0,
                                              ),
                                            ),
                                            margin: const EdgeInsets.only(bottom: 10),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                       Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                         decoration: BoxDecoration(
                                                           color: isMismatched ? Colors.red.withOpacity(0.15) : AppTheme.cobalt.withOpacity(0.15),
                                                           borderRadius: BorderRadius.circular(4),
                                                         ),
                                                         child: Text(
                                                           'Pkg #${idx + 1}',
                                                           style: TextStyle(
                                                             fontWeight: FontWeight.bold,
                                                             color: isMismatched ? Colors.red.shade900 : AppTheme.cobalt,
                                                             fontSize: 12,
                                                           ),
                                                         ),
                                                       ),
                                                       const SizedBox(width: 8),
                                                       Expanded(
                                                         child: InkWell(
                                                           onTap: () async {
                                                             final picked = await _showHsCodeSearchPicker(context, tariffs);
                                                             if (picked != null) {
                                                               setState(() {
                                                                 _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(hsCode: picked.hsCode);
                                                               });
                                                             }
                                                           },
                                                           child: InputDecorator(
                                                             decoration: InputDecoration(
                                                               labelText: 'HS Code (بحث 🔍) *',
                                                               isDense: true,
                                                               suffixIcon: isMismatched ? const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16) : null,
                                                             ),
                                                             child: Text(
                                                               p.hsCode.isNotEmpty ? p.hsCode : 'اختر بند جمركي',
                                                               style: TextStyle(
                                                                 fontWeight: p.hsCode.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                                                 color: isMismatched ? Colors.red.shade900 : (p.hsCode.isNotEmpty ? AppTheme.cobalt : Colors.grey.shade600),
                                                                 fontSize: 12,
                                                               ),
                                                               overflow: TextOverflow.ellipsis,
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.itemCode,
                                                      decoration: const InputDecoration(labelText: 'Item Code *', isDense: true),
                                                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                                      onChanged: (v) {
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(itemCode: v.trim());
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SearchableDropdownField<String>(
                                                      value: p.packageType,
                                                      labelText: 'Package Type',
                                                      items: ['Carton', 'Pallet', 'Bag', 'Wooden Crate', 'Drum', 'Container']
                                                          .map((t) => SearchableDropdownItem(value: t, label: t))
                                                          .toList(),
                                                      onChanged: (v) => setState(() {
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(packageType: v ?? 'Carton');
                                                      }),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.crimson, size: 20),
                                                    onPressed: () => setState(() => _dialogPackingItems.removeAt(idx)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: SearchableDropdownField<String>(
                                                      value: p.unit,
                                                      labelText: 'Unit',
                                                      items: const [
                                                        SearchableDropdownItem(value: 'cm', label: 'cm'),
                                                        SearchableDropdownItem(value: 'mm', label: 'mm'),
                                                        SearchableDropdownItem(value: 'm', label: 'm'),
                                                      ],
                                                      onChanged: (v) => setState(() {
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(unit: v ?? 'cm');
                                                      }),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.qtyPcs.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Qty PCS', isDense: true),
                                                      onChanged: (v) {
                                                        final q = double.tryParse(v) ?? 1.0;
                                                        _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(qtyPcs: q);
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.qtyPkg.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Qty PKG (طرود)', isDense: true),
                                                      onChanged: (v) {
                                                        final q = double.tryParse(v) ?? 1.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(qtyPkg: q);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.lengthCm.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: InputDecoration(labelText: 'Length (${p.unit})', isDense: true),
                                                      onChanged: (v) {
                                                        final l = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(lengthCm: l);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.widthCm.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: InputDecoration(labelText: 'Width (${p.unit})', isDense: true),
                                                      onChanged: (v) {
                                                        final w = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(widthCm: w);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.heightCm.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: InputDecoration(labelText: 'Height (${p.unit})', isDense: true),
                                                      onChanged: (v) {
                                                        final h = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(heightCm: h);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.netWeightUnitKg.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Net Wt/Unit (kg)', isDense: true),
                                                      onChanged: (v) {
                                                        final nw = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = _dialogPackingItems[idx].copyWith(netWeightUnitKg: nw);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: p.grossWeightUnitKg.toString(),
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      decoration: const InputDecoration(labelText: 'Gross Wt/Unit (kg)', isDense: true),
                                                      onChanged: (v) {
                                                        final gw = double.tryParse(v) ?? 0.0;
                                                        setState(() {
                                                          _dialogPackingItems[idx] = p.copyWith(grossWeightUnitKg: gw);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: SearchableDropdownField<bool>(
                                                      value: p.isStackable,
                                                      labelText: 'تعليمات الرص *',
                                                      items: const [
                                                        SearchableDropdownItem(value: true, label: '📦 قابل للرص'),
                                                        SearchableDropdownItem(value: false, label: '🚫 غير قابل للرص'),
                                                      ],
                                                      onChanged: (v) => setState(() {
                                                        _dialogPackingItems[idx] = p.copyWith(isStackable: v ?? true);
                                                      }),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Colors.blue.shade200),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                        children: [
                                                          Column(
                                                            children: [
                                                              const Text('Total Volume', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                              Text('${p.calculatedCbm.toStringAsFixed(4)} m³', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              const Text('Total Gross Wt', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                              Text('${(p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg)).toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              const Text('Air Chargeable', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                              Text('${(p.calculatedCbm * 166.67).toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                      ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            onPressed: (_isSubmitting || isLoadingMaster)
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء استكمال الحقول الإلزامية (الوصف العربي، HS Code، كود البند) بجميع التبويبات.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_selectedProjectId == null ||
                        _selectedCompanyId == null ||
                        _selectedSupplierId == null ||
                        _selectedIncotermId == null ||
                        _selectedCurrencyId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء التأكد من اختيار كافة الحقول الإلزامية (المشروع، الشركة المستوردة، المورد، الـ Incoterm والعملة).'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_dialogItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء إضافة بند استيرادي واحد على الأقل في أمر الشراء.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final tariffs = ref.read(customsTariffProvider).value ?? [];
                    final reconciliation = _evaluateReconciliation(
                      invoiceItems: _dialogItems,
                      packingItems: _dialogPackingItems,
                      tariffs: tariffs,
                    );

                    String? discrepancyJustification;
                    if (reconciliation.hasDiscrepancy) {
                      discrepancyJustification = await showDialog<String?>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => _ReconciliationWarningDialog(report: reconciliation),
                      );

                      // User chose "الرجوع للتعديل" (Back to Edit)
                      if (discrepancyJustification == null || !mounted) {
                        return;
                      }
                    }

                    if (!mounted) return;
                    setState(() => _isSubmitting = true);
                    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 1.0;

                    // Build final notes with justification if provided
                    String? effectiveNotes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
                    if (discrepancyJustification != null && discrepancyJustification.isNotEmpty) {
                      final header = '[مبررات اختلاف الفاتورة والباكينج]: $discrepancyJustification';
                      effectiveNotes = effectiveNotes == null ? header : '$effectiveNotes\n$header';
                    }

                    if (widget.po == null) {
                      final newPO = PurchaseOrderModel(
                        poNumber: '',
                        proformaInvoiceNumber: _piCtrl.text.trim().isEmpty ? null : _piCtrl.text.trim(),
                        countryOfOrigin: _selectedCountryOfOrigin,
                        importFileId: _selectedImportFileId,
                        projectId: _selectedProjectId!,
                        companyId: _selectedCompanyId!,
                        supplierId: _selectedSupplierId!,
                        incotermId: _selectedIncotermId!,
                        currencyId: _selectedCurrencyId!,
                        orderDate: _selectedOrderDate,
                        exchangeRate: rate,
                        paymentTerms: _selectedPaymentTerms,
                        status: _selectedStatus,
                        notes: effectiveNotes,
                        items: _dialogItems,
                        packingListItems: _dialogPackingItems,
                      );
                      final errorMsg = await ref.read(purchaseOrdersProvider.notifier).createPurchaseOrder(newPO);
                      if (errorMsg != null) {
                        setState(() => _isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ في إدخال أمر الشراء:\n$errorMsg'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('تم إنشاء أمر الشراء بنجاح!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    } else {
                      final oldPO = widget.po!;
                      final List<FieldChangeItem> changes = [];

                      // 1. Header changes
                      final newPi = _piCtrl.text.trim().isEmpty ? null : _piCtrl.text.trim();
                      if (FieldChangeItem.isDifferent(oldPO.proformaInvoiceNumber, newPi)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'رقم الفاتورة المبدئية (PI Number)',
                          oldValue: oldPO.proformaInvoiceNumber,
                          newValue: newPi,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.countryOfOrigin, _selectedCountryOfOrigin)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'بلد المنشأ (Country of Origin)',
                          oldValue: oldPO.countryOfOrigin,
                          newValue: _selectedCountryOfOrigin,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.projectId, _selectedProjectId)) {
                        final oldProj = projects.where((p) => p.projectId == oldPO.projectId).firstOrNull?.projectName ?? '${oldPO.projectId}';
                        final newProj = projects.where((p) => p.projectId == _selectedProjectId).firstOrNull?.projectName ?? '$_selectedProjectId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'المشروع الاستيرادي',
                          oldValue: oldProj,
                          newValue: newProj,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.companyId, _selectedCompanyId)) {
                        final oldComp = companies.where((c) => c.companyId == oldPO.companyId).firstOrNull?.importerName ?? '${oldPO.companyId}';
                        final newComp = companies.where((c) => c.companyId == _selectedCompanyId).firstOrNull?.importerName ?? '$_selectedCompanyId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'الشركة المستوردة',
                          oldValue: oldComp,
                          newValue: newComp,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.supplierId, _selectedSupplierId)) {
                        final oldSupp = suppliers.where((s) => s.supplierId == oldPO.supplierId).firstOrNull?.companyName ?? '${oldPO.supplierId}';
                        final newSupp = suppliers.where((s) => s.supplierId == _selectedSupplierId).firstOrNull?.companyName ?? '$_selectedSupplierId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'المورد الأجنبي',
                          oldValue: oldSupp,
                          newValue: newSupp,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.incotermId, _selectedIncotermId)) {
                        final oldInco = incoterms.where((i) => i.incotermId == oldPO.incotermId).firstOrNull?.incotermCode ?? '${oldPO.incotermId}';
                        final newInco = incoterms.where((i) => i.incotermId == _selectedIncotermId).firstOrNull?.incotermCode ?? '$_selectedIncotermId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'شرط الشحن (Incoterm)',
                          oldValue: oldInco,
                          newValue: newInco,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.currencyId, _selectedCurrencyId)) {
                        final oldCurr = currencies.where((c) => c.currencyId == oldPO.currencyId).firstOrNull?.currencyCode ?? '${oldPO.currencyId}';
                        final newCurr = currencies.where((c) => c.currencyId == _selectedCurrencyId).firstOrNull?.currencyCode ?? '$_selectedCurrencyId';
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'عملة أمر الشراء',
                          oldValue: oldCurr,
                          newValue: newCurr,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.exchangeRate, rate)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'سعر الصرف',
                          oldValue: oldPO.exchangeRate,
                          newValue: rate,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.paymentTerms, _selectedPaymentTerms)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'شروط السداد والدفع',
                          oldValue: oldPO.paymentTerms,
                          newValue: _selectedPaymentTerms,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.status, _selectedStatus)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'حالة أمر الشراء',
                          oldValue: oldPO.status,
                          newValue: _selectedStatus,
                        ));
                      }

                      if (FieldChangeItem.isDifferent(oldPO.notes, effectiveNotes)) {
                        changes.add(FieldChangeItem(
                          section: 'بيانات الفاتورة المبدئية والترويسة',
                          fieldName: 'الملاحظات',
                          oldValue: oldPO.notes,
                          newValue: effectiveNotes,
                        ));
                      }

                      // 2. Line Items
                      if (oldPO.items.length != _dialogItems.length) {
                        changes.add(FieldChangeItem(
                          section: 'بنود الفاتورة المبدئية',
                          fieldName: 'عدد بنود الفاتورة',
                          oldValue: '${oldPO.items.length} بند',
                          newValue: '${_dialogItems.length} بند',
                        ));
                      } else {
                        for (int i = 0; i < _dialogItems.length; i++) {
                          final o = oldPO.items[i];
                          final n = _dialogItems[i];
                          if (FieldChangeItem.isDifferent(o.descriptionAr, n.descriptionAr)) {
                            changes.add(FieldChangeItem(
                              section: 'بنود الفاتورة المبدئية',
                              fieldName: 'بند #${i + 1} - الوصف العربي',
                              oldValue: o.descriptionAr,
                              newValue: n.descriptionAr,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.quantity, n.quantity)) {
                            changes.add(FieldChangeItem(
                              section: 'بنود الفاتورة المبدئية',
                              fieldName: 'بند #${i + 1} (${n.itemCode ?? ""}) - الكمية',
                              oldValue: o.quantity,
                              newValue: n.quantity,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.unitPrice, n.unitPrice)) {
                            changes.add(FieldChangeItem(
                              section: 'بنود الفاتورة المبدئية',
                              fieldName: 'بند #${i + 1} (${n.itemCode ?? ""}) - سعر الوحدة',
                              oldValue: o.unitPrice,
                              newValue: n.unitPrice,
                            ));
                          }
                        }
                      }

                      // 3. Packing List Items
                      if (oldPO.packingListItems.length != _dialogPackingItems.length) {
                        changes.add(FieldChangeItem(
                          section: 'قائمة التعبئة (Packing List)',
                          fieldName: 'عدد طرود قائمة التعبئة',
                          oldValue: '${oldPO.packingListItems.length} طرد',
                          newValue: '${_dialogPackingItems.length} طرد',
                        ));
                      } else {
                        for (int i = 0; i < _dialogPackingItems.length; i++) {
                          final o = oldPO.packingListItems[i];
                          final n = _dialogPackingItems[i];
                          if (FieldChangeItem.isDifferent(o.itemCode, n.itemCode)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} - كود البند',
                              oldValue: o.itemCode,
                              newValue: n.itemCode,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.packageType, n.packageType)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - نوع الطرد',
                              oldValue: o.packageType,
                              newValue: n.packageType,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.qtyPkg, n.qtyPkg)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - عدد الطرود',
                              oldValue: o.qtyPkg,
                              newValue: n.qtyPkg,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.grossWeightUnitKg, n.grossWeightUnitKg)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - وزن الطرد (kg)',
                              oldValue: o.grossWeightUnitKg,
                              newValue: n.grossWeightUnitKg,
                            ));
                          }
                          if (FieldChangeItem.isDifferent(o.isStackable, n.isStackable)) {
                            changes.add(FieldChangeItem(
                              section: 'قائمة التعبئة (Packing List)',
                              fieldName: 'طرد #${i + 1} (${n.itemCode}) - تعليمات الرص',
                              oldValue: o.isStackable ? '📦 قابل للرص' : '🚫 غير قابل للرص',
                              newValue: n.isStackable ? '📦 قابل للرص' : '🚫 غير قابل للرص',
                            ));
                          }
                        }
                      }

                      if (changes.isNotEmpty) {
                        if (!context.mounted) return;
                        final confirmed = await showChangeDiffConfirmationDialog(
                          context,
                          title: 'مراجعة وتأكيد تعديلات أمر الشراء',
                          itemReference: oldPO.poNumber,
                          changes: changes,
                        );
                        if (!confirmed) {
                          if (mounted) setState(() => _isSubmitting = false);
                          return;
                        }
                      }

                      final updateData = {
                        'proforma_invoice_number': _piCtrl.text.trim().isEmpty ? null : _piCtrl.text.trim(),
                        'country_of_origin': _selectedCountryOfOrigin,
                        'import_file_id': _selectedImportFileId,
                        'project_id': _selectedProjectId!,
                        'company_id': _selectedCompanyId!,
                        'supplier_id': _selectedSupplierId!,
                        'incoterm_id': _selectedIncotermId!,
                        'currency_id': _selectedCurrencyId!,
                        'order_date': _selectedOrderDate.toIso8601String(),
                        'exchange_rate': rate,
                        'payment_terms': _selectedPaymentTerms,
                        'status': _selectedStatus,
                        'notes': effectiveNotes,
                        'items': _dialogItems.map((i) => i.toJson()).toList(),
                        'packing_list_items': _dialogPackingItems.map((i) => i.toJson()).toList(),
                      };
                      final errorMsg = await ref.read(purchaseOrdersProvider.notifier).updatePurchaseOrder(widget.po!.poId!, updateData);
                      if (errorMsg != null) {
                        setState(() => _isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ في تحديث أمر الشراء:\n$errorMsg'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ التعديلات بنجاح!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(widget.po == null ? 'Create PO' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showPoVisualLoadPlannerDialog(BuildContext context, List<PackingListItemModel> packingItems) {
    if (packingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة بنود تعبئة أولاً في قائمة التعبئة لمعاينة رص الحاويات.')),
      );
      return;
    }

    final cargoItems = packingItems.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final p = entry.value;
      final lCm = p.unit == 'mm' ? p.lengthCm / 10.0 : (p.unit == 'm' ? p.lengthCm * 100.0 : p.lengthCm);
      final wCm = p.unit == 'mm' ? p.widthCm / 10.0 : (p.unit == 'm' ? p.widthCm * 100.0 : p.widthCm);
      final hCm = p.unit == 'mm' ? p.heightCm / 10.0 : (p.unit == 'm' ? p.heightCm * 100.0 : p.heightCm);
      final grossWt = p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg);

      return CargoItem(
        itemId: '$idx',
        length: lCm > 0 ? lCm : 100.0,
        width: wCm > 0 ? wCm : 80.0,
        height: hCm > 0 ? hCm : 60.0,
        weight: grossWt > 0 ? grossWt : 10.0,
        isStackable: p.isStackable,
        rotate: true,
        packageType: p.packageType,
        description: p.itemCode,
      );
    }).toList();

    final plan = ContainerRequirementEngine.planShipment(cargoItems);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: 1100,
            height: 700,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.view_in_ar_rounded, color: AppTheme.cobalt, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'مخطط ومحاكاة رص الحاويات 3D (Purchase Order Load Planner)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogCtx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: plan.length,
                    itemBuilder: (ctx, pIdx) {
                      final res = plan[pIdx];
                      if (res.containerCode == 'FAILED') {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  res.failureReason ?? 'فشل الرص: تجاوز أبعاد الطرد أو الوزن الأبعاد القياسية المسموح بها داخل الحاوية',
                                  style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
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
                              Text(
                                "حاوية #${pIdx + 1}: ${res.spec.code} — (${res.placedItems.length} طرد) — استغلال المساحة: ${(res.totalVolume / res.spec.internalVolumeCbm * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 380,
                                child: CustomPaint(
                                  size: const Size(double.infinity, 380),
                                  painter: ContainerLoadPlanPainter(
                                    plan: res,
                                    isTopView: true,
                                  ),
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
        );
      },
    );
  }
}
