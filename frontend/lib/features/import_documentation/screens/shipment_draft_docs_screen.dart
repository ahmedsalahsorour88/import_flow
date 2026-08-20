import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';
import '../widgets/coo_review_tab.dart';
import '../widgets/customs_document_approval_tab.dart';
import '../widgets/draft_bl_review_tab.dart';
import '../widgets/inspection_review_tab.dart';
import '../widgets/invoice_bl_matcher_tab.dart';
import '../widgets/po_reconciliation_tab.dart';

class ShipmentDraftDocsScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const ShipmentDraftDocsScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<ShipmentDraftDocsScreen> createState() => _ShipmentDraftDocsScreenState();
}

class _ShipmentDraftDocsScreenState extends ConsumerState<ShipmentDraftDocsScreen> {
  // Active Vertical Sub-Tab:
  // 0: 📦 مطابقة الفاتورة والباكينج (PO & Packing Reconciliation)
  // 1: 📄 مسودة بوليصة الشحن (Draft B/L Review & Dual Approval)
  // 2: ⚡ الاستخراج ومطابقة الفاتورة والبوليصة (Smart Invoice vs. B/L Reconciliation)
  // 3: 📜 مسودة شهادة المنشأ و EUR.1 (Draft COO / EUR.1 Review)
  // 4: 🛡️ شهادات الفحص والمطابقة (Inspection & Conformity Review)
  // 5: 📁 السجل المركزي وتظهير CargoX (Central Docs & CargoX Archive)
  int _selectedSubTab = 0;

  // Selected Import File
  int? _selectedImportFileId;

