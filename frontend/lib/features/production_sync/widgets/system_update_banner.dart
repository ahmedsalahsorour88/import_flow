import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/production_sync_provider.dart';
import '../services/auto_updater_service.dart';

/// Model representing the version check response from GET /api/v1/system/version
class SystemVersionCheckResult {
  final bool hasUpdate;
  final bool isCompatible;
  final bool forceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String minCompatibleVersion;
  final int buildNumber;
  final String installerUrl;
  final String localDownloadUrl;
  final String installerFilename;
  final double installerSizeMb;
  final List<String> releaseNotes;

  const SystemVersionCheckResult({
    required this.hasUpdate,
    required this.isCompatible,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.minCompatibleVersion,
    required this.buildNumber,
    required this.installerUrl,
    required this.localDownloadUrl,
    required this.installerFilename,
    required this.installerSizeMb,
    required this.releaseNotes,
  });

  factory SystemVersionCheckResult.fromJson(Map<String, dynamic> json) {
    return SystemVersionCheckResult(
      hasUpdate: json['has_update'] as bool? ?? false,
      isCompatible: json['is_compatible'] as bool? ?? true,
      forceUpdate: json['force_update'] as bool? ?? false,
      currentVersion: json['current_version'] as String? ?? '1.0.198',
      latestVersion: json['latest_version'] as String? ?? '1.0.198',
      minCompatibleVersion: json['min_compatible_version'] as String? ?? '1.0.180',
      buildNumber: json['build_number'] as int? ?? 199,
      installerUrl: json['installer_url'] as String? ?? '',
      localDownloadUrl: json['local_download_url'] as String? ?? '/api/v1/system/download-installer',
      installerFilename: json['installer_filename'] as String? ?? 'Sorour_Logistics_Setup.exe',
      installerSizeMb: (json['installer_size_mb'] as num?)?.toDouble() ?? 198.0,
      releaseNotes: (json['release_notes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Provider that checks whether an update is available from the backend API
final systemVersionCheckProvider = FutureProvider<SystemVersionCheckResult>((ref) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.serverUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'X-Client-Version': ApiConstants.clientVersion,
      },
    ),
  );

  final response = await dio.get(
    '/api/v1/system/version',
    queryParameters: {'client_version': ApiConstants.clientVersion},
  );

  if (response.statusCode == 200 && response.data is Map) {
    return SystemVersionCheckResult.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
  throw Exception('Failed to check system version');
});

/// Session-based dismissed state provider so normal updates can be dismissed once per app session
final updateBannerDismissedProvider = StateProvider<bool>((ref) => false);

/// Non-blocking Enterprise Update Notification Banner
class SystemUpdateBanner extends ConsumerWidget {
  const SystemUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = ref.watch(updateBannerDismissedProvider);
    final checkAsync = ref.watch(systemVersionCheckProvider);

    return checkAsync.when(
      data: (info) {
        if (!info.hasUpdate) return const SizedBox.shrink();
        if (isDismissed && !info.forceUpdate) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isCritical = info.forceUpdate || !info.isCompatible;

        final bgColor = isCritical
            ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2))
            : (isDark ? const Color(0xFF3B2D14) : const Color(0xFFFFFBEB));

        final borderColor = isCritical
            ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
            : (isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A));

        final textColor = isCritical
            ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
            : (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E));

        final iconColor = isCritical ? AppTheme.crimson : const Color(0xFFD97706);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
          ),
          child: Row(
            children: [
              Icon(
                isCritical ? Icons.warning_amber_rounded : Icons.system_update_alt_rounded,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCritical
                      ? 'تنبيه إلزامي: إصدار التطبيق الحالي (v${ApiConstants.clientVersion}) غير متوافق مع قاعدة البيانات. يرجى التحديث إلى (v${info.latestVersion}) للمتابعة بأمان.'
                      : 'يتوفر تحديث جديد للنظام (v${info.latestVersion}) يتضمن تحسينات ومزايا جديدة. انقر لتثبيته في ثوانٍ.',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: isCritical ? FontWeight.bold : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(context, info),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(
                  isCritical ? 'تحديث إلزامي الآن' : 'تحديث وتثبيت',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCritical ? AppTheme.crimson : AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 1,
                ),
              ),
              if (!isCritical) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'إخفاء التنبيه لهذه الجلسة',
                  color: textColor.withOpacity(0.7),
                  onPressed: () {
                    ref.read(updateBannerDismissedProvider.notifier).state = true;
                  },
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showUpdateDialog(BuildContext context, SystemVersionCheckResult info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => UpdateAvailableDialog(info: info),
    );
  }
}

