import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/production_sync/models/production_sync_model.dart';
import 'package:frontend/features/production_sync/services/local_process_sync_service.dart';

void main() {
  group('ProductionSyncModel Unit Tests', () {
    test('DatabaseStatsModel fromJson should parse correctly', () {
      final json = {
        'exists': true,
        'path': 'C:/ImportFlow/sorour_logistics.db',
        'size_kb': 1588.0,
        'tables_count': 66,
        'total_records': 379,
        'mtime': '2026-08-22 23:45:00',
      };
      final stats = DatabaseStatsModel.fromJson(json);
      expect(stats.exists, isTrue);
      expect(stats.tablesCount, 66);
      expect(stats.totalRecords, 379);
      expect(stats.sizeKb, 1588.0);
    });

    test('SyncComparisonResponseModel should evaluate isFullySynchronized correctly', () {
      final json = {
        'dev_stats': {
          'exists': true,
          'size_kb': 1600.0,
          'tables_count': 66,
          'total_records': 379,
        },
        'prod_stats': {
          'exists': true,
          'size_kb': 1600.0,
          'tables_count': 66,
          'total_records': 379,
        },
        'is_fully_synchronized': true,
        'total_tables': 66,
        'matched_tables_count': 66,
        'differing_tables_count': 0,
        'schema_diffs_count': 0,
        'tables': [
          {
            'table_name': 'transport_locations',
            'dev_count': 54,
            'prod_count': 54,
            'diff': 0,
            'is_match': true,
            'status': 'متطابق (Matched)',
            'dev_columns_count': 10,
            'prod_columns_count': 10,
            'new_columns': [],
            'is_new_table': false,
            'has_schema_diff': false,
            'needs_sync': false,
          },
          {
            'table_name': 'customs_tariffs',
            'dev_count': 12,
            'prod_count': 12,
            'diff': 0,
            'is_match': true,
            'status': 'متطابق (Matched)',
            'dev_columns_count': 8,
            'prod_columns_count': 8,
            'new_columns': [],
            'is_new_table': false,
            'has_schema_diff': false,
            'needs_sync': false,
          }
        ]
      };

      final comp = SyncComparisonResponseModel.fromJson(json);
      expect(comp.isFullySynchronized, isTrue);
      expect(comp.matchedTablesCount, 66);
      expect(comp.differingTablesCount, 0);
      expect(comp.schemaDiffsCount, 0);
      expect(comp.tables.length, 2);
      expect(comp.tables.first.tableName, 'transport_locations');
      expect(comp.tables.first.isMatch, isTrue);
      expect(comp.tables.first.hasSchemaDiff, isFalse);
    });

    test('TableComparisonItemModel parses schema diff fields correctly', () {
      final json = {
        'table_name': 'import_files',
        'dev_count': 5,
        'prod_count': 5,
        'diff': 0,
        'is_match': false,
        'status': 'ترقية Schema (2 عمود جديد: acid_number, acid_expiry_date)',
        'dev_columns_count': 22,
        'prod_columns_count': 20,
        'new_columns': ['acid_number', 'acid_expiry_date'],
        'is_new_table': false,
        'has_schema_diff': true,
        'needs_sync': true,
      };

      final item = TableComparisonItemModel.fromJson(json);
      expect(item.tableName, 'import_files');
      expect(item.isMatch, isFalse);
      expect(item.hasSchemaDiff, isTrue);
      expect(item.isNewTable, isFalse);
      expect(item.needsSync, isTrue);
      expect(item.newColumns, containsAll(['acid_number', 'acid_expiry_date']));
      expect(item.devColumnsCount, 22);
      expect(item.prodColumnsCount, 20);
    });

    test('TableComparisonItemModel parses new_table flag correctly', () {
      final json = {
        'table_name': 'acid_validity_logs',
        'dev_count': 0,
        'prod_count': 0,
        'diff': 0,
        'is_match': false,
        'status': 'جدول جديد (New Table)',
        'dev_columns_count': 5,
        'prod_columns_count': 0,
        'new_columns': [],
        'is_new_table': true,
        'has_schema_diff': true,
        'needs_sync': true,
      };

      final item = TableComparisonItemModel.fromJson(json);
      expect(item.isNewTable, isTrue);
      expect(item.hasSchemaDiff, isTrue);
      expect(item.needsSync, isTrue);
      expect(item.isMatch, isFalse);
    });

    test('SyncActionResponseModel fromJson should parse action and message', () {
      final json = {
        'success': true,
        'action': 'PUSH_TO_PROD',
        'message': 'تمت مزامنة وتحديث قاعدة بيانات البرودكشن بنجاح تام!',
        'timestamp': '2026-08-22 23:45:00',
        'backup_file': 'sorour_logistics_prod_backup.db',
        'affected_tables_count': 66,
        'total_records_synced': 379,
      };

      final res = SyncActionResponseModel.fromJson(json);
      expect(res.success, isTrue);
      expect(res.action, 'PUSH_TO_PROD');
      expect(res.affectedTablesCount, 66);
      expect(res.totalRecordsSynced, 379);
    });

    test('LocalProcessSyncService retrieves db stats directly from filesystem', () {
      final service = LocalProcessSyncService();
      final stats = service.getDbStats(service.devDbPath);
      expect(stats.exists, isTrue);
      expect(stats.sizeKb, greaterThan(0));
      expect(stats.mtime, isNotNull);

      final backups = service.listBackups();
      expect(backups, isA<List<LocalBackupEntry>>());
    });
  });
}
