import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/production_sync/models/production_sync_model.dart';

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
        'tables': [
          {
            'table_name': 'transport_locations',
            'dev_count': 54,
            'prod_count': 54,
            'diff': 0,
            'is_match': true,
            'status': 'متطابق (Matched)',
          },
          {
            'table_name': 'customs_tariffs',
            'dev_count': 12,
            'prod_count': 12,
            'diff': 0,
            'is_match': true,
            'status': 'متطابق (Matched)',
          }
        ]
      };

      final comp = SyncComparisonResponseModel.fromJson(json);
      expect(comp.isFullySynchronized, isTrue);
      expect(comp.matchedTablesCount, 66);
      expect(comp.differingTablesCount, 0);
      expect(comp.tables.length, 2);
      expect(comp.tables.first.tableName, 'transport_locations');
      expect(comp.tables.first.isMatch, isTrue);
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
  });
}
