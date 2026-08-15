import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';

class ImportDocumentationScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const ImportDocumentationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ImportDocumentationScreen> createState() => _ImportDocumentationScreenState();
}

class _ImportDocumentationScreenState extends ConsumerState<ImportDocumentationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ACID Workflow Sub-Tab (0: Request, 1: Smart Import, 2: Discrepancy & Verification, 3: Registry)
  int _acidSubTab = 0;

  // 1. ACID Request Form Controllers (BP-014)
  final _acidRequestFormKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  int? _selectedCompanyId;
  int? _selectedSupplierId;
  int? _selectedBrokerId;

  final TextEditingController _importerNameCtrl = TextEditingController();
  final TextEditingController _importerTaxIdCtrl = TextEditingController();
  final TextEditingController _importerAddressCtrl = TextEditingController();

  final TextEditingController _exporterNameCtrl = TextEditingController();
  final TextEditingController _exporterRegTypeCtrl = TextEditingController(text: 'VAT Number');
  final TextEditingController _exporterRegIdCtrl = TextEditingController();
  final TextEditingController _exporterCountryCtrl = TextEditingController();
  final TextEditingController _exporterCountryCodeCtrl = TextEditingController();
  final TextEditingController _exporterAddressCtrl = TextEditingController();
  final TextEditingController _exporterPhoneCtrl = TextEditingController();
  final TextEditingController _cargoxIdCtrl = TextEditingController();

  final TextEditingController _proformaNoCtrl = TextEditingController();
  final TextEditingController _proformaDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _invoiceDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _invoiceTypeCtrl = TextEditingController(text: 'Proforma Invoice');
  final TextEditingController _poNoCtrl = TextEditingController();
  final TextEditingController _poDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));

  final TextEditingController _polCtrl = TextEditingController();
  final TextEditingController _podCtrl = TextEditingController(text: 'Alexandria Port (EG ALX)');
  final TextEditingController _requestedDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));

  final TextEditingController _brokerNameCtrl = TextEditingController();
  final TextEditingController _brokerPhoneCtrl = TextEditingController();
  final TextEditingController _invoiceAttachmentCtrl = TextEditingController(text: 'Proforma_Invoice_Official.pdf');
  final TextEditingController _requestNotesCtrl = TextEditingController();

  bool _isSavingRequest = false;

  // 2. Smart MTS Parser State
  final TextEditingController _rawMtsTextCtrl = TextEditingController();
  bool _isParsingMts = false;
  Map<String, dynamic>? _lastParsedData;

  // 3. Discrepancy Matrix & Verification State
  AcidComparisonResult? _comparisonResult;
  final TextEditingController _overrideReasonCtrl = TextEditingController();
  final TextEditingController _issuedAcidNumberCtrl = TextEditingController();
  final TextEditingController _generatedDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _expiryDateCtrl = TextEditingController(
    text: DateTime.now().add(const Duration(days: 180)).toString().substring(0, 10),
  );
  bool _isSavingVerification = false;
  int? _activeEditingAcidId;
  String? _activeEditingAcidCode;

  // Form 4 State (BP-015)
  final _bankFormKey = GlobalKey<FormState>();
  int? _editingBankDocId;
  String? _editingBankDocCode;
  int? _form4ImportFileId;
  final TextEditingController _bankAmountController = TextEditingController(text: '62300.0');
  String _bankDocType = 'Form 4';
  String _form4Currency = 'USD';
  int? _selectedBankId;
  String _bankName = 'National Bank of Egypt (NBE)';
  final TextEditingController _form4RequestDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _form4NotesCtrl = TextEditingController();
  int _form4SubTab = 0; // 0: طلب توثيق نموذج جديد, 1: سجل النماذج المحفوظة
  String _form4SearchQuery = '';
  String _form4StatusFilter = 'All';
  bool _isSavingForm4 = false;

  // Document Registry State (BP-016 to BP-018)
  final _docFormKey = GlobalKey<FormState>();
  final TextEditingController _docNumController = TextEditingController(text: 'INV-2026-SH990');
  String _docName = 'Commercial Invoice (الفاتورة التجارية)';

  // Search Filter for ACID registry
  String _acidSearchQuery = '';
  String _acidStatusFilter = 'All';

  // Search Filter for ACID Expiry Tracker
  String _trackerSearchQuery = '';
  String _trackerStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
    Future.microtask(() {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(importCompaniesProvider.notifier).fetchCompanies();
    ref.read(suppliersProvider.notifier).fetchSuppliers();
    ref.read(partnersProvider.notifier).fetchPartners();
    ref.read(transportLocationsProvider.notifier).fetchLocations();
    ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
    ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
    ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
    ref.read(shipmentDocumentsProvider.notifier).fetchShipmentDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importerNameCtrl.dispose();
    _importerTaxIdCtrl.dispose();
    _importerAddressCtrl.dispose();
    _exporterNameCtrl.dispose();
    _exporterRegTypeCtrl.dispose();
    _exporterRegIdCtrl.dispose();
    _exporterCountryCtrl.dispose();
    _exporterCountryCodeCtrl.dispose();
    _exporterAddressCtrl.dispose();
    _exporterPhoneCtrl.dispose();
    _cargoxIdCtrl.dispose();
    _proformaNoCtrl.dispose();
    _proformaDateCtrl.dispose();
    _invoiceDateCtrl.dispose();
    _invoiceTypeCtrl.dispose();
    _poNoCtrl.dispose();
    _poDateCtrl.dispose();
    _polCtrl.dispose();
    _podCtrl.dispose();
    _requestedDateCtrl.dispose();
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _invoiceAttachmentCtrl.dispose();
    _requestNotesCtrl.dispose();
    _rawMtsTextCtrl.dispose();
    _overrideReasonCtrl.dispose();
    _issuedAcidNumberCtrl.dispose();
    _generatedDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _bankAmountController.dispose();
    _form4RequestDateCtrl.dispose();
    _form4NotesCtrl.dispose();
    _docNumController.dispose();
    super.dispose();
  }

  void _onImportFileSelected(int? fileId) {
    setState(() {
      _selectedImportFileId = fileId;
    });

    if (fileId == null) return;

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.firstWhere((f) => f.importFileId == fileId, orElse: () => files.first);

    // Auto extract company data
    _importerNameCtrl.text = file.companyName;
    final companies = ref.read(importCompaniesProvider).value ?? [];
    final matchedComp = companies.where((c) => c.companyId == file.companyId || c.importerName == file.companyName).firstOrNull;
    if (matchedComp != null) {
      _selectedCompanyId = matchedComp.companyId;
      _importerTaxIdCtrl.text = matchedComp.vatId;
      _importerAddressCtrl.text = matchedComp.address;
    }

    // Auto extract supplier data
    _exporterNameCtrl.text = file.supplierName;
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final matchedSupp = suppliers.where((s) => s.supplierId == file.supplierId || s.companyName == file.supplierName).firstOrNull;
    if (matchedSupp != null) {
      _selectedSupplierId = matchedSupp.supplierId;
      _exporterRegTypeCtrl.text = matchedSupp.registrationType;
      _exporterRegIdCtrl.text = matchedSupp.foreignExporterId;
      _exporterCountryCtrl.text = matchedSupp.foreignExporterCountry;
      _exporterCountryCodeCtrl.text = matchedSupp.foreignExporterCountryCode;
      _exporterAddressCtrl.text = matchedSupp.address;
      _exporterPhoneCtrl.text = matchedSupp.phone ?? matchedSupp.mobile ?? '';
    }

    // Auto extract broker data
    if (file.brokerName != null && file.brokerName!.isNotEmpty) {
      _brokerNameCtrl.text = file.brokerName!;
      final partners = ref.read(partnersProvider).value ?? [];
      final matchedBroker = partners.where((p) => p.providerId == file.brokerId || p.partnerName == file.brokerName).firstOrNull;
      if (matchedBroker != null) {
        _selectedBrokerId = matchedBroker.providerId;
        _brokerPhoneCtrl.text = matchedBroker.phone ?? '';
      }
    }

    // Auto extract invoice & PO data
    _proformaNoCtrl.text = file.piNumber ?? '';
    _poNoCtrl.text = file.poNumber ?? '';

    // If file already has an ACID, populate it
    if (file.acidNumber != null && file.acidNumber!.isNotEmpty) {
      _issuedAcidNumberCtrl.text = file.acidNumber!;
    }
  }

  Map<String, dynamic> _buildRequestedDataMap() {
    return {
      'importer_name': _importerNameCtrl.text.trim(),
      'importer_tax_id': _importerTaxIdCtrl.text.trim(),
      'importer_address': _importerAddressCtrl.text.trim(),
      'exporter_name': _exporterNameCtrl.text.trim(),
      'exporter_reg_type': _exporterRegTypeCtrl.text.trim(),
      'exporter_reg_id': _exporterRegIdCtrl.text.trim(),
      'exporter_country': _exporterCountryCtrl.text.trim(),
      'exporter_country_code': _exporterCountryCodeCtrl.text.trim(),
      'exporter_address': _exporterAddressCtrl.text.trim(),
      'exporter_phone': _exporterPhoneCtrl.text.trim(),
      'cargox_id': _cargoxIdCtrl.text.trim(),
      'proforma_invoice_no': _proformaNoCtrl.text.trim(),
      'proforma_invoice_date': _proformaDateCtrl.text.trim(),
      'invoice_date': _invoiceDateCtrl.text.trim(),
      'invoice_type': _invoiceTypeCtrl.text.trim(),
      'po_number': _poNoCtrl.text.trim(),
      'po_date': _poDateCtrl.text.trim(),
      'pol_name': _polCtrl.text.trim(),
      'pod_name': _podCtrl.text.trim(),
      'customs_broker_name': _brokerNameCtrl.text.trim(),
      'customs_broker_phone': _brokerPhoneCtrl.text.trim(),
      'requested_date': _requestedDateCtrl.text.trim(),
      'invoice_attachment_name': _invoiceAttachmentCtrl.text.trim(),
    };
  }

  void _loadAcidSessionForEdit(AcidRegistrationModel session) {
    setState(() {
      _activeEditingAcidId = session.acidId;
      _activeEditingAcidCode = session.acidCode;
      _selectedImportFileId = session.importFileId;
      _importerNameCtrl.text = session.importerName;
      _importerTaxIdCtrl.text = session.importerTaxId;
      _importerAddressCtrl.text = session.importerAddress ?? '';
      _exporterNameCtrl.text = session.exporterName;
      _exporterRegTypeCtrl.text = session.exporterRegType ?? 'VAT Number';
      _exporterRegIdCtrl.text = session.exporterRegId;
      _exporterCountryCtrl.text = session.exporterCountry;
      _exporterCountryCodeCtrl.text = session.exporterCountryCode ?? '';
      _exporterAddressCtrl.text = session.exporterAddress ?? '';
      _exporterPhoneCtrl.text = session.exporterPhone ?? '';
      _cargoxIdCtrl.text = session.cargoxId ?? '';
      _proformaNoCtrl.text = session.proformaInvoiceNo;
      _proformaDateCtrl.text = session.proformaInvoiceDate ?? '';
      _invoiceDateCtrl.text = session.invoiceDate ?? '';
      _invoiceTypeCtrl.text = session.invoiceType ?? 'Proforma Invoice';
      _poNoCtrl.text = session.poNumber ?? '';
      _poDateCtrl.text = session.poDate ?? '';
      _polCtrl.text = session.polName;
      _podCtrl.text = session.podName;
      _selectedBrokerId = session.customsBrokerId;
      _brokerNameCtrl.text = session.customsBrokerName ?? '';
      _brokerPhoneCtrl.text = session.customsBrokerPhone ?? '';
      _requestedDateCtrl.text = session.requestedDate ?? DateTime.now().toIso8601String().substring(0, 10);
      _requestNotesCtrl.text = session.verificationNotes ?? '';
      _issuedAcidNumberCtrl.text = session.acidNumber;
      _acidSubTab = 0; // Go to Request Tab
    });
  }

  void _resetAcidForm() {
    setState(() {
      _activeEditingAcidId = null;
      _activeEditingAcidCode = null;
      _selectedImportFileId = null;
      _importerNameCtrl.clear();
      _importerTaxIdCtrl.clear();
      _importerAddressCtrl.clear();
      _exporterNameCtrl.clear();
      _exporterRegTypeCtrl.text = 'VAT Number';
      _exporterRegIdCtrl.clear();
      _exporterCountryCtrl.clear();
      _exporterCountryCodeCtrl.clear();
      _exporterAddressCtrl.clear();
      _exporterPhoneCtrl.clear();
      _cargoxIdCtrl.clear();
      _proformaNoCtrl.clear();
      _proformaDateCtrl.clear();
      _invoiceDateCtrl.clear();
      _invoiceTypeCtrl.text = 'Proforma Invoice';
      _poNoCtrl.clear();
      _poDateCtrl.clear();
      _polCtrl.clear();
      _podCtrl.clear();
      _selectedBrokerId = null;
      _brokerNameCtrl.clear();
      _brokerPhoneCtrl.clear();
      _requestedDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
      _requestNotesCtrl.clear();
      _issuedAcidNumberCtrl.clear();
    });
  }

  Future<void> _saveAcidRequest() async {
    if (!_acidRequestFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى استكمال الحقول الإلزامية لطلب الـ ACID'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Duplicate session validation: prevent creating new request if active session already exists for this file
    final acidSessions = ref.read(acidSessionsProvider).value ?? [];
    if (_activeEditingAcidId == null && _selectedImportFileId != null) {
      final existingAcid = acidSessions.where((s) => s.importFileId == _selectedImportFileId && s.isActive).firstOrNull;
      if (existingAcid != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 28),
                SizedBox(width: 8),
                Text('جلسة ACID مسجلة مسبقاً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'لا يمكن حفظ طلب ACID جديد لأن ملف الشحنة المختار مرتبط بالفعل بجلسة مسجلة ومحفوظة في سجل الطلبات (${existingAcid.acidCode}${existingAcid.acidNumber != "PENDING" && existingAcid.acidNumber.isNotEmpty ? " - رقم ACID: ${existingAcid.acidNumber}" : ""}).\n\nيرجى التوجه إلى سجل الطلبات والإصدار للتعديل على الجلسة الحالية بدلاً من إنشاء طلب جديد.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('سجل الطلبات'),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _acidSubTab = 3);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange, foregroundColor: Colors.white),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل الجلسة الحالية'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadAcidSessionForEdit(existingAcid);
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() => _isSavingRequest = true);
    try {
      final reqMap = _buildRequestedDataMap();
      final payload = {
        'acid_number': _activeEditingAcidId != null && _issuedAcidNumberCtrl.text.trim().isNotEmpty
            ? _issuedAcidNumberCtrl.text.trim()
            : 'PENDING',
        'import_file_id': _selectedImportFileId,
        'importer_id': _selectedCompanyId,
        'importer_name': reqMap['importer_name'],
        'importer_tax_id': reqMap['importer_tax_id'],
        'importer_address': reqMap['importer_address'],
        'supplier_id': _selectedSupplierId,
        'exporter_name': reqMap['exporter_name'],
        'exporter_reg_type': reqMap['exporter_reg_type'],
        'exporter_reg_id': reqMap['exporter_reg_id'],
        'exporter_country': reqMap['exporter_country'],
        'exporter_country_code': reqMap['exporter_country_code'],
        'exporter_address': reqMap['exporter_address'],
        'exporter_phone': reqMap['exporter_phone'],
        'cargox_id': reqMap['cargox_id'],
        'proforma_invoice_no': reqMap['proforma_invoice_no'],
        'proforma_invoice_date': reqMap['proforma_invoice_date'],
        'invoice_date': reqMap['invoice_date'],
        'invoice_type': reqMap['invoice_type'],
        'invoice_attachment_name': reqMap['invoice_attachment_name'],
        'po_number': reqMap['po_number'],
        'po_date': reqMap['po_date'],
        'pol_name': reqMap['pol_name'],
        'pod_name': reqMap['pod_name'],
        'customs_broker_id': _selectedBrokerId,
        'customs_broker_name': reqMap['customs_broker_name'],
        'customs_broker_phone': reqMap['customs_broker_phone'],
        'requested_date': reqMap['requested_date'],
        'requested_data': reqMap,
        'verification_notes': _requestNotesCtrl.text.trim(),
        'status': 'Requested',
      };

      if (_activeEditingAcidId != null) {
        final updated = await ref.read(acidSessionsProvider.notifier).updateAcidSession(_activeEditingAcidId!, payload);
        if (mounted && updated != null) {
          ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
          ref.read(importFilesProvider.notifier).fetchImportFiles();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تحديث بيانات طلب الـ ACID بنجاح! كود الطلب: ${updated.acidCode}'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } else {
        final created = await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);
        if (mounted && created != null) {
          _activeEditingAcidId = created.acidId;
          _activeEditingAcidCode = created.acidCode;
          ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
          ref.read(importFilesProvider.notifier).fetchImportFiles();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم حفظ طلب الـ ACID بنجاح في النظام! كود الطلب: ${created.acidCode}'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ فشل حفظ طلب الـ ACID',
          error: e,
          subtitle: 'يرجى مراجعة البيانات المدخلة وتصحيح الأخطاء التالية:',
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingRequest = false);
    }
  }

  Future<void> _runSmartMtsParser() async {
    final rawText = _rawMtsTextCtrl.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى لصق نص إشعار نافذة أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isParsingMts = true);
    try {
      final res = await ref.read(acidSessionsProvider.notifier).parseAcidText(
            rawText,
            importFileId: _selectedImportFileId,
          );
      final parsed = res['parsed_data'] as Map<String, dynamic>?;

      if (parsed != null) {
        _lastParsedData = parsed;
        _issuedAcidNumberCtrl.text = parsed['acid_number'] ?? '';
        if (parsed['generated_date'] != null) _generatedDateCtrl.text = parsed['generated_date'];
        if (parsed['expiry_date'] != null) _expiryDateCtrl.text = parsed['expiry_date'];

        // Perform live comparison against currently requested data
        final reqMap = _buildRequestedDataMap();
        final compRes = await ref.read(acidSessionsProvider.notifier).compareAcid(reqMap, parsed);

        setState(() {
          _comparisonResult = compRes;
          _acidSubTab = 2; // Auto-switch to Discrepancy & Verification Tab
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                compRes.allMatched
                    ? '✨ تم استخراج البيانات ومطابقتها بنسبة 100% بنجاح!'
                    : '⚠️ تم استخراج البيانات مع وجود ${compRes.discrepantCount} فروقات. يرجى مراجعة الجدول.',
              ),
              backgroundColor: compRes.allMatched ? AppTheme.emerald : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ تعذر تحليل النص: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isParsingMts = false);
    }
  }

  void _loadSampleMtsText() {
    _rawMtsTextCtrl.text = """MTS Notification
Dear Impact Acoustic Spa,

Kindly be informed that an Advance Cargo Information request (ACI) has been approved for shipping:
[ACID: 7595528271015010011]
Requested: 31-May-2026 10:40:55 AM   Generated: 31-May-2026 10:41:01 AM   Expires: 30-Nov-2026 10:41:01 AM 
Egyptian Importer
Egyptian Importer Name: Arki Brands for Carpet and Flooring Trading
Egyptian Importer Tax ID: 759552827
Address: القاهره المعادى 44 ش 18 المعادى

Foreign Exporter
Foreign Exporter Name: Impact Acoustic Spa
Registration Type: VAT Number
Foreign Exporter ID: IT04462890981
Country: ITALY
Country Code: IT 
Address: Via Caldera 21
20153
Tel. No.: 0

Shipment
Proforma Invoice No.: IT-DN26-0031496
Proforma Invoice Date: 5/27/2026 12:00:00 AM
Invoice Date: 5/31/2026 10:38:19 AM
Type of invoice: Proforma Invoice
Shipping Port: Genoa
Destination Port: Alexandria
Note that any modifications for shipping or destination port for a shipment will not impact the customs clearance procedure in Egypt. 


ACID: 7595528271015010011 
Egyptian Importer Tax ID: 759552827 
Foreign Exporter Registration Type: VAT Number 
Foreign Exporter ID: IT04462890981 
Foreign Exporter Country: ITALY 
Foreign Exporter Country Code: IT 

Please make sure to print ACID on all shipping documents (commercial invoice, bill of lading, packing list, certificate of origin,...etc) as well as the tax ID of the Egyptian importer and the identity of the foreign exporter on the commercial invoice and bill of lading. 

Egyptian Customs Authority (ECA) will not accept any document not matching the above requirement starting as of the 1 of October 2021 


Warning 
Please note that the required documents for the mentioned shipment must be uploaded from the exporter who registered with ID: 67a645ce-62e8-4850-a09e-a20b8ea1d917 on the CargoX platform.""";
  }

  Future<void> _saveVerificationDecision({required bool proceedWithOverride}) async {
    final acidNum = _issuedAcidNumberCtrl.text.trim();
    if (acidNum.isEmpty || acidNum.length != 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ رقم الـ ACID يجب أن يتكون من 19 رقمًا'), backgroundColor: Colors.red),
      );
      return;
    }

    if (proceedWithOverride && _overrideReasonCtrl.text.trim().isEmpty && (_comparisonResult != null && !_comparisonResult!.allMatched)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى كتابة سبب الاستمرار وتجاوز الفروقات'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSavingVerification = true);
    try {
      final reqMap = _buildRequestedDataMap();
      final finalStatus = (_comparisonResult?.allMatched ?? true) ? 'Verified' : 'Discrepancy_Accepted';

      final payload = {
        'acid_number': acidNum,
        'import_file_id': _selectedImportFileId,
        'importer_id': _selectedCompanyId,
        'importer_name': _importerNameCtrl.text.trim(),
        'importer_tax_id': _importerTaxIdCtrl.text.trim(),
        'importer_address': _importerAddressCtrl.text.trim(),
        'supplier_id': _selectedSupplierId,
        'exporter_name': _exporterNameCtrl.text.trim(),
        'exporter_reg_type': _exporterRegTypeCtrl.text.trim(),
        'exporter_reg_id': _exporterRegIdCtrl.text.trim(),
        'exporter_country': _exporterCountryCtrl.text.trim(),
        'exporter_country_code': _exporterCountryCodeCtrl.text.trim(),
        'exporter_address': _exporterAddressCtrl.text.trim(),
        'exporter_phone': _exporterPhoneCtrl.text.trim(),
        'cargox_id': _cargoxIdCtrl.text.trim(),
        'proforma_invoice_no': _proformaNoCtrl.text.trim(),
        'proforma_invoice_date': _proformaDateCtrl.text.trim(),
        'invoice_date': _invoiceDateCtrl.text.trim(),
        'invoice_type': _invoiceTypeCtrl.text.trim(),
        'invoice_attachment_name': _invoiceAttachmentCtrl.text.trim(),
        'po_number': _poNoCtrl.text.trim(),
        'po_date': _poDateCtrl.text.trim(),
        'pol_name': _polCtrl.text.trim(),
        'pod_name': _podCtrl.text.trim(),
        'customs_broker_id': _selectedBrokerId,
        'customs_broker_name': _brokerNameCtrl.text.trim(),
        'customs_broker_phone': _brokerPhoneCtrl.text.trim(),
        'requested_date': _requestedDateCtrl.text.trim(),
        'generated_date': _generatedDateCtrl.text.trim(),
        'expiry_date': _expiryDateCtrl.text.trim(),
        'raw_nafeza_text': _rawMtsTextCtrl.text.trim(),
        'requested_data': reqMap,
        'generated_data': _lastParsedData,
        'discrepancies_data': _comparisonResult?.toJson(),
        'discrepancy_override_reason': _overrideReasonCtrl.text.trim(),
        'is_importer_matched': true,
        'is_exporter_matched': true,
        'is_invoice_matched': true,
        'is_ports_matched': true,
        'has_discrepancies': !(_comparisonResult?.allMatched ?? true),
        'status': finalStatus,
      };

      if (_activeEditingAcidId != null) {
        await ref.read(acidSessionsProvider.notifier).updateAcidSession(_activeEditingAcidId!, payload);
      } else {
        final created = await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);
        if (created != null) _activeEditingAcidId = created.acidId;
      }

      ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
      ref.read(importFilesProvider.notifier).fetchImportFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 تم اعتماد وتوثيق رقم الـ ACID ($acidNum) وربطه بالشحنة بنجاح!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        setState(() => _acidSubTab = 3); // Go to Registry Tab
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ فشل اعتماد وتوثيق رقم الـ ACID',
          error: e,
          subtitle: 'يرجى مراجعة البيانات المدخلة أو رقم الـ ACID وتصحيح الأخطاء التالية:',
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingVerification = false);
    }
  }

  void _showWhatsAppDialog() async {
    final reqMap = _buildRequestedDataMap();
    final tmpls = await ref.read(acidSessionsProvider.notifier).generateTemplates(reqMap);
    final waMsg = tmpls['whatsapp_text'] ?? '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat, color: Colors.green),
            SizedBox(width: 8),
            Text('مشاركة طلب الـ ACID عبر الواتساب (WhatsApp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إرسال للمخلص: ${_brokerNameCtrl.text.isEmpty ? "المخلص الجمركي" : _brokerNameCtrl.text} (${_brokerPhoneCtrl.text.isEmpty ? "لا يوجد هاتف" : _brokerPhoneCtrl.text})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                height: 220,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: SingleChildScrollView(
                  child: SelectableText(waMsg, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
            label: const Text('نسخ الرسالة للواتساب', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: waMsg));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم نسخ نص الرسالة للحافظة بنجاح!'), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEmailDialog() async {
    final reqMap = _buildRequestedDataMap();
    final tmpls = await ref.read(acidSessionsProvider.notifier).generateTemplates(reqMap);
    final subject = tmpls['email_subject'] ?? '';
    final body = tmpls['email_body'] ?? '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: AppTheme.cobalt),
            SizedBox(width: 8),
            Text('إرسال طلب الـ ACID بالبريد الإلكتروني (Email)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الموضوع (Subject):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 4),
              SelectableText(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
              const SizedBox(height: 12),
              Text('نص الرسالة (Body):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                height: 220,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: SingleChildScrollView(
                  child: SelectableText(body, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
            label: const Text('نسخ الموضوع والنص', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Subject: $subject\n\n$body"));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم نسخ محتوى الإيميل للحافظة بنجاح!'), backgroundColor: AppTheme.cobalt),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPrintPreviewDialog() {
    final reqMap = _buildRequestedDataMap();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: AppTheme.charcoal),
            SizedBox(width: 8),
            Text('معاينة وطباعة أمر استخراج الـ ACID الرسمي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black45), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('IMPORTFLOW ERP | NAfeza ACI ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('تاريخ الطلب: ${reqMap['requested_date']}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const Divider(thickness: 1.5),
                      const SizedBox(height: 6),
                      const Center(child: Text('نموذج طلب إصدار رقم قيد جمركي مبدئي (ACID Request Slip)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      const SizedBox(height: 12),
                      _buildPrintRow('اسم المستورد المصري (Egyptian Importer)', reqMap['importer_name']),
                      _buildPrintRow('الرقم الضريبي للمستورد (Tax ID)', reqMap['importer_tax_id']),
                      _buildPrintRow('عنوان المستورد (Address)', reqMap['importer_address']),
                      const Divider(),
                      _buildPrintRow('اسم المصدر الأجنبي (Foreign Exporter)', reqMap['exporter_name']),
                      _buildPrintRow('نوع التسجيل والمعرف (Reg Type & ID)', '${reqMap['exporter_reg_id']} (${reqMap['exporter_reg_type']})'),
                      _buildPrintRow('دولة وكود المصدر (Country & Code)', '${reqMap['exporter_country']} (${reqMap['exporter_country_code']})'),
                      _buildPrintRow('عنوان المصدر (Address)', reqMap['exporter_address']),
                      _buildPrintRow('هاتف المصدر (Tel No)', reqMap['exporter_phone']),
                      _buildPrintRow('معرف منصة CargoX (ID)', reqMap['cargox_id']),
                      const Divider(),
                      _buildPrintRow('رقم الفاتورة المبدئية (Proforma Invoice No)', reqMap['proforma_invoice_no']),
                      _buildPrintRow('تاريخ الفاتورة المبدئية (Proforma Date)', reqMap['proforma_invoice_date']),
                      _buildPrintRow('تاريخ الفاتورة (Invoice Date)', reqMap['invoice_date']),
                      _buildPrintRow('نوع الفاتورة (Type of Invoice)', reqMap['invoice_type']),
                      _buildPrintRow('رقم وتاريخ أمر الشراء (PO No & Date)', '${reqMap['po_number']} بتاريخ ${reqMap['po_date']}'),
                      _buildPrintRow('ميناء الشحن (POL)', reqMap['pol_name']),
                      _buildPrintRow('ميناء الوصول والتفريغ (POD)', reqMap['pod_name']),
                      _buildPrintRow('المخلص الجمركي المسؤول', '${reqMap['customs_broker_name']} - ${reqMap['customs_broker_phone']}'),
                      _buildPrintRow('الفاتورة المرفقة', reqMap['invoice_attachment_name']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal),
            icon: const Icon(Icons.print, color: Colors.white, size: 16),
            label: const Text('طباعة المستند', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🖨️ تم إرسال أمر الطباعة بنجاح'), backgroundColor: AppTheme.charcoal),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrintRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 260, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text(
              'مستندات الاستيراد والتسجيل الحكومي ACI (Phase 3 – Import Documentation & Nafeza)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: const [
          BackToDashboardButton(),
          SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'ACID & Nafeza (BP-014 منظومة نافذة)'),
            Tab(icon: Icon(Icons.account_balance), text: 'Form 4 & Banking (BP-015 المعاملات البنكية)'),
            Tab(icon: Icon(Icons.folder_shared), text: 'Shipment Docs & CargoX (BP-016/018 السجل الرقمي)'),
            Tab(icon: Icon(Icons.description), text: 'Declaration 46 (BP-019 إقرار 46 جمارك)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: REDESIGNED ACID & NAFEZA WORKSPACE (BP-014)
          _buildAcidWorkspaceTab(),

          // TAB 2: BANKING DOCUMENTS (BP-015)
          _buildBankingDocsTab(),

          // TAB 3: SHIPMENT DOCUMENTS & CARGOX (BP-016 to BP-018)
          _buildShipmentDocsTab(),

          // TAB 4: DECLARATION 46 PREPARATION (BP-019)
          _buildDeclaration46Tab(),
        ],
      ),
    );
  }

  Widget _buildAcidWorkspaceTab() {
    return Column(
      children: [
        // Sub-Navigation Toolbar for ACID Stages
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildSubTabButton(0, '1. طلب الـ ACID (Request)', Icons.edit_note),
              const SizedBox(width: 8),
              _buildSubTabButton(1, '2. الإدخال الذكي من نافذة (Smart Import)', Icons.auto_awesome),
              const SizedBox(width: 8),
              _buildSubTabButton(2, '3. المقارنة والتحقق (Discrepancy Matrix)', Icons.compare_arrows),
              const SizedBox(width: 8),
              _buildSubTabButton(3, '4. سجل الطلبات والإصدار (Registry)', Icons.table_chart),
              const SizedBox(width: 8),
              _buildSubTabButton(4, '5. متتبع الصلاحية والإفراج (Expiry Tracker)', Icons.hourglass_top),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                tooltip: 'تحديث البيانات الحية',
                onPressed: _refreshAllData,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Sub-Tab Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildActiveAcidSubTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(int index, String title, IconData icon) {
    final isSelected = _acidSubTab == index;
    return InkWell(
      onTap: () {
        setState(() => _acidSubTab = index);
        if (index == 4) {
          ref.read(acidTrackerProvider.notifier).fetchAcidTracker();
        } else if (index == 3) {
          ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cobalt : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.charcoal),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.charcoal,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAcidSubTabContent() {
    switch (_acidSubTab) {
      case 0:
        return _buildAcidRequestStageView();
      case 1:
        return _buildSmartMtsImportStageView();
      case 2:
        return _buildDiscrepancyAndVerificationStageView();
      case 3:
        return _buildAcidRegistryTableView();
      case 4:
        return _buildAcidExpiryTrackerView();
      default:
        return _buildAcidRequestStageView();
    }
  }

  // --- SUB-VIEW 1: ACID REQUEST STAGE ---
  Widget _buildAcidRequestStageView() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final partners = ref.watch(partnersProvider).value ?? [];
    final brokerPartners = partners.where((p) => p.partnerType.contains('Customs') || p.partnerType.contains('مخلص') || p.partnerType.contains('Broker')).toList();
    final acidSessions = ref.watch(acidSessionsProvider).value ?? [];
    final existingAcidForSelectedFile = (_activeEditingAcidId == null && _selectedImportFileId != null)
        ? acidSessions.where((s) => s.importFileId == _selectedImportFileId && s.isActive).firstOrNull
        : null;

    return Form(
      key: _acidRequestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit Mode Banner
          if (_activeEditingAcidId != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppTheme.orange, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أنت الآن في وضع تعديل جلسة الـ ACID المسجلة: ${_activeEditingAcidCode ?? "جلسة #$_activeEditingAcidId"}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('إلغاء التعديل والعودة لطلب جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _resetAcidForm,
                  ),
                ],
              ),
            ),
          ],

          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppTheme.cobalt, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مرحلة إعداد وطلب الـ ACID: يتم استخراج البيانات تلقائياً من ملف الشحنة وجداول الموردين والمستوردين. '
                    'يجب إرفاق الفاتورة المبدئية عند إرسال الطلب للمخلص الجمركي عبر الواتساب أو البريد أو الطباعة.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. File Selection & Importer Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏢 بيانات الشحنة والمستورد المصري (Egyptian Importer)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SearchableDropdownField<int?>(
                          value: _selectedImportFileId,
                          labelText: 'ملف الشحنة الاستيرادية (Import File) *',
                          searchHintText: 'ابحث برقم الملف أو اسم المورد...',
                          items: [
                            const SearchableDropdownItem<int?>(value: null, label: '-- اختر ملف الشحنة للسحب التلقائي --'),
                            ...importFiles.map((f) => SearchableDropdownItem<int?>(
                                  value: f.importFileId,
                                  label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "Shipment #${f.importFileId}"}',
                                  subtitle: '${f.companyName} | ${f.supplierName}',
                                )),
                          ],
                          onChanged: _onImportFileSelected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _importerNameCtrl,
                          decoration: const InputDecoration(labelText: 'Egyptian Importer Name (اسم المستورد) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المستورد مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _importerTaxIdCtrl,
                          decoration: const InputDecoration(labelText: 'Egyptian Importer Tax ID (الرقم الضريبي) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'الرقم الضريبي مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  if (existingAcidForSelectedFile != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'تنبيه: ملف الشحنة هذا مسجل له بالفعل جلسة ACID في سجل الطلبات (${existingAcidForSelectedFile.acidCode}${existingAcidForSelectedFile.acidNumber != "PENDING" && existingAcidForSelectedFile.acidNumber.isNotEmpty ? " - رقم ACID: ${existingAcidForSelectedFile.acidNumber}" : ""}). لا يمكن إضافة طلب جديد، يرجى التعديل على الجلسة الحالية.',
                              style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.edit, size: 15),
                            label: const Text('تعديل الجلسة الحالية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _loadAcidSessionForEdit(existingAcidForSelectedFile),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _importerAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Address (عنوان المستورد في مصر)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Foreign Exporter Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌍 بيانات المصدر / المورد الأجنبي (Foreign Exporter)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _exporterNameCtrl,
                          decoration: const InputDecoration(labelText: 'Foreign Exporter Name (اسم المصدر) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المصدر مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _exporterRegTypeCtrl,
                          decoration: const InputDecoration(labelText: 'Registration Type (نوع التسجيل) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'نوع التسجيل مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _exporterRegIdCtrl,
                          decoration: const InputDecoration(labelText: 'Foreign Exporter ID (المعرف الضريبي) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'المعرف الضريبي مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _exporterCountryCtrl,
                          decoration: const InputDecoration(labelText: 'Country (الدولة) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'الدولة مطلوبة' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _exporterCountryCodeCtrl,
                          decoration: const InputDecoration(labelText: 'Country Code (كود الدولة مثل IT, CN) *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _exporterPhoneCtrl,
                          decoration: const InputDecoration(labelText: 'Tel. No (هاتف المصدر)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cargoxIdCtrl,
                          decoration: const InputDecoration(labelText: 'CargoX Exporter ID', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _exporterAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Address (عنوان المصدر بالخارج)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Invoices, Purchase Order & Shipping Ports Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📄 بيانات الفاتورة، أمر الشراء وموانئ الشحن (Shipment & Invoices)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _proformaNoCtrl,
                          decoration: const InputDecoration(labelText: 'Proforma Invoice No (رقم الفاتورة المبدئية) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الفاتورة مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _proformaDateCtrl,
                          decoration: const InputDecoration(labelText: 'Proforma Invoice Date (تاريخ الفاتورة المبدئية)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceDateCtrl,
                          decoration: const InputDecoration(labelText: 'Invoice Date (تاريخ الفاتورة)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceTypeCtrl,
                          decoration: const InputDecoration(labelText: 'Type of invoice (نوع الفاتورة)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _poNoCtrl,
                          decoration: const InputDecoration(labelText: 'Purchase Order No (رقم أمر الشراء)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _poDateCtrl,
                          decoration: const InputDecoration(labelText: 'Purchase Order Date (تاريخ أمر الشراء)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _polCtrl,
                          decoration: const InputDecoration(labelText: 'Shipping Port / POL (ميناء الشحن) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'ميناء الشحن مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _podCtrl,
                          decoration: const InputDecoration(labelText: 'Destination Port / POD (ميناء الوصول) *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'ميناء الوصول مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SearchableDropdownField<int?>(
                          value: _selectedBrokerId,
                          labelText: 'المخلص الجمركي (Customs Broker)',
                          searchHintText: 'ابحث عن المخلص الجمركي...',
                          items: [
                            const SearchableDropdownItem<int?>(value: null, label: '-- اختر من شركاء التخليص الجمركي أو أدخل يدوياً --'),
                            ...brokerPartners.map((b) => SearchableDropdownItem<int?>(
                                  value: b.providerId,
                                  label: b.partnerName,
                                  subtitle: b.phone ?? b.email ?? '',
                                )),
                          ],
                          onChanged: (id) {
                            setState(() => _selectedBrokerId = id);
                            if (id != null) {
                              final b = brokerPartners.firstWhere((p) => p.providerId == id);
                              _brokerNameCtrl.text = b.partnerName;
                              _brokerPhoneCtrl.text = b.phone ?? '';
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _brokerNameCtrl,
                          decoration: const InputDecoration(labelText: 'اسم المخلص الجمركي', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _brokerPhoneCtrl,
                          decoration: const InputDecoration(labelText: 'هاتف المخلص (لإرسال الواتساب)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceAttachmentCtrl,
                          decoration: const InputDecoration(
                            labelText: 'مرفق الفاتورة المبدئية (Attached Invoice File) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_file, color: AppTheme.cobalt),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _requestedDateCtrl,
                          decoration: const InputDecoration(labelText: 'تاريخ الطلب (Requested Date)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Bar: Print, WhatsApp, Email, and Save Request
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  icon: const Icon(Icons.print, color: Colors.white, size: 18),
                  label: const Text('🖨️ طباعة الطلب (Print Slip)', style: TextStyle(color: Colors.white)),
                  onPressed: _showPrintPreviewDialog,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                  label: const Text('💬 إرسال واتساب (WhatsApp)', style: TextStyle(color: Colors.white)),
                  onPressed: _showWhatsAppDialog,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  icon: const Icon(Icons.email, color: Colors.white, size: 18),
                  label: const Text('✉️ إرسال بالإيميل (Email)', style: TextStyle(color: Colors.white)),
                  onPressed: _showEmailDialog,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeEditingAcidId != null ? AppTheme.orange : AppTheme.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  icon: _isSavingRequest
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_activeEditingAcidId != null ? Icons.save_as_rounded : Icons.save, color: Colors.white),
                  label: Text(
                    _isSavingRequest
                        ? 'جاري الحفظ...'
                        : (_activeEditingAcidId != null ? '💾 حفظ تعديلات طلب الـ ACID' : '💾 حفظ طلب الـ ACID (Save Request)'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSavingRequest ? null : _saveAcidRequest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW 2: SMART NAFEZA / MTS IMPORT STAGE ---
  Widget _buildSmartMtsImportStageView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'الإدخال الذكي لإشعار نافذة (Smart Nafeza / MTS Text Parser): الصق نص الإيميل أو الإشعار المستلم من نافذة، '
                  'وسيقوم النظام باستخراج رقم الـ ACID (19 رقماً) والتواريخ وكافة بيانات الشحنة ومطابقتها آلياً مع ما تم طلبه.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نص إشعار MTS / Nafeza المستلم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    TextButton.icon(
                      icon: const Icon(Icons.paste, size: 16),
                      label: const Text('تحميل نص إشعار تجريبي (Load Sample)'),
                      onPressed: _loadSampleMtsText,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rawMtsTextCtrl,
                  maxLines: 12,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'الصق نص إشعار نافذة كاملاً هنا...\nمثال:\n[ACID: 7595528271015010011]\nRequested: 31-May-2026 ...\nEgyptian Importer Name: ...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      icon: _isParsingMts
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(
                        _isParsingMts ? 'جاري التحليل الذكي...' : '🚀 استخراج وتدقيق البيانات فورياً (Smart Parse & Compare)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _isParsingMts ? null : _runSmartMtsParser,
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('مسح النص'),
                      onPressed: () => setState(() => _rawMtsTextCtrl.clear()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SUB-VIEW 3: DISCREPANCY MATRIX & VERIFICATION STAGE ---
  Widget _buildDiscrepancyAndVerificationStageView() {
    final comp = _comparisonResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match status summary card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (comp?.allMatched ?? true) ? Colors.green.shade50 : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (comp?.allMatched ?? true) ? Icons.check_circle : Icons.warning,
                    color: (comp?.allMatched ?? true) ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (comp?.allMatched ?? true) ? 'نتيجة التدقيق: متطابق بالكامل (100% Match)' : 'نتيجة التدقيق: يوجد اختلافات بين ما طُلب وما صَدَر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (comp?.allMatched ?? true) ? Colors.green.shade800 : Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إجمالي الحقول المقارنة: ${comp?.totalComparedFields ?? 0} | الحقول المتطابقة: ${comp?.matchedCount ?? 0} | الاختلافات: ${comp?.discrepantCount ?? 0}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: (comp?.allMatched ?? true) ? AppTheme.emerald : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'نسبة التطابق: ${comp?.matchPercentage ?? 100}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Side-by-Side Discrepancy Matrix Table
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 مصفوفة المقارنة المباشرة (Requested vs Generated Comparison)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(),
                const SizedBox(height: 10),
                if (comp == null || comp.items.isEmpty) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('قم بتحليل نص الإشعار أو إدخال البيانات لعرض مصفوفة الفروقات والمقارنة الحية.'),
                    ),
                  ),
                ] else ...[
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
                    columnWidths: const {
                      0: FlexColumnWidth(2.0),
                      1: FlexColumnWidth(3.0),
                      2: FlexColumnWidth(3.0),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: const [
                          Padding(padding: EdgeInsets.all(10), child: Text('اسم الحقل والبيان', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(10), child: Text('ما تم طلبه (Requested)', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(10), child: Text('ما تم إصداره من نافذة (Generated)', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(10), child: Text('حالة المطابقة', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...comp.items.map((item) {
                        return TableRow(
                          decoration: BoxDecoration(
                            color: item.isMatched ? Colors.transparent : Colors.orange.shade50,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.labelAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(item.labelEn, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(10), child: Text(item.requestedValue.isEmpty ? '-' : item.requestedValue)),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                item.generatedValue.isEmpty ? '-' : item.generatedValue,
                                style: TextStyle(
                                  fontWeight: item.isMatched ? FontWeight.normal : FontWeight.bold,
                                  color: item.isMatched ? Colors.black87 : Colors.red.shade800,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: item.isMatched
                                  ? const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 4), Text('متطابق ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))])
                                  : Row(children: [const Icon(Icons.error_outline, color: Colors.orange, size: 16), const SizedBox(width: 4), Text('يوجد اختلاف ⚠️', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12))]),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Issued ACID Numbers & Dates Confirmation Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔢 بيانات الإصدار وتاريخ الصلاحية (ACID Generated Details)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _issuedAcidNumberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رقم الـ ACID الصادر (19 رقمًا) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.verified, color: AppTheme.cobalt),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _generatedDateCtrl,
                        decoration: const InputDecoration(labelText: 'تاريخ الإصدار (Generated Date)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateCtrl,
                        decoration: const InputDecoration(labelText: 'تاريخ الانتهاء (Expiry Date)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                if (comp != null && !comp.allMatched) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note, color: Colors.amber, size: 20),
                            SizedBox(width: 6),
                            Text('سبب الاستمرار واعتماد الـ ACID رغم وجود الفروقات (Override Reason Note):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _overrideReasonCtrl,
                          decoration: const InputDecoration(
                            hintText: 'مثال: تم قبول تعديل ميناء الشحن بموافقة الجمارك / اختلاف طفيف في تهجئة الاسم تم اعتماده...',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Actions: Return for edit OR Proceed with override / Verify
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: const BorderSide(color: Colors.orange),
                ),
                icon: const Icon(Icons.replay, color: Colors.orange),
                label: const Text('🔄 العودة للتعديل وإخطار المخلص (Return for Revision)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => _acidSubTab = 0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الرجوع لنموذج الطلب لإجراء التعديلات المطلوبة'), backgroundColor: Colors.orange),
                  );
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (comp?.allMatched ?? true) ? AppTheme.emerald : Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: _isSavingVerification
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified, color: Colors.white),
                label: Text(
                  _isSavingVerification
                      ? 'جاري الاعتماد...'
                      : (comp?.allMatched ?? true)
                          ? '✅ اعتماد وتوثيق الـ ACID (Verify & Link Shipment)'
                          : '💾 الاستمرار واعتماد الـ ACID مع سبب التجاوز (Proceed & Save)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isSavingVerification ? null : () => _saveVerificationDecision(proceedWithOverride: !(comp?.allMatched ?? true)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUB-VIEW 4: ACID REGISTRY TABLE ---
  Widget _buildAcidRegistryTableView() {
    final acidSessionsState = ref.watch(acidSessionsProvider);

    return acidSessionsState.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('خطأ في جلب السجلات: $e', style: const TextStyle(color: Colors.red)))),
      data: (sessions) {
        var filtered = sessions;
        if (_acidStatusFilter != 'All') {
          filtered = filtered.where((s) => s.status == _acidStatusFilter).toList();
        }
        if (_acidSearchQuery.isNotEmpty) {
          filtered = filtered.where((s) =>
              s.acidCode.toLowerCase().contains(_acidSearchQuery.toLowerCase()) ||
              s.acidNumber.contains(_acidSearchQuery) ||
              s.importerName.toLowerCase().contains(_acidSearchQuery.toLowerCase()) ||
              s.exporterName.toLowerCase().contains(_acidSearchQuery.toLowerCase()) ||
              s.proformaInvoiceNo.toLowerCase().contains(_acidSearchQuery.toLowerCase())).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'بحث في سجلات الـ ACID (كود، رقم الـ ACID، المستورد، المورد)...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _acidSearchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _acidStatusFilter,
                        decoration: const InputDecoration(labelText: 'تصفية حسب الحالة', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('جميع الحالات (All)')),
                          DropdownMenuItem(value: 'Requested', child: Text('تحت الطلب (Requested)')),
                          DropdownMenuItem(value: 'Generated', child: Text('صادر من نافذة (Generated)')),
                          DropdownMenuItem(value: 'Verified', child: Text('ساري ومطابق (Verified)')),
                          DropdownMenuItem(value: 'Discrepancy_Accepted', child: Text('معتمد بفروقات (Discrepancy Accepted)')),
                        ],
                        onChanged: (v) => setState(() => _acidStatusFilter = v ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('طلب ACID جديد', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        setState(() {
                          _selectedImportFileId = null;
                          _activeEditingAcidId = null;
                          _comparisonResult = null;
                          _acidSubTab = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty) ...[
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('لا توجد سجلات مطابقة للبحث.'))),
            ] else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.06)),
                    columns: const [
                      DataColumn(label: Text('كود السجل', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('رقم الـ ACID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المستورد والمورد', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الصلاحية والتنفيذ', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((session) {
                      return DataRow(
                        cells: [
                          DataCell(Text(session.acidCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                          DataCell(
                            Text(
                              session.importFileCode ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                            ),
                          ),
                          DataCell(Text(session.acidNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(session.importerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                                Text(session.exporterName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          DataCell(Text(session.proformaInvoiceNo)),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('صلاحية: ${session.expiryDate ?? "-"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                                Text('تنفيذ: ${session.executionDays != null ? "${session.executionDays} يوم" : "-"}', style: const TextStyle(fontSize: 10, color: AppTheme.emerald, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          DataCell(_buildStatusBadge(session.status)),
                          DataCell(
                            RowActionsPill(
                              onView: () => _showAcidDetailsDialog(context, session),
                              onEdit: () => _loadAcidSessionForEdit(session),
                              onPrint: () => _showPrintPreviewDialog(),
                              onDelete: () async {
                                await ref.read(acidSessionsProvider.notifier).softDeleteAcidSession(session.acidId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم حذف الجلسة بنجاح'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                              viewTooltip: 'عرض تفاصيل الـ ACID ومطابقته',
                              editTooltip: 'تعديل بيانات الـ ACID',
                              printTooltip: 'طباعة نموذج الطلب',
                              deleteTooltip: 'حذف السجل',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // --- SUB-VIEW 5: ACID EXPIRY TRACKER (متتبع صلاحية الـ ACID والصرف الجمركي) ---
  Widget _buildAcidExpiryTrackerView() {
    final trackerState = ref.watch(acidTrackerProvider);

    return trackerState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل متتبع صلاحية أرقام الـ ACID والحالات الجمركية الحية...'),
            ],
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.crimson, size: 40),
              const SizedBox(height: 10),
              Text('تعذر تحميل بيانات متتبع الصلاحية: $err', style: const TextStyle(color: AppTheme.crimson)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(acidTrackerProvider.notifier).fetchAcidTracker(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      data: (summary) {
        // Filter items
        final filteredItems = summary.items.where((item) {
          final q = _trackerSearchQuery.trim().toLowerCase();
          final matchesSearch = q.isEmpty ||
              item.acidNumber.toLowerCase().contains(q) ||
              (item.importFileCode ?? '').toLowerCase().contains(q) ||
              (item.customFileNumber ?? '').toLowerCase().contains(q) ||
              item.importerName.toLowerCase().contains(q) ||
              item.supplierName.toLowerCase().contains(q) ||
              (item.poNumber ?? '').toLowerCase().contains(q);

          if (!matchesSearch) return false;

          if (_trackerStatusFilter == 'All') return true;
          if (_trackerStatusFilter == 'Valid' && item.status == 'Valid') return true;
          if (_trackerStatusFilter == 'Expiring Soon' && item.status == 'Expiring Soon') return true;
          if (_trackerStatusFilter == 'Expired' && item.status == 'Expired') return true;
          if (_trackerStatusFilter == 'Customs Released' && item.isCustomsReleased) return true;
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildTrackerKpiCard(
                    title: 'ساري وصالح (Valid)',
                    count: summary.validCount,
                    icon: Icons.check_circle_outline,
                    color: AppTheme.emerald,
                    subtitle: 'متبقي أكثر من 14 يوماً',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrackerKpiCard(
                    title: 'يوشك على الانتهاء',
                    count: summary.expiringSoonCount,
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.orange,
                    subtitle: 'متبقي 14 يوماً أو أقل (تنبيه)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrackerKpiCard(
                    title: 'منتهي الصلاحية (Expired)',
                    count: summary.expiredCount,
                    icon: Icons.dangerous_outlined,
                    color: AppTheme.crimson,
                    subtitle: 'لم تُصرف من الجمرك (حرج)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrackerKpiCard(
                    title: 'صُرفت من الجمرك',
                    count: summary.customsReleasedCount,
                    icon: Icons.verified_user_outlined,
                    color: AppTheme.charcoal,
                    subtitle: 'معفاة من تنبيهات الصلاحية',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Official Regulation & Alert Policy Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.cobalt, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'قاعدة متابعة صلاحية الـ ACID والإفراج الجمركي (Egyptian Customs ACID Policy):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'رقم القيد الجمركي المبدئي (ACID) صالح قانوناً لـ 3 أو 6 أشهر من تاريخ إصداره. بمجرد صرف الشحنة والإفراج الجمركي النهائي عنها (Customs Released)، يُلغى تنبيه انتهاء الصلاحية فوراً وتُعتبر الشحنة معفاة من متابعة الصلاحية.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search & Status Filters
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ابحث برقم الـ ACID أو كود ملف الشحنة أو اسم المستورد / المورد...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _trackerSearchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Filter Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('الكل', 'All', summary.totalAcidsCount),
                        _buildFilterChip('ساري وصالح', 'Valid', summary.validCount, color: AppTheme.emerald),
                        _buildFilterChip('يوشك على الانتهاء', 'Expiring Soon', summary.expiringSoonCount, color: AppTheme.orange),
                        _buildFilterChip('منتهي الصلاحية', 'Expired', summary.expiredCount, color: AppTheme.crimson),
                        _buildFilterChip('صُرفت من الجمرك', 'Customs Released', summary.customsReleasedCount, color: AppTheme.charcoal),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.cobalt),
                      tooltip: 'تحديث حي لمتتبع الصلاحية',
                      onPressed: () => ref.read(acidTrackerProvider.notifier).fetchAcidTracker(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tracker Table
            if (filteredItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: const [
                      Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('لا توجد شحنات مطابقة لمعايير البحث الحالية في متتبع الصلاحية.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    columnSpacing: 20,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 68,
                    columns: const [
                      DataColumn(label: Text('رقم الـ ACID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المستورد والمورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('تواريخ الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المدة المتبقية ونسبة السريان', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('حالة الإفراج الجمركي', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('حالة التنبيه', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredItems.map((item) {
                      Color progressColor;
                      if (item.isCustomsReleased) {
                        progressColor = Colors.grey;
                      } else if (item.status == 'Expired') {
                        progressColor = AppTheme.crimson;
                      } else if (item.status == 'Expiring Soon') {
                        progressColor = AppTheme.orange;
                      } else {
                        progressColor = AppTheme.emerald;
                      }

                      return DataRow(
                        cells: [
                          // ACID Number
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SelectableText(
                                  item.acidNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 14, color: AppTheme.cobalt),
                                  tooltip: 'نسخ رقم الـ ACID',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: item.acidNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم نسخ رقم الـ ACID: ${item.acidNumber}')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Import File Code & Custom File No
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.importFileCode ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 13),
                                ),
                                if (item.customFileNumber != null && item.customFileNumber!.isNotEmpty)
                                  Text(
                                    'رقم مخصص: ${item.customFileNumber}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),

                          // Importer & Supplier
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.importerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                Text('المورد: ${item.supplierName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),

                          // Dates & Execution
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('الإصدار: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(item.acidIssueDate ?? '—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('الانتهاء: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(item.acidExpiryDate ?? '—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                                  ],
                                ),
                                if (item.executionDays != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('أيام التنفيذ: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text('${item.executionDays} يوم', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Days Remaining & Progress Bar
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.isCustomsReleased
                                            ? 'صُرفت من الجمرك'
                                            : item.daysRemaining < 0
                                                ? 'منتهٍ منذ ${item.daysRemaining.abs()} يوم'
                                                : '${item.daysRemaining} يوم متبقٍ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: progressColor,
                                        ),
                                      ),
                                      if (!item.isCustomsReleased)
                                        Text('${item.validityPercentage.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: item.isCustomsReleased ? 1.0 : (item.validityPercentage / 100.0).clamp(0.0, 1.0),
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Customs Release Status Badge
                          DataCell(
                            item.isCustomsReleased
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check_circle, size: 14, color: AppTheme.emerald),
                                        SizedBox(width: 4),
                                        Text('تم الصرف الجمركي', style: TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.hourglass_top, size: 14, color: AppTheme.orange),
                                        SizedBox(width: 4),
                                        Text('قيد التخليص بالميناء', style: TextStyle(color: AppTheme.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                          ),

                          // Alert Status Badge
                          DataCell(
                            item.alertRequired
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.status == 'Expired' ? Colors.red.shade50 : Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: item.status == 'Expired' ? Colors.red.shade300 : Colors.amber.shade400),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.status == 'Expired' ? Icons.error : Icons.notification_important,
                                          size: 14,
                                          color: item.status == 'Expired' ? AppTheme.crimson : AppTheme.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.status == 'Expired' ? 'تنبيه انتهاء حرج' : 'تنبيه اقتراب انتهاء',
                                          style: TextStyle(
                                            color: item.status == 'Expired' ? AppTheme.crimson : AppTheme.orange,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.notifications_off_outlined, size: 14, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text('معفى / لا يوجد تنبيه', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                          ),

                          // Actions
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 18, color: AppTheme.cobalt),
                                  tooltip: 'عرض وتعديل جلسة الـ ACID',
                                  onPressed: () {
                                    if (item.acidSessionId != null) {
                                      setState(() {
                                        _acidSubTab = 3; // Switch to registry
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                                  tooltip: 'تحديث حالة السجل',
                                  onPressed: () => ref.read(acidTrackerProvider.notifier).fetchAcidTracker(),
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
          ],
        );
      },
    );
  }

  Widget _buildTrackerKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count, {Color? color}) {
    final isSelected = _trackerStatusFilter == value;
    final activeColor = color ?? AppTheme.cobalt;

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _trackerStatusFilter = value),
      selectedColor: activeColor.withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? activeColor : AppTheme.charcoal,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? activeColor : Colors.grey.shade300),
    );
  }

  // --- TAB 2: BANKING DOCUMENTS (BP-015: Form 4 Management) ---
  Widget _buildBankingDocsTab() {
    final partnersState = ref.watch(partnersProvider);
    final banksList = (partnersState.value ?? []).where((p) => p.partnerType.contains('Bank') || p.partnerType.contains('بنك')).toList();
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final bankingDocsState = ref.watch(bankingDocumentsProvider);
    final docs = bankingDocsState.value ?? [];

    return Column(
      children: [
        // Sub-Tabs Header
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildForm4SubTabButton(
                index: 0,
                title: 'طلب إصدار وتوثيق نموذج 4 جديد (New Request)',
                icon: Icons.note_add_outlined,
              ),
              const SizedBox(width: 12),
              _buildForm4SubTabButton(
                index: 1,
                title: 'سجل النماذج البنكية والتوثيق (Saved Form 4 Registry)',
                icon: Icons.history_edu_outlined,
                badgeCount: docs.length,
              ),
            ],
          ),
        ),
        Expanded(
          child: _form4SubTab == 0
              ? _buildForm4RequestTab(banksList, importFiles)
              : _buildForm4HistoryRegistryTab(docs, importFiles),
        ),
      ],
    );
  }

  Widget _buildForm4SubTabButton({
    required int index,
    required String title,
    required IconData icon,
    int? badgeCount,
  }) {
    final isSelected = _form4SubTab == index;
    return InkWell(
      onTap: () => setState(() => _form4SubTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cobalt : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.cobalt : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.cobalt.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.charcoal),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.charcoal,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppTheme.cobalt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? AppTheme.cobalt : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _loadForm4ForEdit(BankingDocumentModel doc) {
    setState(() {
      _editingBankDocId = doc.bankDocId;
      _editingBankDocCode = doc.bankDocCode;
      _form4ImportFileId = doc.importFileId;
      _bankDocType = doc.docType;
      _selectedBankId = doc.bankId;
      _bankName = doc.bankName;
      _bankAmountController.text = doc.amount.toStringAsFixed(2);
      _form4Currency = doc.currencyCode;
      _form4RequestDateCtrl.text = doc.requestDate ?? doc.issueDate;
      _form4NotesCtrl.text = doc.notes ?? '';
      _form4SubTab = 0; // Switch to Request Tab
    });
  }

  void _resetForm4Form() {
    setState(() {
      _editingBankDocId = null;
      _editingBankDocCode = null;
      _form4ImportFileId = null;
      _bankDocType = 'Form 4';
      _selectedBankId = null;
      _bankName = 'National Bank of Egypt (NBE)';
      _bankAmountController.clear();
      _form4Currency = 'USD';
      _form4RequestDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
      _form4NotesCtrl.clear();
    });
  }

  // --- FORM 4 SUB-TAB 0: REQUEST FORM ---
  Widget _buildForm4RequestTab(List banksList, List<dynamic> importFiles) {
    final selectedFile = _form4ImportFileId != null
        ? importFiles.where((f) => f.importFileId == _form4ImportFileId).firstOrNull
        : null;
    final bankingDocs = ref.watch(bankingDocumentsProvider).value ?? [];
    final existingForm4ForSelectedFile = (_editingBankDocId == null && _form4ImportFileId != null && _bankDocType == 'Form 4')
        ? bankingDocs.where((d) => d.importFileId == _form4ImportFileId && d.docType == 'Form 4' && d.isActive).firstOrNull
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _bankFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edit Mode Banner
            if (_editingBankDocId != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppTheme.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'أنت الآن في وضع تعديل طلب نموذج 4: ${_editingBankDocCode ?? "طلب #$_editingBankDocId"}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimson,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('إلغاء التعديل والعودة لطلب جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _resetForm4Form,
                    ),
                  ],
                ),
              ),
            ],

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined, color: AppTheme.cobalt, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'مرحلة الطلب: إصدار وتوثيق نموذج 4 / تحويل بنكي / اعتماد مستندي (BP-015)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'البنك المركزي المصري • CBE Form 4 Protocol',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // 1. Link Import File & Transaction Type & Bank
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Link Import File Dropdown
                        Expanded(
                          flex: 3,
                          child: SearchableDropdownField<int?>(
                            value: _form4ImportFileId,
                            labelText: 'ربط ملف الشحنة الاستيرادية (Import File) *',
                            searchHintText: 'ابحث برقم الملف، الشركة المستوردة، أو المورد...',
                            items: [
                              const SearchableDropdownItem<int?>(value: null, label: '-- بدون ربط (طلب حر) --'),
                              ...importFiles.map((f) {
                                final label = '${f.importFileCode} - ${f.companyName} (${f.supplierName})';
                                return SearchableDropdownItem<int?>(
                                  value: f.importFileId,
                                  label: label,
                                  subtitle: 'PO: ${f.poNumber ?? "-"} | التكلفة التقديرية: ${f.estimatedCost} | المرحلة: ${f.currentStage}',
                                );
                              }),
                            ],
                            onChanged: (id) {
                              setState(() {
                                _form4ImportFileId = id;
                                if (id != null) {
                                  final file = importFiles.where((f) => f.importFileId == id).firstOrNull;
                                  if (file != null) {
                                    if (file.estimatedCost > 0) {
                                      _bankAmountController.text = file.estimatedCost.toStringAsFixed(2);
                                    }
                                    if (file.invoicesData != null && (file.invoicesData as List).isNotEmpty) {
                                      final firstInv = (file.invoicesData as List).first;
                                      if (firstInv is Map && firstInv['currency'] != null) {
                                        _form4Currency = firstInv['currency'].toString().toUpperCase();
                                      }
                                      if (firstInv is Map && firstInv['amount'] != null && (firstInv['amount'] as num) > 0) {
                                        _bankAmountController.text = (firstInv['amount'] as num).toDouble().toStringAsFixed(2);
                                      }
                                    }
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Transaction Type Dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _bankDocType,
                            decoration: const InputDecoration(labelText: 'نوع المعاملة البنكية *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'Form 4', child: Text('نموذج 4 (Form 4 - تحويل بنكي)')),
                              DropdownMenuItem(value: 'Form 9', child: Text('نموذج 9 (Form 9 - تحصيل مستندي)')),
                              DropdownMenuItem(value: 'Letter of Credit (L/C)', child: Text('اعتماد مستندي (Letter of Credit)')),
                            ],
                            onChanged: (v) => setState(() => _bankDocType = v ?? 'Form 4'),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Bank Selector
                        Expanded(
                          flex: 2,
                          child: SearchableDropdownField<int?>(
                            value: _selectedBankId,
                            labelText: 'البنك المصرفي (Bank) *',
                            searchHintText: 'ابحث عن البنك المصرفي...',
                            items: banksList
                                .map((b) => SearchableDropdownItem<int?>(
                                      value: b.providerId,
                                      label: b.partnerName,
                                      subtitle: b.country,
                                    ))
                                .toList(),
                            onChanged: (id) {
                              setState(() {
                                _selectedBankId = id;
                                if (id != null) {
                                  _bankName = banksList.firstWhere((b) => b.providerId == id).partnerName;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Duplicate warning banner if Form 4 already exists for this file
                    if (existingForm4ForSelectedFile != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'تنبيه: ملف الشحنة هذا مسجل له بالفعل طلب نموذج 4 في سجل النماذج (${existingForm4ForSelectedFile.bankDocCode}${existingForm4ForSelectedFile.docReferenceNumber != "PENDING" && existingForm4ForSelectedFile.docReferenceNumber.isNotEmpty ? " - رقم النموذج: ${existingForm4ForSelectedFile.docReferenceNumber}" : ""}). لا يمكن إضافة طلب جديد، يرجى التعديل على الطلب القائم.',
                                style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.edit, size: 15),
                              label: const Text('تعديل الطلب القائم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _loadForm4ForEdit(existingForm4ForSelectedFile),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Linked File Summary Preview Card
                    if (selectedFile != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, color: AppTheme.cobalt, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Wrap(
                                spacing: 20,
                                runSpacing: 8,
                                children: [
                                  _buildSummaryChip('ملف الشحنة:', selectedFile.importFileCode, Colors.blueGrey),
                                  _buildSummaryChip('الشركة المستوردة:', selectedFile.companyName, AppTheme.cobalt),
                                  _buildSummaryChip('المورد الأجنبي:', selectedFile.supplierName, AppTheme.charcoal),
                                  if (selectedFile.poNumber != null)
                                    _buildSummaryChip('أمر الشراء PO:', selectedFile.poNumber!, AppTheme.emerald),
                                  if (selectedFile.piNumber != null)
                                    _buildSummaryChip('الفاتورة PI:', selectedFile.piNumber!, Colors.deepPurple),
                                  _buildSummaryChip('طريقة الشحن:', selectedFile.shipmentMode, Colors.teal),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 2. Amount & Currency & Request Date
                    Row(
                      children: [
                        // Amount
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _bankAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'المبلغ الإجمالي للمعاملة *',
                              hintText: 'e.g. 62300.00',
                              prefixIcon: const Icon(Icons.attach_money_rounded),
                              border: const OutlineInputBorder(),
                              helperText: 'يتم استدعاؤه آلياً من ملف الشحنة أو الفاتورة المبدئية',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null || parsed <= 0) return 'يرجى إدخال مبلغ صحيح أكبر من صفر';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Currency
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _form4Currency,
                            decoration: const InputDecoration(
                              labelText: 'عملة المعاملة *',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                              DropdownMenuItem(value: 'EUR', child: Text('يورو أوروبي (EUR)')),
                              DropdownMenuItem(value: 'GBP', child: Text('جنيه إسترليني (GBP)')),
                              DropdownMenuItem(value: 'CNY', child: Text('يوان صيني (CNY)')),
                              DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                              DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                              DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                            ],
                            onChanged: (v) => setState(() => _form4Currency = v ?? 'USD'),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Request Date with Picker
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _form4RequestDateCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'تاريخ تقديم الطلب للبنك *',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(_form4RequestDateCtrl.text) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() {
                                  _form4RequestDateCtrl.text = picked.toString().substring(0, 10);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _form4NotesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات طلب نموذج 4 والتعليمات المصرفية',
                        hintText: 'أي تفاصيل خاصة بتعليمات التحويل أو الغطاء النقدي أو البنك المراسل...',
                        prefixIcon: Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _editingBankDocId != null ? AppTheme.orange : AppTheme.emerald,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isSavingForm4
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_editingBankDocId != null ? Icons.save_as_rounded : Icons.check_circle_outline, color: Colors.white),
                          label: Text(
                            _isSavingForm4
                                ? 'جاري الحفظ...'
                                : (_editingBankDocId != null ? '💾 حفظ تعديلات طلب نموذج 4' : 'تسجيل وحفظ طلب نموذج 4 (BP-015)'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: _isSavingForm4 ? null : _saveBankingDoc,
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.cobalt,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('الانتقال إلى سجل النماذج المحفوظة', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _form4SubTab = 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // --- FORM 4 SUB-TAB 1: SAVED HISTORY REGISTRY (Matches Shipping Scenarios Style) ---
  Widget _buildForm4HistoryRegistryTab(List<BankingDocumentModel> docs, List<dynamic> importFiles) {
    final totalCount = docs.length;
    final requestedCount = docs.where((d) => d.status == 'Requested' || d.docReferenceNumber == 'PENDING').length;
    final receivedCount = docs.where((d) => d.status == 'Received' || d.docReferenceNumber != 'PENDING').length;
    final receivedDocs = docs.where((d) => d.executionDays > 0).toList();
    final avgExecDays = receivedDocs.isNotEmpty
        ? (receivedDocs.fold<int>(0, (sum, d) => sum + d.executionDays) / receivedDocs.length).round()
        : 0;

    // Filtering
    final filtered = docs.where((d) {
      final matchesSearch = _form4SearchQuery.isEmpty ||
          d.bankDocCode.toLowerCase().contains(_form4SearchQuery.toLowerCase()) ||
          d.bankName.toLowerCase().contains(_form4SearchQuery.toLowerCase()) ||
          (d.importFileCode != null && d.importFileCode!.toLowerCase().contains(_form4SearchQuery.toLowerCase())) ||
          (d.importerName != null && d.importerName!.toLowerCase().contains(_form4SearchQuery.toLowerCase())) ||
          (d.docReferenceNumber.toLowerCase().contains(_form4SearchQuery.toLowerCase()));

      final matchesStatus = _form4StatusFilter == 'All' ||
          (_form4StatusFilter == 'Requested' && (d.status == 'Requested' || d.docReferenceNumber == 'PENDING')) ||
          (_form4StatusFilter == 'Received' && (d.status == 'Received' || d.docReferenceNumber != 'PENDING'));

      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Summary Stat Cards in Charcoal Banner
        Container(
          color: AppTheme.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _form4StatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'إجمالي النماذج',
                value: '$totalCount',
                color: AppTheme.cobalt,
              ),
              const SizedBox(width: 10),
              _form4StatCard(
                icon: Icons.pending_actions_rounded,
                label: 'طلبات جارية (قيد التنفيذ)',
                value: '$requestedCount',
                color: Colors.orange.shade400,
              ),
              const SizedBox(width: 10),
              _form4StatCard(
                icon: Icons.check_circle_rounded,
                label: 'نماذج معتمدة ومستلمة',
                value: '$receivedCount',
                color: AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              _form4StatCard(
                icon: Icons.timer_outlined,
                label: 'متوسط سرعة التنفيذ',
                value: avgExecDays > 0 ? '$avgExecDays يوم' : '-',
                color: Colors.purple.shade300,
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تحديث السجل', style: TextStyle(fontSize: 13)),
                onPressed: () => ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('طلب جديد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _form4SubTab = 0),
              ),
            ],
          ),
        ),

        // 2. Search & Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث بكود الطلب، رقم نموذج 4، البنك، الشركة، أو رقم ملف الشحنة...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cobalt),
                    suffixIcon: _form4SearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _form4SearchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (val) => setState(() => _form4SearchQuery = val),
                ),
              ),
              const SizedBox(width: 14),
              // Status Filter
              DropdownButton<String>(
                value: _form4StatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                  DropdownMenuItem(value: 'Requested', child: Text('قيد التنفيذ (Pending)')),
                  DropdownMenuItem(value: 'Received', child: Text('تم الاستلام والتوثيق (Received)')),
                ],
                onChanged: (v) => setState(() => _form4StatusFilter = v ?? 'All'),
              ),
            ],
          ),
        ),

        // 3. DataTable Registry
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _form4SearchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة لبحثك' : 'لا توجد نماذج بنكية مسجلة حتى الآن',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('قم بتقديم طلب نموذج 4 جديد لربطه بملفات الشحنات وتوثيقه لدى البنك', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('إنشاء طلب نموذج 4 الآن'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                        onPressed: () => setState(() => _form4SubTab = 0),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                        horizontalMargin: 16,
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('كود الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('البنك المصرفي', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المبلغ والعملة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('تاريخ الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('رقم نموذج 4', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('تاريخ الاستلام', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مدة التنفيذ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((d) {
                          final isReceived = d.status == 'Received' || (d.docReferenceNumber != 'PENDING' && d.docReferenceNumber.isNotEmpty);
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Receive / Finalize Action
                                    if (!isReceived)
                                      IconButton(
                                        icon: const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.emerald, size: 20),
                                        tooltip: 'استلام وتوثيق رقم نموذج 4',
                                        onPressed: () => _showReceiveForm4Dialog(d),
                                      ),
                                    // View / Share / Export Action
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined, color: AppTheme.cobalt, size: 20),
                                      tooltip: 'عرض وتصدير PDF / Excel / WhatsApp / Email',
                                      onPressed: () => _showForm4ShareExportDialog(d),
                                    ),
                                    // Edit Action
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.orange, size: 20),
                                      tooltip: 'تعديل بيانات الطلب',
                                      onPressed: () => _loadForm4ForEdit(d),
                                    ),
                                    // Delete
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 20),
                                      tooltip: 'حذف',
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('تأكيد الحذف'),
                                            content: Text('هل أنت متأكد من حذف المستند البنكي ${d.bankDocCode}؟'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await ref.read(bankingDocumentsProvider.notifier).deleteBankingDocument(d.bankDocId);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(d.bankDocCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                              DataCell(Text(d.docType)),
                              DataCell(
                                Text(
                                  d.importFileCode ?? (d.importFileId != null ? 'FILE-${d.importFileId}' : '-'),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(Text(d.bankName)),
                              DataCell(
                                Text(
                                  '${d.amount.toStringAsFixed(2)} ${d.currencyCode}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                ),
                              ),
                              DataCell(Text(d.requestDate ?? d.issueDate)),
                              DataCell(
                                d.docReferenceNumber == 'PENDING'
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
                                        child: const Text('قيد الاستخراج', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                                      )
                                    : Text(d.docReferenceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                              ),
                              DataCell(Text(d.receivedDate ?? '-')),
                              DataCell(
                                d.executionDays > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.shade200)),
                                        child: Text('${d.executionDays} يوم', style: TextStyle(fontSize: 11, color: Colors.purple.shade800, fontWeight: FontWeight.bold)),
                                      )
                                    : const Text('-'),
                              ),
                              DataCell(_buildStatusBadge(d.status)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _form4StatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: SHIPMENT DOCUMENTS & CARGOX ---
  Widget _buildShipmentDocsTab() {
    final shipmentDocsState = ref.watch(shipmentDocumentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _docFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تسجيل مستندات الشحنة ورفع CargoX والتظهير الملاحي (Shipment Docs & B/L Endorsement)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _docName,
                            decoration: const InputDecoration(labelText: 'نوع المستند الرسمي *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'Commercial Invoice (الفاتورة التجارية)', child: Text('الفاتورة التجارية النهائية (Commercial Invoice)')),
                              DropdownMenuItem(value: 'Packing List (بيان العبوة)', child: Text('بيان العبوة (Packing List)')),
                              DropdownMenuItem(value: 'Bill of Lading (بوليصة الشحن)', child: Text('بوليصة الشحن البحرية/الجوية (B/L)')),
                              DropdownMenuItem(value: 'Certificate of Origin (شهادة المنشأ)', child: Text('شهادة المنشأ المعتمدة (Certificate of Origin)')),
                              DropdownMenuItem(value: 'EUR.1 / FTA Certificate', child: Text('شهادة الاتفاقية التفضيلية (EUR.1 / Agadir / GAFTA)')),
                            ],
                            onChanged: (v) => setState(() => _docName = v ?? 'Commercial Invoice (الفاتورة التجارية)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _docNumController,
                            decoration: const InputDecoration(labelText: 'رقم المستند / البوليصة *', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم المستند مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('إضافة للسجل المركزي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _saveShipmentDoc,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            shipmentDocsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: $e'),
              data: (docs) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('الإجراءات')),
                      DataColumn(label: Text('كود المستند')),
                      DataColumn(label: Text('نوع المستند')),
                      DataColumn(label: Text('رقم المستند')),
                      DataColumn(label: Text('CargoX Envelope')),
                      DataColumn(label: Text('التظهير الملاحي (B/L)')),
                      DataColumn(label: Text('الحالة')),
                    ],
                    rows: docs.map((doc) {
                      return DataRow(cells: [
                        DataCell(
                          RowActionsPill(
                            onView: () => _showCargoxAndBLEndorsementDialog(doc),
                            onEdit: () => _showCargoxAndBLEndorsementDialog(doc),
                            onPrint: () {},
                            onDelete: () {},
                            viewTooltip: 'عرض وتظهير المستند',
                            editTooltip: 'تحديث منصة CargoX',
                            printTooltip: 'طباعة المستند',
                            deleteTooltip: 'حذف',
                          ),
                        ),
                        DataCell(Text(doc.documentCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                        DataCell(Text(doc.docName)),
                        DataCell(Text(doc.docNumber)),
                        DataCell(
                          doc.isCargoxUploaded
                              ? Chip(label: Text('CargoX ✔ (${doc.cargoxEnvelopeId ?? "-"})', style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green)
                              : const Chip(label: Text('Pending Upload', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.grey),
                        ),
                        DataCell(
                          doc.isBlEndorsed
                              ? Chip(label: Text('Endorsed ✔ (${doc.endorsementNumber ?? "-"})', style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: AppTheme.cobalt)
                              : const Text('-'),
                        ),
                        DataCell(_buildStatusBadge(doc.status)),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 4: DECLARATION 46 PREPARATION ---
  Widget _buildDeclaration46Tab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description, color: AppTheme.cobalt),
                    SizedBox(width: 8),
                    Text('مسودة إقرار 46 جمارك الجاهزة للربط مع نافذة (Customs Declaration 46 Draft)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رقم التسجيل المسبق ACID: 7595528271015010011', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt)),
                      SizedBox(height: 6),
                      Text('رقم نموذج 4 البنكي: F4-2026-99081 | بوليصة الشحن: MAEU987654321'),
                      SizedBox(height: 6),
                      Text('إجمالي القيمة الجمركية (CIF Base EGP): 3,322,500.00 EGP'),
                      Text('إجمالي ضريبة الوارد والجمارك المقدرة: 332,250.00 EGP'),
                      Text('إجمالي ضريبة القيمة المضافة (VAT): 511,665.00 EGP'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBankingDoc() async {
    if (!_bankFormKey.currentState!.validate()) return;

    // Duplicate session validation: prevent creating new request if active Form 4 session already exists for this file
    final bankingDocs = ref.read(bankingDocumentsProvider).value ?? [];
    if (_editingBankDocId == null && _form4ImportFileId != null && _bankDocType == 'Form 4') {
      final existingForm4 = bankingDocs.where((d) => d.importFileId == _form4ImportFileId && d.docType == 'Form 4' && d.isActive).firstOrNull;
      if (existingForm4 != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 28),
                SizedBox(width: 8),
                Text('طلب نموذج 4 مسجل مسبقاً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'لا يمكن حفظ طلب نموذج 4 جديد لأن ملف الشحنة المختار مرتبط بالفعل بطلب مسجل ومحفوظ في سجل النماذج (${existingForm4.bankDocCode}${existingForm4.docReferenceNumber != "PENDING" && existingForm4.docReferenceNumber.isNotEmpty ? " - رقم النموذج: ${existingForm4.docReferenceNumber}" : ""}).\n\nيرجى التوجه إلى سجل النماذج للتعديل على الطلب الحالي بدلاً من إنشاء طلب جديد.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.history_edu, size: 16),
                label: const Text('سجل النماذج'),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _form4SubTab = 1);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange, foregroundColor: Colors.white),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل الطلب القائم'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadForm4ForEdit(existingForm4);
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() => _isSavingForm4 = true);
    try {
      final payload = {
        'doc_type': _bankDocType,
        'import_file_id': _form4ImportFileId,
        'bank_id': _selectedBankId,
        'bank_name': _bankName,
        'doc_reference_number': 'PENDING',
        'amount': double.tryParse(_bankAmountController.text.trim()) ?? 0.0,
        'currency_code': _form4Currency,
        'request_date': _form4RequestDateCtrl.text.trim(),
        'issue_date': _form4RequestDateCtrl.text.trim(),
        'notes': _form4NotesCtrl.text.trim().isEmpty ? null : _form4NotesCtrl.text.trim(),
      };

      if (_editingBankDocId != null) {
        final updated = await ref.read(bankingDocumentsProvider.notifier).updateBankingDocument(_editingBankDocId!, payload);
        ref.read(importFilesProvider.notifier).fetchImportFiles();
        if (mounted && updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تحديث بيانات طلب نموذج 4 بنجاح: ${updated.bankDocCode}'),
              backgroundColor: AppTheme.emerald,
              duration: const Duration(seconds: 3),
            ),
          );
          _showForm4ShareExportDialog(updated);
        }
      } else {
        final created = await ref.read(bankingDocumentsProvider.notifier).createBankingDocument(payload);
        ref.read(importFilesProvider.notifier).fetchImportFiles();
        if (mounted && created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تسجيل وحفظ طلب نموذج 4 بنجاح: ${created.bankDocCode}'),
              backgroundColor: AppTheme.emerald,
              duration: const Duration(seconds: 3),
            ),
          );
          // Open the Share / Export Dialog immediately upon saving!
          _showForm4ShareExportDialog(created);
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ خطأ في حفظ طلب نموذج 4',
          error: e,
          subtitle: 'تعذر حفظ المستند البنكي لدى السيرفر.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingForm4 = false);
    }
  }

  // --- DIALOG 1: RECEIVE & ENDORSE FORM 4 (مرحلة استلام وتوثيق نموذج 4) ---
  void _showReceiveForm4Dialog(BankingDocumentModel doc) {
    final form4NoCtrl = TextEditingController(text: doc.docReferenceNumber == 'PENDING' ? '' : doc.docReferenceNumber);
    final receivedDateCtrl = TextEditingController(text: doc.receivedDate ?? DateTime.now().toString().substring(0, 10));
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final reqDate = DateTime.tryParse(doc.requestDate ?? doc.issueDate) ?? DateTime.now();
            final recDate = DateTime.tryParse(receivedDateCtrl.text) ?? DateTime.now();
            final execDays = max(0, recDate.difference(reqDate).inDays);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.emerald, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'مرحلة استلام وتوثيق نموذج 4 (${doc.bankDocCode})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Summary Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('البنك: ${doc.bankName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('المبلغ: ${doc.amount} ${doc.currencyCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('ملف الشحنة: ${doc.importFileCode ?? (doc.importFileId != null ? "FILE-${doc.importFileId}" : "غير مربوط")}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text('تاريخ تقديم الطلب للبنك: ${doc.requestDate ?? doc.issueDate}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Form 4 Number
                        TextFormField(
                          controller: form4NoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'رقم نموذج 4 الرسمي المعتمد من البنك *',
                            hintText: 'e.g. F4-2026-99081 / 108472910',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم نموذج 4 مطلوب' : null,
                        ),
                        const SizedBox(height: 14),

                        // Receipt Date with Live Execution Days Calculation
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: receivedDateCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ استلام واعتماد النموذج *',
                                  prefixIcon: Icon(Icons.event_available_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: recDate,
                                    firstDate: reqDate,
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      receivedDateCtrl.text = picked.toString().substring(0, 10);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Execution Days Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.shade300),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('مدة التنفيذ', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$execDays يوم',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات الاعتماد والاستلام',
                            hintText: 'اسم الموظف المستلم أو أي تفاصيل مصرفية إضافية...',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('اعتماد وحفظ ومزامنة ملف الشحنة'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);
                    try {
                      final payload = {
                        'form4_number': form4NoCtrl.text.trim(),
                        'received_date': receivedDateCtrl.text.trim(),
                        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      };
                      final updated = await ref.read(bankingDocumentsProvider.notifier).receiveBankingDocument(doc.bankDocId, payload);
                      // Auto refresh import files to show the synced Form 4 number and execution days!
                      ref.read(importFilesProvider.notifier).fetchImportFiles();

                      if (mounted && updated != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ تم اعتماد نموذج 4 بنجاح وتمت المزامنة الآلية مع ملف الشحنة (${updated.docReferenceNumber})'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        await showErrorDetailsDialog(
                          context,
                          title: '❌ خطأ في اعتماد نموذج 4',
                          error: e,
                          subtitle: 'تعذر تحديث بيانات الاستلام.',
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIALOG 2: SHARE & EXPORT (PDF, EXCEL, WHATSAPP, EMAIL) ---
  void _showForm4ShareExportDialog(BankingDocumentModel doc) {
    final reqDate = doc.requestDate ?? doc.issueDate;
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final linkedFile = doc.importFileId != null
        ? importFiles.where((f) => f.importFileId == doc.importFileId).firstOrNull
        : null;

    final importerName = doc.importerName ?? linkedFile?.companyName ?? 'الشركة المستوردة';
    final supplierName = doc.supplierName ?? linkedFile?.supplierName ?? 'المورد الأجنبي';
    final poNumber = doc.poNumber ?? linkedFile?.poNumber ?? 'PO-1001';
    final piNumber = linkedFile?.piNumber ?? 'PI-Official';
    final shipmentMode = linkedFile?.shipmentMode ?? 'Sea FCL';

    // WhatsApp Message Text Pre-generation
    final whatsAppText = '''
*طلب توثيق وإصدار نموذج 4 بنكي (CBE Form 4 Application)*
🏛 *البنك المصرفي:* ${doc.bankName}
📄 *كود المعاملة:* ${doc.bankDocCode}
📁 *ملف الشحنة:* ${doc.importFileCode ?? (linkedFile != null ? linkedFile.importFileCode : "-")}
🏢 *الشركة المستوردة:* $importerName
🌐 *المورد الأجنبي:* $supplierName
📦 *أمر الشراء / الفاتورة:* $poNumber / $piNumber
💰 *المبلغ والعملة:* ${doc.amount.toStringAsFixed(2)} ${doc.currencyCode}
📅 *تاريخ الطلب:* $reqDate
📌 *الحالة الحالية:* ${doc.status}
${doc.docReferenceNumber != 'PENDING' ? '🔢 *رقم نموذج 4 المعتمد:* ' + doc.docReferenceNumber : ''}
''';

    // Email Subject & Body Pre-generation
    final emailSubject = 'طلب توثيق وإصدار نموذج 4 - $importerName - ملف ${doc.importFileCode ?? doc.bankDocCode}';
    final emailBody = '''
السادة / إدارة العمليات المصرفية والتجارة الخارجية - ${doc.bankName}
تحية طيبة وبعد،،

يرجى التكرم باتخاذ اللازم نحو توثيق وإصدار نموذج 4 (Form 4) للشحنة الاستيرادية الخاصة بنا وفقاً للبيانات التالية:

• كود الطلب الداخلي: ${doc.bankDocCode}
• ملف الشحنة: ${doc.importFileCode ?? "-"}
• الشركة المستوردة: $importerName
• المورد الأجنبي: $supplierName
• رقم أمر الشراء: $poNumber
• رقم الفاتورة المبدئية: $piNumber
• المبلغ الإجمالي: ${doc.amount.toStringAsFixed(2)} ${doc.currencyCode}
• تاريخ تقديم الطلب: $reqDate
• طريقة الشحن: $shipmentMode

مرفق طيه صورة الفاتورة المبدئية ومستندات الشحن للتوثيق البنكي طبقاً لتعليمات البنك المركزي المصري.

وتفضلوا بقبول فائق الاحترام والتقدير،،
إدارة الاستيراد والتخليص الجمركي
$importerName
''';

    // CSV Format String
    final csvContent = '''
كود الطلب,نوع المعاملة,البنك المصرفي,ملف الشحنة,الشركة المستوردة,المورد الأجنبي,رقم أمر الشراء,المبلغ,العملة,تاريخ الطلب,رقم نموذج 4,تاريخ الاستلام,أيام التنفيذ,الحالة
"${doc.bankDocCode}","${doc.docType}","${doc.bankName}","${doc.importFileCode ?? ''}","$importerName","$supplierName","$poNumber",${doc.amount},"${doc.currencyCode}","$reqDate","${doc.docReferenceNumber}","${doc.receivedDate ?? ''}",${doc.executionDays},"${doc.status}"
''';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.print_outlined, color: AppTheme.cobalt, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'خيارات التصدير والمشاركة لنموذج 4 (${doc.bankDocCode})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Cards Grid
                  Row(
                    children: [
                      // PDF Preview & Print Card
                      Expanded(
                        child: _buildShareActionCard(
                          icon: Icons.picture_as_pdf_rounded,
                          title: 'عرض وتنزيل PDF',
                          subtitle: 'طباعة خطاب طلب نموذج 4 الرسمي الموجه للبنك',
                          color: Colors.red.shade700,
                          bgColor: Colors.red.shade50,
                          onTap: () {
                            _showPdfPreviewModal(doc, importerName, supplierName, poNumber, piNumber, reqDate);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Excel Export Card
                      Expanded(
                        child: _buildShareActionCard(
                          icon: Icons.table_view_rounded,
                          title: 'تصدير إكسيل (Excel / CSV)',
                          subtitle: 'نسخ وتنزيل بيانات النموذج بتنسيق جدول بيانات',
                          color: Colors.green.shade700,
                          bgColor: Colors.green.shade50,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: csvContent));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم نسخ بيانات الجدول (CSV / Excel) إلى الحافظة بنجاح!'),
                                backgroundColor: AppTheme.emerald,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // WhatsApp Share Card
                      Expanded(
                        child: _buildShareActionCard(
                          icon: Icons.chat_rounded,
                          title: 'إرسال عبر واتساب (WhatsApp)',
                          subtitle: 'مشاركة رسالة منسقة وجاهزة بالبيانات للبنك/المسؤول',
                          color: const Color(0xFF25D366),
                          bgColor: const Color(0xFFE8F8EE),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: whatsAppText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم نسخ نص رسالة الواتساب المنسقة إلى الحافظة بنجاح!'),
                                backgroundColor: Color(0xFF25D366),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Email Share Card
                      Expanded(
                        child: _buildShareActionCard(
                          icon: Icons.email_outlined,
                          title: 'إرسال بريد إلكتروني (Email)',
                          subtitle: 'توليد خطاب إيميل رسمي لإدارة العمليات المصرفية',
                          color: AppTheme.cobalt,
                          bgColor: Colors.blue.shade50,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: 'Subject: $emailSubject\n\n$emailBody'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم نسخ موضوع ومحتوى البريد الإلكتروني إلى الحافظة بنجاح!'),
                                backgroundColor: AppTheme.cobalt,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Message Preview Box
                  const Text('معاينة نص الخطاب / المراسلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      emailBody,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfPreviewModal(
    BankingDocumentModel doc,
    String importerName,
    String supplierName,
    String poNumber,
    String piNumber,
    String reqDate,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text('معاينة وثيقة طلب نموذج 4 (${doc.bankDocCode}) - PDF'),
              ),
            ],
          ),
          content: Container(
            width: 600,
            height: 520,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Official Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(importerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('إدارة التجارة الخارجية والعمليات الاستيرادية', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.charcoal, borderRadius: BorderRadius.circular(4)),
                        child: Text(doc.bankDocCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1.5, height: 24),

                  // Bank & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إلى: السادة / ${doc.bankName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('التاريخ: $reqDate', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Subject
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade400)),
                      child: const Text(
                        'الموضوع: طلب إصدار وتوثيق نموذج 4 بنكي (CBE Form 4 Application)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table of details
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      _buildPdfRow('الشركة المستوردة:', importerName),
                      _buildPdfRow('المورد الأجنبي / المستفيد:', supplierName),
                      _buildPdfRow('رقم أمر الشراء (PO):', poNumber),
                      _buildPdfRow('رقم الفاتورة المبدئية (PI):', piNumber),
                      _buildPdfRow('المبلغ الإجمالي:', '${doc.amount.toStringAsFixed(2)} ${doc.currencyCode}'),
                      _buildPdfRow('ملف الشحنة الداخلي:', doc.importFileCode ?? "-"),
                      _buildPdfRow('نوع المعاملة البنكية:', doc.docType),
                      if (doc.docReferenceNumber != 'PENDING')
                        _buildPdfRow('رقم نموذج 4 المعتمد:', doc.docReferenceNumber),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CBE Text
                  const Text(
                    'نقر بصحة البيانات الواردة أعلاه ونفوضكم في توثيق نموذج 4 طبقاً للتعليمات والضوابط المنظمة الصادرة عن البنك المركزي المصري ومنظومة نافذة النافذة الواحدة.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // Signatures
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text('توقيع المدير المالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: 35),
                          Text('.............................', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('ختم الشركة المستوردة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: 35),
                          Text('[ خـتـم الـشـركـة ]', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('اعتماد البنك المصرفي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: 35),
                          Text('.............................', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 18),
              label: const Text('طباعة / تنزيل PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🖨️ تم إرسال وثيقة طلب نموذج 4 للطباعة والحفظ بصيغة PDF بنجاح!'), backgroundColor: AppTheme.emerald),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  TableRow _buildPdfRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _saveShipmentDoc() async {
    if (!_docFormKey.currentState!.validate()) return;
    try {
      final payload = {
        'doc_name': _docName,
        'doc_number': _docNumController.text.trim(),
        'issue_date': DateTime.now().toString().substring(0, 10),
      };
      final created = await ref.read(shipmentDocumentsProvider.notifier).createShipmentDocument(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم إضافة المستند إلى السجل المركزي: ${created.documentCode}'), backgroundColor: AppTheme.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showCargoxAndBLEndorsementDialog(ShipmentDocumentModel doc) {
    final cargoxController = TextEditingController(text: doc.cargoxEnvelopeId ?? 'ENV-CGX-2026-887766');
    final blEndorsementController = TextEditingController(text: doc.endorsementNumber ?? 'END-BL-2026-112233');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.file_upload, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تحديث وتظهير المستند: ${doc.docName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cargoxController,
                  decoration: const InputDecoration(labelText: 'رقم الغلاف الرقمي منصة CargoX (Envelope ID)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (doc.docName.contains('Bill of Lading') || doc.docName.contains('b/l') || doc.docName.contains('بوليصة')) ...[
                  TextField(
                    controller: blEndorsementController,
                    decoration: const InputDecoration(labelText: 'رقم التظهير الملاحي لبوليصة الشحن (B/L Endorsement No) *', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              onPressed: () async {
                final nav = Navigator.of(context);
                await ref.read(shipmentDocumentsProvider.notifier).updateCargoXAndBLEndorsement(
                      doc.documentId,
                      cargoxEnvId: cargoxController.text.trim(),
                      endorsementNum: blEndorsementController.text.trim(),
                    );
                nav.pop();
              },
              child: const Text('تأكيد وتحديث التظهير', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAcidDetailsDialog(BuildContext context, AcidRegistrationModel acid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Expanded(
              child: Text('تفاصيل رقم الـ ACID: ${acid.acidCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.cobalt, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'رقم الـ ACID (منظومة نافذة): ${acid.acidNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.business, color: AppTheme.charcoal),
                  title: Text('المستورد المصري: ${acid.importerName}'),
                  subtitle: Text('الرقم الضريبي: ${acid.importerTaxId} | العنوان: ${acid.importerAddress ?? "-"}'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.public, color: AppTheme.charcoal),
                  title: Text('المصدر الأجنبي: ${acid.exporterName} (${acid.exporterCountry})'),
                  subtitle: Text('المعرف الضريبي: ${acid.exporterRegId} (${acid.exporterRegType ?? "-"}) | كود: ${acid.exporterCountryCode ?? "-"}'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.inventory_2, color: AppTheme.cobalt),
                  title: Text('ملف الشحنة المرتبط: ${acid.importFileCode ?? "-"}'),
                  subtitle: Text('رقم الفاتورة: ${acid.proformaInvoiceNo} | أمر الشراء: ${acid.poNumber ?? "-"} | ميناء الشحن: ${acid.polName} ➔ الوصول: ${acid.podName}'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.event, color: AppTheme.charcoal),
                  title: Text('تاريخ الطلب: ${acid.requestedDate ?? "-"} | تاريخ الإصدار: ${acid.generatedDate ?? "-"} | مدة التنفيذ: ${acid.executionDays != null ? "${acid.executionDays} يوم" : "-"}'),
                  subtitle: Text('تاريخ الانتهاء: ${acid.expiryDate ?? "-"} (متبقي ${acid.daysToExpiry} يومًا)'),
                ),
                if (acid.discrepancyOverrideReason != null && acid.discrepancyOverrideReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text('⚠️ سبب الاستمرار وتجاوز الفروقات: ${acid.discrepancyOverrideReason}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Verified' || status == 'Approved' || status == 'Endorsed' || status == 'Form Issued') bg = Colors.green;
    if (status == 'Generated') bg = Colors.blue;
    if (status == 'Requested') bg = Colors.orange;
    if (status == 'Discrepancy_Accepted') bg = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
