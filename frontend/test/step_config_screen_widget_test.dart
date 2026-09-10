import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/copyable_data_helper.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/lifecycle_board/models/step_config_model.dart';
import 'package:frontend/features/lifecycle_board/providers/step_config_provider.dart';
import 'package:frontend/features/lifecycle_board/screens/step_config_management_screen.dart';

final mockOperator = UserModel(
  userId: 10,
  username: 'operator_samir',
  email: 'samir@importflow.com',
  fullName: 'Samir Logistics Operator',
  role: 'OPERATOR',
  isActive: true,
);

final mockManager = UserModel(
  userId: 1,
  username: 'manager_ahmed',
  email: 'manager@importflow.com',
  fullName: 'Ahmed General Manager',
  role: 'MANAGER',
  isActive: true,
);

final mockConfigs = [
  const StepConfigModel(
    id: 1,
    stepCode: 'STEP_01',
    stepNameAr: 'تسجيل الفاتورة المبدئية',
    stepNameEn: 'Proforma Invoice Registration',
    phaseId: 1,
    skipPolicy: 'blocked',
    supportsPendingReference: false,
  ),
  const StepConfigModel(
    id: 6,
    stepCode: 'STEP_06',
    stepNameAr: 'فحص وتجهيز البضاعة والشحن',
    stepNameEn: 'Cargo Inspection & Shipping Loading',
    phaseId: 2,
    skipPolicy: 'single_approval',
    supportsPendingReference: true,
    approverRoles: ['Manager'],
    reasonCategories: ['Regulatory Exemption', 'Client Waived'],
  ),
];

Widget _buildTestApp({Locale locale = const Locale('ar'), bool isManager = true}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _MockAuthNotifier(
            AuthState(user: isManager ? mockManager : mockOperator, isAuthenticated: true),
          )),
      stepConfigProvider.overrideWith((ref) => _MockStepConfigNotifier(
            StepConfigState(configs: mockConfigs, isLoading: false),
          )),
    ],
    child: MaterialApp(
      home: AppLocalizationsProvider(
        locale: locale,
        child: Directionality(
          textDirection:
              locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: const StepConfigManagementScreen(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Non-manager (OPERATOR) sees Access Denied screen wrapped in SelectionArea',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(locale: const Locale('ar'), isManager: false));
    await tester.pumpAndSettle();

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.textContaining('صلاحية غير كافية'), findsOneWidget);
    expect(find.textContaining('هذه الشاشة متاحة حصرياً للمدير المعتمد'),
        findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
  });

  testWidgets(
      'Manager sees authorized table with SelectionArea, 4 exports, and CopyableTableCell',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(locale: const Locale('ar'), isManager: true));
    await tester.pumpAndSettle();

    // Verify SelectionArea exists
    expect(find.byType(SelectionArea), findsAtLeastNWidgets(1));

    // Verify header and table items
    expect(find.textContaining('إعدادات تصنيف مخاطر المراحل وحوكمة التخطي'),
        findsOneWidget);
    expect(find.text('STEP_01'), findsOneWidget);
    expect(find.text('تسجيل الفاتورة المبدئية'), findsOneWidget);
    expect(find.text('STEP_06'), findsOneWidget);
    expect(find.text('فحص وتجهيز البضاعة والشحن'), findsOneWidget);

    // Verify 4-action export toolbar buttons
    expect(find.byIcon(Icons.table_view_rounded), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    expect(find.byIcon(Icons.copy_all_rounded), findsOneWidget);

    // Verify search bar and refresh button
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // Verify CopyableTableCell presence
    expect(find.byType(CopyableTableCell), findsWidgets);

    // Tap on row copy button
    final rowCopyButtons = find.byIcon(Icons.copy_rounded);
    expect(rowCopyButtons, findsWidgets);

    // Tap on edit button for STEP_06
    final editButtons = find.byIcon(Icons.edit_note_rounded);
    expect(editButtons, findsNWidgets(2));
    await tester.ensureVisible(editButtons.at(1));
    await tester.tap(editButtons.at(1));
    await tester.pumpAndSettle();

    // Verify Edit Dialog opened with pure Arabic fields
    expect(find.textContaining('تعديل سياسة الخطوة: STEP_06'), findsOneWidget);
    expect(find.textContaining('السبب التبريري للتعديل'), findsOneWidget);
    expect(find.text('تسجيل مرجع معلق مبكر'), findsOneWidget);

    // Try submitting without justification: validation error must appear
    final saveButton = find.text('حفظ التعديل وتوثيق السجل');
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('يجب إدخال سبب تبريري لا يقل عن 5 أحرف'),
        findsOneWidget);
  });

  testWidgets('Renders properly in English mode with LTR Directionality',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(locale: const Locale('en'), isManager: true));
    await tester.pumpAndSettle();

    // Verify English header
    expect(
        find.text('Lifecycle Steps Risk Classification & Skip Governance'),
        findsOneWidget);
    // Verify English step names
    expect(find.text('Proforma Invoice Registration'), findsOneWidget);
    expect(find.text('Cargo Inspection & Shipping Loading'), findsOneWidget);
    // Verify English export buttons
    expect(find.text('Export TSV'), findsOneWidget);
    expect(find.text('Export Excel'), findsOneWidget);
    expect(find.text('Vector PDF'), findsOneWidget);
    expect(find.text('Copy Dossier'), findsOneWidget);
  });
}

class _MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStepConfigNotifier extends StateNotifier<StepConfigState>
    implements StepConfigNotifier {
  _MockStepConfigNotifier(super.state);

  @override
  Future<void> fetchConfigs() async {}

  @override
  void setSearchQuery(String q) {}

  @override
  void setFilterPhase(int? p) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
