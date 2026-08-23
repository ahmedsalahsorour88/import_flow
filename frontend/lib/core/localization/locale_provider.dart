import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted locale state for ImportFlow ERP.
/// Saved to secure storage so preference survives app restarts.
///
/// Usage:
///   ref.read(localeProvider.notifier).toggleLocale()
///   ref.read(localeProvider.notifier).setLocale(const Locale('ar'))
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  static const _storageKey = 'importflow_locale';
  static const _storage = FlutterSecureStorage();

  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'ar') {
        state = const Locale('ar');
      }
    } catch (_) {
      // fallback to English
    }
  }

  /// Toggle between English and Arabic.
  Future<void> toggleLocale() async {
    final next =
        state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    state = next;
    try {
      await _storage.write(key: _storageKey, value: next.languageCode);
    } catch (_) {}
  }

  /// Set a specific locale.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      await _storage.write(key: _storageKey, value: locale.languageCode);
    } catch (_) {}
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}
