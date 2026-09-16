import 'package:flutter/material.dart';

/// A set of icons that are known to indicate forward/backward direction
/// and should be mirrored when rendering in a Right-to-Left (RTL) locale.
final Set<IconData> _directionalIcons = {
  Icons.arrow_forward,
  Icons.arrow_back,
  Icons.arrow_forward_ios,
  Icons.arrow_back_ios,
  Icons.arrow_forward_rounded,
  Icons.arrow_back_rounded,
  Icons.chevron_right,
  Icons.chevron_left,
  Icons.navigate_next,
  Icons.navigate_before,
  Icons.arrow_right_alt,
  Icons.keyboard_arrow_right,
  Icons.keyboard_arrow_left,
  Icons.double_arrow,
  Icons.forward,
  Icons.last_page,
  Icons.first_page,
};

/// A shared icon widget that automatically mirrors direction-sensitive icons
/// (such as forward/back arrows and navigation chevrons) when active in RTL mode.
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool? forceMirror;

  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.forceMirror,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final shouldMirror = forceMirror ?? (isRtl && _directionalIcons.contains(icon));

    final iconWidget = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );

    if (shouldMirror) {
      return Transform.scale(
        scaleX: -1.0,
        alignment: Alignment.center,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}

/// A localized workflow arrow widget or symbol that points in the forward
/// reading direction (right '→' in LTR / English, left '←' in RTL / Arabic).
class DirectionalArrow extends StatelessWidget {
  final TextStyle? style;
  final Color? color;
  final double? size;

  const DirectionalArrow({
    super.key,
    this.style,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final arrowChar = isRtl ? '←' : '→';

    return Text(
      arrowChar,
      style: (style ?? const TextStyle()).copyWith(
        color: color,
        fontSize: size,
      ),
    );
  }

  /// Return arrow string symbol directly based on active RTL state.
  static String symbol(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl ? '←' : '→';
  }

  /// Return arrow string symbol directly based on isArabic boolean flag.
  static String symbolForArabic(bool isArabic) {
    return isArabic ? '←' : '→';
  }
}
