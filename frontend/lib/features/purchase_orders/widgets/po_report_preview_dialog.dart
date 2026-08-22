import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/customs_tariff/models/customs_tariff_model.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';

class POReportPreviewDialog extends StatelessWidget {
  final String poNumber;
  final String? piNumber;
  final String? acidNumber;
  final DateTime orderDate;
  final String companyName;
  final String? companyTaxId;
  final String supplierName;
  final String? supplierCountry;
  final String incoterm;
  final String currency;
  final double exchangeRate;
  final String? countryOfOrigin;
  final String? paymentTerms;
  final String? projectName;
  final String? importFileCode;
  final List<POLineItemModel> items;
  final List<PackingListItemModel> packingItems;
  final List<PalletPlanItemModel> palletItems;
  final List<CustomsTariffModel> tariffs;
  final bool isDirectVolumeMode;
  final String? notes;
  final VoidCallback? onConfirmSave;

  const POReportPreviewDialog({
    super.key,
    required this.poNumber,
    this.piNumber,
    this.acidNumber,
    required this.orderDate,
    required this.companyName,
    this.companyTaxId,
    required this.supplierName,
    this.supplierCountry,
    required this.incoterm,
    required this.currency,
    required this.exchangeRate,
    this.countryOfOrigin,
    this.paymentTerms,
    this.projectName,
    this.importFileCode,
    required this.items,
    required this.packingItems,
    required this.palletItems,
    this.tariffs = const [],
    this.isDirectVolumeMode = false,
    this.notes,
    this.onConfirmSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String poNumber,
    String? piNumber,
    String? acidNumber,
    required DateTime orderDate,
    required String companyName,
    String? companyTaxId,
    required String supplierName,
    String? supplierCountry,
    required String incoterm,
    required String currency,
    required double exchangeRate,
    String? countryOfOrigin,
    String? paymentTerms,
    String? projectName,
    String? importFileCode,
    required List<POLineItemModel> items,
    required List<PackingListItemModel> packingItems,
    required List<PalletPlanItemModel> palletItems,
    List<CustomsTariffModel> tariffs = const [],
    bool isDirectVolumeMode = false,
    String? notes,
    VoidCallback? onConfirmSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => POReportPreviewDialog(
        poNumber: poNumber,
        piNumber: piNumber,
        acidNumber: acidNumber,
        orderDate: orderDate,
        companyName: companyName,
        companyTaxId: companyTaxId,
        supplierName: supplierName,
        supplierCountry: supplierCountry,
        incoterm: incoterm,
        currency: currency,
        exchangeRate: exchangeRate,
        countryOfOrigin: countryOfOrigin,
        paymentTerms: paymentTerms,
        projectName: projectName,
        importFileCode: importFileCode,
        items: items,
        packingItems: packingItems,
        palletItems: palletItems,
        tariffs: tariffs,
        isDirectVolumeMode: isDirectVolumeMode,
        notes: notes,
        onConfirmSave: onConfirmSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    final double totalGrossWeight = packingItems.fold(
      0.0,
      (sum, p) => sum + (p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.grossWeightUnitKg * p.qtyPkg)),
    );
    final double totalNetWeight = packingItems.fold(
      0.0,
      (sum, p) => sum + (p.totalNetWeightKg > 0 ? p.totalNetWeightKg : (p.netWeightUnitKg * p.qtyPkg)),
    );
    final double totalPackages = packingItems.fold(0.0, (sum, p) => sum + p.qtyPkg);
    final double totalPcs = packingItems.fold(0.0, (sum, p) => sum + p.qtyPcs);
    final double totalCbm = packingItems.fold(0.0, (sum, p) => sum + p.calculatedCbm);

    final int totalPallets = palletItems.fold(0, (sum, p) => sum + p.palletCount);
    final double totalPalletCbm = palletItems.fold(0.0, (sum, p) => sum + p.calculatedCbm);
    final double totalPalletWeight = palletItems.fold(0.0, (sum, p) => sum + p.totalWeightKg);

    // Compute container recommendation
    String recommendedContainer = '20ft Standard (20GP)';
    if (totalPallets > 11 || totalCbm > 28.0 || totalGrossWeight > 21500) {
      recommendedContainer = '40ft High Cube (40HC)';
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: screenWidth > 1150 ? 1080 : (screenWidth * 0.95),
        constraints: const BoxConstraints(maxHeight: 820),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معاينة تقرير أمر الشراء وقائمة التعبئة المعتمدة (PO & Packing List Preview)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'استعراض تفصيلي شامل ومطابقة نهائية قبل الحفظ — Sorour Logistics ERP',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('نسخ نص التقرير', style: TextStyle(fontSize: 11.5)),
                    onPressed: () => _copyReportTextToClipboard(context),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'إغلاق المعاينة',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content (Report Body)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Document Header Box (Formal ERP Style)
                    _buildReportHeaderCard(totalAmount),
                    const SizedBox(height: 14),

                    // Metrics Badges
                    _buildMetricsSummaryBar(
                      totalAmount: totalAmount,
                      totalPackages: totalPackages,
                      totalPcs: totalPcs,
                      totalGrossWeight: totalGrossWeight,
                      totalNetWeight: totalNetWeight,
                      totalCbm: totalCbm,
                      totalPallets: totalPallets,
                      totalPalletCbm: totalPalletCbm,
                      totalPalletWeight: totalPalletWeight,
                      recommendedContainer: recommendedContainer,
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Commercial Invoice Line Items Table
                    _buildSectionTitle('1. جدول بنود الفاتورة التجارية (Commercial Invoice Line Items)', Icons.receipt_long_rounded),
                    const SizedBox(height: 8),
                    _buildInvoiceItemsTable(),
                    const SizedBox(height: 18),

                    // Section 2: Detailed Packing List Table
                    _buildSectionTitle('2. بيان قائمة التعبئة والطرود والأبعاد (Detailed Packing List)', Icons.inventory_2_outlined),
                    const SizedBox(height: 8),
                    _buildPackingListTable(),
                    const SizedBox(height: 18),

                    // Section 3: Master Pallet Plan Table (If Pallets configured)
                    if (palletItems.isNotEmpty && palletItems.any((p) => p.palletCount > 0)) ...[
                      _buildSectionTitle('3. لوحة مخطط البالتات ووحدات الشحن (Master Palletization Plan)', Icons.layers_outlined),
                      const SizedBox(height: 8),
                      _buildPalletPlanTable(),
                      const SizedBox(height: 18),
                    ],

                    // Notes Section
                    if (notes != null && notes!.trim().isNotEmpty) ...[
                      _buildSectionTitle('4. الملاحظات والشروط الإضافية (Additional Notes & Terms)', Icons.note_alt_outlined),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          notes!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2)),
                ],
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.emerald, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'جاهز للاعتماد: ${items.length} بنود | ${packingItems.length} طرود ${totalPallets > 0 ? " | $totalPallets بالتات" : ""}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق والعودة للتعديل', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('حفظ واعتماد أمر الشراء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirmSave?.call();
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
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.cobalt),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
          ),
        ),
      ],
    );
  }

  Widget _buildReportHeaderCard(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PURCHASE ORDER & PACKING SPECIFICATION',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blue.shade900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PO Number: $poNumber ${piNumber != null && piNumber!.isNotEmpty ? " | PI: $piNumber" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                    ),
                    if (acidNumber != null && acidNumber!.isNotEmpty)
                      Text(
                        'ACID Number: $acidNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.emerald),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Order Date: ${orderDate.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Currency: $currency (Rate: ${exchangeRate.toStringAsFixed(4)} EGP)',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Text(
                    'Incoterms: $incoterm | Origin: ${countryOfOrigin ?? "N/A"}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🏢 الشركة المستوردة (Buyer):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                      if (companyTaxId != null && companyTaxId!.isNotEmpty)
                        Text('Tax ID: $companyTaxId', style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                      if (importFileCode != null && importFileCode!.isNotEmpty)
                        Text('ملف الشحنة: $importFileCode', style: const TextStyle(fontSize: 10.5, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🚢 المورد الأجنبي (Seller):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                      Text('Country: ${supplierCountry ?? countryOfOrigin ?? "N/A"}', style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                      if (paymentTerms != null && paymentTerms!.isNotEmpty)
                        Text('Terms: $paymentTerms', style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSummaryBar({
    required double totalAmount,
    required double totalPackages,
    required double totalPcs,
    required double totalGrossWeight,
    required double totalNetWeight,
    required double totalCbm,
    required int totalPallets,
    required double totalPalletCbm,
    required double totalPalletWeight,
    required String recommendedContainer,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cobalt.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _buildMetricBadge('إجمالي الفاتورة', '${totalAmount.toStringAsFixed(2)} $currency', Icons.monetization_on_outlined, AppTheme.emerald),
          _buildMetricBadge('عدد الطرود والقطع', '${totalPackages.toStringAsFixed(0)} طرد (${totalPcs.toStringAsFixed(0)} pcs)', Icons.inventory_2_outlined, AppTheme.cobalt),
          _buildMetricBadge('الوزن القائم', '${totalGrossWeight.toStringAsFixed(1)} kg', Icons.scale_outlined, AppTheme.orange),
          _buildMetricBadge('الحجم CBM', '${totalCbm.toStringAsFixed(3)} m³', Icons.view_in_ar_outlined, Colors.purple),
          if (totalPallets > 0)
            _buildMetricBadge('مخطط البالتات', '$totalPallets بالتة (${totalPalletCbm.toStringAsFixed(3)} m³)', Icons.layers_outlined, Colors.indigo),
          _buildMetricBadge('الحاوية المقترحة', recommendedContainer, Icons.directions_boat_outlined, AppTheme.charcoal),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
            Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FixedColumnWidth(110),
                2: FixedColumnWidth(260),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(90),
                5: FixedColumnWidth(110),
                6: FixedColumnWidth(120),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    _HeaderCell('#'),
                    _HeaderCell('Item Code'),
                    _HeaderCell('Description / البيان'),
                    _HeaderCell('HS Code'),
                    _HeaderCell('Qty / Unit'),
                    _HeaderCell('Unit Price'),
                    _HeaderCell('Total Amount'),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final itm = entry.value;
                  String hs = itm.hsCode ?? '';
                  if (hs.isEmpty && itm.tariffId != null) {
                    final match = tariffs.where((t) => t.tariffId == itm.tariffId).firstOrNull;
                    if (match != null) hs = match.hsCode;
                  }
                  return TableRow(
                    decoration: BoxDecoration(color: idx % 2 == 1 ? const Color(0xFFFDFDFD) : Colors.white),
                    children: [
                      _DataCell('${idx + 1}', align: TextAlign.center),
                      _DataCell(itm.itemCode ?? '-', isBold: true, color: AppTheme.cobalt),
                      _DataCell(itm.descriptionAr.isNotEmpty ? itm.descriptionAr : (itm.descriptionEn ?? '-')),
                      _DataCell(hs.isNotEmpty ? hs : '⚠️ غير مسجل', color: hs.isNotEmpty ? AppTheme.charcoal : Colors.red),
                      _DataCell('${itm.quantity.toStringAsFixed(0)} ${itm.unitOfMeasure}'),
                      _DataCell('${itm.unitPrice.toStringAsFixed(2)} $currency'),
                      _DataCell('${itm.totalPrice.toStringAsFixed(2)} $currency', isBold: true),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5)),
                  children: [
                    const _DataCell(''),
                    const _DataCell('الإجمالي الكلي', isBold: true, color: AppTheme.charcoal),
                    _DataCell('${items.length} بنود', isBold: true),
                    const _DataCell(''),
                    _DataCell('${items.fold<double>(0.0, (s, i) => s + i.quantity).toStringAsFixed(0)} pcs', isBold: true),
                    const _DataCell(''),
                    _DataCell('${items.fold<double>(0.0, (s, i) => s + i.totalPrice).toStringAsFixed(2)} $currency', isBold: true, color: AppTheme.emerald),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackingListTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FixedColumnWidth(110),
                2: FixedColumnWidth(220),
                3: FixedColumnWidth(80),
                4: FixedColumnWidth(90),
                5: FixedColumnWidth(110),
                6: FixedColumnWidth(90),
                7: FixedColumnWidth(85),
                8: FixedColumnWidth(80),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    _HeaderCell('#'),
                    _HeaderCell('Item Code'),
                    _HeaderCell('Description / البيان'),
                    _HeaderCell('Type'),
                    _HeaderCell('Pkg / Pcs'),
                    _HeaderCell('Dimensions'),
                    _HeaderCell('Gross (kg)'),
                    _HeaderCell('CBM (m³)'),
                    _HeaderCell('Stackable'),
                  ],
                ),
                ...packingItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final grossTot = p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.grossWeightUnitKg * p.qtyPkg);
                  final dimStr = (p.lengthCm > 0 && p.widthCm > 0 && p.heightCm > 0)
                      ? '${p.lengthCm.toStringAsFixed(0)}×${p.widthCm.toStringAsFixed(0)}×${p.heightCm.toStringAsFixed(0)}'
                      : 'حجم مباشر';
                  return TableRow(
                    decoration: BoxDecoration(color: idx % 2 == 1 ? const Color(0xFFFDFDFD) : Colors.white),
                    children: [
                      _DataCell('${idx + 1}', align: TextAlign.center),
                      _DataCell(p.itemCode, isBold: true, color: AppTheme.cobalt),
                      _DataCell(p.description != null && p.description!.isNotEmpty ? p.description! : '-'),
                      _DataCell(p.packageType),
                      _DataCell('${p.qtyPkg.toStringAsFixed(0)} / ${p.qtyPcs.toStringAsFixed(0)}'),
                      _DataCell(dimStr, color: Colors.black87),
                      _DataCell(grossTot.toStringAsFixed(1)),
                      _DataCell(p.calculatedCbm.toStringAsFixed(3)),
                      _DataCell(p.isStackable ? '📦 نعم' : '🚫 أرضي', color: p.isStackable ? Colors.green.shade800 : Colors.orange.shade800),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5)),
                  children: [
                    const _DataCell(''),
                    const _DataCell('إجمالي التعبئة', isBold: true, color: AppTheme.charcoal),
                    _DataCell('${packingItems.length} أسطر', isBold: true),
                    const _DataCell(''),
                    _DataCell(
                      '${packingItems.fold<double>(0.0, (s, p) => s + p.qtyPkg).toStringAsFixed(0)} طرد',
                      isBold: true,
                    ),
                    const _DataCell(''),
                    _DataCell(
                      '${packingItems.fold<double>(0.0, (s, p) => s + (p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.grossWeightUnitKg * p.qtyPkg))).toStringAsFixed(1)} kg',
                      isBold: true,
                      color: AppTheme.orange,
                    ),
                    _DataCell(
                      '${packingItems.fold<double>(0.0, (s, p) => s + p.calculatedCbm).toStringAsFixed(3)} m³',
                      isBold: true,
                      color: Colors.purple,
                    ),
                    const _DataCell(''),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPalletPlanTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1)),
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FixedColumnWidth(160),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(110),
                4: FixedColumnWidth(90),
                5: FixedColumnWidth(90),
                6: FixedColumnWidth(130),
                7: FixedColumnWidth(160),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    _HeaderCell('#'),
                    _HeaderCell('نوع ومقاس البالتة'),
                    _HeaderCell('العدد'),
                    _HeaderCell('الأبعاد'),
                    _HeaderCell('الوزن (kg)'),
                    _HeaderCell('الحجم (m³)'),
                    _HeaderCell('تعليمات الرص'),
                    _HeaderCell('ملاحظات'),
                  ],
                ),
                ...palletItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(color: idx % 2 == 1 ? const Color(0xFFFDFDFD) : Colors.white),
                    children: [
                      _DataCell('${idx + 1}', align: TextAlign.center),
                      _DataCell(p.palletType, isBold: true),
                      _DataCell('${p.palletCount} بالتات', isBold: true, color: AppTheme.cobalt),
                      _DataCell('${p.lengthCm.toStringAsFixed(0)}×${p.widthCm.toStringAsFixed(0)}×${p.heightCm.toStringAsFixed(0)}'),
                      _DataCell(p.totalWeightKg.toStringAsFixed(1)),
                      _DataCell(p.calculatedCbm.toStringAsFixed(3)),
                      _DataCell(p.isStackable ? '📦 قابل للرص' : '🚫 أرضي Floor Only', color: p.isStackable ? Colors.green.shade800 : Colors.orange.shade800),
                      _DataCell(p.notes != null && p.notes!.isNotEmpty ? p.notes! : '-'),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5)),
                  children: [
                    const _DataCell(''),
                    const _DataCell('إجمالي البالتات', isBold: true, color: AppTheme.charcoal),
                    _DataCell('${palletItems.fold<int>(0, (s, p) => s + p.palletCount)} بالتة', isBold: true, color: AppTheme.cobalt),
                    const _DataCell(''),
                    _DataCell('${palletItems.fold<double>(0.0, (s, p) => s + p.totalWeightKg).toStringAsFixed(1)} kg', isBold: true),
                    _DataCell('${palletItems.fold<double>(0.0, (s, p) => s + p.calculatedCbm).toStringAsFixed(3)} m³', isBold: true, color: Colors.purple),
                    const _DataCell(''),
                    const _DataCell(''),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyReportTextToClipboard(BuildContext context) {
    final double totalAmount = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    final double totalGrossWeight = packingItems.fold(
      0.0,
      (sum, p) => sum + (p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.grossWeightUnitKg * p.qtyPkg)),
    );
    final double totalNetWeight = packingItems.fold(
      0.0,
      (sum, p) => sum + (p.totalNetWeightKg > 0 ? p.totalNetWeightKg : (p.netWeightUnitKg * p.qtyPkg)),
    );
    final double totalPackages = packingItems.fold(0.0, (sum, p) => sum + p.qtyPkg);
    final double totalCbm = packingItems.fold(0.0, (sum, p) => sum + p.calculatedCbm);
    final int totalPallets = palletItems.fold(0, (sum, p) => sum + p.palletCount);

    final sb = StringBuffer();
    sb.writeln('================================================================');
    sb.writeln('Sorour Logistics ERP — Purchase Order & Packing Specification');
    sb.writeln('================================================================');
    sb.writeln('PO Number: $poNumber');
    if (piNumber != null) sb.writeln('Proforma Invoice: $piNumber');
    if (acidNumber != null) sb.writeln('ACID Number: $acidNumber');
    sb.writeln('Order Date: ${orderDate.toIso8601String().substring(0, 10)}');
    sb.writeln('Importer: $companyName (Tax ID: ${companyTaxId ?? "N/A"})');
    sb.writeln('Supplier: $supplierName (Country: ${supplierCountry ?? countryOfOrigin ?? "N/A"})');
    sb.writeln('Incoterms: $incoterm | Currency: $currency | Ex. Rate: $exchangeRate EGP');
    if (projectName != null) sb.writeln('Project: $projectName');
    if (importFileCode != null) sb.writeln('Import File: $importFileCode');
    sb.writeln('----------------------------------------------------------------');
    sb.writeln('Total Amount: ${totalAmount.toStringAsFixed(2)} $currency (${(totalAmount * exchangeRate).toStringAsFixed(2)} EGP)');
    sb.writeln('Total Packages: ${totalPackages.toStringAsFixed(0)} Pkgs | Gross Wt: ${totalGrossWeight.toStringAsFixed(1)} kg | Net Wt: ${totalNetWeight.toStringAsFixed(1)} kg');
    sb.writeln('Total Volume: ${totalCbm.toStringAsFixed(3)} CBM | Pallet Count: $totalPallets Pallets');
    sb.writeln('================================================================\n');

    sb.writeln('--- 1. COMMERCIAL INVOICE ITEMS ---');
    sb.writeln('# | Item Code | Description | HS Code | Qty | Unit | Price | Total');
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      sb.writeln('${i + 1} | ${it.itemCode ?? "-"} | ${it.descriptionAr} | ${it.hsCode ?? "-"} | ${it.quantity} | ${it.unitOfMeasure} | ${it.unitPrice} | ${it.totalPrice}');
    }
    sb.writeln('\n--- 2. DETAILED PACKING LIST ---');
    sb.writeln('# | Item Code | Description | Type | Pkg Qty | Dimensions (cm) | Gross Wt (kg) | CBM');
    for (int i = 0; i < packingItems.length; i++) {
      final p = packingItems[i];
      final dim = (p.lengthCm > 0 && p.widthCm > 0 && p.heightCm > 0) ? '${p.lengthCm}x${p.widthCm}x${p.heightCm}' : 'Direct CBM';
      sb.writeln('${i + 1} | ${p.itemCode} | ${p.description ?? "-"} | ${p.packageType} | ${p.qtyPkg} | $dim | ${p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : p.grossWeightUnitKg * p.qtyPkg} | ${p.calculatedCbm}');
    }

    if (palletItems.isNotEmpty) {
      sb.writeln('\n--- 3. MASTER PALLETIZATION PLAN ---');
      sb.writeln('# | Pallet Type | Count | Dimensions (cm) | Weight (kg) | CBM | Stackable');
      for (int i = 0; i < palletItems.length; i++) {
        final pal = palletItems[i];
        sb.writeln('${i + 1} | ${pal.palletType} | ${pal.palletCount} | ${pal.lengthCm}x${pal.widthCm}x${pal.heightCm} | ${pal.totalWeightKg} | ${pal.calculatedCbm} | ${pal.isStackable ? "Stackable" : "Floor Only"}');
      }
    }

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 تم نسخ نص التقرير بالكامل للحافظة بنجاح!'),
        backgroundColor: AppTheme.cobalt,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? color;
  final TextAlign align;
  const _DataCell(this.text, {this.isBold = false, this.color, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}
