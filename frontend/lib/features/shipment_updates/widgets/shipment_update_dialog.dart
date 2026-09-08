import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
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

  static const List<String> _phaseCodes = [
    'Phase 1',
    'Phase 2',
    'Phase 3',
    'Phase 4',
    'Phase 5',
    'Phase 6',
    'Phase 7',
    'Phase 8',
    'Phase 9',
    'Phase 10',
  ];

  String _getPhaseName(AppLocalizations l, String code) {
    switch (code) {
      case 'Phase 1':
        return l.shipmentUpdatePhase1Name;
      case 'Phase 2':
        return l.shipmentUpdatePhase2Name;
      case 'Phase 3':
        return l.shipmentUpdatePhase3Name;
      case 'Phase 4':
        return l.shipmentUpdatePhase4Name;
      case 'Phase 5':
        return l.shipmentUpdatePhase5Name;
      case 'Phase 6':
        return l.shipmentUpdatePhase6Name;
      case 'Phase 7':
        return l.shipmentUpdatePhase7Name;
      case 'Phase 8':
        return l.shipmentUpdatePhase8Name;
      case 'Phase 9':
        return l.shipmentUpdatePhase9Name;
      case 'Phase 10':
        return l.shipmentUpdatePhase10Name;
      default:
        return code;
    }
  }

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
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileId == null || _selectedFileCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.shipmentUpdateFieldShipmentRequired), backgroundColor: AppTheme.crimson),
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
          SnackBar(content: Text(l.shipmentUpdateSuccessSaved), backgroundColor: AppTheme.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.shipmentUpdateErrorSaving(e.toString())), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  Expanded(
                    child: Text(
                      l.shipmentUpdateDialogTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            labelText: l.shipmentUpdateFieldShipmentLabel,
                            items: files.map((f) => SearchableDropdownItem<int>(
                              value: f.importFileId,
                              label: '${f.primaryNameWithCode} - ${f.supplierName} (${f.currentModule})',
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFileId = val;
                                if (val != null) {
                                  final sel = files.firstWhere((f) => f.importFileId == val);
                                  _selectedFileCode = sel.importFileCode;
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
                              isExpanded: true,
                              decoration: InputDecoration(labelText: l.shipmentUpdateFieldCategoryLabel, border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(value: 'Follow-up & Notes', child: Text(l.shipmentUpdateCatOptFollowUp, overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'Phase Cost Adjustment', child: Text(l.shipmentUpdateCatOptCostAdjustment, overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'Future Phase Alert', child: Text(l.shipmentUpdateCatOptFutureAlert, overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'Daily Check-in', child: Text(l.shipmentUpdateCatOptDailyCheckin, overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (v) => setState(() => _updateCategory = v!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPhase,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: l.shipmentUpdateFieldTargetStageLabel, border: const OutlineInputBorder()),
                              items: _phaseCodes.map((code) => DropdownMenuItem(value: code, child: Text(_getPhaseName(l, code), overflow: TextOverflow.ellipsis))).toList(),
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
                                decoration: InputDecoration(labelText: l.shipmentUpdateFieldCostItemLabel, border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _prevCostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: l.shipmentUpdateFieldPrevCostLabel, border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _newCostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: l.shipmentUpdateFieldNewCostLabel, border: const OutlineInputBorder()),
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
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.shipmentUpdateFieldAlertPriorityLabel, border: const OutlineInputBorder()),
                          items: [
                            DropdownMenuItem(value: 'Low', child: Text(l.shipmentUpdatePriorityLow)),
                            DropdownMenuItem(value: 'Normal', child: Text(l.shipmentUpdatePriorityNormal)),
                            DropdownMenuItem(value: 'High', child: Text(l.shipmentUpdatePriorityHigh)),
                            DropdownMenuItem(value: 'Critical', child: Text(l.shipmentUpdatePriorityCritical)),
                          ],
                          onChanged: (v) => setState(() => _alertPriority = v!),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Log Date
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: l.shipmentUpdateFieldDateLabel,
                          prefixIcon: const Icon(Icons.event),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes Input
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l.shipmentUpdateFieldNotesLabel,
                          hintText: l.shipmentUpdateFieldNotesHint,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.shipmentUpdateFieldNotesRequired : null,
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
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l.shipmentUpdateBtnCancel)),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(l.shipmentUpdateBtnSaveUpdate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
