import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/api_constants.dart';
import '../models/production_sync_model.dart';

/// States of the in-app auto-update download process.
enum AutoUpdateState {
  idle,
  downloading,
  done,
  launching,
  error,
}

/// Service responsible for downloading and launching the latest installer
/// for in-app silent self-update on Windows.
class AutoUpdaterService {
  final Dio _dio;

  AutoUpdaterService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 30),
              ),
            );

  /// Fetches the latest installer info from the backend API.
  Future<InstallerInfoModel> getInstallerInfo() async {
    final response = await Dio(
      BaseOptions(
        baseUrl: ApiConstants.serverUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    ).get('/api/v1/production-sync/installer-info');

    if (response.statusCode == 200) {
      return InstallerInfoModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
    throw Exception('Failed to fetch installer info: ${response.statusCode}');
  }

  /// Downloads the installer from [installerUrl] to the Windows temp directory.
  /// Reports progress via [onProgress] (0.0 to 1.0).
  /// Returns the local path of the downloaded installer file.
  Future<String> downloadInstaller({
    required String installerUrl,
    required String installerFilename,
    required void Function(double progress, int downloadedMb, int totalMb) onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempBase = Platform.environment['TEMP'] ??
        Platform.environment['TMP'] ??
        Directory.systemTemp.path;
    final tempDir = Directory(p.join(tempBase, 'SorourLogisticsUpdate'));
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }

    final savePath = p.join(tempDir.path, installerFilename);

    // Remove stale file
    final existingFile = File(savePath);
    if (existingFile.existsSync()) {
      existingFile.deleteSync();
    }

    await _dio.download(
      installerUrl,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          final downloadedMb = (received / (1024 * 1024)).round();
          final totalMb = (total / (1024 * 1024)).round();
          onProgress(progress, downloadedMb, totalMb);
        }
      },
    );

    final downloadedFile = File(savePath);
    if (!downloadedFile.existsSync() || downloadedFile.lengthSync() < 1024) {
      throw Exception('Download failed or file is corrupt. Please try again.');
    }

    return savePath;
  }

  /// Launches the downloaded Inno Setup installer silently and exits the Flutter app.
  Future<void> launchInstallerAndExit(String installerPath) async {
    final file = File(installerPath);
    if (!file.existsSync()) {
      throw Exception('Installer file not found: $installerPath');
    }

    await Process.start(
      installerPath,
      ['/SILENT', '/NORESTART'],
      mode: ProcessStartMode.detached,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    exit(0);
  }

  /// Cleans up the temp update folder.
  void cleanupTempFolder() {
    try {
      final tempBase = Platform.environment['TEMP'] ??
          Platform.environment['TMP'] ??
          Directory.systemTemp.path;
      final tempDir = Directory(p.join(tempBase, 'SorourLogisticsUpdate'));
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }
}
