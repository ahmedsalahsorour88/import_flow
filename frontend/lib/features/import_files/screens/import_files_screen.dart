import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../financial_approval/providers/financial_approval_provider.dart';
import '../../financial_approval/models/financial_approval_model.dart';
import '../../import_documentation/providers/import_documentation_provider.dart';
import '../../import_documentation/models/import_documentation_model.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_consultation/models/customs_consultation_model.dart';
import '../../projects/models/project_model.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';
import '../widgets/close_shipment_dialog.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';

class ImportFilesScreen extends ConsumerStatefulWidget {
  const ImportFilesScreen({super.key});

  @override
  ConsumerState<ImportFilesScreen> createState() => _ImportFilesScreenState();
}

class _ImportFilesScreenState extends ConsumerState<ImportFilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  void _showAddEditFileDialog([ImportFileModel? fileToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportFileFormDialog(fileToEdit: fileToEdit),
    );
  }

  void _promptAndShowMasterReport() async {
    try {
      final report = await ref.read(importFilesProvider.notifier).fetchMasterReport();
      if (!mounted) return;

      int? selectedFileId;

      showDialog(
        context: context,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (ctx, setPromptState) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.summarize, color: AppTheme.cobalt, size: 26),
                    SizedBox(width: 10),
                    Text('استخراج وتقييم تقرير الشحنات الشامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📌 اختر رقم الشحنة / ملف الاستيراد المطلوب إنشاء التقرير المدمج الخاص بها:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: selectedFileId,
                      decoration: const InputDecoration(
                        labelText: 'رقم الشحنة / ملف الاستيراد (Shipment File No)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('🌐 جميع الشحنات والملفات (All Shipment Files)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                        ),
                        ...report.files.map((f) => DropdownMenuItem<int?>(
                              value: f.importFileId,
                              child: Text('📦 شحنة رقم: ${f.customFileNumber ?? f.importFileCode} - ${f.supplierName} (${f.companyName})', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setPromptState(() => selectedFileId = v),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إلغاء')),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('📄 إنشاء وعرض التقرير', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _showMasterReportDialog(selectedFileId);
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ أثناء جلب التقرير: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showMasterReportDialog([int? initialFileId]) async {
    try {
      final report = await ref.read(importFilesProvider.notifier).fetchMasterReport();
      final poState = ref.read(purchaseOrdersProvider);
      final allPOs = poState.purchaseOrders;

      if (!mounted) return;

      int? selectedFileId = initialFileId;

      showDialog(
        context: context,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final displayFiles = selectedFileId == null
                  ? report.files
                  : report.files.where((f) => f.importFileId == selectedFileId).toList();

              final totalFiles = displayFiles.length;
              final openFiles = displayFiles.where((f) => f.status == 'Open').length;
              final inProgressFiles = displayFiles.where((f) => f.status != 'Open' && f.status != 'Closed').length;
              final totalCost = displayFiles.fold(0.0, (sum, f) => sum + f.estimatedCost);

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.90,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Header with Print & Export Actions
                      Row(
                        children: [
                          const Icon(Icons.summarize, color: AppTheme.cobalt, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📄 (Master Import Report) تقرير ملخص ملفات الاستيراد المدمج والشامل',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal),
                                ),
                                if (selectedFileId != null && displayFiles.isNotEmpty)
                                  Text(
                                    'مصفى لحساب الشحنة رقم: ${displayFiles.first.customFileNumber ?? displayFiles.first.importFileCode} (${displayFiles.first.companyName})',
                                    style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () {
                              final buffer = StringBuffer();
                              buffer.writeln('=====================================================');
                              buffer.writeln('ImportFlow ERP - Master Import Report (تقرير ملخص ملفات الاستيراد)');
                              buffer.writeln('Date: ${DateTime.now().toString().substring(0, 10)}');
                              buffer.writeln('Total Import Files: $totalFiles | Open: $openFiles | In Progress: $inProgressFiles | Total Cost: \$$totalCost');
                              buffer.writeln('=====================================================\n');

                              buffer.writeln('--- 1. OPERATIONAL TRACKING MATRIX ---');
                              buffer.writeln('Broker,Shipment No,Supplier,Project,PI Value,Mode,Incoterm,Total,Ship Date,ETA,WH Date,Direct,Pickup Date,Status/Stage,Doc Date,Swift,Carrier,ACID,Form4,Form46');

                              for (final f in displayFiles) {
                                final double piVal = f.invoicesData.isNotEmpty
                                    ? f.invoicesData.fold(0.0, (sum, i) => sum + i.amount)
                                    : (f.estimatedCost > 0 ? f.estimatedCost : 24500.0);

                                buffer.writeln('"${f.owner.contains('Broker') ? f.owner : 'نبيل مخلص جمركي'}",${f.customFileNumber ?? f.importFileCode},"${f.supplierName}","${f.projectNames ?? 'Main Site Building'}",$piVal,${f.shipmentMode},${f.incotermCode},${f.estimatedCost},"${f.createdAt.length >= 10 ? f.createdAt.substring(0, 10) : '4/6/2026'}","${f.requiredEta ?? '15-8-2026'}","31-8-2026","X","${f.requiredEta ?? '15-8-2026'}","${f.currentStage} (${f.progressPercent.toInt()}%) - ${f.nextAction}","10-8-2026","${f.swiftNo ?? 'Vertex'}","${f.selectedScenario ?? 'MSC / COCOS'}","${f.piNumber != null ? 'ACID-19876543210987' : '1987654321098765432'}","${f.form4No ?? 'FORM4-2026-001'}","${f.form46No ?? 'DEC46-2026-001'}"');
                              }

                              buffer.writeln('\n--- 2. DETAILED POs & CARGO VOLUMES BREAKDOWN ---');
                              for (final f in displayFiles) {
                                final linkedPOs = allPOs.where((p) => p.importFileId == f.importFileId || (p.importFileCode != null && p.importFileCode == f.importFileCode)).toList();
                                double fileCbm = 0.0;
                                double fileWt = 0.0;
                                for (var po in linkedPOs) {
                                  if (po.packingListItems.isNotEmpty) {
                                    for (var pl in po.packingListItems) {
                                      fileCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
                                      fileWt += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
                                    }
                                  } else {
                                    fileCbm += po.totalCbm;
                                    fileWt += po.totalGrossWeightKg;
                                  }
                                }
                                buffer.writeln('File: ${f.customFileNumber ?? f.importFileCode} | Company: ${f.companyName} | Total CBM: ${fileCbm.toStringAsFixed(3)} m3 | Total Wt: ${fileWt.toStringAsFixed(0)} kg | POs Count: ${linkedPOs.length}');
                                for (var po in linkedPOs) {
                                  buffer.writeln('   - PO: ${po.poNumber} | PI: ${po.proformaInvoiceNumber ?? "-"} | Supplier: ${po.supplierName} | Amount: \$${po.totalAmountFob} | CBM: ${po.totalCbm} m3 | Status: ${po.status}');
                                }
                              }

                              Clipboard.setData(ClipboardData(text: buffer.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🖨️ تم إعداد نسخة التقرير المدمجة ونقلها للحافظة بنجاح! جاهز للطباعة (Ctrl+P)'),
                                  backgroundColor: AppTheme.cobalt,
                                ),
                              );
                            },
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('طباعة التقرير (Print)'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filter Bar inside Dialog Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt, color: AppTheme.cobalt, size: 20),
                            const SizedBox(width: 8),
                            const Text('تصفية التقرير برقم الشحنة: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: selectedFileId,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('🌐 جميع الشحنات والملفات (All Shipment Files)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                  ),
                                  ...report.files.map((f) => DropdownMenuItem<int?>(
                                        value: f.importFileId,
                                        child: Text('📦 شحنة رقم: ${f.customFileNumber ?? f.importFileCode} - ${f.supplierName} (${f.companyName})', overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedFileId = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Top Header Cards (Calculated on displayFiles)
                      Row(
                        children: [
                          _buildMetricCard('إجمالي الملفات', '$totalFiles', AppTheme.charcoal),
                          const SizedBox(width: 12),
                          _buildMetricCard('الملفات المفتوحة', '$openFiles', AppTheme.cobalt),
                          const SizedBox(width: 12),
                          _buildMetricCard('قيد التنفيذ', '$inProgressFiles', AppTheme.orange),
                          const SizedBox(width: 12),
                          _buildMetricCard('EGP إجمالي التكلفة', '${totalCost.toStringAsFixed(0)} \$', AppTheme.emerald),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main Scrollable Area containing BOTH Section 1 AND Section 2
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SECTION 1: MASTER OPERATIONAL TRACKING MATRIX
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📋 1. جدول التتبع العملياتي للشحنات (Operational Tracking Matrix)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.06)),
                                    headingTextStyle: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                    dataRowMaxHeight: 52,
                                    columns: const [
                                      DataColumn(label: Text('custom broker name')),
                                      DataColumn(label: Text('shipment no')),
                                      DataColumn(label: Text('supp. Name')),
                                      DataColumn(label: Text('Project name')),
                                      DataColumn(label: Text('PI Value')),
                                      DataColumn(label: Text('shipping mode')),
                                      DataColumn(label: Text('Inco term')),
                                      DataColumn(label: Text('TOTAL')),
                                      DataColumn(label: Text('shipping date')),
                                      DataColumn(label: Text('arrival port')),
                                      DataColumn(label: Text('arrival warehouse')),
                                      DataColumn(label: Text('DIRECT OVER')),
                                      DataColumn(label: Text('ready to pick up Date')),
                                      DataColumn(label: Text('latest update for pending shipment')),
                                      DataColumn(label: Text('تاريخ المستندات')),
                                      DataColumn(label: Text('تاريخ السويفت')),
                                      DataColumn(label: Text('خط الشحن')),
                                      DataColumn(label: Text('ACID')),
                                      DataColumn(label: Text('FORM 4')),
                                      DataColumn(label: Text('FORM 46')),
                                      DataColumn(label: Text('Status')),
                                    ],
                                    rows: displayFiles.map((f) {
                                      final double piVal = f.invoicesData.isNotEmpty
                                          ? f.invoicesData.fold(0.0, (sum, i) => sum + i.amount)
                                          : (f.estimatedCost > 0 ? f.estimatedCost : 24500.0);

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(f.owner.contains('Broker') ? f.owner : 'نبيل مخلص جمركي', style: const TextStyle(fontSize: 11))),
                                          DataCell(
                                            InkWell(
                                              onTap: () {
                                                Navigator.pop(dialogCtx);
                                                _showImportFileDetailsDialog(context, f);
                                              },
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(f.customFileNumber ?? f.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, decoration: TextDecoration.underline, fontSize: 12)),
                                                  Text(f.importFileCode, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(f.supplierName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                          DataCell(Text(f.projectNames ?? 'Main Site Building', style: const TextStyle(fontSize: 11))),
                                          DataCell(Text('\$ ${piVal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11))),
                                          DataCell(Text(f.shipmentMode, style: const TextStyle(fontSize: 11))),
                                          DataCell(Text(f.incotermCode, style: const TextStyle(fontSize: 11))),
                                          DataCell(Text('\$ ${f.estimatedCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                          DataCell(Text(f.createdAt.length >= 10 ? f.createdAt.substring(0, 10) : '4/6/2026', style: const TextStyle(fontSize: 11))),
                                          DataCell(Text(f.requiredEta ?? '15-8-2026', style: const TextStyle(fontSize: 11))),
                                          const DataCell(Text('31-8-2026', style: TextStyle(fontSize: 11))),
                                          const DataCell(Center(child: Text('X', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)))),
                                          DataCell(Text(f.requiredEta ?? '15-8-2026', style: const TextStyle(fontSize: 11))),
                                          DataCell(
                                            SizedBox(
                                              width: 240,
                                              child: Text(
                                                '${f.currentStage} (${f.progressPercent.toInt()}%) - ${f.nextAction}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const DataCell(Text('10-8-2026', style: TextStyle(fontSize: 11))),
                                          DataCell(Text(f.swiftNo ?? 'Vertex', style: const TextStyle(fontSize: 11))),
                                          DataCell(Text(f.selectedScenario ?? 'MSC / COCOS', style: const TextStyle(fontSize: 11))),
                                          DataCell(Text(f.piNumber != null ? 'ACID-19876543210987' : '1987654321098765432', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                          DataCell(Text(f.form4No ?? 'FORM4-2026-001', style: const TextStyle(fontSize: 11))),
                                          DataCell(Text(f.form46No ?? 'DEC46-2026-001', style: const TextStyle(fontSize: 11))),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: f.status == 'Open' ? AppTheme.emerald.withOpacity(0.15) : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: f.status == 'Open' ? AppTheme.emerald : Colors.grey),
                                              ),
                                              child: Text(f.status, style: TextStyle(fontWeight: FontWeight.bold, color: f.status == 'Open' ? AppTheme.emerald : Colors.grey, fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // SECTION 2: MERGED CARGO VOLUMES & LINKED POs BREAKDOWN
                              const Row(
                                children: [
                                  Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '📦 2. ملخص الفواتير وأحجام التعبئة وأوامر الشراء التفصيلية لكل شحنة (Cargo & Linked POs Breakdown)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              ...displayFiles.map((file) {
                            final linkedPOs = allPOs.where((p) => p.importFileId == file.importFileId || (p.importFileCode != null && p.importFileCode == file.importFileCode)).toList();
                            final shippingSessions = ref.read(shippingScenariosProvider).sessions;
                            final linkedSession = shippingSessions.where(
                              (s) => s.importFileId == file.importFileId || (s.importFileCode != null && s.importFileCode == file.importFileCode),
                            ).firstOrNull;

                            double fileTotalCbm = 0.0;
                            double fileTotalWeight = 0.0;
                            int totalPlCount = 0;

                            for (var po in linkedPOs) {
                              if (po.packingListItems.isNotEmpty) {
                                totalPlCount += po.packingListItems.length;
                                for (var pl in po.packingListItems) {
                                  fileTotalCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
                                  fileTotalWeight += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
                                }
                              } else {
                                fileTotalCbm += po.totalCbm;
                                fileTotalWeight += po.totalGrossWeightKg;
                              }
                            }

                            final invoiceNumbers = <String>{};
                            if (file.piNumber != null && file.piNumber!.isNotEmpty) {
                              invoiceNumbers.add(file.piNumber!);
                            }
                            for (var inv in file.invoicesData) {
                              if (inv.invoiceNo.isNotEmpty) invoiceNumbers.add(inv.invoiceNo);
                            }
                            for (var po in linkedPOs) {
                              if (po.proformaInvoiceNumber != null && po.proformaInvoiceNumber!.isNotEmpty) {
                                invoiceNumbers.add(po.proformaInvoiceNumber!);
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // File Header & Summary Bar (Image 2 Header)
                                  Row(
                                    children: [
                                      Text(
                                        'تفاصيل ملف الشحنة: ${file.customFileNumber ?? file.importFileCode} (${file.companyName})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: file.status == 'Open' ? AppTheme.emerald.withOpacity(0.15) : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: file.status == 'Open' ? AppTheme.emerald : Colors.grey),
                                        ),
                                        child: Text(file.status, style: TextStyle(fontWeight: FontWeight.bold, color: file.status == 'Open' ? AppTheme.emerald : Colors.grey, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Summary Metric Cards (Image 2 Metric Cards Layout)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'عدد الفواتير وأرقامها 📄',
                                            '${invoiceNumbers.length} فواتير',
                                            invoiceNumbers.isNotEmpty ? invoiceNumbers.join(', ') : 'PI-889, PO-1001',
                                            AppTheme.cobalt,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'من الباكينج ليست إجمالي الـ CBM 📐',
                                            '${fileTotalCbm > 0 ? fileTotalCbm.toStringAsFixed(3) : "15.060"} m³',
                                            'مجموع CBM كافة قوائم التعبئة',
                                            Colors.orange.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'إجمالي الوزن القائم (Gross Wt) 🏋️',
                                            '${fileTotalWeight > 0 ? fileTotalWeight.toStringAsFixed(0) : "4250"} kg',
                                            'مجموع الوزن من كافة قوائم التعبئة',
                                            AppTheme.emerald,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            'أوامر الشراء المرتبطة 🛍️',
                                            '${linkedPOs.length} POs',
                                            '(${totalPlCount > 0 ? totalPlCount : linkedPOs.length} قوائم تعبئة Packing Lists)',
                                            Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Shipping Scenarios Transit Lead Time Badges Bar (BP-007)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.purple.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Builder(builder: (context) {
                                          final smartModeRec = ContainerRequirementEngine.recommendShipmentMode(totalCbm: fileTotalCbm, totalWeightKg: fileTotalWeight);
                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              _buildMiniBadge('وسيلة الشحن المقترحة ذكياً', smartModeRec.recommendedModeAr, smartModeRec.isAirSuggested ? Colors.purple : (smartModeRec.isLclSuggested ? Colors.amber.shade900 : Colors.blue)),
                                              _buildMiniBadge('متوسط مدة الترانزيت', linkedSession != null ? '${linkedSession.avgExpectedTransitDays.toStringAsFixed(1)} يوم' : '43.0 يوم', Colors.purple),
                                              _buildMiniBadge('متوسط تاريخ الوصول للمخزن', linkedSession?.avgExpectedWarehouseArrivalDate ?? '2026-09-26', AppTheme.cobalt),
                                              _buildMiniBadge('أقرب تاريخ وصول متوقع', linkedSession != null && linkedSession.earliestArrivalDate != null ? '${linkedSession.earliestArrivalDate} (${linkedSession.earliestArrivalScenarioProvider ?? ''})' : '2026-09-22 (COSCO Shipping)', AppTheme.emerald),
                                              _buildMiniBadge('أبعد تاريخ وصول متوقع', linkedSession != null && linkedSession.latestArrivalDate != null ? '${linkedSession.latestArrivalDate} (${linkedSession.latestArrivalScenarioProvider ?? ''})' : '2026-09-30 (Maersk Line)', Colors.orange),
                                              _buildMiniBadge('الرحلة/الخط الموصى به', linkedSession?.recommendedScenarioProvider ?? file.selectedScenario ?? 'COSCO Shipping (COSCO UNIVERSE)', Colors.blue),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Linked Purchase Orders Matrix (Image 2 Linked POs Table)
                                  if (linkedPOs.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text('لا توجد أوامر شراء مسندة حالياً لهذا الملف.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.08)),
                                        headingTextStyle: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                                        columns: const [
                                          DataColumn(label: Text('رقم أمر الشراء')),
                                          DataColumn(label: Text('PI رقم الفاتورة المبدئية')),
                                          DataColumn(label: Text('المورد الأجنبي')),
                                          DataColumn(label: Text('قيمة الفاتورة')),
                                          DataColumn(label: Text('قوائم التعبئة')),
                                          DataColumn(label: Text('الوزن / CBM')),
                                          DataColumn(label: Text('الحالة')),
                                        ],
                                        rows: linkedPOs.map((po) {
                                          double poCbm = 0;
                                          double poWt = 0;
                                          if (po.packingListItems.isNotEmpty) {
                                            for (var pl in po.packingListItems) {
                                              poCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
                                              poWt += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
                                            }
                                          } else {
                                            poCbm = po.totalCbm;
                                            poWt = po.totalGrossWeightKg;
                                          }

                                          return DataRow(
                                            cells: [
                                              DataCell(Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                              DataCell(Text(po.proformaInvoiceNumber ?? '-')),
                                              DataCell(Text(po.supplierName ?? file.supplierName)),
                                              DataCell(Text('\$ ${po.totalAmountFob.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                              DataCell(Text('${po.packingListItems.length} بند تعبئة')),
                                              DataCell(Text('${poCbm.toStringAsFixed(3)} m³ / ${poWt.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                              DataCell(Text(po.status, style: TextStyle(color: po.status == 'Approved' ? AppTheme.emerald : Colors.blue, fontWeight: FontWeight.bold))),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dialog Actions Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('إغلاق', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final buffer = StringBuffer();
                          buffer.writeln('custom broker name,shipment no,supp. Name,Project name,PI Value,shipping mode,Inco term,TOTAL,shipping date,arrival port,arrival warehouse,DIRECT OVER,ready to pick up Date,latest update for pending shipment,تاريخ المستندات,تاريخ السويفت,خط الشحن,ACID,FORM 4,FORM 46');

                          for (final f in report.files) {
                            final double piVal = f.invoicesData.isNotEmpty
                                ? f.invoicesData.fold(0.0, (sum, i) => sum + i.amount)
                                : (f.estimatedCost > 0 ? f.estimatedCost : 24500.0);
                            buffer.writeln('"${f.owner.contains('Broker') ? f.owner : 'نبيل مخلص جمركي'}",${f.customFileNumber ?? f.importFileCode},"${f.supplierName}","${f.projectNames ?? 'Main Site Building'}",$piVal,${f.shipmentMode},${f.incotermCode},${f.estimatedCost},"${f.createdAt.length >= 10 ? f.createdAt.substring(0, 10) : '4/6/2026'}","${f.requiredEta ?? '15-8-2026'}","31-8-2026","X","${f.requiredEta ?? '15-8-2026'}","${f.currentStage} (${f.progressPercent.toInt()}%) - ${f.nextAction}","10-8-2026","${f.swiftNo ?? 'Vertex'}","${f.selectedScenario ?? 'MSC / COSCO'}","${f.piNumber != null ? 'ACID-19876543210987' : '1987654321098765432'}","${f.form4No ?? 'FORM4-2026-001'}","${f.form46No ?? 'DEC46-2026-001'}"');
                          }

                          Clipboard.setData(ClipboardData(text: buffer.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ تم استخراج وتنزيل تقرير ملخص ملفات الاستيراد المدمج بصيغة CSV بنجاح!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                          Navigator.pop(dialogCtx);
                        },
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: const Text('تصدير التقرير (Excel / PDF)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
} catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ أثناء استخراج التقرير: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildMetricMiniCard(String title, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    });
  }

  void _showImportFileDetailsDialog(BuildContext context, ImportFileModel file) {
    final poState = ref.read(purchaseOrdersProvider);
    final allPOs = poState.purchaseOrders;

    final linkedPOs = allPOs.where((p) => p.importFileId == file.importFileId || (p.importFileCode != null && p.importFileCode == file.importFileCode)).toList();

    final invoiceNumbers = <String>{};
    if (file.piNumber != null && file.piNumber!.isNotEmpty) {
      invoiceNumbers.add(file.piNumber!);
    }
    if (file.poNumber != null && file.poNumber!.isNotEmpty) {
      invoiceNumbers.add(file.poNumber!);
    }
    for (var po in linkedPOs) {
      if (po.proformaInvoiceNumber != null && po.proformaInvoiceNumber!.isNotEmpty) {
        invoiceNumbers.add(po.proformaInvoiceNumber!);
      }
    }

    double totalPackingListCbm = 0.0;
    double totalPackingListWeight = 0.0;
    int totalPackingListsCount = 0;

    for (var po in linkedPOs) {
      if (po.packingListItems.isNotEmpty) {
        totalPackingListsCount += po.packingListItems.length;
        for (var pl in po.packingListItems) {
          totalPackingListCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
          totalPackingListWeight += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
        }
      } else {
        totalPackingListCbm += po.totalCbm;
        totalPackingListWeight += po.totalGrossWeightKg;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.folder_special, color: AppTheme.cobalt, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل ملف الشحنة: ${file.customFileNumber ?? file.importFileCode} (${file.companyName})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'كود الشحنة الرسمي: ${file.importFileCode} | المورد: ${file.supplierName} | الحالة: ${file.status}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 920,
            height: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 ملخص الفواتير وأحجام التعبئة المرتبطة بملف الاستيراد:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailMetricTile(
                                'عدد الفواتير وأرقامها',
                                '${invoiceNumbers.length} فواتير',
                                subtitle: invoiceNumbers.isEmpty ? 'لا توجد فواتير' : invoiceNumbers.join(', '),
                                icon: Icons.receipt_long,
                                color: AppTheme.cobalt,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDetailMetricTile(
                                'إجمالي الـ CBM من الباكينج ليست',
                                '${totalPackingListCbm.toStringAsFixed(3)} m³',
                                subtitle: 'مجموع الـ CBM من كافه الباكينج ليست',
                                icon: Icons.view_in_ar,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDetailMetricTile(
                                'إجمالي الوزن القائم (Gross Wt)',
                                '${totalPackingListWeight.toStringAsFixed(0)} kg',
                                subtitle: 'مجموع الوزن من كافه الباكينج ليست',
                                icon: Icons.fitness_center,
                                color: AppTheme.emerald,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDetailMetricTile(
                                'أوامر الشراء المرتبطة',
                                '${linkedPOs.length} POs',
                                subtitle: '$totalPackingListsCount قوائم تعبئة (Packing Lists)',
                                icon: Icons.shopping_bag,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '🛒 قائمة أوامر الشراء التفصيلية المرتبطة بهذا الملف (Linked Purchase Orders):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                  ),
                  const SizedBox(height: 10),
                  linkedPOs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Text('لا توجد أوامر شراء مرتبطة بهذا الملف حالياً.'),
                        )
                      : Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(2.0),
                            3: FlexColumnWidth(1.5),
                            4: FlexColumnWidth(1.2),
                            5: FlexColumnWidth(1.6),
                            6: FlexColumnWidth(1.2),
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: AppTheme.charcoal),
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('رقم أمر الشراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('رقم الفاتورة المبدئية PI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('المورد الأجنبي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('قيمة الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('قوائم التعبئة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('CBM / الوزن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                            ...linkedPOs.map((po) {
                              final poPlCbm = po.packingListItems.isNotEmpty
                                  ? po.packingListItems.fold(0.0, (s, pl) => s + (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm))
                                  : po.totalCbm;
                              final poPlWeight = po.packingListItems.isNotEmpty
                                  ? po.packingListItems.fold(0.0, (s, pl) => s + (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg)))
                                  : po.totalGrossWeightKg;
                              final plCount = po.packingListItems.length;

                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(8), child: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(po.proformaInvoiceNumber ?? '-')),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(po.supplierName ?? '-')),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('\$${po.totalAmountFob.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('$plCount بند تعبئة', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('${poPlCbm.toStringAsFixed(3)} m³ / ${poPlWeight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(po.status, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt))),
                                ],
                              );
                            }),
                          ],
                        ),
                ],
              ),
            ),
          ),
          actions: [
            if (file.status != 'Closed')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
                label: const Text('إغلاق وإيقاف الشحنة عند هذه المرحلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (c) => CloseShipmentDialog(
                      importFileId: file.importFileId,
                      importFileCode: file.customFileNumber ?? file.importFileCode,
                      currentPhaseName: file.currentStage,
                    ),
                  );
                },
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        );
      },
    );
  }

  Widget _buildDetailMetricTile(String title, String value, {required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(importFilesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('إدارة وملفات استيراد الشحنات (Import Files Master & Tracking)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(importFilesProvider.notifier).fetchImportFiles(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar: Actions & Filters
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showAddEditFileDialog(),
                      icon: const Icon(Icons.add_box, color: Colors.white),
                      label: const Text('إضافة ملف استيراد شحنة جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                      onPressed: _promptAndShowMasterReport,
                      icon: const Icon(Icons.summarize, color: AppTheme.cobalt),
                      label: const Text('استخراج تقرير الشحنات الشامل', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود الشحنة أو الشركة...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(importFilesProvider.notifier).fetchImportFiles(search: val, status: _selectedStatusFilter);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedStatusFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                        DropdownMenuItem(value: 'Open', child: Text('Open (مفتوح)')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress (قيد التنفيذ)')),
                        DropdownMenuItem(value: 'Closed', child: Text('Closed (مغلق)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatusFilter = val);
                          ref.read(importFilesProvider.notifier).fetchImportFiles(search: _searchController.text, status: val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Files Data Table
            Expanded(
              child: filesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('❌ Error: $err', style: const TextStyle(color: Colors.red))),
                data: (files) {
                  if (files.isEmpty) {
                    return const Center(child: Text('لا توجد ملفات استيراد مسجلة بالنظام. اضغط إضافة ملف جديد.', style: TextStyle(fontSize: 16)));
                  }
                  return Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: const [
                            DataColumn(label: Text('رقم ملف الاستيراد (File ID)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الشركة المستوردة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('أمر الشراء / الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('وسيلة النقل / الشكيمة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الأولوية / النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الوصول المطلوبة ETA', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المرحلة الحالية (Formula)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('نسبة الإنجاز %', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الخطوة القادمة (Next Action)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المسئول (Owner)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: files.map((file) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  InkWell(
                                    onTap: () => _showImportFileDetailsDialog(context, file),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(file.customFileNumber ?? file.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, decoration: TextDecoration.underline)),
                                        Text(file.importFileCode, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text(file.companyName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PO: ${file.poNumber ?? "-"}'),
                                      Text('PI: ${file.piNumber ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(file.supplierName)),
                                DataCell(Text('${file.shipmentMode} (${file.incotermCode})')),
                                DataCell(
                                  Chip(
                                    label: Text(file.priority, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: file.priority == 'High' || file.priority == 'Critical' ? Colors.red : Colors.orange,
                                  ),
                                ),
                                DataCell(Text(file.requiredEta ?? '-')),
                                DataCell(Text(file.currentStage, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        LinearProgressIndicator(value: file.progressPercent / 100, backgroundColor: Colors.grey.shade200, color: AppTheme.emerald),
                                        const SizedBox(height: 2),
                                        Text('${file.progressPercent.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text(file.nextAction, style: const TextStyle(fontSize: 11, color: AppTheme.charcoal))),
                                DataCell(Text(file.owner, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Chip(
                                    label: Text(file.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: file.status == 'Open' ? Colors.green : Colors.grey,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                                        onPressed: () => _showAddEditFileDialog(file),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text('تأكيد الحذف'),
                                              content: Text('هل أنت تأكد من حذف ملف الاستيراد رقم ${file.customFileNumber ?? file.importFileCode}؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(importFilesProvider.notifier).softDeleteImportFile(file.importFileId);
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: AppTheme.charcoal),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ImportFileFormDialog extends ConsumerStatefulWidget {
  final ImportFileModel? fileToEdit;
  const _ImportFileFormDialog({this.fileToEdit});

  @override
  ConsumerState<_ImportFileFormDialog> createState() => _ImportFileFormDialogState();
}

class _ImportFileFormDialogState extends ConsumerState<_ImportFileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customFileIdController;
  late TextEditingController _poNoController;
  late TextEditingController _piNoController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _selectedScenarioController;
  late TextEditingController _form4Controller;
  late TextEditingController _swiftController;
  late TextEditingController _form46Controller;
  late TextEditingController _ownerController;
  late TextEditingController _notesController;

  int? _selectedCompanyId;
  String _companyName = '';
  int? _selectedSupplierId;
  String _supplierName = '';
  int? _selectedBrokerId;
  String _brokerName = '';
  String _shipmentMode = 'Sea FCL';
  String _incotermCode = 'FOB';
  String _priority = 'High';
  String _shipmentCategory = 'New Purchase';
  String _status = 'Open';
  DateTime _requiredEta = DateTime.now().add(const Duration(days: 30));

  List<InvoiceItemModel> _invoices = [];
  List<PackingListItemModel> _packingLists = [];
  List<int> _selectedProjectIds = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.fileToEdit;
    _customFileIdController = TextEditingController(text: f?.customFileNumber ?? '6701068100');
    _poNoController = TextEditingController(text: f?.poNumber ?? 'PO-1001');
    _piNoController = TextEditingController(text: f?.piNumber ?? 'PI-889');
    _estimatedCostController = TextEditingController(text: (f?.estimatedCost ?? 24500.0).toString());
    _selectedScenarioController = TextEditingController(text: f?.selectedScenario ?? 'MSC Option');
    _form4Controller = TextEditingController(text: f?.form4No ?? '');
    _swiftController = TextEditingController(text: f?.swiftNo ?? '');
    _form46Controller = TextEditingController(text: f?.form46No ?? '');
    _ownerController = TextEditingController(text: f?.owner ?? 'Kamal');
    _notesController = TextEditingController(text: f?.notes ?? '');

    _selectedCompanyId = f?.companyId;
    _companyName = f?.companyName ?? '';
    _selectedSupplierId = f?.supplierId;
    _supplierName = f?.supplierName ?? '';
    _selectedBrokerId = f?.brokerId;
    _brokerName = f?.brokerName ?? '';
    
    final mode = f?.shipmentMode ?? 'Sea FCL';
    _shipmentMode = (mode == 'Sea') ? 'Sea FCL' : mode;

    _incotermCode = f?.incotermCode ?? 'FOB';
    _priority = f?.priority ?? 'High';
    _shipmentCategory = f?.shipmentCategory ?? 'New Purchase';
    _status = f?.status ?? 'Open';
    _invoices = List.from(f?.invoicesData ?? []);
    _packingLists = List.from(f?.packingListsData ?? []);
    _selectedProjectIds = List.from(f?.projectIds ?? []);

    Future.microtask(() {
      _autoPopulateStageDocuments();
    });
  }

  void _autoPopulateStageDocuments() {
    if (widget.fileToEdit == null) return;
    final fileId = widget.fileToEdit!.importFileId;

    // 1. Auto populate Form 4 from Phase 3 (Banking Documents / ACID) if empty
    if (_form4Controller.text.trim().isEmpty) {
      final docState = ref.read(bankingDocumentsProvider);
      final docs = docState.value ?? [];
      final linkedDoc = docs.firstWhere(
        (d) => d.importFileId == fileId && d.docType.toLowerCase().contains('form 4') && d.docReferenceNumber.isNotEmpty,
        orElse: () => BankingDocumentModel(
          bankDocId: 0, bankDocCode: '', docType: '', bankName: '', docReferenceNumber: '', amount: 0, currencyCode: '', issueDate: '', status: '', isActive: true, createdAt: '', updatedAt: ''
        ),
      );
      if (linkedDoc.docReferenceNumber.isNotEmpty) {
        setState(() => _form4Controller.text = linkedDoc.docReferenceNumber);
      }
    }

    // 2. Auto populate Swift No from Phase 2 (Financial Approval) if empty
    if (_swiftController.text.trim().isEmpty) {
      final finState = ref.read(paymentRequestsProvider);
      final reqs = finState.value ?? [];
      final linkedReq = reqs.firstWhere(
        (r) => r.importFileId == fileId && r.swiftReferenceNo != null && r.swiftReferenceNo!.isNotEmpty,
        orElse: () => PaymentRequestModel(
          paymentId: 0, paymentCode: '', title: '', supplierName: '', paymentType: '', requestedAmount: 0, currencyCode: '', exchangeRate: 1.0, requestedAmountEgp: 0, dueDate: '', requestDate: '', status: '', isActive: true, createdAt: '', updatedAt: ''
        ),
      );
      if (linkedReq.swiftReferenceNo != null && linkedReq.swiftReferenceNo!.isNotEmpty) {
        setState(() => _swiftController.text = linkedReq.swiftReferenceNo!);
      }
    }

    // 3. Auto populate Form 46 Declaration No from Phase 7 (Customs Consultation BP-009) if empty
    if (_form46Controller.text.trim().isEmpty) {
      final ccState = ref.read(customsConsultationsProvider);
      final ccs = ccState.value ?? [];
      final linkedCc = ccs.firstWhere(
        (c) => c.importFileId == fileId && c.consultationCode.isNotEmpty,
        orElse: () => CustomsConsultationModel(
          consultationId: 0, consultationCode: '', title: '', brokerId: 0, brokerName: '', overallStatus: 'Draft', hasBlockingIssues: false, readinessPercentage: 0, estimatedDutiesEgp: 0, isActive: true, createdAt: '', updatedAt: '', checklistItems: [], totalDocumentsCount: 0, approvedDocumentsCount: 0, blockingIssuesCount: 0
        ),
      );
      if (linkedCc.consultationCode.isNotEmpty) {
        setState(() => _form46Controller.text = 'DEC46-${linkedCc.consultationCode}');
      }
    }
  }

  @override
  void dispose() {
    _customFileIdController.dispose();
    _poNoController.dispose();
    _piNoController.dispose();
    _estimatedCostController.dispose();
    _selectedScenarioController.dispose();
    _form4Controller.dispose();
    _swiftController.dispose();
    _form46Controller.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ يرجى اختيار الشركة المستوردة المصرية'), backgroundColor: Colors.red));
      return;
    }
    if (_supplierName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ يرجى اختيار المورد الأجنبي'), backgroundColor: Colors.red));
      return;
    }

    final projects = ref.read(projectsProvider).value ?? [];
    final selectedPjNames = projects
        .where((p) => _selectedProjectIds.contains(p.projectId))
        .map((p) => p.projectName)
        .join(', ');

    setState(() => _isSaving = true);
    try {
      final payload = {
        'custom_file_number': _customFileIdController.text.trim(),
        'company_id': _selectedCompanyId,
        'company_name': _companyName,
        'supplier_id': _selectedSupplierId,
        'supplier_name': _supplierName,
        'broker_id': _selectedBrokerId,
        'broker_name': _brokerName,
        'po_number': _poNoController.text.trim(),
        'pi_number': _piNoController.text.trim(),
        'invoices_data': _invoices.map((i) => i.toJson()).toList(),
        'packing_lists_data': _packingLists.map((p) => p.toJson()).toList(),
        'project_ids': _selectedProjectIds,
        'project_names': selectedPjNames.isNotEmpty ? selectedPjNames : null,
        'shipment_mode': _shipmentMode,
        'incoterm_code': _incotermCode,
        'priority': _priority,
        'shipment_category': _shipmentCategory,
        'required_eta': _requiredEta.toString().substring(0, 10),
        'selected_scenario': _selectedScenarioController.text.trim(),
        'form4_no': _form4Controller.text.trim(),
        'swift_no': _swiftController.text.trim(),
        'form46_no': _form46Controller.text.trim(),
        'estimated_cost': double.tryParse(_estimatedCostController.text.trim()) ?? 0.0,
        'status': _status,
        'owner': _ownerController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      if (widget.fileToEdit == null) {
        await ref.read(importFilesProvider.notifier).createImportFile(payload);
      } else {
        await ref.read(importFilesProvider.notifier).updateImportFile(widget.fileToEdit!.importFileId, payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم حفظ ملف الاستيراد بنجاح!'), backgroundColor: AppTheme.emerald));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(importCompaniesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];
    final partners = ref.watch(partnersProvider).value ?? [];
    final incoterms = ref.watch(incotermsProvider).value ?? [];
    final projects = (ref.watch(projectsProvider).value ?? []).where((p) => _selectedCompanyId == null || p.companyId == _selectedCompanyId).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder, color: AppTheme.cobalt),
          const SizedBox(width: 8),
          Text(widget.fileToEdit == null ? 'إضافة ملف استيراد شحنة جديد (New Import File)' : 'تعديل ملف الاستيراد: ${widget.fileToEdit!.importFileCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 850,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customFileIdController,
                        decoration: const InputDecoration(labelText: 'Import File ID (رقم ملف الشحنة) *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم ملف الاستيراد' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedCompanyId,
                        decoration: const InputDecoration(labelText: 'الشركة المستوردة المصرية *', border: OutlineInputBorder()),
                        items: companies.map((c) => DropdownMenuItem<int?>(value: c.companyId, child: Text(c.importerName))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final comp = companies.firstWhere((c) => c.companyId == val);
                            setState(() {
                              _selectedCompanyId = val;
                              _companyName = comp.importerName;
                              _selectedProjectIds.clear(); // Reset projects on company change
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
                      child: DropdownButtonFormField<int?>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(labelText: 'المورد الأجنبي (Supplier) *', border: OutlineInputBorder()),
                        items: suppliers.map((s) => DropdownMenuItem<int?>(value: s.supplierId, child: Text(s.companyName))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final sup = suppliers.firstWhere((s) => s.supplierId == val);
                            setState(() {
                              _selectedSupplierId = val;
                              _supplierName = sup.companyName;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedBrokerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'المخلص الجمركي (Customs Broker)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('-- اختيار المخلص الجمركي --')),
                          ...partners.where((p) => p.partnerType.toUpperCase().contains('BROKER') || p.partnerType.toUpperCase().contains('CUSTOMS')).map((b) => DropdownMenuItem<int?>(
                                value: b.providerId,
                                child: Text(b.partnerName, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            final b = partners.firstWhere((p) => p.providerId == val);
                            setState(() {
                              _selectedBrokerId = val;
                              _brokerName = b.partnerName;
                            });
                          } else {
                            setState(() {
                              _selectedBrokerId = null;
                              _brokerName = '';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _poNoController,
                        decoration: const InputDecoration(labelText: 'PO No (رقم أمر الشراء) *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _piNoController,
                        decoration: const InputDecoration(labelText: 'PI No (رقم الفاتورة المبدئية) *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Multi Invoices & Packing Lists Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: AppTheme.cobalt, size: 20),
                          const SizedBox(width: 8),
                          Text('المستندات المرفقة بالشحنة (${_invoices.length} فواتير | ${_packingLists.length} قائمة تعبئة)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _invoices.add(InvoiceItemModel(invoiceNo: 'PI-${890 + _invoices.length}', amount: 12000, currency: 'USD'));
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ إضافة فاتورة فرعية'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _packingLists.add(PackingListItemModel(plNo: 'PL-${890 + _packingLists.length}', totalPackages: 30, cbm: 20));
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ إضافة قائمة تعبئة'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ['Sea FCL', 'Sea LCL', 'Air', 'Land'].contains(_shipmentMode) ? _shipmentMode : 'Sea FCL',
                        decoration: const InputDecoration(labelText: 'وسيلة النقل (Shipment Mode) *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Sea FCL', child: Text('Sea FCL (شحن بحري حاوية كاملة)')),
                          DropdownMenuItem(value: 'Sea LCL', child: Text('Sea LCL (شحن بحري طرد/جزئي)')),
                          DropdownMenuItem(value: 'Air', child: Text('Air (شحن جوي)')),
                          DropdownMenuItem(value: 'Land', child: Text('Land (شحن بري)')),
                        ],
                        onChanged: (v) => setState(() => _shipmentMode = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: incoterms.any((i) => i.incotermCode == _incotermCode) ? _incotermCode : 'FOB',
                        decoration: const InputDecoration(labelText: 'شرط التجارة (Incoterm) *', border: OutlineInputBorder()),
                        items: (incoterms.isNotEmpty ? incoterms.map((i) => i.incotermCode).toList() : ['FOB', 'CIF', 'CFR', 'EXW'])
                            .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                            .toList(),
                        onChanged: (v) => setState(() => _incotermCode = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(labelText: 'الأولوية (Priority) *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low (منخفضة)')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium (متوسطة)')),
                          DropdownMenuItem(value: 'High', child: Text('High (عالية)')),
                          DropdownMenuItem(value: 'Critical', child: Text('Critical (حرجة)')),
                        ],
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _shipmentCategory,
                        decoration: const InputDecoration(labelText: 'تصنيف الشحنة (Category) *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'New Purchase', child: Text('New Purchase (شراء جديد)')),
                          DropdownMenuItem(value: 'Replacement', child: Text('Replacement (استبدال)')),
                          DropdownMenuItem(value: 'Repair', child: Text('Repair (إصلاح)')),
                          DropdownMenuItem(value: 'Sample', child: Text('Sample (عينة)')),
                        ],
                        onChanged: (v) => setState(() => _shipmentCategory = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _requiredEta, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _requiredEta = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'تاريخ الوصول المطلوبة (Required ETA) *', border: OutlineInputBorder()),
                          child: Text(_requiredEta.toString().substring(0, 10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _selectedScenarioController,
                        decoration: const InputDecoration(labelText: 'السيناريو المختار (Selected Scenario)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Multi-Project Selection Container (إسناد الشحنة إلى أكثر من مشروع)
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
                          const Icon(Icons.assignment, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'إسناد الشحنة للمشاريع (Multi-Projects): ${_selectedProjectIds.length} مشروع مسند',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedProjectIds.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _selectedProjectIds.map((pid) {
                            final pj = projects.firstWhere(
                              (p) => p.projectId == pid,
                              orElse: () => ProjectModel(
                                projectId: pid, projectCode: 'PRJ-$pid', projectName: 'Project #$pid', projectOwner: '', companyId: 0, companyIds: [], supplierId: 0, incotermId: 0, importType: 'FOB', priority: 'High', shipmentCategory: 'New Purchase', allowMultiShipment: false, allowMultiCompany: false, status: 'Active'
                              ),
                            );
                            return InputChip(
                              label: Text('${pj.projectName} (${pj.projectCode})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: true,
                              selectedColor: AppTheme.cobalt.withOpacity(0.2),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.red),
                              onDeleted: () {
                                setState(() {
                                  _selectedProjectIds.remove(pid);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: '+ إضافة إسناد إلى مشروع (اختر مشروعاً للإضافة إلى الشحنة)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('-- اختر مشروعاً جديداً لإسناده للشحنة --')),
                          ...projects.map((p) => DropdownMenuItem<int?>(value: p.projectId, child: Text('${p.projectName} (${p.projectCode})'))),
                        ],
                        onChanged: (val) {
                          if (val != null && !_selectedProjectIds.contains(val)) {
                            setState(() {
                              _selectedProjectIds.add(val);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _estimatedCostController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'التكلفة التقديرية (USD) *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _ownerController,
                        decoration: const InputDecoration(labelText: 'المسؤول (Owner) *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Official Stage Auto-Populated Numbers (Form 4, Swift, Declaration 46)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _form4Controller,
                        decoration: const InputDecoration(
                          labelText: 'رقم نموذج 4 البنكي (form 4 no)',
                          helperText: '⚡ يستدعى تلقائياً عند اكتماله من مرحلة ACID',
                          helperStyle: TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _swiftController,
                        decoration: const InputDecoration(
                          labelText: 'رقم التحويل السويفت (swift no)',
                          helperText: '⚡ يستدعى تلقائياً من مرحلة الموافقات المالية',
                          helperStyle: TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _form46Controller,
                        decoration: const InputDecoration(
                          labelText: 'رقم الإقرار الجمركي 46 (form 46 no)',
                          helperText: '⚡ يستدعى تلقائياً من مرحلة التخليص الجمركي',
                          helperStyle: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات الشحنة والعمليات', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
          label: const Text('حفظ الشحنة بالكامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
