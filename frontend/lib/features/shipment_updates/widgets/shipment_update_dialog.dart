import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/shipment_updates_provider.dart';

class ShipmentUpdateDialog extends ConsumerStatefulWidget {
  final int? initialFileId;
  final String? initialFileCode;
  final String? initialTargetPhase;
  final String? defaultCategory;

  const ShipmentUpdateDialog({
    super.key,
    this.initialFileId,
    this.initialFileCode,
    this.initialTargetPhase,
    this.defaultCategory,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialFileId,
    String? initialFileCode,
    String? initialTargetPhase,
    String? defaultCategory,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShipmentUpdateDialog(
        initialFileId: initialFileId,
        initialFileCode: initialFileCode,
        initialTargetPhase: initialTargetPhase,
        defaultCategory: defaultCategory,
      ),
    );
  }

  @override
  ConsumerState<ShipmentUpdateDialog> createState() => _ShipmentUpdateDialogState();
}

class _ShipmentUpdateDialogState extends ConsumerState<ShipmentUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noteController;
  late TextEditingController _dateController;
  late TextEditingController _costItemController;
  late TextEditingController _prevCostController;
  late TextEditingController _newCostController;

  int? _selectedFileId;
  String? _selectedFileCode;
  String _selectedPhase = 'Phase 1';
  String _updateCategory = 'Follow-up & Notes';
  String _alertPriority = 'Normal';
  final String _assignedUser = 'Kamal';
  bool _isSubmitting = false;

  static const List<Map<String, String>> _allPhases = [
    {'code': 'Phase 1', 'name': 'P1: التخطيط والجدوى'},
    {'code': 'Phase 2', 'name': 'P2: الموافقة والاعتماد المالي'},
    {'code': 'Phase 3', 'name': 'P3: المستندات والـ ACID'},
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
    _selectedFileId = widget.initialFileId;
    _selectedFileCode = widget.initialFileCode;
    _selectedPhase = widget.initialTargetPhase ?? 'Phase 1';
    _updateCategory = widget.defaultCategory ?? 'Follow-up & Notes';

    _noteController = TextEditingController();
    _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    _costItemController = TextEditingController(text: 'Freight / Duties');
    _prevCostController = TextEditingController(text: '0.0');
    _newCostController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _dateController.dispose();
    _costItemController.dispose();
    _prevCostController.dispose();
    _newCostController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileId == null || _selectedFileCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الشحنة المراد تسجيل التحديث عليها'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'import_file_id': _selectedFileId,
        'import_file_code': _selectedFileCode,
        'update_category': _updateCategory,
        'target_phase': _selectedPhase,
        'phase_status': 'Current',
        'log_date': _dateController.text,
        'note': _noteController.text.trim(),
        'adjusted_cost_item': _updateCategory == 'Phase Cost Adjustment' ? _costItemController.text.trim() : null,
        'previous_cost': _updateCategory == 'Phase Cost Adjustment' ? double.tryParse(_prevCostController.text) ?? 0.0 : 0.0,
        'new_cost': _updateCategory == 'Phase Cost Adjustment' ? double.tryParse(_newCostController.text) ?? 0.0 : 0.0,
        'alert_priority': _updateCategory == 'Future Phase Alert' ? _alertPriority : 'Normal',
        'assigned_user': _assignedUser,
      };

      await ref.read(shipmentUpdatesProvider.notifier).createLog(payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل التحديث التشغيلي / التحديث اليومي بنجاح'), backgroundColor: AppTheme.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء حفظ التحديث: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFilesState = ref.watch(importFilesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.published_with_changes, color: AppTheme.cobalt, size: 28),
                  const SizedBox(width: 10),
                  const Text('محرك تحديث الشحنات التشغيلي واليومي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Shipment Selector
                      importFilesState.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (files) {
                          return SearchableDropdownField<int>(
                            value: _selectedFileId,
                            labelText: 'اختر الشحنة المراد تحديثها *',
                            items: files.map((f) => SearchableDropdownItem<int>(
                              value: f.importFileId,
                              label: '${f.customFileNumber ?? f.importFileCode} - ${f.supplierName} (${f.currentModule})',
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFileId = val;
                                if (val != null) {
                                  final sel = files.firstWhere((f) => f.importFileId == val);
                                  _selectedFileCode = sel.customFileNumber ?? sel.importFileCode;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. Update Category & Target Phase Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _updateCategory,
                              decoration: const InputDecoration(labelText: 'نوع التحديث *', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Follow-up & Notes', child: Text('1. متابعة وملاحظات مرحلية')),
                                DropdownMenuItem(value: 'Phase Cost Adjustment', child: Text('2. تعديل بيانات / تكلفة مرحلة')),
                                DropdownMenuItem(value: 'Future Phase Alert', child: Text('3. فتح/تنبيه لمرحلة قادمة')),
                                DropdownMenuItem(value: 'Daily Check-in', child: Text('4. تحديث يومي عن الشحنة')),
                              ],
                              onChanged: (v) => setState(() => _updateCategory = v!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPhase,
                              decoration: const InputDecoration(labelText: 'المرحلة المستهدفة *', border: OutlineInputBorder()),
                              items: _allPhases.map((p) => DropdownMenuItem(value: p['code']!, child: Text(p['name']!))).toList(),
                              onChanged: (v) => setState(() => _selectedPhase = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Conditional Type B: Phase Cost Adjustment Fields
                      if (_updateCategory == 'Phase Cost Adjustment') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _costItemController,
                                decoration: const InputDecoration(labelText: 'بند التكلفة / البيان المعدل', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _prevCostController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'التكلفة السابقة', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _newCostController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'التكلفة الجديدة المعدلة', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Conditional Type C: Future Phase Alert Fields
                      if (_updateCategory == 'Future Phase Alert') ...[
                        DropdownButtonFormField<String>(
                          value: _alertPriority,
                          decoration: const InputDecoration(labelText: 'درجة أولوية التنبيه للمرحلة القادمة', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Normal', child: Text('عادي (Normal)')),
                            DropdownMenuItem(value: 'High', child: Text('عالي (High Priority)')),
                            DropdownMenuItem(value: 'Critical', child: Text('حرج (Critical Alert)')),
                          ],
                          onChanged: (v) => setState(() => _alertPriority = v!),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Log Date
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ التحديث اليومي / المتابعة',
                          prefixIcon: Icon(Icons.event),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes Input
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'نص التحديث اليومي / الملاحظة التشغيلية التفصيلية *',
                          hintText: 'اكتب تفاصيل المتابعة، موقف الشحنة بالميناء، توجيهات المخلص...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'ملاحظات التحديث مطلوبة' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.white),
                    label: const Text('حفظ التحديث التشغيلي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
