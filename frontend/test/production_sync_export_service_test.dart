import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/production_sync/services/local_process_sync_models.dart';
import 'package:frontend/features/production_sync/services/production_sync_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductionSyncExportService Tests', () {
    const mockTables = [
      SyncTableDiff(
        tableName: 'transport_locations',
        devCount: 261,
        prodCount: 256,
        diff: 5,
        status: 'NEW_DATA',
      ),
      SyncTableDiff(
        tableName: 'cargo_insurance_certificates',
        devCount: 10,
        prodCount: 0,
        diff: 10,
        status: 'NEW_TABLE',
      ),
      SyncTableDiff(
        tableName: 'users',
        devCount: 4,
        prodCount: 4,
        diff: 0,
        status: 'MATCH',
      ),
    ];

    const mockBackups = [
      LocalBackupEntry(
        filename: 'auto_pre_upgrade_20260908.db',
        filepath: '/backups/auto_pre_upgrade_20260908.db',
        sizeKb: 1024,
        mtime: '2026-09-08 12:00:00',
        tag: 'auto',
      ),
      LocalBackupEntry(
        filename: 'manual_backup_20260908.db',
        filepath: '/backups/manual_backup_20260908.db',
        sizeKb: 2048,
        mtime: '2026-09-08 14:00:00',
        tag: 'prod',
      ),
    ];

    testWidgets('exportTableDiffToTsv generates TSV with UTF-8 BOM and headers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));

      final tsv = ProductionSyncExportService.exportTableDiffToTsv(
        context: context,
        tables: mockTables,
      );

      expect(tsv.startsWith('\uFEFF'), isTrue, reason: 'Must include UTF-8 BOM');
      expect(tsv, contains('transport_locations'));
      expect(tsv, contains('cargo_insurance_certificates'));
      expect(tsv, contains('users'));
      expect(tsv, contains('\t'));
    });

    testWidgets('exportTableDiffToCsv generates clean CSV with UTF-8 BOM', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));

      final csv = ProductionSyncExportService.exportTableDiffToCsv(
        context: context,
        tables: mockTables,
      );

      expect(csv.startsWith('\uFEFF'), isTrue, reason: 'Must include UTF-8 BOM');
      expect(csv, contains('transport_locations'));
      expect(csv, contains(','));
    });

    testWidgets('exportBackupsToTsv generates TSV with UTF-8 BOM', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));

      final tsv = ProductionSyncExportService.exportBackupsToTsv(
        context: context,
        backups: mockBackups,
      );

      expect(tsv.startsWith('\uFEFF'), isTrue);
      expect(tsv, contains('auto_pre_upgrade_20260908.db'));
      expect(tsv, contains('manual_backup_20260908.db'));
    });

    testWidgets('buildSystemSyncDossier produces structured text report', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final BuildContext context = tester.element(find.byType(SizedBox));

      final dossier = ProductionSyncExportService.buildSystemSyncDossier(
        context: context,
        version: '1.0.53',
        buildNumber: 54,
        devStats: const LocalDbStats(exists: true, dbPath: '/test/dev.db', sizeKb: 1500, mtime: '2026-09-08'),
        prodStats: const LocalDbStats(exists: true, dbPath: '/test/prod.db', sizeKb: 1400, mtime: '2026-09-08'),
        diffSummary: const SyncDiffSummary(
          exists: true,
          targetExists: true,
          totalNewRecords: 15,
          tablesWithDiff: 2,
          tables: mockTables,
        ),
        backups: mockBackups,
      );

      expect(dossier, contains('1.0.53'));
      expect(dossier, contains('54'));
      expect(dossier, contains('transport_locations'));
      expect(dossier, contains('auto_pre_upgrade_20260908.db'));
    });
  });
}