  // State for Central Archive (Tab 5)
  final _docFormKey = GlobalKey<FormState>();
  final TextEditingController _docNameCtrl = TextEditingController(text: 'Commercial Invoice');
  final TextEditingController _docNumberCtrl = TextEditingController();
  final TextEditingController _issueDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _cargoxEnvelopeCtrl = TextEditingController();
  bool _isCargoxUploaded = false;
  bool _isBlEndorsed = false;
  final String _docStatus = 'Approved';
  String _docSearchQuery = '';
  bool _isSavingDoc = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(shipmentDocumentsProvider.notifier).fetchShipmentDocuments();
  }

  @override
  void dispose() {
    _docNameCtrl.dispose();
    _docNumberCtrl.dispose();
    _issueDateCtrl.dispose();
    _cargoxEnvelopeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipmentDocs = ref.watch(shipmentDocumentsProvider).value ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.verified_user,
        titleEn: 'Docs Customs Approval Hub',
        titleAr: 'مركز اعتماد المستندات الجمركية',
      ),
      const VerticalNavTabItem(
        icon: Icons.fact_check_outlined,
        titleEn: 'PO & Packing Reconciliation',
        titleAr: 'مطابقة الفاتورة وقائمة التعبئة',
      ),
      const VerticalNavTabItem(
        icon: Icons.assignment_turned_in_outlined,
        titleEn: 'Draft B/L Review & Approval',
        titleAr: 'مسودة بوليصة الشحن والاعتماد',
      ),
      const VerticalNavTabItem(
        icon: Icons.auto_awesome,
        titleEn: 'Smart Invoice vs B/L Match',
        titleAr: 'استخراج ومطابقة الفاتورة والبوليصة',
      ),
      const VerticalNavTabItem(
        icon: Icons.flag_circle_outlined,
        titleEn: 'Draft COO & EUR.1 Review',
        titleAr: 'مسودة شهادة المنشأ و EUR.1',
      ),
      const VerticalNavTabItem(
        icon: Icons.security_outlined,
        titleEn: 'Inspection Review',
        titleAr: 'شهادات الفحص والمطابقة',
      ),
      VerticalNavTabItem(
        icon: Icons.folder_shared_outlined,
        titleEn: 'Central Archive & CargoX',
        titleAr: 'السجل المركزي وتظهير CargoX',
        badge: shipmentDocs.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${shipmentDocs.length}',
                  style: const TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Shipment Draft Documents Review & CargoX',
      titleAr: 'مراجعة وتدقيق مسودات مستندات الشحن',
      headerIcon: Icons.folder_open_outlined,
      headerColor: AppTheme.emerald,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (index) {
        setState(() => _selectedSubTab = index);
        if (index == 6) {
          ref.read(shipmentDocumentsProvider.notifier).fetchShipmentDocuments();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث البيانات (Refresh)',
          onPressed: _refreshData,
        ),
      ],
      body: _selectedSubTab == 6
          ? SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildCentralDocsArchiveView())
          : _buildCurrentSubTabContent(),
    );
  }

  Widget _buildCurrentSubTabContent() {
    switch (_selectedSubTab) {
      case 0:
        return CustomsDocumentApprovalTab(initialImportFileId: _selectedImportFileId);
      case 1:
        return POReconciliationTab(initialImportFileId: _selectedImportFileId);
      case 2:
        return DraftBLReviewTab(initialImportFileId: _selectedImportFileId);
      case 3:
        return InvoiceBLMatcherTab(
          selectedImportFileId: _selectedImportFileId,
          onImportFileChanged: (newId) {
            setState(() {
              _selectedImportFileId = newId;
            });
          },
        );
      case 4:
        return COOReviewTab(initialImportFileId: _selectedImportFileId);
      case 5:
        return InspectionReviewTab(initialImportFileId: _selectedImportFileId);
      default:
        return CustomsDocumentApprovalTab(initialImportFileId: _selectedImportFileId);
    }
  }

  // --- SUB-VIEW 4: CENTRAL DOCS ARCHIVE VIEW ---
  Widget _buildCentralDocsArchiveView() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final shipmentDocs = ref.watch(shipmentDocumentsProvider).value ?? [];

    final filtered = shipmentDocs.where((d) {
      final q = _docSearchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return d.docName.toLowerCase().contains(q) ||
          d.docNumber.toLowerCase().contains(q) ||
          (d.importFileCode != null && d.importFileCode!.toLowerCase().contains(q));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New Document Registration Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Form(
            key: _docFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'قيد مستند شحن جديد بالسجل المركزي وأرشيف CargoX:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<int>(
                        labelText: 'ملف الشحنة (Select Import File)',
                        hintText: 'اختر ملف الشحنة...',
                        value: _selectedImportFileId,
                        isRequired: true,
                        items: importFiles.map((f) => SearchableDropdownItem<int>(
                          value: f.importFileId,
                          label: '${f.importFileCode} — ${f.supplierName}',
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedImportFileId = val),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _docNameCtrl,
                        decoration: const InputDecoration(labelText: 'نوع المستند *', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _docNumberCtrl,
                        decoration: const InputDecoration(labelText: 'رقم المستند / المرجع *', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _issueDateCtrl,
                        decoration: const InputDecoration(labelText: 'تاريخ الإصدار', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _cargoxEnvelopeCtrl,
                        decoration: const InputDecoration(labelText: 'معرف مظروف CargoX Envelope ID', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CheckboxListTile(
                        value: _isCargoxUploaded,
                        title: const Text('مرفوع على CargoX', style: TextStyle(fontSize: 13)),
                        onChanged: (val) => setState(() => _isCargoxUploaded = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        value: _isBlEndorsed,
                        title: const Text('مظهر بنكياً', style: TextStyle(fontSize: 13)),
                        onChanged: (val) => setState(() => _isBlEndorsed = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _isSavingDoc ? null : _saveDocument,
                  icon: _isSavingDoc
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('حفظ وتسجيل المستند في الأرشيف المركزي', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Registry Search & Table
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث في الأرشيف المركزي للمستندات بالاسم، الرقم، رقم الملف...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _docSearchQuery = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('رقم المستند', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('نوع المستند', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('رقم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ الإصدار', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('حالة CargoX', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('التظهير البنكي', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('حالة الاعتماد', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filtered.map((d) {
              return DataRow(
                cells: [
                  DataCell(Text(d.docNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                  DataCell(Text(d.docName)),
                  DataCell(Text(d.importFileCode ?? '-')),
                  DataCell(Text(d.issueDate)),
                  DataCell(
                    Row(
                      children: [
                        Icon(d.isCargoxUploaded ? Icons.cloud_done : Icons.cloud_upload_outlined, size: 16, color: d.isCargoxUploaded ? Colors.green : Colors.grey),
                        const SizedBox(width: 4),
                        Text(d.isCargoxUploaded ? 'تم التظهير' : 'لم يرفع', style: TextStyle(fontSize: 11, color: d.isCargoxUploaded ? Colors.green : Colors.grey)),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(d.isBlEndorsed ? 'مظهر ✅' : 'غير مظهر', style: TextStyle(fontSize: 11, color: d.isBlEndorsed ? Colors.green : Colors.grey)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(d.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _saveDocument() async {
    if (!_docFormKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSavingDoc = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'doc_name': _docNameCtrl.text.trim(),
        'doc_number': _docNumberCtrl.text.trim(),
        'issue_date': _issueDateCtrl.text.trim(),
        'is_cargox_uploaded': _isCargoxUploaded,
        'cargox_envelope_id': _cargoxEnvelopeCtrl.text.trim(),
        'is_bl_endorsed': _isBlEndorsed,
        'status': _docStatus,
      };

      await ref.read(shipmentDocumentsProvider.notifier).createShipmentDocument(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل وحفظ المستند في الأرشيف المركزي بنجاح'), backgroundColor: AppTheme.emerald),
        );
        _docNumberCtrl.clear();
        _cargoxEnvelopeCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في تسجيل المستند', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSavingDoc = false);
    }
  }
}
