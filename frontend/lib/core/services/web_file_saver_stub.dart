/// WebFileSaver Stub implementation for non-web environments (Desktop / CLI / Tests).
class WebFileSaver {
  /// Whether File System Access API is supported in current platform.
  static bool get isSupported => false;

  /// Attempts to prompt user with native showSaveFilePicker. Always returns null on non-web.
  static Future<String?> saveFileWithPicker({
    required List<int> bytes,
    required String fileName,
    List<String>? allowedExtensions,
  }) async {
    return null;
  }

  /// Triggers fallback browser download. No-op on non-web.
  static void triggerFallbackDownload({
    required List<int> bytes,
    required String fileName,
  }) {}

  /// Stub for openFilePicker on non-web.
  static Future<dynamic> openFilePicker({
    required String fileName,
    List<String>? allowedExtensions,
  }) async {
    return null;
  }

  /// Stub for writeToFileHandle on non-web.
  static Future<String?> writeToFileHandle({
    required dynamic fileHandle,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    return null;
  }
}

