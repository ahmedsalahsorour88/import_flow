import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/import_files/models/import_file_model.dart';
import '../../features/import_files/providers/import_files_provider.dart';

class ResumeShipmentFromStageDialog extends ConsumerStatefulWidget {
  final ImportFileModel importFile;
  final String currentStageName;
  final VoidCallback? onSuccess;

  const ResumeShipmentFromStageDialog({
    super.key,
    required this.importFile,
    required this.currentStageName,
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ImportFileModel importFile,
    required String currentStageName,
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResumeShipmentFromStageDialog(
        importFile: importFile,
        currentStageName: currentStageName,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<ResumeShipmentFromStageDialog> createState() => _ResumeShipmentFromStageDialogState();
}

class _ResumeShipmentFromStageDialogState extends ConsumerState<ResumeShipmentFromStageDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleResume() async {
    setState(() => _isSubmitting = true);
    final notes = _notesController.text.trim();

    try {
      final updated = await ref.read(importFilesProvider.notifier).resumeShipment(
            widget.importFile.importFileId,
            resumeNotes: notes.isNotEmpty ? notes : null,
          );

      if (mounted && updated != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '▶️ تم استئناف واستكمال الشحنة (${widget.importFile.importFileCode}) بنجاح!',
            ),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ تعذر استئناف الشحنة: $e'),
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
    final pausedStage = file.pausedAtStage ?? widget.currentStageName;
    final holdReason = file.holdReason ?? 'غير محدد';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.emerald.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          border: Border(bottom: BorderSide(color: AppTheme.emerald.withOpacity(0.4))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.emerald,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'استئناف واستكمال الشحنة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emerald,
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
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Paused Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pause_circle_outline, color: Colors.amber.shade900, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'بيانات توقف الشحنة السابق:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• مرحلة التوقف: $pausedStage',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• سبب التوقف المسجل: $holdReason',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resume Info & Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.emerald, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'عند تأكيد الاستئناف، ستعود حالة الشحنة إلى "In Progress" النشطة وسيتمكن الفريق من استكمال ومتابعة باقي الإجراءات والمراحل.',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.charcoal, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Resume Notes Optional Field
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات الاستئناف ومبررات المتابعة (اختياري)',
                  hintText: 'مثال: تم استيفاء التعديل المطلوب من المورد وجاهزية المتابعة...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment, color: AppTheme.emerald),
                ),
              ),
            ],
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
          onPressed: _isSubmitting ? null : _handleResume,
          icon: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('تأكيد استكمال واستئناف الشحنة'),
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
