import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../freight_booking/providers/freight_booking_provider.dart';
import '../models/cargo_shipping_model.dart';
import '../providers/cargo_shipping_provider.dart';

class CargoShippingScreen extends ConsumerStatefulWidget {
  const CargoShippingScreen({super.key});

  @override
  ConsumerState<CargoShippingScreen> createState() => _CargoShippingScreenState();
}

class _CargoShippingScreenState extends ConsumerState<CargoShippingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cargoShippingProvider.notifier).fetchRecords();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(freightBookingProvider.notifier).fetchBookings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([CargoShippingModel? recordToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CargoShippingFormDialog(recordToEdit: recordToEdit),
    );
  }

  void _showCargoXDialog(CargoShippingModel record) {
    showDialog(
      context: context,
      builder: (context) => _CargoXExchangeDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(cargoShippingProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('تجهيز وشحن البضائع والتبادل الإلكتروني (Phase 5 - Cargo Preparation & CargoX)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(cargoShippingProvider.notifier).fetchRecords(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar
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
                      icon: const Icon(Icons.add_location_alt, color: Colors.white),
                      label: const Text('تسجيل متابعة شحنة جديدة (New Cargo Shipping)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود الشحن أو المسئول...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(cargoShippingProvider.notifier).fetchRecords(search: val, status: _selectedStatusFilter);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 220,
                      child: SearchableDropdownField<String>(
                        value: _selectedStatusFilter,
                        labelText: 'تصفية حسب الحالة',
                        searchHintText: 'ابحث عن الحالة...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                          SearchableDropdownItem(value: 'Cargo Ready', label: 'Cargo Ready (جاهزية البضاعة)'),
                          SearchableDropdownItem(value: 'Loaded & Sealed', label: 'Loaded & Sealed (مُحمل ومختوم)'),
                          SearchableDropdownItem(value: 'Dual Approved', label: 'Dual Approved (معتمد ثنائياً)'),
                          SearchableDropdownItem(value: 'CargoX Transfer Completed', label: 'CargoX Completed'),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                            ref.read(cargoShippingProvider.notifier).fetchRecords(search: _searchController.text, status: val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Master DataTable
            Expanded(
              child: recordsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('❌ Error: $err', style: const TextStyle(color: Colors.red))),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('لا توجد سجلات تجهيز وشحن بضائع مسجلة. اضغط تسجيل شحنة جديدة.', style: TextStyle(fontSize: 16)));
                  }
                  return Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: const [
                            DataColumn(label: Text('كود الشحن', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('جاهزية البضاعة (CRD / Cut-off)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('مطابقة المواعيد', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحاويات والرصاص الأمني', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الاعتماد الثنائي (Dual Approval)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المستندات الأصلية (DHL/FedEx)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('التبادل الإلكتروني (CargoX)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة العامة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: records.map((rec) {
                            final isDualPassed = rec.dualApprovalStatus == 'Dual Approved';
                            return DataRow(
                              cells: [
                                DataCell(Text(rec.cargoShippingCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.charcoal.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rec.importFileCode ?? 'IMP-${rec.importFileId}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('CRD: ${rec.crdDate != null ? rec.crdDate!.substring(0, 10) : "-"}'),
                                      Text('Cut-off: ${rec.cargoCutoffDate != null ? rec.cargoCutoffDate!.substring(0, 10) : "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(rec.isCrdValidated ? 'مطابق' : 'متأخر عن Cut-off', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                    backgroundColor: rec.isCrdValidated ? Colors.green : Colors.red,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    rec.containersLoadingData.map((c) => '${c.containerNo} (${c.sealNo})').join(', '),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(
                                        isDualPassed ? Icons.verified : Icons.hourglass_top,
                                        color: isDualPassed ? Colors.green : Colors.orange,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(rec.dualApprovalStatus, style: TextStyle(fontWeight: FontWeight.bold, color: isDualPassed ? Colors.green : Colors.orange)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${rec.courierTrackingData.courierProvider}: ${rec.courierTrackingData.trackingNumber ?? "-"}', style: const TextStyle(fontSize: 11)),
                                      Text(rec.courierTrackingData.receiptStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                    onPressed: () => _showCargoXDialog(rec),
                                    icon: const Icon(Icons.cloud_upload, color: Colors.white, size: 14),
                                    label: Text(rec.cargoxExchangeData.envelopeStatus, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(rec.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: rec.status == 'Dual Approved' || rec.status == 'CargoX Transfer Completed' ? AppTheme.emerald : Colors.blueGrey,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.rate_review, color: AppTheme.cobalt, size: 18),
                                        tooltip: 'تعديل والاعتماد الثنائي',
                                        onPressed: () => _showAddEditDialog(rec),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        tooltip: 'حذف لطفياً',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text('تأكيد الحذف'),
                                              content: Text('هل أنت تأكد من حذف سجل شحن البضاعة ${rec.cargoShippingCode}؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(cargoShippingProvider.notifier).softDeleteRecord(rec.cargoShippingId);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald, size: 18),
                                        tooltip: 'استعادة السجل',
                                        onPressed: () async {
                                          await ref.read(cargoShippingProvider.notifier).restoreRecord(rec.cargoShippingId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('✅ تم استعادة سجل الشحن ${rec.cargoShippingCode} بنجاح'), backgroundColor: AppTheme.emerald),
                                            );
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
}

class _CargoShippingFormDialog extends ConsumerStatefulWidget {
  final CargoShippingModel? recordToEdit;
  const _CargoShippingFormDialog({this.recordToEdit});

  @override
  ConsumerState<_CargoShippingFormDialog> createState() => _CargoShippingFormDialogState();
}

class _CargoShippingFormDialogState extends ConsumerState<_CargoShippingFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedImportFileId;
  DateTime _crdDate = DateTime.now().add(const Duration(days: 2));
  DateTime _cargoCutoffDate = DateTime.now().add(const Duration(days: 5));

  late TextEditingController _courierProviderController;
  late TextEditingController _trackingNoController;
  late TextEditingController _liveTrackingUrlController;
  late TextEditingController _level1NotesController;
  late TextEditingController _level2NotesController;

  List<ContainerLoadingModel> _containers = [];
  String _receiptStatus = 'Dispatched';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    _selectedImportFileId = r?.importFileId;
    _courierProviderController = TextEditingController(text: r?.courierTrackingData.courierProvider ?? 'DHL Express');
    _trackingNoController = TextEditingController(text: r?.courierTrackingData.trackingNumber ?? 'DHL-9876543210');
    _liveTrackingUrlController = TextEditingController(text: r?.liveTrackingUrl ?? 'https://www.msc.com/track/?number=MSCU1234567');
    _level1NotesController = TextEditingController(text: r?.level1Notes ?? '');
    _level2NotesController = TextEditingController(text: r?.level2Notes ?? '');
    _receiptStatus = r?.courierTrackingData.receiptStatus ?? 'Dispatched';

    if (r?.containersLoadingData != null && r!.containersLoadingData.isNotEmpty) {
      _containers = List.from(r.containersLoadingData);
    } else {
      _containers = [
        ContainerLoadingModel(containerNo: 'MSCU1234567', sealNo: 'SL-99001', tareWeightKg: 3800, netWeightKg: 20700, grossWeightKg: 24500, vgmStatus: 'Submitted', vgmRefNo: 'VGM-9901')
      ];
    }
  }

  @override
  void dispose() {
    _courierProviderController.dispose();
    _trackingNoController.dispose();
    _liveTrackingUrlController.dispose();
    _level1NotesController.dispose();
    _level2NotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار ملف الشحنة الاستيرادية'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'crd_date': _crdDate.toIso8601String(),
        'cargo_cutoff_date': _cargoCutoffDate.toIso8601String(),
        'containers_loading_data': _containers.map((c) => c.toJson()).toList(),
        'courier_tracking_data': {
          'courier_provider': _courierProviderController.text.trim(),
          'tracking_number': _trackingNoController.text.trim(),
          'dispatch_date': DateTime.now().toIso8601String(),
          'receipt_status': _receiptStatus,
        },
        'live_tracking_url': _liveTrackingUrlController.text.trim(),
        'status': 'Cargo Ready',
        'owner': 'Kamal',
      };

      if (widget.recordToEdit == null) {
        await ref.read(cargoShippingProvider.notifier).createRecord(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم حفظ بيانات التحميل ومتابعة الشحن بنجاح!'), backgroundColor: AppTheme.emerald));
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
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final r = widget.recordToEdit;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.local_shipping, color: AppTheme.cobalt),
          const SizedBox(width: 8),
          Text(r == null ? 'تسجيل متابعة وتحميل شحنة جديدة (New Cargo Shipping)' : 'تحديث سجل الشحن والاعتماد الثنائي: ${r.cargoShippingCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 800,
        height: 550,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Cargo Readiness Date (CRD)
                SearchableDropdownField<int?>(
                  value: _selectedImportFileId,
                  labelText: 'ملف الشحنة الاستيرادية المرتبط *',
                  searchHintText: 'ابحث عن ملف الشحنة بالرقم أو اسم الشركة...',
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '${f.customFileNumber ?? f.importFileCode} (${f.companyName})',
                            subtitle: f.supplierName,
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _crdDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _crdDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'تاريخ جاهزية البضاعة (Cargo Ready Date - CRD) *', border: OutlineInputBorder()),
                          child: Text(_crdDate.toString().substring(0, 10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _cargoCutoffDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) setState(() => _cargoCutoffDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'موعد قطع البضاعة (Cargo Cut-off Date) *', border: OutlineInputBorder()),
                          child: Text(_cargoCutoffDate.toString().substring(0, 10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 2: Containers & Seals
                Row(
                  children: [
                    const Text('بيانات أرقام الحاويات والرصاص الأمني والأوزان (VGM):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _containers.add(ContainerLoadingModel(containerNo: 'MSCU0000000', sealNo: 'SL-00000', grossWeightKg: 20000));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة حاوية'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _containers.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _containers[index];
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.containerNo,
                            decoration: const InputDecoration(labelText: 'رقم الحاوية (Container No)', border: OutlineInputBorder()),
                            onChanged: (v) {
                              setState(() {
                                _containers[index] = ContainerLoadingModel(
                                  containerNo: v,
                                  sealNo: item.sealNo,
                                  tareWeightKg: item.tareWeightKg,
                                  netWeightKg: item.netWeightKg,
                                  grossWeightKg: item.grossWeightKg,
                                  vgmStatus: item.vgmStatus,
                                  vgmRefNo: item.vgmRefNo,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.sealNo,
                            decoration: const InputDecoration(labelText: 'الختم الرصاصي (Seal No)', border: OutlineInputBorder()),
                            onChanged: (v) {
                              setState(() {
                                _containers[index] = ContainerLoadingModel(
                                  containerNo: item.containerNo,
                                  sealNo: v,
                                  tareWeightKg: item.tareWeightKg,
                                  netWeightKg: item.netWeightKg,
                                  grossWeightKg: item.grossWeightKg,
                                  vgmStatus: item.vgmStatus,
                                  vgmRefNo: item.vgmRefNo,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.grossWeightKg.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الوزن القائم (Gross Kg)', border: OutlineInputBorder()),
                            onChanged: (v) {
                              final w = double.tryParse(v) ?? 0.0;
                              setState(() {
                                _containers[index] = ContainerLoadingModel(
                                  containerNo: item.containerNo,
                                  sealNo: item.sealNo,
                                  tareWeightKg: item.tareWeightKg,
                                  netWeightKg: item.netWeightKg,
                                  grossWeightKg: w,
                                  vgmStatus: item.vgmStatus,
                                  vgmRefNo: item.vgmRefNo,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Section 3: Dual Approval Status (If Editing)
                if (r != null) ...[
                  const Text('الاعتماد الثنائي للمستندات الصادرة (BP-022 Dual Approval):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt)),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.blueGrey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Level 1 (Operational Review): ${r.level1ApprovalStatus}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: () async {
                                  await ref.read(cargoShippingProvider.notifier).submitLevel1Approval(r.cargoShippingId, 'Operational Lead', true, notes: 'تم تدقيق أرقام الحاويات والـ ACID');
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                                child: const Text('اعتماد المستوى 1', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Text('Level 2 (Management Review): ${r.level2ApprovalStatus}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                                onPressed: () async {
                                  try {
                                    await ref.read(cargoShippingProvider.notifier).submitLevel2Approval(r.cargoShippingId, 'Import Manager', true, notes: 'اعتماد ثنائي نهائي');
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
                                  }
                                },
                                child: const Text('اعتماد المستوى 2 النهائي', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section 4: Original Documents & Courier
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _courierProviderController,
                        decoration: const InputDecoration(labelText: 'شركة البريد السريع (Express Courier)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _trackingNoController,
                        decoration: const InputDecoration(labelText: 'رقم تتبع الشحنة البريدية', border: OutlineInputBorder()),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
          label: const Text('حفظ السجل بالكامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _CargoXExchangeDialog extends ConsumerStatefulWidget {
  final CargoShippingModel record;
  const _CargoXExchangeDialog({required this.record});

  @override
  ConsumerState<_CargoXExchangeDialog> createState() => _CargoXExchangeDialogState();
}

class _CargoXExchangeDialogState extends ConsumerState<_CargoXExchangeDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cargox = widget.record.cargoxExchangeData;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cloud_upload, color: AppTheme.cobalt),
          const SizedBox(width: 8),
          Text('منظومة التبادل الإلكتروني للمستندات (CargoX Platform): ${widget.record.cargoShippingCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('منصة التبادل: ${cargox.platformProvider}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('رقم المظروف: ${cargox.envelopeId ?? "لم يُنشأ بعد"}'),
                          Text('رمز البلوكشين (Blockchain Hash): ${cargox.blockchainTxHash ?? "غير متوفر"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(cargox.envelopeStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: cargox.envelopeStatus == 'Uploaded' || cargox.envelopeStatus == 'Completed' ? AppTheme.emerald : Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('قائمة الفحص والمراجعة الآلية (Document Verification Rules):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (cargox.verificationChecklist.isEmpty)
                const Text('لم يتم تشغيل قائمة المراجعة الآلية بعد. اضغط زر تشغيل الفحص بالأسفل.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cargox.verificationChecklist.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = cargox.verificationChecklist[index];
                    return ListTile(
                      leading: Icon(
                        item.passed ? Icons.check_circle : Icons.cancel,
                        color: item.passed ? Colors.green : Colors.red,
                      ),
                      title: Text(item.ruleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.details ?? ''),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(cargoShippingProvider.notifier).runCargoXChecklist(widget.record.cargoShippingId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          icon: const Icon(Icons.rule, color: Colors.white),
          label: const Text('1. تشغيل الفحص التلقائي (Run Checklist)', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(cargoShippingProvider.notifier).advanceCargoXStage(widget.record.cargoShippingId, 'Uploaded');
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          icon: const Icon(Icons.cloud_upload, color: Colors.white),
          label: const Text('2. رفع المظروف على CargoX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
