import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../shipment_updates/providers/shipment_updates_provider.dart';
import '../../shipment_updates/widgets/shipment_update_dialog.dart';
import '../../customs_clearance/providers/customs_clearance_provider.dart';
import '../../customs_clearance/models/customs_clearance_model.dart';
import '../../warehouse_receiving/providers/warehouse_receiving_provider.dart';
import '../../warehouse_receiving/models/warehouse_receiving_model.dart';

// ============================================================
// Comprehensive Import File Report Screen
// تقرير ملخص ملفات الاستيراد المدمج والشامل
// ============================================================

class ImportFileComprehensiveReportScreen extends ConsumerStatefulWidget {
  const ImportFileComprehensiveReportScreen({super.key});

  @override
  ConsumerState<ImportFileComprehensiveReportScreen> createState() =>
      _ImportFileComprehensiveReportScreenState();
}

class _ImportFileComprehensiveReportScreenState
    extends ConsumerState<ImportFileComprehensiveReportScreen> {
  int? _selectedFileId;
  ImportFileModel? _selectedFile;

  static const List<Map<String, dynamic>> _allPhases = [
    {'code': 'Phase 1', 'name': 'التخطيط والجدوى والنولون', 'icon': Icons.analytics_outlined, 'bp': 'BP-001 → BP-011'},
    {'code': 'Phase 2', 'name': 'الموافقة والاعتماد المالي', 'icon': Icons.account_balance_outlined, 'bp': 'BP-012 → BP-013'},
    {'code': 'Phase 3', 'name': 'المستندات والـ ACID و Form 4', 'icon': Icons.description_outlined, 'bp': 'BP-014 → BP-016'},
    {'code': 'Phase 4', 'name': 'حجز الشحن والناقل', 'icon': Icons.directions_boat_outlined, 'bp': 'BP-017 → BP-019'},
    {'code': 'Phase 5', 'name': 'الشحن الفعلي وتتبع CargoX', 'icon': Icons.local_shipping_outlined, 'bp': 'BP-020 → BP-025'},
    {'code': 'Phase 6', 'name': 'إقرار 46 والتعريفة الجمركية', 'icon': Icons.account_balance_wallet_outlined, 'bp': 'BP-026 → BP-028'},
    {'code': 'Phase 7', 'name': 'التخليص الجمركي وسداد الرسوم', 'icon': Icons.receipt_long_outlined, 'bp': 'BP-029 → BP-032'},
    {'code': 'Phase 8', 'name': 'استلام البضاعة بالمخازن GRN', 'icon': Icons.warehouse_outlined, 'bp': 'BP-033 → BP-035'},
    {'code': 'Phase 9', 'name': 'تسوية تكلفة الوصول Landed Cost', 'icon': Icons.calculate_outlined, 'bp': 'BP-036 → BP-039'},
    {'code': 'Phase 10', 'name': 'إغلاق الملف والأرشفة التاريخية', 'icon': Icons.archive_outlined, 'bp': 'BP-040'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  void _onFileSelected(int? val, List<ImportFileModel> files) {
    if (val == null) return;
    final file = files.firstWhere((f) => f.importFileId == val);
    setState(() {
      _selectedFileId = val;
      _selectedFile = file;
    });
    ref.read(shipmentUpdatesProvider.notifier).fetchLogs(importFileId: val);
    ref.read(customsClearanceProvider.notifier).fetchRecords(importFileId: val);
    ref.read(warehouseReceivingProvider.notifier).fetchRecords(importFileId: val);
  }

  int _currentPhaseIndex(ImportFileModel file) {
    final mod = file.currentModule;
    for (int i = 0; i < _allPhases.length; i++) {
      if (mod.contains(_allPhases[i]['code'] as String)) return i;
    }
    return 0;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return AppTheme.crimson;
      case 'high': return AppTheme.orange;
      case 'medium': return AppTheme.cobalt;
      default: return AppTheme.emerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFilesState = ref.watch(importFilesProvider);
    final updatesState = ref.watch(shipmentUpdatesProvider);
    final clearanceState = ref.watch(customsClearanceProvider);
    final warehouseState = ref.watch(warehouseReceivingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.summarize_outlined, color: AppTheme.cobalt, size: 24),
            SizedBox(width: 10),
            Text(
              'تقرير ملف الاستيراد الشامل والمدمج',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.cobalt.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                icon: const Icon(Icons.published_with_changes, color: Colors.white, size: 16),
                label: const Text('إضافة تحديث', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () => ShipmentUpdateDialog.show(
                  context,
                  initialFileId: _selectedFile!.importFileId,
                  initialFileCode: _selectedFile!.customFileNumber ?? _selectedFile!.importFileCode,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Shipment Selector Bar ──────────────────────────────────
          Container(
            color: AppTheme.charcoal.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: importFilesState.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: AppTheme.crimson)),
              data: (files) => Row(
                children: [
                  const Icon(Icons.folder_open, color: AppTheme.cobalt, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SearchableDropdownField<int>(
                      value: _selectedFileId,
                      labelText: 'اختر ملف الاستيراد لعرض التقرير الشامل',
                      items: files.map((f) => SearchableDropdownItem<int>(
                        value: f.importFileId,
                        label: '${f.customFileNumber ?? f.importFileCode}  |  ${f.supplierName}  |  ${f.currentStage}  |  ${f.status}',
                      )).toList(),
                      onChanged: (val) => _onFileSelected(val, files),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Report Body ───────────────────────────────────────────
          Expanded(
            child: _selectedFile == null
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Header Banner
                        _buildHeaderBanner(_selectedFile!),
                        const SizedBox(height: 16),

                        // Section 2: 10-Phase Progress Pipeline
                        _buildPhasePipeline(_selectedFile!, updatesState),
                        const SizedBox(height: 16),

                        // Section 3: Two-Column Detail Cards
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COL
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildBasicInfoCard(_selectedFile!),
                                  const SizedBox(height: 14),
                                  _buildDocumentsCard(_selectedFile!),
                                  const SizedBox(height: 14),
                                  _buildInvoicesCard(_selectedFile!),
                                  const SizedBox(height: 14),
                                  _buildPackingListCard(_selectedFile!),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // RIGHT COL
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildStatusCard(_selectedFile!),
                                  const SizedBox(height: 14),
                                  _buildFinancialCard(_selectedFile!),
                                  const SizedBox(height: 14),
                                  _buildNotesCard(_selectedFile!),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 4: Live Update Logs Timeline
                        _buildUpdateTimeline(_selectedFile!, updatesState),
                        const SizedBox(height: 16),
                        
                        // Section 5: Customs Clearance Real-Time Data
                        _buildClearanceSection(clearanceState),
                        const SizedBox(height: 16),
                        
                        // Section 6: Warehouse Receiving & GRN Real-Time Data
                        _buildWarehouseSection(warehouseState),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.summarize_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'اختر ملف استيراد من القائمة أعلاه\nلعرض التقرير الشامل والمدمج',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ── Section 1: Header Banner ──────────────────────────────────────
  Widget _buildHeaderBanner(ImportFileModel file) {
    final isClosed = file.status == 'Closed';
    final phaseIdx = _currentPhaseIndex(file);
    final completedCount = isClosed ? 10 : phaseIdx;
    final remainingCount = isClosed ? 0 : (10 - phaseIdx - 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClosed
              ? [Colors.grey.shade700, Colors.grey.shade500]
              : [AppTheme.charcoal, const Color(0xFF34495E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isClosed ? Icons.archive : Icons.folder_open,
              color: isClosed ? Colors.grey.shade300 : AppTheme.cobalt,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      file.customFileNumber ?? file.importFileCode,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    _statusPill(file.status),
                    const SizedBox(width: 8),
                    _priorityPill(file.priority),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${file.supplierName}  •  ${file.companyName}',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  file.currentStage,
                  style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),

                // Progress Bar
                Row(
                  children: [
                    Text(
                      '${file.progressPercent.toStringAsFixed(0)}% مكتمل',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: file.progressPercent / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isClosed ? Colors.grey.shade400 : AppTheme.emerald,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Counters
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _counterBadge('$completedCount', 'مراحل مكتملة', AppTheme.emerald),
              const SizedBox(height: 8),
              _counterBadge('$remainingCount', 'مراحل متبقية', AppTheme.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterBadge(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    switch (status) {
      case 'Open': bg = AppTheme.cobalt; break;
      case 'In Progress': bg = AppTheme.emerald; break;
      case 'Closed': bg = Colors.grey; break;
      default: bg = AppTheme.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _priorityPill(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _priorityColor(priority).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _priorityColor(priority).withOpacity(0.5)),
      ),
      child: Text(priority, style: TextStyle(color: _priorityColor(priority), fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ── Section 2: 10-Phase Pipeline ──────────────────────────────────
  Widget _buildPhasePipeline(ImportFileModel file, ShipmentUpdatesState updatesState) {
    final currentIdx = _currentPhaseIndex(file);
    final isClosed = file.status == 'Closed';

    return _reportCard(
      title: 'خط سير مراحل الشحنة التشغيلي (10 مراحل)',
      icon: Icons.linear_scale,
      iconColor: AppTheme.cobalt,
      child: Column(
        children: [
          // Phase Stepper Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_allPhases.length, (idx) {
                final phase = _allPhases[idx];
                final pCode = phase['code'] as String;
                final phaseLogs = updatesState.logs.where((l) => l.targetPhase.contains(pCode)).toList();

                bool isCompleted = isClosed || idx < currentIdx;
                bool isCurrent = !isClosed && idx == currentIdx;

                Color dotColor = isCompleted
                    ? AppTheme.emerald
                    : isCurrent
                        ? AppTheme.cobalt
                        : Colors.grey.shade300;

                Color borderColor = isCompleted
                    ? AppTheme.emerald
                    : isCurrent
                        ? AppTheme.cobalt
                        : Colors.grey.shade300;

                Color textColor = isCompleted
                    ? Colors.green.shade800
                    : isCurrent
                        ? AppTheme.cobalt
                        : Colors.grey.shade500;

                return Row(
                  children: [
                    Container(
                      width: 130,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade50
                            : isCurrent
                                ? Colors.blue.shade50
                                : Colors.grey.shade50,
                        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : isCurrent
                                        ? Icons.play_circle_fill
                                        : Icons.radio_button_unchecked,
                                size: 16,
                                color: dotColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pCode,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              if (phaseLogs.isNotEmpty) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${phaseLogs.length}',
                                    style: const TextStyle(fontSize: 9, color: AppTheme.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phase['name'] as String,
                            style: TextStyle(fontSize: 9, color: textColor, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (phaseLogs.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              phaseLogs.first.note,
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (idx < _allPhases.length - 1)
                      Container(
                        width: 16,
                        height: 2,
                        color: idx < currentIdx ? AppTheme.emerald : Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                  ],
                );
              }),
            ),
          ),

          if (isClosed && file.closedAtPhase != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outlined, color: AppTheme.crimson, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'تم إيقاف الشحنة عند: ${file.closedAtPhase}',
                    style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  if (file.closureReason != null) ...[
                    const SizedBox(width: 8),
                    Text(' — ${file.closureReason}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section 3a: Basic Info ────────────────────────────────────────
  Widget _buildBasicInfoCard(ImportFileModel file) {
    return _reportCard(
      title: 'بيانات ملف الاستيراد الأساسية',
      icon: Icons.info_outline,
      iconColor: AppTheme.cobalt,
      child: Column(
        children: [
          _infoRow('كود الملف', file.importFileCode),
          _infoRow('رقم الملف الجمركي', file.customFileNumber ?? '—'),
          _infoRow('الشركة المستوردة', file.companyName),
          _infoRow('المورد الأجنبي', file.supplierName),
          _infoRow('المخلص الجمركي', file.brokerName ?? '—'),
          _infoRow('رقم أمر الشراء PO', file.poNumber ?? '—'),
          _infoRow('رقم الفاتورة PI', file.piNumber ?? '—'),
          _infoRow('وسيلة الشحن', file.shipmentMode),
          _infoRow('شرط التجارة (Incoterm)', file.incotermCode),
          _infoRow('فئة الشحنة', file.shipmentCategory),
          _infoRow('السيناريو المختار', file.selectedScenario ?? '—'),
          _infoRow('تاريخ الوصول المطلوب ETA', file.requiredEta ?? '—'),
          _infoRow('المسئول التشغيلي (Owner)', file.owner),
          _infoRow('تاريخ الإنشاء', file.createdAt.split('T').first),
          _infoRow('آخر تحديث', file.updatedAt.split('T').first),
        ],
      ),
    );
  }

  // ── Section 3b: Documents ─────────────────────────────────────────
  Widget _buildDocumentsCard(ImportFileModel file) {
    final docs = <Map<String, String>>[
      {'label': 'رقم الـ ACID (نافذة)', 'value': file.acidNumber ?? '—'},
      {'label': 'رقم نموذج 4 البنكي (Form 4)', 'value': file.form4No ?? '—'},
      {'label': 'رقم التحويل البنكي SWIFT', 'value': file.swiftNo ?? '—'},
      {'label': 'رقم إقرار 46 الجمركي', 'value': file.form46No ?? '—'},
    ];

    return _reportCard(
      title: 'المستندات الرسمية والوثائق الجمركية',
      icon: Icons.description_outlined,
      iconColor: AppTheme.orange,
      child: Column(
        children: docs.map((d) {
          final hasValue = d['value'] != '—';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(
                  hasValue ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                  size: 16,
                  color: hasValue ? AppTheme.emerald : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(d['label']!, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasValue ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: hasValue ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: Text(
                    d['value']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasValue ? Colors.green.shade800 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section 3c: Invoices ──────────────────────────────────────────
  Widget _buildInvoicesCard(ImportFileModel file) {
    return _reportCard(
      title: 'الفواتير التجارية المرتبطة (${file.invoicesData.length} فاتورة)',
      icon: Icons.receipt_outlined,
      iconColor: AppTheme.emerald,
      child: file.invoicesData.isEmpty
          ? const Text('لا توجد فواتير مسجلة', style: TextStyle(color: Colors.grey, fontSize: 12))
          : Column(
              children: file.invoicesData.map((inv) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt, size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(inv.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(inv.invoiceType, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text(
                        '${inv.amount.toStringAsFixed(2)} ${inv.currency}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 12),
                      ),
                      if (inv.date != null) ...[
                        const SizedBox(width: 8),
                        Text(inv.date!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ),
              )).toList(),
            ),
    );
  }

  // ── Section 3d: Packing Lists ─────────────────────────────────────
  Widget _buildPackingListCard(ImportFileModel file) {
    double totalCbm = file.packingListsData.fold(0.0, (s, p) => s + p.cbm);
    double totalWeight = file.packingListsData.fold(0.0, (s, p) => s + p.grossWeightKg);
    int totalPkgs = file.packingListsData.fold(0, (s, p) => s + p.totalPackages);

    return _reportCard(
      title: 'بيانات الباكينج ليست والشحن (${file.packingListsData.length} قائمة)',
      icon: Icons.inventory_2_outlined,
      iconColor: AppTheme.cobalt,
      child: file.packingListsData.isEmpty
          ? const Text('لا توجد بيانات باكينج ليست', style: TextStyle(color: Colors.grey, fontSize: 12))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary totals
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('الطرود الإجمالية', '$totalPkgs قطعة'),
                      _miniStat('الوزن الإجمالي', '${totalWeight.toStringAsFixed(1)} KG'),
                      _miniStat('الحجم الإجمالي CBM', '${totalCbm.toStringAsFixed(2)} m³'),
                    ],
                  ),
                ),
                ...file.packingListsData.map((pl) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 14, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Text(pl.plNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const Spacer(),
                        Text('${pl.totalPackages} طرد', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 10),
                        Text('${pl.grossWeightKg.toStringAsFixed(1)} KG', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 10),
                        Text('${pl.cbm.toStringAsFixed(2)} CBM', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      ],
                    ),
                  ),
                )),
              ],
            ),
    );
  }

  // ── Section 3e: Status Card ───────────────────────────────────────
  Widget _buildStatusCard(ImportFileModel file) {
    return _reportCard(
      title: 'الحالة التشغيلية والمرحلة الحالية',
      icon: Icons.timeline_outlined,
      iconColor: AppTheme.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: _priorityColor(file.priority)),
              const SizedBox(width: 6),
              Text('الأولوية: ${file.priority}', style: TextStyle(fontWeight: FontWeight.bold, color: _priorityColor(file.priority), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('الحالة', file.status),
          _infoRow('المرحلة الحالية', file.currentStage),
          _infoRow('المعالجة الحالية', file.currentModule),
          _infoRow('الإجراء التالي المطلوب', file.nextAction),
          const SizedBox(height: 10),
          const Text('نسبة الإنجاز الكلية:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: file.progressPercent / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      file.progressPercent >= 80 ? AppTheme.emerald : AppTheme.cobalt,
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${file.progressPercent.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section 3f: Financial Card ─────────────────────────────────────
  Widget _buildFinancialCard(ImportFileModel file) {
    double totalInvoicesValue = file.invoicesData.fold(0.0, (s, i) => s + i.amount);

    return _reportCard(
      title: 'الملخص المالي',
      icon: Icons.account_balance_outlined,
      iconColor: AppTheme.orange,
      child: Column(
        children: [
          _financialRow('قيمة الفواتير الإجمالية', '${totalInvoicesValue.toStringAsFixed(2)} USD', Colors.teal),
          _financialRow('التكلفة التقديرية الشاملة', '${file.estimatedCost.toStringAsFixed(2)} USD', AppTheme.cobalt),
          const Divider(height: 16),
          _financialRow('الفرق التقديري', '${(file.estimatedCost - totalInvoicesValue).toStringAsFixed(2)} USD',
              file.estimatedCost > totalInvoicesValue ? AppTheme.orange : AppTheme.emerald),
        ],
      ),
    );
  }

  // ── Section 3g: Notes Card ─────────────────────────────────────────
  Widget _buildNotesCard(ImportFileModel file) {
    return _reportCard(
      title: 'الملاحظات العامة',
      icon: Icons.notes_outlined,
      iconColor: AppTheme.charcoal,
      child: file.notes == null || file.notes!.isEmpty
          ? const Text('لا توجد ملاحظات عامة مسجلة.', style: TextStyle(color: Colors.grey, fontSize: 12))
          : Text(file.notes!, style: const TextStyle(fontSize: 12, height: 1.5)),
    );
  }

  // ── Section 4: Update Timeline ────────────────────────────────────
  Widget _buildUpdateTimeline(ImportFileModel file, ShipmentUpdatesState updatesState) {
    final logs = updatesState.logs;

    return _reportCard(
      title: 'سجل التحديثات والمتابعة التشغيلية اليومية (${logs.length} تحديث)',
      icon: Icons.history_outlined,
      iconColor: AppTheme.cobalt,
      child: logs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('لا توجد تحديثات تشغيلية مسجلة على هذه الشحنة حتى الآن.', style: TextStyle(color: Colors.grey))),
            )
          : Column(
              children: logs.map((log) {
                Color catColor;
                IconData catIcon;
                switch (log.updateCategory) {
                  case 'Phase Cost Adjustment':
                    catColor = AppTheme.orange;
                    catIcon = Icons.edit_note;
                    break;
                  case 'Future Phase Alert':
                    catColor = AppTheme.crimson;
                    catIcon = Icons.notification_important;
                    break;
                  case 'Daily Check-in':
                    catColor = AppTheme.emerald;
                    catIcon = Icons.today;
                    break;
                  default:
                    catColor = AppTheme.cobalt;
                    catIcon = Icons.sticky_note_2_outlined;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dot
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: catColor.withOpacity(0.12), shape: BoxShape.circle),
                            child: Icon(catIcon, size: 16, color: catColor),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Log Content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(log.updateCategory, style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.charcoal.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(log.targetPhase, style: const TextStyle(fontSize: 10, color: AppTheme.charcoal, fontWeight: FontWeight.bold)),
                                  ),
                                  const Spacer(),
                                  Text(log.logDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  const SizedBox(width: 8),
                                  Text('بواسطة: ${log.assignedUser}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(log.note, style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87)),
                              if (log.updateCategory == 'Phase Cost Adjustment' && log.adjustedCostItem != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.orange.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.swap_horiz, size: 14, color: AppTheme.orange),
                                      const SizedBox(width: 6),
                                      Text('${log.adjustedCostItem}: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text(log.previousCost.toStringAsFixed(2), style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                      const Text(' → ', style: TextStyle(fontSize: 11, color: AppTheme.orange)),
                                      Text('${log.newCost.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.orange)),
                                    ],
                                  ),
                                ),
                              ],
                              if (log.updateCategory == 'Future Phase Alert') ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.flag, size: 13, color: AppTheme.crimson),
                                    const SizedBox(width: 4),
                                    Text('درجة الأولوية: ${log.alertPriority}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.crimson, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _reportCard({required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: iconColor.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          ),
        ],
      ),
    );
  }

  Widget _financialRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildClearanceSection(AsyncValue<List<CustomsClearanceModel>> state) {
    return _reportCard(
      title: 'بيانات التخليص الجمركي (Phase 7)',
      icon: Icons.receipt_long_outlined,
      iconColor: AppTheme.cobalt,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('خطأ: $err', style: const TextStyle(color: AppTheme.crimson)),
        data: (list) {
          if (list.isEmpty) return const Text('لا توجد بيانات تخليص جمركي', style: TextStyle(color: Colors.grey));
          final clr = list.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (clr.declaration46No != null)
                    Chip(label: Text('إقرار: ${clr.declaration46No}', style: const TextStyle(fontSize: 12)), backgroundColor: Colors.blue.shade50),
                  Chip(
                    label: Text(clr.channelType, style: const TextStyle(fontSize: 12)),
                    backgroundColor: clr.channelType.toLowerCase().contains('green') ? Colors.green.shade50 : (clr.channelType.toLowerCase().contains('red') ? Colors.red.shade50 : Colors.orange.shade50),
                  ),
                  Chip(label: Text(clr.customsOfficeName, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.grey.shade100),
                ],
              ),
              const SizedBox(height: 8),
              if (clr.releasePermitNo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('تصريح إفراج: ${clr.releasePermitNo}', style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat('ضريبة الوارد', clr.importDutyAmount.toStringAsFixed(2)),
                  _miniStat('القيمة المضافة', clr.vatAmount.toStringAsFixed(2)),
                  _miniStat('ضريبة الجدول', clr.scheduleTaxAmount.toStringAsFixed(2)),
                  _miniStat('رسوم العرض', clr.labServiceFees.toStringAsFixed(2)),
                  _miniStat('الإجمالي', clr.totalDutyPayable.toStringAsFixed(2)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (clr.paymentDate != null) Text('تاريخ السداد: ${clr.paymentDate}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 16),
                  if (clr.releaseDate != null) Text('تاريخ الإفراج: ${clr.releaseDate}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarehouseSection(AsyncValue<List<WarehouseReceivingModel>> state) {
    return _reportCard(
      title: 'استلام المخازن وسند GRN (Phase 8)',
      icon: Icons.warehouse_outlined,
      iconColor: AppTheme.emerald,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('خطأ: $err', style: const TextStyle(color: AppTheme.crimson)),
        data: (list) {
          if (list.isEmpty) return const Text('لا توجد بيانات استلام مخازن', style: TextStyle(color: Colors.grey));
          final wh = list.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('GRN: ${wh.grnCode}', style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 16),
                  Text(wh.warehouseName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('وصول: ${wh.arrivalDatetime}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Text('المفتش: ${wh.inspectorName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('الكمية المفوترة', wh.totalInvoicedQty.toString()),
                  _miniStat('المقبول', wh.totalAcceptedQty.toString()),
                  _miniStat('العجز', wh.totalShortageQty.toString()),
                  _miniStat('التالف', wh.totalDamagedQty.toString()),
                ],
              ),
              const SizedBox(height: 12),
              if (wh.grnItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 32,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('الكود', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('الصنف', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('فواتير', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('مقبول', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('عجز', style: TextStyle(fontSize: 11))),
                      DataColumn(label: Text('تالف', style: TextStyle(fontSize: 11))),
                    ],
                    rows: wh.grnItems.map((item) => DataRow(cells: [
                      DataCell(Text(item.itemCode, style: const TextStyle(fontSize: 11))),
                      DataCell(Text(item.itemName, style: const TextStyle(fontSize: 11))),
                      DataCell(Text(item.invoicedQty.toString(), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(item.acceptedQty.toString(), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(item.shortageQty.toString(), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(item.damagedQty.toString(), style: const TextStyle(fontSize: 11))),
                    ])).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
