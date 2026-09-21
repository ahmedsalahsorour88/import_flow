// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// WebFileSaver implementation for Web using the File System Access API (window.showSaveFilePicker).
/// 
/// Supported on Chromium-based desktop browsers (Chrome, Edge, Opera, Brave) on HTTPS/localhost.
/// Gracefully detects support, prompts user for save directory & file name, handles AbortError (Cancel),
/// and falls back to anchor download on non-supporting browsers (Firefox, Safari, mobile).
class WebFileSaver {
  /// Feature-detect File System Access API: 'showSaveFilePicker' in window
  static bool get isSupported {
    try {
      return js_util.hasProperty(html.window, 'showSaveFilePicker');
    } catch (_) {
      return false;
    }
  }

  /// Prompts user with native Save As file picker via File System Access API.
  /// 
  /// Returns:
  /// - `String` (chosen file name/path) upon successful save.
  /// - `null` if the user intentionally clicked 'Cancel' (AbortError).
  /// - Throws exception if API fails unexpectedly or is not supported.
  static Future<String?> saveFileWithPicker({
    required List<int> bytes,
    required String fileName,
    List<String>? allowedExtensions,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('showSaveFilePicker is not supported in this browser');
    }

    try {
      final ext = allowedExtensions != null && allowedExtensions.isNotEmpty
          ? allowedExtensions.first.replaceAll('.', '').toLowerCase().trim()
          : (fileName.contains('.') ? fileName.split('.').last.toLowerCase().trim() : '');

      String mimeType = 'application/octet-stream';
      String description = 'Document';
      List<String> extList = [];

      if (ext == 'pdf') {
        mimeType = 'application/pdf';
        description = 'PDF Document';
        extList = ['.pdf'];
      } else if (ext == 'xlsx') {
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        description = 'Excel Spreadsheet';
        extList = ['.xlsx'];
      } else if (ext == 'xls') {
        mimeType = 'application/vnd.ms-excel';
        description = 'Excel 97-2004 Spreadsheet';
        extList = ['.xls'];
      } else if (ext == 'csv') {
        mimeType = 'text/csv';
        description = 'CSV Document';
        extList = ['.csv'];
      } else if (ext == 'png') {
        mimeType = 'image/png';
        description = 'PNG Image';
        extList = ['.png'];
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
        description = 'JPEG Image';
        extList = ['.jpg', '.jpeg'];
      } else if (ext == 'txt') {
        mimeType = 'text/plain';
        description = 'Text Document';
        extList = ['.txt'];
      } else if (ext.isNotEmpty) {
        mimeType = 'application/$ext';
        description = '${ext.toUpperCase()} Document';
        extList = ['.${ext.toLowerCase()}'];
      }

      final pickerOptions = js_util.newObject();
      js_util.setProperty(pickerOptions, 'suggestedName', fileName);

      if (extList.isNotEmpty) {
        final acceptObj = js_util.newObject();
        js_util.setProperty(acceptObj, mimeType, js_util.jsify(extList));

        final typeObj = js_util.newObject();
        js_util.setProperty(typeObj, 'description', description);
        js_util.setProperty(typeObj, 'accept', acceptObj);

        js_util.setProperty(pickerOptions, 'types', js_util.jsify([typeObj]));
      }

      // ⚡ CRITICAL FIX — User Gesture Chain Rule:
      // showSaveFilePicker() MUST be called synchronously within the browser user-gesture
      // handler (onClick). Any await BEFORE this call causes the browser to lose the gesture
      // context → SecurityError: "Must be handling a user gesture to show a file picker."
      //
      // Correct pattern:
      //   1. Call JS method synchronously (no prior await) → gesture chain satisfied ✅
      //   2. Await the returned Promise → browser allows this ✅
      //   3. Write data to the obtained FileHandle stream → safe ✅
      //
      // NEVER do: await someAsyncWork(); then showSaveFilePicker() — this breaks the chain ❌
      final handlePromise = js_util.callMethod(html.window, 'showSaveFilePicker', [pickerOptions]);

      // Safe to await from here — gesture chain was honoured by the synchronous JS call above.
      final fileHandle = await js_util.promiseToFuture(handlePromise);

      // Create writable stream
      final writablePromise = js_util.callMethod(fileHandle, 'createWritable', []);
      final writable = await js_util.promiseToFuture(writablePromise);

      // Write data as Blob
      final u8 = Uint8List.fromList(bytes);
      final blob = html.Blob([u8], mimeType);
      final writePromise = js_util.callMethod(writable, 'write', [blob]);
      await js_util.promiseToFuture(writePromise);

      // Close the stream
      final closePromise = js_util.callMethod(writable, 'close', []);
      await js_util.promiseToFuture(closePromise);

      // Retrieve chosen name if available
      try {
        final nameProp = js_util.getProperty(fileHandle, 'name');
        if (nameProp != null && nameProp.toString().trim().isNotEmpty) {
          return nameProp.toString().trim();
        }
      } catch (_) {}

      return fileName;
    } catch (e) {
      final errStr = e.toString();
      // AbortError  → user cancelled the dialog → return null silently
      // SecurityError → gesture chain was already broken upstream (caller did await before
      //                 invoking FileSaveHelper) → fall back gracefully without crashing
      bool isGestureCancellation = errStr.contains('AbortError') || errStr.contains('SecurityError');
      try {
        if (js_util.hasProperty(e, 'name')) {
          final errName = js_util.getProperty(e, 'name').toString();
          if (errName == 'AbortError' || errName == 'SecurityError') {
            isGestureCancellation = true;
          }
        }
      } catch (_) {}

      if (isGestureCancellation) {
        return null; // Caller will fall back to triggerFallbackDownload
      }
      rethrow;
    }
  }

  /// Triggers fallback browser download via <a> anchor for browsers without File System Access API
  /// (e.g. Firefox, Safari, Mobile).
  static void triggerFallbackDownload({
    required List<int> bytes,
    required String fileName,
  }) {
    final u8 = Uint8List.fromList(bytes);
    final blob = html.Blob([u8]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName;
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
