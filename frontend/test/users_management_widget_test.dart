import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/core/widgets/copyable_data_helper.dart';
import 'package:frontend/features/auth/models/rbac_models.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/rbac_provider.dart';
import 'package:frontend/features/auth/providers/users_provider.dart';
import 'package:frontend/features/auth/screens/users_management_screen.dart';

class _FakeUsersNotifier extends UsersNotifier {
  _FakeUsersNotifier() : super(Dio()) {
    state = UsersState(
      users: [
        UserDetail(
          userId: 1,
          username: 'admin',
          email: 'admin@sorour.com',
          fullName: 'Ahmed Salah Sorour',
          role: 'ADMIN',
          isActive: true,
          createdAt: '2026-01-15T10:00:00Z',
        ),
        UserDetail(
          userId: 2,
          username: 'logistics_mgr',
          email: 'mgr@sorour.com',
          fullName: 'Mohamed Ali',
          role: 'MANAGER',
          isActive: true,
          createdAt: '2026-02-01T12:00:00Z',
        ),
        UserDetail(
          userId: 3,
          username: 'operator1',
          email: 'op1@sorour.com',
          fullName: 'Mahmoud Hassan',
          role: 'OPERATOR',
          isActive: false,
          createdAt: '2026-03-01T08:30:00Z',
        ),
      ],
      isLoading: false,
    );
  }

  @override
  Future<void> fetchUsers() async {
    // Keep fake state intact
  }
}

class _FakeRbacNotifier extends RbacNotifier {
  _FakeRbacNotifier() : super(Dio()) {
    state = const RbacState(
      roles: [
        RoleModel(
          roleId: 1,
          roleCode: 'ADMIN',
          nameEn: 'Administrator',
          nameAr: 'مدير النظام',
          isSystemRole: true,
          isActive: true,
          permissions: ['users.read', 'users.write', 'roles.manage'],
        ),
        RoleModel(
          roleId: 2,
          roleCode: 'MANAGER',
          nameEn: 'Operations Manager',
          nameAr: 'مدير العمليات',
          isSystemRole: false,
          isActive: true,
          permissions: ['users.read'],
        ),
      ],
      permissionGroups: [
        PermissionModuleGroup(
          moduleName: 'AUTH',
          moduleNameAr: 'المستخدمين والأمان',
          permissions: [
            PermissionModel(
              permissionId: 1,
              permissionCode: 'users.read',
              moduleName: 'AUTH',
              action: 'READ',
              nameEn: 'View Users',
              nameAr: 'عرض المستخدمين',
            ),
            PermissionModel(
              permissionId: 2,
              permissionCode: 'users.write',
              moduleName: 'AUTH',
              action: 'WRITE',
              nameEn: 'Manage Users',
              nameAr: 'إدارة المستخدمين',
            ),
          ],
        ),
      ],
      isLoading: false,
    );
  }

  @override
  Future<void> fetchRbacData() async {
    // Keep fake state intact
  }

  @override
  Future<UserEffectivePermissions?> fetchUserPermissions(int userId) async {
    return const UserEffectivePermissions(
      userId: 1,
      username: 'admin',
      role: 'ADMIN',
      roleId: 1,
      roleCode: 'ADMIN',
      customGrants: ['audit.export'],
      customRevocations: [],
      effectivePermissions: ['users.read', 'users.write', 'audit.export'],
    );
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(Dio(), const FlutterSecureStorage()) {
    state = AuthState(
      isAuthenticated: true,
      user: UserModel(
        userId: 1,
        username: 'admin',
        email: 'admin@sorour.com',
        fullName: 'Ahmed Salah Sorour',
        role: 'ADMIN',
        isActive: true,
      ),
    );
  }
}

Widget _buildTestApp({Locale locale = const Locale('ar')}) {
  return ProviderScope(
    overrides: [
      usersProvider.overrideWith((ref) => _FakeUsersNotifier()),
      rbacProvider.overrideWith((ref) => _FakeRbacNotifier()),
      authProvider.overrideWith((ref) => _FakeAuthNotifier()),
      localeProvider.overrideWith((ref) {
        final n = LocaleNotifier();
        n.setLocale(locale);
        return n;
      }),
    ],
    child: MaterialApp(
      home: AppLocalizationsProvider(
        locale: locale,
        child: Directionality(
          textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: const UsersManagementScreen(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 66: UsersManagementScreen UI & Copy Features Tests', () {
    testWidgets('Renders root SelectionArea and export toolbar with 4 action buttons', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Root SelectionArea must exist
      expect(find.byType(SelectionArea), findsWidgets);

      // Export toolbar buttons must be visible
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget); // TSV
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);    // Excel
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget); // PDF
      expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);   // Dossier
    });

    testWidgets('Renders users table with CopyableTableCell instances and copy buttons', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Table contains CopyableTableCell wrappers
      expect(find.byType(CopyableTableCell), findsWidgets);

      // Usernames rendered
      expect(find.text('@admin'), findsOneWidget);
      expect(find.text('@logistics_mgr'), findsOneWidget);
      expect(find.text('@operator1'), findsOneWidget);

      // Quick row copy buttons (Icons.copy_rounded) present in row actions
      expect(find.byIcon(Icons.copy_rounded), findsWidgets);
    });

    testWidgets('Search field displays copy button when query is entered', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter query
      await tester.enterText(searchField, 'Ahmed');
      await tester.pumpAndSettle();

      // Clear icon and copy icon should be displayed in suffix
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsWidgets);
    });

    testWidgets('English locale renders correctly without errors', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // English titles and buttons
      expect(find.text('Export TSV'), findsOneWidget);
      expect(find.text('Export Excel'), findsOneWidget);
      expect(find.text('Print PDF'), findsOneWidget);
      expect(find.text('Copy Dossier'), findsOneWidget);
    });
  });
}