/// Modal Dialog for Downloading and Executing the Inno Setup Update
class UpdateAvailableDialog extends ConsumerWidget {
  final SystemVersionCheckResult info;
  const UpdateAvailableDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppTheme.charcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cobalt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحديث تطبيق Sorour Logistics ERP',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'الإصدار الحالي: v${ApiConstants.clientVersion} ← الإصدار الجديد: v${info.latestVersion}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Release Notes Header
            Row(
              children: [
                const Icon(Icons.article_outlined, size: 18, color: AppTheme.cobalt),
                const SizedBox(width: 6),
                const Text(
                  'أبرز التحديثات والمزايا في هذا الإصدار:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const Spacer(),
                Text(
                  'الحجم: ~${info.installerSizeMb.toStringAsFixed(1)} MB',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Scrollable Release Notes List
            Container(
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2631) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
              ),
              child: info.releaseNotes.isEmpty
                  ? const Center(child: Text('تحسينات أمنية وإصلاحات تشغيلية عامة.'))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: info.releaseNotes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, i) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                info.releaseNotes[i],
                                style: const TextStyle(fontSize: 12.5, height: 1.3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Download Progress & States
            if (downloadState.state == AutoUpdateState.downloading) ...[
              LinearProgressIndicator(
                value: downloadState.progress > 0 ? downloadState.progress : null,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.cobalt,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'جاري التنزيل: ${downloadState.downloadedMb} MB من ${downloadState.totalMb > 0 ? downloadState.totalMb : info.installerSizeMb.round()} MB',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(downloadState.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                  ),
                ],
              ),
            ] else if (downloadState.state == AutoUpdateState.done) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132F20) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.emerald),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اكتمل تحميل التحديث بنجاح! جاهز للتثبيت السريع وإعادة التشغيل.',
                        style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (downloadState.state == AutoUpdateState.error) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.crimson),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        downloadState.errorMessage ?? 'حدث خطأ أثناء تنزيل التحديث.',
                        style: const TextStyle(color: AppTheme.crimson, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        if (downloadState.state != AutoUpdateState.downloading &&
            downloadState.state != AutoUpdateState.launching &&
            !info.forceUpdate)
          TextButton(
            onPressed: () {
              ref.read(downloadProgressProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('تذكيري لاحقاً'),
          ),
        if (downloadState.state == AutoUpdateState.downloading)
          TextButton(
            onPressed: () {
              ref.read(downloadProgressProvider.notifier).cancelDownload();
            },
            child: const Text('إلغاء التنزيل', style: TextStyle(color: AppTheme.crimson)),
          ),
        if (downloadState.state == AutoUpdateState.idle || downloadState.state == AutoUpdateState.error)
          ElevatedButton.icon(
            onPressed: () {
              // Prefer local LAN server download endpoint; fallback to installerUrl
              final targetUrl = '${ApiConstants.serverUrl}${info.localDownloadUrl}';
              ref.read(downloadProgressProvider.notifier).startDownload(
                    installerUrl: targetUrl,
                    installerFilename: info.installerFilename,
                    installerSizeMb: info.installerSizeMb,
                  );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('بدء التنزيل والتثبيت'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        if (downloadState.state == AutoUpdateState.done)
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(downloadProgressProvider.notifier).launchAndExit();
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('تثبيت الآن وإعادة التشغيل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }
}
