import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Button variant options for ImportFlow ERP.
enum AppButtonVariant {
  /// Primary action (cobalt blue) — Save, Confirm, Submit
  primary,
  /// Success action (emerald green) — Save & Confirm, Final Save
  success,
  /// Danger action (crimson red) — Delete, Cancel with warning
  danger,
  /// Warning action (orange) — Import, Caution operations
  warning,
  /// Secondary / neutral (outlined) — Cancel, Close, Reset
  secondary,
  /// Ghost / transparent (outlined subtle) — Live Refresh, Back
  ghost,
  /// Save Draft (light cobalt fill with border) — Progressive save
  saveDraft,
}

/// Button size options.
enum AppButtonSize {
  small,   // 32px height
  medium,  // 40px height (default)
  large,   // 48px height
}

/// 🎯 Unified Professional Button for ImportFlow ERP.
///
/// Replaces all `ElevatedButton.styleFrom(...)` and `OutlinedButton.styleFrom(...)`
/// scattered across the codebase. Single source of truth for button appearance.
///
/// Features:
/// - 6 variants covering all use cases
/// - Built-in loading spinner (isLoading)
/// - Disabled state (onPressed == null or isLoading)
/// - Optional leading/trailing icon
/// - 3 sizes (small, medium, large)
/// - Tooltip support
///
/// Usage:
/// ```dart
/// AppButton(
///   label: context.l10n.save,
///   variant: AppButtonVariant.success,
///   icon: Icons.check_circle_outline,
///   isLoading: isSaving,
///   onPressed: _onSave,
/// )
/// ```
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool trailingIcon;
  final String? tooltip;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.trailingIcon = false,
    this.tooltip,
  });

  // ── Size helpers ──────────────────────────────────────────────────────────

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 22, vertical: 14);
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 11;
      case AppButtonSize.medium:
        return 12.5;
      case AppButtonSize.large:
        return 14;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }

  double get _spinnerSize {
    switch (size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  // ── Color / style resolver ────────────────────────────────────────────────

  _ButtonStyle get _resolved {
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonStyle(
          bg: AppTheme.cobalt,
          fg: Colors.white,
          border: null,
          spinnerColor: Colors.white,
        );
      case AppButtonVariant.success:
        return const _ButtonStyle(
          bg: AppTheme.emerald,
          fg: Colors.white,
          border: null,
          spinnerColor: Colors.white,
        );
      case AppButtonVariant.danger:
        return const _ButtonStyle(
          bg: AppTheme.crimson,
          fg: Colors.white,
          border: null,
          spinnerColor: Colors.white,
        );
      case AppButtonVariant.warning:
        return const _ButtonStyle(
          bg: AppTheme.orange,
          fg: Colors.white,
          border: null,
          spinnerColor: Colors.white,
        );
      case AppButtonVariant.secondary:
        return const _ButtonStyle(
          bg: Colors.white,
          fg: AppTheme.charcoal,
          border: BorderSide(color: Color(0xFFBDBDBD)),
          spinnerColor: AppTheme.charcoal,
        );
      case AppButtonVariant.ghost:
        return const _ButtonStyle(
          bg: Colors.transparent,
          fg: AppTheme.charcoal,
          border: BorderSide(color: Color(0xFFBDBDBD)),
          spinnerColor: AppTheme.cobalt,
        );
      case AppButtonVariant.saveDraft:
        return const _ButtonStyle(
          bg: Color(0xFFEFF6FF),
          fg: AppTheme.cobalt,
          border: BorderSide(color: AppTheme.cobalt),
          spinnerColor: AppTheme.cobalt,
        );
    }
  }


  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = _resolved;
    final bool disabled = isLoading || onPressed == null;

    final Widget spinner = SizedBox(
      width: _spinnerSize,
      height: _spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: s.spinnerColor,
      ),
    );

    final Widget iconWidget = Icon(icon, size: _iconSize, color: s.fg);

    Widget content;
    if (icon != null) {
      final leading = isLoading ? spinner : (trailingIcon ? null : iconWidget);
      final trailing = trailingIcon ? (isLoading ? spinner : iconWidget) : null;

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _fontSize,
              color: disabled ? s.fg.withOpacity(0.5) : s.fg,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[spinner, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _fontSize,
              color: disabled ? s.fg.withOpacity(0.5) : s.fg,
            ),
          ),
        ],
      );
    }

    final ButtonStyle buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return s.bg == Colors.transparent
              ? Colors.transparent
              : s.bg.withOpacity(0.5);
        }
        return s.bg;
      }),
      foregroundColor: WidgetStateProperty.all(s.fg),
      padding: WidgetStateProperty.all(_padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      side: s.border != null
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(color: s.border!.color.withOpacity(0.4));
              }
              return s.border;
            })
          : null,
      elevation: WidgetStateProperty.resolveWith((states) {
        if (s.bg == Colors.transparent || s.border != null) return 0;
        if (states.contains(WidgetState.hovered)) return 3;
        return 2;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withOpacity(0.08);
        }
        return null;
      }),
    );

    Widget btn = ElevatedButton(
      style: buttonStyle,
      onPressed: disabled ? null : onPressed,
      child: content,
    );

    if (tooltip != null) {
      btn = Tooltip(message: tooltip!, child: btn);
    }

    return btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal style data class
// ─────────────────────────────────────────────────────────────────────────────

class _ButtonStyle {
  final Color bg;
  final Color fg;
  final BorderSide? border;
  final Color spinnerColor;

  const _ButtonStyle({
    required this.bg,
    required this.fg,
    required this.border,
    required this.spinnerColor,
  });
}
