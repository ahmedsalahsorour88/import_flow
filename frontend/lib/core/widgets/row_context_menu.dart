import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class RowContextMenuHelper {
  static void showContextMenu({
    required BuildContext context,
    required Offset globalPosition,
    required String codeToCopy,
    required VoidCallback onEdit,
    required VoidCallback onHistory,
    required bool isActive,
    required VoidCallback onToggleActive,
  }) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: AppTheme.cobalt),
              SizedBox(width: 10),
              Text('Edit Record', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, size: 18, color: AppTheme.charcoal),
              SizedBox(width: 10),
              Text('View Activity Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18, color: AppTheme.charcoal),
              SizedBox(width: 10),
              Text('Copy Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                isActive ? Icons.block : Icons.restore,
                size: 18,
                color: isActive ? AppTheme.crimson : AppTheme.emerald,
              ),
              const SizedBox(width: 10),
              Text(
                isActive ? 'Deactivate Record' : 'Restore Record',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.crimson : AppTheme.emerald,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'edit':
          onEdit();
          break;
        case 'history':
          onHistory();
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: codeToCopy));
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Copied "$codeToCopy" to clipboard'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        case 'toggle':
          onToggleActive();
          break;
      }
    });
  }
}
