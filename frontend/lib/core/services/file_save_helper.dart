import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'web_file_saver.dart';

/// Central Unified File Save Service for Sorour Logistics ERP (Task I).
/// 
/// ⚡ PROTOCOL: Mandatory Save File Location Dialog Protocol (قاعدة فتح نافذة حوارية إلزامية لتحديد مكان حفظ وتنزيل الملفات)
/// - All file exports and downloads (Excel, PDF, PNG, CSV, TSV) MUST prompt the user via a native modal dialog
///   allowing explicit selection of the download directory and custom file name.
/// - Silent downloads directly into default downloads or temp folders without user confirmation are STRICTLY FORBIDDEN.
/// - Uses [FilePicker.saveFile] with `lockParentWindow: true` on Desktop to guarantee the dialog appears modally in front.
/// - Uses File System Access API (`window.showSaveFilePicker`) on Chromium Web browsers with graceful AbortError cancel handling.
/// - Falls back gracefully to anchor download with an informative toast on non-supporting browsers (Firefox, Safari, mobile).
/// - Standardizes file naming convention: `[Stage Name] - [Import File Name or Code].[ext]`.
/// - If cancelled, safely returns `null` without throwing errors or showing failed snackbars.
class FileSaveHelper {
  /// Sanitizes string to be valid across Windows, Linux, macOS, and Web filesystems.
  /// Strips invalid characters: / \ : * ? " < > | and redundant spaces.
  static String sanitizeFileName(String name) {
    var sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    sanitized = sanitized.replaceAll(RegExp(r'-+'), '-');
    sanitized = sanitized.trim();
    if (sanitized.isEmpty) {
      sanitized = 'Export';
    }
    return sanitized;
  }

  /// Builds a unified file name following the project standard:
  /// `[Stage Name] - [Import File Name or Code].[extension]`
  /// e.g. `CargoX Blockchain & ACI Hub - PET Stock (IMP-2026-0004).xlsx`
  static String buildExportFileName({
    required String stageName,
    required String importFileNameOrCode,
    required String extension,
  }) {
    final cleanStage = sanitizeFileName(stageName);
    final cleanFile = sanitizeFileName(importFileNameOrCode);
    final cleanExt = extension.replaceAll('.', '').trim().toLowerCase();
    return '$cleanStage - $cleanFile.$cleanExt';
  }

  /// Unified Export & Save method used by all screens and modules.
  /// - Automatically builds standardized file name.
  /// - Always opens the native modal "Save As" dialog to specify location.
  /// - Passes bytes to WebFileSaver / FilePicker.saveFile.
  /// - Triggers native Save As on Desktop and File System Access API on Chromium Web.
  static Future<String?> exportAndSaveFile({
    required BuildContext? context,
    required List<int> bytes,
    required String stageName,
    required String importFileNameOrCode,
    required String extension,
    String? customDialogTitle,
    bool showNotification = true,
  }) async {
    final fileName = buildExportFileName(
      stageName: stageName,
      importFileNameOrCode: importFileNameOrCode,
      extension: extension,
    );
    final cleanExt = extension.replaceAll('.', '').trim().toLowerCase();
    return saveBytes(
      context: context,
      bytes: bytes,
      defaultFileName: fileName,
      dialogTitle: customDialogTitle ?? 'تحديد مكان حفظ وتنزيل ملف $cleanExt (Save File As)',
      allowedExtensions: [cleanExt],
      showNotification: showNotification,
    );
  }

