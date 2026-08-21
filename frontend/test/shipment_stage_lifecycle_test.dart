import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/shipment_stage_lifecycle_control.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

void main() {
  testWidgets('ShipmentStageLifecycleControl displays hold button when shipment is active', (tester) async {
    final activeFile = ImportFileModel(
      importFileId: 101,
      importFileCode: 'IMP-2026-0101',
      customFileNumber: '6701068100',
      companyName: 'Egyptian Import Co',
      supplierName: 'ABC China',
      currentModule: 'Phase 3 - Draft B/L Review',
      currentStage: 'مراجعة وتدقيق مسودات مستندات الشحن',
      nextAction: 'مراجعة درافت بوليصة الشحن',
      status: 'Open',
      createdAt: '2026-08-21',
      updatedAt: '2026-08-21',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => MockImportFilesNotifier([activeFile])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ShipmentStageLifecycleControl(
              importFileId: 101,
              stageName: 'مراجعة وتدقيق مسودات مستندات الشحن',
              stageCode: 'STEP-09',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('إيقاف الشحنة عند هذه المرحلة'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
  });

  testWidgets('ShipmentStageLifecycleControl displays resume button when shipment is On Hold', (tester) async {
    final heldFile = ImportFileModel(
      importFileId: 102,
      importFileCode: 'IMP-2026-0102',
      customFileNumber: '6701068102',
      companyName: 'Egyptian Import Co',
      supplierName: 'ABC China',
      currentModule: 'Phase 3 - Draft B/L Review',
      currentStage: 'مراجعة وتدقيق مسودات مستندات الشحن',
      nextAction: 'مراجعة درافت بوليصة الشحن',
      status: 'On Hold',
      pausedAtStage: 'مراجعة وتدقيق مسودات مستندات الشحن',
      holdReason: 'في انتظار رد المورد على تعديل المانيفست',
      createdAt: '2026-08-21',
      updatedAt: '2026-08-21',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => MockImportFilesNotifier([heldFile])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ShipmentStageLifecycleControl(
              importFileId: 102,
              stageName: 'مراجعة وتدقيق مسودات مستندات الشحن',
              stageCode: 'STEP-09',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('استكمال الشحنة'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.textContaining('متوقفة:'), findsOneWidget);
  });
}

class MockImportFilesNotifier extends StateNotifier<AsyncValue<List<ImportFileModel>>> implements ImportFilesNotifier {
  MockImportFilesNotifier(List<ImportFileModel> initial) : super(AsyncValue.data(initial));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
