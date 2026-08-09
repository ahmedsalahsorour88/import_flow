import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/import_files_provider.dart';

class CloseShipmentDialog extends ConsumerStatefulWidget {
  final int importFileId;
  final String importFileCode;
  final String currentPhaseName;

  const CloseShipmentDialog({
    super.key,
    required this.importFileId,
    required this.importFileCode,
    required this.currentPhaseName,
  });

  @override
  ConsumerState<CloseShipmentDialog> createState() => _CloseShipmentDialogState();
}

class _CloseShipmentDialogState extends ConsumerState<CloseShipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppTheme.crimson, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'إيقاف وإغلاق الشحنة (${widget.importFileCode})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحلة الإيقاف الحالية: ${widget.currentPhaseName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ملاحظة: عند إيقاف وإغلاق الشحنة، سيتم تغيير حالتها إلى (Closed) وترحيلها تلقائياً إلى "Phase 10 - Import File Closure & Archive" وتسجيل سبب الإيقاف بشكل دائم في الأرشيف.',
                      style: TextStyle(fontSize: 11, color: AppTheme.charcoal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'سبب إيقاف وإغلاق الشحنة والملاحظات التفصيلية *',
                  hintText: 'مثال: إلغاء أوردر الشراء من قبل المورد / تعذر السداد البنكي / إلغاء ACID...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'يرجى كتابة سبب إيقاف وإغلاق الشحنة';
                  }
                  if (v.trim().length < 3) {
                    return 'يرجى كتابة سبب واضح (أكثر من 3 أحرف)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 18),
          label: const Text(
            'تأكيد الإيقاف والترحيل للأرشيف (Phase 10)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref.read(importFilesProvider.notifier).closeShipment(
                            widget.importFileId,
                            _reasonController.text.trim(),
                            widget.currentPhaseName,
                          );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('تم إيقاف الشحنة بنجاح وترحيلها إلى Phase 10 شحنة مغلقة.'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                      nav.pop(true);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('خطأ أثناء إغلاق الشحنة: $e'), backgroundColor: AppTheme.crimson),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
        ),
      ],
    );
  }
}
