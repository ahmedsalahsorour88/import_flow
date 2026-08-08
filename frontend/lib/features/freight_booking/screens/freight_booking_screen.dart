import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/freight_booking_model.dart';
import '../providers/freight_booking_provider.dart';

class FreightBookingScreen extends ConsumerStatefulWidget {
  const FreightBookingScreen({super.key});

  @override
  ConsumerState<FreightBookingScreen> createState() => _FreightBookingScreenState();
}

class _FreightBookingScreenState extends ConsumerState<FreightBookingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  void _showAddEditBookingDialog([ShipmentBookingModel? bookingToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FreightBookingFormDialog(bookingToEdit: bookingToEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(freightBookingProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.directions_boat, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('حجز الشحن وتخصيص الحاويات (Freight Booking & Carrier Allocation - Phase 4)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(freightBookingProvider.notifier).fetchBookings(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showAddEditBookingDialog(),
                      icon: const Icon(Icons.add_task, color: Colors.white),
                      label: const Text('إنشاء حجز شحن جديد (Create Booking)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود الحجز أو رقم التأكيد...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(freightBookingProvider.notifier).fetchBookings(search: val, status: _selectedStatusFilter);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedStatusFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                        DropdownMenuItem(value: 'Draft', child: Text('Draft (مسودة)')),
                        DropdownMenuItem(value: 'Booking Requested', child: Text('Booking Requested (تم الطلب)')),
                        DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed (مؤكد)')),
                        DropdownMenuItem(value: 'Sailed', child: Text('Sailed (أبحر)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatusFilter = val);
                          ref.read(freightBookingProvider.notifier).fetchBookings(search: _searchController.text, status: val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Master DataTable
            Expanded(
              child: bookingsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('❌ Error: $err', style: const TextStyle(color: Colors.red))),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(child: Text('لا توجد حجوزات شحن مسجلة بالنظام. اضغط إضافة حجز جديد.', style: TextStyle(fontSize: 16)));
                  }
                  return Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: const [
                            DataColumn(label: Text('رقم كود الحجز', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('رقم تأكيد الحجز (Booking Confirmation)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الخط الملاحي / الوكيل', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('موانئ الشحن (POL -> POD)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('السفينة / رقم الرحلة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المغادرة ETD / الوصول ETA', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('مدة الترانزيت', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحاويات المخصصة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجمالي النولون USD', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: bookings.map((bkg) {
                            return DataRow(
                              cells: [
                                DataCell(Text(bkg.bookingCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                DataCell(Text(bkg.bookingConfirmationNo ?? 'Draft Pending', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(bkg.shippingLineName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('FWD: ${bkg.freightForwarderName ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text('${bkg.polName ?? "-"} -> ${bkg.podName ?? "-"}')),
                                DataCell(Text('${bkg.vesselName ?? "-"} (${bkg.voyageNumber ?? "-"})')),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ETD: ${bkg.etd != null ? bkg.etd!.substring(0, 10) : "-"}'),
                                      Text('ETA: ${bkg.eta != null ? bkg.eta!.substring(0, 10) : "-"}', style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataCell(Text('${bkg.transitTimeDays} يوم')),
                                DataCell(
                                  Text(
                                    bkg.containersData.map((c) => '${c.quantity}x ${c.containerType}').join(', '),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataCell(Text('\$ ${bkg.totalFreightCostUsd.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                DataCell(
                                  Chip(
                                    label: Text(bkg.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: bkg.status == 'Confirmed' || bkg.status == 'Sailed' ? Colors.green : Colors.orange,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                                        onPressed: () => _showAddEditBookingDialog(bkg),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text('تأكيد الحذف'),
                                              content: Text('هل أنت تأكد من حذف حجز الشحن ${bkg.bookingCode}؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(freightBookingProvider.notifier).softDeleteBooking(bkg.bookingId);
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

class _FreightBookingFormDialog extends ConsumerStatefulWidget {
  final ShipmentBookingModel? bookingToEdit;
  const _FreightBookingFormDialog({this.bookingToEdit});

  @override
  ConsumerState<_FreightBookingFormDialog> createState() => _FreightBookingFormDialogState();
}

class _FreightBookingFormDialogState extends ConsumerState<_FreightBookingFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bookingConfirmNoController;
  late TextEditingController _polController;
  late TextEditingController _podController;
  late TextEditingController _vesselNameController;
  late TextEditingController _voyageNoController;
  late TextEditingController _releaseOrderNoController;
  late TextEditingController _freeDemurrageController;
  late TextEditingController _ownerController;
  late TextEditingController _notesController;

  int? _selectedImportFileId;
  String _shipmentType = 'Ocean FCL';
  String _freightTerms = 'Collect';
  String _status = 'Draft';
  String _shippingLineName = 'Mediterranean Shipping Company (MSC)';
  String _freightForwarderName = 'El-Ahram Logistics';

  DateTime _etd = DateTime.now().add(const Duration(days: 5));
  DateTime _eta = DateTime.now().add(const Duration(days: 23));

  List<ContainerAllocationModel> _containers = [];
  List<BookingChargeModel> _charges = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bookingToEdit;
    _bookingConfirmNoController = TextEditingController(text: b?.bookingConfirmationNo ?? 'MSC-CN-889001');
    _polController = TextEditingController(text: b?.polName ?? 'Shanghai Port (CNSHA)');
    _podController = TextEditingController(text: b?.podName ?? 'Alexandria Port (EGALY)');
    _vesselNameController = TextEditingController(text: b?.vesselName ?? 'MSC Oscar');
    _voyageNoController = TextEditingController(text: b?.voyageNumber ?? 'VY-2026-X8');
    _releaseOrderNoController = TextEditingController(text: b?.containerReleaseOrderNo ?? 'RO-MSC-9912');
    _freeDemurrageController = TextEditingController(text: (b?.freeDemurrageDays ?? 14).toString());
    _ownerController = TextEditingController(text: b?.owner ?? 'Kamal');
    _notesController = TextEditingController(text: b?.notes ?? '');

    _selectedImportFileId = b?.importFileId;
    _shipmentType = b?.shipmentType ?? 'Ocean FCL';
    _freightTerms = b?.freightTerms ?? 'Collect';
    _status = b?.status ?? 'Draft';
    _shippingLineName = b?.shippingLineName ?? 'Mediterranean Shipping Company (MSC)';
    _freightForwarderName = b?.freightForwarderName ?? 'El-Ahram Logistics';

    if (b?.containersData != null && b!.containersData.isNotEmpty) {
      _containers = List.from(b.containersData);
    } else {
      _containers = [
        ContainerAllocationModel(containerType: '40HC', quantity: 2, containerNumbers: ['MSCU1234567', 'MSCU7654321'], sealNumbers: ['SL-99001', 'SL-99002'], vgmWeightKg: 24500)
      ];
    }

    if (b?.costChargesData != null && b!.costChargesData.isNotEmpty) {
      _charges = List.from(b.costChargesData);
    } else {
      _charges = [
        BookingChargeModel(chargeType: 'Sea Freight', unit: 'Per Container', quantity: 2, currency: 'USD', rate: 2200, total: 4400),
        BookingChargeModel(chargeType: 'THC', unit: 'Per Container', quantity: 2, currency: 'USD', rate: 350, total: 700),
        BookingChargeModel(chargeType: 'BL Fee', unit: 'Per Shipment', quantity: 1, currency: 'USD', rate: 80, total: 80),
      ];
    }
  }

  @override
  void dispose() {
    _bookingConfirmNoController.dispose();
    _polController.dispose();
    _podController.dispose();
    _vesselNameController.dispose();
    _voyageNoController.dispose();
    _releaseOrderNoController.dispose();
    _freeDemurrageController.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'booking_confirmation_no': _bookingConfirmNoController.text.trim(),
        'import_file_id': _selectedImportFileId,
        'freight_forwarder_name': _freightForwarderName,
        'shipping_line_name': _shippingLineName,
        'shipment_type': _shipmentType,
        'pol_name': _polController.text.trim(),
        'pod_name': _podController.text.trim(),
        'etd': _etd.toIso8601String(),
        'eta': _eta.toIso8601String(),
        'free_demurrage_days': int.tryParse(_freeDemurrageController.text.trim()) ?? 14,
        'vessel_name': _vesselNameController.text.trim(),
        'voyage_number': _voyageNoController.text.trim(),
        'container_release_order_no': _releaseOrderNoController.text.trim(),
        'freight_terms': _freightTerms,
        'containers_data': _containers.map((c) => c.toJson()).toList(),
        'cost_charges_data': _charges.map((c) => c.toJson()).toList(),
        'status': _status,
        'owner': _ownerController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      if (widget.bookingToEdit == null) {
        await ref.read(freightBookingProvider.notifier).createBooking(payload);
      } else {
        await ref.read(freightBookingProvider.notifier).updateBooking(widget.bookingToEdit!.bookingId, payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم حفظ وتأكيد حجز الشحن بنجاح!'), backgroundColor: AppTheme.emerald));
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

    return DefaultTabController(
      length: 3,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.directions_boat, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text(widget.bookingToEdit == null ? 'إنشاء حجز شحن جديد (New Carrier Booking)' : 'تعديل حجز الشحن: ${widget.bookingToEdit!.bookingCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 850,
          height: 600,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.cobalt,
                tabs: [
                  Tab(icon: Icon(Icons.description), text: '1. تفاصيل الحجز والموانئ'),
                  Tab(icon: Icon(Icons.inventory_2), text: '2. تخصيص الحاويات والمعدات'),
                  Tab(icon: Icon(Icons.attach_money), text: '3. بنود التكلفة والنولون'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    children: [
                      // Tab 1: Booking Details & Route
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    value: _selectedImportFileId,
                                    decoration: const InputDecoration(labelText: 'ملف الشحنة الاستيرادية (Import File)', border: OutlineInputBorder()),
                                    items: importFiles.map((f) => DropdownMenuItem<int?>(value: f.importFileId, child: Text('${f.customFileNumber ?? f.importFileCode} (${f.companyName})'))).toList(),
                                    onChanged: (val) => setState(() => _selectedImportFileId = val),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _bookingConfirmNoController,
                                    decoration: const InputDecoration(labelText: 'رقم تأكيد الحجز (Booking Confirmation No) *', border: OutlineInputBorder()),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم تأكيد الحجز' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _shippingLineName,
                                    decoration: const InputDecoration(labelText: 'الخط الملاحي (Shipping Line) *', border: OutlineInputBorder()),
                                    onChanged: (v) => _shippingLineName = v,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _freightForwarderName,
                                    decoration: const InputDecoration(labelText: 'وكيل الشحن (Freight Forwarder)', border: OutlineInputBorder()),
                                    onChanged: (v) => _freightForwarderName = v,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _polController,
                                    decoration: const InputDecoration(labelText: 'ميناء التحميل (POL) *', border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _podController,
                                    decoration: const InputDecoration(labelText: 'ميناء الوصول (POD) *', border: OutlineInputBorder()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(context: context, initialDate: _etd, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                      if (d != null) setState(() => _etd = d);
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'تاريخ المغادرة المتوقع (ETD) *', border: OutlineInputBorder()),
                                      child: Text(_etd.toString().substring(0, 10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(context: context, initialDate: _eta, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                      if (d != null) setState(() => _eta = d);
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'تاريخ الوصول المتوقع (ETA) *', border: OutlineInputBorder()),
                                      child: Text(_eta.toString().substring(0, 10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _freeDemurrageController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'الأيام المجانية (Free Days) *', border: OutlineInputBorder()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _vesselNameController,
                                    decoration: const InputDecoration(labelText: 'اسم السفينة (Vessel Name)', border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _voyageNoController,
                                    decoration: const InputDecoration(labelText: 'رقم الرحلة (Voyage No)', border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _status,
                                    decoration: const InputDecoration(labelText: 'حالة الحجز (Status) *', border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                                      DropdownMenuItem(value: 'Booking Requested', child: Text('Booking Requested')),
                                      DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                                      DropdownMenuItem(value: 'Sailed', child: Text('Sailed')),
                                    ],
                                    onChanged: (v) => setState(() => _status = v!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Container Equipment Allocation
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('بيانات الحاويات والمعدات المخصصة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _containers.add(ContainerAllocationModel(containerType: '20GP', quantity: 1, vgmWeightKg: 12000));
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة نوع حااوية جديد'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                      child: DropdownButtonFormField<String>(
                                        value: item.containerType,
                                        decoration: const InputDecoration(labelText: 'نوع الحاوية', border: OutlineInputBorder()),
                                        items: const [
                                          DropdownMenuItem(value: '20GP', child: Text('20GP Standard')),
                                          DropdownMenuItem(value: '40GP', child: Text('40GP Standard')),
                                          DropdownMenuItem(value: '40HC', child: Text('40HC High Cube')),
                                          DropdownMenuItem(value: '45HC', child: Text('45HC High Cube')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _containers[index] = ContainerAllocationModel(
                                                containerType: val,
                                                quantity: item.quantity,
                                                containerNumbers: item.containerNumbers,
                                                sealNumbers: item.sealNumbers,
                                                vgmWeightKg: item.vgmWeightKg,
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.quantity.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'العدد (Qty)', border: OutlineInputBorder()),
                                        onChanged: (val) {
                                          final q = int.tryParse(val) ?? 1;
                                          setState(() {
                                            _containers[index] = ContainerAllocationModel(
                                              containerType: item.containerType,
                                              quantity: q,
                                              containerNumbers: item.containerNumbers,
                                              sealNumbers: item.sealNumbers,
                                              vgmWeightKg: item.vgmWeightKg,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.vgmWeightKg.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'وزن VGM (Kg)', border: OutlineInputBorder()),
                                        onChanged: (val) {
                                          final w = double.tryParse(val) ?? 0.0;
                                          setState(() {
                                            _containers[index] = ContainerAllocationModel(
                                              containerType: item.containerType,
                                              quantity: item.quantity,
                                              containerNumbers: item.containerNumbers,
                                              sealNumbers: item.sealNumbers,
                                              vgmWeightKg: w,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _containers.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Tab 3: Cost Breakdown
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('جدول بنود التكلفة والنولون الأولية (Freight Charges):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _charges.add(BookingChargeModel(chargeType: 'Sea Freight', unit: 'Per Container', quantity: 1, rate: 1000));
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة بند تكلفة'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _charges.length,
                              separatorBuilder: (c, i) => const Divider(),
                              itemBuilder: (context, index) {
                                final c = _charges[index];
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: c.chargeType,
                                        decoration: const InputDecoration(labelText: 'نوع البند', border: OutlineInputBorder()),
                                        onChanged: (val) {
                                          setState(() {
                                            _charges[index] = BookingChargeModel(
                                              chargeType: val,
                                              unit: c.unit,
                                              quantity: c.quantity,
                                              currency: c.currency,
                                              rate: c.rate,
                                              total: c.rate * c.quantity,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<String>(
                                        value: c.unit,
                                        decoration: const InputDecoration(labelText: 'وحدة الاحتساب', border: OutlineInputBorder()),
                                        items: const [
                                          DropdownMenuItem(value: 'Per Container', child: Text('Per Container')),
                                          DropdownMenuItem(value: 'Per Shipment', child: Text('Per Shipment')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _charges[index] = BookingChargeModel(
                                                chargeType: c.chargeType,
                                                unit: val,
                                                quantity: c.quantity,
                                                currency: c.currency,
                                                rate: c.rate,
                                                total: c.rate * c.quantity,
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        initialValue: c.rate.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'السعر (Rate)', border: OutlineInputBorder()),
                                        onChanged: (val) {
                                          final r = double.tryParse(val) ?? 0.0;
                                          setState(() {
                                            _charges[index] = BookingChargeModel(
                                              chargeType: c.chargeType,
                                              unit: c.unit,
                                              quantity: c.quantity,
                                              currency: c.currency,
                                              rate: r,
                                              total: r * c.quantity,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _charges.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
            label: const Text('حفظ حجز الشحن بالكامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
