import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/import_files/models/import_file_model.dart';
import '../../features/import_files/providers/import_files_provider.dart';

class ReopenShipmentDialog extends ConsumerStatefulWidget {
  final ImportFileModel importFile;
  final VoidCallback? onSuccess;

  const ReopenShipmentDialog({
    super.key,
    required this.importFile,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required ImportFileModel importFile,
    VoidCallback? onSuccess,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReopenShipmentDialog(
        importFile: importFile,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<ReopenShipmentDialog> createState() => _ReopenShipmentDialogState();
}

class _ReopenShipmentDialogState extends ConsumerState<ReopenShipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleReopenShipment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final reopened = await ref.read(importFilesProvider.notifier).reopenShipment(
            widget.importFile.importFileId,
            _reasonController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        final phaseName = reopened?.currentModule ?? widget.importFile.closedAtPhase ?? 'Phase 1';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إعادة فتح وتنشيط الشحنة (${widget.importFile.importFileCode}) وإعادتها بنجاح لمرحلة ($phaseName)!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ أثناء إعادة فتح الشحنة: $e'),
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
    final restoredPhase = widget.importFile.closedAtPhase ?? 'Phase 1 - Import Planning & Feasibility';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.emerald.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.restart_alt, color: AppTheme.emerald, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'إعادة فتح وتنشيط الشحنة (${widget.importFile.importFileCode})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.emerald,
                ),
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 550,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المرحلة التي ستعود إليها الشحنة: $restoredPhase',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emerald,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '- ملاحظة: سيتم إلغاء حالة الإغلاق وتغيير حالة الشحنة إلى نشطة "Active" وإعادتها بنفس البيانات والتفاصيل إلى المرحلة التشغيلية التي تم إيقافها عندها.',
                      style: TextStyle(fontSize: 11, color: AppTheme.charcoal, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason Text Field
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '* سبب إعادة فتح وتنشيط الشحنة والملاحظات التفصيلية',
                  hintText: 'اكتب هنا سبب استئناف وإعادة فتح الشحنة المغلقة مسبقاً...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال سبب إعادة فتح الشحنة.';
                  }
                  if (val.trim().length < 3) {
                    return 'يجب ألا يقل سبب إعادة الفتح عن 3 حروف.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleReopenShipment,
          icon: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow, size: 18),
          label: const Text('تأكيد إعادة الفتح والتنشيط'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
