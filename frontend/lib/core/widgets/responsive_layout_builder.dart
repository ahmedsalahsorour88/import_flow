import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Screen classification types based on enterprise breakpoints.
enum ResponsiveScreenType {
  desktop, // >= 1200px
  tablet,  // 768px - 1199px
  mobile,  // < 768px
}

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  ResponsiveScreenType screenType,
  BoxConstraints constraints,
);

/// A unified, responsive layout builder that adapts smoothly to Desktop,
/// Tablet, and Mobile viewports according to ImportFlow design system guidelines.
class ResponsiveLayoutBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder? builder;
  final WidgetBuilder? desktop;
  final WidgetBuilder? tablet;
  final WidgetBuilder? mobile;

  const ResponsiveLayoutBuilder({
    super.key,
    this.builder,
    this.desktop,
    this.tablet,
    this.mobile,
  }) : assert(
          builder != null || desktop != null,
          'Either builder or desktop must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = getScreenTypeFromWidth(constraints.maxWidth);

        if (builder != null) {
          return builder!(context, screenType, constraints);
        }

        switch (screenType) {
          case ResponsiveScreenType.desktop:
            return desktop!(context);
          case ResponsiveScreenType.tablet:
            return (tablet ?? desktop)!(context);
          case ResponsiveScreenType.mobile:
            return (mobile ?? tablet ?? desktop)!(context);
        }
      },
    );
  }

  /// Classify screen type from width constraint.
  static ResponsiveScreenType getScreenTypeFromWidth(double width) {
    if (AppTheme.isDesktopWidth(width)) {
      return ResponsiveScreenType.desktop;
    } else if (AppTheme.isTabletWidth(width)) {
      return ResponsiveScreenType.tablet;
    } else {
      return ResponsiveScreenType.mobile;
    }
  }

  /// Classify screen type from BuildContext MediaQuery.
  static ResponsiveScreenType getScreenType(BuildContext context) {
    return getScreenTypeFromWidth(MediaQuery.sizeOf(context).width);
  }

  /// Return a responsive value based on the current screen type.
  static T resolveValue<T>(
    BuildContext context, {
    required T desktop,
    T? tablet,
    T? mobile,
  }) {
    final type = getScreenType(context);
    switch (type) {
      case ResponsiveScreenType.desktop:
        return desktop;
      case ResponsiveScreenType.tablet:
        return tablet ?? desktop;
      case ResponsiveScreenType.mobile:
        return mobile ?? tablet ?? desktop;
    }
  }
}

/// Convenience extensions on BuildContext for quick responsive checks.
extension ResponsiveContextExtensions on BuildContext {
  bool get isDesktop => AppTheme.isDesktop(this);
  bool get isTablet => AppTheme.isTablet(this);
  bool get isMobile => AppTheme.isMobile(this);

  ResponsiveScreenType get responsiveScreenType =>
      ResponsiveLayoutBuilder.getScreenType(this);
}
