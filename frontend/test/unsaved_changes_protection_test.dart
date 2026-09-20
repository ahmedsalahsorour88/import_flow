import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/unsaved_changes_guard.dart';
import 'package:frontend/core/widgets/unsaved_changes_dialog.dart';
import 'package:frontend/features/purchase_orders/services/po_draft_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PODraftManager Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Draft lifecycle: save, check, load, and clear', () async {
      const poId = 'PO-UNIT-TEST-100';

      // 1. Initial state: no draft
      expect(await PODraftManager.hasDraft(poId), isFalse);
      expect(await PODraftManager.loadDraft(poId), isNull);

      // 2. Save draft
      final testData = {
        'po_reference': 'PO-2026-TEST',
        'supplier_id': 42,
        'currency': 'USD',
        'exchange_rate': 49.5,
        'notes': 'Urgent import shipment',
      };
      await PODraftManager.saveDraft(poId: poId, draftData: Map<String, dynamic>.from(testData));

      // 3. Verify draft exists and contains metadata
      expect(await PODraftManager.hasDraft(poId), isTrue);
      final loaded = await PODraftManager.loadDraft(poId);
      expect(loaded, isNotNull);
      expect(loaded!['po_reference'], equals('PO-2026-TEST'));
      expect(loaded['exchange_rate'], equals(49.5));
      expect(loaded.containsKey('saved_at'), isTrue);

      // 4. Clear draft
      await PODraftManager.clearDraft(poId);
      expect(await PODraftManager.hasDraft(poId), isFalse);
      expect(await PODraftManager.loadDraft(poId), isNull);
    });

    test('New PO draft format key uses new identifier', () async {
      expect(await PODraftManager.hasDraft(null), isFalse);
      await PODraftManager.saveDraft(poId: null, draftData: {'po_reference': 'DRAFT-NEW'});
      expect(await PODraftManager.hasDraft(null), isTrue);
      final loaded = await PODraftManager.loadDraft(null);
      expect(loaded!['po_reference'], equals('DRAFT-NEW'));
      await PODraftManager.clearDraft(null);
      expect(await PODraftManager.hasDraft(null), isFalse);
    });
  });

  group('UnsavedChangesGuard & maybePop Widget Tests', () {
    Widget buildTestApp({
      required Widget child,
    }) {
      return AppLocalizationsProvider(
        locale: const Locale('ar'),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: child,
          ),
        ),
      );
    }

    testWidgets('maybePop with isDirty=false pops immediately without confirmation', (tester) async {
      bool dialogPopped = false;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => UnsavedChangesGuard(
                    isDirty: false,
                    child: AlertDialog(
                      title: const Text('نموذج نظيف'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            final didPop = await UnsavedChangesGuard.maybePop(ctx, isDirty: false);
                            if (didPop) dialogPopped = true;
                          },
                          child: const Text('إلغاء'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('فتح النموذج'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('فتح النموذج'));
      await tester.pumpAndSettle();
      expect(find.text('نموذج نظيف'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Verify it popped immediately and NO UnsavedChangesDialog appeared
      expect(find.text('نموذج نظيف'), findsNothing);
      expect(find.byType(UnsavedChangesDialog), findsNothing);
      expect(dialogPopped, isTrue);
    });

    testWidgets('maybePop with isDirty=true intercepts close and displays UnsavedChangesDialog', (tester) async {
      bool discardCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => UnsavedChangesGuard(
                    isDirty: true,
                    onDiscard: () => discardCalled = true,
                    child: AlertDialog(
                      title: const Text('نموذج به تعديلات غير محفوظة'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await UnsavedChangesGuard.maybePop(
                              ctx,
                              isDirty: true,
                              onDiscard: () => discardCalled = true,
                            );
                          },
                          child: const Text('إلغاء'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('فتح النموذج المعدل'),
            ),
          ),
        ),
      );

      // Open dirty dialog
      await tester.tap(find.text('فتح النموذج المعدل'));
      await tester.pumpAndSettle();
      expect(find.text('نموذج به تعديلات غير محفوظة'), findsOneWidget);

      // Tap cancel on the form
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Verify that UnsavedChangesDialog appeared and original dialog is STILL on screen
      expect(find.byType(UnsavedChangesDialog), findsOneWidget);
      expect(find.text('نموذج به تعديلات غير محفوظة'), findsOneWidget);

      // Tap discard button ('تجاهل التعديلات والمتابعة')
      final discardBtn = find.text('تجاهل التعديلات والمتابعة');
      expect(discardBtn, findsOneWidget);
      await tester.tap(discardBtn);
      await tester.pumpAndSettle();

      // Verify both dialogs are now closed and discard callback fired
      expect(find.byType(UnsavedChangesDialog), findsNothing);
      expect(find.text('نموذج به تعديلات غير محفوظة'), findsNothing);
      expect(discardCalled, isTrue);
    });

    testWidgets('maybePop with isDirty=true: tapping "البقاء في الشاشة" keeps form open', (tester) async {
      bool discardCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => UnsavedChangesGuard(
                    isDirty: true,
                    onDiscard: () => discardCalled = true,
                    child: AlertDialog(
                      title: const Text('نموذج بيانات مهمة'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await UnsavedChangesGuard.maybePop(
                              ctx,
                              isDirty: true,
                              onDiscard: () => discardCalled = true,
                            );
                          },
                          child: const Text('إلغاء'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('فتح النموذج'),
            ),
          ),
        ),
      );

      // Open dirty dialog
      await tester.tap(find.text('فتح النموذج'));
      await tester.pumpAndSettle();
      expect(find.text('نموذج بيانات مهمة'), findsOneWidget);

      // Tap cancel on the form
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Verify that UnsavedChangesDialog appeared
      expect(find.byType(UnsavedChangesDialog), findsOneWidget);

      // Tap 'البقاء في الشاشة'
      final stayBtn = find.text('البقاء في الشاشة');
      expect(stayBtn, findsOneWidget);
      await tester.tap(stayBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog is closed, but the form dialog remains OPEN!
      expect(find.byType(UnsavedChangesDialog), findsNothing);
      expect(find.text('نموذج بيانات مهمة'), findsOneWidget);
      expect(discardCalled, isFalse);
    });
  });
}
