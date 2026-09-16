import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/density_provider.dart';

/// Reusable display density selector button for ERP tables.
/// Allows toggling between Comfortable (56px), Compact (48px), and Ultra-Compact (40px).
class DisplayDensitySelector extends ConsumerWidget {
  final bool compact;

  const DisplayDensitySelector({
    super.key,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDensity = ref.watch(displayDensityProvider);
    final isDark = AppTheme.isDark(context);

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final xOffset = isRtl ? 40.0 : -70.0;

    return PopupMenuButton<DisplayDensityMode>(
      tooltip: 'كثافة عرض الجدول (Display Density)',
      position: PopupMenuPosition.under,
      offset: Offset(xOffset, 6),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      elevation: 6,
      initialValue: currentDensity,
      onSelected: (mode) {
        ref.read(displayDensityProvider.notifier).setDensity(mode);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
        ),
      ),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          mode: DisplayDensityMode.comfortable,
          icon: Icons.table_rows_outlined,
          isSelected: currentDensity == DisplayDensityMode.comfortable,
          isDark: isDark,
        ),
        _buildMenuItem(
          context,
          mode: DisplayDensityMode.compact,
          icon: Icons.view_headline,
          isSelected: currentDensity == DisplayDensityMode.compact,
          isDark: isDark,
        ),
        _buildMenuItem(
          context,
          mode: DisplayDensityMode.ultraCompact,
          icon: Icons.density_small,
          isSelected: currentDensity == DisplayDensityMode.ultraCompact,
          isDark: isDark,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForMode(currentDensity),
              size: 16,
              color: AppTheme.cobalt,
            ),
            const SizedBox(width: 6),
            Text(
              currentDensity.nameAr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMode(DisplayDensityMode mode) {
    switch (mode) {
      case DisplayDensityMode.comfortable:
        return Icons.table_rows_outlined;
      case DisplayDensityMode.compact:
        return Icons.view_headline;
      case DisplayDensityMode.ultraCompact:
        return Icons.density_small;
    }
  }

  PopupMenuItem<DisplayDensityMode> _buildMenuItem(
    BuildContext context, {
    required DisplayDensityMode mode,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return PopupMenuItem<DisplayDensityMode>(
      value: mode,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.cobalt : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mode.nameAr,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.cobalt
                    : (isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B)),
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check,
              size: 16,
              color: AppTheme.cobalt,
            ),
        ],
      ),
    );
  }
}