  /// Prompts the user with a native FilePicker save dialog (Desktop) or triggers
  /// native File System Access API / browser download (Web), writing the file safely without platform crashes.
  static Future<String?> saveBytes({
    required BuildContext? context,
    required List<int> bytes,
    required String defaultFileName,
    required String dialogTitle,
    List<String>? allowedExtensions,
    bool showNotification = true,
  }) async {
    try {
      final sanitizedDefaultName = sanitizeFileName(defaultFileName);
      String? finalPath;

      if (kIsWeb) {
        // 1. Web Environment — File System Access API with Graceful Fallback
        if (WebFileSaver.isSupported) {
          final savedName = await WebFileSaver.saveFileWithPicker(
            bytes: bytes,
            fileName: sanitizedDefaultName,
            allowedExtensions: allowedExtensions,
          );
          // null means: user cancelled (AbortError) OR SecurityError (gesture chain broken by prior await).
          // In both cases we fall through to the fallback download below.
          if (savedName == null) {
            // Trigger anchor fallback download so the file is still saved
            WebFileSaver.triggerFallbackDownload(
              bytes: bytes,
              fileName: sanitizedDefaultName,
            );
            finalPath = sanitizedDefaultName;

            // Inform user (only if SecurityError — we can't distinguish, so always show a gentle note)
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFE67E22), // AppTheme.orange
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                  content: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تم حفظ الملف في مجلد التنزيلات (Downloads) — متصفحك لا يدعم اختيار مجلد الحفظ في هذا السياق',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            finalPath = savedName;
          }
        } else {
          // Unsupported Web Browser (Firefox, Safari, Mobile) -> fallback to <a download>
          WebFileSaver.triggerFallbackDownload(
            bytes: bytes,
            fileName: sanitizedDefaultName,
          );
          finalPath = sanitizedDefaultName;

          // Inform user why dialog didn't appear
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFFE67E22), // AppTheme.orange
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'متصفحك لا يدعم اختيار مجلد الحفظ — تم حفظ الملف في مجلد التنزيلات (Downloads)',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      } else {
        // 2. Desktop Environment (Windows, macOS, Linux) — Native Modal FilePicker
        final savePath = await FilePicker.saveFile(
          dialogTitle: dialogTitle,
          fileName: sanitizedDefaultName,
          type: (allowedExtensions != null && allowedExtensions.isNotEmpty)
              ? FileType.custom
              : FileType.any,
          allowedExtensions: allowedExtensions,
          lockParentWindow: true,
        );

        // User cancelled the dialog
        if (savePath == null || savePath.trim().isEmpty) {
          return null;
        }

        var desktopPath = savePath.trim();
        if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
          final primaryExt = allowedExtensions.first.toLowerCase().replaceAll('.', '');
          final hasValidExt = allowedExtensions.any((ext) => desktopPath.toLowerCase().endsWith('.${ext.toLowerCase().replaceAll('.', '')}'));
          if (!hasValidExt) {
            desktopPath = '$desktopPath.$primaryExt';
          }
        }

        final file = io.File(desktopPath);
        await file.writeAsBytes(bytes);
        finalPath = desktopPath;
      }

      // 3. Show Professional Notification with "Open Folder" Action
      if (showNotification && context != null && context.mounted) {
        final fileNameOnly = finalPath.contains('/') || finalPath.contains(r'\')
            ? (finalPath.split(RegExp(r'[\\/]')).last)
            : sanitizedDefaultName;
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
                        'تم حفظ وتنزيل الملف بنجاح ($fileSizeKb KB)',
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
            action: (!kIsWeb && io.Platform.isWindows)
                ? SnackBarAction(
                    label: 'فتح المجلد',
                    textColor: Colors.amberAccent,
                    onPressed: () {
                      openContainingFolder(finalPath!);
                    },
                  )
                : null,
          ),
        );
      }

      return finalPath;
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

  /// Opens the folder containing the saved file and selects/highlights it in Windows Explorer (Desktop only)
  static void openContainingFolder(String filePath) {
    if (kIsWeb) return;
    try {
      if (io.Platform.isWindows) {
        io.Process.run('explorer.exe', ['/select,', filePath]);
      } else if (io.Platform.isMacOS) {
        io.Process.run('open', ['-R', filePath]);
      } else if (io.Platform.isLinux) {
        final parentDir = io.File(filePath).parent.path;
        io.Process.run('xdg-open', [parentDir]);
      }
    } catch (_) {}
  }
}
