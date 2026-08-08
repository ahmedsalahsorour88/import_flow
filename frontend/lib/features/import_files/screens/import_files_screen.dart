import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';

class ImportFilesScreen extends ConsumerStatefulWidget {
  const ImportFilesScreen({super.key});

  @override
  ConsumerState<ImportFilesScreen> createState() => _ImportFilesScreenState();
}

class _ImportFilesScreenState extends ConsumerState<ImportFilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  void _showAddEditFileDialog([ImportFileModel? fileToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportFileFormDialog(fileToEdit: fileToEdit),
    );
  }

  void _showMasterReportDialog() async {
    try {
      final report = await ref.read(importFilesProvider.notifier).fetchMasterReport();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.summarize, color: AppTheme.cobalt),
                SizedBox(width: 10),
                Text('تقرير ملخص ملفات الاستيراد الشامل (Master Import Report)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 800,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMetricCard('إجمالي الملفات', '${report.totalImportFiles}', AppTheme.charcoal),
                      const SizedBox(width: 10),
                      _buildMetricCard('الملفات المفتوحة', '${report.openFilesCount}', AppTheme.cobalt),
                      const SizedBox(width: 10),
                      _buildMetricCard('قيد التنفيذ', '${report.inProgressCount}', AppTheme.orange),
                      const SizedBox(width: 10),
                      _buildMetricCard('إجمالي التكلفة EGP', '${report.totalEstimatedCost.toStringAsFixed(0)} \$', AppTheme.emerald),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('تفاصيل ملفات الشحنات والاستخراج:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: report.files.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final f = report.files[index];
                        return ListTile(
                          title: Text('كود الشحنة: ${f.customFileNumber ?? f.importFileCode} | الشركة: ${f.companyName} | المورد: ${f.supplierName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('المرحلة: ${f.currentStage} | النسبية: ${f.progressPercent}% | القادمة: ${f.nextAction} | المسئول: ${f.owner}'),
                          trailing: Chip(label: Text(f.status), backgroundColor: Colors.green.shade100),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم استخراج التقرير الشامل بنجاح إلى ملف Excel/PDF!'), backgroundColor: AppTheme.emerald));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('تصدير التقرير (Excel / PDF)', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ أثناء استخراج التقرير: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(importFilesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('إدارة وملفات استيراد الشحنات (Import Files Master & Tracking)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(importFilesProvider.notifier).fetchImportFiles(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar: Actions & Filters
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showAddEditFileDialog(),
                      icon: const Icon(Icons.add_box, color: Colors.white),
                      label: const Text('إضافة ملف استيراد شحنة جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                      onPressed: _showMasterReportDialog,
                      icon: const Icon(Icons.summarize, color: AppTheme.cobalt),
                      label: const Text('استخراج تقرير الشحنات الشامل', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود الشحنة أو الشركة...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(importFilesProvider.notifier).fetchImportFiles(search: val, status: _selectedStatusFilter);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedStatusFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                        DropdownMenuItem(value: 'Open', child: Text('Open (مفتوح)')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress (قيد التنفيذ)')),
                        DropdownMenuItem(value: 'Closed', child: Text('Closed (مغلق)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatusFilter = val);
                          ref.read(importFilesProvider.notifier).fetchImportFiles(search: _searchController.text, status: val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Files Data Table
            Expanded(
              child: filesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('❌ Error: $err', style: const TextStyle(color: Colors.red))),
                data: (files) {
                  if (files.isEmpty) {
                    return const Center(child: Text('لا توجد ملفات استيراد مسجلة بالنظام. اضغط إضافة ملف جديد.', style: TextStyle(fontSize: 16)));
                  }
                  return Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: const [
                            DataColumn(label: Text('رقم ملف الاستيراد (File ID)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الشركة المستوردة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('أمر الشراء / الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('وسيلة النقل / الشكيمة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الأولوية / النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الوصول المطلوبة ETA', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المرحلة الحالية (Formula)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('نسبة الإنجاز %', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الخطوة القادمة (Next Action)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المسئول (Owner)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: files.map((file) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(file.customFileNumber ?? file.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                      Text(file.importFileCode, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(file.companyName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PO: ${file.poNumber ?? "-"}'),
                                      Text('PI: ${file.piNumber ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(file.supplierName)),
                                DataCell(Text('${file.shipmentMode} (${file.incotermCode})')),
                                DataCell(
                                  Chip(
                                    label: Text(file.priority, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: file.priority == 'High' || file.priority == 'Critical' ? Colors.red : Colors.orange,
                                  ),
                                ),
                                DataCell(Text(file.requiredEta ?? '-')),
                                DataCell(Text(file.currentStage, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        LinearProgressIndicator(value: file.progressPercent / 100, backgroundColor: Colors.grey.shade200, color: AppTheme.emerald),
                                        const SizedBox(height: 2),
                                        Text('${file.progressPercent.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text(file.nextAction, style: const TextStyle(fontSize: 11, color: AppTheme.charcoal))),
                                DataCell(Text(file.owner, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Chip(
                                    label: Text(file.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: file.status == 'Open' ? Colors.green : Colors.grey,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                                        onPressed: () => _showAddEditFileDialog(file),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text('تأكيد الحذف'),
                                              content: Text('هل أنت تأكد من حذف ملف الاستيراد رقم ${file.customFileNumber ?? file.importFileCode}؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(importFilesProvider.notifier).softDeleteImportFile(file.importFileId);
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

class _ImportFileFormDialog extends ConsumerStatefulWidget {
  final ImportFileModel? fileToEdit;
  const _ImportFileFormDialog({this.fileToEdit});

  @override
  ConsumerState<_ImportFileFormDialog> createState() => _ImportFileFormDialogState();
}

class _ImportFileFormDialogState extends ConsumerState<_ImportFileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customFileIdController;
  late TextEditingController _poNoController;
  late TextEditingController _piNoController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _selectedScenarioController;
  late TextEditingController _form4Controller;
  late TextEditingController _swiftController;
  late TextEditingController _form46Controller;
  late TextEditingController _ownerController;
  late TextEditingController _notesController;

  int? _selectedCompanyId;
  String _companyName = '';
  int? _selectedSupplierId;
  String _supplierName = '';
  String _shipmentMode = 'Sea';
  String _incotermCode = 'FOB';
  String _priority = 'High';
  String _shipmentCategory = 'New Purchase';
  String _status = 'Open';
  DateTime _requiredEta = DateTime.now().add(const Duration(days: 30));

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
    _estimatedCostController = TextEditingController(text: (f?.estimatedCost ?? 24500.0).toString());
    _selectedScenarioController = TextEditingController(text: f?.selectedScenario ?? 'MSC Option');
    _form4Controller = TextEditingController(text: f?.form4No ?? '');
    _swiftController = TextEditingController(text: f?.swiftNo ?? '');
    _form46Controller = TextEditingController(text: f?.form46No ?? '');
    _ownerController = TextEditingController(text: f?.owner ?? 'Kamal');
    _notesController = TextEditingController(text: f?.notes ?? '');

    _selectedCompanyId = f?.companyId;
    _companyName = f?.companyName ?? '';
    _selectedSupplierId = f?.supplierId;
    _supplierName = f?.supplierName ?? '';
    _shipmentMode = f?.shipmentMode ?? 'Sea';
    _incotermCode = f?.incotermCode ?? 'FOB';
    _priority = f?.priority ?? 'High';
    _shipmentCategory = f?.shipmentCategory ?? 'New Purchase';
    _status = f?.status ?? 'Open';
    _invoices = List.from(f?.invoicesData ?? []);
    _packingLists = List.from(f?.packingListsData ?? []);
    _selectedProjectIds = List.from(f?.projectIds ?? []);
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

    setState(() => _isSaving = true);
    try {
      final payload = {
        'custom_file_number': _customFileIdController.text.trim(),
        'company_id': _selectedCompanyId,
        'company_name': _companyName,
        'supplier_id': _selectedSupplierId,
        'supplier_name': _supplierName,
        'po_number': _poNoController.text.trim(),
        'pi_number': _piNoController.text.trim(),
        'invoices_data': _invoices.map((i) => i.toJson()).toList(),
        'packing_lists_data': _packingLists.map((p) => p.toJson()).toList(),
        'project_ids': _selectedProjectIds,
        'shipment_mode': _shipmentMode,
        'incoterm_code': _incotermCode,
        'priority': _priority,
        'shipment_category': _shipmentCategory,
        'required_eta': _requiredEta.toString().substring(0, 10),
        'selected_scenario': _selectedScenarioController.text.trim(),
        'form4_no': _form4Controller.text.trim(),
        'swift_no': _swiftController.text.trim(),
        'form46_no': _form46Controller.text.trim(),
        'estimated_cost': double.tryParse(_estimatedCostController.text.trim()) ?? 0.0,
        'status': _status,
        'owner': _ownerController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      if (widget.fileToEdit == null) {
        await ref.read(importFilesProvider.notifier).createImportFile(payload);
      } else {
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
    final incoterms = ref.watch(incotermsProvider).incoterms;
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
                      child: DropdownButtonFormField<int?>(
                        value: _selectedCompanyId,
                        decoration: const InputDecoration(labelText: 'الشركة المستوردة المصرية *', border: OutlineInputBorder()),
                        items: companies.map((c) => DropdownMenuItem<int?>(value: c.companyId, child: Text(c.importerName))).toList(),
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
                      child: DropdownButtonFormField<int?>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(labelText: 'المورد الأجنبي (Supplier) *', border: OutlineInputBorder()),
                        items: suppliers.map((s) => DropdownMenuItem<int?>(value: s.supplierId, child: Text(s.companyName))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final sup = suppliers.firstWhere((s) => s.supplierId == val);
                            setState(() {
                              _selectedSupplierId = val;
                              _supplierName = sup.companyName;
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
                      child: DropdownButtonFormField<String>(
                        value: _shipmentMode,
                        decoration: const InputDecoration(labelText: 'وسيلة النقل (Shipment Mode) *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Sea', child: Text('Sea (شحن بحري)')),
                          DropdownMenuItem(value: 'Air', child: Text('Air (شحن جوي)')),
                          DropdownMenuItem(value: 'Land', child: Text('Land (شحن بري)')),
                        ],
                        onChanged: (v) => setState(() => _shipmentMode = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: incoterms.any((i) => i.incotermCode == _incotermCode) ? _incotermCode : 'FOB',
                        decoration: const InputDecoration(labelText: 'شرط التجارة (Incoterm) *', border: OutlineInputBorder()),
                        items: (incoterms.isNotEmpty ? incoterms.map((i) => i.incotermCode).toList() : ['FOB', 'CIF', 'CFR', 'EXW'])
                            .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                            .toList(),
                        onChanged: (v) => setState(() => _incotermCode = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(labelText: 'الأولوية (Priority) *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low (منخفضة)')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium (متوسطة)')),
                          DropdownMenuItem(value: 'High', child: Text('High (عالية)')),
                          DropdownMenuItem(value: 'Critical', child: Text('Critical (حرجة)')),
                        ],
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _shipmentCategory,
                        decoration: const InputDecoration(labelText: 'تصنيف الشحنة (Category) *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'New Purchase', child: Text('New Purchase (شراء جديد)')),
                          DropdownMenuItem(value: 'Replacement', child: Text('Replacement (استبدال)')),
                          DropdownMenuItem(value: 'Repair', child: Text('Repair (إصلاح)')),
                          DropdownMenuItem(value: 'Sample', child: Text('Sample (عينة)')),
                        ],
                        onChanged: (v) => setState(() => _shipmentCategory = v!),
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
                      child: TextFormField(
                        controller: _selectedScenarioController,
                        decoration: const InputDecoration(labelText: 'السيناريو المختار (Selected Scenario)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Linking Multiple Projects Rule Notice
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'إسناد الشحنة إلى مشروع (Projects) *', border: OutlineInputBorder()),
                        items: projects.map((p) => DropdownMenuItem<int>(value: p.projectId, child: Text('${p.projectName} (${p.projectCode})'))).toList(),
                        onChanged: (val) {
                          if (val != null && !_selectedProjectIds.contains(val)) {
                            setState(() => _selectedProjectIds.add(val));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _estimatedCostController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'التكلفة التقديرية (USD) *', border: OutlineInputBorder()),
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _form4Controller,
                        decoration: const InputDecoration(labelText: 'رقم نموذج 4 البنكي (form 4 no)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _swiftController,
                        decoration: const InputDecoration(labelText: 'رقم التحويل السويفت (swift no)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _form46Controller,
                        decoration: const InputDecoration(labelText: 'رقم الإقرار الجمركي 46 (form 46 no)', border: OutlineInputBorder()),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
          label: const Text('حفظ الشحنة بالكامل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
