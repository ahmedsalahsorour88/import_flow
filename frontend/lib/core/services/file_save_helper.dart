import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Central Unified File Save Service for ImportFlow ERP
/// Standardizes all file download, export, and generation operations across the entire application.
class FileSaveHelper {
  /// Prompts the user with a native FilePicker save dialog to select the destination path,
  /// then writes the raw [bytes] to disk and displays a professional feedback banner with an
  /// action to open the containing folder in Windows Explorer.
  static Future<String?> saveBytes({
    required BuildContext? context,
    required List<int> bytes,
    required String defaultFileName,
    required String dialogTitle,
    List<String>? allowedExtensions,
    bool showNotification = true,
  }) async {
    try {
      // 1. Open Native Save File Dialog
      final savePath = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: defaultFileName,
        type: (allowedExtensions != null && allowedExtensions.isNotEmpty)
            ? FileType.custom
            : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      // User cancelled the dialog
      if (savePath == null || savePath.trim().isEmpty) {
        return null;
      }

      // 2. Ensure Proper File Extension
      var finalPath = savePath.trim();
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        final primaryExt = allowedExtensions.first.toLowerCase().replaceAll('.', '');
        final hasValidExt = allowedExtensions.any((ext) => finalPath.toLowerCase().endsWith('.${ext.toLowerCase().replaceAll('.', '')}'));
        if (!hasValidExt) {
          finalPath = '$finalPath.$primaryExt';
        }
      }

      // 3. Write File to Disk
      final file = File(finalPath);
      await file.writeAsBytes(bytes);

      // 4. Show Professional Notification with "Open Folder" Action
      if (showNotification && context != null && context.mounted) {
        final fileNameOnly = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : defaultFileName;
        final fileSizeKb = (bytes.length / 1024).toStringAsFixed(1);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم حفظ الملف بنجاح ($fileSizeKb KB)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        fileNameOnly,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'فتح المجلد',
              textColor: Colors.amberAccent,
              onPressed: () {
                openContainingFolder(file.path);
              },
            ),
          ),
        );
      }

      return file.path;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC0392B),
            content: Text('خطأ أثناء حفظ الملف: $e'),
          ),
        );
      }
      return null;
    }
  }

  /// Prompts the user to save a text or CSV string (with UTF-8 BOM for Excel compatibility)
  static Future<String?> saveText({
    required BuildContext? context,
    required String textContent,
    required String defaultFileName,
    required String dialogTitle,
    List<String>? allowedExtensions,
    bool addUtf8Bom = true,
    bool showNotification = true,
  }) async {
    final rawString = addUtf8Bom ? '\uFEFF$textContent' : textContent;
    final bytes = utf8.encode(rawString);
    return saveBytes(
      context: context,
      bytes: bytes,
      defaultFileName: defaultFileName,
      dialogTitle: dialogTitle,
      allowedExtensions: allowedExtensions ?? ['csv', 'txt'],
      showNotification: showNotification,
    );
  }

  /// Opens the folder containing the saved file and selects/highlights it in Windows Explorer
  static void openContainingFolder(String filePath) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        final parentDir = File(filePath).parent.path;
        Process.run('xdg-open', [parentDir]);
      }
    } catch (_) {}
  }
}
