import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/home/home_screen.dart';
import 'package:frontend/main.dart';

void main() {
  group('AuthGate Reactive Navigation Tests', () {
    testWidgets('AuthGate renders LoginScreen when unauthenticated', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _MockAuthNotifier(const AuthState(isAuthenticated: false))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: AuthGate(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('AuthGate switches to HomeScreen dynamically when authenticated', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockNotifier = _MockAuthNotifier(const AuthState(isAuthenticated: false));
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => mockNotifier),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: AuthGate(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      // Now authenticate
      mockNotifier.setAuthenticated(true);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.initialState);

  void setAuthenticated(bool isAuth) {
    state = state.copyWith(
      isAuthenticated: isAuth,
      user: isAuth
          ? UserModel(
              userId: 1,
              username: 'admin',
              email: 'admin@sorourlogistics.com',
              fullName: 'System Admin',
              role: 'ADMIN',
              isActive: true,
            )
          : null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
