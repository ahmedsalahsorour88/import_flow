
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../financial_approval/providers/financial_approval_provider.dart';
import '../../financial_approval/models/financial_approval_model.dart';
import '../../import_documentation/providers/import_documentation_provider.dart';
import '../../import_documentation/models/import_documentation_model.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_consultation/models/customs_consultation_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../projects/models/project_model.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../../transport_locations/models/transport_location_model.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';


class ImportFileFormDialog extends ConsumerStatefulWidget {
  final ImportFileModel? fileToEdit;
  const ImportFileFormDialog({this.fileToEdit});

  @override
  ConsumerState<ImportFileFormDialog> createState() => ImportFileFormDialogState();
}

class ImportFileFormDialogState extends ConsumerState<ImportFileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customFileIdController;
  late TextEditingController _poNoController;
  late TextEditingController _piNoController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _selectedScenarioController;
  late TextEditingController _pickupAddressController;
  late TextEditingController _polController;
  late TextEditingController _podController;
  late TextEditingController _targetFreeDaysController;
  late TextEditingController _shippingInstructionsNotesController;
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
  String _serviceTypePreference = 'Direct';
  DateTime _requiredEta = DateTime.now().add(const Duration(days: 30));
  DateTime _fileOpeningDate = DateTime.now();
  DateTime _cargoReadyDate = DateTime.now().add(const Duration(days: 7));
  String _estimatedCostCurrency = 'USD';

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
    _estimatedCostController = TextEditingController(text: (f?.estimatedCost != null && f!.estimatedCost > 0) ? f.estimatedCost.toString() : '');
    _selectedScenarioController = TextEditingController(text: f?.selectedScenario ?? '');
    _pickupAddressController = TextEditingController(text: f?.pickupAddress ?? '');
    _polController = TextEditingController(text: f?.portOfLoading ?? '');
    _podController = TextEditingController(text: f?.portOfDischarge ?? 'El Dekheila Port (non TMT)');
    _targetFreeDaysController = TextEditingController(text: (f?.targetFreeDays ?? 21).toString());
    _shippingInstructionsNotesController = TextEditingController(text: f?.shippingInstructionsNotes ?? '');
    _serviceTypePreference = f?.serviceTypePreference ?? 'Direct';
    _form4Controller = TextEditingController(text: f?.form4No ?? '');
    _swiftController = TextEditingController(text: f?.swiftNo ?? '');
    _form46Controller = TextEditingController(text: f?.form46No ?? '');
    _ownerController = TextEditingController(text: f?.owner ?? 'Kamal');
    _notesController = TextEditingController(text: f?.notes ?? '');

    if (f?.fileOpeningDate != null && f!.fileOpeningDate!.isNotEmpty) {
      _fileOpeningDate = DateTime.tryParse(f.fileOpeningDate!) ?? DateTime.now();
    }
    if (f?.cargoReadyDate != null && f!.cargoReadyDate!.isNotEmpty) {
      _cargoReadyDate = DateTime.tryParse(f.cargoReadyDate!) ?? DateTime.now().add(const Duration(days: 7));
    }
    _estimatedCostCurrency = f?.estimatedCostCurrency ?? 'USD';

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
        'file_opening_date': _fileOpeningDate.toString().substring(0, 10),
        'selected_scenario': _selectedScenarioController.text.trim().isEmpty ? null : _selectedScenarioController.text.trim(),
        'pickup_address': _pickupAddressController.text.trim().isEmpty ? null : _pickupAddressController.text.trim(),
        'port_of_loading': _polController.text.trim().isEmpty ? null : _polController.text.trim(),
        'port_of_discharge': _podController.text.trim().isEmpty ? 'El Dekheila Port (non TMT)' : _podController.text.trim(),
        'cargo_ready_date': _cargoReadyDate.toString().substring(0, 10),
        'target_free_days': int.tryParse(_targetFreeDaysController.text.trim()) ?? 21,
        'service_type_preference': _serviceTypePreference,
        'shipping_instructions_notes': _shippingInstructionsNotesController.text.trim().isEmpty ? null : _shippingInstructionsNotesController.text.trim(),
        'form4_no': _form4Controller.text.trim(),
        'swift_no': _swiftController.text.trim(),
        'form46_no': _form46Controller.text.trim(),
        'estimated_cost': double.tryParse(_estimatedCostController.text.trim()) ?? 0.0,
        'estimated_cost_currency': _estimatedCostCurrency,
        'status': _status,
        'owner': _ownerController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      if (widget.fileToEdit == null) {
        await ref.read(importFilesProvider.notifier).createImportFile(payload);
      } else {
        final oldFile = widget.fileToEdit!;
        final List<FieldChangeItem> changes = [];

        if (FieldChangeItem.isDifferent(oldFile.customFileNumber, payload['custom_file_number'])) {
          changes.add(FieldChangeItem(
            fieldName: 'رقم الملف الجمركي / الداخلي',
            oldValue: oldFile.customFileNumber,
            newValue: payload['custom_file_number'],
          ));
        }
        if (FieldChangeItem.isDifferent(oldFile.companyId, payload['company_id'])) {
          changes.add(FieldChangeItem(
            fieldName: 'الشركة المستوردة',
            oldValue: oldFile.companyName,
            newValue: 'ID: ${payload['company_id']}',
          ));
        }
        if (FieldChangeItem.isDifferent(oldFile.supplierId, payload['supplier_id'])) {
          changes.add(FieldChangeItem(
            fieldName: 'المورد الأجنبي',
            oldValue: oldFile.supplierName,
            newValue: 'ID: ${payload['supplier_id']}',
          ));
        }
        if (FieldChangeItem.isDifferent(oldFile.status, payload['status'])) {
          changes.add(FieldChangeItem(
            fieldName: 'حالة ملف الاستيراد',
            oldValue: oldFile.status,
            newValue: payload['status'],
          ));
        }
        if (FieldChangeItem.isDifferent(oldFile.notes, payload['notes'])) {
          changes.add(FieldChangeItem(
            fieldName: 'الملاحظات والتعليمات',
            oldValue: oldFile.notes,
            newValue: payload['notes'],
          ));
        }

        if (changes.isNotEmpty) {
          final confirmed = await showChangeDiffConfirmationDialog(
            context,
            title: 'مراجعة وتأكيد تعديلات ملف الاستيراد',
            itemReference: oldFile.customFileNumber ?? oldFile.importFileCode,
            changes: changes,
          );
          if (!confirmed) {
            setState(() => _isSaving = false);
            return;
          }
        }

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
    final currencies = ref.watch(currenciesProvider).value ?? [];
    final locations = ref.watch(transportLocationsProvider).asData?.value ?? [];
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
                      child: SearchableDropdownField<int?>(
                        value: _selectedCompanyId,
                        labelText: 'الشركة المستوردة المصرية *',
                        searchHintText: 'ابحث عن الشركة المستوردة...',
                        items: companies
                            .map((c) => SearchableDropdownItem<int?>(
                                  value: c.companyId,
                                  label: c.importerName,
                                  subtitle: c.vatId,
                                ))
                            .toList(),
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
                      child: SearchableDropdownField<int?>(
                        value: _selectedSupplierId,
                        labelText: 'المورد الأجنبي (Supplier) *',
                        searchHintText: 'ابحث عن المورد الأجنبي...',
                        items: suppliers
                            .map((s) => SearchableDropdownItem<int?>(
                                  value: s.supplierId,
                                  label: s.companyName,
                                  subtitle: s.foreignExporterCountry,
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final sup = suppliers.firstWhere((s) => s.supplierId == val);
                            setState(() {
                              _selectedSupplierId = val;
                              _supplierName = sup.companyName;
                              final fullAddr = [sup.address, sup.city, sup.country].where((s) => s.isNotEmpty).join(', ');
                              _pickupAddressController.text = fullAddr.isNotEmpty ? fullAddr : sup.address;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SearchableDropdownField<int?>(
                        value: _selectedBrokerId,
                        labelText: 'المخلص الجمركي (Customs Broker)',
                        searchHintText: 'ابحث عن المخلص الجمركي...',
                        items: [
                          const SearchableDropdownItem<int?>(value: null, label: '-- اختيار المخلص الجمركي --'),
                          ...partners
                              .where((p) => p.partnerType.toUpperCase().contains('BROKER') || p.partnerType.toUpperCase().contains('CUSTOMS'))
                              .map((b) => SearchableDropdownItem<int?>(
                                    value: b.providerId,
                                    label: b.partnerName,
                                    subtitle: b.partnerType,
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
                      child: SearchableDropdownField<String>(
                        value: ['Sea FCL', 'Sea LCL', 'Air', 'Land'].contains(_shipmentMode) ? _shipmentMode : 'Sea FCL',
                        labelText: 'وسيلة النقل (Shipment Mode) *',
                        items: const [
                          SearchableDropdownItem(value: 'Sea FCL', label: 'Sea FCL (شحن بحري حاوية كاملة)'),
                          SearchableDropdownItem(value: 'Sea LCL', label: 'Sea LCL (شحن بحري طرد/جزئي)'),
                          SearchableDropdownItem(value: 'Air', label: 'Air (شحن جوي)'),
                          SearchableDropdownItem(value: 'Land', label: 'Land (شحن بري)'),
                        ],
                        onChanged: (v) => setState(() => _shipmentMode = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: incoterms.any((i) => i.incotermCode == _incotermCode) ? _incotermCode : 'FOB',
                        labelText: 'شرط التجارة (Incoterm) *',
                        searchHintText: 'ابحث عن شرط التجارة...',
                        items: (incoterms.isNotEmpty ? incoterms.map((i) => i.incotermCode).toList() : ['FOB', 'CIF', 'CFR', 'EXW', 'FCA', 'CIP', 'DDP', 'DAP'])
                            .map((code) => SearchableDropdownItem<String>(value: code, label: code))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _incotermCode = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: _priority,
                        labelText: 'الأولوية (Priority) *',
                        searchHintText: 'ابحث عن مستوى الأولوية...',
                        items: const [
                          SearchableDropdownItem(value: 'Low', label: 'Low (منخفضة)'),
                          SearchableDropdownItem(value: 'Medium', label: 'Medium (متوسطة)'),
                          SearchableDropdownItem(value: 'High', label: 'High (عالية)'),
                          SearchableDropdownItem(value: 'Critical', label: 'Critical (حرجة)'),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
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
                        value: _shipmentCategory,
                        labelText: 'تصنيف الشحنة (Category) *',
                        searchHintText: 'ابحث عن التكليف / التصنيف...',
                        items: const [
                          SearchableDropdownItem(value: 'New Purchase', label: 'New Purchase (شراء جديد)'),
                          SearchableDropdownItem(value: 'Replacement', label: 'Replacement (استبدال)'),
                          SearchableDropdownItem(value: 'Repair', label: 'Repair (إصلاح)'),
                          SearchableDropdownItem(value: 'Sample', label: 'Sample (عينة)'),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _shipmentCategory = v);
                        },
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
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _fileOpeningDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setState(() => _fileOpeningDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'تاريخ فتح الملف (File Opening Date) *', border: OutlineInputBorder()),
                          child: Text(_fileOpeningDate.toString().substring(0, 10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Logistics & Freight RFQ Details Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: AppTheme.emerald, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '🚚 بيانات النقل وموانئ الشحن لطلب النولون (Logistics & Freight RFQ Details)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SearchableDropdownField<String>(
                              value: _polController.text.isNotEmpty ? _polController.text : null,
                              labelText: 'ميناء الشحن (Port of Loading - POL)',
                              searchHintText: 'ابحث في موانئ الشحن العالمية...',
                              items: [
                                if (_polController.text.isNotEmpty && !locations.any((l) => l.locationName == _polController.text))
                                  SearchableDropdownItem<String>(value: _polController.text, label: _polController.text),
                                ...locations.map((loc) => SearchableDropdownItem<String>(
                                      value: loc.locationName,
                                      label: '${loc.locationName} (${loc.country}${loc.unLocode.isNotEmpty ? " - ${loc.unLocode}" : ""})',
                                      subtitle: loc.locationType,
                                    )),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _polController.text = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SearchableDropdownField<String>(
                              value: _podController.text.isNotEmpty ? _podController.text : 'El Dekheila Port (non TMT)',
                              labelText: 'ميناء الوصول والتفريغ (Port of Discharge - POD)',
                              searchHintText: 'ابحث في موانئ الوصول المصرية...',
                              items: [
                                if (_podController.text.isNotEmpty && !locations.any((l) => l.locationName == _podController.text))
                                  SearchableDropdownItem<String>(value: _podController.text, label: _podController.text),
                                ...locations.map((loc) => SearchableDropdownItem<String>(
                                      value: loc.locationName,
                                      label: '${loc.locationName} (${loc.country}${loc.unLocode.isNotEmpty ? " - ${loc.unLocode}" : ""})',
                                      subtitle: loc.locationType,
                                    )),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _podController.text = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _cargoReadyDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) setState(() => _cargoReadyDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ جاهزية البضاعة (Cargo Ready Date)',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                child: Text(_cargoReadyDate.toString().substring(0, 10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: TextFormField(
                              controller: _targetFreeDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'أيام السماح المطلوبة (FT)',
                                suffixText: 'يوم',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SearchableDropdownField<String>(
                              value: _serviceTypePreference,
                              labelText: 'تفضيل مسار الخدمة (Service Preference)',
                              items: const [
                                SearchableDropdownItem(value: 'Direct', label: 'Direct Service (خدمة وخط مباشر فقط)'),
                                SearchableDropdownItem(value: 'Transshipment Acceptable', label: 'Transshipment Acceptable (يقبل الترانزيت)'),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _serviceTypePreference = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _pickupAddressController,
                              decoration: const InputDecoration(
                                labelText: 'عنوان الاستلام / المصنع (Pickup / Factory Address for EXW)',
                                hintText: 'عنوان المصنع لتحميل بضاعة الـ EXW...',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _shippingInstructionsNotesController,
                        decoration: const InputDecoration(
                          labelText: 'تعليمات واشتراطات الشحن الخاصة (Shipping Instructions & Exclusions)',
                          hintText: 'مثال: Must avoid TMT Terminal, Earliest vessel required...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
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
                      SearchableDropdownField<int?>(
                        value: null,
                        labelText: '+ إضافة إسناد إلى مشروع (اختر مشروعاً للإضافة إلى الشحنة)',
                        searchHintText: 'ابحث عن المشروع بالاسم أو الكود...',
                        items: [
                          const SearchableDropdownItem<int?>(value: null, label: '-- اختر مشروعاً جديداً لإسناده للشحنة --'),
                          ...projects.map((p) => SearchableDropdownItem<int?>(
                                value: p.projectId,
                                label: '${p.projectName} (${p.projectCode})',
                              )),
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
                    SizedBox(
                      width: 140,
                      child: SearchableDropdownField<String>(
                        value: currencies.any((c) => c.currencyCode == _estimatedCostCurrency)
                            ? _estimatedCostCurrency
                            : (_estimatedCostCurrency.isNotEmpty ? _estimatedCostCurrency : 'USD'),
                        labelText: 'عملة التكلفة *',
                        items: (currencies.isNotEmpty
                                ? currencies.map((c) => c.currencyCode).toList()
                                : ['USD', 'EUR', 'EGP', 'CNY', 'GBP', 'SAR', 'AED'])
                            .map((code) => SearchableDropdownItem<String>(value: code, label: code))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _estimatedCostCurrency = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _estimatedCostController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'التكلفة التقديرية ($_estimatedCostCurrency) *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل التكلفة التقديرية' : null,
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
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal, side: BorderSide(color: Colors.grey.shade400)),
          onPressed: () {
            ref.read(importFilesProvider.notifier).fetchImportFiles();
            ref.read(importCompaniesProvider.notifier).fetchCompanies();
            ref.read(suppliersProvider.notifier).fetchSuppliers();
            ref.read(partnersProvider.notifier).fetchPartners();
          },
          icon: const Icon(Icons.refresh, size: 16, color: AppTheme.cobalt),
          label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade800, side: BorderSide(color: Colors.grey.shade400)),
          onPressed: () {
            setState(() {
              _selectedCompanyId = null;
              _selectedSupplierId = null;
              _selectedBrokerId = null;
              _customFileIdController.clear();
              _poNoController.clear();
              _piNoController.clear();
              _notesController.clear();
            });
          },
          icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.blueGrey),
          label: const Text('تفريغ وبدء تسجيل جديد 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEFF6FF),
            foregroundColor: AppTheme.cobalt,
            elevation: 0,
            side: const BorderSide(color: AppTheme.cobalt),
          ),
          onPressed: _isSaving ? null : _submit,
          icon: const Icon(Icons.save_outlined, size: 16, color: AppTheme.cobalt),
          label: const Text('حفظ مؤقت ومتابعة لاحقة 💾', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
          label: Text(widget.fileToEdit != null ? 'تحديث وحفظ الملف 💾' : 'حفظ الشحنة بالكامل ✅', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
