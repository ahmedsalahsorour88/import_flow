import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted theme mode state for Sorour Logistics / ImportFlow ERP.
/// Saved to secure storage so preference survives app restarts.
///
/// Usage:
///   ref.read(themeModeProvider.notifier).toggleTheme();
///   ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _storageKey = 'importflow_theme_mode';
  static const _storage = FlutterSecureStorage();

  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadSavedThemeMode();
  }

  Future<void> _loadSavedThemeMode() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {
      // fallback to light
    }
  }

  /// Toggle between Light and Dark mode.
  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    try {
      final modeStr = next == ThemeMode.dark ? 'dark' : 'light';
      await _storage.write(key: _storageKey, value: modeStr);
    } catch (_) {}
  }

  /// Set a specific theme mode (light, dark, system).
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.system ? 'system' : 'light');
      await _storage.write(key: _storageKey, value: modeStr);
    } catch (_) {}
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
