class HttpEndpointStatModel {
  final String path;
  final String method;
  final int count;
  final double p50Ms;
  final double p95Ms;
  final int errors;

  HttpEndpointStatModel({
    required this.path,
    required this.method,
    required this.count,
    required this.p50Ms,
    required this.p95Ms,
    required this.errors,
  });

  factory HttpEndpointStatModel.fromJson(Map<String, dynamic> json) {
    return HttpEndpointStatModel(
      path: json['path'] ?? '',
      method: json['method'] ?? '',
      count: json['count'] ?? 0,
      p50Ms: (json['p50_ms'] as num?)?.toDouble() ?? 0.0,
      p95Ms: (json['p95_ms'] as num?)?.toDouble() ?? 0.0,
      errors: json['errors'] ?? 0,
    );
  }
}

class SystemMetricsModel {
  final String status;
  final double uptimeSeconds;
  final String uptimeHuman;
  final double processCpuPercent;
  final double processMemoryMb;
  final double systemCpuPercent;
  final double systemMemoryPercent;
  final double requestsPerSecond;
  final int totalRequests;
  final int totalErrors;
  final double p50LatencyMs;
  final double p95LatencyMs;
  final double p99LatencyMs;
  final int status2xx;
  final int status4xx;
  final int status5xx;
  final List<HttpEndpointStatModel> topEndpoints;

  SystemMetricsModel({
    required this.status,
    required this.uptimeSeconds,
    required this.uptimeHuman,
    required this.processCpuPercent,
    required this.processMemoryMb,
    required this.systemCpuPercent,
    required this.systemMemoryPercent,
    required this.requestsPerSecond,
    required this.totalRequests,
    required this.totalErrors,
    required this.p50LatencyMs,
    required this.p95LatencyMs,
    required this.p99LatencyMs,
    required this.status2xx,
    required this.status4xx,
    required this.status5xx,
    required this.topEndpoints,
  });

  factory SystemMetricsModel.fromJson(Map<String, dynamic> json) {
    final rawEndpoints = json['top_endpoints'] as List<dynamic>? ?? [];
    return SystemMetricsModel(
      status: json['status'] ?? 'UNKNOWN',
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toDouble() ?? 0.0,
      uptimeHuman: json['uptime_human'] ?? '0m',
      processCpuPercent: (json['process_cpu_percent'] as num?)?.toDouble() ?? 0.0,
      processMemoryMb: (json['process_memory_mb'] as num?)?.toDouble() ?? 0.0,
      systemCpuPercent: (json['system_cpu_percent'] as num?)?.toDouble() ?? 0.0,
      systemMemoryPercent: (json['system_memory_percent'] as num?)?.toDouble() ?? 0.0,
      requestsPerSecond: (json['requests_per_second'] as num?)?.toDouble() ?? 0.0,
      totalRequests: json['total_requests'] ?? 0,
      totalErrors: json['total_errors'] ?? 0,
      p50LatencyMs: (json['p50_latency_ms'] as num?)?.toDouble() ?? 0.0,
      p95LatencyMs: (json['p95_latency_ms'] as num?)?.toDouble() ?? 0.0,
      p99LatencyMs: (json['p99_latency_ms'] as num?)?.toDouble() ?? 0.0,
      status2xx: json['status_2xx'] ?? 0,
      status4xx: json['status_4xx'] ?? 0,
      status5xx: json['status_5xx'] ?? 0,
      topEndpoints: rawEndpoints.map((e) => HttpEndpointStatModel.fromJson(e)).toList(),
    );
  }
}

class SlowQueryItemModel {
  final String timestamp;
  final double durationMs;
  final String statement;
  final String? paramsSummary;

  SlowQueryItemModel({
    required this.timestamp,
    required this.durationMs,
    required this.statement,
    this.paramsSummary,
  });

  factory SlowQueryItemModel.fromJson(Map<String, dynamic> json) {
    return SlowQueryItemModel(
      timestamp: json['timestamp'] ?? '',
      durationMs: (json['duration_ms'] as num?)?.toDouble() ?? 0.0,
      statement: json['statement'] ?? '',
      paramsSummary: json['params_summary'],
    );
  }
}

class DatabaseHealthModel {
  final bool connected;
  final String engineType;
  final double databaseSizeMb;
  final double walSizeMb;
  final String journalMode;
  final int busyTimeoutMs;
  final int lockWaitEvents;
  final int slowQueriesCount;
  final List<SlowQueryItemModel> recentSlowQueries;

  DatabaseHealthModel({
    required this.connected,
    required this.engineType,
    required this.databaseSizeMb,
    required this.walSizeMb,
    required this.journalMode,
    required this.busyTimeoutMs,
    required this.lockWaitEvents,
    required this.slowQueriesCount,
    required this.recentSlowQueries,
  });

