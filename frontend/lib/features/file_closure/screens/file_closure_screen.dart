import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/reopen_shipment_dialog.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
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

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.archive_outlined,
        titleEn: 'Archived Files Registry',
        titleAr: 'سجل الملفات المغلقة والمؤرشفة',
      ),
      const VerticalNavTabItem(
        icon: Icons.inventory_2_outlined,
        titleEn: 'Close Import File',
        titleAr: 'إغلاق وأرشفة ملف شحنة',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'CLR-01',
      titleEn: 'Import File Final Closure & Archival',
      titleAr: 'إغلاق الملف والأرشفة التاريخية',
      headerIcon: Icons.archive,
      headerColor: AppTheme.emerald,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (index) {
        if (index == 1) {
          _showCloseFileDialog();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: context.l10n.fileClosureRefreshTooltip,
          onPressed: () => ref.read(fileClosureProvider.notifier).fetchClosures(),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'file-closure',
              title: 'File_Closure',
              onRefreshNeeded: () => ref.read(fileClosureProvider.notifier).fetchClosures(),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showCloseFileDialog(),
                      icon: const Icon(Icons.lock_clock, color: Colors.white),
                      label: Text(context.l10n.fileClosureNewCertificateBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.l10n.fileClosureSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: const OutlineInputBorder(),
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
                                    Text(context.l10n.fileClosureClosedFilesBannerTitle(closedFiles.length), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
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
                                                child: Text(cf.closedAtPhase ?? context.l10n.fileClosureClosedBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                                              ),
                                            ],
                                          ),
                                          if (cf.closureReason != null && cf.closureReason!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(context.l10n.fileClosureStopReason(cf.closureReason!), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87)),
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
                                            label: Text(context.l10n.fileClosureReopenBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                error: (err, _) => Center(child: Text('${context.l10n.fileClosureFetchError} $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return Center(child: Text(context.l10n.fileClosureEmptyRecords));
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
                                  Text(context.l10n.fileClosureFileRefLabel(r.importFileId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 12),
                                  Text(context.l10n.fileClosureVaultLabel(r.archiveLocation), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                    child: Text(context.l10n.fileClosureStatusBadgeClosed, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Checklist Verified Badges
                              Text(context.l10n.fileClosureChecklistHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChecklistChip(context.l10n.fileClosureChecklistDocsOriginals, chk.docsVerified),
                                  _buildChecklistChip(context.l10n.fileClosureChecklistCustomsCleared, chk.customsCleared),
                                  _buildChecklistChip(context.l10n.fileClosureChecklistWarehouseGrn, chk.warehouseReceived),
                                  _buildChecklistChip(context.l10n.fileClosureChecklistLandedCost, chk.landedCostSettled),
                                  _buildChecklistChip(context.l10n.fileClosureChecklistTasksClosed, chk.tasksClosed),
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
                                      Expanded(child: Text(context.l10n.fileClosureArchivalNotes(r.archivalNotes!), style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(context.l10n.fileClosureAuditorLabel(r.auditorName), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const Spacer(),
                                  RowActionsPill(
                                    onView: () {
                                      showDialog(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: Text(context.l10n.fileClosureCertificateDialogTitle(r.closureCode)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(context.l10n.fileClosureCertFileNo(r.importFileId)),
                                              Text(context.l10n.fileClosureCertLocation(r.archiveLocation)),
                                              Text(context.l10n.fileClosureCertAuditor(r.auditorName)),
                                              Text(context.l10n.fileClosureCertClosedDate(r.closedAt)),
                                              if (r.archivalNotes != null) Text(context.l10n.fileClosureCertNotes(r.archivalNotes!)),
                                            ],
                                          ),
                                          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(context.l10n.close))],
                                        ),
                                      );
                                    },
                                    onEdit: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(context.l10n.fileClosureEditSnack(r.closureCode)), backgroundColor: AppTheme.orange),
                                      );
                                    },
                                    onPrint: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(context.l10n.fileClosurePrintSnack(r.closureCode, r.importFileId)),
                                          backgroundColor: AppTheme.charcoal,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    onDelete: () async {
                                      final l10n = context.l10n;
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: Text(l10n.fileClosureDeleteTitle),
                                          content: Text(l10n.fileClosureDeleteMessage),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.delete, style: const TextStyle(color: AppTheme.crimson))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(fileClosureProvider.notifier).softDeleteClosure(r.closureId);
                                      }
                                    },
                                    viewTooltip: context.l10n.fileClosureViewTooltip,
                                    editTooltip: context.l10n.fileClosureEditTooltip,
                                    printTooltip: context.l10n.fileClosurePrintTooltip,
                                    deleteTooltip: context.l10n.fileClosureDeleteTooltip,
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
  bool _isDraftSaving = false;

  @override
  void dispose() {
    _auditorCtrl.dispose();
    _vaultCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onFileSelected(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) return;

    final existingClosures = ref.read(fileClosureProvider).value ?? [];
    final match = existingClosures.where((c) => c.importFileId == fileId).firstOrNull;
    if (match != null) {
      setState(() {
        _docsVerified = match.closureChecklist.docsVerified;
        _customsCleared = match.closureChecklist.customsCleared;
        _warehouseReceived = match.closureChecklist.warehouseReceived;
        _landedCostSettled = match.closureChecklist.landedCostSettled;
        _tasksClosed = match.closureChecklist.tasksClosed;
        if (match.auditorName.isNotEmpty) _auditorCtrl.text = match.auditorName;
        if (match.archiveLocation.isNotEmpty) _vaultCtrl.text = match.archiveLocation;
        if (match.archivalNotes != null) _notesCtrl.text = match.archivalNotes!;
      });
    }
  }

  Future<void> _submitClosure({required bool isDraft}) async {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (!_formKey.currentState!.validate()) return;

    if (!isDraft) {
      if (!_docsVerified || !_customsCleared || !_warehouseReceived || !_landedCostSettled || !_tasksClosed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.fileClosureChecklistIncompleteWarning),
          backgroundColor: AppTheme.crimson,
        ));
        return;
      }
    }

    setState(() {
      if (isDraft) {
        _isDraftSaving = true;
      } else {
        _isLoading = true;
      }
    });

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
        'is_draft': isDraft,
      };

      await ref.read(fileClosureProvider.notifier).closeImportFile(payload);
      await ref.read(importFilesProvider.notifier).fetchImportFiles();

      final int completedCount = (_docsVerified ? 1 : 0) +
          (_customsCleared ? 1 : 0) +
          (_warehouseReceived ? 1 : 0) +
          (_landedCostSettled ? 1 : 0) +
          (_tasksClosed ? 1 : 0);
      final double progressPct = (completedCount / 5.0) * 100.0;

      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? (isArabic
                    ? '💾 تم حفظ تقدم الإغلاق مؤقتاً بنجاح (نسبة الإنجاز: ${progressPct.toStringAsFixed(0)}% - $completedCount من 5 مهام)'
                    : 'Draft progress saved successfully (${progressPct.toStringAsFixed(0)}% - $completedCount/5 tasks)')
                : (isArabic ? '✅ تم اعتماد وإصدار شهادة الإغلاق النهائي والأرشفة بنجاح!' : 'Final Closure & Archival Certified Successfully!'),
          ),
          backgroundColor: isDraft ? AppTheme.cobalt : AppTheme.emerald,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.fileClosureSaveError('$e')), backgroundColor: AppTheme.crimson));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDraftSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final int completedCount = (_docsVerified ? 1 : 0) +
        (_customsCleared ? 1 : 0) +
        (_warehouseReceived ? 1 : 0) +
        (_landedCostSettled ? 1 : 0) +
        (_tasksClosed ? 1 : 0);
    final double progressPct = (completedCount / 5.0) * 100.0;
    final bool isFullyComplete = completedCount == 5;
    final Color progressColor = isFullyComplete
        ? AppTheme.emerald
        : (completedCount >= 3 ? AppTheme.cobalt : (completedCount >= 1 ? Colors.orange.shade800 : Colors.grey.shade600));

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppTheme.cobalt, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(context.l10n.fileClosureDialogTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdownField<int?>(
                  value: _selectedImportFileId,
                  labelText: context.l10n.fileClosureSelectImportFile,
                  searchHintText: context.l10n.fileClosureSelectImportFileHint,
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                            subtitle: f.companyName,
                          ))
                      .toList(),
                  onChanged: _onFileSelected,
                  validator: (v) => v == null ? context.l10n.fileClosureSelectImportFileValidator : null,
                ),
                const SizedBox(height: 14),

                // ─── Dynamic Overall Completion Progress Card ─────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: progressColor.withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isFullyComplete ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                color: progressColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'نسبة اكتمال المهام والأوراق الكلية:' : 'Overall Checklist Completion:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: progressColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${progressPct.toStringAsFixed(0)}% ($completedCount/5)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completedCount / 5.0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isArabic
                            ? '💡 يمكنك استخدام زر "حفظ مؤقت (Save Draft)" لحفظ تقدم الإنجاز ومتابعة باقي الأوراق لاحقاً.'
                            : '💡 You can use "Save Draft" to save intermediate progress and complete later.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(context.l10n.fileClosureMandatoryChecklistHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                const SizedBox(height: 6),
                CheckboxListTile(
                  title: Text(context.l10n.fileClosureCheck1Docs, style: TextStyle(fontWeight: _docsVerified ? FontWeight.bold : FontWeight.normal)),
                  secondary: Icon(_docsVerified ? Icons.check_box : Icons.check_box_outline_blank, color: _docsVerified ? AppTheme.emerald : Colors.grey),
                  value: _docsVerified,
                  onChanged: (v) => setState(() => _docsVerified = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: Text(context.l10n.fileClosureCheck2Customs, style: TextStyle(fontWeight: _customsCleared ? FontWeight.bold : FontWeight.normal)),
                  secondary: Icon(_customsCleared ? Icons.check_box : Icons.check_box_outline_blank, color: _customsCleared ? AppTheme.emerald : Colors.grey),
                  value: _customsCleared,
                  onChanged: (v) => setState(() => _customsCleared = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: Text(context.l10n.fileClosureCheck3Warehouse, style: TextStyle(fontWeight: _warehouseReceived ? FontWeight.bold : FontWeight.normal)),
                  secondary: Icon(_warehouseReceived ? Icons.check_box : Icons.check_box_outline_blank, color: _warehouseReceived ? AppTheme.emerald : Colors.grey),
                  value: _warehouseReceived,
                  onChanged: (v) => setState(() => _warehouseReceived = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: Text(context.l10n.fileClosureCheck4LandedCost, style: TextStyle(fontWeight: _landedCostSettled ? FontWeight.bold : FontWeight.normal)),
                  secondary: Icon(_landedCostSettled ? Icons.check_box : Icons.check_box_outline_blank, color: _landedCostSettled ? AppTheme.emerald : Colors.grey),
                  value: _landedCostSettled,
                  onChanged: (v) => setState(() => _landedCostSettled = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: Text(context.l10n.fileClosureCheck5Tasks, style: TextStyle(fontWeight: _tasksClosed ? FontWeight.bold : FontWeight.normal)),
                  secondary: Icon(_tasksClosed ? Icons.check_box : Icons.check_box_outline_blank, color: _tasksClosed ? AppTheme.emerald : Colors.grey),
                  value: _tasksClosed,
                  onChanged: (v) => setState(() => _tasksClosed = v ?? false),
                  dense: true,
                ),

                const SizedBox(height: 14),
                TextFormField(
                  controller: _auditorCtrl,
                  decoration: InputDecoration(labelText: context.l10n.fileClosureAuditorNameLabel, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? context.l10n.fileClosureAuditorNameValidator : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _vaultCtrl,
                  decoration: InputDecoration(labelText: context.l10n.fileClosureVaultLocationLabel, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: context.l10n.fileClosureArchivalNotesLabel, border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal, side: BorderSide(color: Colors.grey.shade400)),
          onPressed: () => ref.read(fileClosureProvider.notifier).fetchClosures(),
          icon: const Icon(Icons.refresh, size: 16, color: AppTheme.cobalt),
          label: Text(context.l10n.fileClosureLiveReloadBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade800, side: BorderSide(color: Colors.grey.shade400)),
          onPressed: () {
            setState(() {
              _notesCtrl.clear();
              _auditorCtrl.clear();
              _vaultCtrl.text = 'Main Archive Vault #1';
              _docsVerified = false;
              _customsCleared = false;
              _warehouseReceived = false;
              _landedCostSettled = false;
              _tasksClosed = false;
            });
          },
          icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.blueGrey),
          label: Text(context.l10n.fileClosureResetFormBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),

        // ─── 💾 Save Draft / حفظ مؤقت ومتابعة لاحقاً ───────────────────────────
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEFF6FF),
            foregroundColor: AppTheme.cobalt,
            elevation: 0,
            side: const BorderSide(color: AppTheme.cobalt),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: _isDraftSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: AppTheme.cobalt, strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 16, color: AppTheme.cobalt),
          label: Text(
            isArabic ? 'حفظ مؤقت (Save Draft) 💾' : 'Save Draft 💾',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          onPressed: (_isLoading || _isDraftSaving) ? null : () => _submitClosure(isDraft: true),
        ),
        const SizedBox(width: 4),

        TextButton(onPressed: (_isLoading || _isDraftSaving) ? null : () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        const SizedBox(width: 4),

        // ─── ✅ Certify Final Closure & Archival ──────────────────────────────
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emerald,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.archive_outlined, color: Colors.white, size: 16),
          label: Text(context.l10n.fileClosureCertifySubmitBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          onPressed: (_isLoading || _isDraftSaving) ? null : () => _submitClosure(isDraft: false),
        ),
      ],
    );
  }
}
