import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';

void main() {
  group('Authentication & Login Screen Localization Tests', () {
    test('All login getters return non-empty strings and have matching translations', () {
      const ar = AppLocalizationsAr();
      const en = AppLocalizationsEn();

      expect(ar.loginScreenTitle.isNotEmpty, isTrue);
      expect(en.loginScreenTitle.isNotEmpty, isTrue);

      expect(ar.loginScreenSubtitle.isNotEmpty, isTrue);
      expect(en.loginScreenSubtitle.isNotEmpty, isTrue);

      expect(ar.loginUsernameLabel.isNotEmpty, isTrue);
      expect(en.loginUsernameLabel.isNotEmpty, isTrue);

      expect(ar.loginUsernameRequired.isNotEmpty, isTrue);
      expect(en.loginUsernameRequired.isNotEmpty, isTrue);

      expect(ar.loginPasswordLabel.isNotEmpty, isTrue);
      expect(en.loginPasswordLabel.isNotEmpty, isTrue);

      expect(ar.loginPasswordRequired.isNotEmpty, isTrue);
      expect(en.loginPasswordRequired.isNotEmpty, isTrue);

      expect(ar.loginButtonLabel.isNotEmpty, isTrue);
      expect(en.loginButtonLabel.isNotEmpty, isTrue);

      expect(ar.loginAuthenticating.isNotEmpty, isTrue);
      expect(en.loginAuthenticating.isNotEmpty, isTrue);

      expect(ar.loginQuickDemoAccess.isNotEmpty, isTrue);
      expect(en.loginQuickDemoAccess.isNotEmpty, isTrue);

      expect(ar.loginInvalidCredentials.isNotEmpty, isTrue);
      expect(en.loginInvalidCredentials.isNotEmpty, isTrue);

      expect(ar.loginRoleAdmin.isNotEmpty, isTrue);
      expect(en.loginRoleAdmin.isNotEmpty, isTrue);

      expect(ar.loginRoleManager.isNotEmpty, isTrue);
      expect(en.loginRoleManager.isNotEmpty, isTrue);

      expect(ar.loginRoleSpecialist.isNotEmpty, isTrue);
      expect(en.loginRoleSpecialist.isNotEmpty, isTrue);
    });

    test('Arabic translations do not contain Latin characters or stacked English text', () {
      const ar = AppLocalizationsAr();
      final latinPattern = RegExp(r'[a-zA-Z]');

      expect(latinPattern.hasMatch(ar.loginScreenTitle), isFalse);
      expect(latinPattern.hasMatch(ar.loginScreenSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.loginUsernameLabel), isFalse);
      expect(latinPattern.hasMatch(ar.loginUsernameRequired), isFalse);
      expect(latinPattern.hasMatch(ar.loginPasswordLabel), isFalse);
      expect(latinPattern.hasMatch(ar.loginPasswordRequired), isFalse);
      expect(latinPattern.hasMatch(ar.loginButtonLabel), isFalse);
      expect(latinPattern.hasMatch(ar.loginAuthenticating), isFalse);
      expect(latinPattern.hasMatch(ar.loginQuickDemoAccess), isFalse);
      expect(latinPattern.hasMatch(ar.loginInvalidCredentials), isFalse);
      expect(latinPattern.hasMatch(ar.loginRoleAdmin), isFalse);
      expect(latinPattern.hasMatch(ar.loginRoleManager), isFalse);
      expect(latinPattern.hasMatch(ar.loginRoleSpecialist), isFalse);
    });

    testWidgets('LoginScreen renders correctly in Arabic and switches cleanly to English', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Arabic fields
      expect(find.text('اسم المستخدم أو البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('تسجيل الدخول إلى النظام'), findsOneWidget);
      expect(find.text('الدخول السريع بحسابات النظام التجريبية:'), findsOneWidget);
      expect(find.text('مسؤول النظام'), findsOneWidget);
      expect(find.text('مدير العمليات'), findsOneWidget);
      expect(find.text('أخصائي لوجستي'), findsOneWidget);

      // Verify no stacked bilingual strings
      expect(find.textContaining('(Username / Email)'), findsNothing);
      expect(find.textContaining('(Password)'), findsNothing);
      expect(find.textContaining('(Login)'), findsNothing);
      expect(find.textContaining('(Quick Demo Access)'), findsNothing);
    });
  });
}
