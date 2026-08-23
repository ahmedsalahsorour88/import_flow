import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'buttons/icon_action_button.dart';

/// Standard 4-Action Row Pill Widget for ImportFlow ERP data tables.
///
/// Uses [IconActionButton] factory subclasses for consistent styling.
/// Labels pulled from [AppLocalizations] (context.l10n).
///
/// Actions:
///   1. 👁️ View Details
///   2. ✏️ Edit
///   3. 🖨️ Print / Export
///   4. 🗑️ Delete
class RowActionsPill extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPrint;
  final VoidCallback? onDelete;

  /// Override tooltips for domain-specific labels (optional).
  final String? viewTooltip;
  final String? editTooltip;
  final String? printTooltip;
  final String? deleteTooltip;

  final double iconSize;

  const RowActionsPill({
    super.key,
    this.onView,
    this.onEdit,
    this.onPrint,
    this.onDelete,
    this.viewTooltip,
    this.editTooltip,
    this.printTooltip,
    this.deleteTooltip,
    this.iconSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: AppTheme.pillDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. View
          ViewActionButton(
            tooltip: viewTooltip ?? l.viewDetailsTooltip,
            onTap: onView,
            iconSize: iconSize,
          ),
          const SizedBox(width: 4),

          // 2. Edit
          EditActionButton(
            tooltip: editTooltip ?? l.editTooltip,
            onTap: onEdit,
            iconSize: iconSize,
          ),
          const SizedBox(width: 4),

          // 3. Print / Export
          PrintActionButton(
            tooltip: printTooltip ?? l.printTooltip,
            onTap: onPrint ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.preparingExport),
                      backgroundColor: AppTheme.charcoal,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
            iconSize: iconSize,
          ),
          const SizedBox(width: 4),

          // 4. Delete
          DeleteActionButton(
            tooltip: deleteTooltip ?? l.deleteTooltip,
            onTap: onDelete,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }
}
