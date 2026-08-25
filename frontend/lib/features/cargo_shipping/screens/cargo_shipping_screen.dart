import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/utils/import_file_po_linker.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../freight_booking/providers/freight_booking_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../cargo_insurance/screens/cargo_insurance_screen.dart';
import '../models/cargo_shipping_model.dart';
import '../providers/cargo_shipping_provider.dart';

class CargoShippingScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  const CargoShippingScreen({super.key, this.initialSubTab = 0});

  @override
  ConsumerState<CargoShippingScreen> createState() => _CargoShippingScreenState();
}

class _CargoShippingScreenState extends ConsumerState<CargoShippingScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final TextEditingController _searchController = TextEditingController();

  // Registry Filters
  String _registryStatusFilter = 'All';
  String _registrySlaFilter = 'All'; // 'All', 'OnTime', 'Breached'
  String _registryActiveFilter = 'Active'; // 'All', 'Active', 'Deleted'

  // Form State (2 Focused Steps Only)
  int _activeStepIndex = 0;
  int? _editingRecordId;
  String? _editingRecordCode;
  int? _selectedImportFileId;
  String _shipmentType = 'FCL'; // 'FCL', 'LCL'
  bool _isStackable = true;
  bool _isSaving = false;

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _cfsWarehouseCtrl = TextEditingController(text: 'Shanghai International CFS Hub #3');

  // Milestone Notes State
  final Map<int, String> _selectedMilestoneForNote = {};
  final Map<String, TextEditingController> _milestoneNoteControllers = {};

  List<ContainerLoadingModel> _containers = [];
  LclLoadingTrackingModel? _lclTracking;

  @override
  void initState() {
    super.initState();
    _activeStepIndex = widget.initialSubTab.clamp(0, 1);
    _mainTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    _initDefaultContainer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  @override
  void didUpdateWidget(covariant CargoShippingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      setState(() {
        _activeStepIndex = widget.initialSubTab.clamp(0, 1);
        _mainTabController.index = 0;
      });
    }
  }

  void _initDefaultContainer() {
    final nowIso = DateTime.now().toIso8601String();
    _containers = [
      ContainerLoadingModel(
        containerType: '40HC',
        quantity: 1,
        containerNo: 'MSCU1234567',
        sealNo: 'SL-99001',
        tareWeightKg: 3800,
        netWeightKg: 20700,
        grossWeightKg: 24500,
        vgmStatus: 'Submitted',
        vgmRefNo: 'VGM-9901',
        containerAssignmentDate: nowIso,
        trackingStatus: 'ASSIGNED',
        individualUnits: [
          {'container_no': 'MSCU1234567', 'seal_no': 'SL-99001'}
        ],
      )
    ];

    _lclTracking = LclLoadingTrackingModel(
      shipmentType: 'LCL',
      cfsWarehouseName: 'Shanghai CFS Warehouse Hub',
      consolidationScheduledDate: nowIso,
      trackingStatus: 'ASSIGNED',
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _searchController.dispose();
    _cfsWarehouseCtrl.dispose();
    for (final c in _milestoneNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _refreshAllData() {
    ref.read(cargoShippingProvider.notifier).fetchRecords(includeInactive: true);
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(freightBookingProvider.notifier).fetchBookings();
    ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
  }

  void _resetForm() {
    setState(() {
      _editingRecordId = null;
      _editingRecordCode = null;
      _selectedImportFileId = null;
      _shipmentType = 'FCL';
      _isStackable = true;
      _cfsWarehouseCtrl.text = 'Shanghai International CFS Hub #3';
      _activeStepIndex = 0;
      for (final c in _milestoneNoteControllers.values) {
        c.dispose();
      }
      _milestoneNoteControllers.clear();
      _initDefaultContainer();
    });
  }

  void _loadRecordForEditing(CargoShippingModel rec, {bool showSnack = true}) {
    setState(() {
      _editingRecordId = rec.cargoShippingId;
      _editingRecordCode = rec.cargoShippingCode;
      _selectedImportFileId = rec.importFileId;
      _shipmentType = rec.shipmentType;

      if (rec.containersLoadingData.isNotEmpty) {
        _containers = List.from(rec.containersLoadingData);
      } else {
        _initDefaultContainer();
      }

      _lclTracking = rec.lclTrackingData;
      _activeStepIndex = 1; // Open container tracking step
      for (final c in _milestoneNoteControllers.values) {
        c.dispose();
      }
      _milestoneNoteControllers.clear();
      _selectedMilestoneForNote.clear();
    });

    _mainTabController.animateTo(0);
    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cargoShippingLoadSuccessSnack(rec.importFileCode ?? rec.cargoShippingCode)),
          backgroundColor: AppTheme.cobalt,
        ),
      );
    }
  }

  Future<void> _onImportFileSelected(int? val) async {
    if (val == null) {
      setState(() => _selectedImportFileId = null);
      return;
    }

    var existingRecords = ref.read(cargoShippingProvider).value ?? [];
    if (existingRecords.isEmpty) {
      await ref.read(cargoShippingProvider.notifier).fetchRecords(includeInactive: true);
      existingRecords = ref.read(cargoShippingProvider).value ?? [];
    }

    final existingRec = existingRecords.where((r) => r.importFileId == val && r.isActive).firstOrNull;

    if (existingRec != null) {
      // Automatically load the saved draft/record seamlessly!
      _loadRecordForEditing(existingRec, showSnack: true);
    } else {
      final bookings = ref.read(freightBookingProvider).value ?? [];
      final linkedBooking = bookings.where((b) => b.importFileId == val && b.isActive).firstOrNull;

      setState(() {
        _selectedImportFileId = val;
        _editingRecordId = null;
        _editingRecordCode = null;
        for (final c in _milestoneNoteControllers.values) {
          c.dispose();
        }
        _milestoneNoteControllers.clear();

        if (linkedBooking != null) {
          _shipmentType = linkedBooking.shipmentType == 'LCL' ? 'LCL' : 'FCL';
          if (_shipmentType == 'FCL' && linkedBooking.containersData.isNotEmpty) {
            final nowIso = DateTime.now().toIso8601String();
            final List<ContainerLoadingModel> loadedContainers = [];
            for (final alloc in linkedBooking.containersData) {
              for (int uIdx = 0; uIdx < alloc.individualContainers.length; uIdx++) {
                final indiv = alloc.individualContainers[uIdx];
                final cNo = indiv.containerNumber.isNotEmpty ? indiv.containerNumber : 'MSCU${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}${loadedContainers.length + 1}';
                final sNo = indiv.sealNumber.isNotEmpty ? indiv.sealNumber : 'SL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}${loadedContainers.length + 1}';
                loadedContainers.add(
                  ContainerLoadingModel(
                    containerType: alloc.containerType.isNotEmpty ? alloc.containerType : '40HC',
                    quantity: 1,
                    containerNo: cNo,
                    sealNo: sNo,
                    tareWeightKg: 3800,
                    netWeightKg: indiv.vgmWeightKg > 3800 ? (indiv.vgmWeightKg - 3800) : 20700,
                    grossWeightKg: indiv.vgmWeightKg > 0 ? indiv.vgmWeightKg : 24500,
                    vgmStatus: 'Submitted',
                    vgmRefNo: 'VGM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    containerAssignmentDate: nowIso,
                    trackingStatus: 'ASSIGNED',
                    individualUnits: [
                      {'container_no': cNo, 'seal_no': sNo}
                    ],
                  ),
                );
              }
            }
            if (loadedContainers.isNotEmpty) {
              _containers = loadedContainers;
            } else {
              _initDefaultContainer();
            }
          } else {
            _initDefaultContainer();
          }
        } else {
          _initDefaultContainer();
        }
      });
    }
  }

  // ===========================================================================
  // DATE & TIME PICKER HELPERS
  // ===========================================================================
  String _formatDisplayDateTime(String? raw, BuildContext ctx) {
    if (raw == null || raw.trim().isEmpty) return ctx.l10n.cargoShippingClickToSetDateTime;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final datePart = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    if (!raw.contains('T') && !raw.contains(':')) {
      return datePart;
    }
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? (Localizations.localeOf(ctx).languageCode == 'ar' ? 'م' : 'PM') : (Localizations.localeOf(ctx).languageCode == 'ar' ? 'ص' : 'AM');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$datePart | $hour:$minute $ampm";
  }

  Future<String?> _pickDateTime(BuildContext context, {String? initialIso, DateTime? minDate, String? title}) async {
    final now = DateTime.now();
    final initDt = (initialIso != null && initialIso.isNotEmpty) ? (DateTime.tryParse(initialIso) ?? now) : now;
    final effectiveInit = (minDate != null && initDt.isBefore(minDate)) ? minDate : initDt;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: effectiveInit,
      firstDate: minDate ?? DateTime(2020),
      lastDate: DateTime(2035),
      helpText: title ?? context.l10n.cargoShippingPickMilestone1,
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.confirm,
    );
    if (pickedDate == null) return null;

    if (!context.mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(effectiveInit),
      helpText: title ?? context.l10n.cargoShippingPickMilestone1,
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.confirm,
    );
    if (pickedTime == null) return null;

    final finalDt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (minDate != null && finalDt.isBefore(minDate)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cargoShippingDateSequenceError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return finalDt.toIso8601String();
  }

  // ===========================================================================
  // PROGRESSIVE / QUICK SAVE FOR CONTAINER MILESTONE
  // ===========================================================================
  Future<void> _quickSaveContainerMilestone(int containerIndex) async {
    final c = _containers[containerIndex];

    // If no import file is selected yet, prompt the user
    if (_selectedImportFileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cargoShippingSelectFileFirstForContainer),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_editingRecordId == null) {
      final existingRecords = ref.read(cargoShippingProvider).value ?? [];
      final existingRec = existingRecords.where((r) => r.importFileId == _selectedImportFileId && r.isActive).firstOrNull;
      if (existingRec != null) {
        _editingRecordId = existingRec.cargoShippingId;
        _editingRecordCode = existingRec.cargoShippingCode;
      }
    }

    if (_editingRecordId != null) {
      setState(() => _isSaving = true);
      try {
        final payload = {
          'container_assignment_date': c.containerAssignmentDate,
          'arrival_at_supplier_at': c.arrivalAtSupplierAt,
          'loading_start_at': c.loadingStartAt,
          'loading_end_at': c.loadingEndAt,
          'port_gate_in_at': c.portGateInAt,
          'milestone_notes': c.milestoneNotes,
        };
        final updatedRecord = await ref.read(cargoShippingProvider.notifier).updateContainerTracking(
          _editingRecordId!,
          c.containerNo,
          payload,
        );
        if (mounted) {
          if (updatedRecord != null && updatedRecord.containersLoadingData.isNotEmpty) {
            setState(() {
              _containers = List.from(updatedRecord.containersLoadingData);
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.cargoShippingSaveContainerMilestoneSuccess(c.containerNo, c.getLocalizedStatus(context.l10n))),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } catch (e) {
        if (e.toString().contains('404')) {
          _editingRecordId = null;
          await _submitForm(isDraftProgressive: true);
        } else if (mounted) {
          final cleanMsg = e is DioException
              ? (e.response?.data?['detail'] ?? e.message ?? 'Server error')
              : e.toString().replaceAll('Exception:', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.cargoShippingQuickSaveError(cleanMsg)), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      await _submitForm(isDraftProgressive: true);
    }
  }

  Future<void> _quickSaveLclMilestone() async {
    if (_lclTracking == null) return;

    if (_selectedImportFileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cargoShippingSelectFileFirstForLcl),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_editingRecordId == null) {
      final existingRecords = ref.read(cargoShippingProvider).value ?? [];
      final existingRec = existingRecords.where((r) => r.importFileId == _selectedImportFileId && r.isActive).firstOrNull;
      if (existingRec != null) {
        _editingRecordId = existingRec.cargoShippingId;
        _editingRecordCode = existingRec.cargoShippingCode;
      }
    }

    if (_editingRecordId != null) {
      setState(() => _isSaving = true);
      try {
        final updatedRecord = await ref.read(cargoShippingProvider.notifier).updateLclTracking(
          _editingRecordId!,
          _lclTracking!.toJson(),
        );
        if (mounted) {
          if (updatedRecord != null && updatedRecord.lclTrackingData != null) {
            setState(() {
              _lclTracking = updatedRecord.lclTrackingData;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.cargoShippingSaveLclMilestoneSuccess(_lclTracking!.getLocalizedStatus(context.l10n))),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } catch (e) {
        if (e.toString().contains('404')) {
          _editingRecordId = null;
          await _submitForm(isDraftProgressive: true);
        } else if (mounted) {
          final cleanMsg = e is DioException
              ? (e.response?.data?['detail'] ?? e.message ?? 'Server error')
              : e.toString().replaceAll('Exception:', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.cargoShippingLclSaveError(cleanMsg)), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      await _submitForm(isDraftProgressive: true);
    }
  }

  void _autoCompleteAllContainersTracking() {
    final now = DateTime.now();
    final isoNow = now.toIso8601String();

    setState(() {
      if (_shipmentType == 'FCL') {
        for (int i = 0; i < _containers.length; i++) {
          final c = _containers[i];
          _containers[i] = ContainerLoadingModel(
            containerType: c.containerType,
            quantity: c.quantity,
            containerNo: c.containerNo,
            sealNo: c.sealNo,
            tareWeightKg: c.tareWeightKg,
            netWeightKg: c.netWeightKg,
            grossWeightKg: c.grossWeightKg,
            vgmStatus: 'Submitted',
            vgmRefNo: c.vgmRefNo ?? 'VGM-${now.millisecondsSinceEpoch.toString().substring(8)}',
            individualUnits: c.individualUnits,
            containerAssignmentDate: c.containerAssignmentDate ?? now.subtract(const Duration(hours: 40)).toIso8601String(),
            arrivalAtSupplierAt: c.arrivalAtSupplierAt ?? now.subtract(const Duration(hours: 30)).toIso8601String(),
            loadingStartAt: c.loadingStartAt ?? now.subtract(const Duration(hours: 24)).toIso8601String(),
            loadingEndAt: c.loadingEndAt ?? now.subtract(const Duration(hours: 12)).toIso8601String(),
            portGateInAt: c.portGateInAt ?? isoNow,
            trackingStatus: 'GATED_IN_AT_PORT',
            isSlaBreached: false,
          );
        }
      } else {
        _lclTracking = LclLoadingTrackingModel(
          shipmentType: 'LCL',
          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
          consolidationScheduledDate: now.subtract(const Duration(hours: 40)).toIso8601String(),
          arrivalAtCfsAt: now.subtract(const Duration(hours: 30)).toIso8601String(),
          stuffingStartAt: now.subtract(const Duration(hours: 24)).toIso8601String(),
          stuffingEndAt: now.subtract(const Duration(hours: 12)).toIso8601String(),
          portGateInAt: isoNow,
          trackingStatus: 'GATED_IN_AT_PORT',
          isSlaBreached: false,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.cargoShippingAutoCompleteSuccess),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  Future<void> _submitForm({bool isDraftProgressive = false}) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cargoShippingFillRequiredFields), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cargoShippingSelectLinkedFilePrompt), backgroundColor: Colors.orange),
      );
      return;
    }

    // Check duplicate import file locally first
    final existingRecords = ref.read(cargoShippingProvider).value ?? [];
    final dupRecord = existingRecords.where((r) => r.importFileId == _selectedImportFileId && r.isActive).toList();
    if (dupRecord.isNotEmpty && _editingRecordId == null) {
      _editingRecordId = dupRecord.first.cargoShippingId;
      _editingRecordCode = dupRecord.first.cargoShippingCode;
    }

    setState(() => _isSaving = true);

    final payload = {
      'import_file_id': _selectedImportFileId,
      'shipment_type': _shipmentType,
      'containers_loading_data': _containers.map((c) => c.toJson()).toList(),
      'lcl_tracking_data': _shipmentType == 'LCL' && _lclTracking != null ? _lclTracking!.toJson() : null,
      'status': 'Cargo Ready',
      'owner': 'Kamal',
    };

    try {
      CargoShippingModel? resultRecord;
      if (_editingRecordId != null) {
        resultRecord = await ref.read(cargoShippingProvider.notifier).updateRecord(_editingRecordId!, payload);
      } else {
        resultRecord = await ref.read(cargoShippingProvider.notifier).createRecord(payload);
      }

      if (mounted) {
        if (resultRecord != null) {
          setState(() {
            _editingRecordId = resultRecord!.cargoShippingId;
            _editingRecordCode = resultRecord.cargoShippingCode;
            if (resultRecord.containersLoadingData.isNotEmpty) {
              _containers = List.from(resultRecord.containersLoadingData);
            }
            _lclTracking = resultRecord.lclTrackingData;
          });
        }

        if (isDraftProgressive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.cargoShippingDraftSaveSuccess),
              backgroundColor: AppTheme.emerald,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.cargoShippingStudySaveSuccess(_editingRecordCode ?? "")),
              backgroundColor: AppTheme.emerald,
            ),
          );
          _resetForm();
          _mainTabController.animateTo(1);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Text(context.l10n.cargoShippingDuplicateWarningTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(errorMsg, style: const TextStyle(fontSize: 13, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.close),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mainTabController.animateTo(1);
                },
                child: Text(context.l10n.cargoShippingGoToSavedRegistry, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.local_shipping_outlined,
        titleEn: 'Loading & Tracking Form',
        titleAr: 'تجهيز الشحن ومتابعة التحميل',
      ),
      const VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Saved Cargo Registry',
        titleAr: 'سجل متابعة الشحنات والتحميل',
      ),
    ];
    final isTrackingTab = _activeStepIndex == 1;

    return VerticalStageScaffold(
      stageCode: isTrackingTab ? 'STEP-08' : 'STEP-07',
      titleEn: isTrackingTab ? 'Cargo Shipping Tracking (48h SLA)' : 'Freight Allocations & Cargo Shipping (VGM)',
      titleAr: isTrackingTab ? 'متابعة حركة الشحن وتحميل وتوريد الحاويات (48h SLA)' : 'تخصيص وتوزيع الحاويات ومتابعة حركة الشحن (VGM)',
      headerIcon: isTrackingTab ? Icons.directions_boat_outlined : Icons.grid_view_outlined,
      headerColor: isTrackingTab ? AppTheme.cobalt : AppTheme.emerald,
      tabs: tabs,
      selectedIndex: _mainTabController.index,
      onTabSelected: (index) => setState(() => _mainTabController.index = index),
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: () {
        ref.read(importFilesProvider.notifier).fetchImportFiles();
      },
      headerActions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.shield_outlined, size: 16, color: Colors.white),
          label: Text(
            Localizations.localeOf(context).languageCode == 'ar' ? 'وثيقة التأمين (Insurance)' : 'Cargo Insurance',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {
            CargoInsuranceScreen.showCreateDialog(
              context,
              initialImportFileId: _selectedImportFileId,
            );
          },
        ),
        const SizedBox(width: 8),
        SmartUploadButton(
          module: SmartUploadModule.cargoShipping,
          label: context.l10n.cargoShippingUploadBlLabel,
          onDataExtracted: (result) {
            final fields = result.extractedFields;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.cargoShippingUploadBlSuccess(fields['bl_number'] ?? 'N/A'),
                ),
                backgroundColor: AppTheme.emerald,
                duration: const Duration(seconds: 5),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: context.l10n.liveReload,
          onPressed: _refreshAllData,
        ),
      ],
      body: IndexedStack(
        index: _mainTabController.index,
        children: [
          _buildInteractiveShippingFormTab(),
          _buildSavedShippingRegistryTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: INTERACTIVE FORM & 2-STEP WORKSPACE
  // ===========================================================================
  Widget _buildInteractiveShippingFormTab() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final poState = ref.watch(purchaseOrdersProvider);
    final poList = poState.purchaseOrders;

    // Selected file details for top banner
    final matchingFiles = importFiles.where((f) => f.importFileId == _selectedImportFileId).toList();
    final curFile = matchingFiles.isNotEmpty ? matchingFiles.first : null;

    // Calculate aggregated cargo metrics from linked POs / Packing Lists
    double totalCargoCbm = 0.0;
    double totalCargoWeightKg = 0.0;
    if (_selectedImportFileId != null && curFile != null) {
      final filePos = ImportFilePoLinker.getLinkedPOs(file: curFile, allPOs: poList);
      final metrics = ImportFilePoLinker.computeMetrics(file: curFile, linkedPOs: filePos);
      totalCargoCbm = metrics.cbm;
      totalCargoWeightKg = metrics.weightKg;
    }

    if (totalCargoCbm == 0 && _selectedImportFileId != null) {
      totalCargoCbm = 40.0;
      totalCargoWeightKg = 2274.0;
    }

    final dualRec = ContainerRequirementEngine.calculateBoth(
      totalCbm: totalCargoCbm > 0 ? totalCargoCbm : 40.0,
      totalWeightKg: totalCargoWeightKg > 0 ? totalCargoWeightKg : 2274.0,
    );
    final activeContainerRec = _isStackable ? dualRec.stackableResult : dualRec.nonStackableResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Active File Banner
            if (_selectedImportFileId != null && curFile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cobalt),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_special, color: AppTheme.cobalt, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${context.l10n.cargoShippingLinkedFileBannerPrefix} [${curFile.importFileCode}] ${curFile.companyName} | ${context.l10n.cargoShippingSupplierLabel} ${curFile.supplierName}${curFile.acidNumber != null ? " | ACID: ${curFile.acidNumber}" : ""}${_editingRecordCode != null ? " (${context.l10n.cargoShippingCodeLabel} $_editingRecordCode)" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
                      ),
                    ),
                    if (_editingRecordId != null)
                      TextButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: Text(context.l10n.cargoShippingCancelStartNew, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),

            // Stepper Navigation Sub-Tabs (2 Steps Only)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  _buildStepperButton(0, context.l10n.cargoShippingStep1Title, Icons.inventory_2_outlined),
                  _buildStepperButton(1, context.l10n.cargoShippingStep2Title, Icons.timelapse_outlined),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Step Content Area
            IndexedStack(
              index: _activeStepIndex,
              children: [
                _buildStep1ContainerAssignment(importFiles, totalCargoCbm, totalCargoWeightKg, activeContainerRec),
                _buildStep2ContainerLoadingTracking(importFiles, curFile),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Action Toolbar
            _buildBottomActionToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton(int index, String title, IconData icon) {
    final isSelected = _activeStepIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeStepIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cobalt : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.charcoal),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppTheme.charcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= STEP 1: CONTAINERS & VGM ASSIGNMENT =================
  Widget _buildStep1ContainerAssignment(
    List<dynamic> importFiles,
    double totalCargoCbm,
    double totalCargoWeightKg,
    ContainerRecommendationResult activeContainerRec,
  ) {
    final existingRecords = ref.watch(cargoShippingProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SearchableDropdownField<int?>(
                  labelText: context.l10n.cargoShippingImportFileLabel,
                  hintText: context.l10n.cargoShippingImportFileHint,
                  value: _selectedImportFileId,
                  items: [
                    SearchableDropdownItem<int?>(value: null, label: context.l10n.cargoShippingImportFileDefault),
                    ...importFiles.map((f) {
                      final hasExisting = existingRecords.any((r) => r.importFileId == f.importFileId && r.isActive);
                      return SearchableDropdownItem<int?>(
                        value: f.importFileId,
                        label: '[${f.importFileCode}] ${f.companyName} | ACID: ${f.acidNumber ?? "N/A"}${hasExisting ? " ${context.l10n.cargoShippingPreviouslyRegistered}" : ""}',
                        subtitle: f.supplierName,
                      );
                    }),
                  ],
                  onChanged: (val) => _onImportFileSelected(val),
                  validator: (v) => v == null ? context.l10n.cargoShippingSelectFileValidator : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  labelText: context.l10n.cargoShippingShipmentTypeLabel,
                  value: _shipmentType,
                  items: [
                    SearchableDropdownItem(value: 'FCL', label: context.l10n.cargoShippingFclLabel),
                    SearchableDropdownItem(value: 'LCL', label: context.l10n.cargoShippingLclLabel),
                  ],
                  onChanged: (val) => setState(() => _shipmentType = val ?? 'FCL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stacking & Container Recommendation Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.cargoShippingAggregatedCargoMetrics(totalCargoCbm.toStringAsFixed(2), totalCargoWeightKg.toStringAsFixed(0)),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(context.l10n.cargoShippingCargoStackingLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(context.l10n.cargoShippingStackable),
                      selected: _isStackable,
                      onSelected: (val) => setState(() => _isStackable = val),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(context.l10n.cargoShippingNonStackable),
                      selected: !_isStackable,
                      onSelected: (val) => setState(() => _isStackable = !val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Text(
                    context.l10n.cargoShippingAutoRecommendation(
                      activeContainerRec.requiredContainersCount,
                      activeContainerRec.recommendedContainerCode,
                      activeContainerRec.spaceUtilizationPercent.toStringAsFixed(1),
                      activeContainerRec.payloadUtilizationPercent.toStringAsFixed(1),
                    ),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Container Allocation Header
          if (_shipmentType == 'FCL') ...[
            Row(
              children: [
                Text(context.l10n.cargoShippingContainersHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                  onPressed: () {
                    setState(() {
                      final nowMs = DateTime.now().millisecondsSinceEpoch.toString();
                      final nowIso = DateTime.now().toIso8601String();
                      _containers.add(ContainerLoadingModel(
                        containerType: '40HC',
                        quantity: 1,
                        containerNo: 'MSCU${nowMs.substring(6)}',
                        sealNo: 'SL-${nowMs.substring(8)}',
                        grossWeightKg: 24500,
                        containerAssignmentDate: nowIso,
                        trackingStatus: 'ASSIGNED',
                        individualUnits: [
                          {
                            'container_no': 'MSCU${nowMs.substring(6)}',
                            'seal_no': 'SL-${nowMs.substring(8)}',
                          }
                        ],
                      ));
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: Text(context.l10n.cargoShippingAddContainerType, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Container Equipment List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _containers.length,
              separatorBuilder: (c, i) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = _containers[index];
                return _buildContainerEquipmentCard(item, index);
              },
            ),
          ] else ...[
            // LCL CFS Warehouse Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.cargoShippingCfsHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cfsWarehouseCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.cargoShippingCfsWarehouseLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.warehouse, color: AppTheme.cobalt),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContainerEquipmentCard(ContainerLoadingModel item, int index) {
    final qty = item.quantity;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchableDropdownField<String>(
                  value: item.containerType,
                  labelText: context.l10n.cargoShippingContainerType,
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
                        _containers[index] = ContainerLoadingModel(
                          containerType: val,
                          quantity: item.quantity,
                          containerNo: item.containerNo,
                          sealNo: item.sealNo,
                          tareWeightKg: item.tareWeightKg,
                          netWeightKg: item.netWeightKg,
                          grossWeightKg: item.grossWeightKg,
                          vgmStatus: item.vgmStatus,
                          vgmRefNo: item.vgmRefNo,
                          individualUnits: item.individualUnits,
                          containerAssignmentDate: item.containerAssignmentDate,
                          arrivalAtSupplierAt: item.arrivalAtSupplierAt,
                          loadingStartAt: item.loadingStartAt,
                          loadingEndAt: item.loadingEndAt,
                          portGateInAt: item.portGateInAt,
                          trackingStatus: item.trackingStatus,
                          isSlaBreached: item.isSlaBreached,
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: context.l10n.cargoShippingQty, border: const OutlineInputBorder()),
                  onChanged: (val) {
                    final q = int.tryParse(val) ?? 1;
                    setState(() {
                      final units = List<Map<String, String>>.from(item.individualUnits);
                      while (units.length < q) {
                        final ms = DateTime.now().millisecondsSinceEpoch.toString();
                        units.add({
                          'container_no': 'MSCU${ms.substring(6)}${units.length + 1}',
                          'seal_no': 'SL-${ms.substring(8)}${units.length + 1}',
                        });
                      }
                      if (units.length > q) units.removeRange(q, units.length);
                      _containers[index] = ContainerLoadingModel(
                        containerType: item.containerType,
                        quantity: q,
                        containerNo: units.isNotEmpty ? units.first['container_no'] ?? '' : '',
                        sealNo: units.isNotEmpty ? units.first['seal_no'] ?? '' : '',
                        tareWeightKg: item.tareWeightKg,
                        netWeightKg: item.netWeightKg,
                        grossWeightKg: item.grossWeightKg,
                        vgmStatus: item.vgmStatus,
                        vgmRefNo: item.vgmRefNo,
                        individualUnits: units,
                        containerAssignmentDate: item.containerAssignmentDate,
                        arrivalAtSupplierAt: item.arrivalAtSupplierAt,
                        loadingStartAt: item.loadingStartAt,
                        loadingEndAt: item.loadingEndAt,
                        portGateInAt: item.portGateInAt,
                        trackingStatus: item.trackingStatus,
                        isSlaBreached: item.isSlaBreached,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: item.grossWeightKg.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: context.l10n.cargoShippingVgmWeight, border: const OutlineInputBorder()),
                  onChanged: (val) {
                    final w = double.tryParse(val) ?? 0.0;
                    setState(() {
                      _containers[index] = ContainerLoadingModel(
                        containerType: item.containerType,
                        quantity: item.quantity,
                        containerNo: item.containerNo,
                        sealNo: item.sealNo,
                        tareWeightKg: item.tareWeightKg,
                        netWeightKg: item.netWeightKg,
                        grossWeightKg: w,
                        vgmStatus: item.vgmStatus,
                        vgmRefNo: item.vgmRefNo,
                        individualUnits: item.individualUnits,
                        containerAssignmentDate: item.containerAssignmentDate,
                        arrivalAtSupplierAt: item.arrivalAtSupplierAt,
                        loadingStartAt: item.loadingStartAt,
                        loadingEndAt: item.loadingEndAt,
                        portGateInAt: item.portGateInAt,
                        trackingStatus: item.trackingStatus,
                        isSlaBreached: item.isSlaBreached,
                      );
                    });
                  },
                ),
              ),
              if (_containers.length > 1) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _containers.removeAt(index)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Per-Unit Container No & Seal No Fields
          Text(context.l10n.cargoShippingUnitDetailsHeader, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 6),
          ...List.generate(qty, (unitIdx) {
            final units = item.individualUnits;
            final curCNo = unitIdx < units.length ? (units[unitIdx]['container_no'] ?? '') : item.containerNo;
            final curSNo = unitIdx < units.length ? (units[unitIdx]['seal_no'] ?? '') : item.sealNo;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(context.l10n.cargoShippingUnitPrefix(unitIdx + 1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: TextFormField(
                      initialValue: curCNo,
                      decoration: InputDecoration(labelText: context.l10n.cargoShippingContainerNo, isDense: true, border: const OutlineInputBorder()),
                      onChanged: (cVal) {
                        final updatedUnits = List<Map<String, String>>.from(item.individualUnits);
                        while (updatedUnits.length <= unitIdx) {
                          updatedUnits.add({'container_no': '', 'seal_no': ''});
                        }
                        updatedUnits[unitIdx]['container_no'] = cVal;
                        _containers[index] = ContainerLoadingModel(
                          containerType: item.containerType,
                          quantity: item.quantity,
                          containerNo: updatedUnits.first['container_no'] ?? '',
                          sealNo: updatedUnits.first['seal_no'] ?? '',
                          tareWeightKg: item.tareWeightKg,
                          netWeightKg: item.netWeightKg,
                          grossWeightKg: item.grossWeightKg,
                          vgmStatus: item.vgmStatus,
                          vgmRefNo: item.vgmRefNo,
                          individualUnits: updatedUnits,
                          containerAssignmentDate: item.containerAssignmentDate,
                          arrivalAtSupplierAt: item.arrivalAtSupplierAt,
                          loadingStartAt: item.loadingStartAt,
                          loadingEndAt: item.loadingEndAt,
                          portGateInAt: item.portGateInAt,
                          trackingStatus: item.trackingStatus,
                          isSlaBreached: item.isSlaBreached,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: curSNo,
                      decoration: InputDecoration(labelText: context.l10n.cargoShippingSealNo, isDense: true, border: const OutlineInputBorder()),
                      onChanged: (sVal) {
                        final updatedUnits = List<Map<String, String>>.from(item.individualUnits);
                        while (updatedUnits.length <= unitIdx) {
                          updatedUnits.add({'container_no': '', 'seal_no': ''});
                        }
                        updatedUnits[unitIdx]['seal_no'] = sVal;
                        _containers[index] = ContainerLoadingModel(
                          containerType: item.containerType,
                          quantity: item.quantity,
                          containerNo: updatedUnits.first['container_no'] ?? '',
                          sealNo: updatedUnits.first['seal_no'] ?? '',
                          tareWeightKg: item.tareWeightKg,
                          netWeightKg: item.netWeightKg,
                          grossWeightKg: item.grossWeightKg,
                          vgmStatus: item.vgmStatus,
                          vgmRefNo: item.vgmRefNo,
                          individualUnits: updatedUnits,
                          containerAssignmentDate: item.containerAssignmentDate,
                          arrivalAtSupplierAt: item.arrivalAtSupplierAt,
                          loadingStartAt: item.loadingStartAt,
                          loadingEndAt: item.loadingEndAt,
                          portGateInAt: item.portGateInAt,
                          trackingStatus: item.trackingStatus,
                          isSlaBreached: item.isSlaBreached,
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
    );
  }


  // ================= STEP 2: CONTAINER LOADING FOLLOW-UP & 48H SLA TRACKING =================
  Widget _buildStep2ContainerLoadingTracking(List<dynamic> importFiles, dynamic curFile) {
    final existingRecords = ref.watch(cargoShippingProvider).value ?? [];

    // Calculate summary statistics
    int totalCount = _shipmentType == 'FCL' ? _containers.length : 1;
    int gatedInCount = 0;
    int inProgressCount = 0;
    int breachedCount = 0;

    if (_shipmentType == 'FCL') {
      for (var c in _containers) {
        if (c.trackingStatus == 'GATED_IN_AT_PORT') gatedInCount++;
        if (c.trackingStatus == 'LOADING_IN_PROGRESS' || c.trackingStatus == 'ARRIVED_AT_SUPPLIER') inProgressCount++;
        if (c.isSlaBreached) breachedCount++;
      }
    } else if (_lclTracking != null) {
      if (_lclTracking!.trackingStatus == 'GATED_IN_AT_PORT') gatedInCount = 1;
      if (_lclTracking!.isSlaBreached) breachedCount = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Import File Selector Card for Step 2
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SearchableDropdownField<int?>(
                      labelText: context.l10n.cargoShippingImportFileTrackingLabel,
                      hintText: context.l10n.cargoShippingImportFileTrackingHint,
                      value: _selectedImportFileId,
                      items: [
                        SearchableDropdownItem<int?>(value: null, label: context.l10n.cargoShippingImportFileDefault),
                        ...importFiles.map((f) {
                          final hasExisting = existingRecords.any((r) => r.importFileId == f.importFileId && r.isActive);
                          return SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.companyName} | ACID: ${f.acidNumber ?? "N/A"}${hasExisting ? " ${context.l10n.cargoShippingPreviouslyRegistered}" : ""}',
                            subtitle: f.supplierName,
                          );
                        }),
                      ],
                      onChanged: (val) => _onImportFileSelected(val),
                      validator: (v) => v == null ? context.l10n.cargoShippingSelectFileValidator : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SearchableDropdownField<String>(
                      labelText: context.l10n.cargoShippingShipmentTypeLabel,
                      value: _shipmentType,
                      items: [
                        SearchableDropdownItem(value: 'FCL', label: context.l10n.cargoShippingFclLabel),
                        SearchableDropdownItem(value: 'LCL', label: context.l10n.cargoShippingLclLabel),
                      ],
                      onChanged: (val) => setState(() => _shipmentType = val ?? 'FCL'),
                    ),
                  ),
                ],
              ),
              if (curFile != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.cobalt, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${context.l10n.cargoShippingLinkedFileBannerPrefix} [${curFile.importFileCode}] ${curFile.companyName} | ${context.l10n.cargoShippingSupplierLabel} ${curFile.supplierName} | ACID: ${curFile.acidNumber ?? "N/A"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Top Summary Dashboard Cards
        Row(
          children: [
            _buildMetricSummaryCard(context.l10n.cargoShippingMetricTotalContainers, totalCount.toString(), Icons.inventory_2, AppTheme.cobalt),
            const SizedBox(width: 8),
            _buildMetricSummaryCard(context.l10n.cargoShippingMetricInProgress, inProgressCount.toString(), Icons.hourglass_top, AppTheme.orange),
            const SizedBox(width: 8),
            _buildMetricSummaryCard(context.l10n.cargoShippingMetricGatedIn, gatedInCount.toString(), Icons.check_circle, AppTheme.emerald),
            const SizedBox(width: 8),
            _buildMetricSummaryCard(context.l10n.cargoShippingMetricSlaBreached, breachedCount.toString(), Icons.warning, breachedCount > 0 ? AppTheme.crimson : Colors.grey),
          ],
        ),
        const SizedBox(height: 12),

        // FCL Mode: Individual Container Cards
        if (_shipmentType == 'FCL') ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _containers.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final container = _containers[index];
              return _buildFclContainerTrackingCard(container, index);
            },
          ),
        ] else ...[
          // LCL Mode: Single CFS Consolidation Card
          _buildLclConsolidationTrackingCard(),
        ],
      ],
    );
  }

  Widget _buildMetricSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 3)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFclContainerTrackingCard(ContainerLoadingModel c, int index) {
    DateTime? assignDt = c.containerAssignmentDate != null ? DateTime.tryParse(c.containerAssignmentDate!) : null;
    DateTime? arrivalDt = c.arrivalAtSupplierAt != null ? DateTime.tryParse(c.arrivalAtSupplierAt!) : assignDt;
    DateTime? loadStartDt = c.loadingStartAt != null ? DateTime.tryParse(c.loadingStartAt!) : arrivalDt;
    DateTime? loadEndDt = c.loadingEndAt != null ? DateTime.tryParse(c.loadingEndAt!) : loadStartDt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.isSlaBreached ? AppTheme.crimson : Colors.grey.shade300, width: c.isSlaBreached ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Container No + Status + SLA Alert + Quick Save Milestone Button
          Row(
            children: [
              const Icon(Icons.directions_boat, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.cargoShippingContainerCardHeader(index + 1, c.containerNo, c.containerType, c.sealNo),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.statusColor),
                ),
                child: Text(
                  c.getLocalizedStatus(context.l10n),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.statusColor),
                ),
              ),
              const SizedBox(width: 8),
              if (c.isSlaBreached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.crimson),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm_off, size: 14, color: AppTheme.crimson),
                      const SizedBox(width: 4),
                      Text(context.l10n.cargoShippingSlaBreachedBadge, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.crimson)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: AppTheme.cobalt,
                  elevation: 0,
                  side: const BorderSide(color: AppTheme.cobalt),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _quickSaveContainerMilestone(index),
                icon: const Icon(Icons.save, size: 16, color: AppTheme.cobalt),
                label: Text(context.l10n.cargoShippingQuickSaveContainer, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5-Milestone Visual Timeline Progress
          _buildMilestoneTimelineProgress(
            stepIndex: c.progressStepIndex,
            labels: [
              context.l10n.cargoShippingMilestone1,
              context.l10n.cargoShippingMilestone2,
              context.l10n.cargoShippingMilestone3,
              context.l10n.cargoShippingMilestone4,
              context.l10n.cargoShippingMilestone5,
            ],
          ),
          const SizedBox(height: 14),

          // 5 Interactive Milestone DateTime Picker Boxes (With Date + Time for all 5 steps)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Assignment Date & Time
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '1',
                  stepTitle: context.l10n.cargoShippingMilestone1Title,
                  valueText: c.containerAssignmentDate,
                  noteText: c.milestoneNotes['1'],
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: c.containerAssignmentDate,
                      title: context.l10n.cargoShippingPickMilestone1,
                    );
                    if (dt != null) _updateContainerTimestamp(index, assignmentDate: dt);
                  },
                  onSetNow: () {
                    final nowIso = DateTime.now().toIso8601String();
                    _updateContainerTimestamp(index, assignmentDate: nowIso);
                  },
                  onClear: () => _updateContainerTimestamp(index, assignmentDate: ''),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Arrival at Supplier
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '2',
                  stepTitle: context.l10n.cargoShippingMilestone2Title,
                  valueText: c.arrivalAtSupplierAt,
                  noteText: c.milestoneNotes['2'],
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: c.arrivalAtSupplierAt,
                      minDate: assignDt,
                      title: context.l10n.cargoShippingPickMilestone2,
                    );
                    if (dt != null) _updateContainerTimestamp(index, arrival: dt);
                  },
                  onSetNow: () {
                    _updateContainerTimestamp(index, arrival: DateTime.now().toIso8601String());
                  },
                  onClear: () => _updateContainerTimestamp(index, arrival: ''),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Loading Start
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '3',
                  stepTitle: context.l10n.cargoShippingMilestone3Title,
                  valueText: c.loadingStartAt,
                  noteText: c.milestoneNotes['3'],
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: c.loadingStartAt,
                      minDate: arrivalDt,
                      title: context.l10n.cargoShippingPickMilestone3,
                    );
                    if (dt != null) _updateContainerTimestamp(index, loadingStart: dt);
                  },
                  onSetNow: () {
                    _updateContainerTimestamp(index, loadingStart: DateTime.now().toIso8601String());
                  },
                  onClear: () => _updateContainerTimestamp(index, loadingStart: ''),
                ),
              ),
              const SizedBox(width: 8),

              // 4. Loading End
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '4',
                  stepTitle: context.l10n.cargoShippingMilestone4Title,
                  valueText: c.loadingEndAt,
                  noteText: c.milestoneNotes['4'],
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: c.loadingEndAt,
                      minDate: loadStartDt,
                      title: context.l10n.cargoShippingPickMilestone4,
                    );
                    if (dt != null) _updateContainerTimestamp(index, loadingEnd: dt);
                  },
                  onSetNow: () {
                    _updateContainerTimestamp(index, loadingEnd: DateTime.now().toIso8601String());
                  },
                  onClear: () => _updateContainerTimestamp(index, loadingEnd: ''),
                ),
              ),
              const SizedBox(width: 8),

              // 5. Port Gate-In
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '5',
                  stepTitle: context.l10n.cargoShippingMilestone5Title,
                  valueText: c.portGateInAt,
                  noteText: c.milestoneNotes['5'],
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: c.portGateInAt,
                      minDate: loadEndDt,
                      title: context.l10n.cargoShippingPickMilestone5,
                    );
                    if (dt != null) _updateContainerTimestamp(index, gateIn: dt);
                  },
                  onSetNow: () {
                    _updateContainerTimestamp(index, gateIn: DateTime.now().toIso8601String());
                  },
                  onClear: () => _updateContainerTimestamp(index, gateIn: ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Milestone-Linked Interactive Notes Section
          _buildMilestoneNotesInteractiveSection(index, c),
        ],
      ),
    );
  }

  Widget _buildMilestonePickerBox({
    required String stepNumber,
    required String stepTitle,
    required String? valueText,
    String? noteText,
    required VoidCallback onPick,
    required VoidCallback onSetNow,
    required VoidCallback onClear,
  }) {
    final hasValue = valueText != null && valueText.trim().isNotEmpty;
    final hasNote = noteText != null && noteText.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasValue ? const Color(0xFFF0FDF4) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasValue ? AppTheme.emerald : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$stepNumber. $stepTitle',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: hasValue ? AppTheme.charcoal : Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (hasValue)
                InkWell(
                  onTap: onClear,
                  child: const Icon(Icons.cancel, size: 14, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: hasValue ? AppTheme.emerald.withOpacity(0.5) : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    hasValue ? Icons.check_circle : Icons.schedule,
                    size: 14,
                    color: hasValue ? AppTheme.emerald : AppTheme.cobalt,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDisplayDateTime(valueText, context),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                        color: hasValue ? AppTheme.charcoal : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasNote) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt, size: 12, color: Colors.amber),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      noteText,
                      style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    side: BorderSide(color: hasValue ? AppTheme.emerald.withOpacity(0.6) : Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: onPick,
                  child: Text(context.l10n.cargoShippingPickBtn, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 4),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  side: const BorderSide(color: AppTheme.cobalt),
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: onSetNow,
                child: Text(context.l10n.cargoShippingSetNowBtn, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneNotesInteractiveSection(int containerIndex, ContainerLoadingModel c) {
    final selectedStep = _selectedMilestoneForNote[containerIndex] ?? '1';
    final noteKey = '${containerIndex}_$selectedStep';
    final ctrl = _milestoneNoteControllers.putIfAbsent(
      noteKey,
      () => TextEditingController(text: c.milestoneNotes[selectedStep] ?? ''),
    );
    if (ctrl.text != (c.milestoneNotes[selectedStep] ?? '')) {
      ctrl.text = c.milestoneNotes[selectedStep] ?? '';
    }

    final stepTitles = {
      '1': context.l10n.cargoShippingMilestone1,
      '2': context.l10n.cargoShippingMilestone2,
      '3': context.l10n.cargoShippingMilestone3,
      '4': context.l10n.cargoShippingMilestone4,
      '5': context.l10n.cargoShippingMilestone5,
    };

    final quickTags = [
      context.l10n.cargoShippingTagDriverDelayed,
      context.l10n.cargoShippingTagPermitPending,
      context.l10n.cargoShippingTagContainerInspection,
      context.l10n.cargoShippingTagPortCongestion,
      context.l10n.cargoShippingTagPalletizedCargo,
      context.l10n.cargoShippingTagVisualCheck,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, color: AppTheme.cobalt, size: 18),
              const SizedBox(width: 6),
              Text(
                context.l10n.cargoShippingNotesHeader(c.containerNo.isNotEmpty ? c.containerNo : context.l10n.cargoShippingUnitPrefix(containerIndex + 1)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Selector of Milestone
          Row(
            children: [
              Text(context.l10n.cargoShippingSelectMilestoneTarget, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: stepTitles.entries.map((entry) {
                    final isSel = selectedStep == entry.key;
                    final hasExistingNote = (c.milestoneNotes[entry.key]?.isNotEmpty ?? false);
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(entry.value, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          if (hasExistingNote) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.comment, size: 12, color: Colors.amber),
                          ],
                        ],
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFFE0F2FE),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedMilestoneForNote[containerIndex] = entry.key;
                            final nextKey = '${containerIndex}_${entry.key}';
                            final nextCtrl = _milestoneNoteControllers.putIfAbsent(
                              nextKey,
                              () => TextEditingController(text: c.milestoneNotes[entry.key] ?? ''),
                            );
                            nextCtrl.text = c.milestoneNotes[entry.key] ?? '';
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Quick Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: quickTags.map((tag) {
              return ActionChip(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade300)),
                label: Text(tag, style: const TextStyle(fontSize: 10, color: AppTheme.charcoal)),
                onPressed: () {
                  final cur = ctrl.text.trim();
                  if (cur.isEmpty) {
                    ctrl.text = tag;
                  } else if (!cur.contains(tag)) {
                    ctrl.text = '$cur | $tag';
                  }
                  setState(() {});
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // 3. Note Input & Save Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: context.l10n.cargoShippingNoteHint(stepTitles[selectedStep] ?? ""),
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onPressed: () {
                      final text = ctrl.text.trim();
                      final updatedNotes = Map<String, String>.from(c.milestoneNotes);
                      if (text.isEmpty) {
                        updatedNotes.remove(selectedStep);
                      } else {
                        updatedNotes[selectedStep] = text;
                      }
                      setState(() {
                        _containers[containerIndex] = c.copyWith(milestoneNotes: updatedNotes);
                      });
                      _quickSaveContainerMilestone(containerIndex);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(context.l10n.cargoShippingSaveNote, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  if (c.milestoneNotes[selectedStep]?.isNotEmpty ?? false)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero),
                      onPressed: () {
                        ctrl.clear();
                        final updatedNotes = Map<String, String>.from(c.milestoneNotes);
                        updatedNotes.remove(selectedStep);
                        setState(() {
                          _containers[containerIndex] = c.copyWith(milestoneNotes: updatedNotes);
                        });
                        _quickSaveContainerMilestone(containerIndex);
                      },
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: Text(context.l10n.cargoShippingClearNote, style: const TextStyle(fontSize: 10)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateContainerTimestamp(
    int index, {
    String? assignmentDate,
    String? arrival,
    String? loadingStart,
    String? loadingEnd,
    String? gateIn,
  }) {
    final c = _containers[index];
    final assign = assignmentDate ?? c.containerAssignmentDate;
    final arr = arrival ?? c.arrivalAtSupplierAt;
    final lStart = loadingStart ?? c.loadingStartAt;
    final lEnd = loadingEnd ?? c.loadingEndAt;
    final gIn = gateIn ?? c.portGateInAt;

    String newStatus = 'PENDING_ASSIGNMENT';
    if (gIn != null && gIn.isNotEmpty) {
      newStatus = 'GATED_IN_AT_PORT';
    } else if (lEnd != null && lEnd.isNotEmpty) {
      newStatus = 'LOADING_COMPLETED';
    } else if (lStart != null && lStart.isNotEmpty) {
      newStatus = 'LOADING_IN_PROGRESS';
    } else if (arr != null && arr.isNotEmpty) {
      newStatus = 'ARRIVED_AT_SUPPLIER';
    } else if (assign != null && assign.isNotEmpty) {
      newStatus = 'ASSIGNED';
    }

    setState(() {
      _containers[index] = c.copyWith(
        containerAssignmentDate: assign,
        arrivalAtSupplierAt: arr,
        loadingStartAt: lStart,
        loadingEndAt: lEnd,
        portGateInAt: gIn,
        trackingStatus: newStatus,
      );
    });
  }

  Widget _buildLclConsolidationTrackingCard() {
    final lcl = _lclTracking ??
        LclLoadingTrackingModel(
          shipmentType: 'LCL',
          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
          consolidationScheduledDate: DateTime.now().toIso8601String(),
          trackingStatus: 'ASSIGNED',
        );

    DateTime? schedDt = lcl.consolidationScheduledDate != null ? DateTime.tryParse(lcl.consolidationScheduledDate!) : null;
    DateTime? arrCfsDt = lcl.arrivalAtCfsAt != null ? DateTime.tryParse(lcl.arrivalAtCfsAt!) : schedDt;
    DateTime? stuffStartDt = lcl.stuffingStartAt != null ? DateTime.tryParse(lcl.stuffingStartAt!) : arrCfsDt;
    DateTime? stuffEndDt = lcl.stuffingEndAt != null ? DateTime.tryParse(lcl.stuffingEndAt!) : stuffStartDt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warehouse, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.cargoShippingLclTrackingHeader(_cfsWarehouseCtrl.text),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lcl.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lcl.statusColor),
                ),
                child: Text(
                  lcl.getLocalizedStatus(context.l10n),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: lcl.statusColor),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: AppTheme.cobalt,
                  elevation: 0,
                  side: const BorderSide(color: AppTheme.cobalt),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: _quickSaveLclMilestone,
                icon: const Icon(Icons.save, size: 16, color: AppTheme.cobalt),
                label: Text(context.l10n.cargoShippingQuickSaveLcl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timeline
          _buildMilestoneTimelineProgress(
            stepIndex: lcl.progressStepIndex,
            labels: [
              context.l10n.cargoShippingLclMilestone1,
              context.l10n.cargoShippingLclMilestone2,
              context.l10n.cargoShippingLclMilestone3,
              context.l10n.cargoShippingLclMilestone4,
              context.l10n.cargoShippingLclMilestone5,
            ],
          ),
          const SizedBox(height: 14),

          // 5 LCL Interactive Pickers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sched Date
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '1',
                  stepTitle: context.l10n.cargoShippingLclMilestone1,
                  valueText: lcl.consolidationScheduledDate,
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: lcl.consolidationScheduledDate,
                      title: context.l10n.cargoShippingLclPickMilestone1,
                    );
                    if (dt != null) {
                      setState(() => _lclTracking = LclLoadingTrackingModel(
                            cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                            consolidationScheduledDate: dt,
                            arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                            stuffingStartAt: lcl.stuffingStartAt,
                            stuffingEndAt: lcl.stuffingEndAt,
                            portGateInAt: lcl.portGateInAt,
                            trackingStatus: 'ASSIGNED',
                          ));
                    }
                  },
                  onSetNow: () {
                    final nowIso = DateTime.now().toIso8601String();
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: nowIso,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: 'ASSIGNED',
                        ));
                  },
                  onClear: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: '',
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: 'PENDING_ASSIGNMENT',
                        ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 2. Arrival CFS
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '2',
                  stepTitle: context.l10n.cargoShippingLclMilestone2,
                  valueText: lcl.arrivalAtCfsAt,
                  noteText: null,
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: lcl.arrivalAtCfsAt,
                      minDate: schedDt,
                      title: context.l10n.cargoShippingLclPickMilestone2,
                    );
                    if (dt != null) {
                      setState(() => _lclTracking = LclLoadingTrackingModel(
                            cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                            consolidationScheduledDate: lcl.consolidationScheduledDate,
                            arrivalAtCfsAt: dt,
                            stuffingStartAt: lcl.stuffingStartAt,
                            stuffingEndAt: lcl.stuffingEndAt,
                            portGateInAt: lcl.portGateInAt,
                            trackingStatus: 'ARRIVED_AT_CFS',
                          ));
                    }
                  },
                  onSetNow: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: DateTime.now().toIso8601String(),
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: 'ARRIVED_AT_CFS',
                        ));
                  },
                  onClear: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: '',
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: lcl.consolidationScheduledDate != null ? 'ASSIGNED' : 'PENDING_ASSIGNMENT',
                        ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 3. Stuffing Start
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '3',
                  stepTitle: context.l10n.cargoShippingLclMilestone3,
                  valueText: lcl.stuffingStartAt,
                  noteText: null,
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: lcl.stuffingStartAt,
                      minDate: arrCfsDt,
                      title: context.l10n.cargoShippingLclPickMilestone3,
                    );
                    if (dt != null) {
                      setState(() => _lclTracking = LclLoadingTrackingModel(
                            cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                            consolidationScheduledDate: lcl.consolidationScheduledDate,
                            arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                            stuffingStartAt: dt,
                            stuffingEndAt: lcl.stuffingEndAt,
                            portGateInAt: lcl.portGateInAt,
                            trackingStatus: 'LOADING_IN_PROGRESS',
                          ));
                    }
                  },
                  onSetNow: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: DateTime.now().toIso8601String(),
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: 'LOADING_IN_PROGRESS',
                        ));
                  },
                  onClear: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: '',
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: lcl.arrivalAtCfsAt != null ? 'ARRIVED_AT_CFS' : 'ASSIGNED',
                        ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 4. Stuffing End
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '4',
                  stepTitle: context.l10n.cargoShippingLclMilestone4,
                  valueText: lcl.stuffingEndAt,
                  noteText: null,
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: lcl.stuffingEndAt,
                      minDate: stuffStartDt,
                      title: context.l10n.cargoShippingLclPickMilestone4,
                    );
                    if (dt != null) {
                      setState(() => _lclTracking = LclLoadingTrackingModel(
                            cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                            consolidationScheduledDate: lcl.consolidationScheduledDate,
                            arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                            stuffingStartAt: lcl.stuffingStartAt,
                            stuffingEndAt: dt,
                            portGateInAt: lcl.portGateInAt,
                            trackingStatus: 'LOADING_COMPLETED',
                          ));
                    }
                  },
                  onSetNow: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: DateTime.now().toIso8601String(),
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: 'LOADING_COMPLETED',
                        ));
                  },
                  onClear: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: '',
                          portGateInAt: lcl.portGateInAt,
                          trackingStatus: lcl.stuffingStartAt != null ? 'LOADING_IN_PROGRESS' : 'ARRIVED_AT_CFS',
                        ));
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 5. Port Gate-In
              Expanded(
                child: _buildMilestonePickerBox(
                  stepNumber: '5',
                  stepTitle: context.l10n.cargoShippingLclMilestone5,
                  valueText: lcl.portGateInAt,
                  noteText: null,
                  onPick: () async {
                    final dt = await _pickDateTime(
                      context,
                      initialIso: lcl.portGateInAt,
                      minDate: stuffEndDt,
                      title: context.l10n.cargoShippingLclPickMilestone5,
                    );
                    if (dt != null) {
                      setState(() => _lclTracking = LclLoadingTrackingModel(
                            cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                            consolidationScheduledDate: lcl.consolidationScheduledDate,
                            arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                            stuffingStartAt: lcl.stuffingStartAt,
                            stuffingEndAt: lcl.stuffingEndAt,
                            portGateInAt: dt,
                            trackingStatus: 'GATED_IN_AT_PORT',
                          ));
                    }
                  },
                  onSetNow: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: DateTime.now().toIso8601String(),
                          trackingStatus: 'GATED_IN_AT_PORT',
                        ));
                  },
                  onClear: () {
                    setState(() => _lclTracking = LclLoadingTrackingModel(
                          cfsWarehouseName: _cfsWarehouseCtrl.text.trim(),
                          consolidationScheduledDate: lcl.consolidationScheduledDate,
                          arrivalAtCfsAt: lcl.arrivalAtCfsAt,
                          stuffingStartAt: lcl.stuffingStartAt,
                          stuffingEndAt: lcl.stuffingEndAt,
                          portGateInAt: '',
                          trackingStatus: lcl.stuffingEndAt != null ? 'LOADING_COMPLETED' : 'LOADING_IN_PROGRESS',
                        ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTimelineProgress({required int stepIndex, required List<String> labels}) {
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final isCompleted = (i ~/ 2) < stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppTheme.emerald : Colors.grey.shade300,
            ),
          );
        }

        final nodeIdx = i ~/ 2;
        final isReached = (nodeIdx + 1) <= stepIndex;
        final color = isReached ? AppTheme.emerald : Colors.grey.shade400;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: color,
              child: isReached
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text('${nodeIdx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 4),
            Text(
              labels[nodeIdx],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                color: isReached ? AppTheme.charcoal : Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomActionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2FE),
                foregroundColor: AppTheme.cobalt,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _autoCompleteAllContainersTracking,
              icon: const Icon(Icons.bolt, color: AppTheme.cobalt, size: 18),
              label: Text(context.l10n.cargoShippingAutoCompleteCycle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.charcoal,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _refreshAllData,
              icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
              label: Text(context.l10n.liveReload, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade800,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _resetForm,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.blueGrey),
              label: Text(context.l10n.cargoShippingClearStartNew, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: AppTheme.cobalt,
                elevation: 0,
                side: const BorderSide(color: AppTheme.cobalt),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: () => _submitForm(isDraftProgressive: true),
              icon: const Icon(Icons.save_outlined, size: 18, color: AppTheme.cobalt),
              label: Text(context.l10n.cargoShippingSaveDraft, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 2,
              ),
              onPressed: _isSaving ? null : () => _submitForm(isDraftProgressive: false),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _editingRecordId != null ? context.l10n.cargoShippingUpdateStudy : context.l10n.cargoShippingSaveStudy,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SAVED SHIPPING & LOADING REGISTRY
  // ===========================================================================
  Widget _buildSavedShippingRegistryTab() {
    final recordsAsync = ref.watch(cargoShippingProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          MasterDataToolbarWidget(
            moduleEndpoint: 'cargo-shipping',
            title: 'Cargo_Shipping_Registry',
            onRefreshNeeded: _refreshAllData,
          ),
          const SizedBox(height: 12),

          // Filters Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.l10n.cargoShippingRegistrySearchHint,
                      prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: context.l10n.cargoShippingStatusFilterLabel,
                    value: _registryStatusFilter,
                    items: [
                      SearchableDropdownItem(value: 'All', label: context.l10n.cargoShippingStatusAll),
                      SearchableDropdownItem(value: 'Cargo Ready', label: context.l10n.cargoShippingStatusCargoReady),
                      SearchableDropdownItem(value: 'Completed', label: context.l10n.cargoShippingStatusCompleted),
                    ],
                    onChanged: (v) => setState(() => _registryStatusFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: context.l10n.cargoShippingSlaFilterLabel,
                    value: _registrySlaFilter,
                    items: [
                      SearchableDropdownItem(value: 'All', label: context.l10n.cargoShippingSlaAll),
                      SearchableDropdownItem(value: 'OnTime', label: context.l10n.cargoShippingSlaOnTimeFilter),
                      SearchableDropdownItem(value: 'Breached', label: context.l10n.cargoShippingSlaBreachedFilter),
                    ],
                    onChanged: (v) => setState(() => _registrySlaFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SearchableDropdownField<String>(
                    labelText: context.l10n.cargoShippingActiveFilterLabel,
                    value: _registryActiveFilter,
                    items: [
                      SearchableDropdownItem(value: 'All', label: context.l10n.cargoShippingActiveAll),
                      SearchableDropdownItem(value: 'Active', label: context.l10n.cargoShippingActiveOnly),
                      SearchableDropdownItem(value: 'Deleted', label: context.l10n.cargoShippingDeletedOnly),
                    ],
                    onChanged: (v) => setState(() => _registryActiveFilter = v ?? 'Active'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Registry DataTable
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('${context.l10n.error}: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (list) {
                final filtered = list.where((item) {
                  // Search query
                  final query = _searchController.text.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    final matchCode = item.cargoShippingCode.toLowerCase().contains(query);
                    final matchFile = (item.importFileCode ?? '').toLowerCase().contains(query);
                    final matchCompany = (item.companyName ?? '').toLowerCase().contains(query);
                    final matchContainer = item.containersLoadingData.any((c) => c.containerNo.toLowerCase().contains(query) || c.sealNo.toLowerCase().contains(query));
                    if (!matchCode && !matchFile && !matchCompany && !matchContainer) return false;
                  }

                  // Status filter
                  if (_registryStatusFilter != 'All' && item.status != _registryStatusFilter) return false;

                  // SLA filter
                  final hasBreach = item.containersLoadingData.any((c) => c.isSlaBreached) || (item.lclTrackingData?.isSlaBreached ?? false);
                  if (_registrySlaFilter == 'Breached' && !hasBreach) return false;
                  if (_registrySlaFilter == 'OnTime' && hasBreach) return false;

                  // Active filter
                  if (_registryActiveFilter == 'Active' && !item.isActive) return false;
                  if (_registryActiveFilter == 'Deleted' && item.isActive) return false;

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(context.l10n.cargoShippingNoMatchingRecords, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                          onPressed: () => _mainTabController.animateTo(0),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(context.l10n.cargoShippingCreateNewRecord, style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final rec = filtered[idx];
                      return _buildRegistryRow(rec);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryRow(CargoShippingModel rec) {
    final hasBreach = rec.containersLoadingData.any((c) => c.isSlaBreached) || (rec.lclTrackingData?.isSlaBreached ?? false);
    final gatedCount = rec.containersLoadingData.where((c) => c.trackingStatus == 'GATED_IN_AT_PORT').length;

    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final matchingFile = importFiles.where((f) => f.importFileId == rec.importFileId).firstOrNull;
    final fileCode = matchingFile?.customFileNumber ?? matchingFile?.importFileCode ?? rec.importFileCode ?? 'IMP-${rec.importFileId}';
    final companyName = (matchingFile?.companyName.isNotEmpty == true && matchingFile?.companyName != 'N/A')
        ? matchingFile!.companyName
        : (rec.companyName != null && rec.companyName!.isNotEmpty && rec.companyName != 'N/A' ? rec.companyName! : context.l10n.importCompanies);
    final supplierName = (matchingFile?.supplierName.isNotEmpty == true && matchingFile?.supplierName != 'N/A') ? matchingFile!.supplierName : '';

    // The primary title is always formatted as [Import File Code] Company Name
    final displayName = fileCode.isNotEmpty ? '[$fileCode] $companyName' : companyName;

    return ListTile(
      onTap: () => _loadRecordForEditing(rec),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: rec.isActive ? AppTheme.cobalt.withOpacity(0.12) : Colors.grey.shade300,
        child: Icon(
          rec.isActive ? Icons.folder_special : Icons.delete_outline,
          color: rec.isActive ? AppTheme.cobalt : Colors.grey,
        ),
      ),
      title: Row(
        children: [
          // Primary Name is the Import File
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(rec.cargoShippingCode, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: rec.shipmentType == 'FCL' ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(rec.shipmentType, style: TextStyle(fontSize: 11, color: rec.shipmentType == 'FCL' ? Colors.blue : Colors.purple, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          if (!rec.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
              child: Text(context.l10n.cargoShippingSoftDeletedBadge, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${supplierName.isNotEmpty ? "${context.l10n.cargoShippingSupplierLabel} $supplierName | " : ""}${context.l10n.cargoShippingContainersHeader} ${rec.containersLoadingData.map((c) => "${c.containerNo} (${c.sealNo})").join(", ")}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildBadge(
                  '${context.l10n.status}: ${rec.status == "Completed" ? context.l10n.cargoShippingStatusCompleted : (rec.status == "Cargo Ready" ? context.l10n.cargoShippingStatusCargoReady : rec.status)}',
                  rec.status == 'Completed' ? AppTheme.emerald : AppTheme.cobalt,
                ),
                if (rec.shipmentType == 'FCL')
                  _buildBadge(
                    context.l10n.cargoShippingGatedCountBadge(gatedCount, rec.containersLoadingData.length),
                    AppTheme.emerald,
                  ),
                if (hasBreach)
                  _buildBadge(context.l10n.cargoShippingSlaBreached, AppTheme.crimson)
                else
                  _buildBadge(context.l10n.cargoShippingSlaOnTime, AppTheme.emerald),
              ],
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit Button (Restores if deleted and loads into form)
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.cobalt),
            tooltip: context.l10n.cargoShippingEditTooltip,
            onPressed: () => _loadRecordForEditing(rec),
          ),
          // Restore Button if inactive
          if (!rec.isActive)
            IconButton(
              icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald),
              tooltip: context.l10n.cargoShippingRestoreTooltip,
              onPressed: () async {
                await ref.read(cargoShippingProvider.notifier).restoreRecord(rec.cargoShippingId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.cargoShippingRestoreSuccess(rec.cargoShippingCode)), backgroundColor: AppTheme.emerald),
                  );
                }
              },
            ),
          // Soft Delete Button
          if (rec.isActive)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: context.l10n.delete,
              onPressed: () => _confirmDeleteRecord(rec),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _confirmDeleteRecord(CargoShippingModel rec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(context.l10n.cargoShippingDeleteConfirmTitle),
          ],
        ),
        content: Text(context.l10n.cargoShippingDeleteConfirmMessage(rec.cargoShippingCode, rec.importFileCode ?? '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(cargoShippingProvider.notifier).softDeleteRecord(rec.cargoShippingId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.cargoShippingDeleteSuccess(rec.cargoShippingCode)), backgroundColor: Colors.red),
                );
              }
            },
            child: Text(context.l10n.cargoShippingConfirmDeleteBtn, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
