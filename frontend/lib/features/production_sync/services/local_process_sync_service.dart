import 'dart:io';
import 'dart:convert';

/// Local database statistics read directly from the filesystem (no HTTP needed).
class LocalDbStats {
  final bool exists;
  final String dbPath;
  final double sizeKb;
  final String? mtime;
  final String? error;

  const LocalDbStats({
    required this.exists,
    required this.dbPath,
    this.sizeKb = 0,
    this.mtime,
    this.error,
  });
}

/// A single backup file entry read from the backups directory.
class LocalBackupEntry {
  final String filename;
  final String filepath;
  final double sizeKb;
  final String mtime;
  final String tag;

  const LocalBackupEntry({
    required this.filename,
    required this.filepath,
    required this.sizeKb,
    required this.mtime,
    required this.tag,
  });
}

String _joinPath(String p1, [String? p2, String? p3, String? p4]) {
  final sep = Platform.pathSeparator;
  String res = p1;
  if (p2 != null) res = '$res$sep$p2';
  if (p3 != null) res = '$res$sep$p3';
  if (p4 != null) res = '$res$sep$p4';
  return res;
}

String _baseName(String fullPath) {
  final sep = Platform.pathSeparator;
  final idx = fullPath.lastIndexOf(sep);
  if (idx >= 0 && idx < fullPath.length - 1) {
    return fullPath.substring(idx + 1);
  }
  return fullPath;
}

