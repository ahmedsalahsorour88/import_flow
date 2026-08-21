import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/cargox_model.dart';
import '../providers/cargox_provider.dart';
import '../widgets/standard_invoice_hub_tab.dart';

class CargoXHubScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;
  final bool isEmbedded;

  const CargoXHubScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<CargoXHubScreen> createState() => _CargoXHubScreenState();
}

class _CargoXHubScreenState extends ConsumerState<CargoXHubScreen> {
  int _selectedSubTab = 0;
  int? _selectedImportFileId;

  // Form State for Tab 0 (Create Envelope)
  final _envelopeFormKey = GlobalKey<FormState>();
  final TextEditingController _acidNumberCtrl = TextEditingController();
  final TextEditingController _importerNameCtrl = TextEditingController();
  final TextEditingController _importerTaxCtrl = TextEditingController();
  final TextEditingController _supplierNameCtrl = TextEditingController();
  final TextEditingController _supplierCargoXIdCtrl = TextEditingController();
  final TextEditingController _blNumberCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  int? _selectedCompanyId;
  int? _selectedSupplierId;
  bool _isSavingEnvelope = false;

  // Attached Documents State for Creation
  List<Map<String, dynamic>> _attachedDocs = [];

  // Tab 1: Filter & Search
  String _searchQuery = '';
  String _statusFilter = 'All';

  DigitalManifestModel? _activeDigitalManifest;
  bool _isLoadingManifest = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedImportFileId = widget.initialImportFileId;

    _initDefaultAttachedDocs();

