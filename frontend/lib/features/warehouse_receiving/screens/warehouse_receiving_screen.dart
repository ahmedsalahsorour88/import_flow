import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../customs_clearance/providers/customs_clearance_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/warehouse_receiving_model.dart';
import '../providers/goods_in_transit_provider.dart';
import '../providers/warehouse_receiving_provider.dart';

class WarehouseReceivingScreen extends ConsumerStatefulWidget {
  const WarehouseReceivingScreen({super.key});

  @override
  ConsumerState<WarehouseReceivingScreen> createState() => _WarehouseReceivingScreenState();
}

class _WarehouseReceivingScreenState extends ConsumerState<WarehouseReceivingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(warehouseReceivingProvider.notifier).fetchRecords();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      ref.read(customsClearanceProvider.notifier).fetchRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([WarehouseReceivingModel? recordToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WarehouseReceivingFormDialog(recordToEdit: recordToEdit),
    );
  }

  void _showDiscrepancyDialog(WarehouseReceivingModel record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiscrepancyReportDialog(record: record),
    );
  }

  Future<void> _confirmFinalReceipt(WarehouseReceivingModel record) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.emerald),
            const SizedBox(width: 8),
            Text(l10n.warehouseReceivingConfirmReceiptTitle),
          ],
        ),
        content: Text(
          l10n.warehouseReceivingConfirmReceiptMessage(record.grnCode),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
            icon: const Icon(Icons.verified, color: Colors.white, size: 16),
            label: Text(l10n.warehouseReceivingConfirmReceiptBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final payload = {
          'status': 'Goods Received',
          'discrepancy_notes': l10n.warehouseReceivingStatusGoodsReceived,
        };
        await ref.read(warehouseReceivingProvider.notifier).updateRecord(record.receivingId, payload);
        ref.read(goodsInTransitProvider.notifier).confirmWarehouseReceipt(record.importFileId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.warehouseReceivingConfirmReceiptSuccess(record.grnCode)),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.warehouseReceivingConfirmReceiptError('$e')), backgroundColor: AppTheme.crimson),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(warehouseReceivingProvider);

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.inventory_outlined,
        titleEn: 'Goods Receiving Notes (GRN)',
        titleAr: 'سجل أذون الإضافة المخزنية',
      ),
      const VerticalNavTabItem(
        icon: Icons.add_business_outlined,
        titleEn: 'New GRN Entry',
        titleAr: 'إنشاء إذن استلام وفحص مخزني',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'GRN-01',
      titleEn: 'Warehouse Receiving & Inspection (GRN)',
      titleAr: 'استلام البضائع بالمخازن وفحص الجودة',
      headerIcon: Icons.inventory,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (index) {
        if (index == 1) {
          _showAddEditDialog();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: context.l10n.warehouseReceivingRefreshTooltip,
          onPressed: () => ref.read(warehouseReceivingProvider.notifier).fetchRecords(),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Data Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'warehouse-receiving',
              title: 'Warehouse_Receiving',
              onRefreshNeeded: () => ref.read(warehouseReceivingProvider.notifier).fetchRecords(),
            ),
            const SizedBox(height: 12),

            // Toolbar Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        onPressed: () => _showAddEditDialog(),
                        icon: const Icon(Icons.local_shipping, color: Colors.white),
                        label: Text(context.l10n.warehouseReceivingNewGrnBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: context.l10n.warehouseReceivingSearchHint,
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            ref.read(warehouseReceivingProvider.notifier).fetchRecords(search: val, status: _selectedStatusFilter);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 250,
                        child: SearchableDropdownField<String>(
                          value: _selectedStatusFilter,
                          items: [
                            SearchableDropdownItem(value: 'All', label: context.l10n.warehouseReceivingStatusAll),
                            SearchableDropdownItem(value: 'Draft / Pending Warehouse Count', label: context.l10n.warehouseReceivingStatusDraft),
                            SearchableDropdownItem(value: 'Goods Received', label: context.l10n.warehouseReceivingStatusGoodsReceived),
                            SearchableDropdownItem(value: 'Discrepancy Reported', label: context.l10n.warehouseReceivingStatusDiscrepancy),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatusFilter = val);
                              ref.read(warehouseReceivingProvider.notifier).fetchRecords(search: _searchController.text, status: val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content List Area
            Expanded(
              child: recordsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('${context.l10n.error}: $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return Center(child: Text(context.l10n.warehouseReceivingEmptyRecords));
                  }

                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, idx) {
                      final r = records[idx];
                      final isDraft = r.status.contains('Draft') || r.status.contains('Pending');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(r.grnCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                  ),
                                  Text(r.warehouseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  _buildSealBadge(r.sealIntact, r.sealNumber),
                                  _buildStatusBadge(r.status),
                                ],
                              ),
                              const Divider(height: 20),

                              // Truck & Driver Info
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${context.l10n.warehouseReceivingTruckAndDriver}: ${r.driverName ?? "-"} (${r.truckPlateNumber ?? "-"})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('${context.l10n.warehouseReceivingArrivalDatetime}: ${r.arrivalDatetime.replaceFirst("T", " ").split(".")[0]}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${context.l10n.warehouseReceivingInspector}: ${r.inspectorName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('${context.l10n.warehouseReceivingDiscrepancyStatus}: ${r.discrepancyType}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: r.discrepancyType != "None" ? AppTheme.crimson : AppTheme.emerald)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // GRN Audit Summary Grid Box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildQtyMetric(context.l10n.warehouseReceivingMetricInvoiced, '${r.totalInvoicedQty}', Colors.black87),
                                    _buildQtyMetric(context.l10n.warehouseReceivingMetricAccepted, '${r.totalAcceptedQty}', AppTheme.emerald),
                                    _buildQtyMetric(context.l10n.warehouseReceivingMetricShortage, '${r.totalShortageQty}', r.totalShortageQty > 0 ? AppTheme.crimson : Colors.grey),
                                    _buildQtyMetric(context.l10n.warehouseReceivingMetricDamaged, '${r.totalDamagedQty}', r.totalDamagedQty > 0 ? AppTheme.crimson : Colors.grey),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (isDraft) ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.check_circle, size: 16),
                                        label: Text(context.l10n.warehouseReceivingConfirmFinalReceiptBtn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        onPressed: () => _confirmFinalReceipt(r),
                                      ),
                                    ],
                                    if (r.discrepancyType == 'None' || !r.quarantineZoneAssigned) ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange),
                                        icon: const Icon(Icons.warning_amber, size: 16, color: Colors.white),
                                        label: Text(context.l10n.warehouseReceivingRecordDiscrepancyBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showDiscrepancyDialog(r),
                                      ),
                                    ],
                                    RowActionsPill(
                                      onView: () => _showAddEditDialog(r),
                                      onEdit: () => _showAddEditDialog(r),
                                      onPrint: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(context.l10n.warehouseReceivingPrintGrnSnack(r.grnCode, r.warehouseName)),
                                            backgroundColor: AppTheme.charcoal,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      onDelete: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: Text(context.l10n.warehouseReceivingDeleteTitle),
                                            content: Text(context.l10n.warehouseReceivingDeleteConfirmMessage),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
                                              TextButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.delete, style: const TextStyle(color: AppTheme.crimson))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          ref.read(warehouseReceivingProvider.notifier).softDeleteRecord(r.receivingId);
                                        }
                                      },
                                      viewTooltip: context.l10n.warehouseReceivingViewTooltip,
                                      editTooltip: context.l10n.warehouseReceivingEditTooltip,
                                      printTooltip: context.l10n.warehouseReceivingPrintTooltip,
                                      deleteTooltip: context.l10n.warehouseReceivingDeleteTooltip,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyMetric(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildSealBadge(bool intact, String? sealNo) {
    final color = intact ? AppTheme.emerald : AppTheme.crimson;
    final text = intact ? context.l10n.warehouseReceivingSealIntact : context.l10n.warehouseReceivingSealBroken;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text('$text ${sealNo != null ? "[$sealNo]" : ""}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.cobalt;
    String label = status;
    if (status.contains('Draft') || status.contains('Pending')) {
      color = AppTheme.orange;
      label = context.l10n.warehouseReceivingStatusDraft;
    } else if (status == 'Discrepancy Reported') {
      color = AppTheme.crimson;
      label = context.l10n.warehouseReceivingStatusDiscrepancy;
    } else if (status == 'Closed' || status == 'Goods Received') {
      color = AppTheme.emerald;
      label = context.l10n.warehouseReceivingStatusGoodsReceived;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
    );
  }
}

// -----------------------------------------------------------------------------
// FORM DIALOG WITH MULTI-PO BREAKDOWN & SMART WAREHOUSE ALERTS
// -----------------------------------------------------------------------------

class _WarehouseReceivingFormDialog extends ConsumerStatefulWidget {
  final WarehouseReceivingModel? recordToEdit;
  const _WarehouseReceivingFormDialog({this.recordToEdit});

  @override
  ConsumerState<_WarehouseReceivingFormDialog> createState() => _WarehouseReceivingFormDialogState();
}

class _WarehouseReceivingFormDialogState extends ConsumerState<_WarehouseReceivingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  late TextEditingController _whCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _driverCtrl;
  late TextEditingController _sealCtrl;
  bool _sealIntact = true;

  bool _alertSentToWarehouse = false;
  bool _isLoading = false;

  // Multi-PO Line Items Data
  final List<Map<String, dynamic>> _poItems = [];

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    _selectedImportFileId = r?.importFileId;
    _whCtrl = TextEditingController(text: r?.warehouseName ?? 'Main Warehouse - Cairo');
    _plateCtrl = TextEditingController(text: r?.truckPlateNumber ?? '');
    _driverCtrl = TextEditingController(text: r?.driverName ?? '');
    _sealCtrl = TextEditingController(text: r?.sealNumber ?? '');
    _sealIntact = r?.sealIntact ?? true;

    if (r != null && r.grnItems.isNotEmpty) {
      for (var item in r.grnItems) {
        _poItems.add({
          'po_number': 'PO-MAIN-${r.importFileId}',
          'item_code_ctrl': TextEditingController(text: item.itemCode),
          'item_name_ctrl': TextEditingController(text: item.itemName),
          'inv_qty_ctrl': TextEditingController(text: item.invoicedQty.toString()),
          'acc_qty_ctrl': TextEditingController(text: item.acceptedQty.toString()),
          'short_qty_ctrl': TextEditingController(text: item.shortageQty.toString()),
          'dmg_qty_ctrl': TextEditingController(text: item.damagedQty.toString()),
          'samples_qty_ctrl': TextEditingController(text: '0'),
        });
      }
    } else {
      _loadDefaultItems();
    }
  }

  void _loadDefaultItems() {
    _poItems.clear();
    _poItems.add({
      'po_number': 'PO-2026-IT-001',
      'item_code_ctrl': TextEditingController(text: 'ITM-SR-101'),
      'item_name_ctrl': TextEditingController(text: 'Enterprise Servers'),
      'inv_qty_ctrl': TextEditingController(text: '250'),
      'acc_qty_ctrl': TextEditingController(text: '247'),
      'short_qty_ctrl': TextEditingController(text: '0'),
      'dmg_qty_ctrl': TextEditingController(text: '2'),
      'samples_qty_ctrl': TextEditingController(text: '1'),
    });
    _poItems.add({
      'po_number': 'PO-2026-IT-001',
      'item_code_ctrl': TextEditingController(text: 'ITM-SR-102'),
      'item_name_ctrl': TextEditingController(text: 'Smart Network Switches'),
      'inv_qty_ctrl': TextEditingController(text: '500'),
      'acc_qty_ctrl': TextEditingController(text: '498'),
      'short_qty_ctrl': TextEditingController(text: '0'),
      'dmg_qty_ctrl': TextEditingController(text: '0'),
      'samples_qty_ctrl': TextEditingController(text: '2'),
    });
  }

  void _onImportFileSelected(int? fileId) {
    if (fileId == null) return;
    setState(() {
      _selectedImportFileId = fileId;
    });

    final files = ref.read(importFilesProvider).value ?? [];
    final selectedFile = files.firstWhere((f) => f.importFileId == fileId, orElse: () => files.first);

    // Auto-detect shortage & damage from clearance records
    final clearanceRecords = ref.read(customsClearanceProvider).value ?? [];
    final matchingClearance = clearanceRecords.where((c) => c.importFileId == fileId).toList();
    final hasDiscrepancy = matchingClearance.any((c) => c.status == 'Discrepancy Reported' || (c.dutyVarianceReason != null && c.dutyVarianceReason!.isNotEmpty));

    // Auto populate items from PO
    final poList = ref.read(purchaseOrdersProvider).purchaseOrders;
    final linkedPos = poList.where((p) => selectedFile.poNumber?.contains(p.poNumber) ?? false).toList();

    setState(() {
      _poItems.clear();
      if (linkedPos.isNotEmpty) {
        for (var po in linkedPos) {
          for (var item in po.items) {
            _poItems.add({
              'po_number': po.poNumber,
              'item_code_ctrl': TextEditingController(text: item.itemCode ?? 'ITM-PO'),
              'item_name_ctrl': TextEditingController(text: item.descriptionAr),
              'inv_qty_ctrl': TextEditingController(text: item.quantity.toStringAsFixed(0)),
              'acc_qty_ctrl': TextEditingController(text: item.quantity.toStringAsFixed(0)),
              'short_qty_ctrl': TextEditingController(text: hasDiscrepancy ? '2' : '0'),
              'dmg_qty_ctrl': TextEditingController(text: hasDiscrepancy ? '1' : '0'),
              'samples_qty_ctrl': TextEditingController(text: '1'),
            });
          }
        }
      } else {
        _poItems.add({
          'po_number': selectedFile.poNumber ?? 'PO-2026-GEN',
          'item_code_ctrl': TextEditingController(text: 'ITM-GEN-01'),
          'item_name_ctrl': TextEditingController(text: selectedFile.importFileCode),
          'inv_qty_ctrl': TextEditingController(text: '100'),
          'acc_qty_ctrl': TextEditingController(text: '100'),
          'short_qty_ctrl': TextEditingController(text: hasDiscrepancy ? '1' : '0'),
          'dmg_qty_ctrl': TextEditingController(text: '0'),
          'samples_qty_ctrl': TextEditingController(text: '1'),
        });
      }
    });
  }

  @override
  void dispose() {
    _whCtrl.dispose();
    _plateCtrl.dispose();
    _driverCtrl.dispose();
    _sealCtrl.dispose();
    for (var item in _poItems) {
      (item['item_code_ctrl'] as TextEditingController).dispose();
      (item['item_name_ctrl'] as TextEditingController).dispose();
      (item['inv_qty_ctrl'] as TextEditingController).dispose();
      (item['acc_qty_ctrl'] as TextEditingController).dispose();
      (item['short_qty_ctrl'] as TextEditingController).dispose();
      (item['dmg_qty_ctrl'] as TextEditingController).dispose();
      (item['samples_qty_ctrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm(bool isFinalConfirmation) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      final grnItemsPayload = _poItems.map((item) {
        return {
          'item_code': (item['item_code_ctrl'] as TextEditingController).text.trim(),
          'item_name': (item['item_name_ctrl'] as TextEditingController).text.trim(),
          'invoiced_qty': int.tryParse((item['inv_qty_ctrl'] as TextEditingController).text.trim()) ?? 0,
          'accepted_qty': int.tryParse((item['acc_qty_ctrl'] as TextEditingController).text.trim()) ?? 0,
          'shortage_qty': int.tryParse((item['short_qty_ctrl'] as TextEditingController).text.trim()) ?? 0,
          'damaged_qty': int.tryParse((item['dmg_qty_ctrl'] as TextEditingController).text.trim()) ?? 0,
        };
      }).toList();

      final payload = {
        'import_file_id': _selectedImportFileId,
        'warehouse_name': _whCtrl.text.trim(),
        'truck_plate_number': _plateCtrl.text.trim(),
        'driver_name': _driverCtrl.text.trim(),
        'seal_number': _sealCtrl.text.trim(),
        'seal_intact': _sealIntact,
        'status': isFinalConfirmation ? 'Goods Received' : 'Draft / Pending Warehouse Count',
        'grn_items': grnItemsPayload,
      };

      if (widget.recordToEdit != null) {
        await ref.read(warehouseReceivingProvider.notifier).updateRecord(widget.recordToEdit!.receivingId, payload);
      } else {
        await ref.read(warehouseReceivingProvider.notifier).createRecord(payload);
      }

      if (isFinalConfirmation && _selectedImportFileId != null) {
        ref.read(goodsInTransitProvider.notifier).confirmWarehouseReceipt(_selectedImportFileId!);
      }

      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isFinalConfirmation
              ? l10n.warehouseReceivingFinalSuccessSnack
              : l10n.warehouseReceivingDraftSuccessSnack),
          backgroundColor: isFinalConfirmation ? AppTheme.emerald : AppTheme.orange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppTheme.crimson));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warehouse, color: AppTheme.cobalt),
          const SizedBox(width: 8),
          Text(widget.recordToEdit == null ? context.l10n.warehouseReceivingNewDialogTitle : context.l10n.warehouseReceivingEditDialogTitle),
        ],
      ),
      content: SizedBox(
        width: 850,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Smart Notice Banner for Warehouse Documents
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, color: Colors.orange, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.warehouseReceivingDispatchAlertTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.warehouseReceivingDispatchAlertDesc,
                              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _alertSentToWarehouse ? AppTheme.emerald : AppTheme.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: Icon(_alertSentToWarehouse ? Icons.check : Icons.send, size: 14),
                        label: Text(
                          _alertSentToWarehouse ? context.l10n.warehouseReceivingDispatchSentBtn : context.l10n.warehouseReceivingDispatchSendBtn,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() => _alertSentToWarehouse = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.warehouseReceivingDispatchSuccessSnack),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Shipment Selection & Location
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<int?>(
                        value: _selectedImportFileId,
                        labelText: context.l10n.warehouseReceivingImportFileLabel,
                        items: importFiles
                            .map((f) => SearchableDropdownItem<int?>(
                                  value: f.importFileId,
                                  label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                ))
                            .toList(),
                        onChanged: _onImportFileSelected,
                        validator: (v) => v == null ? context.l10n.warehouseReceivingSelectFileValidator : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _whCtrl,
                        decoration: InputDecoration(labelText: context.l10n.warehouseReceivingWarehouseNameLabel, border: const OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.warehouseReceivingWarehouseNameValidator : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Driver & Truck Plate & Seal Info
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plateCtrl,
                        decoration: InputDecoration(labelText: context.l10n.warehouseReceivingTruckPlateLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _driverCtrl,
                        decoration: InputDecoration(labelText: context.l10n.warehouseReceivingDriverNameLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _sealCtrl,
                        decoration: InputDecoration(labelText: context.l10n.warehouseReceivingSealNumberLabel, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SwitchListTile(
                        title: Text(context.l10n.warehouseReceivingSealIntactSwitch, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        value: _sealIntact,
                        onChanged: (val) => setState(() => _sealIntact = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Multi-PO Line Items Table Header
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: AppTheme.cobalt, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.warehouseReceivingMultiPoHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(context.l10n.warehouseReceivingAddItemBtn, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _poItems.add({
                            'po_number': 'PO-NEW',
                            'item_code_ctrl': TextEditingController(text: 'ITM-NEW'),
                            'item_name_ctrl': TextEditingController(text: 'New Item'),
                            'inv_qty_ctrl': TextEditingController(text: '0'),
                            'acc_qty_ctrl': TextEditingController(text: '0'),
                            'short_qty_ctrl': TextEditingController(text: '0'),
                            'dmg_qty_ctrl': TextEditingController(text: '0'),
                            'samples_qty_ctrl': TextEditingController(text: '0'),
                          });
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Table of PO Line Items
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _poItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = _poItems[i];
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                                  child: Text(context.l10n.warehouseReceivingPoLabel('${item["po_number"]}'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade900)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${(item["item_code_ctrl"] as TextEditingController).text} - ${(item["item_name_ctrl"] as TextEditingController).text}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: item['item_name_ctrl'] as TextEditingController,
                                    decoration: InputDecoration(labelText: context.l10n.warehouseReceivingItemNameLabel, isDense: true, border: const OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['inv_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.l10n.warehouseReceivingInvoicedQtyLabel, isDense: true, border: const OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['acc_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.l10n.warehouseReceivingAcceptedQtyLabel, isDense: true, border: const OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['short_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.l10n.warehouseReceivingShortageQtyLabel, isDense: true, border: const OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['dmg_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.l10n.warehouseReceivingDamagedQtyLabel, isDense: true, border: const OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['samples_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.l10n.warehouseReceivingSamplesQtyLabel, isDense: true, border: const OutlineInputBorder()),
                                  ),
                                ),
                              ],
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
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.orange, side: const BorderSide(color: AppTheme.orange)),
          icon: const Icon(Icons.save_as_outlined, size: 16),
          label: Text(context.l10n.warehouseReceivingSaveDraftBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _isLoading ? null : () => _submitForm(false),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          label: Text(context.l10n.warehouseReceivingSaveFinalBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _isLoading ? null : () => _submitForm(true),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// DISCREPANCY & DAMAGE REPORT DIALOG
// -----------------------------------------------------------------------------

class _DiscrepancyReportDialog extends ConsumerStatefulWidget {
  final WarehouseReceivingModel record;
  const _DiscrepancyReportDialog({required this.record});

  @override
  ConsumerState<_DiscrepancyReportDialog> createState() => _DiscrepancyReportDialogState();
}

class _DiscrepancyReportDialogState extends ConsumerState<_DiscrepancyReportDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDiscrepancyType = 'Shortage and Damage';
  late TextEditingController _notesCtrl;
  bool _quarantineAssigned = true;
  bool _fileClaim = false;
  late TextEditingController _claimRefCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.record.discrepancyNotes ?? 'Discrepancy recorded during unloading.');
    _claimRefCtrl = TextEditingController(text: widget.record.insuranceClaimRef ?? 'CLM-2026-WH-001');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _claimRefCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning, color: AppTheme.orange),
          const SizedBox(width: 8),
          Text(context.l10n.warehouseReceivingDiscrepancyDialogTitle(widget.record.grnCode)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchableDropdownField<String>(
                value: _selectedDiscrepancyType,
                labelText: context.l10n.warehouseReceivingDiscrepancyTypeLabel,
                items: [
                  SearchableDropdownItem(value: 'Shortage and Damage', label: context.l10n.warehouseReceivingDiscrepancyTypeShortageAndDamage),
                  SearchableDropdownItem(value: 'Shortage Only', label: context.l10n.warehouseReceivingDiscrepancyTypeShortageOnly),
                  SearchableDropdownItem(value: 'Damage Only', label: context.l10n.warehouseReceivingDiscrepancyTypeDamageOnly),
                  SearchableDropdownItem(value: 'Broken Seal Discrepancy', label: context.l10n.warehouseReceivingDiscrepancyTypeBrokenSeal),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDiscrepancyType = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: context.l10n.warehouseReceivingDiscrepancyNotesLabel, border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.warehouseReceivingDiscrepancyNotesValidator : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(context.l10n.warehouseReceivingQuarantineSwitch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _quarantineAssigned,
                onChanged: (val) => setState(() => _quarantineAssigned = val),
              ),
              SwitchListTile(
                title: Text(context.l10n.warehouseReceivingInsuranceClaimSwitch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _fileClaim,
                onChanged: (val) => setState(() => _fileClaim = val),
              ),
              if (_fileClaim) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _claimRefCtrl,
                  decoration: InputDecoration(labelText: context.l10n.warehouseReceivingClaimRefLabel, border: const OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final l10n = context.l10n;
                    try {
                      final payload = {
                        'discrepancy_type': _selectedDiscrepancyType,
                        'discrepancy_notes': _notesCtrl.text.trim(),
                        'quarantine_zone_assigned': _quarantineAssigned,
                        'insurance_claim_filed': _fileClaim,
                        'insurance_claim_ref': _fileClaim ? _claimRefCtrl.text.trim() : null,
                      };

                      await ref.read(warehouseReceivingProvider.notifier).reportDiscrepancy(widget.record.receivingId, payload);
                      nav.pop();
                      messenger.showSnackBar(SnackBar(content: Text(l10n.warehouseReceivingDiscrepancySuccessSnack), backgroundColor: AppTheme.emerald));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(context.l10n.warehouseReceivingCertifyDiscrepancyBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
