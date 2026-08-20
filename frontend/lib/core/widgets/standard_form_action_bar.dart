import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Standard Form Action Bar across all screens, studies, and data evaluation workflows in ImportFlow ERP.
/// Provides standard buttons:
/// 1. 💾 حفظ مؤقت ومتابعة لاحقة (Save Draft & Continue Later)
/// 2. 🔄 تفريغ وبدء تسجيل جديد (Clear Form & Start New)
/// 3. 🔄 إعادة تحميل حية (Live Page Refresh)
/// 4. ✅ حفظ وتأكيد السجل (Submit / Save Final)
class StandardFormActionBar extends StatelessWidget {
  final VoidCallback? onSaveDraft;
  final VoidCallback? onResetForm;
  final VoidCallback? onRefresh;
  final VoidCallback? onSubmit;
  final VoidCallback? onClose;
  final String submitLabel;
  final String saveDraftLabel;
  final String resetFormLabel;
  final String refreshLabel;
  final String closeLabel;
  final bool isSaving;
  final bool isSubmitting;
  final bool isEditing;
  final bool showCloseButton;
  final Widget? leadingWidget;
  final List<Widget>? extraActions;

  const StandardFormActionBar({
    super.key,
    this.onSaveDraft,
    this.onResetForm,
    this.onRefresh,
    this.onSubmit,
    this.onClose,
    this.submitLabel = 'حفظ وتأكيد السجل',
    this.saveDraftLabel = 'حفظ مؤقت ومتابعة لاحقة 💾',
    this.resetFormLabel = 'تفريغ وبدء تسجيل جديد 🔄',
    this.refreshLabel = 'إعادة تحميل حية 🔄',
    this.closeLabel = 'إغلاق وتراجع ✕',
    this.isSaving = false,
    this.isSubmitting = false,
    this.isEditing = false,
    this.showCloseButton = true,
    this.leadingWidget,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left / Leading section: Extra buttons / Auto-complete / Live Refresh
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget!,
                const SizedBox(width: 8),
              ],
              if (extraActions != null) ...[
                ...extraActions!,
                const SizedBox(width: 8),
              ],
              if (onRefresh != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.charcoal,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
                  label: Text(refreshLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),

          // Right / Action section: Save Draft, Clear/Reset, Submit/Save
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 0. Close / Cancel Button
              if (showCloseButton || onClose != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.crimson,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: onClose ?? () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.crimson),
                  label: Text(closeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],

              // 1. Reset / Clear Form
              if (onResetForm != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: onResetForm,
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.blueGrey),
                  label: Text(resetFormLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],

              // 2. Progressive Save / Save Draft
              if (onSaveDraft != null) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: AppTheme.cobalt,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.cobalt),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: isSaving ? null : onSaveDraft,
                  icon: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cobalt))
                      : const Icon(Icons.save_outlined, size: 18, color: AppTheme.cobalt),
                  label: Text(saveDraftLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
              ],

              // 3. Final Save / Submit
              if (onSubmit != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    elevation: 2,
                  ),
                  onPressed: (isSaving || isSubmitting) ? null : onSubmit,
                  icon: (isSaving || isSubmitting)
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    isEditing ? 'تحديث وحفظ السجل 💾' : submitLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
