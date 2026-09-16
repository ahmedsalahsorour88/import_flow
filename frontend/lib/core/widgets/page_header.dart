import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/density_provider.dart';

/// Standard, reusable Page Header for ImportFlow ERP screens (Type B List/Index & Master screens).
///
/// Features:
/// - Replaces ad-hoc local AppBars and custom gradient containers.
/// - Uses uniform solid dark charcoal [AppTheme.charcoal] (or dark mode [Color(0xFF141A22)]).
/// - Automatically scales font sizes, paddings, and heights with [displayDensityProvider].
/// - Implements [PreferredSizeWidget] so it can be passed directly to `Scaffold.appBar`
///   or placed as the first widget in a `Column`.
class PageHeader extends ConsumerWidget implements PreferredSizeWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final double elevation;

  const PageHeader({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.elevation = 0.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null && subtitle!.isNotEmpty ? 58.0 : 54.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(displayDensityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? const Color(0xFF141A22) : AppTheme.charcoal);
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.black12,
            width: 1.0,
          ),
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: density.headerPadding.left,
        vertical: hasSubtitle ? 2.5 : 6.0,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? AppTheme.cobalt,
                      size: density.headerIconSize,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: density.headerTitleFontSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: density.headerSubtitleFontSize,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
