import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard 4-Action Row Pill Widget for ImportFlow ERP tables.
/// Provides:
/// 1. 👁️ View / Details (عرض)
/// 2. ✏️ Edit (تعديل)
/// 3. 🖨️ Print / Single PDF Export (طباعة)
/// 4. 🗑️ Delete / Soft-Delete (حذف)
class RowActionsPill extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPrint;
  final VoidCallback? onDelete;
  final String viewTooltip;
  final String editTooltip;
  final String printTooltip;
  final String deleteTooltip;
  final double iconSize;

  const RowActionsPill({
    super.key,
    this.onView,
    this.onEdit,
    this.onPrint,
    this.onDelete,
    this.viewTooltip = 'عرض التفاصيل (View Details)',
    this.editTooltip = 'تعديل السجل (Edit)',
    this.printTooltip = 'طباعة وتصدير (Print / Export)',
    this.deleteTooltip = 'حذف / إيقاف التفعيل (Delete)',
    this.iconSize = 16.0,
  });

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: onTap != null ? bgColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: onTap != null ? color : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. View / Details (👁️)
          _actionBtn(
            icon: Icons.visibility,
            color: AppTheme.cobalt,
            bgColor: AppTheme.cobalt.withOpacity(0.08),
            tooltip: viewTooltip,
            onTap: onView,
          ),
          const SizedBox(width: 4),

          // 2. Edit (✏️)
          _actionBtn(
            icon: Icons.edit,
            color: AppTheme.orange,
            bgColor: AppTheme.orange.withOpacity(0.1),
            tooltip: editTooltip,
            onTap: onEdit,
          ),
          const SizedBox(width: 4),

          // 3. Print / Export (🖨️)
          _actionBtn(
            icon: Icons.print,
            color: AppTheme.charcoal,
            bgColor: Colors.grey.shade100,
            tooltip: printTooltip,
            onTap: onPrint ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preparing document print/export...'),
                      backgroundColor: AppTheme.charcoal,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          ),
          const SizedBox(width: 4),

          // 4. Delete (🗑️)
          _actionBtn(
            icon: Icons.delete_outline,
            color: AppTheme.crimson,
            bgColor: AppTheme.crimson.withOpacity(0.08),
            tooltip: deleteTooltip,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
