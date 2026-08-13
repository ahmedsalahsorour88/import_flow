import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../providers/navigation_provider.dart';

class BackToDashboardButton extends ConsumerWidget {
  final bool isCompact;

  const BackToDashboardButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompact) {
      return IconButton(
        tooltip: 'العودة إلى لوحة التحكم (Dashboard)',
        icon: const Icon(Icons.dashboard_customize_outlined, color: AppTheme.cobalt),
        onPressed: () => selectNavigationIndex(ref, 0),
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.cobalt.withOpacity(0.15),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: AppTheme.cobalt.withOpacity(0.4)),
        ),
      ),
      onPressed: () => selectNavigationIndex(ref, 0),
      icon: const Icon(Icons.dashboard_outlined, size: 16, color: AppTheme.cobalt),
      label: const Text(
        'العودة للداش بورد',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
