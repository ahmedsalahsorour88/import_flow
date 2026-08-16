import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';

class POReconciliationTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  const POReconciliationTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<POReconciliationTab> createState() => _POReconciliationTabState();
}

class _POReconciliationTabState extends ConsumerState<POReconciliationTab> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  final TextEditingController _finalInvNumberCtrl = TextEditingController();
  final TextEditingController _finalPLNumberCtrl = TextEditingController();

  List<POReconciliationItemModel> _invoiceItems = [];
  List<POReconciliationItemModel> _packingItems = [];
  bool _isSubmitting = false;
  POReconciliationResultModel? _reconciliationResult;

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() async {
      await ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      if (_selectedImportFileId != null && mounted) {
        _loadPOItems(_selectedImportFileId!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant POReconciliationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImportFileId != oldWidget.initialImportFileId && widget.initialImportFileId != null) {
      _selectedImportFileId = widget.initialImportFileId;
      Future.microtask(() async {
        await ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
        if (mounted) _loadPOItems(_selectedImportFileId!);
      });
    }
  }

  void _loadPOItems(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    _finalInvNumberCtrl.text = file.piNumber ?? 'INV-FINAL-${file.importFileCode}';
    _finalPLNumberCtrl.text = 'PL-FINAL-${file.importFileCode}';

    final poList = ref.read(purchaseOrdersProvider).purchaseOrders;
    final linkedPOs = poList.where((p) => p.importFileId == fileId || (file.poIds?.contains(p.poId) ?? false)).toList();

    List<POReconciliationItemModel> invList = [];
    List<POReconciliationItemModel> plList = [];

    for (var po in linkedPOs) {
      // 1. Load Commercial Invoice Line Items for Section 1
      for (var itm in po.items) {
        invList.add(POReconciliationItemModel(
          poItemId: itm.itemId,
          itemCode: (itm.itemCode != null && itm.itemCode!.isNotEmpty) ? itm.itemCode! : '1',
          description: itm.descriptionAr.isNotEmpty ? itm.descriptionAr : (itm.descriptionEn ?? 'بند الفاتورة'),
          hsCode: itm.hsCode,
          packageType: 'Carton',
          initialQuantity: itm.quantity,
          finalQuantity: itm.quantity,
          initialUnitPrice: itm.unitPrice,
          unitPrice: itm.unitPrice,
          finalUnitPrice: itm.unitPrice,
          initialPackagesCount: 1.0,
          finalPackagesCount: 1.0,
          initialNetWeightKg: itm.netWeightKg,
          finalNetWeightKg: itm.netWeightKg,
          initialGrossWeightKg: itm.grossWeightKg,
          finalGrossWeightKg: itm.grossWeightKg,
          initialCbm: itm.totalCbm,
          finalCbm: itm.totalCbm,
          variancePercentage: 0.0,
          priceVariancePercentage: 0.0,
          weightVariancePercentage: 0.0,
        ));
      }

      // 2. Load Packing List Breakdown for Section 2
      if (po.packingListItems.isNotEmpty) {
        for (int i = 0; i < po.packingListItems.length; i++) {
          final pl = po.packingListItems[i];

          double initPackages = pl.qtyPkg > 0 ? pl.qtyPkg : 1.0;
          double initNetW = pl.totalNetWeightKg > 0
              ? pl.totalNetWeightKg
              : (pl.netWeightUnitKg > 0 ? pl.netWeightUnitKg * initPackages : 0.0);
          double initGrossW = pl.totalGrossWeightKg > 0
              ? pl.totalGrossWeightKg
              : (pl.grossWeightUnitKg > 0 ? pl.grossWeightUnitKg * initPackages : 0.0);
          double initCbm = pl.totalCbm > 0
              ? pl.totalCbm
              : (pl.calculatedCbm > 0 ? pl.calculatedCbm : 0.0);
          String pkgType = pl.packageType.isNotEmpty ? pl.packageType : 'Carton';
          String code = pl.itemCode.isNotEmpty ? pl.itemCode : 'PL-${i + 1}';

          plList.add(POReconciliationItemModel(
            poItemId: (pl.packingItemId != null && pl.packingItemId! > 0) ? pl.packingItemId : (i + 1),
            itemCode: code,
            description: pl.itemCode.isNotEmpty ? pl.itemCode : 'بند تعبئة $pkgType (${initPackages.toInt()} طرد)',
            hsCode: pl.hsCode,
            packageType: pkgType,
            initialQuantity: pl.qtyPcs > 0 ? pl.qtyPcs : initPackages,
            finalQuantity: pl.qtyPcs > 0 ? pl.qtyPcs : initPackages,
            initialUnitPrice: 0.0,
            unitPrice: 0.0,
            finalUnitPrice: 0.0,
            initialPackagesCount: initPackages,
            finalPackagesCount: initPackages,
            initialNetWeightKg: initNetW,
            finalNetWeightKg: initNetW,
            initialGrossWeightKg: initGrossW,
            finalGrossWeightKg: initGrossW,
            initialCbm: initCbm,
            finalCbm: initCbm,
            variancePercentage: 0.0,
            priceVariancePercentage: 0.0,
            weightVariancePercentage: 0.0,
          ));
        }
      }
    }

    if (invList.isEmpty) {
      invList = [
        POReconciliationItemModel(
          itemCode: 'ITEM-001',
          description: 'Industrial Control & Equipment Unit',
          packageType: 'Carton',
          initialQuantity: 100.0,
          finalQuantity: 100.0,
          initialUnitPrice: 250.0,
          unitPrice: 250.0,
          finalUnitPrice: 250.0,
          initialPackagesCount: 10.0,
          finalPackagesCount: 10.0,
          initialNetWeightKg: 20700.0,
          finalNetWeightKg: 20700.0,
          initialGrossWeightKg: 24500.0,
          finalGrossWeightKg: 24500.0,
          initialCbm: 58.4,
          finalCbm: 58.4,
        ),
      ];
    }

    if (plList.isEmpty) {
      plList = invList.map((inv) => inv).toList();
    }

    setState(() {
      _invoiceItems = invList;
      _packingItems = plList;
    });
  }

  Future<void> _submitCertification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Send both invoice items and packing list items for certification
      final combined = [..._invoiceItems, ..._packingItems];
      final payload = {
        'import_file_id': _selectedImportFileId,
        'final_invoice_number': _finalInvNumberCtrl.text.trim(),
        'final_packing_list_number': _finalPLNumberCtrl.text.trim(),
        'items': combined.map((i) => i.toJson()).toList(),
      };

      final res = await ref.read(poReconciliationProvider).submitPOFinalReconciliation(payload);
      setState(() {
        _reconciliationResult = res;
      });

      ref.invalidate(importFilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✔ تم اعتماد الأرقام النهائية للفاتورة والباكينج ليست بنجاح وتحديث بيانات المنظومة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الاعتماد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    double totalAmount = _invoiceItems.fold(0.0, (s, itm) => s + (itm.finalQuantity * (itm.finalUnitPrice > 0 ? itm.finalUnitPrice : itm.unitPrice)));
    double totalPackages = _packingItems.fold(0.0, (s, itm) => s + itm.finalPackagesCount);
    double totalGrossWeight = _packingItems.fold(0.0, (s, itm) => s + itm.finalGrossWeightKg);
    double totalNetWeight = _packingItems.fold(0.0, (s, itm) => s + itm.finalNetWeightKg);
    double totalCbm = _packingItems.fold(0.0, (s, itm) => s + itm.finalCbm);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.fact_check, color: AppTheme.cobalt, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'مراجعة وتأكيد الفاتورة التجارية والباكينج ليست النهائية (PO Final Reconciliation & Review)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_reconciliationResult != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'معتمدة ومحدثة في المنظومة',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'البيانات والكميات والأسعار والأوزان المعتمدة هنا هي المرجع الحاكم لدرافت البوليصة، والمخزون بالطريق، والإفراج الجمركي، واستلام المخزن.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SearchableDropdownField<int>(
                            value: _selectedImportFileId,
                            labelText: 'ملف الشحنة الاستيرادي *',
                            searchHintText: 'ابحث برقم الملف أو كود الشحنة...',
                            items: importFiles
                                .map((f) => SearchableDropdownItem<int>(
                                      value: f.importFileId,
                                      label: '${f.importFileCode} - ${f.companyName} (${f.supplierName})',
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              if (v != null) {
                                setState(() => _selectedImportFileId = v);
                                await ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
                                if (mounted) _loadPOItems(v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _finalInvNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رقم الفاتورة التجارية النهائية *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.receipt_long),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _finalPLNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رقم قائمة التعبئة النهائية *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary Metrics Cards
            Row(
              children: [
                _buildSummaryCard('إجمالي الفاتورة النهائية', '${totalAmount.toStringAsFixed(2)} \$', Icons.monetization_on, Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الطرود الفعلية', '${totalPackages.toStringAsFixed(0)} طرد', Icons.all_inbox, Colors.purple),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الوزن القائم (Gross)', '${totalGrossWeight.toStringAsFixed(2)} كجم', Icons.scale, Colors.teal),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الوزن الصافي (Net)', '${totalNetWeight.toStringAsFixed(2)} كجم', Icons.fitness_center, Colors.indigo),
                const SizedBox(width: 12),
                _buildSummaryCard('إجمالي الحجم (CBM)', '${totalCbm.toStringAsFixed(3)} م³', Icons.view_in_ar, Colors.orange),
              ],
            ),
            const SizedBox(height: 20),

            // SECTION 1: INVOICE & PRICE RECONCILIATION TABLE
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt, color: AppTheme.cobalt),
                            SizedBox(width: 8),
                            Text('1. مراجعة وتأكيد بنود وأسعار الفاتورة التجارية النهائية (Invoice Items & Price Review)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cobalt,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.verified, color: Colors.white),
                          label: const Text('اعتماد ومطابقة البيانات النهائية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _isSubmitting ? null : _submitCertification,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_invoiceItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text('يرجى اختيار ملف الشحنة لعرض بنود أمر الشراء للمطابقة', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('كود الصنف')),
                            DataColumn(label: Text('الوصف')),
                            DataColumn(label: Text('كمية PO')),
                            DataColumn(label: Text('الكمية النهائية *')),
                            DataColumn(label: Text('فارق الكمية %')),
                            DataColumn(label: Text('سعر الوحدة (PO) \$')),
                            DataColumn(label: Text('* مراجعة السعر النهائي \$')),
                            DataColumn(label: Text('فارق السعر %')),
                            DataColumn(label: Text('إجمالي الفاتورة (\$)')),
                          ],
                          rows: _invoiceItems.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var itm = entry.value;
                            double currentPrice = itm.finalUnitPrice > 0 ? itm.finalUnitPrice : itm.unitPrice;
                            double lineTotal = itm.finalQuantity * currentPrice;
                            double priceVariance = itm.initialUnitPrice > 0 ? ((currentPrice - itm.initialUnitPrice) / itm.initialUnitPrice) * 100.0 : 0.0;
                            double qtyVariance = itm.initialQuantity > 0 ? ((itm.finalQuantity - itm.initialQuantity) / itm.initialQuantity) * 100.0 : 0.0;

                            return DataRow(cells: [
                              DataCell(Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(width: 220, child: Text(itm.description, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))),
                              DataCell(Text(itm.initialQuantity.toStringAsFixed(1))),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: itm.finalQuantity.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? q = double.tryParse(v);
                                      if (q != null) {
                                        setState(() {
                                          _invoiceItems[idx] = itm.copyWith(
                                            finalQuantity: q,
                                            variancePercentage: itm.initialQuantity > 0 ? ((q - itm.initialQuantity) / itm.initialQuantity) * 100.0 : 0.0,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(_buildVarianceBadge(qtyVariance)),
                              DataCell(Text(itm.initialUnitPrice.toStringAsFixed(2))),
                              DataCell(
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    initialValue: currentPrice.toStringAsFixed(2),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      prefixText: '\$ ',
                                      contentPadding: EdgeInsets.all(6),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _invoiceItems[idx] = itm.copyWith(
                                            finalUnitPrice: p,
                                            unitPrice: p,
                                            priceVariancePercentage: itm.initialUnitPrice > 0 ? ((p - itm.initialUnitPrice) / itm.initialUnitPrice) * 100.0 : 0.0,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(_buildVarianceBadge(priceVariance)),
                              DataCell(Text('${lineTotal.toStringAsFixed(2)} \$', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 2: PACKING LIST & ACTUAL WEIGHTS / PACKAGES RECONCILIATION TABLE
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          '2. مراجعة وتأكيد بيان العبوة والباكينج ليست النهائية (Packing List & Actual Packages/Weights)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مراجعة الأعداد الفعلية للطرود/الكراتين، والأوزان الصافية والقائمة الفعلية، والحجم الفعلي لتطابق درافت البوليصة والمخزن.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Divider(height: 20),
                    if (_packingItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text('يرجى اختيار ملف الشحنة لعرض بنود بيان التعبئة للمطابقة', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('كود الصنف')),
                            DataColumn(label: Text('الوصف')),
                            DataColumn(label: Text('نوع التغليف')),
                            DataColumn(label: Text('طرود PO')),
                            DataColumn(label: Text('الطرود الفعلية بالباكينج *')),
                            DataColumn(label: Text('الصافي الأولي (كجم)')),
                            DataColumn(label: Text('الصافي الفعلي (كجم) *')),
                            DataColumn(label: Text('القائم الأولي (كجم)')),
                            DataColumn(label: Text('القائم الفعلي (كجم) *')),
                            DataColumn(label: Text('فارق الوزن %')),
                            DataColumn(label: Text('الحجم الأولي CBM')),
                            DataColumn(label: Text('الحجم الفعلي CBM *')),
                          ],
                          rows: _packingItems.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var itm = entry.value;
                            double weightVariance = itm.initialGrossWeightKg > 0
                                ? ((itm.finalGrossWeightKg - itm.initialGrossWeightKg) / itm.initialGrossWeightKg) * 100.0
                                : 0.0;

                            return DataRow(cells: [
                              DataCell(Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(width: 150, child: Text(itm.description, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: itm.packageType,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      _packingItems[idx] = itm.copyWith(packageType: v);
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(itm.initialPackagesCount.toStringAsFixed(0))),
                              DataCell(
                                SizedBox(
                                  width: 75,
                                  child: TextFormField(
                                    initialValue: itm.finalPackagesCount.toStringAsFixed(0),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(finalPackagesCount: p);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(itm.initialNetWeightKg.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade700))),
                              DataCell(
                                SizedBox(
                                  width: 85,
                                  child: TextFormField(
                                    initialValue: itm.finalNetWeightKg.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(finalNetWeightKg: p);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(itm.initialGrossWeightKg.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade700))),
                              DataCell(
                                SizedBox(
                                  width: 85,
                                  child: TextFormField(
                                    initialValue: itm.finalGrossWeightKg.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(
                                            finalGrossWeightKg: p,
                                            weightVariancePercentage: itm.initialGrossWeightKg > 0 ? ((p - itm.initialGrossWeightKg) / itm.initialGrossWeightKg) * 100.0 : 0.0,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(_buildVarianceBadge(weightVariance)),
                              DataCell(Text(itm.initialCbm.toStringAsFixed(3), style: TextStyle(color: Colors.grey.shade700))),
                              DataCell(
                                SizedBox(
                                  width: 85,
                                  child: TextFormField(
                                    initialValue: itm.finalCbm.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6), border: OutlineInputBorder()),
                                    onChanged: (v) {
                                      double? p = double.tryParse(v);
                                      if (p != null) {
                                        setState(() {
                                          _packingItems[idx] = itm.copyWith(finalCbm: p);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceBadge(double variance) {
    bool isZero = variance == 0.0;
    bool isPositive = variance > 0;
    Color color = isZero ? Colors.grey : (isPositive ? Colors.green : Colors.red);
    String text = isZero ? '0.0%' : '${isPositive ? '+' : ''}${variance.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
