import '../widgets/po_form_dialog.dart';
import '../widgets/po_reconciliation_warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';

import '../../currencies/providers/currencies_provider.dart';
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
                                          Padding(padding: const EdgeInsets.all(6), child: Text(((p.netWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.netWeightUnitKg) : p.totalNetWeightKg).toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                                          Padding(padding: const EdgeInsets.all(6), child: Text(((p.grossWeightUnitKg > 0 && p.qtyPkg > 0) ? (p.qtyPkg * p.grossWeightUnitKg) : p.totalGrossWeightKg).toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
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
      builder: (dialogCtx) => POFormDialog(po: po, initialExtractedFields: initialExtractedFields),
    );
  }
}

// ==================================================
// PO & Packing List Reconciliation Helper & Dialog
// ==================================================
