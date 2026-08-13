import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
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

  // ACID Form State (BP-014)
  final _acidFormKey = GlobalKey<FormState>();
  final TextEditingController _acidNumController = TextEditingController(text: '1987654321098765432');
  final TextEditingController _importerTaxIdController = TextEditingController(text: '100-200-300');
  final TextEditingController _exporterRegIdController = TextEditingController(text: 'CN-SH-987654');
  final TextEditingController _exporterCountryController = TextEditingController(text: 'China');
  final TextEditingController _proformaNoController = TextEditingController(text: 'PI-2026-SH09');
  final TextEditingController _notesController = TextEditingController();

  int? _acidSelectedImportFileId;
  int? _selectedImporterId;
  String _importerName = 'المصرية الحديثة للتنسيج والغزل ش.م.م';
  int? _selectedSupplierId;
  String _exporterName = 'Shanghai Machinery & Textile Exports Ltd.';
  String _polName = 'Shanghai Port (CN SHA), China';
  String _podName = 'Alexandria Port (EG ALX), Egypt';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 90));
  bool _isSavingAcid = false;

  // Form 4 State (BP-015)
  final _bankFormKey = GlobalKey<FormState>();
  final TextEditingController _bankRefController = TextEditingController(text: 'F4-2026-99081');
  final TextEditingController _bankAmountController = TextEditingController(text: '62300.0');
  String _bankDocType = 'Form 4';
  int? _selectedBankId;
  String _bankName = 'National Bank of Egypt (NBE)';

  // Document Registry State (BP-016 to BP-018)
  final _docFormKey = GlobalKey<FormState>();
  final TextEditingController _docNumController = TextEditingController(text: 'INV-2026-SH990');
  String _docName = 'Commercial Invoice (الفاتورة التجارية)';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      ref.read(partnersProvider.notifier).fetchPartners();
      ref.read(transportLocationsProvider.notifier).fetchLocations();
      ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
      ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
      ref.read(shipmentDocumentsProvider.notifier).fetchShipmentDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _acidNumController.dispose();
    _importerTaxIdController.dispose();
    _exporterRegIdController.dispose();
    _exporterCountryController.dispose();
    _proformaNoController.dispose();
    _notesController.dispose();
    _bankRefController.dispose();
    _bankAmountController.dispose();
    _docNumController.dispose();
    super.dispose();
  }

  Future<void> _saveAcidSession() async {
    if (!_acidFormKey.currentState!.validate()) return;

    setState(() => _isSavingAcid = true);
    try {
      final payload = {
        'acid_number': _acidNumController.text.trim(),
        'import_file_id': _acidSelectedImportFileId,
        'importer_id': _selectedImporterId,
        'importer_name': _importerName,
        'importer_tax_id': _importerTaxIdController.text.trim(),
        'supplier_id': _selectedSupplierId,
        'exporter_name': _exporterName,
        'exporter_reg_id': _exporterRegIdController.text.trim(),
        'exporter_country': _exporterCountryController.text.trim(),
        'proforma_invoice_no': _proformaNoController.text.trim(),
        'pol_name': _polName,
        'pod_name': _podName,
        'expiry_date': _expiryDate.toString().substring(0, 10),
        'verification_notes': _notesController.text.trim(),
      };

      final created = await ref.read(acidSessionsProvider.notifier).createAcidSession(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم تسجيل وتدقيق رقم الـ ACID بنجاح! كود الجلسة: ${created.acidCode}'), backgroundColor: AppTheme.emerald),
        );
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ أثناء التسجيل: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAcid = false);
    }
  }

  Future<void> _saveBankingDoc() async {
    if (!_bankFormKey.currentState!.validate()) return;

    try {
      final payload = {
        'doc_type': _bankDocType,
        'bank_id': _selectedBankId,
        'bank_name': _bankName,
        'doc_reference_number': _bankRefController.text.trim(),
        'amount': double.tryParse(_bankAmountController.text.trim()) ?? 0.0,
        'currency_code': 'USD',
        'issue_date': DateTime.now().toString().substring(0, 10),
      };

      final created = await ref.read(bankingDocumentsProvider.notifier).createBankingDocument(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم تسجيل المستند البنكي بنجاح: ${created.bankDocCode}'), backgroundColor: AppTheme.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
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
              child: Text(
                'تفاصيل رقم الـ ACID: ${acid.acidCode}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
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
                          'رقم الـ ACID (منصة نافذة): ${acid.acidNumber}',
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
                  title: Text('المستورد: ${acid.importerName}'),
                  subtitle: Text('رقم التسجيل الضريبي: ${acid.importerTaxId}'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.public, color: AppTheme.charcoal),
                  title: Text('المصدر الأجنبي: ${acid.exporterName} (${acid.exporterCountry})'),
                  subtitle: Text('رقم السجل التجاري: ${acid.exporterRegId}'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.receipt_long, color: AppTheme.charcoal),
                  title: Text('رقم الفاتورة المبدئية (PI): ${acid.proformaInvoiceNo}'),
                  subtitle: Text('ميناء التحميل: ${acid.polName} | ميناء الوصول: ${acid.podName}'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.event, color: AppTheme.charcoal),
                  title: Text('تاريخ الصلاحية: ${acid.expiryDate} (متبقي ${acid.daysToExpiry} يومًا)'),
                  subtitle: Text('تاريخ الطلب: ${acid.requestedDate} | حالة المطابقة: ${acid.status}'),
                ),
                if (acid.verificationNotes != null && acid.verificationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('ملاحظات وتدقيق: ${acid.verificationNotes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companiesState = ref.watch(importCompaniesProvider);
    final suppliersState = ref.watch(suppliersProvider);
    final portsState = ref.watch(transportLocationsProvider);
    final partnersState = ref.watch(partnersProvider);

    final acidSessionsState = ref.watch(acidSessionsProvider);
    final bankingDocsState = ref.watch(bankingDocumentsProvider);
    final shipmentDocsState = ref.watch(shipmentDocumentsProvider);

    final companiesList = companiesState.value ?? [];
    final suppliersList = suppliersState.value ?? [];
    final portsList = portsState.value ?? [];
    final banksList = (partnersState.value ?? []).where((p) => p.partnerType.contains('Bank')).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('مستندات الاستيراد والتسجيل الحكومي ACI (Phase 3 – Import Documentation & Nafeza)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
            Tab(icon: Icon(Icons.qr_code), text: 'ACID & Nafeza (BP-014 تسجيل نافذة)'),
            Tab(icon: Icon(Icons.account_balance), text: 'Form 4 & Banking (BP-015 المعاملات البنكية)'),
            Tab(icon: Icon(Icons.folder_shared), text: 'Shipment Docs & CargoX (BP-016/018 السجل الرقمي)'),
            Tab(icon: Icon(Icons.description), text: 'Declaration 46 (BP-019 إقرار 46 جمارك)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ACID & NAFEZA WORKSPACE (BP-014)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _acidFormKey,
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
                          const Text('تسجيل ومطابقة رقم التسجيل المسبق للشحنات ACID (Nafeza ACI Registration)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _acidSelectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية)',
                                  searchHintText: 'ابحث عن ملف الشحنة...',
                                  items: [
                                    const SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- None / غير مرتبط بملف شحنة --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                          subtitle: f.companyName,
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _acidSelectedImportFileId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _acidNumController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'رقم الـ ACID (19 رقمًا) *', border: OutlineInputBorder()),
                                  validator: (v) {
                                    if (v == null || v.trim().length != 19 || int.tryParse(v.trim()) == null) {
                                      return 'رقم الـ ACID يجب أن يتكون من 19 رقمًا بالضبط';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _proformaNoController,
                                  decoration: const InputDecoration(labelText: 'رقم الفاتورة المبدئية (PI No) *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم الفاتورة' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                    if (d != null) setState(() => _expiryDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'تاريخ انتهاء ACID *', border: OutlineInputBorder()),
                                    child: Text(_expiryDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImporterId,
                                  labelText: 'الشركة المستوردة المصرية *',
                                  searchHintText: 'ابحث عن الشركة المستوردة...',
                                  items: companiesList
                                      .map((c) => SearchableDropdownItem<int?>(
                                            value: c.companyId,
                                            label: c.importerName,
                                            subtitle: 'ضريبي: ${c.vatId}',
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final c = companiesList.firstWhere((comp) => comp.companyId == val);
                                      setState(() {
                                        _selectedImporterId = val;
                                        _importerName = c.importerName;
                                        _importerTaxIdController.text = c.vatId;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _importerTaxIdController,
                                  decoration: const InputDecoration(labelText: 'رقم التسجيل الضريبي للمستورد *', border: OutlineInputBorder()),
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
                                  labelText: 'المورد الأجنبي (Foreign Exporter) *',
                                  searchHintText: 'ابحث عن المورد الأجنبي...',
                                  items: suppliersList
                                      .map((s) => SearchableDropdownItem<int?>(
                                            value: s.supplierId,
                                            label: s.companyName,
                                            subtitle: s.foreignExporterCountry,
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final s = suppliersList.firstWhere((sup) => sup.supplierId == val);
                                      setState(() {
                                        _selectedSupplierId = val;
                                        _exporterName = s.companyName;
                                        _exporterRegIdController.text = s.foreignExporterId;
                                        _exporterCountryController.text = s.foreignExporterCountry;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _exporterRegIdController,
                                  decoration: const InputDecoration(labelText: 'رقم التسجيل التجاري للمورد الأجنبي *', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _exporterCountryController,
                                  decoration: const InputDecoration(labelText: 'دولة المورد *', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: portsList.any((p) => p.locationName == _polName) ? _polName : (portsList.isNotEmpty ? portsList.first.locationName : _polName),
                                  labelText: 'ميناء التحميل (POL) *',
                                  items: portsList.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName)).toList(),
                                  onChanged: (val) => setState(() => _polName = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: portsList.any((p) => p.locationName == _podName) ? _podName : (portsList.length > 1 ? portsList[1].locationName : _podName),
                                  labelText: 'ميناء الوصول (POD) *',
                                  items: portsList.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName)).toList(),
                                  onChanged: (val) => setState(() => _podName = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(labelText: 'ملاحظات وتدقيق الـ ACID', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),

                          // 7-Point Match Checklist Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade300)),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('جدول المطابقة التلقائية: بيانات المستورد الضريبية، بيانات المصدر الأجنبي، رقم الفاتورة المبدئية، وموانئ الإبحار والوصول متطابقة 100% مع منصة نافذة.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                              onPressed: _isSavingAcid ? null : _saveAcidSession,
                              icon: _isSavingAcid ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified, color: Colors.white),
                              label: const Text('اعتماد ومطابقة رقم الـ ACID الشامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ACID REGISTRY DATATABLE
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.format_list_bulleted, color: AppTheme.cobalt),
                                  SizedBox(width: 8),
                                  Text(
                                    'سجل أرقام الـ ACID المعتمدة والمسجلة (ACID Registration Registry)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          acidSessionsState.when(
                            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                            error: (err, _) => Center(child: Text('❌ خطأ في تحميل السجل: $err')),
                            data: (sessions) {
                              if (sessions.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(child: Text('لا توجد أرقام ACID مسجلة في السجل الحالي.')),
                                );
                              }
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                  columns: const [
                                    DataColumn(label: Text('⚡ العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('كود ACID', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('رقم ACID نافذة (19 رقم)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('المستورد', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('المصدر الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('رقم الفاتورة PI', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('تاريخ الانتهاء', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('أيام الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('الحالة والمطابقة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: sessions.map((sess) {
                                    final isExpired = sess.daysToExpiry <= 0;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility, color: AppTheme.cobalt, size: 18),
                                                tooltip: 'عرض التفاصيل',
                                                onPressed: () => _showAcidDetailsDialog(context, sess),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  sess.isActive ? Icons.delete_outline : Icons.restore,
                                                  color: sess.isActive ? Colors.red : Colors.green,
                                                  size: 18,
                                                ),
                                                tooltip: sess.isActive ? 'حذف' : 'استعادة',
                                                onPressed: () async {
                                                  if (sess.isActive) {
                                                    await ref.read(acidSessionsProvider.notifier).softDeleteAcidSession(sess.acidId);
                                                  } else {
                                                    await ref.read(acidSessionsProvider.notifier).restoreAcidSession(sess.acidId);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(sess.acidCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                        DataCell(Text(sess.acidNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(sess.importFileCode ?? (sess.importFileId != null ? 'File #${sess.importFileId}' : 'مستقل'))),
                                        DataCell(Text(sess.importerName)),
                                        DataCell(Text('${sess.exporterName} (${sess.exporterCountry})')),
                                        DataCell(Text(sess.proformaInvoiceNo)),
                                        DataCell(Text(sess.expiryDate)),
                                        DataCell(
                                          Chip(
                                            label: Text(
                                              isExpired ? 'منتهي' : '${sess.daysToExpiry} يومًا',
                                              style: TextStyle(fontSize: 10, color: isExpired ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: isExpired ? Colors.red : Colors.amber.shade200,
                                          ),
                                        ),
                                        DataCell(
                                          Chip(
                                            avatar: const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                            label: Text(sess.status, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                            backgroundColor: AppTheme.emerald,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 2: FORM 4 & BANKING OPERATIONS (BP-015)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _bankFormKey,
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
                          const Text('إصدار وتتبع نموذج 4 البنكي / نموذج 9 / الاعتماد المستندي (BP-015 Form 4 Operations)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: _bankDocType,
                                  labelText: 'نوع المعاملة البنكية *',
                                  items: const [
                                    SearchableDropdownItem(value: 'Form 4', label: 'Form 4 (نموذج 4 تحويلات ومستندات)'),
                                    SearchableDropdownItem(value: 'Form 9', label: 'Form 9 (نموذج 9 تسديد مبدئي)'),
                                    SearchableDropdownItem(value: 'Letter of Credit (L/C)', label: 'L/C (اعتماد مستندي بنكي)'),
                                  ],
                                  onChanged: (val) => setState(() => _bankDocType = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedBankId,
                                  labelText: 'البنك المصري المعالج *',
                                  searchHintText: 'ابحث عن البنك المصرفي...',
                                  items: banksList
                                      .map((b) => SearchableDropdownItem<int?>(
                                            value: b.providerId,
                                            label: b.partnerName,
                                            subtitle: b.partnerType,
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final b = banksList.firstWhere((bk) => bk.providerId == val);
                                      setState(() {
                                        _selectedBankId = val;
                                        _bankName = b.partnerName;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _bankRefController,
                                  decoration: const InputDecoration(labelText: 'رقم المرجع البنكي / رقم نموذج 4 *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم المرجع' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bankAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'المبلغ المغطى بالنموذج (USD) *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغاً صحيحاً' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                              onPressed: _saveBankingDoc,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('تسجيل النموذج البنكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BANKING DOCUMENTS DATATABLE
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: AppTheme.cobalt),
                              SizedBox(width: 8),
                              Text(
                                'سجل المعاملات والنماذج البنكية المسجلة (Banking Documents & Form 4 Registry)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              ),
                            ],
                          ),
                          const Divider(),
                          bankingDocsState.when(
                            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                            error: (err, _) => Center(child: Text('❌ خطأ في تحميل السجل البنكي: $err')),
                            data: (bDocs) {
                              if (bDocs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(child: Text('لا توجد نماذج بنكية مسجلة بالسجل.')),
                                );
                              }
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                  columns: const [
                                    DataColumn(label: Text('كود السجل', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('نوع المعاملة', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('البنك المصري المعالج', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('رقم المرجع / نموذج 4', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('المبلغ المغطى', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('تاريخ الإصدار', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('الحالة البنكية', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: bDocs.map((doc) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(doc.bankDocCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                        DataCell(Chip(label: Text(doc.docType, style: const TextStyle(fontSize: 11)), backgroundColor: Colors.blue.shade50)),
                                        DataCell(Text(doc.bankName)),
                                        DataCell(Text(doc.docReferenceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text('${doc.amount.toStringAsFixed(2)} ${doc.currencyCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                        DataCell(Text(doc.issueDate)),
                                        DataCell(_buildStatusBadge(doc.status)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 3: SHIPMENT DOCS REGISTRY & CARGOX (BP-016 to BP-018)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _docFormKey,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SearchableDropdownField<String>(
                              value: _docName,
                              labelText: 'اسم المستند *',
                              items: const [
                                SearchableDropdownItem(value: 'Commercial Invoice (الفاتورة التجارية)', label: 'Commercial Invoice (الفاتورة التجارية)'),
                                SearchableDropdownItem(value: 'Packing List (قائمة التعبئة)', label: 'Packing List (قائمة التعبئة)'),
                                SearchableDropdownItem(value: 'Bill of Lading (بوليصة الشحن)', label: 'Bill of Lading (بوليصة الشحن)'),
                                SearchableDropdownItem(value: 'Certificate of Origin (شهادة المنشأ)', label: 'Certificate of Origin (شهادة المنشأ)'),
                                SearchableDropdownItem(value: 'Inspection Certificate (شهادة الفحص)', label: 'Inspection Certificate (شهادة الفحص)'),
                              ],
                              onChanged: (v) => setState(() => _docName = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _docNumController,
                              decoration: const InputDecoration(labelText: 'رقم المستند الرسمي *', border: OutlineInputBorder()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم المستند' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                            onPressed: _saveShipmentDoc,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('إضافة مستند للسجل', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: shipmentDocsState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('❌ Error: $err')),
                    data: (docs) {
                      if (docs.isEmpty) {
                        return const Center(child: Text('لا توجد مستندات مسجلة بالسجل الرقمي.'));
                      }
                      return SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: const [
                            DataColumn(label: Text('كود المستند', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('نوع المستند', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('رقم المستند', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('رفع CargoX', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('التظهير الملاحي (B/L)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: docs.map((doc) {
                            return DataRow(
                              cells: [
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
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: AppTheme.cobalt),
                                    onPressed: () => _showCargoxAndBLEndorsementDialog(doc),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // TAB 4: DECLARATION 46 PREPARATION (BP-019)
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Card(
                elevation: 2,
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
                            Text('رقم التسجيل المسبق ACID: 1987654321098765432', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Verified' || status == 'Approved' || status == 'Endorsed' || status == 'Form Issued') bg = Colors.green;
    if (status == 'Generated') bg = Colors.blue;
    if (status == 'Requested') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