    Future.microtask(() {
      _refreshData();
      if (_selectedImportFileId != null) {
        _onImportFileSelected(_selectedImportFileId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CargoXHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      setState(() => _selectedSubTab = widget.initialSubTab);
    }
    if (widget.initialImportFileId != null && widget.initialImportFileId != _selectedImportFileId) {
      setState(() => _selectedImportFileId = widget.initialImportFileId);
      _onImportFileSelected(widget.initialImportFileId);
    }
  }

  void _initDefaultAttachedDocs() {
    _attachedDocs = [
      {
        'doc_type': 'Commercial Invoice',
        'doc_number': 'INV-2026-FINAL',
        'file_name': 'Commercial_Invoice_Final.pdf',
        'file_size_kb': 420.0,
        'is_mandatory': true,
        'verified_against_acid': true,
      },
      {
        'doc_type': 'Packing List',
        'doc_number': 'PL-2026-FINAL',
        'file_name': 'Packing_List_Final.pdf',
        'file_size_kb': 310.0,
        'is_mandatory': true,
        'verified_against_acid': true,
      },
      {
        'doc_type': 'Draft B/L',
        'doc_number': 'MEDUST982145',
        'file_name': 'Bill_of_Lading_Official.pdf',
        'file_size_kb': 650.0,
        'is_mandatory': true,
        'verified_against_acid': true,
      },
      {
        'doc_type': 'Certificate of Origin / EUR.1',
        'doc_number': 'COO-EG-9981',
        'file_name': 'Certificate_of_Origin_EUR1.pdf',
        'file_size_kb': 280.0,
        'is_mandatory': false,
        'verified_against_acid': true,
      },
    ];
  }

  void _refreshData() {
    ref.read(cargoxEnvelopesProvider.notifier).fetchEnvelopes();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(suppliersProvider.notifier).fetchSuppliers();
    ref.read(importCompaniesProvider.notifier).fetchCompanies();
  }

  @override
  void dispose() {
    _acidNumberCtrl.dispose();
    _importerNameCtrl.dispose();
    _importerTaxCtrl.dispose();
    _supplierNameCtrl.dispose();
    _supplierCargoXIdCtrl.dispose();
    _blNumberCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onImportFileSelected(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) return;

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    // Auto-populate ACID
    if (file.acidNumber != null && file.acidNumber!.isNotEmpty) {
      _acidNumberCtrl.text = file.acidNumber!;
    } else {
      _acidNumberCtrl.text = '7595528271020210010';
    }

    // Auto-populate Importer
    _selectedCompanyId = file.companyId;
    _importerNameCtrl.text = file.companyName;

    // Auto-populate Supplier & CargoX ID
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final matchedSup = suppliers.where((s) => s.supplierId == file.supplierId).firstOrNull;
    if (matchedSup != null) {
      _selectedSupplierId = matchedSup.supplierId;
      _supplierNameCtrl.text = matchedSup.companyName;
      _supplierCargoXIdCtrl.text = matchedSup.cargoxPlatformId != null && matchedSup.cargoxPlatformId!.isNotEmpty
          ? matchedSup.cargoxPlatformId!
          : 'CX-${matchedSup.supplierCode}';
    } else {
      _supplierNameCtrl.text = file.supplierName;
      _supplierCargoXIdCtrl.text = 'CX-SUP-DEFAULT';
    }

    _blNumberCtrl.text = file.customFileNumber != null ? 'BL-${file.customFileNumber}' : 'MEDUST-${file.importFileCode}';
  }

  @override
  Widget build(BuildContext context) {
    final envelopesState = ref.watch(cargoxEnvelopesProvider);
    final envelopes = envelopesState.value ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.table_chart_outlined,
        titleEn: 'Standard Commercial Invoice',
        titleAr: 'الفاتورة المعيارية Excel والمطابقة',
      ),
      const VerticalNavTabItem(
        icon: Icons.markunread_mailbox_outlined,
        titleEn: 'Create CargoX Envelope',
        titleAr: 'تجهيز وتوليد مظروف جديد',
      ),
      VerticalNavTabItem(
        icon: Icons.hub_outlined,
        titleEn: 'Blockchain Envelopes Hub',
        titleAr: 'مركز تتبع أظرف البلوك تشين',
        badge: envelopes.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${envelopes.length}',
                  style: const TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      const VerticalNavTabItem(
        icon: Icons.description_outlined,
        titleEn: 'ACI Digital Manifest Viewer',
        titleAr: 'معاينة وتصدير المانيفست الرقمي',
      ),
    ];

    final bodyContent = IndexedStack(
      index: _selectedSubTab,
      children: [
        StandardInvoiceHubTab(initialImportFileId: _selectedImportFileId),
        _buildCreateEnvelopeTab(),
        _buildEnvelopesTrackingTab(envelopes),
        _buildDigitalManifestViewerTab(envelopes),
      ],
    );

    if (widget.isEmbedded) {
      return Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.hub_outlined, color: AppTheme.cobalt, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'منظومة كارجو إكس والبلوك تشين (CargoX & ACI Dispatch Hub):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                  ),
                  const SizedBox(width: 24),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('الفاتورة المعيارية 📊', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 1, label: Text('تجهيز المظروف 📦', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 2, label: Text('تتبع البلوك تشين 🔗', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 3, label: Text('المانيفست الرقمي 📜', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_selectedSubTab},
                    onSelectionChanged: (set) => setState(() => _selectedSubTab = set.first),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: bodyContent),
        ],
      );
    }

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'CargoX & ACI Blockchain Dispatch Hub',
      titleAr: 'منظومة كارجو إكس والبلوك تشين والمانيفست الرقمي',
      headerIcon: Icons.hub_outlined,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (idx) => setState(() => _selectedSubTab = idx),
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'Live Refresh (تحديث حي)',
          onPressed: _refreshData,
        ),
      ],
      body: bodyContent,
    );
  }

  // ── TAB 0: CREATE & SIGN ENVELOPE ───────────────────────────────────────────
  Widget _buildCreateEnvelopeTab() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _envelopeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.cobalt.withOpacity(0.12), Colors.blue.shade50],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.cobalt, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تجهيز وتوليد مظروف كارجو إكس المشفر (CargoX Blockchain Envelope Generator)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'يتم إنشاء المظروف الرقمي وتوقيعه إلكترونياً بالتشفير (PKI) وربطه برقم الـ ACID ومستندات الشحن المعتمدة قبل التحويل لمصلحة الجمارك المصرية.',
                          style: TextStyle(fontSize: 11.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card 1: Main Identification
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined, color: AppTheme.cobalt, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '1. بيانات الشحنة والربط مع منظومة التسجيل المسبق (ACID & Import File):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SearchableDropdownField<int?>(
                            value: _selectedImportFileId,
                            labelText: 'Import File (ملف الشحنة الاستيرادية) *',
                            searchHintText: 'ابحث عن ملف الشحنة...',
                            items: [
                              const SearchableDropdownItem<int?>(
                                value: null,
                                label: '-- None / غير مرتبط بملف شحنة --',
                              ),
                              ...importFiles.map((f) => SearchableDropdownItem<int?>(
                                    value: f.importFileId,
                                    label: '${f.importFileCode} — ${f.supplierName} (${f.companyName})',
                                  )),
                            ],
                            onChanged: _onImportFileSelected,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _acidNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رقم الـ ACID الجمركي (19 رقماً) *',
                              prefixIcon: Icon(Icons.qr_code_2, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'مطلوب';
                              final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length != 19) return 'يجب أن يتكون من 19 رقماً';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _blNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رقم بوليصة الشحن (B/L Number)',
                              prefixIcon: Icon(Icons.directions_boat_outlined, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _importerNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'الشركة المستوردة (Importer Company) *',
                              prefixIcon: Icon(Icons.business_outlined, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _supplierNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'المورد الأجنبي (Foreign Exporter) *',
                              prefixIcon: Icon(Icons.factory_outlined, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _supplierCargoXIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'معرف منصة CargoX للمورد (CargoX ID) *',
                              prefixIcon: Icon(Icons.fingerprint, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Attached Documents Matrix
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.checklist_rtl_outlined, color: AppTheme.emerald, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '2. قائمة المستندات المحملة داخل المظروف (Attached Documents Checklist):',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.restore_page, size: 16),
                            label: const Text('استعادة القائمة القياسية 📄', style: TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _initDefaultAttachedDocs()),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Documents Table
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(2.2),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(2.5),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(1.5),
                        5: FlexColumnWidth(1.0),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: AppTheme.charcoal),
                          children: [
                            Padding(padding: EdgeInsets.all(8), child: Text('نوع المستند', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('رقم المرجع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('اسم الملف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الحجم (KB)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('مطابقة ACID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        ..._attachedDocs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final doc = entry.value;
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Text(doc['doc_type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                              Padding(padding: const EdgeInsets.all(8), child: Text(doc['doc_number'] ?? '-', style: const TextStyle(fontSize: 11.5))),
                              Padding(padding: const EdgeInsets.all(8), child: Text(doc['file_name'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${doc['file_size_kb']} KB', style: const TextStyle(fontSize: 11.5))),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: const Text('🟢 100% مطابق', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _attachedDocs.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: AppTheme.charcoal,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة مستند جديد للمظروف', style: TextStyle(fontSize: 11.5)),
                      onPressed: _showAddDocumentDialog,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isSavingEnvelope
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.security, size: 20, color: Colors.amber),
                  label: const Text(
                    'توليد وتوقيع مظروف CargoX بالبلوك تشين ⚡ (Generate & Sign Envelope)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _isSavingEnvelope ? null : _submitCreateEnvelope,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDocumentDialog() {
    final typeCtrl = TextEditingController(text: 'Certificate of Analysis (COA)');
    final numCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: 'Analysis_Report.pdf');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مستند جديد للمظروف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'نوع المستند *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'رقم المستند', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الملف *', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            onPressed: () {
              if (typeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              setState(() {
                _attachedDocs.add({
                  'doc_type': typeCtrl.text.trim(),
                  'doc_number': numCtrl.text.trim(),
                  'file_name': nameCtrl.text.trim(),
                  'file_size_kb': 250.0,
                  'is_mandatory': false,
                  'verified_against_acid': true,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('إضافة للمظروف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCreateEnvelope() async {
    if (!_envelopeFormKey.currentState!.validate()) return;
    if (_attachedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة مستند واحد على الأقل داخل المظروف'), backgroundColor: AppTheme.orange),
      );
      return;
    }

    setState(() => _isSavingEnvelope = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'acid_number': _acidNumberCtrl.text.trim(),
        'importer_company_id': _selectedCompanyId,
        'importer_company_name': _importerNameCtrl.text.trim(),
        'importer_tax_number': _importerTaxCtrl.text.trim(),
        'supplier_id': _selectedSupplierId,
        'supplier_name': _supplierNameCtrl.text.trim(),
        'supplier_cargox_id': _supplierCargoXIdCtrl.text.trim(),
        'bl_number': _blNumberCtrl.text.trim().isNotEmpty ? _blNumberCtrl.text.trim() : null,
        'notes': _notesCtrl.text.trim(),
        'documents': _attachedDocs,
        'mode': 'MOCK',
      };

      final created = await ref.read(cargoxEnvelopesProvider.notifier).createEnvelope(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم توليد وتوقيع مظروف CargoX بنجاح (${created.envelopeCode}) ⚡'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        setState(() => _selectedSubTab = 1);
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ أثناء إنشاء المظروف', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSavingEnvelope = false);
    }
  }

  // ── TAB 1: BLOCKCHAIN ENVELOPES TRACKING HUB ────────────────────────────────
  Widget _buildEnvelopesTrackingTab(List<CargoXEnvelopeModel> envelopes) {
    final filtered = envelopes.where((e) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final matches = e.envelopeCode.toLowerCase().contains(q) ||
            e.acidNumber.toLowerCase().contains(q) ||
            e.supplierName.toLowerCase().contains(q) ||
            (e.blNumber != null && e.blNumber!.toLowerCase().contains(q)) ||
            (e.importFileCode != null && e.importFileCode!.toLowerCase().contains(q));
        if (!matches) return false;
      }
      if (_statusFilter != 'All' && e.status != _statusFilter) return false;
      return true;
    }).toList();

    final totalCount = envelopes.length;
    final acceptedCount = envelopes.where((e) => e.status == 'ACCEPTED_BY_CUSTOMS').length;
    final uploadedCount = envelopes.where((e) => e.status == 'UPLOADED_BY_SUPPLIER' || e.status == 'DRAFT').length;
    final verifiedCount = envelopes.where((e) => e.isAcidVerified).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Cards
          Row(
            children: [
              _buildMetricCard('إجمالي المظاريف (Total Envelopes)', '$totalCount', AppTheme.cobalt, Icons.markunread_mailbox),
              const SizedBox(width: 12),
              _buildMetricCard('تم قبولها بالجمارك (Accepted by Customs)', '$acceptedCount', AppTheme.emerald, Icons.verified),
              const SizedBox(width: 12),
              _buildMetricCard('قيد المعالجة (In Progress / Uploaded)', '$uploadedCount', AppTheme.orange, Icons.hourglass_top),
              const SizedBox(width: 12),
              _buildMetricCard('مطابقة الـ ACID بنسبة 100%', '$verifiedCount', Colors.purple, Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 18),

          // Search & Filter Toolbar
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'ابحث برقم المظروف، رقم الـ ACID، المورد، أو البوليصة...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 14),
                  DropdownButton<String>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('جميع الحالات (All Statuses)')),
                      DropdownMenuItem(value: 'DRAFT', child: Text('مسودة (Draft)')),
                      DropdownMenuItem(value: 'UPLOADED_BY_SUPPLIER', child: Text('مرفوع بالبلوك تشين (Uploaded)')),
                      DropdownMenuItem(value: 'ACCEPTED_BY_CUSTOMS', child: Text('مقبول بالجمارك (Accepted)')),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val ?? 'All'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('تجهيز مظروف جديد ➕', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                    onPressed: () => setState(() => _selectedSubTab = 0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Envelopes List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: const Center(
                child: Text('لا توجد مظاريف مطابقة لشروط البحث', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            )
          else
            ...filtered.map((env) => _buildEnvelopeCard(env)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvelopeCard(CargoXEnvelopeModel env) {
    final isAccepted = env.status == 'ACCEPTED_BY_CUSTOMS';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.markunread_mailbox, color: AppTheme.cobalt, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      env.envelopeCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                    ),
                    const SizedBox(width: 10),
                    if (env.importFileCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                        child: Text(env.importFileCode!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      ),
                  ],
                ),
                _buildStatusBadge(env.status),
              ],
            ),
            const Divider(height: 18),

            // Metadata Grid
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildMetaItem('رقم الـ ACID الجمركي:', env.acidNumber, isCopyable: true),
                _buildMetaItem('المورد الأجنبي:', env.supplierName),
                _buildMetaItem('معرف CargoX للمورد:', env.supplierCargoxId),
                _buildMetaItem('رقم البوليصة:', env.blNumber ?? 'قيد الإصدار'),
                if (env.blockchainTxHash != null)
                  _buildMetaItem('Blockchain TX Hash:', '${env.blockchainTxHash!.substring(0, 16)}...', isCopyable: true, fullValue: env.blockchainTxHash),
                if (env.customsConfirmationReceipt != null)
                  _buildMetaItem('إيصال الجمارك:', env.customsConfirmationReceipt!, isCopyable: true),
              ],
            ),
            const SizedBox(height: 12),

            // Documents chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: env.documents.map((d) {
                return Chip(
                  avatar: const Icon(Icons.attach_file, size: 14, color: AppTheme.cobalt),
                  label: Text('${d.docType} (${d.fileName})', style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.grey.shade100,
                  padding: const EdgeInsets.all(4),
                );
              }).toList(),
            ),
            const Divider(height: 18),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.verified_outlined, size: 15, color: Colors.purple),
                  label: const Text('فحص الـ ACID 🛡️', style: TextStyle(fontSize: 11, color: Colors.purple)),
                  onPressed: () => _runAcidVerification(env.envelopeId),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.receipt_long, size: 15, color: AppTheme.cobalt),
                  label: const Text('المانيفست الرقمي 📜', style: TextStyle(fontSize: 11, color: AppTheme.cobalt)),
                  onPressed: () => _viewManifest(env),
                ),
                const SizedBox(width: 8),
                if (!isAccepted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.send_to_mobile, size: 15, color: Colors.white),
                    label: const Text('إغلاق وتحويل للجمارك ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _sealAndTransfer(env),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade300)),
                    child: const Text('🟢 تم التسليم والاعتماد الجمركي', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, {bool isCopyable = false, String? fullValue}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
        if (isCopyable) ...[
          const SizedBox(width: 2),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: fullValue ?? value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 تم النسخ إلى الحافظة'), duration: Duration(seconds: 1)),
              );
            },
            child: const Icon(Icons.copy, size: 13, color: AppTheme.cobalt),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    String label = status;
    if (status == 'ACCEPTED_BY_CUSTOMS') {
      bg = AppTheme.emerald;
      label = 'مقبول بالجمارك (Accepted)';
    } else if (status == 'UPLOADED_BY_SUPPLIER') {
      bg = AppTheme.cobalt;
      label = 'مرفوع بالبلوك تشين (Uploaded)';
    } else if (status == 'SEALED_AND_TRANSFERRED') {
      bg = Colors.purple;
      label = 'محول للجمارك (Transferred)';
    } else if (status == 'DRAFT') {
      bg = Colors.orange;
      label = 'مسودة (Draft)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: bg.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Future<void> _runAcidVerification(int envelopeId) async {
    try {
      final report = await ref.read(cargoxEnvelopesProvider.notifier).verifyAcidConsistency(envelopeId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(report.allMatched ? Icons.verified : Icons.warning_amber, color: report.allMatched ? AppTheme.emerald : Colors.red),
                const SizedBox(width: 8),
                Text('تقرير مطابقة الـ ACID (${report.envelopeCode})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الـ ACID المستهدف: ${report.targetAcidNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('نسبة المطابقة: ${report.verifiedCount} من إجمالي ${report.totalDocuments} مستندات', style: const TextStyle(fontSize: 12)),
                  const Divider(),
                  ...report.items.map((item) => ListTile(
                        dense: true,
                        leading: Icon(item.isMatched ? Icons.check_circle : Icons.cancel, color: item.isMatched ? Colors.green : Colors.red, size: 18),
                        title: Text(item.docType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(item.notes ?? '', style: const TextStyle(fontSize: 11)),
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ أثناء فحص الـ ACID', error: e);
      }
    }
  }

  Future<void> _sealAndTransfer(CargoXEnvelopeModel env) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: AppTheme.cobalt),
            SizedBox(width: 8),
            Text('تأكيد الإغلاق والتحويل للجمارك', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من إغلاق المظروف (${env.envelopeCode}) وتوقيعه رقمياً وتحويله لمصلحة الجمارك المصرية (Nafeza)؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
            icon: const Icon(Icons.send, size: 16, color: Colors.white),
            label: const Text('تأكيد التحويل الجمركي', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ref.read(cargoxEnvelopesProvider.notifier).sealAndTransferToCustoms(
            env.envelopeId,
            blNumber: env.blNumber,
            mode: 'MOCK',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${res['message']} (إيصال: ${res['customs_confirmation_receipt']})'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ أثناء تحويل المظروف للجمارك', error: e);
      }
    }
  }

  void _viewManifest(CargoXEnvelopeModel env) async {
    setState(() {
      _selectedSubTab = 2;
      _isLoadingManifest = true;
    });

    try {
      final manifest = await ref.read(cargoxEnvelopesProvider.notifier).fetchDigitalManifest(env.envelopeId);
      if (mounted) {
        setState(() {
          _activeDigitalManifest = manifest;
          _isLoadingManifest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingManifest = false);
        showErrorDetailsDialog(context, title: 'خطأ أثناء جلب المانيفست الرقمي', error: e);
      }
    }
  }

  // ── TAB 2: ACI DIGITAL MANIFEST VIEWER ───────────────────────────────────────
  Widget _buildDigitalManifestViewerTab(List<CargoXEnvelopeModel> envelopes) {
    if (_isLoadingManifest) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeDigitalManifest == null && envelopes.isNotEmpty) {
      if (!_isLoadingManifest) {
        Future.microtask(() => _viewManifest(envelopes.first));
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeDigitalManifest == null) {
      return const Center(
        child: Text('يرجى اختيار مظروف من مركز التتبع لعرض المانيفست الرقمي الخاص به'),
      );
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(_activeDigitalManifest!.manifestJson);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Control Bar
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.cobalt, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'المانيفست الرقمي الرسمي: ${_activeDigitalManifest!.envelopeCode} (ACID: ${_activeDigitalManifest!.acidNumber})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.copy, size: 15, color: Colors.white),
                    label: const Text('نسخ الـ JSON 📋', style: TextStyle(color: Colors.white, fontSize: 11)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 تم نسخ المانيفست الرقمي إلى الحافظة بنجاح')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // JSON Code Viewer Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: SelectableText(
              jsonStr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF9CDCFE),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
