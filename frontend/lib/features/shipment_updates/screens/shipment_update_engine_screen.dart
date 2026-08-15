import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';

import 'package:printing/printing.dart';

import '../../customs_consultation/models/customs_consultation_model.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_consultation/services/customs_consultation_pdf_service.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../import_files/models/import_file_model.dart';
import '../models/shipment_update_model.dart';
import '../providers/shipment_updates_provider.dart';
import '../widgets/shipment_update_dialog.dart';

class ShipmentUpdateEngineScreen extends ConsumerStatefulWidget {
  const ShipmentUpdateEngineScreen({super.key});

  @override
  ConsumerState<ShipmentUpdateEngineScreen> createState() => _ShipmentUpdateEngineScreenState();
}

class _ShipmentUpdateEngineScreenState extends ConsumerState<ShipmentUpdateEngineScreen> {
  int? _selectedFileId;
  ImportFileModel? _selectedFile;
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _allPhases = [
    {'code': 'Phase 1', 'name': 'P1: التخطيط والجدوى'},
    {'code': 'Phase 2', 'name': 'P2: الاعتماد المالي'},
    {'code': 'Phase 3', 'name': 'P3: المستندات و ACID'},
    {'code': 'Phase 4', 'name': 'P4: حجز الشحن والناقل'},
    {'code': 'Phase 5', 'name': 'P5: الشحن وتتبع CargoX'},
    {'code': 'Phase 6', 'name': 'P6: إقرار 46 والتعريفه'},
    {'code': 'Phase 7', 'name': 'P7: التخليص وسداد الرسوم'},
    {'code': 'Phase 8', 'name': 'P8: استلام المخازن GRN'},
    {'code': 'Phase 9', 'name': 'P9: تسوية تكلفة الوصول'},
    {'code': 'Phase 10', 'name': 'P10: إغلاق الملف والأرشفة'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles().then((_) {
        final files = ref.read(importFilesProvider).value ?? [];
        if (files.isNotEmpty && _selectedFileId == null) {
          setState(() {
            _selectedFileId = files.first.importFileId;
            _selectedFile = files.first;
          });
          ref.read(shipmentUpdatesProvider.notifier).fetchLogs(importFileId: files.first.importFileId);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onShipmentSelected(int? val, List<ImportFileModel> files) {
    if (val == null) return;
    final file = files.firstWhere((f) => f.importFileId == val);
    setState(() {
      _selectedFileId = val;
      _selectedFile = file;
    });
    ref.read(shipmentUpdatesProvider.notifier).fetchLogs(importFileId: val);
  }

  @override
  Widget build(BuildContext context) {
    final importFilesState = ref.watch(importFilesProvider);
    final updatesState = ref.watch(shipmentUpdatesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.published_with_changes, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('محرك تحديث الشحنات التشغيلي واليومي (Operational & Daily Update Engine)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(importFilesProvider.notifier).fetchImportFiles();
              if (_selectedFileId != null) {
                ref.read(shipmentUpdatesProvider.notifier).fetchLogs(importFileId: _selectedFileId);
              }
            },
          ),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar: Shipment Selector Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: importFilesState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('خطأ في تحميل الشحنات: $err', style: const TextStyle(color: AppTheme.crimson)),
                  data: (files) {
                    if (files.isEmpty) {
                      return const Text('لا توجد شحنات مسجلة بالنظام حتى الآن.');
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: SearchableDropdownField<int>(
                            value: _selectedFileId,
                            labelText: 'اختر الشحنة لتشغيل محرك التحديث والفحص المرحلي',
                            items: files.map((f) => SearchableDropdownItem<int>(
                              value: f.importFileId,
                              label: '${f.customFileNumber ?? f.importFileCode} | المورد: ${f.supplierName} | المرحلة الحالية: ${f.currentModule}',
                            )).toList(),
                            onChanged: (val) => _onShipmentSelected(val, files),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                          onPressed: _selectedFile == null
                              ? null
                              : () {
                                  ShipmentUpdateDialog.show(
                                    context,
                                    initialFileId: _selectedFile!.importFileId,
                                    initialFileCode: _selectedFile!.customFileNumber ?? _selectedFile!.importFileCode,
                                    initialTargetPhase: _selectedFile!.currentModule,
                                    defaultCategory: 'Daily Check-in',
                                  );
                                },
                          icon: const Icon(Icons.today, color: Colors.white),
                          label: const Text('تحديث يومي شامل عن الشحنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visual 10-Phase Pipeline Inspector Component
            if (_selectedFile != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub, color: AppTheme.cobalt, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'المخطط التفاعلي لمراحل الشحنة (${_selectedFile!.customFileNumber ?? _selectedFile!.importFileCode}) — اضغط على أي مرحلة للتحديث:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                          ),
                          const Spacer(),
                          Text(
                            'المرحلة الحالية: ${_selectedFile!.currentModule}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Inspected Phases Stepper
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _allPhases.map((phaseMap) {
                            final pCode = phaseMap['code']!;
                            final pName = phaseMap['name']!;

                            // Find inspection data
                            final insp = updatesState.inspectedPhases.firstWhere(
                              (ip) => ip.phaseCode == pCode,
                              orElse: () => PhaseInspectionModel(phaseCode: pCode, phaseName: pName, phaseNumber: 1, status: 'Future', updateCount: 0),
                            );

                            Color tileBg = Colors.grey.shade100;
                            Color borderCol = Colors.grey.shade300;
                            Color textCol = Colors.grey.shade700;
                            IconData statusIcon = Icons.hourglass_empty;

                            if (insp.status == 'Completed') {
                              tileBg = Colors.green.shade50;
                              borderCol = AppTheme.emerald;
                              textCol = Colors.green.shade900;
                              statusIcon = Icons.check_circle;
                            } else if (insp.status == 'Current') {
                              tileBg = Colors.blue.shade50;
                              borderCol = AppTheme.cobalt;
                              textCol = AppTheme.cobalt;
                              statusIcon = Icons.play_circle_fill;
                            } else {
                              tileBg = Colors.orange.shade50;
                              borderCol = Colors.orange.shade300;
                              textCol = Colors.orange.shade900;
                              statusIcon = Icons.upcoming;
                            }

                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 140,
                              child: InkWell(
                                onTap: () {
                                  ShipmentUpdateDialog.show(
                                    context,
                                    initialFileId: _selectedFile!.importFileId,
                                    initialFileCode: _selectedFile!.customFileNumber ?? _selectedFile!.importFileCode,
                                    initialTargetPhase: pCode,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: tileBg, border: Border.all(color: borderCol), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(statusIcon, size: 16, color: borderCol),
                                          const SizedBox(width: 6),
                                          Text(insp.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: borderCol)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(pName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textCol), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      Text('التحديثات: ${insp.updateCount} سجلات', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── CUSTOMS CONSULTATION & INSPECTION RESULTS CARD ──────────────
            if (_selectedFile != null) ...[
              _buildCustomsConsultationSection(
                (ref.watch(customsConsultationsProvider).value ?? []).where((c) =>
                    (c.importFileId != null && c.importFileId == _selectedFileId) ||
                    (c.importFileCode != null && c.importFileCode == (_selectedFile!.customFileNumber ?? _selectedFile!.importFileCode)) ||
                    (c.importFileCode != null && c.importFileCode == _selectedFile!.importFileCode)
                ).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Master Data Toolbar (Data Actions & Export/Import)
            MasterDataToolbarWidget(
              moduleEndpoint: 'shipment-updates',
              title: 'Shipment_Updates',
              onRefreshNeeded: () {
                if (_selectedFileId != null) {
                  ref.read(shipmentUpdatesProvider.notifier).fetchLogs(importFileId: _selectedFileId);
                  ref.read(customsConsultationsProvider.notifier).fetchConsultations();
                }
              },
            ),
            const SizedBox(height: 12),

            // Live Update Logs Table (سجل التحديثات والتحديث اليومي)
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: updatesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : updatesState.error != null
                        ? Center(child: Text('خطأ في جلب سجل التحديثات: ${updatesState.error}', style: const TextStyle(color: AppTheme.crimson)))
                        : updatesState.logs.isEmpty
                            ? const Center(child: Text('لا توجد تحديثات تشغيلية مسجلة لهذه الشحنة حتى الآن.'))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                    columns: const [
                                      DataColumn(label: Text('⚡ العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('كود التحديث', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('نوع التحديث', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المرحلة المستهدفة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('ملاحظة وتفاصيل التحديث اليومي والتشغيلي', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('تعديل التكلفة (Cost Adjustment)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المسئول', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: updatesState.logs.map((log) {
                                      final isCostAdj = log.updateCategory == 'Phase Cost Adjustment';
                                      final isDaily = log.updateCategory == 'Daily Check-in';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            RowActionsPill(
                                              onView: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: Text('تفاصيل التحديث: ${log.updateCode}'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('المرحلة: ${log.targetPhase}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                        Text('التاريخ: ${log.logDate}'),
                                                        Text('المسئول: ${log.assignedUser}'),
                                                        const SizedBox(height: 8),
                                                        Text('الملاحظات:\n${log.note}'),
                                                      ],
                                                    ),
                                                    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))],
                                                  ),
                                                );
                                              },
                                              onEdit: () {
                                                ShipmentUpdateDialog.show(
                                                  context,
                                                  initialFileId: log.importFileId,
                                                  initialTargetPhase: log.targetPhase,
                                                  defaultCategory: log.updateCategory,
                                                );
                                              },
                                              onPrint: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('طباعة سجل التحديث التشغيلي: ${log.updateCode} (${log.targetPhase})'),
                                                    backgroundColor: AppTheme.charcoal,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              onDelete: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: const Text('تأكيد الحذف'),
                                                    content: Text('هل أنت متأكد من حذف سجل التحديث ${log.updateCode}؟'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                                        onPressed: () => Navigator.pop(c, true),
                                                        child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  ref.read(shipmentUpdatesProvider.notifier).deleteLog(log.updateId);
                                                }
                                              },
                                              viewTooltip: 'عرض تفاصيل التحديث',
                                              editTooltip: 'تعديل التحديث',
                                              printTooltip: 'طباعة سجل التحديث',
                                              deleteTooltip: 'حذف سجل التحديث',
                                            ),
                                          ),
                                          DataCell(Text(log.updateCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                          DataCell(Text(log.logDate)),
                                          DataCell(
                                            Chip(
                                              label: Text(isDaily ? 'تحديث يومي' : log.updateCategory, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                              backgroundColor: isDaily ? AppTheme.emerald : (isCostAdj ? AppTheme.orange : AppTheme.cobalt),
                                            ),
                                          ),
                                          DataCell(Text(log.targetPhase, style: const TextStyle(fontWeight: FontWeight.bold))),
                                          DataCell(
                                            SizedBox(
                                              width: 320,
                                              child: Text(log.note, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ),
                                          ),
                                          DataCell(
                                            isCostAdj
                                                ? Text('${log.adjustedCostItem ?? "Cost"}: ${log.previousCost} ➔ ${log.newCost} USD', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 11))
                                                : const Text('-'),
                                          ),
                                          DataCell(Text(log.assignedUser)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomsConsultationSection(List<CustomsConsultationModel> consultations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel_rounded, color: AppTheme.cobalt, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'سجل ونتائج دراسة الاستشارة الجمركية والفحص المستندي (Customs Consultation & Inspection Records)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: consultations.isNotEmpty ? AppTheme.emerald.withOpacity(0.12) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: consultations.isNotEmpty ? AppTheme.emerald.withOpacity(0.4) : Colors.grey.shade300),
                  ),
                  child: Text(
                    consultations.isNotEmpty ? '${consultations.length} دراسة مسجلة ومحفوظة' : 'لا توجد دراسة مسجلة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: consultations.isNotEmpty ? AppTheme.emerald : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (consultations.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.cobalt, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لم يتم حفظ دراسة استشارة جمركية بعد لملف هذه الشحنة. يمكنك فتح "مركز الاستشارة الجمركية (BP-009)" لإنشاء ومزامنة بنود التعريفة وقائمة المستندات.',
                        style: TextStyle(fontSize: 12, color: AppTheme.charcoal, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...consultations.map((c) {
                final readinessPct = c.readinessPercentage;
                final hasBlocking = c.hasBlockingIssues || c.blockingIssuesCount > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Code, Title, Broker, Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                            ),
                            child: Text(
                              c.consultationCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('المستخلص: ${c.brokerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(width: 10),
                          _buildCustomsStatusBadge(c.overallStatus),
                        ],
                      ),
                      const Divider(height: 18),

                      // Metrics & Quick Status Bar
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildMetricBadge(
                            '💰 الرسوم التقديرية',
                            '${c.estimatedDutiesEgp.toStringAsFixed(0)} EGP',
                            AppTheme.crimson,
                          ),
                          _buildMetricBadge(
                            '📄 المستندات المعتمدة',
                            '${c.approvedDocumentsCount} من ${c.totalDocumentsCount} مستند',
                            Colors.green.shade800,
                          ),
                          _buildMetricBadge(
                            '🚫 عوائق التخليص (Blocking)',
                            hasBlocking ? '${c.blockingIssuesCount} عائق معطل' : '0 عوائق (جاهز)',
                            hasBlocking ? AppTheme.crimson : AppTheme.emerald,
                          ),
                          // Progress Bar
                          Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('نسبة الجاهزية:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text(
                                      '${readinessPct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: readinessPct >= 80 ? AppTheme.emerald : (readinessPct >= 50 ? Colors.orange : AppTheme.crimson),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (readinessPct / 100).clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      readinessPct >= 80 ? AppTheme.emerald : (readinessPct >= 50 ? Colors.orange : AppTheme.crimson),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Actions Row: View, Edit, Print & Daily Update
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.charcoal,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              Printing.layoutPdf(
                                onLayout: (format) =>
                                    CustomsConsultationPdfService.generateConsultationPdf(c),
                                name: 'Customs_Consultation_${c.consultationCode}',
                              );
                            },
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('طباعة التقرير (PDF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.cobalt,
                              side: const BorderSide(color: AppTheme.cobalt),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _showConsultationDetailsDialog(c, initialEditMode: false),
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('استعراض قائمة الفحص', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.orange,
                              side: const BorderSide(color: AppTheme.orange),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _showConsultationDetailsDialog(c, initialEditMode: true),
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('تعديل ومراجعة المستندات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emerald,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              ShipmentUpdateDialog.show(
                                context,
                                initialFileId: _selectedFile!.importFileId,
                                initialFileCode: _selectedFile!.customFileNumber ?? _selectedFile!.importFileCode,
                                initialTargetPhase: 'Phase 6',
                                defaultCategory: 'Daily Check-in',
                              );
                            },
                            icon: const Icon(Icons.post_add_rounded, color: Colors.white, size: 16),
                            label: const Text('تسجيل تحديث يومي', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showConsultationDetailsDialog(CustomsConsultationModel session, {bool initialEditMode = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isEditing = initialEditMode;
        bool isSaving = false;
        String selectedStatus = session.overallStatus;
        final List<CustomsChecklistItemModel> editableItems = session.checklistItems
            .map((item) => CustomsChecklistItemModel(
                  itemId: item.itemId,
                  consultationId: item.consultationId,
                  documentType: item.documentType,
                  hsCode: item.hsCode,
                  isRequired: item.isRequired,
                  isBlockingShipment: item.isBlockingShipment,
                  responsibleParty: item.responsibleParty,
                  regulatoryAgency: item.regulatoryAgency,
                  status: item.status,
                  remarks: item.remarks,
                ))
            .toList();

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final approvedCount = editableItems.where((i) => i.status == 'Approved' || i.status == 'Verified').length;
            final totalCount = editableItems.length;
            final blockingCount = editableItems.where((i) => i.isBlockingShipment && i.status != 'Approved' && i.status != 'Verified').length;
            final readinessPct = totalCount > 0 ? (approvedCount / totalCount * 100) : 0.0;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.assignment_turned_in, color: AppTheme.cobalt),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing
                          ? '✏️ تعديل ومراجعة دراسة الاستشارة: ${session.consultationCode}'
                          : 'تفاصيل دراسة الاستشارة الجمركية: ${session.consultationCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded, color: AppTheme.charcoal),
                    tooltip: 'طباعة تقرير الاستشارة الجمركية (PDF)',
                    onPressed: () {
                      Printing.layoutPdf(
                        onLayout: (format) =>
                            CustomsConsultationPdfService.generateConsultationPdf(session),
                        name: 'Customs_Consultation_${session.consultationCode}',
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(isEditing ? Icons.visibility_rounded : Icons.edit_rounded,
                        color: isEditing ? AppTheme.cobalt : AppTheme.orange),
                    tooltip: isEditing ? 'التبديل إلى وضع العرض' : 'التبديل إلى وضع التعديل',
                    onPressed: () => setDialogState(() => isEditing = !isEditing),
                  ),
                ],
              ),
              content: SizedBox(
                width: 850,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isEditing ? Colors.amber.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isEditing ? Colors.orange.shade300 : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المستخلص: ${session.brokerName}', style: const TextStyle(fontSize: 12)),
                            Text('الرسوم التقديرية: ${session.estimatedDutiesEgp.toStringAsFixed(2)} EGP',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 12)),
                            if (isEditing)
                              Row(
                                children: [
                                  const Text('الحالة العامة: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  DropdownButton<String>(
                                    value: selectedStatus,
                                    isDense: true,
                                    items: const [
                                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                      DropdownMenuItem(value: 'Clearance Ready', child: Text('Clearance Ready')),
                                      DropdownMenuItem(value: 'Blocked', child: Text('Blocked')),
                                      DropdownMenuItem(value: 'Action Required', child: Text('Action Required')),
                                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() => selectedStatus = val);
                                      }
                                    },
                                  ),
                                ],
                              )
                            else
                              Text('الحالة: ${session.overallStatus}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metrics Summary
                      Row(
                        children: [
                          _buildMetricBadge('نسبة الجاهزية', '${readinessPct.toStringAsFixed(0)}%', readinessPct >= 80 ? Colors.green : Colors.blue),
                          const SizedBox(width: 8),
                          _buildMetricBadge('إجمالي المستندات', '$totalCount', Colors.grey),
                          const SizedBox(width: 8),
                          _buildMetricBadge('المعتمد', '$approvedCount', Colors.green),
                          const SizedBox(width: 8),
                          _buildMetricBadge('عوائق التخليص (Blocking)', '$blockingCount', blockingCount > 0 ? Colors.red : Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Text('قائمة فحص المستندات والاشتراطات الجمركية المربوطة بالشحنة:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const Spacer(),
                          if (isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('⚡ وضع التعديل التفاعلي مفعل — اضغط لتحديث حالة أي مستند',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Checklist Table
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columnWidths: const {
                          0: FlexColumnWidth(2.8),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.4),
                          3: FlexColumnWidth(2.2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                            children: const [
                              Padding(padding: EdgeInsets.all(8), child: Text('نوع المستند والبنود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('الجهة المسؤولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('ملاحظات والاشتراطات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            ],
                          ),
                          ...editableItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final doc = entry.value;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: idx % 2 == 1 ? Colors.grey.shade50 : Colors.white,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (doc.isBlockingShipment)
                                            const Tooltip(
                                              message: 'عائق معطل للشحن/التخليص الجمركي',
                                              child: Icon(Icons.block, color: Colors.red, size: 14),
                                            ),
                                          if (doc.isBlockingShipment) const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              doc.documentType,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11.5,
                                                color: doc.isBlockingShipment ? Colors.red.shade900 : AppTheme.charcoal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (doc.hsCode != null && doc.hsCode!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text('بنود: ${doc.hsCode}',
                                              style: const TextStyle(fontSize: 10, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(doc.responsibleParty, style: const TextStyle(fontSize: 11)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: isEditing
                                      ? DropdownButton<String>(
                                          value: doc.status,
                                          isDense: true,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.charcoal, fontWeight: FontWeight.bold),
                                          items: const [
                                            DropdownMenuItem(value: 'Approved', child: Text('🟢 Approved')),
                                            DropdownMenuItem(value: 'Pending', child: Text('🟠 Pending')),
                                            DropdownMenuItem(value: 'Received', child: Text('🔵 Received')),
                                            DropdownMenuItem(value: 'Verified', child: Text('🟣 Verified')),
                                            DropdownMenuItem(value: 'Rejected', child: Text('🔴 Rejected')),
                                          ],
                                          onChanged: (newSt) {
                                            if (newSt != null) {
                                              setDialogState(() {
                                                editableItems[idx] = CustomsChecklistItemModel(
                                                  itemId: doc.itemId,
                                                  consultationId: doc.consultationId,
                                                  documentType: doc.documentType,
                                                  hsCode: doc.hsCode,
                                                  isRequired: doc.isRequired,
                                                  isBlockingShipment: doc.isBlockingShipment,
                                                  responsibleParty: doc.responsibleParty,
                                                  regulatoryAgency: doc.regulatoryAgency,
                                                  status: newSt,
                                                  remarks: doc.remarks,
                                                );
                                              });
                                            }
                                          },
                                        )
                                      : _buildDocItemStatusBadge(doc.status),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(doc.remarks ?? '-', style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.charcoal),
                  onPressed: () {
                    Printing.layoutPdf(
                      onLayout: (format) =>
                          CustomsConsultationPdfService.generateConsultationPdf(session),
                      name: 'Customs_Consultation_${session.consultationCode}',
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('طباعة التقرير (PDF)'),
                ),
                if (isEditing)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setDialogState(() => isSaving = true);
                            try {
                              final payload = {
                                'overall_status': selectedStatus,
                                'checklist_items': editableItems.map((item) => item.toJson()).toList(),
                              };
                              await ref
                                  .read(customsConsultationsProvider.notifier)
                                  .updateConsultation(session.consultationId, payload);
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ تم حفظ وتحديث دراسة الاستشارة الجمركية ${session.consultationCode} بنجاح!'),
                                    backgroundColor: AppTheme.emerald,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطأ في حفظ التعديلات: $e'), backgroundColor: AppTheme.crimson),
                                );
                              }
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, color: Colors.white, size: 16),
                    label: Text(
                      isSaving ? 'جاري الحفظ...' : '💾 حفظ التعديلات',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إغلاق'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCustomsStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Clearance Ready') bg = Colors.green;
    if (status == 'Blocked') bg = Colors.red;
    if (status == 'Action Required') bg = Colors.orange;
    if (status == 'In Progress') bg = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildDocItemStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Approved') bg = Colors.green;
    if (status == 'Rejected') bg = Colors.red;
    if (status == 'Verified') bg = Colors.blue;
    if (status == 'Received') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
