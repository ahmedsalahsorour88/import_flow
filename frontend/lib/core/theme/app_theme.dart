import 'package:flutter/material.dart';

class AppTheme {
  // ── Flat Color Palette ────────────────────────────────────────────────────
  static const Color charcoal = Color(0xFF2C3E50);
  static const Color cobalt = Color(0xFF3498DB);
  static const Color emerald = Color(0xFF27AE60);
  static const Color orange = Color(0xFFE67E22);
  static const Color crimson = Color(0xFFC0392B);
  static const Color cloudWhite = Color(0xFFECF0F1);

  // ── Opacity Color Constants ───────────────────────────────────────────────
  // Pre-computed to avoid withOpacity() allocations on every build.
  static const Color cobaltLight = Color(0x143498DB);   // cobalt ~8%
  static const Color cobaltMedium = Color(0x263498DB);  // cobalt ~15%
  static const Color cobaltBorder = Color(0x663498DB);  // cobalt ~40%
  static const Color emeraldLight = Color(0x2E27AE60);  // emerald ~18%
  static const Color emeraldBorder = Color(0x6627AE60); // emerald ~40%
  static const Color orangeLight = Color(0x1AE67E22);   // orange ~10%
  static const Color crimsonLight = Color(0x14C0392B);  // crimson ~8%
  static const Color charcoalSurface = Color(0x0A2C3E50); // charcoal ~4%

  // ── Shared BoxDecorations ─────────────────────────────────────────────────

  /// Standard card/panel decoration — used in toolbars and form sections.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 5, offset: Offset(0, 2)),
        ],
      );

  /// Lighter decoration for toolbar containers.
  static BoxDecoration get toolbarDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  /// Decoration for action pill containers (row action buttons).
  static BoxDecoration get pillDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: cobalt,
      scaffoldBackgroundColor: cloudWhite,
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
    );
  }
}
