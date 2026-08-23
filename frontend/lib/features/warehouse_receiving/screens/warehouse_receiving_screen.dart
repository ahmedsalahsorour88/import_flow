import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.emerald),
            SizedBox(width: 8),
            Text('تأكيد الاستلام النهائي للمخزن'),
          ],
        ),
        content: Text(
          'هل تريد تأكيد الاستلام النهائي للشحنة رقم [${record.grnCode}] بالمخزن؟\n\n'
          '⚠️ هذا الإجراء سيقوم بتثبيت الكميات الفعلية وإغلاق المحضر وخصم رصيد الشحنة من تقرير "البضاعة في الطريق (GIT)".',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
            icon: const Icon(Icons.verified, color: Colors.white, size: 16),
            label: const Text('نعم، تأكيد الاستلام النهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final payload = {
          'status': 'Goods Received',
          'discrepancy_notes': 'تم تأكيد الاستلام النهائي بالمخزن واعتماد الكميات الفعلية.',
        };
        await ref.read(warehouseReceivingProvider.notifier).updateRecord(record.receivingId, payload);
        ref.read(goodsInTransitProvider.notifier).confirmWarehouseReceipt(record.importFileId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تأكيد الاستلام النهائي لـ ${record.grnCode} وخصم رصيد البضاعة بالطريق بنجاح ✅'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء تأكيد الاستلام: $e'), backgroundColor: AppTheme.crimson),
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
          tooltip: 'تحديث البيانات',
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
                        label: const Text('تسجيل وصول شاحنة واستلام محضر GRN جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'بحث برقم GRN، الشاحنة، السائق...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(),
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
                          items: const [
                            SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                            SearchableDropdownItem(value: 'Draft / Pending Warehouse Count', label: '🟡 مسودة مؤقتة (بانتظار العد)'),
                            SearchableDropdownItem(value: 'Goods Received', label: '🟢 تم الاستلام النهائي بالمخزن'),
                            SearchableDropdownItem(value: 'Discrepancy Reported', label: '🟠 مُثبت به عجز/تلف جمركي'),
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
                error: (err, _) => Center(child: Text('خطأ في جلب بيانات استلام المخزن: $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('لا توجد سجلات استلام بمخازن الشركة حالياً.'));
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
                                        Text('الشاحنة والسائق: ${r.driverName ?? "غير محدد"} (${r.truckPlateNumber ?? "بلا رقم"})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('تاريخ ووقت الوصول: ${r.arrivalDatetime.replaceFirst("T", " ").split(".")[0]}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('مسئول الاستلام والجودة: ${r.inspectorName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('حالة الفروق: ${r.discrepancyType}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: r.discrepancyType != "None" ? AppTheme.crimson : AppTheme.emerald)),
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
                                    _buildQtyMetric('الفاتورة (Invoiced)', '${r.totalInvoicedQty}', Colors.black87),
                                    _buildQtyMetric('المقبول (Accepted)', '${r.totalAcceptedQty}', AppTheme.emerald),
                                    _buildQtyMetric('العجز (Shortage)', '${r.totalShortageQty}', r.totalShortageQty > 0 ? AppTheme.crimson : Colors.grey),
                                    _buildQtyMetric('التلف (Damaged)', '${r.totalDamagedQty}', r.totalDamagedQty > 0 ? AppTheme.crimson : Colors.grey),
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
                                        label: const Text('تأكيد الاستلام النهائي للمخزن ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        onPressed: () => _confirmFinalReceipt(r),
                                      ),
                                    ],
                                    if (r.discrepancyType == 'None' || !r.quarantineZoneAssigned) ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange),
                                        icon: const Icon(Icons.warning_amber, size: 16, color: Colors.white),
                                        label: const Text('إثبات عجز / تلف', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showDiscrepancyDialog(r),
                                      ),
                                    ],
                                    RowActionsPill(
                                      onView: () => _showAddEditDialog(r),
                                      onEdit: () => _showAddEditDialog(r),
                                      onPrint: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('طباعة محضر استلام البضاعة GRN: ${r.grnCode} (${r.warehouseName})'),
                                            backgroundColor: AppTheme.charcoal,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      onDelete: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('حذف محضر الاستلام'),
                                            content: const Text('هل أنت متأكد من نقل محضر الاستلام للمحذوفات؟'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: AppTheme.crimson))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          ref.read(warehouseReceivingProvider.notifier).softDeleteRecord(r.receivingId);
                                        }
                                      },
                                      viewTooltip: 'عرض محضر الاستلام',
                                      editTooltip: 'تعديل محضر الاستلام',
                                      printTooltip: 'طباعة محضر GRN',
                                      deleteTooltip: 'حذف محضر الاستلام (Soft Delete)',
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
    final text = intact ? 'الرصاص أصل وسليم (Seal Intact)' : 'الرصاص تالف/مكسور (Seal Broken)';
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
      label = '🟡 مسودة مؤقتة (بانتظار العد)';
    } else if (status == 'Discrepancy Reported') {
      color = AppTheme.crimson;
      label = '🟠 مُثبت به عجز/تلف';
    } else if (status == 'Closed' || status == 'Goods Received') {
      color = AppTheme.emerald;
      label = '🟢 تم الاستلام النهائي ✅';
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
      'item_name_ctrl': TextEditingController(text: 'خوادم رقمية صناعية (Enterprise Servers)'),
      'inv_qty_ctrl': TextEditingController(text: '250'),
      'acc_qty_ctrl': TextEditingController(text: '247'),
      'short_qty_ctrl': TextEditingController(text: '0'),
      'dmg_qty_ctrl': TextEditingController(text: '2'),
      'samples_qty_ctrl': TextEditingController(text: '1'),
    });
    _poItems.add({
      'po_number': 'PO-2026-IT-001',
      'item_code_ctrl': TextEditingController(text: 'ITM-SR-102'),
      'item_name_ctrl': TextEditingController(text: 'محولات شبكية ذكية (Smart Network Switches)'),
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
          'item_name_ctrl': TextEditingController(text: 'بضائع ومنتجات استيرادية معتمدة بالفاتورة'),
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
              ? 'تم تأكيد الاستلام النهائي للمخزن وخصم رصيد البضاعة بالطريق بنجاح ✅'
              : 'تم حفظ المحضر كمسودة مؤقتة بانتظار العد الفعلي للمخزن ⏳'),
          backgroundColor: isFinalConfirmation ? AppTheme.emerald : AppTheme.orange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.crimson));
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
          Text(widget.recordToEdit == null ? 'تسجيل محضر استلام شحنة جديدة بالمخزن' : 'تعديل بيانات المحضر وتأكيد الاستلام'),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ تنبيه إداري عاجل (Document Dispatch Alert):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'يجب إرسال أوراق الشحنة المعتمدة (Packing List & Commercial Invoice) فوراً إلى مسؤولي المخزن لمطابقة البضائع عند وصول الشاحنة.',
                              style: TextStyle(fontSize: 11.5, color: Colors.black87),
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
                          _alertSentToWarehouse ? 'تم الإرسال للمخزن ✅' : '📤 إرسال إشعار للمخزن وتوليد مهمة',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() => _alertSentToWarehouse = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إرسال إشعار المستندات وتوليد مهمة ذكية في الداش بورد لمسؤولي المخزن بنجاح ✅'),
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
                        labelText: 'ملف الشحنة الاستيرادية *',
                        items: importFiles
                            .map((f) => SearchableDropdownItem<int?>(
                                  value: f.importFileId,
                                  label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                ))
                            .toList(),
                        onChanged: _onImportFileSelected,
                        validator: (v) => v == null ? 'يرجى اختيار ملف الشحنة' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _whCtrl,
                        decoration: const InputDecoration(labelText: 'اسم المخزن والفرع *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المخزن' : null,
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
                        decoration: const InputDecoration(labelText: 'رقم الشاحنة / السيارة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _driverCtrl,
                        decoration: const InputDecoration(labelText: 'اسم السائق', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _sealCtrl,
                        decoration: const InputDecoration(labelText: 'رقم السيل / الرصاص الأمني', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('سلامة السيل (Seal Intact)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                    const Text(
                      'بيانات جرد واختبار كميات الأصناف تفصيلياً بكل أمر شراء (Multi-PO Breakdown):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('إضافة صنف', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _poItems.add({
                            'po_number': 'PO-NEW',
                            'item_code_ctrl': TextEditingController(text: 'ITM-NEW'),
                            'item_name_ctrl': TextEditingController(text: 'صنف جديد'),
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
                                  child: Text('أمر الشراء: ${item["po_number"]}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade900)),
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
                                    decoration: const InputDecoration(labelText: 'اسم وبيان الصنف', isDense: true, border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['inv_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'العدد بالفاتورة', isDense: true, border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['acc_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'المستلم الفعلي', isDense: true, border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['short_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'العجز', isDense: true, border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['dmg_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'التلف', isDense: true, border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    controller: item['samples_qty_ctrl'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'عينات مسحوبة', isDense: true, border: OutlineInputBorder()),
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
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.orange, side: const BorderSide(color: AppTheme.orange)),
          icon: const Icon(Icons.save_as_outlined, size: 16),
          label: const Text('حفظ مؤقت (مسودة بانتظار العد) ⏳', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _isLoading ? null : () => _submitForm(false),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          label: const Text('تأكيد الاستلام النهائي للمخزن ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    _notesCtrl = TextEditingController(text: widget.record.discrepancyNotes ?? 'عجز وتلف ملحوظ أثناء تفريغ الحاوية بمخزن الشركة.');
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
          Text('إثبات عجز / تلف رسمي لمحضر: ${widget.record.grnCode}'),
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
                labelText: 'نوع التباين والعجز *',
                items: const [
                  SearchableDropdownItem(value: 'Shortage and Damage', label: 'عجز وتلف كلي (Shortage and Damage)'),
                  SearchableDropdownItem(value: 'Shortage Only', label: 'عجز طرود فقط (Shortage Only)'),
                  SearchableDropdownItem(value: 'Damage Only', label: 'تلف وكسر بضائع فقط (Damage Only)'),
                  SearchableDropdownItem(value: 'Broken Seal Discrepancy', label: 'كسر سيل وتباين مشمول (Broken Seal)'),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDiscrepancyType = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات وتفاصيل الفحص *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة الملاحظات' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('عزل البضاعة في منطقة الحجر (Quarantine Zone)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _quarantineAssigned,
                onChanged: (val) => setState(() => _quarantineAssigned = val),
              ),
              SwitchListTile(
                title: const Text('رفع مطالبة تعويض تأمين بحري (Insurance Claim)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _fileClaim,
                onChanged: (val) => setState(() => _fileClaim = val),
              ),
              if (_fileClaim) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _claimRefCtrl,
                  decoration: const InputDecoration(labelText: 'رقم مرجع المطالبة التأمينية', border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
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
                      messenger.showSnackBar(const SnackBar(content: Text('تم توثيق محضر العجز والتلف بنجاح'), backgroundColor: AppTheme.emerald));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('اعتماد محضر العجز والتلف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
