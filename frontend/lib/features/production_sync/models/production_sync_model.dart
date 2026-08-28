class DatabaseStatsModel {
  final bool exists;
  final String? path;
  final double sizeKb;
  final int tablesCount;
  final int totalRecords;
  final String? mtime;
  final String? error;

  const DatabaseStatsModel({
    required this.exists,
    this.path,
    this.sizeKb = 0.0,
    this.tablesCount = 0,
    this.totalRecords = 0,
    this.mtime,
    this.error,
  });

  factory DatabaseStatsModel.fromJson(Map<String, dynamic> json) {
    return DatabaseStatsModel(
      exists: json['exists'] as bool? ?? true,
      path: json['path'] as String?,
      sizeKb: (json['size_kb'] as num?)?.toDouble() ?? 0.0,
      tablesCount: json['tables_count'] as int? ?? 0,
      totalRecords: json['total_records'] as int? ?? 0,
      mtime: json['mtime'] as String?,
      error: json['error'] as String?,
    );
  }
}

class TableComparisonItemModel {
  final String tableName;
  final int devCount;
  final int prodCount;
  final int diff;
  final bool isMatch;
  final String status;
  // ── Schema comparison fields ──────────────────────────────────────────
  final int devColumnsCount;
  final int prodColumnsCount;
  final List<String> newColumns;
  final bool isNewTable;
  final bool hasSchemaDiff;
  final bool needsSync;

  const TableComparisonItemModel({
    required this.tableName,
    required this.devCount,
    required this.prodCount,
    required this.diff,
    required this.isMatch,
    required this.status,
    this.devColumnsCount = 0,
    this.prodColumnsCount = 0,
    this.newColumns = const [],
    this.isNewTable = false,
    this.hasSchemaDiff = false,
    this.needsSync = false,
  });

