import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/reopen_shipment_dialog.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/file_closure_provider.dart';

class FileClosureScreen extends ConsumerStatefulWidget {
  const FileClosureScreen({super.key});

  @override
  ConsumerState<FileClosureScreen> createState() => _FileClosureScreenState();
}

class _FileClosureScreenState extends ConsumerState<FileClosureScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(fileClosureProvider.notifier).fetchClosures();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCloseFileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _FileClosureFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closuresState = ref.watch(fileClosureProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.archive, color: AppTheme.emerald),
            SizedBox(width: 10),
            Text('إغلاق الملف والأرشفة التاريخية (Phase 10 - Import File Closure & Historical Archival)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(fileClosureProvider.notifier).fetchClosures(),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showCloseFileDialog(),
                      icon: const Icon(Icons.lock_clock, color: Colors.white),
                      label: const Text('إصدار شهادة إغلاق وأرشفة شحنة نهائياً (Close & Archive)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود الشهادة CLR، المراجع...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(fileClosureProvider.notifier).fetchClosures(search: val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Closed Shipments Reopening Banner
            ref.watch(importFilesProvider).when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (files) {
                    final closedFiles = files.where((f) => f.status == 'Closed').toList();
                    if (closedFiles.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          color: Colors.amber.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.amber.shade300)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.history, color: AppTheme.orange, size: 22),
                                    const SizedBox(width: 8),
                                    Text('سجل الشحنات المغلقة مسبقاً (${closedFiles.length} شحنة مغلقة بالأرشيف):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  children: closedFiles.map((cf) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(cf.importFileCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 13)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: Text(cf.closedAtPhase ?? 'Closed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                                              ),
                                            ],
                                          ),
                                          if (cf.closureReason != null && cf.closureReason!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text('سبب الإيقاف: ${cf.closureReason}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87)),
                                          ],
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.emerald,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            ),
                                            onPressed: () {
                                              ReopenShipmentDialog.show(
                                                context,
                                                importFile: cf,
                                                onSuccess: () => ref.read(importFilesProvider.notifier).fetchImportFiles(),
                                              );
                                            },
                                            icon: const Icon(Icons.restart_alt, size: 14),
                                            label: const Text('إعادة فتح وتنشيط الشحنة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

            // Closure Records Grid/List
            Expanded(
              child: closuresState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في جلب بيانات أرشيف الشحنات: $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('لا توجد شحنات مغلقة ومؤرشفة نهائياً حالياً.'));
                  }

                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, idx) {
                      final r = records[idx];
                      final chk = r.closureChecklist;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.emerald.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.emerald)),
                                    child: Text(r.closureCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('ملف الشحنة المرجعي: #${r.importFileId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 12),
                                  Text('مستودع الأرشيف: ${r.archiveLocation}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('🔒 Closed & Archived (100%)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Checklist Verified Badges
                              const Text('شروط الإغلاق المكتملة (Closure Verification Checklist):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChecklistChip('المستندات الأصلية & CargoX', chk.docsVerified),
                                  _buildChecklistChip('الإفراج الجمركي & نموذج 46', chk.customsCleared),
                                  _buildChecklistChip('فحص واستلام المخازن GRN', chk.warehouseReceived),
                                  _buildChecklistChip('التسوية المالية & Landed Cost', chk.landedCostSettled),
                                  _buildChecklistChip('إغلاق المهام التشغيلية', chk.tasksClosed),
                                ],
                              ),

                              if (r.archivalNotes != null && r.archivalNotes!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.note, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('ملاحظات الأرشيف: ${r.archivalNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('المراجع المسؤول: ${r.auditorName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
                                    tooltip: 'حذف لطفياً',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('حذف سجل الأرشفة'),
                                          content: const Text('هل أنت تأكد من نقل سجل الإغلاق للمحذوفات؟'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: AppTheme.crimson))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(fileClosureProvider.notifier).softDeleteClosure(r.closureId);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald),
                                    tooltip: 'استعادة السجل',
                                    onPressed: () async {
                                      await ref.read(fileClosureProvider.notifier).restoreClosure(r.closureId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('✅ تم استعادة شهادة إغلاق الملف ${r.closureCode} بنجاح'), backgroundColor: AppTheme.emerald),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistChip(String label, bool isOk) {
    return Chip(
      avatar: Icon(isOk ? Icons.check_circle : Icons.cancel, color: isOk ? AppTheme.emerald : AppTheme.crimson, size: 16),
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOk ? Colors.black87 : AppTheme.crimson)),
      backgroundColor: isOk ? AppTheme.emerald.withOpacity(0.1) : AppTheme.crimson.withOpacity(0.1),
    );
  }
}

// -----------------------------------------------------------------------------
// FORM DIALOG
// -----------------------------------------------------------------------------

class _FileClosureFormDialog extends ConsumerStatefulWidget {
  const _FileClosureFormDialog();

  @override
  ConsumerState<_FileClosureFormDialog> createState() => _FileClosureFormDialogState();
}

class _FileClosureFormDialogState extends ConsumerState<_FileClosureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;

  bool _docsVerified = true;
  bool _customsCleared = true;
  bool _warehouseReceived = true;
  bool _landedCostSettled = true;
  bool _tasksClosed = true;

  final TextEditingController _auditorCtrl = TextEditingController(text: 'Adel Hassan (Senior Auditor)');
  final TextEditingController _vaultCtrl = TextEditingController(text: 'Digital Vault Archive 2026 - Main Server');
  final TextEditingController _notesCtrl = TextEditingController(text: 'تم استيفاء جميع المستندات والإفراج الجمركي وحساب تكلفة الوصول بنجاح.');

  bool _isLoading = false;

  @override
  void dispose() {
    _auditorCtrl.dispose();
    _vaultCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return AlertDialog(
      title: const Text('إصدار شهادة إغلاق وأرشفة شحنة نهائياً (Phase 10)'),
      content: SizedBox(
        width: 550,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdownField<int?>(
                  value: _selectedImportFileId,
                  labelText: 'اختر ملف الشحنة للإغلاق النهائي *',
                  searchHintText: 'ابحث عن ملف الشحنة بالرقم أو اسم الشركة...',
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                            subtitle: f.companyName,
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                  validator: (v) => v == null ? 'يرجى اختيار ملف الشحنة' : null,
                ),
                const SizedBox(height: 14),

                const Text('قائمة التحقق الإلزامية للإغلاق (Mandatory Closure Checklist):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                const SizedBox(height: 6),
                CheckboxListTile(
                  title: const Text('1️⃣ استلام المستندات الأصلية والتبادل الإلكتروني (CargoX)'),
                  value: _docsVerified,
                  onChanged: (v) => setState(() => _docsVerified = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('2️⃣ إتمام الإفراج الجمركي وسداد الضرائب والإيقاف الجمركي (Dec 46)'),
                  value: _customsCleared,
                  onChanged: (v) => setState(() => _customsCleared = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('3️⃣ استلام البضائع بالمخازن وإصدار إذن الإضافة GRN'),
                  value: _warehouseReceived,
                  onChanged: (v) => setState(() => _warehouseReceived = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('4️⃣ التسوية المالية وتوزيع المصاريف وحساب Landed Cost'),
                  value: _landedCostSettled,
                  onChanged: (v) => setState(() => _landedCostSettled = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('5️⃣ إغلاق كافة المهام والتنبيهات المرتبطة بالشحنة'),
                  value: _tasksClosed,
                  onChanged: (v) => setState(() => _tasksClosed = v ?? false),
                  dense: true,
                ),

                const SizedBox(height: 14),
                TextFormField(
                  controller: _auditorCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المراجع المسؤول *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'يلزم إدخال اسم المراجع' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _vaultCtrl,
                  decoration: const InputDecoration(labelText: 'مستودع الأرشيف الرقمي *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات الأرشفة والتدقيق', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    if (!_docsVerified || !_customsCleared || !_warehouseReceived || !_landedCostSettled || !_tasksClosed) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تنبيه: يلزم اكتمال جميع البنود الـ 5 في قائمة التحقق لإغلاق الملف نهائياً.'),
                        backgroundColor: AppTheme.crimson,
                      ));
                      return;
                    }

                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final payload = {
                        'import_file_id': _selectedImportFileId,
                        'closure_checklist': {
                          'docs_verified': _docsVerified,
                          'customs_cleared': _customsCleared,
                          'warehouse_received': _warehouseReceived,
                          'landed_cost_settled': _landedCostSettled,
                          'tasks_closed': _tasksClosed,
                        },
                        'auditor_name': _auditorCtrl.text.trim(),
                        'archive_location': _vaultCtrl.text.trim(),
                        'archival_notes': _notesCtrl.text.trim(),
                      };

                      await ref.read(fileClosureProvider.notifier).closeImportFile(payload);
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ أثناء إغلاق وأرشفة الملف: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تأكيد الإغلاق النهائي وتجميد الملف 🔒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
