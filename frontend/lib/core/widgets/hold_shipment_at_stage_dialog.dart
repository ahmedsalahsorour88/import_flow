import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/import_files/models/import_file_model.dart';
import '../../features/import_files/providers/import_files_provider.dart';

class HoldShipmentAtStageDialog extends ConsumerStatefulWidget {
  final ImportFileModel importFile;
  final String stageName;
  final String stageCode;
  final VoidCallback? onSuccess;

  const HoldShipmentAtStageDialog({
    super.key,
    required this.importFile,
    required this.stageName,
    this.stageCode = '',
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ImportFileModel importFile,
    required String stageName,
    String stageCode = '',
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HoldShipmentAtStageDialog(
        importFile: importFile,
        stageName: stageName,
        stageCode: stageCode,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<HoldShipmentAtStageDialog> createState() => _HoldShipmentAtStageDialogState();
}

class _HoldShipmentAtStageDialogState extends ConsumerState<HoldShipmentAtStageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _commonReasons = [
    'في انتظار رد وموافقة المورد الخارجي',
    'طلب تعديل على مسودة بوليصة الشحن',
    'في انتظار موافقة البنك وإصدار نموذج 4',
    'استيفاء موافقة جهة العرض والرقابة',
    'تأخير الحجز وتأكيد الخط الملاحي',
    'مراجعة وتدقيق أسعار بنود التعريفة الجمركية',
    'طلب فحص ومعاينة إضافية للبضاعة',
    'تعليق إداري مؤقت للشحنة',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleHold() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final reason = _reasonController.text.trim();
    final notes = _notesController.text.trim();

    try {
      final updated = await ref.read(importFilesProvider.notifier).holdShipment(
            widget.importFile.importFileId,
            reason,
            holdNotes: notes.isNotEmpty ? notes : null,
            stageName: widget.stageName,
            stepName: widget.stageCode.isNotEmpty ? widget.stageCode : null,
          );

      if (mounted && updated != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ تم إيقاف وتجميد الشحنة (${widget.importFile.importFileCode}) بنجاح عند مرحلة: ${widget.stageName}',
            ),
            backgroundColor: Colors.amber.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ تعذر إيقاف الشحنة: $e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.importFile;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إيقاف وتجميد الشحنة عند هذه المرحلة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  Text(
                    '${file.importFileCode} | ${file.companyName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Stage Target Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المرحلة الحالية للإيقاف: ${widget.stageName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'سيتم تعليق الشحنة مؤقتاً عند هذه المرحلة، مع إمكانية استئنافها فوراً في أي وقت بنقرة واحدة.',
                              style: TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Common Reasons Chips
                const Text(
                  'أسباب الإيقاف الشائعة (انقر للاختيار السريع):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonReasons.map((r) {
                    final isSelected = _reasonController.text == r;
                    return ChoiceChip(
                      label: Text(r, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.charcoal)),
                      selected: isSelected,
                      selectedColor: Colors.amber.shade800,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (selected) {
                        setState(() {
                          _reasonController.text = selected ? r : '';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Reason Required Field
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'سبب إيقاف وتعليق الشحنة *',
                    hintText: 'اكتب سبب الإيقاف أو اختر من الأسباب بالأعلى...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note, color: Colors.orange),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال سبب الإيقاف قبل الاستمرار.';
                    }
                    if (v.trim().length < 3) {
                      return 'يجب ألا يقل سبب الإيقاف عن 3 أحرف.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes Optional Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات وتوجيهات إضافية (اختياري)',
                    hintText: 'أي توجيهات لفريق العمل أو المخلص أثناء فترة التوقف...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء التراجع'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleHold,
          icon: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.pause_circle_filled, size: 18),
          label: const Text('تأكيد إيقاف وتجميد الشحنة عند هذه المرحلة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
