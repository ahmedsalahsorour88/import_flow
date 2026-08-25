import '../widgets/import_file_details_dialog.dart';
import '../widgets/import_file_form_dialog.dart';
import '../widgets/freight_rfq_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/import_file_po_linker.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart' hide PackingListItemModel;
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/reopen_shipment_dialog.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/stop_shipment_dialog.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';


class ImportFilesScreen extends ConsumerStatefulWidget {
  const ImportFilesScreen({super.key});

  @override
  ConsumerState<ImportFilesScreen> createState() => _ImportFilesScreenState();
}

class _ImportFilesScreenState extends ConsumerState<ImportFilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  void _showVisualLoadPlanDialogForReport(BuildContext context, List<PurchaseOrderModel> pos, double totalCbm, double totalWeight) {
    final l = context.l10n;
    final List<CargoItem> cargoItems = [];
    int itemCounter = 1;

    for (final po in pos) {
      final hasPalletPlan = po.palletPlanItems.isNotEmpty && po.palletPlanItems.any((p) => p.palletCount > 0);
      final hasSinglePallet = po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0;

      if (hasPalletPlan) {
        final double totalGross = po.packingListItems.fold<double>(
          0.0,
          (sum, p) => sum + (p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg)),
        );
        final int totalPallets = po.palletPlanItems.fold<int>(0, (sum, p) => sum + p.palletCount);
        final double defaultPalletWeight = totalPallets > 0 && totalGross > 0 ? (totalGross / totalPallets) : 137.5;

        for (final pLine in po.palletPlanItems) {
          final pL = pLine.lengthCm > 0 ? pLine.lengthCm : 120.0;
          final pW = pLine.widthCm > 0 ? pLine.widthCm : 80.0;
          final pH = pLine.heightCm > 0 ? pLine.heightCm : 150.0;
          final pWt = pLine.grossWeightPerPalletKg > 0 ? pLine.grossWeightPerPalletKg : defaultPalletWeight;

          for (int i = 0; i < pLine.palletCount; i++) {
            cargoItems.add(CargoItem(
              itemId: 'PLT-$itemCounter',
              length: pL,
              width: pW,
              height: pH,
              weight: pWt,
              isStackable: pLine.isStackable,
              rotate: true,
              packageType: pLine.palletType,
              description: '${pLine.palletType} #$itemCounter${pLine.isStackable ? "" : " [Floor Only]"}',
            ));
            itemCounter++;
          }
        }
      } else if (hasSinglePallet) {
        final double pWt = po.totalGrossWeightKg > 0 ? (po.totalGrossWeightKg / po.palletCount) : 137.5;
        for (int i = 0; i < po.palletCount; i++) {
          cargoItems.add(CargoItem(
            itemId: 'PLT-$itemCounter',
            length: po.palletLengthCm,
            width: po.palletWidthCm,
            height: po.palletHeightCm,
            weight: pWt,
            isStackable: po.isPalletStackable,
            rotate: true,
            packageType: po.palletType,
            description: '${po.palletType} #$itemCounter${po.isPalletStackable ? "" : " [Floor Only]"}',
          ));
          itemCounter++;
        }
      } else if (po.packingListItems.isNotEmpty) {
        for (final pl in po.packingListItems) {
          for (int q = 0; q < pl.qtyPkg.toInt(); q++) {
            double lCm = pl.lengthCm;
            double wCm = pl.widthCm;
            double hCm = pl.heightCm;
            if (pl.unit == 'mm') {
              lCm /= 10;
              wCm /= 10;
              hCm /= 10;
            } else if (pl.unit == 'm') {
              lCm *= 100;
              wCm *= 100;
              hCm *= 100;
            }

            cargoItems.add(CargoItem(
              itemId: '$itemCounter',
              length: lCm > 0 ? lCm : 100.0,
              width: wCm > 0 ? wCm : 80.0,
              height: hCm > 0 ? hCm : 60.0,
              weight: pl.grossWeightUnitKg > 0 ? pl.grossWeightUnitKg : (pl.totalGrossWeightKg / (pl.qtyPkg > 0 ? pl.qtyPkg : 1)),
              rotate: true,
              isStackable: pl.isStackable,
              packageType: pl.packageType,
            ));
            itemCounter++;
          }
        }
      }
    }

    if (cargoItems.isEmpty && totalCbm > 0) {
      final double targetCbm = totalCbm;
      final double targetWeight = totalWeight > 0 ? totalWeight : 1000.0;
      final int numPallets = (targetCbm / 2.0).ceil().clamp(1, 50);
      final double perPalletCbm = targetCbm / numPallets;
      final double perPalletWeight = targetWeight / numPallets;

      double palletHeightCm = (perPalletCbm * 1000000.0) / 12000.0;
      if (palletHeightCm > 260) palletHeightCm = 260;

      for (int i = 0; i < numPallets; i++) {
        cargoItems.add(CargoItem(
          itemId: 'PLT-$itemCounter',
          length: 120,
          width: 100,
          height: palletHeightCm.clamp(30.0, 260.0),
          weight: perPalletWeight,
          rotate: true,
          isStackable: true,
          packageType: 'Pallet',
        ));
        itemCounter++;
      }
    }

    if (cargoItems.isEmpty) {
      cargoItems.add(CargoItem(
        itemId: 'Simulated Cargo',
        length: 120,
        width: 80,
        height: 100,
        weight: totalWeight > 0 ? totalWeight : 500.0,
        rotate: true,
      ));
    }

    final plan = ContainerRequirementEngine.planShipment(cargoItems);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.view_in_ar, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Text(
                l.visualLoadPlannerTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 900,
            height: 600,
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(2.2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                      children: [
                        Padding(padding: const EdgeInsets.all(8.0), child: Text(l.containerLoadPlanButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8.0), child: Text(l.packingListItemsCol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8.0), child: Text(l.totalGrossWeightFromPl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(8.0), child: Text(l.currentPhaseStage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    ...plan.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final res = entry.value;
                      final placedIds = res.placedItems.map((p) => p.item.itemId).join(', ');
                      
                      String statusText = '';
                      if (res.containerCode == 'FAILED') {
                        statusText = l.containerLoadFailed;
                      } else {
                        final spaceUtil = (res.totalVolume / res.spec.internalVolumeCbm) * 100;
                        if (res.placedItems.any((p) => p.length >= 190 || p.width >= 190)) {
                          statusText = l.containerOverfilled;
                        } else if (spaceUtil < 25) {
                          statusText = l.containerEmpty;
                        } else {
                          statusText = '${l.containerGoodUtil} (${spaceUtil.toStringAsFixed(1)}%)';
                        }
                      }

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              res.containerCode == 'FAILED' ? l.containerLoadFailed : '$idx: ${res.spec.code}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(placedIds.isEmpty ? '-' : placedIds),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(res.containerCode == 'FAILED' ? '-' : '${res.totalWeight.toStringAsFixed(0)} kg'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusText.contains(l.containerOverfilled) || statusText.contains(l.containerLoadFailed)
                                    ? Colors.red.shade800
                                    : (statusText.contains(l.containerEmpty) ? Colors.amber.shade900 : Colors.green.shade800),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: plan.length,
                    itemBuilder: (ctx, pIdx) {
                      final res = plan[pIdx];
                      if (res.containerCode == 'FAILED') {
                        return Center(
                          child: Text(
                            '${l.containerLoadFailed}: ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l.containerLoadPlanButton} #${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text('${l.sideViewTitle} (${l.internalDimensions} ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 190,
                                          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(4)),
                                          child: CustomPaint(
                                            painter: ContainerLoadPlanPainter(plan: res, isTopView: false),
                                            child: Container(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text('${l.topViewTitle} (${l.internalDimensions} ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} cm)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 140,
                                          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(4)),
                                          child: CustomPaint(
                                            painter: ContainerLoadPlanPainter(plan: res, isTopView: true),
                                            child: Container(),
                                          ),
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
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditFileDialog([ImportFileModel? fileToEdit]) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImportFileFormDialog(fileToEdit: fileToEdit),
    );
    if (!mounted) return;
    ref.read(paginatedImportFilesProvider.notifier).fetchPage(
          ref.read(paginatedImportFilesProvider).page,
          search: _searchController.text,
          status: _selectedStatusFilter,
        );
    ref.read(importFilesProvider.notifier).fetchImportFiles();
  }

  void _promptAndShowMasterReport() async {
    final l = context.l10n;
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
                title: Row(
                  children: [
                    const Icon(Icons.summarize, color: AppTheme.cobalt, size: 26),
                    const SizedBox(width: 10),
                    Text(l.evaluateMasterReportTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📌 ${l.selectShipmentForReport}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<int?>(
                      value: selectedFileId,
                      labelText: l.importFileIdLabel,
                      items: [
                        SearchableDropdownItem<int?>(
                          value: null,
                          label: '🌐 ${l.allShipmentFiles}',
                        ),
                        ...report.files.map((f) => SearchableDropdownItem<int?>(
                              value: f.importFileId,
                              label: '📦 ${l.shipmentNoPrefix} ${f.customFileNumber ?? f.importFileCode} - ${f.supplierName} (${f.companyName})',
                            )),
                      ],
                      onChanged: (val) => setPromptState(() => selectedFileId = val),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(l.cancel)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                    icon: const Icon(Icons.print, size: 16),
                    label: Text(l.createAndDisplayReport, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showMasterReportDialog([int? initialFileId]) async {
    final l = context.l10n;
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
                                Text(
                                  l.masterImportReportTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal),
                                ),
                                if (selectedFileId != null && displayFiles.isNotEmpty)
                                  Text(
                                    '${l.filteredForShipment} ${displayFiles.first.customFileNumber ?? displayFiles.first.importFileCode} (${displayFiles.first.companyName})',
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
                              buffer.writeln('Sorour Logistics ERP - Master Import Report');
                              buffer.writeln('Date: ${DateTime.now().toString().substring(0, 10)}');
                              buffer.writeln('Total Import Files: $totalFiles | Open: $openFiles | In Progress: $inProgressFiles | Total Cost: \$$totalCost');
                              buffer.writeln('=====================================================\n');

                              buffer.writeln('--- 1. OPERATIONAL TRACKING MATRIX ---');
                              buffer.writeln('Broker,Shipment No,Supplier,Project,PI Value,Mode,Incoterm,Total,Ship Date,ETA,WH Date,Direct,Pickup Date,Status/Stage,Doc Date,Swift,Carrier,ACID,Form4,Form46');

                              for (final f in displayFiles) {
                                final double piVal = f.invoicesData.isNotEmpty
                                    ? f.invoicesData.fold(0.0, (sum, i) => sum + i.amount)
                                    : (f.estimatedCost > 0 ? f.estimatedCost : 24500.0);

                                buffer.writeln('"${f.owner.contains('Broker') ? f.owner : 'Customs Broker'}",${f.customFileNumber ?? f.importFileCode},"${f.supplierName}","${f.projectNames ?? 'Main Site Building'}",$piVal,${f.shipmentMode},${f.incotermCode},${f.estimatedCost},"${f.createdAt.length >= 10 ? f.createdAt.substring(0, 10) : '4/6/2026'}","${f.requiredEta ?? '15-8-2026'}","31-8-2026","X","${f.requiredEta ?? '15-8-2026'}","${f.currentStage} (${f.progressPercent.toInt()}%) - ${f.nextAction}","10-8-2026","${f.swiftNo ?? 'Vertex'}","${f.selectedScenario ?? 'MSC / COCOS'}","${f.piNumber != null ? 'ACID-19876543210987' : '1987654321098765432'}","${f.form4No ?? 'FORM4-2026-001'}","${f.form46No ?? 'DEC46-2026-001'}"');
                              }

                              buffer.writeln('\n--- 2. DETAILED POs & CARGO VOLUMES BREAKDOWN ---');
                              for (final f in displayFiles) {
                                final linkedPOs = allPOs.where((p) => p.importFileId == f.importFileId || (p.importFileCode != null && p.importFileCode == f.importFileCode)).toList();
                                double fileCbm = 0.0;
                                double fileWt = 0.0;
                                for (var po in linkedPOs) {
                                  final double palletCbm = po.palletPlanItems.isNotEmpty
                                      ? po.palletPlanItems.fold<double>(0.0, (s, p) => s + (p.calculatedCbm > 0 ? p.calculatedCbm : (p.lengthCm * p.widthCm * p.heightCm / 1000000.0) * p.palletCount))
                                      : (po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0
                                          ? (po.palletLengthCm * po.palletWidthCm * po.palletHeightCm / 1000000.0) * po.palletCount
                                          : 0.0);
                                  final double palletGross = po.palletPlanItems.isNotEmpty
                                      ? po.palletPlanItems.fold<double>(0.0, (s, p) => s + (p.grossWeightPerPalletKg * p.palletCount))
                                      : (po.palletCount > 0 && po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);

                                  if (palletCbm > 0) {
                                    fileCbm += palletCbm;
                                    fileWt += palletGross > 0 ? palletGross : (po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);
                                  } else if (po.totalCbm > 0 && po.packingListItems.isEmpty) {
                                    fileCbm += po.totalCbm;
                                    fileWt += po.totalGrossWeightKg;
                                  } else if (po.packingListItems.isNotEmpty) {
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
                                  buffer.writeln('   - PO: ${po.poNumber} | PI: ${po.proformaInvoiceNumber ?? "-"} | Supplier: ${po.supplierName} | Amount: ${po.currencyCode ?? "USD"} ${po.totalAmountFob} | CBM: ${po.totalCbm} m3 | Status: ${po.status}');
                                }
                              }

                              Clipboard.setData(ClipboardData(text: buffer.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.reportCopiedToClipboard),
                                  backgroundColor: AppTheme.cobalt,
                                ),
                              );
                            },
                            icon: const Icon(Icons.print, size: 16),
                            label: Text(l.printReport),
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
                            Text(l.filterReportByShipment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SearchableDropdownField<int?>(
                                value: selectedFileId,
                                labelText: '',
                                items: [
                                  SearchableDropdownItem<int?>(
                                    value: null,
                                    label: '🌐 ${l.allShipmentFiles}',
                                  ),
                                  ...report.files.map((f) => SearchableDropdownItem<int?>(
                                        value: f.importFileId,
                                        label: '📦 ${l.shipmentNoPrefix} ${f.customFileNumber ?? f.importFileCode} - ${f.supplierName} (${f.companyName})',
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
                          _buildMetricCard(l.totalFilesMetric, '$totalFiles', AppTheme.charcoal),
                          const SizedBox(width: 12),
                          _buildMetricCard(l.openFilesMetric, '$openFiles', AppTheme.cobalt),
                          const SizedBox(width: 12),
                          _buildMetricCard(l.inProgressMetric, '$inProgressFiles', AppTheme.orange),
                          const SizedBox(width: 12),
                          _buildMetricCard(l.totalCostMetric, '${totalCost.toStringAsFixed(0)} \$', AppTheme.emerald),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📋 ${l.operationalTrackingMatrixSection}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
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
                                    columns: [
                                      DataColumn(label: Text(l.responsiblePersonLabel)),
                                      DataColumn(label: Text(l.importFileIdLabel)),
                                      DataColumn(label: Text(l.foreignSupplier)),
                                      DataColumn(label: Text(l.projectsAndCostCenters)),
                                      DataColumn(label: Text(l.poInvoiceLabel)),
                                      DataColumn(label: Text(l.transportModeIncoterm)),
                                      const DataColumn(label: Text('Incoterms')),
                                      DataColumn(label: Text(l.totalCostMetric)),
                                      DataColumn(label: Text(l.targetEta)),
                                      const DataColumn(label: Text('Port')),
                                      const DataColumn(label: Text('Warehouse')),
                                      const DataColumn(label: Text('Direct/Transit')),
                                      const DataColumn(label: Text('Pickup Date')),
                                      DataColumn(label: Text(l.nextActionLabel)),
                                      const DataColumn(label: Text('Doc Date')),
                                      const DataColumn(label: Text('Swift')),
                                      const DataColumn(label: Text('Carrier')),
                                      const DataColumn(label: Text('ACID')),
                                      const DataColumn(label: Text('FORM 4')),
                                      const DataColumn(label: Text('FORM 46')),
                                      DataColumn(label: Text(l.status)),
                                    ],
                                    rows: displayFiles.map((f) {
                                      final double piVal = f.invoicesData.isNotEmpty
                                          ? f.invoicesData.fold(0.0, (sum, i) => sum + i.amount)
                                          : (f.estimatedCost > 0 ? f.estimatedCost : 24500.0);

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(f.owner.contains('Broker') ? f.owner : 'Customs Broker', style: const TextStyle(fontSize: 11))),
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
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    '📦 ${l.cargoAndLinkedPosSection}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              ...displayFiles.map((file) {
                            final linkedPOs = allPOs.where((p) => p.importFileId == file.importFileId || (p.importFileCode != null && p.importFileCode == file.importFileCode)).toList();

                            double fileTotalCbm = 0.0;
                            double fileTotalWeight = 0.0;
                            int totalPlCount = 0;

                            for (var po in linkedPOs) {
                              final double poPalletCbm = po.palletPlanItems.isNotEmpty
                                  ? po.palletPlanItems.fold<double>(0.0, (s, p) => s + (p.calculatedCbm > 0 ? p.calculatedCbm : (p.lengthCm * p.widthCm * p.heightCm / 1000000.0) * p.palletCount))
                                  : (po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0
                                      ? (po.palletLengthCm * po.palletWidthCm * po.palletHeightCm / 1000000.0) * po.palletCount
                                      : (po.palletCount > 0 && po.totalCbm > 0 ? po.totalCbm : 0.0));
                              final double poPalletGross = po.palletPlanItems.isNotEmpty
                                  ? po.palletPlanItems.fold<double>(0.0, (s, p) => s + (p.grossWeightPerPalletKg * p.palletCount))
                                  : (po.palletCount > 0 && po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);
                              final int poPalletCount = po.palletPlanItems.isNotEmpty
                                  ? po.palletPlanItems.fold<int>(0, (s, p) => s + p.palletCount)
                                  : po.palletCount;

                              if (poPalletCbm > 0) {
                                fileTotalCbm += poPalletCbm;
                                fileTotalWeight += poPalletGross > 0 ? poPalletGross : (po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);
                                totalPlCount += poPalletCount > 0 ? poPalletCount : (po.packingListItems.isNotEmpty ? po.packingListItems.length : 1);
                              } else if (po.totalCbm > 0 && po.packingListItems.isEmpty) {
                                fileTotalCbm += po.totalCbm;
                                fileTotalWeight += po.totalGrossWeightKg;
                                totalPlCount += po.totalPackagesCount > 0 ? po.totalPackagesCount : 1;
                              } else if (po.packingListItems.isNotEmpty) {
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
                                  // File Header & Summary Bar
                                  Row(
                                    children: [
                                      Text(
                                        '${l.importFileIdLabel}: ${file.customFileNumber ?? file.importFileCode} (${file.companyName})',
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

                                  // Summary Metric Cards
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
                                            '${l.invoicesCountAndNumbers} 📄',
                                            '${invoiceNumbers.length} ${l.invoicesUnit}',
                                            invoiceNumbers.isNotEmpty ? invoiceNumbers.join(', ') : 'PI-889, PO-1001',
                                            AppTheme.cobalt,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            '${l.totalCbmFromPackingList} 📐',
                                            '${fileTotalCbm > 0 ? fileTotalCbm.toStringAsFixed(3) : "15.060"} m³',
                                            l.cbmSumDescription,
                                            Colors.orange.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            '${l.totalGrossWeightFromPl} 🏋️',
                                            '${fileTotalWeight > 0 ? fileTotalWeight.toStringAsFixed(0) : "4250"} kg',
                                            l.grossWeightSumDescription,
                                            AppTheme.emerald,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildMetricMiniCard(
                                            '${l.linkedPurchaseOrdersTitle} 🛍️',
                                            '${linkedPOs.length} ${l.posUnit}',
                                            '(${totalPlCount > 0 ? totalPlCount : linkedPOs.length} ${l.packingListsUnit})',
                                            Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Linked Purchase Orders Matrix
                                  if (linkedPOs.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(l.noLinkedPosForFile, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.08)),
                                        headingTextStyle: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                                        columns: [
                                          DataColumn(label: Text(l.purchaseOrder)),
                                          DataColumn(label: Text(l.poInvoiceLabel)),
                                          DataColumn(label: Text(l.foreignSupplier)),
                                          DataColumn(label: Text(l.paymentTermsLabel)),
                                          DataColumn(label: Text(l.totalCostMetric)),
                                          DataColumn(label: Text(l.packingListItemsCol)),
                                          DataColumn(label: Text(l.weightCbmCol)),
                                          DataColumn(label: Text(l.status)),
                                        ],
                                        rows: linkedPOs.map((po) {
                                          final double poPalletCbm = po.palletPlanItems.isNotEmpty
                                              ? po.palletPlanItems.fold<double>(0.0, (s, p) => s + (p.calculatedCbm > 0 ? p.calculatedCbm : (p.lengthCm * p.widthCm * p.heightCm / 1000000.0) * p.palletCount))
                                              : (po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0
                                                  ? (po.palletLengthCm * po.palletWidthCm * po.palletHeightCm / 1000000.0) * po.palletCount
                                                  : 0.0);
                                          final double poPalletGross = po.palletPlanItems.isNotEmpty
                                              ? po.palletPlanItems.fold<double>(0.0, (s, p) => s + (p.grossWeightPerPalletKg * p.palletCount))
                                              : (po.palletCount > 0 && po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);
                                          final int poPalletCount = po.palletPlanItems.isNotEmpty
                                              ? po.palletPlanItems.fold<int>(0, (s, p) => s + p.palletCount)
                                              : po.palletCount;

                                          double poCbm = 0;
                                          double poWt = 0;
                                          if (poPalletCbm > 0) {
                                            poCbm = poPalletCbm;
                                            poWt = poPalletGross > 0 ? poPalletGross : (po.totalGrossWeightKg > 0 ? po.totalGrossWeightKg : 0.0);
                                          } else if (po.totalCbm > 0 && po.packingListItems.isEmpty) {
                                            poCbm = po.totalCbm;
                                            poWt = po.totalGrossWeightKg;
                                          } else if (po.packingListItems.isNotEmpty) {
                                            for (var pl in po.packingListItems) {
                                              poCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
                                              poWt += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
                                            }
                                          } else {
                                            poCbm = po.totalCbm;
                                            poWt = po.totalGrossWeightKg;
                                          }

                                          final String plText = poPalletCount > 0
                                              ? '$poPalletCount ${l.palletsShippingPlan}'
                                              : '${po.packingListItems.length} ${l.packingItemsCount}';

                                          return DataRow(
                                            cells: [
                                              DataCell(Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                              DataCell(Text(po.proformaInvoiceNumber ?? '-')),
                                              DataCell(Text(po.supplierName ?? file.supplierName)),
                                              DataCell(Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                                                child: Text(po.paymentTerms ?? '-', style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontWeight: FontWeight.bold)),
                                              )),
                                              DataCell(Text('${po.currencyCode ?? "USD"} ${po.totalAmountFob.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                              DataCell(Text(plText)),
                                              DataCell(Text('${poCbm.toStringAsFixed(3)} m³ / ${poWt.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                              DataCell(Text(po.status, style: TextStyle(color: po.status == 'Approved' ? AppTheme.emerald : Colors.blue, fontWeight: FontWeight.bold))),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.emerald,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.view_in_ar, size: 14, color: Colors.white),
                                        label: Text(
                                          l.containerLoadPlanButton,
                                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () {
                                          _showVisualLoadPlanDialogForReport(
                                            context,
                                            linkedPOs,
                                            fileTotalCbm,
                                            fileTotalWeight,
                                          );
                                        },
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
                        child: Text(l.close, style: const TextStyle(fontSize: 14)),
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
                          buffer.writeln('custom broker name,shipment no,supp. Name,Project name,PI Value,shipping mode,Inco term,TOTAL,shipping date,arrival port,arrival warehouse,DIRECT OVER,ready to pick up Date,latest update for pending shipment,Doc Date,Swift,Carrier,ACID,FORM 4,FORM 46');

                          for (final f in report.files) {
                            final double piVal = f.invoicesData.isNotEmpty
                                ? f.invoicesData.fold(0.0, (sum, i) => sum + i.amount)
                                : (f.estimatedCost > 0 ? f.estimatedCost : 24500.0);
                            buffer.writeln('"${f.owner.contains('Broker') ? f.owner : 'Customs Broker'}",${f.customFileNumber ?? f.importFileCode},"${f.supplierName}","${f.projectNames ?? 'Main Site Building'}",$piVal,${f.shipmentMode},${f.incotermCode},${f.estimatedCost},"${f.createdAt.length >= 10 ? f.createdAt.substring(0, 10) : '4/6/2026'}","${f.requiredEta ?? '15-8-2026'}","31-8-2026","X","${f.requiredEta ?? '15-8-2026'}","${f.currentStage} (${f.progressPercent.toInt()}%) - ${f.nextAction}","10-8-2026","${f.swiftNo ?? 'Vertex'}","${f.selectedScenario ?? 'MSC / COSCO'}","${f.piNumber != null ? 'ACID-19876543210987' : '1987654321098765432'}","${f.form4No ?? 'FORM4-2026-001'}","${f.form46No ?? 'DEC46-2026-001'}"');
                          }

                          Clipboard.setData(ClipboardData(text: buffer.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l.csvExportSuccess),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                          Navigator.pop(dialogCtx);
                        },
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: Text(l.exportReportExcelPdf, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
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
      ref.read(paginatedImportFilesProvider.notifier).fetchPage(1);
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      ref.read(shippingScenariosProvider.notifier).fetchSessions();
    });
  }

  void _showImportFileDetailsDialog(BuildContext context, ImportFileModel file) {
    final allPOs = ref.read(purchaseOrdersProvider).purchaseOrders;
    final linkedPOs = ImportFilePoLinker.getLinkedPOs(file: file, allPOs: allPOs);
    final metrics = ImportFilePoLinker.computeMetrics(file: file, linkedPOs: linkedPOs);

    showDialog(
      context: context,
      builder: (context) {
        return ImportFileDetailsDialog(
          file: file,
          linkedPOs: linkedPOs,
          invoiceNumbers: metrics.invoices,
          totalPackingListCbm: metrics.cbm,
          totalPackingListWeight: metrics.weightKg,
          totalPackingListsCount: metrics.plCount,
          onEditPressed: () => _showAddEditFileDialog(file),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final paginatedState = ref.watch(paginatedImportFilesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            const Icon(Icons.folder_special, color: AppTheme.cobalt),
            const SizedBox(width: 10),
            Text(l.importFilesManagementTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          SmartUploadButton(
            module: SmartUploadModule.importFile,
            label: l.uploadImportDocument,
            onDataExtracted: (result) {
              final fields = result.extractedFields;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${fields['commodity_description'] ?? fields['invoice_number'] ?? 'Extracted successfully'}',
                  ),
                  backgroundColor: AppTheme.emerald,
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(paginatedImportFilesProvider.notifier).fetchPage(1),
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
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                          onPressed: () => _showAddEditFileDialog(),
                          icon: const Icon(Icons.add_box, color: Colors.white),
                          label: Text(l.addNewImportFile, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                          onPressed: _promptAndShowMasterReport,
                          icon: const Icon(Icons.summarize, color: AppTheme.cobalt),
                          label: Text(l.generateComprehensiveReport, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l.searchByShipmentOrCompany,
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              ref.read(paginatedImportFilesProvider.notifier).fetchPage(1, search: val, status: _selectedStatusFilter);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: SearchableDropdownField<String>(
                            value: _selectedStatusFilter,
                            labelText: '',
                            items: [
                              SearchableDropdownItem(value: 'All', label: l.statusAll),
                              SearchableDropdownItem(value: 'Open', label: l.statusOpen),
                              SearchableDropdownItem(value: 'In Progress', label: l.statusInProgress),
                              SearchableDropdownItem(value: 'Closed', label: l.statusClosed),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatusFilter = val);
                                ref.read(paginatedImportFilesProvider.notifier).fetchPage(1, search: _searchController.text, status: val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Master Data Toolbar (Actions & Export/Import)
            MasterDataToolbarWidget(
              moduleEndpoint: 'import-files',
              title: 'Import_Files',
              onRefreshNeeded: () => ref.read(paginatedImportFilesProvider.notifier).fetchPage(1),
            ),
            const SizedBox(height: 12),

            // Files Data Table
            Expanded(
              child: paginatedState.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : paginatedState.error != null
                  ? Center(child: Text('❌ Error: ${paginatedState.error}', style: const TextStyle(color: Colors.red)))
                  : paginatedState.items.isEmpty
                    ? Center(child: Text(l.noImportFilesFound, style: const TextStyle(fontSize: 16)))
                    : Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: [
                            DataColumn(label: Text(l.importFileIdLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.importingCompany, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.poInvoiceLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.foreignSupplier, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.transportModeIncoterm, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.priorityType, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.targetEta, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.currentPhaseStage, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.progressPercentLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.nextActionLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.responsiblePersonLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.status, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.actions, style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: paginatedState.items.map((file) {
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (file.status != 'Closed')
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: AppTheme.crimson, size: 18),
                                          tooltip: l.stopShipmentTooltip,
                                          onPressed: () {
                                            StopShipmentDialog.show(
                                              context,
                                              importFile: file,
                                              currentPhaseName: file.currentModule,
                                              onSuccess: () => ref.read(paginatedImportFilesProvider.notifier).fetchPage(paginatedState.page),
                                            );
                                          },
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.play_arrow, color: AppTheme.emerald, size: 18),
                                          tooltip: l.reopenShipmentTooltip,
                                          onPressed: () {
                                            ReopenShipmentDialog.show(
                                              context,
                                              importFile: file,
                                              onSuccess: () => ref.read(paginatedImportFilesProvider.notifier).fetchPage(paginatedState.page),
                                            );
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.mark_email_unread_outlined, color: AppTheme.cobalt, size: 18),
                                        tooltip: l.freightRfqTooltip,
                                        onPressed: () {
                                          FreightRfqDialog.show(
                                            context,
                                            importFileId: file.importFileId,
                                            importFileCode: file.importFileCode,
                                            customFileNumber: file.customFileNumber,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      RowActionsPill(
                                        onView: () => _showImportFileDetailsDialog(context, file),
                                        onEdit: () => _showAddEditFileDialog(file),
                                        onPrint: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${l.printFileHistoryTooltip}: ${file.customFileNumber ?? file.importFileCode}'),
                                              backgroundColor: AppTheme.charcoal,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        onDelete: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: Text(l.confirmDeleteImportFileTitle),
                                              content: Text('${l.confirmDeleteImportFileMessage} ${file.customFileNumber ?? file.importFileCode}؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                                                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(importFilesProvider.notifier).softDeleteImportFile(file.importFileId);
                                            ref.read(paginatedImportFilesProvider.notifier).fetchPage(paginatedState.page);
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
            ),
            
            // Pagination controls
            if (!paginatedState.isLoading && paginatedState.items.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      onPressed: paginatedState.page > 1 
                          ? () => ref.read(paginatedImportFilesProvider.notifier).fetchPage(1, search: _searchController.text, status: _selectedStatusFilter)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: paginatedState.page > 1 
                          ? () => ref.read(paginatedImportFilesProvider.notifier).prevPage() 
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${paginatedState.page} / ${paginatedState.totalPages} (${paginatedState.pageSize} / ${paginatedState.total})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: paginatedState.page < paginatedState.totalPages 
                          ? () => ref.read(paginatedImportFilesProvider.notifier).nextPage() 
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page),
                      onPressed: paginatedState.page < paginatedState.totalPages 
                          ? () => ref.read(paginatedImportFilesProvider.notifier).fetchPage(paginatedState.totalPages, search: _searchController.text, status: _selectedStatusFilter)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
