import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../shipping_scenarios/models/shipping_scenario_model.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(freightBookingProvider.notifier).fetchBookings();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(partnersProvider.notifier).fetchPartners();
      ref.read(transportLocationsProvider.notifier).fetchLocations();
      ref.read(shippingScenariosProvider.notifier).fetchSessions();
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      ref.read(currenciesProvider.notifier).fetchCurrencies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditBookingDialog([ShipmentBookingModel? bookingToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FreightBookingFormDialog(bookingToEdit: bookingToEdit),
    );
  }

  void _showViewBookingDialog(ShipmentBookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => _FreightBookingViewDialog(booking: booking),
    );
  }

  void _showPrintBookingDialog(ShipmentBookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => _FreightBookingPrintDialog(booking: booking),
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
            Text(
              'حجز الشحن وتخصيص الحاويات (Freight Booking & Carrier Allocation - Phase 4)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(freightBookingProvider.notifier).fetchBookings();
              ref.read(shippingScenariosProvider.notifier).fetchSessions();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'freight-bookings',
              title: 'Freight_Bookings',
              onRefreshNeeded: () => ref.read(freightBookingProvider.notifier).fetchBookings(),
            ),
            const SizedBox(height: 12),

            // Top Toolbar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () => _showAddEditBookingDialog(),
                      icon: const Icon(Icons.add_task, color: Colors.white),
                      label: const Text(
                        'إنشاء حجز شحن جديد (Create Booking)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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
                    SizedBox(
                      width: 220,
                      child: SearchableDropdownField<String>(
                        value: _selectedStatusFilter,
                        labelText: 'تصفية حسب الحالة',
                        searchHintText: 'ابحث عن الحالة...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                          SearchableDropdownItem(value: 'Draft', label: 'Draft (مسودة)'),
                          SearchableDropdownItem(value: 'Booking Requested', label: 'Booking Requested (تم الطلب)'),
                          SearchableDropdownItem(value: 'Confirmed', label: 'Confirmed (مؤكد)'),
                          SearchableDropdownItem(value: 'Sailed', label: 'Sailed (أبحر)'),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                            ref.read(freightBookingProvider.notifier).fetchBookings(search: _searchController.text, status: val);
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
              child: bookingsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('❌ Error: $err', style: const TextStyle(color: Colors.red))),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Text('لا توجد حجوزات شحن مسجلة بالنظام. اضغط إضافة حجز جديد.', style: TextStyle(fontSize: 16)),
                    );
                  }
                  return Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.06)),
                          horizontalMargin: 12,
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('العمليات ⚡', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('كود الحجز', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('رقم تأكيد الحجز', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الخط الملاحي / الوكيل', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('موانئ الشحن (POL ➔ POD)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('السفينة / رقم الرحلة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المغادرة (ETD / ATD)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الوصول (ETA / المخزن)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحاويات المخصصة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجمالي النولون USD', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: bookings.map((bkg) {
                            final hasDelay = bkg.departureDelayDays > 0;
                            return DataRow(
                              cells: [
                                // 1. Operations Pill in Column 1
                                DataCell(
                                  RowActionsPill(
                                    onView: () => _showViewBookingDialog(bkg),
                                    onEdit: () => _showAddEditBookingDialog(bkg),
                                    onPrint: () => _showPrintBookingDialog(bkg),
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('تأكيد الحذف'),
                                          content: Text('هل أنت متأكد من حذف حجز الشحن ${bkg.bookingCode}؟'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('حذف'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(freightBookingProvider.notifier).softDeleteBooking(bkg.bookingId);
                                      }
                                    },
                                    viewTooltip: 'عرض تفاصيل الحجز',
                                    editTooltip: 'تعديل حجز الشحن',
                                    printTooltip: 'طباعة بطاقة الحجز',
                                    deleteTooltip: 'حذف حجز الشحن',
                                  ),
                                ),

                                // 2. Booking Code (Clickable Badge)
                                DataCell(
                                  InkWell(
                                    onTap: () => _showViewBookingDialog(bkg),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cobalt.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!bkg.isActive)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 4),
                                              child: Icon(Icons.block, size: 12, color: AppTheme.crimson),
                                            ),
                                          Text(
                                            bkg.bookingCode,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: bkg.isActive ? AppTheme.cobalt : AppTheme.crimson,
                                              fontSize: 12,
                                              decoration: bkg.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. Linked Import File
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.charcoal.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      bkg.importFileCode ?? (bkg.importFileId != null ? 'IMP-${bkg.importFileId}' : '—'),
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                    ),
                                  ),
                                ),

                                // 4. Confirmation No
                                DataCell(
                                  Text(
                                    bkg.bookingConfirmationNo ?? 'Draft Pending',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),

                                // 5. Shipping Line / Forwarder
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(bkg.shippingLineName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      if (bkg.scenarioProviderName != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified, size: 11, color: AppTheme.emerald),
                                            const SizedBox(width: 2),
                                            Text(
                                              'عرض معتمد: ${bkg.scenarioProviderName}',
                                              style: const TextStyle(fontSize: 10, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        )
                                      else
                                        Text('FWD: ${bkg.freightForwarderName ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),

                                // 6. POL ➔ POD
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.cobalt),
                                      const SizedBox(width: 3),
                                      Text('${bkg.polName ?? "-"} ➔ ${bkg.podName ?? "-"}', style: const TextStyle(fontSize: 11.5)),
                                    ],
                                  ),
                                ),

                                // 7. Vessel & Voyage
                                DataCell(Text('${bkg.vesselName ?? "-"} (${bkg.voyageNumber ?? "-"})', style: const TextStyle(fontSize: 11.5))),

                                // 8. Departure (ETD / ATD)
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ETD: ${bkg.etd != null ? bkg.etd!.substring(0, 10) : "-"}', style: const TextStyle(fontSize: 11)),
                                      if (bkg.atd != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('ATD: ${bkg.atd!.substring(0, 10)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            if (hasDelay) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: Text('+${bkg.departureDelayDays}d', style: TextStyle(fontSize: 9, color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                // 9. Arrival (ETA / WH)
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ETA: ${bkg.eta != null ? bkg.eta!.substring(0, 10) : "-"}', style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 11)),
                                      if (bkg.expectedWarehouseArrivalDate != null)
                                        Text('مخزن: ${bkg.expectedWarehouseArrivalDate!.substring(0, 10)}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),

                                // 10. Allocated Containers
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bkg.containersData.isNotEmpty
                                          ? bkg.containersData.map((c) => '${c.quantity}x ${c.containerType}').join(', ')
                                          : '—',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),

                                // 11. Total Freight USD
                                DataCell(
                                  Text(
                                    '\$ ${bkg.totalFreightCostUsd.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 12),
                                  ),
                                ),

                                // 12. Status Pill
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: bkg.status == 'Confirmed' || bkg.status == 'Sailed'
                                          ? AppTheme.emerald.withOpacity(0.15)
                                          : AppTheme.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: bkg.status == 'Confirmed' || bkg.status == 'Sailed'
                                            ? AppTheme.emerald.withOpacity(0.4)
                                            : AppTheme.orange.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      bkg.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: bkg.status == 'Confirmed' || bkg.status == 'Sailed'
                                            ? AppTheme.emerald
                                            : AppTheme.orange,
                                      ),
                                    ),
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
  late TextEditingController _expectedWhDaysController;
  late TextEditingController _ownerController;
  late TextEditingController _notesController;

  int? _selectedImportFileId;
  int? _selectedScenarioSessionId;
  int? _selectedScenarioItemId;
  String? _selectedScenarioProviderName;

  String _shipmentType = 'Ocean FCL';
  String _freightTerms = 'Collect';
  String _status = 'Draft';
  String _shippingLineName = 'Mediterranean Shipping Company (MSC)';
  String _freightForwarderName = 'El-Ahram Logistics';

  DateTime _etd = DateTime.now().add(const Duration(days: 5));
  DateTime _eta = DateTime.now().add(const Duration(days: 23));
  DateTime? _atd;
  String? _containerMismatchReason;

  bool _isStackable = true;
  List<ContainerAllocationModel> _containers = [];
  List<BookingChargeModel> _charges = [];

  // Full 17 quote items state matching Phase 1
  String _mainQuoteCurrency = 'USD';

  bool _container40ftApp = true;
  double _container40ftPrice = 8500.0;
  String _container40ftCur = 'USD';
  int _container40ftQty = 1;

  bool _container20ftApp = false;
  double _container20ftPrice = 0.0;
  String _container20ftCur = 'USD';
  int _container20ftQty = 0;

  bool _lclCbmApp = false;
  double _lclCbmPrice = 0.0;
  String _lclCbmCur = 'USD';
  double _lclCbmQty = 0.0;

  bool _expressCourierApp = false;
  double _expressCourierPrice = 0.0;
  String _expressCourierCur = 'USD';

  bool _eurAtrApp = false;
  double _eurAtrPrice = 0.0;
  String _eurAtrCur = 'USD';

  bool _solasVgmApp = false;
  double _solasVgmPrice = 0.0;
  String _solasVgmCur = 'USD';

  bool _vgmNotifApp = false;
  double _vgmNotifPrice = 0.0;
  String _vgmNotifCur = 'USD';

  bool _telexReleaseApp = false;
  double _telexReleasePrice = 0.0;
  String _telexReleaseCur = 'USD';

  bool _insuranceApp = false;
  double _insurancePrice = 0.0;
  String _insuranceCur = 'USD';

  bool _cancellationApp = false;
  double _cancellationPrice = 0.0;
  String _cancellationCur = 'USD';

  bool _ics2App = false;
  double _ics2Price = 0.0;
  String _ics2Cur = 'USD';

  bool _otherFeesApp = false;
  double _otherFeesPrice = 0.0;
  String _otherFeesCur = 'USD';

  bool _docFeesApp = false;
  double _docFeesPrice = 0.0;
  String _docFeesCur = 'USD';

  bool _waiverApp = false;
  double _waiverPrice = 0.0;
  String _waiverCur = 'USD';

  bool _dthcApp = false;
  double _dthcPrice = 0.0;
  String _dthcCur = 'USD';

  bool _storagePerWeekApp = false;
  double _storagePerWeekPrice = 0.0;
  String _storagePerWeekCur = 'USD';

  bool _extraDayStorageApp = false;
  double _extraDayStoragePrice = 0.0;
  String _extraDayStorageCur = 'USD';

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
    _expectedWhDaysController = TextEditingController(text: (b?.expectedWarehouseDays ?? 7).toString());
    _ownerController = TextEditingController(text: b?.owner ?? 'Kamal');
    _notesController = TextEditingController(text: b?.notes ?? '');

    _selectedImportFileId = b?.importFileId;
    _selectedScenarioSessionId = b?.scenarioSessionId;
    _selectedScenarioItemId = b?.scenarioItemId;
    _selectedScenarioProviderName = b?.scenarioProviderName;
    _containerMismatchReason = b?.containerMismatchReason;

    _shipmentType = b?.shipmentType ?? 'Ocean FCL';
    _freightTerms = b?.freightTerms ?? 'Collect';
    _status = b?.status ?? 'Draft';
    _shippingLineName = b?.shippingLineName ?? 'Mediterranean Shipping Company (MSC)';
    _freightForwarderName = b?.freightForwarderName ?? 'El-Ahram Logistics';

    if (b?.etd != null) _etd = DateTime.tryParse(b!.etd!) ?? _etd;
    if (b?.eta != null) _eta = DateTime.tryParse(b!.eta!) ?? _eta;
    if (b?.atd != null) _atd = DateTime.tryParse(b!.atd!);

    if (b?.containersData != null && b!.containersData.isNotEmpty) {
      _containers = List.from(b.containersData);
    } else {
      _containers = [
        ContainerAllocationModel(
          containerType: '40HC',
          quantity: 1,
          containerNumbers: ['MSCU1234567'],
          sealNumbers: ['SL-99001'],
          vgmWeightKg: 24500,
        )
      ];
    }

    if (b?.costChargesData != null && b!.costChargesData.isNotEmpty) {
      _charges = List.from(b.costChargesData);
    }

    if (b?.quotationDetailsData != null && b!.quotationDetailsData.isNotEmpty) {
      _loadQuotationDataFromMap(b.quotationDetailsData);
    }
  }

  void _loadQuotationDataFromMap(Map<String, dynamic> q) {
    _mainQuoteCurrency = q['main_quote_currency'] ?? 'USD';
    _container40ftApp = q['container_40ft_app'] ?? true;
    _container40ftPrice = (q['container_40ft_price'] as num?)?.toDouble() ?? 8500.0;
    _container40ftCur = q['container_40ft_cur'] ?? 'USD';
    _container40ftQty = q['container_40ft_qty'] ?? 1;

    _container20ftApp = q['container_20ft_app'] ?? false;
    _container20ftPrice = (q['container_20ft_price'] as num?)?.toDouble() ?? 0.0;
    _container20ftCur = q['container_20ft_cur'] ?? 'USD';
    _container20ftQty = q['container_20ft_qty'] ?? 0;

    _lclCbmApp = q['lcl_cbm_app'] ?? false;
    _lclCbmPrice = (q['lcl_cbm_price'] as num?)?.toDouble() ?? 0.0;
    _lclCbmCur = q['lcl_cbm_cur'] ?? 'USD';
    _lclCbmQty = (q['lcl_cbm_qty'] as num?)?.toDouble() ?? 0.0;

    _expressCourierApp = q['express_courier_app'] ?? false;
    _expressCourierPrice = (q['express_courier_price'] as num?)?.toDouble() ?? 0.0;
    _expressCourierCur = q['express_courier_cur'] ?? 'USD';

    _eurAtrApp = q['eur_atr_app'] ?? false;
    _eurAtrPrice = (q['eur_atr_price'] as num?)?.toDouble() ?? 0.0;
    _eurAtrCur = q['eur_atr_cur'] ?? 'USD';

    _solasVgmApp = q['solas_vgm_app'] ?? false;
    _solasVgmPrice = (q['solas_vgm_price'] as num?)?.toDouble() ?? 0.0;
    _solasVgmCur = q['solas_vgm_cur'] ?? 'USD';

    _vgmNotifApp = q['vgm_notif_app'] ?? false;
    _vgmNotifPrice = (q['vgm_notif_price'] as num?)?.toDouble() ?? 0.0;
    _vgmNotifCur = q['vgm_notif_cur'] ?? 'USD';

    _telexReleaseApp = q['telex_release_app'] ?? false;
    _telexReleasePrice = (q['telex_release_price'] as num?)?.toDouble() ?? 0.0;
    _telexReleaseCur = q['telex_release_cur'] ?? 'USD';

    _insuranceApp = q['insurance_app'] ?? false;
    _insurancePrice = (q['insurance_price'] as num?)?.toDouble() ?? 0.0;
    _insuranceCur = q['insurance_cur'] ?? 'USD';

    _cancellationApp = q['cancellation_app'] ?? false;
    _cancellationPrice = (q['cancellation_price'] as num?)?.toDouble() ?? 0.0;
    _cancellationCur = q['cancellation_cur'] ?? 'USD';

    _ics2App = q['ics2_app'] ?? false;
    _ics2Price = (q['ics2_price'] as num?)?.toDouble() ?? 0.0;
    _ics2Cur = q['ics2_cur'] ?? 'USD';

    _otherFeesApp = q['other_fees_app'] ?? false;
    _otherFeesPrice = (q['other_fees_price'] as num?)?.toDouble() ?? 0.0;
    _otherFeesCur = q['other_fees_cur'] ?? 'USD';

    _docFeesApp = q['doc_fees_app'] ?? false;
    _docFeesPrice = (q['doc_fees_price'] as num?)?.toDouble() ?? 0.0;
    _docFeesCur = q['doc_fees_cur'] ?? 'USD';

    _waiverApp = q['waiver_app'] ?? false;
    _waiverPrice = (q['waiver_price'] as num?)?.toDouble() ?? 0.0;
    _waiverCur = q['waiver_cur'] ?? 'USD';

    _dthcApp = q['dthc_app'] ?? false;
    _dthcPrice = (q['dthc_price'] as num?)?.toDouble() ?? 0.0;
    _dthcCur = q['dthc_cur'] ?? 'USD';

    _storagePerWeekApp = q['storage_per_week_app'] ?? false;
    _storagePerWeekPrice = (q['storage_per_week_price'] as num?)?.toDouble() ?? 0.0;
    _storagePerWeekCur = q['storage_per_week_cur'] ?? 'USD';

    _extraDayStorageApp = q['extra_day_storage_app'] ?? false;
    _extraDayStoragePrice = (q['extra_day_storage_price'] as num?)?.toDouble() ?? 0.0;
    _extraDayStorageCur = q['extra_day_storage_cur'] ?? 'USD';
  }

  Map<String, dynamic> _buildQuotationDataMap() {
    return {
      'main_quote_currency': _mainQuoteCurrency,
      'container_40ft_app': _container40ftApp,
      'container_40ft_price': _container40ftPrice,
      'container_40ft_cur': _container40ftCur,
      'container_40ft_qty': _container40ftQty,
      'container_20ft_app': _container20ftApp,
      'container_20ft_price': _container20ftPrice,
      'container_20ft_cur': _container20ftCur,
      'container_20ft_qty': _container20ftQty,
      'lcl_cbm_app': _lclCbmApp,
      'lcl_cbm_price': _lclCbmPrice,
      'lcl_cbm_cur': _lclCbmCur,
      'lcl_cbm_qty': _lclCbmQty,
      'express_courier_app': _expressCourierApp,
      'express_courier_price': _expressCourierPrice,
      'express_courier_cur': _expressCourierCur,
      'eur_atr_app': _eurAtrApp,
      'eur_atr_price': _eurAtrPrice,
      'eur_atr_cur': _eurAtrCur,
      'solas_vgm_app': _solasVgmApp,
      'solas_vgm_price': _solasVgmPrice,
      'solas_vgm_cur': _solasVgmCur,
      'vgm_notif_app': _vgmNotifApp,
      'vgm_notif_price': _vgmNotifPrice,
      'vgm_notif_cur': _vgmNotifCur,
      'telex_release_app': _telexReleaseApp,
      'telex_release_price': _telexReleasePrice,
      'telex_release_cur': _telexReleaseCur,
      'insurance_app': _insuranceApp,
      'insurance_price': _insurancePrice,
      'insurance_cur': _insuranceCur,
      'cancellation_app': _cancellationApp,
      'cancellation_price': _cancellationPrice,
      'cancellation_cur': _cancellationCur,
      'ics2_app': _ics2App,
      'ics2_price': _ics2Price,
      'ics2_cur': _ics2Cur,
      'other_fees_app': _otherFeesApp,
      'other_fees_price': _otherFeesPrice,
      'other_fees_cur': _otherFeesCur,
      'doc_fees_app': _docFeesApp,
      'doc_fees_price': _docFeesPrice,
      'doc_fees_cur': _docFeesCur,
      'waiver_app': _waiverApp,
      'waiver_price': _waiverPrice,
      'waiver_cur': _waiverCur,
      'dthc_app': _dthcApp,
      'dthc_price': _dthcPrice,
      'dthc_cur': _dthcCur,
      'storage_per_week_app': _storagePerWeekApp,
      'storage_per_week_price': _storagePerWeekPrice,
      'storage_per_week_cur': _storagePerWeekCur,
      'extra_day_storage_app': _extraDayStorageApp,
      'extra_day_storage_price': _extraDayStoragePrice,
      'extra_day_storage_cur': _extraDayStorageCur,
    };
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
    _expectedWhDaysController.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyScenarioQuote(ShippingEvaluationModel session, ShippingScenarioItemModel item) {
    setState(() {
      _selectedScenarioSessionId = session.sessionId;
      _selectedScenarioItemId = item.itemId;
      _selectedScenarioProviderName = item.providerName;

      _shippingLineName = item.providerName;
      _freightForwarderName = item.providerName;
      _vesselNameController.text = item.vesselName;
      if (item.voyageNumber != null && item.voyageNumber!.isNotEmpty) {
        _voyageNoController.text = item.voyageNumber!;
      }
      if (item.polName != null && item.polName!.isNotEmpty) {
        _polController.text = item.polName!;
      }
      if (item.podName != null && item.podName!.isNotEmpty) {
        _podController.text = item.podName!;
      }
      final parsedEtd = DateTime.tryParse(item.sailingDate);
      if (parsedEtd != null) _etd = parsedEtd;
      final parsedEta = DateTime.tryParse(item.estimatedArrivalDate);
      if (parsedEta != null) _eta = parsedEta;
      _freeDemurrageController.text = item.freeTimeDays.toString();
      _mainQuoteCurrency = item.quotationCurrency;

      // Map all 17 quote breakdown parameters
      _container40ftApp = item.container40ftApplicable;
      _container40ftPrice = item.container40ftPrice;
      _container40ftCur = item.container40ftCurrency;
      _container40ftQty = item.container40ftQty > 0 ? item.container40ftQty : 1;

      _container20ftApp = item.container20ftApplicable;
      _container20ftPrice = item.container20ftPrice;
      _container20ftCur = item.container20ftCurrency;
      _container20ftQty = item.container20ftQty;

      _lclCbmApp = item.lclCbmApplicable;
      _lclCbmPrice = item.lclCbmPrice;
      _lclCbmCur = item.lclCbmCurrency;
      _lclCbmQty = item.lclCbmQty;

      _expressCourierApp = item.expressCourierApplicable;
      _expressCourierPrice = item.expressCourierPrice;
      _expressCourierCur = item.expressCourierCurrency;

      _eurAtrApp = item.eurAtrApplicable;
      _eurAtrPrice = item.eurAtrPrice;
      _eurAtrCur = item.eurAtrCurrency;

      _solasVgmApp = item.solasVgmApplicable;
      _solasVgmPrice = item.solasVgmPrice;
      _solasVgmCur = item.solasVgmCurrency;

      _vgmNotifApp = item.vgmNotificationApplicable;
      _vgmNotifPrice = item.vgmNotificationPrice;
      _vgmNotifCur = item.vgmNotificationCurrency;

      _telexReleaseApp = item.telexReleaseApplicable;
      _telexReleasePrice = item.telexReleasePrice;
      _telexReleaseCur = item.telexReleaseCurrency;

      _insuranceApp = item.insuranceApplicable;
      _insurancePrice = item.insurancePrice;
      _insuranceCur = item.insuranceCurrency;

      _cancellationApp = item.bookingCancellationApplicable;
      _cancellationPrice = item.bookingCancellationPrice;
      _cancellationCur = item.bookingCancellationCurrency;

      _ics2App = item.ics2FilingFeeApplicable;
      _ics2Price = item.ics2FilingFeePrice;
      _ics2Cur = item.ics2FilingFeeCurrency;

      _otherFeesApp = item.othersFeeApplicable;
      _otherFeesPrice = item.othersFeePrice;
      _otherFeesCur = item.othersFeeCurrency;

      _docFeesApp = item.documentFeesApplicable;
      _docFeesPrice = item.documentFeesPrice;
      _docFeesCur = item.documentFeesCurrency;

      _waiverApp = item.waiverLetterFeeApplicable;
      _waiverPrice = item.waiverLetterFeePrice;
      _waiverCur = item.waiverLetterFeeCurrency;

      _dthcApp = item.dthcApplicable;
      _dthcPrice = item.dthcPrice;
      _dthcCur = item.dthcCurrency;

      _storagePerWeekApp = item.storagePerWeekApplicable;
      _storagePerWeekPrice = item.storagePerWeekPrice;
      _storagePerWeekCur = item.storagePerWeekCurrency;

      _extraDayStorageApp = item.extraDayStorageApplicable;
      _extraDayStoragePrice = item.extraDayStoragePrice;
      _extraDayStorageCur = item.extraDayStorageCurrency;

      // Auto-assign containers based on quotation
      final List<ContainerAllocationModel> newContainers = [];
      if (item.container40ftApplicable && item.container40ftQty > 0) {
        newContainers.add(ContainerAllocationModel(
          containerType: '40HC',
          quantity: item.container40ftQty,
          containerNumbers: List.generate(item.container40ftQty, (i) => 'MSCU${1000000 + (i * 111111)}'),
          sealNumbers: List.generate(item.container40ftQty, (i) => 'SL-40HC-${i + 1}'),
          vgmWeightKg: 24500.0 * item.container40ftQty,
        ));
      }
      if (item.container20ftApplicable && item.container20ftQty > 0) {
        newContainers.add(ContainerAllocationModel(
          containerType: '20GP',
          quantity: item.container20ftQty,
          containerNumbers: List.generate(item.container20ftQty, (i) => 'MSCU${2000000 + (i * 111111)}'),
          sealNumbers: List.generate(item.container20ftQty, (i) => 'SL-20GP-${i + 1}'),
          vgmWeightKg: 14000.0 * item.container20ftQty,
        ));
      }
      if (newContainers.isNotEmpty) {
        _containers = newContainers;
        _shipmentType = 'Ocean FCL';
      } else if (item.lclCbmApplicable && item.lclCbmQty > 0) {
        _shipmentType = 'Ocean LCL';
      }

      // Rebuild charges list
      _rebuildChargesFromQuoteBreakdown();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚢 تم استدعاء وتحديث بيانات العرض المعتمد بنجاح (${item.providerName} - ${item.vesselName})!'),
        backgroundColor: AppTheme.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _rebuildChargesFromQuoteBreakdown() {
    final List<BookingChargeModel> newCharges = [];
    if (_container40ftApp && _container40ftPrice > 0) {
      newCharges.add(BookingChargeModel(
        chargeType: 'Sea Freight 40ft',
        unit: 'Per Container',
        quantity: _container40ftQty > 0 ? _container40ftQty : 1,
        currency: _container40ftCur,
        rate: _container40ftPrice,
        total: _container40ftPrice * (_container40ftQty > 0 ? _container40ftQty : 1),
      ));
    }
    if (_container20ftApp && _container20ftPrice > 0) {
      newCharges.add(BookingChargeModel(
        chargeType: 'Sea Freight 20ft',
        unit: 'Per Container',
        quantity: _container20ftQty > 0 ? _container20ftQty : 1,
        currency: _container20ftCur,
        rate: _container20ftPrice,
        total: _container20ftPrice * (_container20ftQty > 0 ? _container20ftQty : 1),
      ));
    }
    if (_lclCbmApp && _lclCbmPrice > 0) {
      newCharges.add(BookingChargeModel(
        chargeType: 'LCL CBM Freight',
        unit: 'Per CBM',
        quantity: _lclCbmQty.ceil() > 0 ? _lclCbmQty.ceil() : 1,
        currency: _lclCbmCur,
        rate: _lclCbmPrice,
        total: _lclCbmPrice * _lclCbmQty,
      ));
    }
    if (_dthcApp && _dthcPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'DTHC (Destination THC)', unit: 'Per Shipment', quantity: 1, currency: _dthcCur, rate: _dthcPrice, total: _dthcPrice));
    }
    if (_storagePerWeekApp && _storagePerWeekPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Storage per one week', unit: 'Per Week', quantity: 1, currency: _storagePerWeekCur, rate: _storagePerWeekPrice, total: _storagePerWeekPrice));
    }
    if (_extraDayStorageApp && _extraDayStoragePrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Extra day storage', unit: 'Per Day', quantity: 1, currency: _extraDayStorageCur, rate: _extraDayStoragePrice, total: _extraDayStoragePrice));
    }
    if (_solasVgmApp && _solasVgmPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'SOLAS/VGM Fees', unit: 'Per Container', quantity: 1, currency: _solasVgmCur, rate: _solasVgmPrice, total: _solasVgmPrice));
    }
    if (_vgmNotifApp && _vgmNotifPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'VGM Notification Fee', unit: 'Per Container', quantity: 1, currency: _vgmNotifCur, rate: _vgmNotifPrice, total: _vgmNotifPrice));
    }
    if (_telexReleaseApp && _telexReleasePrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Telex Release', unit: 'Per Shipment', quantity: 1, currency: _telexReleaseCur, rate: _telexReleasePrice, total: _telexReleasePrice));
    }
    if (_expressCourierApp && _expressCourierPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Express Courier', unit: 'Per Shipment', quantity: 1, currency: _expressCourierCur, rate: _expressCourierPrice, total: _expressCourierPrice));
    }
    if (_eurAtrApp && _eurAtrPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'EUR.1 / ATR Certificate', unit: 'Per Certificate', quantity: 1, currency: _eurAtrCur, rate: _eurAtrPrice, total: _eurAtrPrice));
    }
    if (_insuranceApp && _insurancePrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Marine Insurance', unit: 'Per Policy', quantity: 1, currency: _insuranceCur, rate: _insurancePrice, total: _insurancePrice));
    }
    if (_docFeesApp && _docFeesPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Document Fees', unit: 'Per Shipment', quantity: 1, currency: _docFeesCur, rate: _docFeesPrice, total: _docFeesPrice));
    }
    if (_waiverApp && _waiverPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Waiver Letter Fee', unit: 'Per Letter', quantity: 1, currency: _waiverCur, rate: _waiverPrice, total: _waiverPrice));
    }
    if (_ics2App && _ics2Price > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'ICS2 Filing Fee', unit: 'Per Filing', quantity: 1, currency: _ics2Cur, rate: _ics2Price, total: _ics2Price));
    }
    if (_otherFeesApp && _otherFeesPrice > 0) {
      newCharges.add(BookingChargeModel(chargeType: 'Other Fees', unit: 'Per Shipment', quantity: 1, currency: _otherFeesCur, rate: _otherFeesPrice, total: _otherFeesPrice));
    }

    _charges = newCharges;
  }

  Future<void> _submitWithContainerValidation(ContainerRecommendationResult? rec) async {
    if (!_formKey.currentState!.validate()) return;

    // Check Container Matching
    if (rec != null) {
      int assignedTotal = _containers.fold(0, (sum, c) => sum + c.quantity);
      String assignedType = _containers.isNotEmpty ? _containers.first.containerType : 'N/A';
      String suggestedType = rec.recommendedContainerCode;
      int suggestedTotal = rec.requiredContainersCount;

      bool isMismatch = (assignedTotal != suggestedTotal) || (_containers.length == 1 && assignedType != suggestedType);

      if (isMismatch && (_containerMismatchReason == null || _containerMismatchReason!.trim().isEmpty)) {
        final assignedStr = '$assignedTotal x $assignedType';
        final suggestedStr = '$suggestedTotal x $suggestedType';

        final bool? shouldProceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('تنبيه عدم تطابق الحاويات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ عدد الحاويات المخصصة ونوعها ($assignedStr) مختلف عن الحاوية المقترحة ($suggestedStr).',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Text('هل ترغب في الاستمرار وتثبيت هذا التخصيص؟', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text(
                    'ℹ️ في حال اختيار "نعم"، يتطلب النظام إدخال سبب التغيير لتوثيق القرار.',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('لا (العودة للمطابقة)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم (الاستمرار وكتابة السبب)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldProceed != true) {
          return;
        }

        if (!mounted) return;

        // Prompt user for mandatory reason
        final reasonController = TextEditingController();
        final formKeyReason = GlobalKey<FormState>();
        final bool? reasonConfirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('سبب تغيير الحاويات المقترحة *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            content: Form(
              key: formKeyReason,
              child: TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'اكتب سبب اعتماد هذا التخصيص المختلف...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يجب إدخال سبب التغيير للاستمرار' : null,
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () {
                  if (formKeyReason.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('تأكيد وحفظ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (reasonConfirmed == true) {
          setState(() {
            _containerMismatchReason = reasonController.text.trim();
          });
        } else {
          return;
        }
      }
    }

    _doSave();
  }

  Future<void> _doSave() async {
    setState(() => _isSaving = true);
    try {
      _rebuildChargesFromQuoteBreakdown();

      final payload = {
        'booking_confirmation_no': _bookingConfirmNoController.text.trim(),
        'import_file_id': _selectedImportFileId,
        'scenario_session_id': _selectedScenarioSessionId,
        'scenario_item_id': _selectedScenarioItemId,
        'scenario_provider_name': _selectedScenarioProviderName,
        'freight_forwarder_name': _freightForwarderName,
        'shipping_line_name': _shippingLineName,
        'shipment_type': _shipmentType,
        'pol_name': _polController.text.trim(),
        'pod_name': _podController.text.trim(),
        'etd': _etd.toIso8601String(),
        'eta': _eta.toIso8601String(),
        'atd': _atd?.toIso8601String(),
        'free_demurrage_days': int.tryParse(_freeDemurrageController.text.trim()) ?? 14,
        'expected_warehouse_days': int.tryParse(_expectedWhDaysController.text.trim()) ?? 7,
        'vessel_name': _vesselNameController.text.trim(),
        'voyage_number': _voyageNoController.text.trim(),
        'container_release_order_no': _releaseOrderNoController.text.trim(),
        'freight_terms': _freightTerms,
        'container_mismatch_reason': _containerMismatchReason,
        'containers_data': _containers.map((c) => c.toJson()).toList(),
        'cost_charges_data': _charges.map((c) => c.toJson()).toList(),
        'quotation_details_data': _buildQuotationDataMap(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ وتأكيد حجز الشحن بنجاح!'), backgroundColor: AppTheme.emerald),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('يوجد بالفعل حجز شحن') || errStr.contains('مسجل لهذا الملف')) {
          final existingBookings = ref.read(freightBookingProvider).value ?? [];
          final duplicate = existingBookings.where((b) => b.importFileId == _selectedImportFileId && b.isActive).toList();
          if (duplicate.isNotEmpty) {
            _showDuplicateBookingWarningDialog(duplicate.first);
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDuplicateBookingWarningDialog(ShipmentBookingModel existing) {
    final importFiles = ref.read(importFilesProvider).value ?? [];
    final curFile = importFiles.where((f) => f.importFileId == existing.importFileId).toList();
    final fileLabel = curFile.isNotEmpty
        ? '${curFile.first.customFileNumber ?? curFile.first.importFileCode} (${curFile.first.companyName})'
        : 'IMP-${existing.importFileId}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تنبيه: الشحنة مسجلة بالفعل!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
              ),
            ),
          ],
        ),
        content: Container(
          width: 500,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملف الشحنة الاستيرادية المختار مرتبط بالفعل بحجز شحن محفوظ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade900),
              ),
              const SizedBox(height: 10),
              _buildDuplicateInfoRow('📁 ملف الشحنة:', fileLabel),
              _buildDuplicateInfoRow('🔖 كود الحجز:', existing.bookingCode),
              _buildDuplicateInfoRow('📝 رقم تأكيد الحجز:', existing.bookingConfirmationNo ?? 'Draft Pending'),
              _buildDuplicateInfoRow('🚢 الخط الملاحي:', existing.shippingLineName ?? 'N/A'),
              _buildDuplicateInfoRow('⚡ الحالة الحالية:', existing.status),
              const Divider(height: 20),
              const Text(
                'قواعد النظام تمنع إنشاء أكثر من حجز لنفس الملف الاستيرادي. يمكنك التحويل لتعديل الحجز الحالي فوراً.',
                style: TextStyle(fontSize: 12, color: AppTheme.charcoal),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedImportFileId = null;
              });
            },
            child: const Text('إلغاء والتراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('🔄 التحويل إلى التعديل', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx); // Close warning dialog
              Navigator.pop(context); // Close current form dialog
              // Open edit dialog for existing booking
              Future.microtask(() {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) => _FreightBookingFormDialog(bookingToEdit: existing),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCostItemRow({
    required String title,
    required bool isApplicable,
    required ValueChanged<bool> onToggle,
    required double price,
    required ValueChanged<double> onPriceChanged,
    required String currency,
    required ValueChanged<String> onCurrencyChanged,
    int? quantity,
    ValueChanged<int>? onQuantityChanged,
    double? doubleQty,
    ValueChanged<double>? onDoubleQtyChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isApplicable ? AppTheme.emerald.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isApplicable ? AppTheme.emerald.withOpacity(0.3) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(title, style: TextStyle(fontWeight: isApplicable ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: price > 0 ? price.toStringAsFixed(0) : '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر البند', isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => onPriceChanged(double.tryParse(v) ?? 0.0),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: SearchableDropdownField<String>(
              value: currency,
              labelText: 'العملة',
              searchHintText: 'ابحث...',
              items: const [
                SearchableDropdownItem(value: 'USD', label: 'USD (\$)'),
                SearchableDropdownItem(value: 'EUR', label: 'EUR (€)'),
                SearchableDropdownItem(value: 'EGP', label: 'EGP (ج.م)'),
                SearchableDropdownItem(value: 'GBP', label: 'GBP (£)'),
                SearchableDropdownItem(value: 'CNY', label: 'CNY (¥)'),
              ],
              onChanged: (v) {
                if (v != null) onCurrencyChanged(v);
              },
            ),
          ),
          if (quantity != null && onQuantityChanged != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: quantity.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية', isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => onQuantityChanged(int.tryParse(v) ?? 1),
              ),
            ),
          ],
          if (doubleQty != null && onDoubleQtyChanged != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: doubleQty.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الحجم CBM', isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => onDoubleQtyChanged(double.tryParse(v) ?? 0.0),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Switch(
            value: isApplicable,
            activeColor: AppTheme.emerald,
            onChanged: (v) {
              onToggle(v);
              _rebuildChargesFromQuoteBreakdown();
            },
          ),
          SizedBox(
            width: 70,
            child: Text(
              isApplicable ? 'مطبق' : 'غير مطبق',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isApplicable ? AppTheme.emerald : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final partners = ref.watch(partnersProvider).value ?? [];
    final ports = ref.watch(transportLocationsProvider).value ?? [];
    final shippingSessions = ref.watch(shippingScenariosProvider).sessions;
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;

    final shippingLines = partners.where((p) => p.partnerType.contains('Shipping Line') || p.partnerType.contains('Carrier') || p.partnerType.contains('Bank') || p.partnerType.contains('Freight')).toList();
    final freightForwarders = partners.where((p) => p.partnerType.contains('Forwarder') || p.partnerType.contains('Logistics') || p.partnerType.contains('Freight')).toList();

    // Quotes for selected file
    final matchingSessions = _selectedImportFileId != null
        ? shippingSessions.where((s) => s.importFileId == _selectedImportFileId).toList()
        : <ShippingEvaluationModel>[];

    // Compute Cargo Stacking from Packing Lists
    double totalCargoCbm = 0.0;
    double totalCargoWeightKg = 0.0;
    if (_selectedImportFileId != null && importFiles.any((f) => f.importFileId == _selectedImportFileId)) {
      final curFile = importFiles.firstWhere((f) => f.importFileId == _selectedImportFileId);
      for (var pl in curFile.packingListsData) {
        totalCargoCbm += pl.cbm;
        totalCargoWeightKg += pl.grossWeightKg;
      }
      final filePos = poList.where((p) => (curFile.poIds ?? []).contains(p.poId)).toList();
      for (var po in filePos) {
        for (var pl in po.packingListItems) {
          totalCargoCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
          totalCargoWeightKg += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
        }
      }
    }

    if (totalCargoCbm == 0 && _selectedImportFileId != null) {
      totalCargoCbm = 40.0;
      totalCargoWeightKg = 2274.0;
    }

    final containerDualRec = ContainerRequirementEngine.calculateBoth(
      totalCbm: totalCargoCbm > 0 ? totalCargoCbm : 40.0,
      totalWeightKg: totalCargoWeightKg > 0 ? totalCargoWeightKg : 2274.0,
    );
    final activeContainerRec = _isStackable ? containerDualRec.stackableResult : containerDualRec.nonStackableResult;

    // Delay calculation
    final int delayDays = _atd != null ? _atd!.difference(_etd).inDays : 0;
    final int whDays = int.tryParse(_expectedWhDaysController.text.trim()) ?? 7;
    final DateTime computedWhArrival = _eta.add(Duration(days: (delayDays > 0 ? delayDays : 0) + whDays));

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.directions_boat, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text(
              widget.bookingToEdit == null ? 'إنشاء حجز شحن ملاحي (New Carrier Booking)' : 'تعديل حجز الشحن: ${widget.bookingToEdit!.bookingCode}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 960,
          height: 680,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.cobalt,
                tabs: [
                  Tab(icon: Icon(Icons.description), text: '1. تفاصيل الحجز وعروض الشحن'),
                  Tab(icon: Icon(Icons.attach_money), text: '2. بنود التكلفة والنولون'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    children: [
                      // ================= TAB 1: BOOKING DETAILS & ROUTE =================
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedImportFileId,
                                    labelText: 'ملف الشحنة الاستيرادية (Import File) *',
                                    searchHintText: 'ابحث عن ملف الشحنة...',
                                    items: importFiles
                                        .map((f) => SearchableDropdownItem<int?>(
                                              value: f.importFileId,
                                              label: '${f.customFileNumber ?? f.importFileCode} (${f.companyName})',
                                              subtitle: f.supplierName,
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val == null) {
                                        setState(() => _selectedImportFileId = null);
                                        return;
                                      }
                                      // Check if there is already an active booking for this file
                                      final existingBookings = ref.read(freightBookingProvider).value ?? [];
                                      final duplicate = existingBookings.where((b) =>
                                          b.importFileId == val &&
                                          b.isActive &&
                                          (widget.bookingToEdit == null || b.bookingId != widget.bookingToEdit!.bookingId)
                                      ).toList();

                                      if (duplicate.isNotEmpty) {
                                        _showDuplicateBookingWarningDialog(duplicate.first);
                                        return;
                                      }

                                      setState(() {
                                        _selectedImportFileId = val;
                                        // If there are evaluated quotes, auto-select recommended
                                        final matched = shippingSessions.where((s) => s.importFileId == val).toList();
                                        if (matched.isNotEmpty && matched.first.items.isNotEmpty) {
                                          final rec = matched.first.items.firstWhere((i) => i.isRecommended, orElse: () => matched.first.items.first);
                                          _applyScenarioQuote(matched.first, rec);
                                        }
                                      });
                                    },
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

                            // Evaluated Shipping Scenarios & Quotes Link Section
                            if (_selectedImportFileId != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blueGrey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_shipping, color: AppTheme.cobalt, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'عروض وسيناريوهات الشحن المقيمة للملف (Phase 1 Evaluated Quotes):',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                        ),
                                        const Spacer(),
                                        if (matchingSessions.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              '${matchingSessions.fold<int>(0, (sum, s) => sum + s.items.length)} عرض متاح',
                                              style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (matchingSessions.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          'ℹ️ لم يتم العثور على دراسة سيناريوهات شحن محفوظة لهذا الملف. يمكنك تعبئة بيانات الناقل أدناه يدوياً.',
                                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                        ),
                                      )
                                    else ...[
                                      const Text(
                                        'اضغط على زر "اعتماد وتطبيق هذا العرض" لتعبئة بيانات الناقل، الموانئ، السفينة، المواعيد، التكاليف، والحاويات آلياً:',
                                        style: TextStyle(fontSize: 11, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: matchingSessions.fold<List<Map<String, dynamic>>>(
                                          [],
                                          (list, s) {
                                            for (var item in s.items) {
                                              list.add({'session': s, 'item': item});
                                            }
                                            return list;
                                          },
                                        ).length,
                                        separatorBuilder: (c, i) => const SizedBox(height: 8),
                                        itemBuilder: (context, idx) {
                                          final allItems = matchingSessions.fold<List<Map<String, dynamic>>>(
                                            [],
                                            (list, s) {
                                              for (var item in s.items) {
                                                list.add({'session': s, 'item': item});
                                              }
                                              return list;
                                            },
                                          );
                                          final pair = allItems[idx];
                                          final ShippingEvaluationModel sess = pair['session'];
                                          final ShippingScenarioItemModel item = pair['item'];
                                          final bool isSelected = _selectedScenarioItemId == item.itemId ||
                                              (_selectedScenarioProviderName == item.providerName && _vesselNameController.text == item.vesselName);

                                          return Card(
                                            elevation: isSelected ? 3 : 1,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: isSelected ? AppTheme.emerald : Colors.grey.shade300,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            color: isSelected ? AppTheme.emerald.withOpacity(0.06) : Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // Carrier & Vessel Details
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              item.providerName,
                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                                            ),
                                                            if (item.isRecommended) ...[
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.amber.shade100,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(color: Colors.amber.shade400),
                                                                ),
                                                                child: const Row(
                                                                  children: [
                                                                    Icon(Icons.star, color: Colors.amber, size: 12),
                                                                    SizedBox(width: 2),
                                                                    Text('الأفضل في الدراسة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '🚢 سفينة: ${item.vesselName} | رحلة: ${item.voyageNumber ?? "-"} | موانئ: ${item.polName ?? "-"} ➔ ${item.podName ?? "-"}',
                                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '📅 إبحار: ${item.sailingDate} ➔ وصول متوقع: ${item.estimatedArrivalDate} | فري تايم: ${item.freeTimeDays} يوم',
                                                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Price & Containers Info
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          '${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}',
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.emerald),
                                                        ),
                                                        Text(
                                                          'دراسة: ${sess.sessionCode} (${sess.cargoReadyDate})',
                                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),

                                                  // Select / Active Action
                                                  if (isSelected)
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppTheme.emerald,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      ),
                                                      onPressed: () => _applyScenarioQuote(sess, item),
                                                      icon: const Icon(Icons.check_circle, size: 16),
                                                      label: const Text('العرض المعتمد ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                    )
                                                  else
                                                    OutlinedButton.icon(
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: AppTheme.cobalt,
                                                        side: const BorderSide(color: AppTheme.cobalt),
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      ),
                                                      onPressed: () => _applyScenarioQuote(sess, item),
                                                      icon: const Icon(Icons.check, size: 16),
                                                      label: const Text('اعتماد هذا العرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: shippingLines.any((s) => s.partnerName == _shippingLineName) ? _shippingLineName : (shippingLines.isNotEmpty ? shippingLines.first.partnerName : _shippingLineName),
                                    labelText: 'الخط الملاحي (Shipping Line) *',
                                    searchHintText: 'ابحث عن الخط الملاحي...',
                                    items: shippingLines.isNotEmpty
                                        ? shippingLines.map((s) => SearchableDropdownItem<String>(value: s.partnerName, label: s.partnerName, subtitle: s.partnerType)).toList()
                                        : [SearchableDropdownItem<String>(value: _shippingLineName, label: _shippingLineName)],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _shippingLineName = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: freightForwarders.any((f) => f.partnerName == _freightForwarderName) ? _freightForwarderName : (freightForwarders.isNotEmpty ? freightForwarders.first.partnerName : _freightForwarderName),
                                    labelText: 'وكيل الشحن (Freight Forwarder)',
                                    searchHintText: 'ابحث عن وكيل الشحن...',
                                    items: freightForwarders.isNotEmpty
                                        ? freightForwarders.map((f) => SearchableDropdownItem<String>(value: f.partnerName, label: f.partnerName, subtitle: f.partnerType)).toList()
                                        : [SearchableDropdownItem<String>(value: _freightForwarderName, label: _freightForwarderName)],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _freightForwarderName = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: ports.any((p) => p.locationName == _polController.text) ? _polController.text : (ports.isNotEmpty ? ports.first.locationName : _polController.text),
                                    labelText: 'ميناء التحميل (POL) *',
                                    searchHintText: 'ابحث عن ميناء التحميل...',
                                    items: ports.isNotEmpty
                                        ? ports.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName, subtitle: p.locationType)).toList()
                                        : [SearchableDropdownItem<String>(value: _polController.text, label: _polController.text)],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _polController.text = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: ports.any((p) => p.locationName == _podController.text) ? _podController.text : (ports.length > 1 ? ports[1].locationName : _podController.text),
                                    labelText: 'ميناء الوصول (POD) *',
                                    searchHintText: 'ابحث عن ميناء الوصول...',
                                    items: ports.isNotEmpty
                                        ? ports.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName, subtitle: p.locationType)).toList()
                                        : [SearchableDropdownItem<String>(value: _podController.text, label: _podController.text)],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _podController.text = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Dates: ETD, ETA, ATD & Delay Tracking
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
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(context: context, initialDate: _atd ?? _etd, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                      if (d != null) setState(() => _atd = d);
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'تاريخ المغادرة الفعلي (ATD)',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: _atd != null
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 16),
                                                onPressed: () => setState(() => _atd = null),
                                              )
                                            : null,
                                      ),
                                      child: Text(_atd != null ? _atd!.toString().substring(0, 10) : 'لم يحدد بعد'),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Departure Delay & Warehouse Lead Time Banner
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: delayDays > 0 ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: delayDays > 0 ? Colors.red.shade200 : Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(delayDays > 0 ? Icons.alarm_off : Icons.check_circle, color: delayDays > 0 ? Colors.red : Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    delayDays > 0 ? '⚠️ تأخير في الإبحار: $delayDays يوم عن الموعد المجدول' : '✅ تم الإبحار في الموعد المجدول (لا توجد تأخيرات)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: delayDays > 0 ? Colors.red.shade900 : Colors.green.shade900),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'موعد الوصول للمخزن المتوقع: ${computedWhArrival.toString().substring(0, 10)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _freeDemurrageController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'الأيام المجانية (Free Days) *', border: OutlineInputBorder()),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _expectedWhDaysController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'أيام الوصول للمخزن (Warehouse Days)', border: OutlineInputBorder()),
                                    onChanged: (v) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: _status,
                                    labelText: 'حالة الحجز (Status) *',
                                    searchHintText: 'ابحث عن حالة الحجز...',
                                    items: const [
                                      SearchableDropdownItem(value: 'Draft', label: 'Draft'),
                                      SearchableDropdownItem(value: 'Booking Requested', label: 'Booking Requested'),
                                      SearchableDropdownItem(value: 'Confirmed', label: 'Confirmed'),
                                      SearchableDropdownItem(value: 'Sailed', label: 'Sailed'),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setState(() => _status = v);
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
                                  child: TextFormField(
                                    controller: _releaseOrderNoController,
                                    decoration: const InputDecoration(labelText: 'إذن الإفراج عن الحاويات (Release Order No)', border: OutlineInputBorder()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Booking Equipment Specification
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<String>(
                                    value: _containers.isNotEmpty ? _containers.first.containerType : '40HC',
                                    labelText: 'نوع الحاوية المطلوب حجزها (Container Type)',
                                    searchHintText: 'ابحث عن النوع...',
                                    items: const [
                                      SearchableDropdownItem(value: '20GP', label: '20GP Standard'),
                                      SearchableDropdownItem(value: '40GP', label: '40GP Standard'),
                                      SearchableDropdownItem(value: '40HC', label: '40HC High Cube'),
                                      SearchableDropdownItem(value: '45HC', label: '45HC High Cube'),
                                      SearchableDropdownItem(value: '20RF', label: '20RF Reefer'),
                                      SearchableDropdownItem(value: '40RF', label: '40RF Reefer'),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          if (_containers.isEmpty) {
                                            _containers.add(ContainerAllocationModel(containerType: val, quantity: 1));
                                          } else {
                                            _containers[0] = ContainerAllocationModel(
                                              containerType: val,
                                              quantity: _containers[0].quantity,
                                              individualContainers: _containers[0].individualContainers,
                                              vgmWeightKg: _containers[0].vgmWeightKg,
                                            );
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: _containers.isNotEmpty ? _containers.first.quantity.toString() : '1',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'عدد الحاويات المحجوزة (Qty)', border: OutlineInputBorder()),
                                    onChanged: (val) {
                                      final q = int.tryParse(val) ?? 1;
                                      setState(() {
                                        if (_containers.isEmpty) {
                                          _containers.add(ContainerAllocationModel(containerType: '40HC', quantity: q));
                                        } else {
                                          _containers[0] = ContainerAllocationModel(
                                            containerType: _containers[0].containerType,
                                            quantity: q,
                                            individualContainers: _containers[0].individualContainers,
                                            vgmWeightKg: _containers[0].vgmWeightKg,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blueGrey.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: AppTheme.cobalt),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ℹ️ ملاحظة: تخصيص الحاويات التفصيلي، أرقام السيل، أوزان VGM، والفحص يتم في مرحلة (متابعة وتجهيز التحميل).',
                                      style: TextStyle(fontSize: 11, color: AppTheme.charcoal),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ================= TAB 2: COMPLETE 17 FREIGHT QUOTE DETAILS =================
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('تفاصيل بنود عرض السعر الشاملة (Freight Quote Details 1..17):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                                const Spacer(),
                                Text('العملة الأساسية: $_mainQuoteCurrency', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 1. Container 40ft
                            _buildCostItemRow(
                              title: '1. شحن حاوية 40 قدم (Container 40ft)',
                              isApplicable: _container40ftApp,
                              onToggle: (v) => setState(() => _container40ftApp = v),
                              price: _container40ftPrice,
                              onPriceChanged: (v) => setState(() => _container40ftPrice = v),
                              currency: _container40ftCur,
                              onCurrencyChanged: (v) => setState(() => _container40ftCur = v),
                              quantity: _container40ftQty,
                              onQuantityChanged: (v) => setState(() => _container40ftQty = v),
                            ),

                            // 2. Container 20ft
                            _buildCostItemRow(
                              title: '2. شحن حاوية 20 قدم (Container 20ft)',
                              isApplicable: _container20ftApp,
                              onToggle: (v) => setState(() => _container20ftApp = v),
                              price: _container20ftPrice,
                              onPriceChanged: (v) => setState(() => _container20ftPrice = v),
                              currency: _container20ftCur,
                              onCurrencyChanged: (v) => setState(() => _container20ftCur = v),
                              quantity: _container20ftQty,
                              onQuantityChanged: (v) => setState(() => _container20ftQty = v),
                            ),

                            // 3. LCL CBM Cost
                            _buildCostItemRow(
                              title: '3. LCL CBM Cost (شحن LCL لشحنة CBM)',
                              isApplicable: _lclCbmApp,
                              onToggle: (v) => setState(() => _lclCbmApp = v),
                              price: _lclCbmPrice,
                              onPriceChanged: (v) => setState(() => _lclCbmPrice = v),
                              currency: _lclCbmCur,
                              onCurrencyChanged: (v) => setState(() => _lclCbmCur = v),
                              doubleQty: _lclCbmQty,
                              onDoubleQtyChanged: (v) => setState(() => _lclCbmQty = v),
                            ),

                            // 4. Express Courier
                            _buildCostItemRow(
                              title: '4. البريد السريع للمستندات (Express Courier)',
                              isApplicable: _expressCourierApp,
                              onToggle: (v) => setState(() => _expressCourierApp = v),
                              price: _expressCourierPrice,
                              onPriceChanged: (v) => setState(() => _expressCourierPrice = v),
                              currency: _expressCourierCur,
                              onCurrencyChanged: (v) => setState(() => _expressCourierCur = v),
                            ),

                            // 5. EUR.1 / ATR Certificate
                            _buildCostItemRow(
                              title: '5. شهادة المنشأ (EUR.1 / ATR Certificate)',
                              isApplicable: _eurAtrApp,
                              onToggle: (v) => setState(() => _eurAtrApp = v),
                              price: _eurAtrPrice,
                              onPriceChanged: (v) => setState(() => _eurAtrPrice = v),
                              currency: _eurAtrCur,
                              onCurrencyChanged: (v) => setState(() => _eurAtrCur = v),
                            ),

                            // 6. SOLAS/VGM Fees
                            _buildCostItemRow(
                              title: '6. مصاريف التحقق من الوزن (SOLAS/VGM Fees)',
                              isApplicable: _solasVgmApp,
                              onToggle: (v) => setState(() => _solasVgmApp = v),
                              price: _solasVgmPrice,
                              onPriceChanged: (v) => setState(() => _solasVgmPrice = v),
                              currency: _solasVgmCur,
                              onCurrencyChanged: (v) => setState(() => _solasVgmCur = v),
                            ),

                            // 7. VGM Notification Fee
                            _buildCostItemRow(
                              title: '7. إخطار إقرار الوزن (VGM Notification Fee)',
                              isApplicable: _vgmNotifApp,
                              onToggle: (v) => setState(() => _vgmNotifApp = v),
                              price: _vgmNotifPrice,
                              onPriceChanged: (v) => setState(() => _vgmNotifPrice = v),
                              currency: _vgmNotifCur,
                              onCurrencyChanged: (v) => setState(() => _vgmNotifCur = v),
                            ),

                            // 8. Telex Release
                            _buildCostItemRow(
                              title: '8. إطلاق الفاكس الملاحي (Telex Release)',
                              isApplicable: _telexReleaseApp,
                              onToggle: (v) => setState(() => _telexReleaseApp = v),
                              price: _telexReleasePrice,
                              onPriceChanged: (v) => setState(() => _telexReleasePrice = v),
                              currency: _telexReleaseCur,
                              onCurrencyChanged: (v) => setState(() => _telexReleaseCur = v),
                            ),

                            // 9. Marine Insurance
                            _buildCostItemRow(
                              title: '9. بوليصة التأمين البحري (Insurance)',
                              isApplicable: _insuranceApp,
                              onToggle: (v) => setState(() => _insuranceApp = v),
                              price: _insurancePrice,
                              onPriceChanged: (v) => setState(() => _insurancePrice = v),
                              currency: _insuranceCur,
                              onCurrencyChanged: (v) => setState(() => _insuranceCur = v),
                            ),

                            // 10. Booking Cancellation
                            _buildCostItemRow(
                              title: '10. غرامة إلغاء الحجز (Booking Cancellation)',
                              isApplicable: _cancellationApp,
                              onToggle: (v) => setState(() => _cancellationApp = v),
                              price: _cancellationPrice,
                              onPriceChanged: (v) => setState(() => _cancellationPrice = v),
                              currency: _cancellationCur,
                              onCurrencyChanged: (v) => setState(() => _cancellationCur = v),
                            ),

                            // 11. ICS2 Filing Fee
                            _buildCostItemRow(
                              title: '11. رسوم إيداع بيان الحمول المسبقة (ICS2 Filing Fee)',
                              isApplicable: _ics2App,
                              onToggle: (v) => setState(() => _ics2App = v),
                              price: _ics2Price,
                              onPriceChanged: (v) => setState(() => _ics2Price = v),
                              currency: _ics2Cur,
                              onCurrencyChanged: (v) => setState(() => _ics2Cur = v),
                            ),

                            // 12. Other Fees
                            _buildCostItemRow(
                              title: '12. مصاريف ورسوم أخرى (Other Fees)',
                              isApplicable: _otherFeesApp,
                              onToggle: (v) => setState(() => _otherFeesApp = v),
                              price: _otherFeesPrice,
                              onPriceChanged: (v) => setState(() => _otherFeesPrice = v),
                              currency: _otherFeesCur,
                              onCurrencyChanged: (v) => setState(() => _otherFeesCur = v),
                            ),

                            // 13. Document Fees
                            _buildCostItemRow(
                              title: '13. مصاريف إصدار وثائق الشحن (Document Fees)',
                              isApplicable: _docFeesApp,
                              onToggle: (v) => setState(() => _docFeesApp = v),
                              price: _docFeesPrice,
                              onPriceChanged: (v) => setState(() => _docFeesPrice = v),
                              currency: _docFeesCur,
                              onCurrencyChanged: (v) => setState(() => _docFeesCur = v),
                            ),

                            // 14. Waiver Letter Fee
                            _buildCostItemRow(
                              title: '14. رسوم خطاب التنازل (Waiver Letter Fee)',
                              isApplicable: _waiverApp,
                              onToggle: (v) => setState(() => _waiverApp = v),
                              price: _waiverPrice,
                              onPriceChanged: (v) => setState(() => _waiverPrice = v),
                              currency: _waiverCur,
                              onCurrencyChanged: (v) => setState(() => _waiverCur = v),
                            ),

                            // 15. DTHC
                            _buildCostItemRow(
                              title: '15. تفريغ ومناولة ميناء الوصول (DTHC)',
                              isApplicable: _dthcApp,
                              onToggle: (v) => setState(() => _dthcApp = v),
                              price: _dthcPrice,
                              onPriceChanged: (v) => setState(() => _dthcPrice = v),
                              currency: _dthcCur,
                              onCurrencyChanged: (v) => setState(() => _dthcCur = v),
                            ),

                            // 16. Storage per one week
                            _buildCostItemRow(
                              title: '16. أرضيات / تخزين لأول أسبوع (Storage per one week)',
                              isApplicable: _storagePerWeekApp,
                              onToggle: (v) => setState(() => _storagePerWeekApp = v),
                              price: _storagePerWeekPrice,
                              onPriceChanged: (v) => setState(() => _storagePerWeekPrice = v),
                              currency: _storagePerWeekCur,
                              onCurrencyChanged: (v) => setState(() => _storagePerWeekCur = v),
                            ),

                            // 17. Extra day storage
                            _buildCostItemRow(
                              title: '17. أرضيات / تخزين لليوم الإضافي (Extra day storage)',
                              isApplicable: _extraDayStorageApp,
                              onToggle: (v) => setState(() => _extraDayStorageApp = v),
                              price: _extraDayStoragePrice,
                              onPriceChanged: (v) => setState(() => _extraDayStoragePrice = v),
                              currency: _extraDayStorageCur,
                              onCurrencyChanged: (v) => setState(() => _extraDayStorageCur = v),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _isSaving ? null : () => _submitWithContainerValidation(activeContainerRec),
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check, color: Colors.white),
            label: const Text('حفظ حجز الشحن بالكامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ================= VIEW BOOKING DIALOG =================
class _FreightBookingViewDialog extends StatelessWidget {
  final ShipmentBookingModel booking;
  const _FreightBookingViewDialog({required this.booking});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.visibility, color: AppTheme.cobalt),
          const SizedBox(width: 8),
          Text('تفاصيل حجز الشحن: ${booking.bookingCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 750,
        height: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Text('الخط الملاحي: ${booking.shippingLineName ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('رقم التأكيد: ${booking.bookingConfirmationNo ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Route & Schedule
              const Text('المسار والمواعيد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('ميناء التحميل: ${booking.polName ?? "-" }')),
                          Expanded(child: Text('ميناء الوصول: ${booking.podName ?? "-" }')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text('السفينة: ${booking.vesselName ?? "-"} (رحلة: ${booking.voyageNumber ?? "-"})')),
                          Expanded(child: Text('مدة الترانزيت: ${booking.transitTimeDays} يوم')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text('تاريخ المغادرة ETD: ${booking.etd != null ? booking.etd!.substring(0, 10) : "-" }')),
                          Expanded(child: Text('تاريخ الوصول ETA: ${booking.eta != null ? booking.eta!.substring(0, 10) : "-" }')),
                        ],
                      ),
                      if (booking.atd != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'تاريخ المغادرة الفعلي ATD: ${booking.atd!.substring(0, 10)} (${booking.departureDelayDays > 0 ? "تأخير: +${booking.departureDelayDays}d" : "في الموعد"})',
                                style: TextStyle(fontWeight: FontWeight.bold, color: booking.departureDelayDays > 0 ? Colors.red : Colors.green),
                              ),
                            ),
                            Expanded(child: Text('وصول المخزن المتوقع: ${booking.expectedWarehouseArrivalDate != null ? booking.expectedWarehouseArrivalDate!.substring(0, 10) : "-" }')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Containers
              const Text('الحاويات وأرقام السيل المخصصة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              const SizedBox(height: 6),
              ...booking.containersData.map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.quantity}x ${c.containerType} (إجمالي الوزن: ${c.vgmWeightKg.toStringAsFixed(0)} kg)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ...c.individualContainers.map((indiv) => Text('• حاوية: ${indiv.containerNumber.isEmpty ? "-" : indiv.containerNumber} | سيل: ${indiv.sealNumber.isEmpty ? "-" : indiv.sealNumber}', style: const TextStyle(fontSize: 11))),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
              // Charges Breakdown
              const Text('بنود التكاليف والنولون المعتمدة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              const SizedBox(height: 6),
              ...booking.costChargesData.map((ch) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('• ${ch.chargeType} (${ch.quantity}x ${ch.rate} ${ch.currency})'),
                      const Spacer(),
                      Text('${ch.total.toStringAsFixed(2)} ${ch.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                children: [
                  const Text('إجمالي النولون التقديري (USD):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('\$ ${booking.totalFreightCostUsd.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emerald)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }
}

// ================= PRINT BOOKING MANIFEST DIALOG =================
class _FreightBookingPrintDialog extends StatelessWidget {
  final ShipmentBookingModel booking;
  const _FreightBookingPrintDialog({required this.booking});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.print, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('طباعة بطاقة حجز الشحن (Booking Manifest): ${booking.bookingCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 520,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text('IMPORTFLOW ERP - CARRIER BOOKING CONFIRMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
                      Text('سند تأكيد حجز الشحن الملاحي (${booking.bookingCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('تاريخ الطباعة: ${DateTime.now().toIso8601String().substring(0, 16).replaceAll("T", " ")}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const Divider(thickness: 1.5),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(child: Text('الخط الملاحي: ${booking.shippingLineName ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('رقم تأكيد الحجز: ${booking.bookingConfirmationNo ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text('السفينة / الرحلة: ${booking.vesselName ?? "-"} / ${booking.voyageNumber ?? "-"}')),
                    Expanded(child: Text('الموانئ: ${booking.polName ?? "-"} ➔ ${booking.podName ?? "-"}')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text('تاريخ المغادرة (ETD): ${booking.etd != null ? booking.etd!.substring(0, 10) : "-"}')),
                    Expanded(child: Text('تاريخ الوصول (ETA): ${booking.eta != null ? booking.eta!.substring(0, 10) : "-"}')),
                  ],
                ),
                if (booking.atd != null) ...[
                  const SizedBox(height: 6),
                  Text('المغادرة الفعلية (ATD): ${booking.atd!.substring(0, 10)} (التأخير: ${booking.departureDelayDays} يوم)'),
                ],

                const SizedBox(height: 12),
                const Text('قائمة الحاويات وأرقام السيل:', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                const SizedBox(height: 4),
                ...booking.containersData.expand((c) => c.individualContainers.map((indiv) => Text('• ${c.containerType} | رقم الحاوية: ${indiv.containerNumber.isEmpty ? "N/A" : indiv.containerNumber} | رقم السيل: ${indiv.sealNumber.isEmpty ? "N/A" : indiv.sealNumber}'))),

                const SizedBox(height: 12),
                const Text('إجمالي النولون والمصاريف المعتمدة:', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                const SizedBox(height: 4),
                ...booking.costChargesData.map((ch) => Text('• ${ch.chargeType}: ${ch.total.toStringAsFixed(2)} ${ch.currency}')),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('الإجمالي العام: \$ ${booking.totalFreightCostUsd.toStringAsFixed(2)} USD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.emerald)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🖨️ تم إرسال سند الحجز للطباعة بنجاح!'), backgroundColor: AppTheme.emerald));
            Navigator.pop(context);
          },
          icon: const Icon(Icons.print, color: Colors.white),
          label: const Text('طباعة الآن (Print)', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
