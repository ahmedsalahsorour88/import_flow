import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/warehouse_receiving_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(warehouseReceivingProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.inventory, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('استلام البضائع بالخزائن والجودة (Phase 8 - Warehouse Receiving & GRN)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(warehouseReceivingProvider.notifier).fetchRecords(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.local_shipping, color: Colors.white),
                      label: const Text('تسجيل وصول شاحنة واستلام محضر GRN جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
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
                          SearchableDropdownItem(value: 'Goods Received', label: 'Goods Received (تم الوصول والأطقم)'),
                          SearchableDropdownItem(value: 'Discrepancy Reported', label: 'Discrepancy Reported (مُثبت به عجز/تلف)'),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(r.grnCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(r.warehouseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 12),
                                  _buildSealBadge(r.sealIntact, r.sealNumber),
                                  const Spacer(),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (r.discrepancyType == 'None' || !r.quarantineZoneAssigned) ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange),
                                      icon: const Icon(Icons.warning_amber, size: 16, color: Colors.white),
                                      label: const Text('إثبات عجز/تلف وتوجيه للعزل Quarantine (BP-035)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showDiscrepancyDialog(r),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
                                    tooltip: 'حذف لطفياً',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('حذف محضر الاستلام'),
                                          content: const Text('هل أنت تأكد من نقل محضر الاستلام للمحذوفات؟'),
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
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald),
                                    tooltip: 'استعادة السجل',
                                    onPressed: () async {
                                      await ref.read(warehouseReceivingProvider.notifier).restoreRecord(r.receivingId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('✅ تم استعادة محضر الاستلام ${r.grnCode} بنجاح'), backgroundColor: AppTheme.emerald),
                                        );
                                      }
                                    },
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
    if (status == 'Discrepancy Reported') color = AppTheme.orange;
    if (status == 'Closed') color = AppTheme.emerald;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
    );
  }
}

