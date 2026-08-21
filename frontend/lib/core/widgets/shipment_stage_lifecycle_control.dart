import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/import_files/models/import_file_model.dart';
import '../../features/import_files/providers/import_files_provider.dart';
import 'hold_shipment_at_stage_dialog.dart';
import 'resume_shipment_from_stage_dialog.dart';
import 'searchable_dropdown_field.dart';

class ShipmentStageLifecycleControl extends ConsumerWidget {
  final int? importFileId;
  final String stageName;
  final String stageCode;
  final VoidCallback? onStatusChanged;
  final bool isHeaderStyle;

  const ShipmentStageLifecycleControl({
    super.key,
    this.importFileId,
    required this.stageName,
    this.stageCode = '',
    this.onStatusChanged,
    this.isHeaderStyle = true,
  });

  void _showSelectAndHoldDialog(BuildContext context, WidgetRef ref, List<ImportFileModel> files) {
    int? selectedId;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.pause_circle_outline, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Text(
                  'اختيار ملف الشحنة للإيقاف عند هذه المرحلة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المرحلة الحالية: $stageName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt),
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<int>(
                  labelText: 'اختر ملف الشحنة المراد إيقافها *',
                  hintText: 'ابحث برقم الملف أو الكود أو اسم الشركة...',
                  items: files.where((f) => f.status != 'Closed').map((f) {
                    final title = f.customFileNumber != null && f.customFileNumber!.isNotEmpty
                        ? '${f.customFileNumber} - ${f.companyName}'
                        : '${f.importFileCode} - ${f.companyName}';
                    return SearchableDropdownItem<int>(
                      value: f.importFileId,
                      label: title,
                    );
                  }).toList(),
                  value: selectedId,
                  onChanged: (val) => setDialogState(() => selectedId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () {
                      Navigator.of(dialogCtx).pop();
                      final file = files.firstWhere((f) => f.importFileId == selectedId);
                      HoldShipmentAtStageDialog.show(
                        context,
                        importFile: file,
                        stageName: stageName,
                        stageCode: stageCode,
                        onSuccess: onStatusChanged,
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900, foregroundColor: Colors.white),
              child: const Text('متابعة وإدخال سبب الإيقاف'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(importFilesProvider).valueOrNull ?? [];

    ImportFileModel? currentFile;
    if (importFileId != null) {
      try {
        currentFile = files.firstWhere((f) => f.importFileId == importFileId);
      } catch (_) {
        currentFile = null;
      }
    }

    if (currentFile == null) {
      return ElevatedButton.icon(
        onPressed: () => _showSelectAndHoldDialog(context, ref, files),
        icon: const Icon(Icons.pause_circle_outline, size: 15),
        label: const Text(
          'إيقاف شحنة عند هذه المرحلة',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade900.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }

    final isHeld = currentFile.status == 'On Hold';
    final isClosed = currentFile.status == 'Closed';

    if (isHeld) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // On Hold Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade400, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_filled, color: Colors.amberAccent, size: 14),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    'متوقفة: ${currentFile.pausedAtStage ?? stageName}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Resume Button
          ElevatedButton.icon(
            onPressed: () async {
              final res = await ResumeShipmentFromStageDialog.show(
                context,
                importFile: currentFile!,
                currentStageName: stageName,
                onSuccess: onStatusChanged,
              );
              if (res == true) {
                onStatusChanged?.call();
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text(
              'استكمال الشحنة',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              visualDensity: VisualDensity.compact,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      );
    }

    if (isClosed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade600),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: Colors.white70, size: 13),
            SizedBox(width: 4),
            Text(
              'الشحنة مغلقة بالأرشيف',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Active / In Progress Shipment: Render the Hold & Stop Button
    return ElevatedButton.icon(
      onPressed: () async {
        final res = await HoldShipmentAtStageDialog.show(
          context,
          importFile: currentFile!,
          stageName: stageName,
          stageCode: stageCode,
          onSuccess: onStatusChanged,
        );
        if (res == true) {
          onStatusChanged?.call();
        }
      },
      icon: const Icon(Icons.pause_circle_outline, size: 15),
      label: const Text(
        'إيقاف الشحنة عند هذه المرحلة',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade900,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class ShipmentHoldWarningBanner extends ConsumerWidget {
  final int? importFileId;
  final String currentStageName;
  final VoidCallback? onResumeSuccess;

  const ShipmentHoldWarningBanner({
    super.key,
    required this.importFileId,
    required this.currentStageName,
    this.onResumeSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (importFileId == null) return const SizedBox.shrink();

    final files = ref.watch(importFilesProvider).valueOrNull ?? [];
    ImportFileModel? file;
    try {
      file = files.firstWhere((f) => f.importFileId == importFileId);
    } catch (_) {
      file = null;
    }

    if (file == null || file.status != 'On Hold') {
      return const SizedBox.shrink();
    }

    final pausedStage = file.pausedAtStage ?? currentStageName;
    final holdReason = file.holdReason ?? 'غير محدد';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚠️ تنبيه: هذه الشحنة (${file.importFileCode}) متوقفة ومعلقة عند مرحلة: [$pausedStage]',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'سبب الإيقاف المسجل: $holdReason',
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final res = await ResumeShipmentFromStageDialog.show(
                context,
                importFile: file!,
                currentStageName: currentStageName,
                onSuccess: onResumeSuccess,
              );
              if (res == true) {
                onResumeSuccess?.call();
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
            label: const Text(
              'استكمال واستئناف الشحنة الآن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