  factory TableComparisonItemModel.fromJson(Map<String, dynamic> json) {
    return TableComparisonItemModel(
      tableName: json['table_name'] as String? ?? '',
      devCount: json['dev_count'] as int? ?? 0,
      prodCount: json['prod_count'] as int? ?? 0,
      diff: json['diff'] as int? ?? 0,
      isMatch: json['is_match'] as bool? ?? true,
      status: json['status'] as String? ?? '',
      devColumnsCount: json['dev_columns_count'] as int? ?? 0,
      prodColumnsCount: json['prod_columns_count'] as int? ?? 0,
      newColumns: (json['new_columns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isNewTable: json['is_new_table'] as bool? ?? false,
      hasSchemaDiff: json['has_schema_diff'] as bool? ?? false,
      needsSync: json['needs_sync'] as bool? ?? false,
    );
  }
}

class SyncComparisonResponseModel {
  final DatabaseStatsModel devStats;
  final DatabaseStatsModel prodStats;
  final bool isFullySynchronized;
  final int totalTables;
  final int matchedTablesCount;
  final int differingTablesCount;
  final int schemaDiffsCount;
  final List<TableComparisonItemModel> tables;

  const SyncComparisonResponseModel({
    required this.devStats,
    required this.prodStats,
    required this.isFullySynchronized,
    required this.totalTables,
    required this.matchedTablesCount,
    required this.differingTablesCount,
    this.schemaDiffsCount = 0,
    required this.tables,
  });

  factory SyncComparisonResponseModel.fromJson(Map<String, dynamic> json) {
    return SyncComparisonResponseModel(
      devStats: DatabaseStatsModel.fromJson(Map<String, dynamic>.from(json['dev_stats'] as Map? ?? {})),
      prodStats: DatabaseStatsModel.fromJson(Map<String, dynamic>.from(json['prod_stats'] as Map? ?? {})),
      isFullySynchronized: json['is_fully_synchronized'] as bool? ?? false,
      totalTables: json['total_tables'] as int? ?? 0,
      matchedTablesCount: json['matched_tables_count'] as int? ?? 0,
      differingTablesCount: json['differing_tables_count'] as int? ?? 0,
      schemaDiffsCount: json['schema_diffs_count'] as int? ?? 0,
      tables: (json['tables'] as List<dynamic>? ?? [])
          .map((item) => TableComparisonItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class SyncActionResponseModel {
  final bool success;
  final String action;
  final String message;
  final String timestamp;
  final String? backupFile;
  final int affectedTablesCount;
  final int totalRecordsSynced;
  final Map<String, dynamic>? details;

  const SyncActionResponseModel({
    required this.success,
    required this.action,
    required this.message,
    required this.timestamp,
    this.backupFile,
    this.affectedTablesCount = 0,
    this.totalRecordsSynced = 0,
    this.details,
  });

  factory SyncActionResponseModel.fromJson(Map<String, dynamic> json) {
    return SyncActionResponseModel(
      success: json['success'] as bool? ?? false,
      action: json['action'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      backupFile: json['backup_file'] as String?,
      affectedTablesCount: json['affected_tables_count'] as int? ?? 0,
      totalRecordsSynced: json['total_records_synced'] as int? ?? 0,
      details: json['details'] != null ? Map<String, dynamic>.from(json['details'] as Map) : null,
    );
  }
}

class BackupItemModel {
  final String filename;
  final String filepath;
  final double sizeKb;
  final String createdAt;
  final String tag;

  const BackupItemModel({
    required this.filename,
    required this.filepath,
    required this.sizeKb,
    required this.createdAt,
    required this.tag,
  });

  factory BackupItemModel.fromJson(Map<String, dynamic> json) {
    return BackupItemModel(
      filename: json['filename'] as String? ?? '',
      filepath: json['filepath'] as String? ?? '',
      sizeKb: (json['size_kb'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String? ?? '',
      tag: json['tag'] as String? ?? 'backup',
    );
  }
}

class RestoreBackupResponseModel {
  final bool success;
  final String message;
  final String timestamp;
  final String restoredFrom;
  final String safetyBackupCreated;
  final String target;

  const RestoreBackupResponseModel({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.restoredFrom,
    required this.safetyBackupCreated,
    required this.target,
  });

  factory RestoreBackupResponseModel.fromJson(Map<String, dynamic> json) {
    return RestoreBackupResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      restoredFrom: json['restored_from'] as String? ?? '',
      safetyBackupCreated: json['safety_backup_created'] as String? ?? '',
      target: json['target'] as String? ?? 'prod',
    );
  }
}

class RemoteUpdateCheckModel {
  final String currentVersion;
  final int currentBuild;
  final String? latestVersion;
  final String? latestTag;
  final bool updateAvailable;
  final String? releaseName;
  final String? releaseNotes;
  final String? publishedAt;
  final String? installerDownloadUrl;
  final String? portableZipDownloadUrl;
  final String? htmlUrl;
  final String checkStatus;
  final String? errorMessage;

  const RemoteUpdateCheckModel({
    required this.currentVersion,
    required this.currentBuild,
    this.latestVersion,
    this.latestTag,
    this.updateAvailable = false,
    this.releaseName,
    this.releaseNotes,
    this.publishedAt,
    this.installerDownloadUrl,
    this.portableZipDownloadUrl,
    this.htmlUrl,
    this.checkStatus = 'success',
    this.errorMessage,
  });

  factory RemoteUpdateCheckModel.fromJson(Map<String, dynamic> json) {
    return RemoteUpdateCheckModel(
      currentVersion: json['current_version'] as String? ?? '1.0.0',
      currentBuild: json['current_build'] as int? ?? 1,
      latestVersion: json['latest_version'] as String?,
      latestTag: json['latest_tag'] as String?,
      updateAvailable: json['update_available'] as bool? ?? false,
      releaseName: json['release_name'] as String?,
      releaseNotes: json['release_notes'] as String?,
      publishedAt: json['published_at'] as String?,
      installerDownloadUrl: json['installer_download_url'] as String?,
      portableZipDownloadUrl: json['portable_zip_download_url'] as String?,
      htmlUrl: json['html_url'] as String?,
      checkStatus: json['check_status'] as String? ?? 'success',
      errorMessage: json['error_message'] as String?,
    );
  }
}