  factory DatabaseHealthModel.fromJson(Map<String, dynamic> json) {
    final rawSlow = json['recent_slow_queries'] as List<dynamic>? ?? [];
    return DatabaseHealthModel(
      connected: json['connected'] ?? false,
      engineType: json['engine_type'] ?? 'SQLite',
      databaseSizeMb: (json['database_size_mb'] as num?)?.toDouble() ?? 0.0,
      walSizeMb: (json['wal_size_mb'] as num?)?.toDouble() ?? 0.0,
      journalMode: json['journal_mode'] ?? 'WAL',
      busyTimeoutMs: json['busy_timeout_ms'] ?? 30000,
      lockWaitEvents: json['lock_wait_events'] ?? 0,
      slowQueriesCount: json['slow_queries_count'] ?? 0,
      recentSlowQueries: rawSlow.map((s) => SlowQueryItemModel.fromJson(s)).toList(),
    );
  }
}

class DomainRadarModel {
  final int expiringAcidsCount;
  final List<Map<String, dynamic>> expiringAcids;
  final int demurrageRisksCount;
  final List<Map<String, dynamic>> demurrageRisks;
  final int stuckShipmentsCount;
  final List<Map<String, dynamic>> stuckShipments;
  final String? lastBackupTimestamp;
  final String lastBackupStatus;
  final String? lastBackupFile;
  final double lastBackupSizeMb;

  DomainRadarModel({
    required this.expiringAcidsCount,
    required this.expiringAcids,
    required this.demurrageRisksCount,
    required this.demurrageRisks,
    required this.stuckShipmentsCount,
    required this.stuckShipments,
    this.lastBackupTimestamp,
    required this.lastBackupStatus,
    this.lastBackupFile,
    required this.lastBackupSizeMb,
  });

  factory DomainRadarModel.fromJson(Map<String, dynamic> json) {
    return DomainRadarModel(
      expiringAcidsCount: json['expiring_acids_count'] ?? 0,
      expiringAcids: (json['expiring_acids'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      demurrageRisksCount: json['demurrage_risks_count'] ?? 0,
      demurrageRisks: (json['demurrage_risks'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      stuckShipmentsCount: json['stuck_shipments_count'] ?? 0,
      stuckShipments: (json['stuck_shipments'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      lastBackupTimestamp: json['last_backup_timestamp'],
      lastBackupStatus: json['last_backup_status'] ?? 'UNKNOWN',
      lastBackupFile: json['last_backup_file'],
      lastBackupSizeMb: (json['last_backup_size_mb'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeepHealthCheckModel {
  final String verdict; // HEALTHY, DEGRADED, CRITICAL
  final String timestamp;
  final bool databaseWriteProbe;
  final double databaseWriteLatencyMs;
  final String databaseIntegrity;
  final double freeDiskSpaceGb;
  final String diskStatus;
  final String backupFreshness;
  final List<String> issues;

  DeepHealthCheckModel({
    required this.verdict,
    required this.timestamp,
    required this.databaseWriteProbe,
    required this.databaseWriteLatencyMs,
    required this.databaseIntegrity,
    required this.freeDiskSpaceGb,
    required this.diskStatus,
    required this.backupFreshness,
    required this.issues,
  });

  factory DeepHealthCheckModel.fromJson(Map<String, dynamic> json) {
    return DeepHealthCheckModel(
      verdict: json['verdict'] ?? 'UNKNOWN',
      timestamp: json['timestamp'] ?? '',
      databaseWriteProbe: json['database_write_probe'] ?? false,
      databaseWriteLatencyMs: (json['database_write_latency_ms'] as num?)?.toDouble() ?? 0.0,
      databaseIntegrity: json['database_integrity'] ?? 'ok',
      freeDiskSpaceGb: (json['free_disk_space_gb'] as num?)?.toDouble() ?? 0.0,
      diskStatus: json['disk_status'] ?? 'OK',
      backupFreshness: json['backup_freshness'] ?? 'OK',
      issues: (json['issues'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class RecentTrafficItemModel {
  final String requestId;
  final String timestamp;
  final String method;
  final String path;
  final int statusCode;
  final double durationMs;
  final String? clientIp;

  RecentTrafficItemModel({
    required this.requestId,
    required this.timestamp,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.durationMs,
    this.clientIp,
  });

  factory RecentTrafficItemModel.fromJson(Map<String, dynamic> json) {
    return RecentTrafficItemModel(
      requestId: json['request_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      method: json['method'] ?? '',
      path: json['path'] ?? '',
      statusCode: json['status_code'] ?? 200,
      durationMs: (json['duration_ms'] as num?)?.toDouble() ?? 0.0,
      clientIp: json['client_ip'],
    );
  }
}
