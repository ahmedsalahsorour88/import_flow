import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
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
                                      DataColumn(label: Text('كود التحديث', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('نوع التحديث', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المرحلة المستهدفة', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('ملاحظة وتفاصيل التحديث اليومي والتشغيلي', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('تعديل التكلفة (Cost Adjustment)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المسئول', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: updatesState.logs.map((log) {
                                      final isCostAdj = log.updateCategory == 'Phase Cost Adjustment';
                                      final isDaily = log.updateCategory == 'Daily Check-in';

                                      return DataRow(
                                        cells: [
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
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              onPressed: () => ref.read(shipmentUpdatesProvider.notifier).deleteLog(log.updateId),
                                            ),
                                          ),
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
}
