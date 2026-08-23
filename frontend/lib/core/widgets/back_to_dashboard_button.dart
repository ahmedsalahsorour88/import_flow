import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import '../providers/navigation_provider.dart';

/// Back to Dashboard button — compact icon or full labeled button.
/// Label pulled from [AppLocalizations].
class BackToDashboardButton extends ConsumerWidget {
  final bool isCompact;

  const BackToDashboardButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    if (isCompact) {
      return IconButton(
        tooltip: l.backToDashboardTooltip,
        icon: const Icon(Icons.dashboard_customize_outlined, color: AppTheme.cobalt),
        onPressed: () => selectNavigationIndex(ref, 0),
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.cobaltMedium,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppTheme.cobaltBorder),
        ),
      ),
      onPressed: () => selectNavigationIndex(ref, 0),
      icon: const Icon(Icons.dashboard_outlined, size: 16, color: AppTheme.cobalt),
      label: Text(
        l.backToDashboard,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
