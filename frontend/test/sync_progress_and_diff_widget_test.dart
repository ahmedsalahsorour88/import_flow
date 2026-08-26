import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/production_sync/services/local_process_sync_service.dart';
import 'package:frontend/features/production_sync/widgets/sync_progress_and_diff_widget.dart';

void main() {
  group('SyncProgressAndDiffWidget Tests', () {
    testWidgets('renders progress bar and completion percentage properly', (WidgetTester tester) async {
      const event = SyncProgressEvent(
        percent: 75,
        stage: 'syncing',
        table: 'cargo_insurance_certificates',
        currentIndex: 55,
        totalTables: 73,
        recordsSynced: 8,
        totalSynced: 1520,
        message: 'جارٍ فحص ومزامنة جدول: cargo_insurance_certificates (55/73)',
      );

      final diffSummary = SyncDiffSummary(
        exists: true,
        targetExists: true,
        totalNewRecords: 5,
        tablesWithDiff: 1,
        tables: const [
          SyncTableDiff(
            tableName: 'transport_locations',
            devCount: 261,
            prodCount: 256,
            diff: 5,
            status: 'NEW_DATA',
          ),
          SyncTableDiff(
            tableName: 'users',
            devCount: 4,
            prodCount: 4,
            diff: 0,
            status: 'MATCH',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SyncProgressAndDiffWidget(
                progress: event,
                diffSummary: diffSummary,
                isRunning: true,
                onCheckDiff: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check Percentage Text
      expect(find.text('75%'), findsOneWidget);
      // Check Table Name in Message
      expect(find.textContaining('cargo_insurance_certificates'), findsOneWidget);
      // Check LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Check Diff Table Name
      expect(find.text('transport_locations'), findsOneWidget);
      // Check +5 new records badge in summary chip and row
      expect(find.text('+5 سجل جديد سيضاف'), findsNWidgets(2));
    });

    testWidgets('allows searching for a specific table', (WidgetTester tester) async {
      final diffSummary = SyncDiffSummary(
        exists: true,
        targetExists: true,
        totalNewRecords: 12,
        tablesWithDiff: 2,
        tables: const [
          SyncTableDiff(
            tableName: 'cargo_shipping_records',
            devCount: 14,
            prodCount: 10,
            diff: 4,
            status: 'NEW_DATA',
          ),
          SyncTableDiff(
            tableName: 'customs_tariffs',
            devCount: 62,
            prodCount: 54,
            diff: 8,
            status: 'NEW_DATA',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SyncProgressAndDiffWidget(
                progress: null,
                diffSummary: diffSummary,
                isRunning: false,
                onCheckDiff: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('cargo_shipping_records'), findsOneWidget);
      expect(find.text('customs_tariffs'), findsOneWidget);

      // Search for tariffs
      await tester.enterText(find.byType(TextField), 'tariff');
      await tester.pump();

      expect(find.text('customs_tariffs'), findsOneWidget);
      expect(find.text('cargo_shipping_records'), findsNothing);
    });
  });
}
