import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/demurrage_model.dart';
import '../providers/demurrage_provider.dart';

/// BK-02: تسجيل وتوثيق فترات السماح المجانية الممنوحة للحاويات
/// يتيح لضابط اللوجستيات توثيق الاتفاق مع الخط الملاحي لتغذية رادار الغرامات تلقائياً.
class FreeDaysAgreementDialog extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  final String? initialCarrierName;
  final int? initialDemurrageDays;
  final int? initialDetentionDays;

  const FreeDaysAgreementDialog({
    super.key,
    this.initialImportFileId,
    this.initialCarrierName,
    this.initialDemurrageDays,
    this.initialDetentionDays,
  });

  static Future<FreeDaysAgreementModel?> show(
    BuildContext context, {
    int? initialImportFileId,
    String? initialCarrierName,
    int? initialDemurrageDays,
    int? initialDetentionDays,
  }) {
    return showDialog<FreeDaysAgreementModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FreeDaysAgreementDialog(
        initialImportFileId: initialImportFileId,
        initialCarrierName: initialCarrierName,
        initialDemurrageDays: initialDemurrageDays,
        initialDetentionDays: initialDetentionDays,
      ),
    );
  }

  @override
  ConsumerState<FreeDaysAgreementDialog> createState() => _FreeDaysAgreementDialogState();
}

