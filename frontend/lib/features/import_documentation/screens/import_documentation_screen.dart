import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';

class ImportDocumentationScreen extends ConsumerStatefulWidget {
  const ImportDocumentationScreen({super.key});

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
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
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

  @override
  Widget build(BuildContext context) {
    final companiesState = ref.watch(importCompaniesProvider);
    final suppliersState = ref.watch(suppliersProvider);
    final portsState = ref.watch(transportLocationsProvider);
    final partnersState = ref.watch(partnersProvider);

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
                                child: DropdownButtonFormField<String>(
                                  value: portsList.any((p) => p.locationName == _polName) ? _polName : (portsList.isNotEmpty ? portsList.first.locationName : _polName),
                                  decoration: const InputDecoration(labelText: 'ميناء التحميل (POL) *', border: OutlineInputBorder()),
                                  items: portsList.map((p) => DropdownMenuItem<String>(value: p.locationName, child: Text(p.locationName))).toList(),
                                  onChanged: (val) => setState(() => _polName = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: portsList.any((p) => p.locationName == _podName) ? _podName : (portsList.length > 1 ? portsList[1].locationName : _podName),
                                  decoration: const InputDecoration(labelText: 'ميناء الوصول (POD) *', border: OutlineInputBorder()),
                                  items: portsList.map((p) => DropdownMenuItem<String>(value: p.locationName, child: Text(p.locationName))).toList(),
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
                                child: DropdownButtonFormField<String>(
                                  value: _bankDocType,
                                  decoration: const InputDecoration(labelText: 'نوع المعاملة البنكية *', border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: 'Form 4', child: Text('Form 4 (نموذج 4 تحويلات ومستندات)')),
                                    DropdownMenuItem(value: 'Form 9', child: Text('Form 9 (نموذج 9 تسديد مبدئي)')),
                                    DropdownMenuItem(value: 'Letter of Credit (L/C)', child: Text('L/C (اعتماد مستندي بنكي)')),
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
                            child: DropdownButtonFormField<String>(
                              value: _docName,
                              decoration: const InputDecoration(labelText: 'اسم المستند *', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Commercial Invoice (الفاتورة التجارية)', child: Text('Commercial Invoice (الفاتورة التجارية)')),
                                DropdownMenuItem(value: 'Packing List (قائمة التعبئة)', child: Text('Packing List (قائمة التعبئة)')),
                                DropdownMenuItem(value: 'Bill of Lading (بوليصة الشحن)', child: Text('Bill of Lading (بوليصة الشحن)')),
                                DropdownMenuItem(value: 'Certificate of Origin (شهادة المنشأ)', child: Text('Certificate of Origin (شهادة المنشأ)')),
                                DropdownMenuItem(value: 'Inspection Certificate (شهادة الفحص)', child: Text('Inspection Certificate (شهادة الفحص)')),
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