/// Resolves the ImportFlow project root from the current working directory or executable.
String _resolveProjectRoot() {
  Directory dir = Directory.current;
  for (int i = 0; i < 8; i++) {
    if (File(_joinPath(dir.path, 'sync_to_production.py')).existsSync()) {
      return dir.path;
    }
    if (File(_joinPath(dir.path, 'sorour_logistics.db')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  final exe = File(Platform.resolvedExecutable);
  dir = exe.parent;
  for (int i = 0; i < 8; i++) {
    if (File(_joinPath(dir.path, 'sync_to_production.py')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  return Directory.current.path;
}

/// Service that executes sync operations by running sync_to_production.py
/// as a subprocess — completely independent of the FastAPI backend server.
class LocalProcessSyncService {
  final String _projectRoot;

  LocalProcessSyncService() : _projectRoot = _resolveProjectRoot();

  String get projectRoot => _projectRoot;

  /// Dev database path (always in project root).
  String get devDbPath => _joinPath(_projectRoot, 'sorour_logistics.db');

  /// Prod database path (inside dist/Sorour_Logistics_Standalone).
  String get prodDbPath => _joinPath(
        _projectRoot,
        'dist',
        'Sorour_Logistics_Standalone',
        'sorour_logistics.db',
      );

  /// Backups directory.
  String get backupsPath => _joinPath(_projectRoot, 'backups');

  /// Reads LocalDbStats for a given db file path (no subprocess needed).
  LocalDbStats getDbStats(String dbPath) {
    final file = File(dbPath);
    if (!file.existsSync()) {
      return LocalDbStats(exists: false, dbPath: dbPath);
    }
    try {
      final stat = file.statSync();
      final sizeKb = stat.size / 1024.0;
      final mtime = stat.modified.toLocal().toString().substring(0, 19);
      return LocalDbStats(
        exists: true,
        dbPath: dbPath,
        sizeKb: double.parse(sizeKb.toStringAsFixed(1)),
        mtime: mtime,
      );
    } catch (e) {
      return LocalDbStats(exists: true, dbPath: dbPath, error: e.toString());
    }
  }

  /// Returns all backup files sorted newest first.
  List<LocalBackupEntry> listBackups() {
    final dir = Directory(backupsPath);
    if (!dir.existsSync()) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.map((f) {
      final stat = f.statSync();
      final nameBase = _baseName(f.path);
      String tag = 'backup';
      if (nameBase.contains('prod_before_sync')) {
        tag = 'prod_before_sync';
      } else if (nameBase.contains('dev_snapshot')) {
        tag = 'dev_snapshot';
      } else if (nameBase.contains('dev_before_pull')) {
        tag = 'dev_before_pull';
      } else if (nameBase.contains('prod_before_pack')) {
        tag = 'prod_before_pack';
      } else if (nameBase.contains('prod_snapshot')) {
        tag = 'prod_snapshot';
      } else if (nameBase.contains('manual')) {
        tag = 'manual';
      }
      return LocalBackupEntry(
        filename: nameBase,
        filepath: f.path,
        sizeKb: double.parse((stat.size / 1024.0).toStringAsFixed(1)),
        mtime: stat.modified.toLocal().toString().substring(0, 19),
        tag: tag,
      );
    }).toList();
  }

  /// Runs sync_to_production.py with the given arguments and streams output.
  Future<int> _runScript(
    List<String> args, {
    required void Function(String line) onOutput,
    required void Function(String line) onError,
  }) async {
    onOutput('⚡ > python sync_to_production.py ${args.join(' ')}');
    onOutput('📂 Project Root: $_projectRoot');
    onOutput('────────────────────────────────────────────────────────────────────────');

    final scriptPath = _joinPath(_projectRoot, 'sync_to_production.py');
    if (!File(scriptPath).existsSync()) {
      onError('❌ [ERROR] لم يتم العثور على ملف sync_to_production.py في المسار: $scriptPath');
      return 1;
    }

    try {
      final process = await Process.start(
        'python',
        [scriptPath, ...args],
        workingDirectory: _projectRoot,
        runInShell: true,
      );

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(onOutput);

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((l) => l.trim().isNotEmpty)
          .listen(onError);

      final exitCode = await process.exitCode;
      onOutput('────────────────────────────────────────────────────────────────────────');
      if (exitCode == 0) {
        onOutput('✅ اكتملت العملية بنجاح تام (Exit Code: 0)');
      } else {
        onError('❌ انتهت العملية مع رمز خطأ: $exitCode');
      }
      return exitCode;
    } catch (e) {
      onError('❌ تعذر تشغيل بايثون: $e');
      return 1;
    }
  }

  /// [1] Sync Dev DB → Prod DB (non-destructive).
  Future<int> syncDevToProd({
    required void Function(String) onOutput,
    required void Function(String) onError,
  }) =>
      _runScript(['--db-only'], onOutput: onOutput, onError: onError);

  /// [2] Pull Prod DB → Dev DB (non-destructive).
  Future<int> pullProdToDev({
    required void Function(String) onOutput,
    required void Function(String) onError,
  }) =>
      _runScript(['--pull'], onOutput: onOutput, onError: onError);

  /// [3] Compare Dev vs Prod databases.
  Future<int> compareDatabases({
    required void Function(String) onOutput,
    required void Function(String) onError,
  }) =>
      _runScript(['--compare'], onOutput: onOutput, onError: onError);

  /// [4] Full production build + test + package + sync.
  Future<int> fullBuildAndSync({
    required void Function(String) onOutput,
    required void Function(String) onError,
  }) =>
      _runScript(['--full'], onOutput: onOutput, onError: onError);

  /// [5] Launch production application.
  Future<int> launchProductionApp({
    required void Function(String) onOutput,
    required void Function(String) onError,
  }) =>
      _runScript(['--launch'], onOutput: onOutput, onError: onError);

  /// [6] Create manual backup (creates snapshot in backups/ dir).
  Future<int> createManualBackup({
    required void Function(String) onOutput,
    required void Function(String) onError,
  }) async {
    onOutput('📸 جارٍ إنشاء لقطة فورية لقاعدة البيانات...');
    final devFile = File(devDbPath);
    if (!devFile.existsSync()) {
      onError('❌ لم يتم العثور على قاعدة بيانات التطوير: $devDbPath');
      return 1;
    }

    try {
      final bDir = Directory(backupsPath);
      if (!bDir.existsSync()) bDir.createSync(recursive: true);

      final now = DateTime.now();
      final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final backupPath = _joinPath(backupsPath, 'sorour_logistics_manual_$ts.db');
      devFile.copySync(backupPath);

      final bFile = File(backupPath);
      final sizeKb = bFile.statSync().size / 1024.0;
      onOutput('✅ تم إنشاء نسخة الأمان بنجاح: ${_baseName(backupPath)} (${sizeKb.toStringAsFixed(1)} KB)');
      return 0;
    } catch (e) {
      onError('❌ فشل إنشاء نسخة الأمان: $e');
      return 1;
    }
  }
}
