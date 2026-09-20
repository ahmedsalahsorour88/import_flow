import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local autosave drafts for Purchase Order form sessions.
/// Enables crash/power-loss recovery without committing partial state to the backend database.
class PODraftManager {
  static const String _keyPrefix = 'po_form_draft_';

  static String _formatKey(dynamic poId) {
    return '$_keyPrefix${poId ?? "new"}';
  }

  /// Saves a snapshot of in-progress PO form data to local persistent storage.
  static Future<void> saveDraft({
    required dynamic poId,
    required Map<String, dynamic> draftData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      draftData['saved_at'] = DateTime.now().toIso8601String();
      final jsonStr = jsonEncode(draftData);
      await prefs.setString(_formatKey(poId), jsonStr);
    } catch (_) {
      // Non-blocking fallback
    }
  }

  /// Retrieves the saved draft for the given PO session if one exists.
  static Future<Map<String, dynamic>?> loadDraft(dynamic poId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_formatKey(poId));
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clears the saved draft after successful save or explicit discard.
  static Future<void> clearDraft(dynamic poId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_formatKey(poId));
    } catch (_) {
      // Non-blocking fallback
    }
  }

  /// Checks if a draft exists for the given PO session.
  static Future<bool> hasDraft(dynamic poId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_formatKey(poId));
    } catch (_) {
      return false;
    }
  }
}
