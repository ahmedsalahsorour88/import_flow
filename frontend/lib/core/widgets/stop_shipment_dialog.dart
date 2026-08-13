import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/import_files/models/import_file_model.dart';
import '../../features/import_files/providers/import_files_provider.dart';

class StopShipmentDialog extends ConsumerStatefulWidget {
  final ImportFileModel importFile;
  final String currentPhaseName;
  final VoidCallback? onSuccess;

  const StopShipmentDialog({
    super.key,
    required this.importFile,
    required this.currentPhaseName,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required ImportFileModel importFile,
    required String currentPhaseName,
    VoidCallback? onSuccess,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StopShipmentDialog(
        importFile: importFile,
        currentPhaseName: currentPhaseName,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<StopShipmentDialog> createState() => _StopShipmentDialogState();
}

class _StopShipmentDialogState extends ConsumerState<StopShipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleStopShipment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(importFilesProvider.notifier).closeShipment(
            widget.importFile.importFileId,
            _reasonController.text.trim(),
            widget.currentPhaseName,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⛔ تم إيقاف وإغلاق الشحنة (${widget.importFile.importFileCode}) وترحيلها بنجاح للارشيف (Phase 10)!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ أثناء إيقاف الشحنة: $e'),
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.crimson.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppTheme.crimson, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'إيقاف وإغلاق الشحنة (${widget.importFile.importFileCode})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.crimson,
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحلة الإيقاف الحالية: ${widget.currentPhaseName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.crimson,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '- ملاحظة: عند إيقاف وإغلاق الشحنة، سيتم تغيير حالتها تلقائياً إلى "Closed" وترحيلها إلى "Phase 10 - Import File Closure & Archive" وتسجيل سبب الإيقاف بشكل دائم في الأرشيف.',
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
                  labelText: '* سبب إيقاف وإغلاق الشحنة والملاحظات التفصيلية',
                  hintText: 'اكتب هنا تفاصيل سبب الإيقاف المبكر للشحنة والتعليمات الإدارية...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال سبب الإيقاف قبل الاستمرار.';
                  }
                  if (val.trim().length < 3) {
                    return 'يجب ألا يقل سبب الإيقاف عن 3 حروف.';
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
          onPressed: _isSubmitting ? null : _handleStopShipment,
          icon: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('(Phase 10) تأكيد الإيقاف والترحيل للأرشيف'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.crimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
