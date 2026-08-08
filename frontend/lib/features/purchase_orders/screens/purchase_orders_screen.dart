import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Orders & Proforma Invoices (أوامر الشراء والفواتير المبدئية)',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'المرحلة الأولى: إدارة وتسجيل أوامر الشراء، الفواتير المبدئية، وحساب الـ CBM والأوزان الإجمالية',
                      style: TextStyle(color: AppTheme.cloudWhite, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                _buildSummaryMetric('Total FOB Value', '\$${totalFobSum.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                const SizedBox(width: 12),
                _buildSummaryMetric('Total Cargo CBM', '${totalCbmSum.toStringAsFixed(2)} CBM', Icons.view_in_ar, Colors.orange),
                const SizedBox(width: 12),
                _buildSummaryMetric('Total Gross Weight', '${totalGrossSum.toStringAsFixed(1)} KG', Icons.scale, Colors.purple),
              ],
            ),
          ),

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
                      child: DropdownButtonFormField<int?>(
                        value: state.projectFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Project',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Projects')),
                          ...projectsList.map((p) => DropdownMenuItem<int?>(
                                value: p.projectId,
                                child: Text('${p.projectCode} - ${p.projectName}', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => ref.read(purchaseOrdersProvider.notifier).setProjectFilter(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: state.statusFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('All Statuses')),
                          DropdownMenuItem<String?>(value: 'Draft', child: Text('Draft')),
                          DropdownMenuItem<String?>(value: 'Approved', child: Text('Approved')),
                          DropdownMenuItem<String?>(value: 'In Transit', child: Text('In Transit')),
                          DropdownMenuItem<String?>(value: 'Closed', child: Text('Closed')),
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
                DataColumn(label: Text('PI Number')),
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('Company')),
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('FOB Amount')),
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

                return DataRow(
                  cells: [
                    DataCell(
                      Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                    ),
                    DataCell(Text(po.proformaInvoiceNumber ?? '-')),
                    DataCell(Text(po.projectName ?? 'PRJ-#${po.projectId}')),
                    DataCell(Text(po.companyName ?? 'COMP-#${po.companyId}')),
                    DataCell(Text(po.supplierName ?? 'SUP-#${po.supplierId}')),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.list_alt, color: AppTheme.cobalt, size: 20),
                            tooltip: 'View Items Details',
                            onPressed: () => _showPODetailsDialog(context, po),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.orange, size: 20),
                            tooltip: 'Edit PO',
                            onPressed: () => _showPODialog(context, po),
                          ),
                          IconButton(
                            icon: Icon(
                              po.isActive ? Icons.delete_outline : Icons.restore,
                              color: po.isActive ? AppTheme.crimson : AppTheme.emerald,
                              size: 20,
                            ),
                            tooltip: po.isActive ? 'Deactivate' : 'Restore',
                            onPressed: () async {
                              if (po.isActive) {
                                await ref.read(purchaseOrdersProvider.notifier).deletePurchaseOrder(po.poId!);
                              } else {
                                await ref.read(purchaseOrdersProvider.notifier).restorePurchaseOrder(po.poId!);
                              }
                            },
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
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text('PO Details: ${po.poNumber} (${po.proformaInvoiceNumber ?? "No PI"})'),
          ],
        ),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _buildDetailItem('Project', po.projectName ?? '-'),
                    _buildDetailItem('Company', po.companyName ?? '-'),
                    _buildDetailItem('Supplier', po.supplierName ?? '-'),
                    _buildDetailItem('Incoterm', po.incotermCode ?? '-'),
                    _buildDetailItem('Currency & Rate', '${po.currencyCode ?? "USD"} (Exchange: ${po.exchangeRate})'),
                    _buildDetailItem('Payment Terms', po.paymentTerms ?? '-'),
                    _buildDetailItem('Total FOB Value', '\$${po.totalAmountFob.toStringAsFixed(2)}'),
                    _buildDetailItem('Total Volume', '${po.totalCbm.toStringAsFixed(3)} CBM'),
                    _buildDetailItem('Gross / Net Weight', '${po.totalGrossWeightKg} kg / ${po.totalNetWeightKg} kg'),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Purchase Order Line Items (بنود أمر الشراء والجداول الجمركية)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.2),
                    4: FlexColumnWidth(1.2),
                    5: FlexColumnWidth(1.2),
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
                        Padding(padding: EdgeInsets.all(6), child: Text('Volume CBM', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...po.items.map(
                      (item) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text(item.itemCode ?? '-')),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.descriptionAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (item.hsCode != null)
                                  Text(
                                    'HS: ${item.hsCode} (Duty: ${item.dutyRate ?? 0}% / VAT: ${item.vatRate ?? 0}%)',
                                    style: const TextStyle(color: AppTheme.cobalt, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${item.quantity} ${item.unitOfMeasure}')),
                          Padding(padding: const EdgeInsets.all(6), child: Text('\$${item.unitPrice.toStringAsFixed(2)}')),
                          Padding(padding: const EdgeInsets.all(6), child: Text('\$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${item.totalCbm.toStringAsFixed(3)} m³')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
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

  void _showPODialog(BuildContext context, PurchaseOrderModel? po) {
    final projects = ref.read(projectsProvider).value ?? [];
    final companies = ref.read(importCompaniesProvider).value ?? [];
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final incoterms = ref.read(incotermsProvider).value ?? [];
    final currencies = ref.read(currenciesProvider).value ?? [];
    final tariffs = ref.read(customsTariffProvider).value ?? [];

    if (projects.isEmpty || companies.isEmpty || suppliers.isEmpty || incoterms.isEmpty || currencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure Projects, Companies, Suppliers, Incoterms, and Currencies are loaded.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final piCtrl = TextEditingController(text: po?.proformaInvoiceNumber ?? '');
    final rateCtrl = TextEditingController(text: (po?.exchangeRate ?? 1.0).toString());
    final termsCtrl = TextEditingController(text: po?.paymentTerms ?? 'LC at Sight / اعتماد مستندي');
    final notesCtrl = TextEditingController(text: po?.notes ?? '');

    int selectedProjectId = po?.projectId ?? projects.first.projectId ?? 1;
    int selectedCompanyId = po?.companyId ?? companies.first.companyId ?? 1;
    int selectedSupplierId = po?.supplierId ?? suppliers.first.supplierId ?? 1;
    int selectedIncotermId = po?.incotermId ?? incoterms.first.incotermId;
    int selectedCurrencyId = po?.currencyId ?? currencies.first.currencyId ?? 1;
    String selectedStatus = po?.status ?? 'Draft';

    final List<POLineItemModel> dialogItems = po != null && po.items.isNotEmpty
        ? po.items.map((i) => POLineItemModel(
            itemCode: i.itemCode,
            descriptionAr: i.descriptionAr,
            descriptionEn: i.descriptionEn,
            tariffId: i.tariffId,
            quantity: i.quantity,
            unitOfMeasure: i.unitOfMeasure,
            unitPrice: i.unitPrice,
            cbmPerUnit: i.cbmPerUnit,
            grossWeightKg: i.grossWeightKg,
            netWeightKg: i.netWeightKg,
          )).toList()
        : [
            POLineItemModel(
              descriptionAr: 'بند استيرادي رئيسي 1',
              quantity: 100,
              unitPrice: 10,
              cbmPerUnit: 0.1,
            )
          ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(po == null ? 'Create New Purchase Order (أمر شراء جديد)' : 'Edit Purchase Order (${po.poNumber})'),
          content: SizedBox(
            width: 750,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: piCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Proforma Invoice # (رقم الفاتورة المبدئية)',
                              hintText: 'e.g. PI-2026-991',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedProjectId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Project *'),
                            items: projects
                                .map((p) => DropdownMenuItem(
                                      value: p.projectId,
                                      child: Text('${p.projectCode} (${p.projectName})', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedProjectId = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedCompanyId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Importing Company *'),
                            items: companies
                                .map((c) => DropdownMenuItem(
                                      value: c.companyId,
                                      child: Text(c.importerName, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedCompanyId = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedSupplierId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Supplier *'),
                            items: suppliers
                                .map((s) => DropdownMenuItem(
                                      value: s.supplierId,
                                      child: Text(s.companyName, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedSupplierId = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedIncotermId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Incoterm *'),
                            items: incoterms
                                .map((i) => DropdownMenuItem(
                                      value: i.incotermId,
                                      child: Text('${i.incotermCode} (${i.incotermName})', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedIncotermId = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedCurrencyId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Currency *'),
                            items: currencies
                                .map((c) => DropdownMenuItem(
                                      value: c.currencyId,
                                      child: Text('${c.currencyCode} (${c.currencyName})', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedCurrencyId = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Exchange Rate'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: ['Draft', 'Approved', 'In Transit', 'Closed', 'Cancelled']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => selectedStatus = v ?? 'Draft'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: termsCtrl,
                      decoration: const InputDecoration(labelText: 'Payment Terms'),
                    ),
                    const SizedBox(height: 14),

                    // Line Items Header & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PO Line Items (بنود أمر الشراء والـ HS Codes) *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Item'),
                          onPressed: () {
                            setDialogState(() {
                              dialogItems.add(
                                POLineItemModel(
                                  descriptionAr: 'بند جديد ${dialogItems.length + 1}',
                                  quantity: 1,
                                  unitPrice: 0,
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dynamic Line Items List
                    ...dialogItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      return Card(
                        color: Colors.grey.shade50,
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
                                      initialValue: item.descriptionAr,
                                      decoration: const InputDecoration(labelText: 'Arabic Description *', isDense: true),
                                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                      onChanged: (v) => dialogItems[idx] = POLineItemModel(
                                        itemCode: item.itemCode,
                                        descriptionAr: v,
                                        descriptionEn: item.descriptionEn,
                                        tariffId: item.tariffId,
                                        quantity: item.quantity,
                                        unitOfMeasure: item.unitOfMeasure,
                                        unitPrice: item.unitPrice,
                                        cbmPerUnit: item.cbmPerUnit,
                                        grossWeightKg: item.grossWeightKg,
                                        netWeightKg: item.netWeightKg,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int?>(
                                      value: item.tariffId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Customs Tariff / HS Code', isDense: true),
                                      items: [
                                        const DropdownMenuItem<int?>(value: null, child: Text('None / General')),
                                        ...tariffs.map((t) => DropdownMenuItem<int?>(
                                              value: t.tariffId,
                                              child: Text('${t.hsCode} (${t.hsDescription})', overflow: TextOverflow.ellipsis),
                                            )),
                                      ],
                                      onChanged: (v) => setDialogState(() {
                                        dialogItems[idx] = POLineItemModel(
                                          itemCode: item.itemCode,
                                          descriptionAr: item.descriptionAr,
                                          descriptionEn: item.descriptionEn,
                                          tariffId: v,
                                          quantity: item.quantity,
                                          unitOfMeasure: item.unitOfMeasure,
                                          unitPrice: item.unitPrice,
                                          cbmPerUnit: item.cbmPerUnit,
                                          grossWeightKg: item.grossWeightKg,
                                          netWeightKg: item.netWeightKg,
                                        );
                                      }),
                                    ),
                                  ),
                                  if (dialogItems.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.crimson, size: 20),
                                      onPressed: () => setDialogState(() => dialogItems.removeAt(idx)),
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
                                      decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                      onChanged: (v) {
                                        final q = double.tryParse(v) ?? 1.0;
                                        dialogItems[idx] = POLineItemModel(
                                          itemCode: item.itemCode,
                                          descriptionAr: item.descriptionAr,
                                          descriptionEn: item.descriptionEn,
                                          tariffId: item.tariffId,
                                          quantity: q,
                                          unitOfMeasure: item.unitOfMeasure,
                                          unitPrice: item.unitPrice,
                                          cbmPerUnit: item.cbmPerUnit,
                                          grossWeightKg: item.grossWeightKg,
                                          netWeightKg: item.netWeightKg,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.unitPrice.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Unit Price', isDense: true),
                                      onChanged: (v) {
                                        final p = double.tryParse(v) ?? 0.0;
                                        dialogItems[idx] = POLineItemModel(
                                          itemCode: item.itemCode,
                                          descriptionAr: item.descriptionAr,
                                          descriptionEn: item.descriptionEn,
                                          tariffId: item.tariffId,
                                          quantity: item.quantity,
                                          unitOfMeasure: item.unitOfMeasure,
                                          unitPrice: p,
                                          cbmPerUnit: item.cbmPerUnit,
                                          grossWeightKg: item.grossWeightKg,
                                          netWeightKg: item.netWeightKg,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.cbmPerUnit.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'CBM / Unit', isDense: true),
                                      onChanged: (v) {
                                        final cbm = double.tryParse(v) ?? 0.0;
                                        dialogItems[idx] = POLineItemModel(
                                          itemCode: item.itemCode,
                                          descriptionAr: item.descriptionAr,
                                          descriptionEn: item.descriptionEn,
                                          tariffId: item.tariffId,
                                          quantity: item.quantity,
                                          unitOfMeasure: item.unitOfMeasure,
                                          unitPrice: item.unitPrice,
                                          cbmPerUnit: cbm,
                                          grossWeightKg: item.grossWeightKg,
                                          netWeightKg: item.netWeightKg,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.grossWeightKg.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Gross Wt (kg)', isDense: true),
                                      onChanged: (v) {
                                        final gw = double.tryParse(v) ?? 0.0;
                                        dialogItems[idx] = POLineItemModel(
                                          itemCode: item.itemCode,
                                          descriptionAr: item.descriptionAr,
                                          descriptionEn: item.descriptionEn,
                                          tariffId: item.tariffId,
                                          quantity: item.quantity,
                                          unitOfMeasure: item.unitOfMeasure,
                                          unitPrice: item.unitPrice,
                                          cbmPerUnit: item.cbmPerUnit,
                                          grossWeightKg: gw,
                                          netWeightKg: item.netWeightKg,
                                        );
                                      },
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
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'PO Notes & Instructions'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (dialogItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least one line item.')),
                    );
                    return;
                  }

                  final rate = double.tryParse(rateCtrl.text.trim()) ?? 1.0;

                  if (po == null) {
                    final newPO = PurchaseOrderModel(
                      poNumber: '',
                      proformaInvoiceNumber: piCtrl.text.trim().isEmpty ? null : piCtrl.text.trim(),
                      projectId: selectedProjectId,
                      companyId: selectedCompanyId,
                      supplierId: selectedSupplierId,
                      incotermId: selectedIncotermId,
                      currencyId: selectedCurrencyId,
                      exchangeRate: rate,
                      paymentTerms: termsCtrl.text.trim().isEmpty ? null : termsCtrl.text.trim(),
                      status: selectedStatus,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      items: dialogItems,
                    );
                    final ok = await ref.read(purchaseOrdersProvider.notifier).createPurchaseOrder(newPO);
                    if (ok && context.mounted) Navigator.pop(dialogCtx);
                  } else {
                    final updateData = {
                      'proforma_invoice_number': piCtrl.text.trim().isEmpty ? null : piCtrl.text.trim(),
                      'project_id': selectedProjectId,
                      'company_id': selectedCompanyId,
                      'supplier_id': selectedSupplierId,
                      'incoterm_id': selectedIncotermId,
                      'currency_id': selectedCurrencyId,
                      'exchange_rate': rate,
                      'payment_terms': termsCtrl.text.trim().isEmpty ? null : termsCtrl.text.trim(),
                      'status': selectedStatus,
                      'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      'items': dialogItems.map((i) => i.toJson()).toList(),
                    };
                    final ok = await ref.read(purchaseOrdersProvider.notifier).updatePurchaseOrder(po.poId!, updateData);
                    if (ok && context.mounted) Navigator.pop(dialogCtx);
                  }
                }
              },
              child: Text(po == null ? 'Create PO' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