// -----------------------------------------------------------------------------
// FORM DIALOGS
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

  late TextEditingController _itemCodeCtrl;
  late TextEditingController _itemNameCtrl;
  late TextEditingController _invQtyCtrl;
  late TextEditingController _accQtyCtrl;
  late TextEditingController _shortQtyCtrl;
  late TextEditingController _dmgQtyCtrl;

  bool _isLoading = false;

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

    _itemCodeCtrl = TextEditingController(text: 'ITM-001');
    _itemNameCtrl = TextEditingController(text: 'Imported Cargo Items');
    _invQtyCtrl = TextEditingController(text: '100');
    _accQtyCtrl = TextEditingController(text: '100');
    _shortQtyCtrl = TextEditingController(text: '0');
    _dmgQtyCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _whCtrl.dispose();
    _plateCtrl.dispose();
    _driverCtrl.dispose();
    _sealCtrl.dispose();
    _itemCodeCtrl.dispose();
    _itemNameCtrl.dispose();
    _invQtyCtrl.dispose();
    _accQtyCtrl.dispose();
    _shortQtyCtrl.dispose();
    _dmgQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return AlertDialog(
      title: Text(widget.recordToEdit == null ? 'تسجيل محضر استلام شحنة جديدة بالمخزن' : 'تعديل بيانات المحضر'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdownField<int?>(
                  value: _selectedImportFileId,
                  labelText: 'ملف الشحنة الاستيرادية *',
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                  validator: (v) => v == null ? 'يرجى اختيار ملف الشحنة' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المخزن والفرع *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المخزن' : null,
                ),
                const SizedBox(height: 12),
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sealCtrl,
                        decoration: const InputDecoration(labelText: 'رقم السيل / الرصاص الأمني', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('سلامة السيل (Seal Intact)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        value: _sealIntact,
                        onChanged: (val) => setState(() => _sealIntact = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // GRN Line Item Setup
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('بيانات جرد واختبار كميات الصنف المستلم (GRN Audit):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemCodeCtrl,
                        decoration: const InputDecoration(labelText: 'كود الصنف', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _itemNameCtrl,
                        decoration: const InputDecoration(labelText: 'اسم الصنف', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _invQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية بالفاتورة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _accQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية المقبولة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _shortQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'العجز', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _dmgQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'التلف', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final itemData = {
                        'item_code': _itemCodeCtrl.text.trim(),
                        'item_name': _itemNameCtrl.text.trim(),
                        'invoiced_qty': int.tryParse(_invQtyCtrl.text.trim()) ?? 0,
                        'accepted_qty': int.tryParse(_accQtyCtrl.text.trim()) ?? 0,
                        'shortage_qty': int.tryParse(_shortQtyCtrl.text.trim()) ?? 0,
                        'damaged_qty': int.tryParse(_dmgQtyCtrl.text.trim()) ?? 0,
                      };

                      final payload = {
                        'import_file_id': _selectedImportFileId,
                        'warehouse_name': _whCtrl.text.trim(),
                        'truck_plate_number': _plateCtrl.text.trim(),
                        'driver_name': _driverCtrl.text.trim(),
                        'seal_number': _sealCtrl.text.trim(),
                        'seal_intact': _sealIntact,
                        'grn_items': [itemData],
                      };

                      await ref.read(warehouseReceivingProvider.notifier).createRecord(payload);
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تسجيل وإصدار GRN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _DiscrepancyReportDialog extends ConsumerStatefulWidget {
  final WarehouseReceivingModel record;
  const _DiscrepancyReportDialog({required this.record});

  @override
  ConsumerState<_DiscrepancyReportDialog> createState() => _DiscrepancyReportDialogState();
}

class _DiscrepancyReportDialogState extends ConsumerState<_DiscrepancyReportDialog> {
  final _formKey = GlobalKey<FormState>();
  String _discrepancyType = 'Shortage';
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _claimRefCtrl = TextEditingController();
  bool _quarantineAssigned = true;
  bool _insuranceClaimFiled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _claimRefCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إثبات عجز/تلفيات ومطالبة تأمين (${widget.record.grnCode})'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchableDropdownField<String>(
                value: _discrepancyType,
                labelText: 'نوع الاختلاف/المحضر *',
                items: const [
                  SearchableDropdownItem(value: 'Shortage', label: 'Shortage (عجز بالكميات)'),
                  SearchableDropdownItem(value: 'Damage', label: 'Damage (بضاعة تالفة)'),
                  SearchableDropdownItem(value: 'Excess', label: 'Excess (زيادة غير مسجلة)'),
                  SearchableDropdownItem(value: 'Wrong Item', label: 'Wrong Item (صنف مخالف)'),
                ],
                onChanged: (v) => setState(() => _discrepancyType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'تفاصيل وملاحظات المحضر والدليل *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال ملاحظات الفحص' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('توجيه للمنطقة المعزولة (Quarantine Zone)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _quarantineAssigned,
                onChanged: (v) => setState(() => _quarantineAssigned = v),
              ),
              SwitchListTile(
                title: const Text('إصدار مطالبة شركة التأمين (Insurance Claim)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: _insuranceClaimFiled,
                onChanged: (v) => setState(() => _insuranceClaimFiled = v),
              ),
              if (_insuranceClaimFiled) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _claimRefCtrl,
                  decoration: const InputDecoration(labelText: 'رقم مرجع مطالبة التأمين', border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final payload = {
                        'discrepancy_type': _discrepancyType,
                        'discrepancy_notes': _notesCtrl.text.trim(),
                        'quarantine_zone_assigned': _quarantineAssigned,
                        'insurance_claim_filed': _insuranceClaimFiled,
                        'insurance_claim_ref': _claimRefCtrl.text.trim().isNotEmpty ? _claimRefCtrl.text.trim() : null,
                      };
                      await ref.read(warehouseReceivingProvider.notifier).reportDiscrepancy(widget.record.receivingId, payload);
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ في إثبات المحضر: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تأكيد المحضر والعزل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
