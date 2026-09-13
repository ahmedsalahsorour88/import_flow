import 'package:flutter/material.dart';

class AppTheme {
  // ── Responsive Breakpoints (Logical Pixels) ──────────────────────────────
  static const double breakpointSm = 600.0;   // Mobile / compact
  static const double breakpointMd = 900.0;   // Tablet / compact desktop
  static const double breakpointLg = 1200.0;  // Standard desktop
  static const double breakpointXl = 1600.0;  // Wide / ultrawide desktop

  /// Width threshold below which horizontal tabs convert to vertical sidebar.
  static const double tabBarSidebarThreshold = 800.0;

  /// Width threshold below which vertical sidebar converts to mobile dropdown/drawer.
  static const double tabBarDropdownThreshold = 550.0;

  /// Tab count at or above which vertical sidebar is preferred automatically.
  static const int tabCountSidebarThreshold = 4;

  // ── Flat Color Palette ────────────────────────────────────────────────────
  static const Color charcoal = Color(0xFF2C3E50);
  static const Color cobalt = Color(0xFF3498DB);
  static const Color emerald = Color(0xFF27AE60);
  static const Color orange = Color(0xFFE67E22);
  static const Color crimson = Color(0xFFC0392B);
  static const Color cloudWhite = Color(0xFFECF0F1);

  // Flat Palette Aliases
  static const Color flatCharcoal = charcoal;
  static const Color flatCobalt = cobalt;
  static const Color flatEmerald = emerald;
  static const Color flatOrange = orange;
  static const Color flatCrimson = crimson;
  static const Color flatCloudWhite = cloudWhite;

  // ── Opacity Color Constants ───────────────────────────────────────────────
  // Pre-computed to avoid withOpacity() allocations on every build.
  static const Color cobaltLight = Color(0x143498DB);   // cobalt ~8%
  static const Color cobaltMedium = Color(0x263498DB);  // cobalt ~15%
  static const Color cobaltBorder = Color(0x663498DB);  // cobalt ~40%
  static const Color emeraldLight = Color(0x2E27AE60);  // emerald ~18%
  static const Color emeraldBorder = Color(0x6627AE60); // emerald ~40%
  static const Color orangeLight = Color(0x1AE67E22);   // orange ~10%
  static const Color crimsonLight = Color(0x14C0392B);  // crimson ~8%
  static const Color crimsonBorder = Color(0x66C0392B); // crimson ~40%
  static const Color charcoalSurface = Color(0x0A2C3E50); // charcoal ~4%

  // ── Dark Theme Color Constants (High-Contrast Desktop Slate) ────────────
  static const Color darkScaffoldBackground = Color(0xFF182029);
  static const Color darkSurface = Color(0xFF242E3D);
  static const Color darkCardBackground = Color(0xFF253140);
  static const Color darkElevatedSurface = Color(0xFF2C3E50); // Flat Charcoal
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderLight = Color(0xFF3E4E63);
  static const Color darkInputBackground = Color(0xFF1E2631);
  static const Color darkTextPrimary = Color(0xFFECF0F1); // Cloud White
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // ── Context-Aware Theme & Decoration Helpers ──────────────────────────────

  /// Detect whether the current context is rendering in Dark Mode.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Standard card/panel decoration — adaptive to light/dark brightness.
  static BoxDecoration cardDecorationOf(BuildContext context) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark ? darkCardBackground : Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: dark ? darkBorder : const Color(0xFFE0E0E0)),
      boxShadow: [
        BoxShadow(
          color: dark ? const Color(0x33000000) : const Color(0x0A000000),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Lighter decoration for toolbar containers — adaptive.
  static BoxDecoration toolbarDecorationOf(BuildContext context) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark ? darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: dark ? darkBorder : const Color(0xFFE0E0E0)),
      boxShadow: [
        BoxShadow(
          color: dark ? const Color(0x29000000) : const Color(0x08000000),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Decoration for action pill containers — adaptive.
  static BoxDecoration pillDecorationOf(BuildContext context) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark ? darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: dark ? darkBorder : const Color(0xFFEEEEEE)),
      boxShadow: [
        BoxShadow(
          color: dark ? const Color(0x20000000) : const Color(0x05000000),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  // ── Shared BoxDecorations (Legacy & Static) ───────────────────────────────

  /// Standard card/panel decoration — used in toolbars and form sections (Light).
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 5, offset: Offset(0, 2)),
        ],
      );

  /// Dark card/panel decoration.
  static BoxDecoration get darkCardDecoration => BoxDecoration(
        color: darkCardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: darkBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
        ],
      );

  /// Lighter decoration for toolbar containers (Light).
  static BoxDecoration get toolbarDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  /// Dark toolbar decoration.
  static BoxDecoration get darkToolbarDecoration => BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: darkBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x29000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  /// Decoration for action pill containers (Light).
  static BoxDecoration get pillDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      );

  /// Dark pill decoration.
  static BoxDecoration get darkPillDecoration => BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x20000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: cobalt,
      scaffoldBackgroundColor: cloudWhite,
      cardColor: Colors.white,
      fontFamily: 'Segoe UI',

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoal,
        foregroundColor: cloudWhite,
        elevation: 0,
      ),

      // Global Scrollbar Theme across all pages
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(8.0),
        radius: const Radius.circular(6),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return cobalt;
          }
          if (states.contains(WidgetState.hovered)) {
            return cobalt.withOpacity(0.85);
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.all(Colors.grey.shade200),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        crossAxisMargin: 2,
        mainAxisMargin: 2,
      ),

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: cobalt,
        secondary: emerald,
        error: crimson,
        surface: Colors.white,
        onSurface: charcoal,
        surfaceContainerHighest: Color(0xFFF1F4F8),
        outline: Color(0xFFE0E0E0),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x0A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: charcoal,
        ),
      ),

      // Input Decoration Theme (Forms & Inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cobalt, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: crimson, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: crimson, width: 2),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cobalt,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      // DataTable Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F8)),
        headingTextStyle: const TextStyle(
          color: charcoal,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        dataTextStyle: const TextStyle(
          color: charcoal,
          fontSize: 13,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 20,
      ),
    );
  }

  /// Dark Theme (الوضع الليلي المكتبي عالي التباين)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: cobalt,
      scaffoldBackgroundColor: darkScaffoldBackground,
      cardColor: darkCardBackground,
      fontFamily: 'Segoe UI',

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141A22),
        foregroundColor: cloudWhite,
        elevation: 0,
      ),

      // Global Scrollbar Theme across all pages in Dark Mode
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(8.0),
        radius: const Radius.circular(6),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return cobalt;
          }
          if (states.contains(WidgetState.hovered)) {
            return cobalt.withOpacity(0.85);
          }
          return const Color(0xFF475569);
        }),
        trackColor: WidgetStateProperty.all(const Color(0xFF1E2631)),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        crossAxisMargin: 2,
        mainAxisMargin: 2,
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: cobalt,
        secondary: emerald,
        error: crimson,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkElevatedSurface,
        outline: darkBorder,
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: darkCardBackground,
        elevation: 2,
        shadowColor: const Color(0x33000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorder),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: darkElevatedSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),

      // Input Decoration Theme (Forms & Inputs in Dark Mode)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: darkTextMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cobalt, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: crimson, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: crimson, width: 2),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cobalt,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cloudWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: darkBorderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // DataTable Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1E2631)),
        headingTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        dataTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 13,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 20,
      ),
    );
  }
}