class _FreeDaysAgreementDialogState extends ConsumerState<FreeDaysAgreementDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedImportFileId;
  String _carrierName = 'MSC';
  late final TextEditingController _demurrageController;
  late final TextEditingController _detentionController;
  late final TextEditingController _storageController;
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _agreementDate = DateTime.now();
  bool _isSubmitting = false;
  bool _isLoadingExisting = false;

  final List<String> _carriers = [
    'MSC',
    'Maersk',
    'CMA CGM',
    'COSCO',
    'Hapag-Lloyd',
    'ONE',
    'Evergreen',
    'Yang Ming',
    'OOCL',
    'ZIM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    if (widget.initialCarrierName != null && widget.initialCarrierName!.isNotEmpty) {
      _carrierName = widget.initialCarrierName!;
    }
    _demurrageController = TextEditingController(
      text: (widget.initialDemurrageDays ?? 21).toString(),
    );
    _detentionController = TextEditingController(
      text: (widget.initialDetentionDays ?? 14).toString(),
    );
    _storageController = TextEditingController(text: '5');

    if (_selectedImportFileId != null) {
      _loadExistingAgreement(_selectedImportFileId!);
    }
  }

  @override
  void dispose() {
    _demurrageController.dispose();
    _detentionController.dispose();
    _storageController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAgreement(int fileId) async {
    setState(() => _isLoadingExisting = true);
    try {
      final agr = await ref.read(demurrageProvider.notifier).fetchFreeDaysAgreement(fileId);
      if (agr != null && mounted) {
        setState(() {
          if (agr.carrierName.isNotEmpty) {
            _carrierName = agr.carrierName;
          }
          _demurrageController.text = agr.agreedDemurrageFreeDays.toString();
          _detentionController.text = agr.agreedDetentionFreeDays.toString();
          _storageController.text = agr.portStorageFreeDays.toString();
          if (agr.agreementReference != null) {
            _refController.text = agr.agreementReference!;
          }
          if (agr.notes != null) {
            _notesController.text = agr.notes!;
          }
          if (agr.agreementDate != null) {
            try {
              _agreementDate = DateTime.parse(agr.agreementDate!);
            } catch (_) {}
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  int get _demDays => int.tryParse(_demurrageController.text) ?? 14;
  int get _detDays => int.tryParse(_detentionController.text) ?? 7;
  int get _storDays => int.tryParse(_storageController.text) ?? 5;

  int get _savedDemDays => (_demDays - 14) > 0 ? (_demDays - 14) : 0;
  int get _savedDetDays => (_detDays - 7) > 0 ? (_detDays - 7) : 0;
  double get _estimatedCostAvoidance => (_savedDemDays * 60.0) + (_savedDetDays * 45.0);

  Future<void> _handleSubmit() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى تحديد ملف الاستيراد المرتبط بالاتفاقية' : 'Please select an import file')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'import_file_id': _selectedImportFileId,
        'carrier_name': _carrierName,
        'agreed_demurrage_free_days': _demDays,
        'agreed_detention_free_days': _detDays,
        'port_storage_free_days': _storDays,
        'agreement_reference': _refController.text.trim().isEmpty ? null : _refController.text.trim(),
        'agreement_date': _agreementDate.toIso8601String().split('T').first,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      final result = await ref.read(demurrageProvider.notifier).registerFreeDaysAgreement(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.flatEmerald,
            content: Text(
              result != null
                  ? (isAr
                      ? 'تم توثيق فترات السماح (${result.agreedDemurrageFreeDays} يوم) وتحديث رادار الغرامات بنجاح'
                      : 'Free days (${result.agreedDemurrageFreeDays} days) documented & radar updated successfully')
                  : (isAr
                      ? 'تم توثيق فترات السماح وتحديث رادار الغرامات بنجاح'
                      : 'Free days documented & radar updated successfully'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.flatCrimson,
            content: Text(isAr ? 'فشل في توثيق فترات السماح: $e' : 'Failed to document free days: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool get _isDirty {
    if (_selectedImportFileId != widget.initialImportFileId) return true;
    if (_refController.text.trim().isNotEmpty) return true;
    if (_notesController.text.trim().isNotEmpty) return true;
    if (_carrierName != (widget.initialCarrierName ?? 'MSC')) return true;
    if (_demDays != (widget.initialDemurrageDays ?? 14)) return true;
    if (_detDays != (widget.initialDetentionDays ?? 7)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final importFiles = ref.watch(importFilesProvider).asData?.value ?? [];

    return UnsavedChangesGuard(
      isDirty: _isDirty,
      child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.flatEmerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.flatEmerald,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'توثيق اتفاقية فترات السماح المجانية (BK-02)' : 'Free Days Agreement (BK-02)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.flatCharcoal,
                            ),
                          ),
                          Text(
                            isAr ? 'توثيق فترات السماح وتغذية رادار الغرامات' : 'Free Days Agreement & Demurrage Radar Feed',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoadingExisting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => UnsavedChangesGuard.maybePop(context, isDirty: _isDirty),
                      tooltip: isAr ? 'إغلاق' : 'Close',
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Content scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Import File selection
                        SearchableDropdownField<int>(
                          labelText: isAr ? 'ملف الاستيراد المرتبط' : 'Linked Import File',
                          isRequired: true,
                          value: _selectedImportFileId,
                          items: importFiles
                              .map(
                                (f) => SearchableDropdownItem<int>(
                                  value: f.importFileId,
                                  label: '${f.importFileCode} - ${f.supplierName}',
                                  subtitle: isAr ? 'فترات السماح الحالية: ${f.targetFreeDays ?? 14} يوم' : 'Current free days: ${f.targetFreeDays ?? 14} days',
                                ),
                              )
                              .toList(),
                          onChanged: widget.initialImportFileId != null
                              ? null
                              : (val) {
                                  setState(() => _selectedImportFileId = val);
                                  if (val != null) {
                                    _loadExistingAgreement(val);
                                  }
                                },
                          validator: (val) => val == null ? (isAr ? 'يرجى اختيار ملف الاستيراد' : 'Please select an import file') : null,
                        ),
                        const SizedBox(height: 16),

                        // Carrier & Agreement Date
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SearchableDropdownField<String>(
                                labelText: isAr ? 'الخط الملاحي (Carrier)' : 'Shipping Carrier',
                                isRequired: true,
                                value: _carrierName,
                                items: _carriers
                                    .map(
                                      (c) => SearchableDropdownItem<String>(
                                        value: c,
                                        label: c,
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _carrierName = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _agreementDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _agreementDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'تاريخ الاتفاقية' : 'Agreement Date',
                                    prefixIcon: const Icon(Icons.calendar_today, size: 18),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _agreementDate.toIso8601String().split('T').first,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section Title: Agreed Free Days
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 18, color: AppTheme.flatCobalt),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isAr ? 'فترات السماح المتفق عليها بالملحق (Agreed Free Days)' : 'Agreed Free Days in Annex',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.flatCharcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Free Days Inputs
                        Row(
                          children: [
                            // Demurrage
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _demurrageController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isAr ? 'أرضيات الحاوية بالميناء (Demurrage)' : 'Port Demurrage',
                                      suffixText: isAr ? 'يوم' : 'days',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (val) {
                                      final v = int.tryParse(val ?? '');
                                      if (v == null || v < 1) return isAr ? 'أدخل عدداً صحيحاً' : 'Enter a valid number';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: [14, 21, 28].map((days) {
                                      return ActionChip(
                                        label: Text(isAr ? '$days يوم' : '$days days', style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          setState(() => _demurrageController.text = days.toString());
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Detention
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _detentionController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isAr ? 'فترة خروج الحاوية (Detention)' : 'Detention Period',
                                      suffixText: isAr ? 'يوم' : 'days',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (val) {
                                      final v = int.tryParse(val ?? '');
                                      if (v == null || v < 1) return isAr ? 'أدخل عدداً صحيحاً' : 'Enter a valid number';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: [7, 14, 21].map((days) {
                                      return ActionChip(
                                        label: Text(isAr ? '$days يوم' : '$days days', style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          setState(() => _detentionController.text = days.toString());
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Port Storage
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _storageController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isAr ? 'سماح الساحة (Port Storage)' : 'Port Storage',
                                      suffixText: isAr ? 'يوم' : 'days',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (val) {
                                      final v = int.tryParse(val ?? '');
                                      if (v == null || v < 0) return isAr ? 'أدخل عدداً صحيحاً' : 'Enter a valid number';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: [3, 5, 7].map((days) {
                                      return ActionChip(
                                        label: Text(isAr ? '$days أيام' : '$days days', style: const TextStyle(fontSize: 11)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          setState(() => _storageController.text = days.toString());
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Document Reference & Notes
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _refController,
                                decoration: InputDecoration(
                                  labelText: isAr ? 'مرجع بند الاتفاقية / ملحق الحجز' : 'Agreement Clause / Booking Annex Ref',
                                  hintText: 'e.g. MSC-FREE-2026-0042 Clause 4.2',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.receipt_long, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  labelText: isAr ? 'ملاحظات الاتفاقية' : 'Agreement Notes',
                                  hintText: isAr ? 'e.g. تم التفاوض وتثبيت 21 يوماً لحاويات الخط' : 'e.g. Negotiated and confirmed 21 days for line containers',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Cost Avoidance & Benefit Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.flatEmerald.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.flatEmerald.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.savings_outlined,
                                        color: AppTheme.flatEmerald,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAr ? 'تحليل الوفر المالي وتغذية رادار الغرامات:' : 'Financial Savings & Radar Analysis:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.flatEmerald,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.flatEmerald,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isAr ? 'وفر متوقع: \$${_estimatedCostAvoidance.toStringAsFixed(0)} / حاوية' : 'Estimated savings: \$${_estimatedCostAvoidance.toStringAsFixed(0)} / ctr',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricItem(
                                      isAr ? 'أيام إضافية Demurrage' : 'Extra Demurrage Days',
                                      isAr ? '+$_savedDemDays يوم' : '+$_savedDemDays days',
                                      isAr ? 'فوق التعرفة القياسية (14 يوم)' : 'Above standard tariff (14 days)',
                                      AppTheme.flatCobalt,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildMetricItem(
                                      isAr ? 'أيام إضافية Detention' : 'Extra Detention Days',
                                      isAr ? '+$_savedDetDays يوم' : '+$_savedDetDays days',
                                      isAr ? 'فوق التعرفة القياسية (7 أيام)' : 'Above standard tariff (7 days)',
                                      AppTheme.flatOrange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildMetricItem(
                                      isAr ? 'مجموع الأيام المحمية' : 'Total Protected Days',
                                      isAr ? '${_demDays + _detDays} يوم' : '${_demDays + _detDays} days',
                                      isAr ? 'فترة آمنة قبل بدء الغرامات' : 'Safe period before penalties',
                                      AppTheme.flatEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isAr
                                    ? '⚡ ملاحظة تشغيلية: بمجرد اعتماد هذه الاتفاقية، يتم تلقائياً تحديث ملف الاستيراد وحجز الشحن وإعادة ضبط عدادات الرادار لكافة الحاويات المسجلة.'
                                    : '⚡ Operational note: Once this agreement is confirmed, the import file and booking are updated, and radar counters reset for all containers.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.flatCharcoal,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Footer Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => UnsavedChangesGuard.maybePop(context, isDirty: _isDirty),
                      child: Text(isAr ? 'إلغاء' : 'Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.flatEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isSubmitting
                            ? (isAr ? 'جاري التوثيق...' : 'Submitting...')
                            : (isAr ? 'توثيق واعتماد فترات السماح (BK-02)' : 'Confirm Free Days (BK-02)'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildMetricItem(String title, String value, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}
