import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide ErrorFormatter;
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/widgets/error_details_dialog.dart';

void main() {
  group('Error Details Dialog Localization (i18n) Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All error dialog getters in AppLocalizationsAr & AppLocalizationsEn are non-empty and valid', () {
      final gettersAr = [
        ar.errorDefaultSummary,
        ar.errorDialogDefaultSubtitle,
        ar.errorServerResponseField,
        ar.errorServerResponseRecommendation,
        ar.errorValidationSummary,
        ar.errorUnspecifiedField,
        ar.errorInvalidValue,
        ar.errorStandardRecommendation,
        ar.errorFieldRequiredMsg,
        ar.errorFieldRequiredRec,
        ar.errorValidDateMsg,
        ar.errorValidDateRec,
        ar.errorMinLengthMsg,
        ar.errorMinLengthRec,
        ar.errorConnectionSummary,
        ar.errorConnectionPointUnavailable,
        ar.errorConnectionPointTarget('http://test-api:8000'),
        ar.errorConnectionPointCors,
        ar.errorConnectionFieldName,
        ar.errorConnectionIssueDesc('http://test-api:8000', 'Failed to connect'),
        ar.errorConnectionRecommendation,
        ar.errorTimeoutSummary,
        ar.errorTimeoutPoint,
        ar.errorTimeoutFieldName,
        ar.errorTimeoutIssueDesc,
        ar.errorTimeoutRecommendation,
        ar.errorConnectionBannerHint,
        ar.errorTableSectionTitle(3),
        ar.errorColFieldCondition,
        ar.errorColDescription,
        ar.errorColAction,
        ar.errorBtnHideTechnicalLog,
        ar.errorBtnShowTechnicalLog,
        ar.errorBtnCopyReport,
        ar.errorReportHeader,
        ar.errorReportDateTime,
        ar.errorReportTitle,
        ar.errorReportSummary,
        ar.errorReportType,
        ar.errorReportTypeConnection,
        ar.errorReportTypeValidation,
        ar.errorReportIssues(3),
        ar.errorReportRawLog,
        ar.errorReportCopiedSnackBar,
        ar.errorBtnRetrying,
        ar.errorBtnRetryNow,
        ar.errorRetryFailedSnackBar('Timeout'),
        ar.errorBtnFixAndClose,
      ];

      final gettersEn = [
        en.errorDefaultSummary,
        en.errorDialogDefaultSubtitle,
        en.errorServerResponseField,
        en.errorServerResponseRecommendation,
        en.errorValidationSummary,
        en.errorUnspecifiedField,
        en.errorInvalidValue,
        en.errorStandardRecommendation,
        en.errorFieldRequiredMsg,
        en.errorFieldRequiredRec,
        en.errorValidDateMsg,
        en.errorValidDateRec,
        en.errorMinLengthMsg,
        en.errorMinLengthRec,
        en.errorConnectionSummary,
        en.errorConnectionPointUnavailable,
        en.errorConnectionPointTarget('http://test-api:8000'),
        en.errorConnectionPointCors,
        en.errorConnectionFieldName,
        en.errorConnectionIssueDesc('http://test-api:8000', 'Failed to connect'),
        en.errorConnectionRecommendation,
        en.errorTimeoutSummary,
        en.errorTimeoutPoint,
        en.errorTimeoutFieldName,
        en.errorTimeoutIssueDesc,
        en.errorTimeoutRecommendation,
        en.errorConnectionBannerHint,
        en.errorTableSectionTitle(3),
        en.errorColFieldCondition,
        en.errorColDescription,
        en.errorColAction,
        en.errorBtnHideTechnicalLog,
        en.errorBtnShowTechnicalLog,
        en.errorBtnCopyReport,
        en.errorReportHeader,
        en.errorReportDateTime,
        en.errorReportTitle,
        en.errorReportSummary,
        en.errorReportType,
        en.errorReportTypeConnection,
        en.errorReportTypeValidation,
        en.errorReportIssues(3),
        en.errorReportRawLog,
        en.errorReportCopiedSnackBar,
        en.errorBtnRetrying,
        en.errorBtnRetryNow,
        en.errorRetryFailedSnackBar('Timeout'),
        en.errorBtnFixAndClose,
      ];

      for (var s in gettersAr) {
        expect(s.trim().isNotEmpty, isTrue, reason: 'Arabic getter was empty');
      }
      for (var s in gettersEn) {
        expect(s.trim().isNotEmpty, isTrue, reason: 'English getter was empty');
      }
    });

    test('AppLocalizationsAr has ZERO stacked English words or acronyms', () {
      final stackedPatterns = [
        '(PO)',
        '(POL)',
        '(POD)',
        '(CRD)',
        '(Retry)',
        '(Fix & Retry)',
        '(Validation Errors)',
        '(Diagnostic Log)',
        '(Connection Timeout)',
        '(Backend Server)',
        '(Backend API Connection Error / CORS)',
        '(FastAPI)',
      ];

      final allArStrings = [
        ar.errorDefaultSummary,
        ar.errorDialogDefaultSubtitle,
        ar.errorServerResponseField,
        ar.errorServerResponseRecommendation,
        ar.errorValidationSummary,
        ar.errorUnspecifiedField,
        ar.errorInvalidValue,
        ar.errorStandardRecommendation,
        ar.errorFieldRequiredMsg,
        ar.errorFieldRequiredRec,
        ar.errorValidDateMsg,
        ar.errorValidDateRec,
        ar.errorMinLengthMsg,
        ar.errorMinLengthRec,
        ar.errorConnectionSummary,
        ar.errorConnectionPointUnavailable,
        ar.errorConnectionPointCors,
        ar.errorConnectionFieldName,
        ar.errorConnectionRecommendation,
        ar.errorTimeoutSummary,
        ar.errorTimeoutPoint,
        ar.errorTimeoutFieldName,
        ar.errorTimeoutIssueDesc,
        ar.errorTimeoutRecommendation,
        ar.errorConnectionBannerHint,
        ar.errorTableSectionTitle(2),
        ar.errorColFieldCondition,
        ar.errorColDescription,
        ar.errorColAction,
        ar.errorBtnHideTechnicalLog,
        ar.errorBtnShowTechnicalLog,
        ar.errorBtnCopyReport,
        ar.errorReportTypeConnection,
        ar.errorReportTypeValidation,
        ar.errorReportIssues(2),
        ar.errorReportRawLog,
        ar.errorReportCopiedSnackBar,
        ar.errorBtnRetrying,
        ar.errorBtnRetryNow,
        ar.errorBtnFixAndClose,
      ];

      for (var str in allArStrings) {
        for (var pattern in stackedPatterns) {
          expect(str, isNot(contains(pattern)),
              reason: 'Arabic string "$str" contains stacked pattern "$pattern"');
        }
      }
    });

    test('AppLocalizationsEn has ZERO Arabic characters in static UI text', () {
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      final allEnStrings = [
        en.errorDefaultSummary,
        en.errorDialogDefaultSubtitle,
        en.errorServerResponseField,
        en.errorServerResponseRecommendation,
        en.errorValidationSummary,
        en.errorUnspecifiedField,
        en.errorInvalidValue,
        en.errorStandardRecommendation,
        en.errorFieldRequiredMsg,
        en.errorFieldRequiredRec,
        en.errorValidDateMsg,
        en.errorValidDateRec,
        en.errorMinLengthMsg,
        en.errorMinLengthRec,
        en.errorConnectionSummary,
        en.errorConnectionPointUnavailable,
        en.errorConnectionPointCors,
        en.errorConnectionFieldName,
        en.errorConnectionRecommendation,
        en.errorTimeoutSummary,
        en.errorTimeoutPoint,
        en.errorTimeoutFieldName,
        en.errorTimeoutIssueDesc,
        en.errorTimeoutRecommendation,
        en.errorConnectionBannerHint,
        en.errorTableSectionTitle(5),
        en.errorColFieldCondition,
        en.errorColDescription,
        en.errorColAction,
        en.errorBtnHideTechnicalLog,
        en.errorBtnShowTechnicalLog,
        en.errorBtnCopyReport,
        en.errorReportTypeConnection,
        en.errorReportTypeValidation,
        en.errorReportIssues(5),
        en.errorReportRawLog,
        en.errorReportCopiedSnackBar,
        en.errorBtnRetrying,
        en.errorBtnRetryNow,
        en.errorBtnFixAndClose,
      ];

      for (var str in allEnStrings) {
        expect(arabicRegex.hasMatch(str), isFalse,
            reason: 'English string "$str" contains Arabic characters');
      }
    });

    test('errorFieldName maps all 32 known keys accurately in Arabic and English without stacked text', () {
      const keys = [
        'importer_name',
        'importer_tax_id',
        'importer_address',
        'exporter_name',
        'exporter_reg_type',
        'exporter_reg_id',
        'exporter_country',
        'exporter_country_code',
        'exporter_address',
        'exporter_phone',
        'cargox_id',
        'proforma_invoice_no',
        'proforma_invoice_date',
        'invoice_date',
        'invoice_type',
        'po_number',
        'po_date',
        'pol_name',
        'pod_name',
        'customs_broker_name',
        'customs_broker_id',
        'customs_broker_phone',
        'requested_date',
        'acid_number',
        'generated_date',
        'expiry_date',
        'items',
        'cargo_ready_date',
        'title',
        'consultation_title',
        'amount',
        'currency',
      ];

      final arabicRegex = RegExp(r'[\u0600-\u06FF]');

      for (var key in keys) {
        final arVal = ar.errorFieldName(key);
        final enVal = en.errorFieldName(key);

        expect(arVal, isNotEmpty);
        expect(enVal, isNotEmpty);
        expect(arVal, isNot(equals(key)), reason: 'Arabic key $key unmapped');
        expect(enVal, isNot(equals(key)), reason: 'English key $key unmapped');

        // Check no stacked acronyms in Arabic
        expect(arVal, isNot(contains('(PO)')));
        expect(arVal, isNot(contains('(POL)')));
        expect(arVal, isNot(contains('(POD)')));
        expect(arVal, isNot(contains('(CRD)')));

        // Check English has no Arabic characters
        expect(arabicRegex.hasMatch(enVal), isFalse,
            reason: 'English translation for $key has Arabic text: $enVal');
      }

      // Fallback for unknown key
      expect(ar.errorFieldName('unknown_random_field'), equals('unknown_random_field'));
      expect(en.errorFieldName('unknown_random_field'), equals('unknown_random_field'));
    });

    test('ErrorFormatter.parse correctly localizes validation issues in Arabic and English', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/shipments'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/shipments'),
          data: {
            'detail': [
              {
                'loc': ['body', 'po_number'],
                'msg': 'Field required',
              },
              {
                'loc': ['body', 'cargo_ready_date'],
                'msg': 'ensure this value is a valid date',
              },
            ],
          },
        ),
      );

      // Parse with Arabic
      final parsedAr = ErrorFormatter.parse(dioException, l10n: ar);
      expect(parsedAr.summary, equals(ar.errorValidationSummary));
      expect(parsedAr.validationIssues.length, equals(2));
      expect(parsedAr.validationIssues[0].fieldName, equals(ar.errorFieldName('po_number')));
      expect(parsedAr.validationIssues[0].issueDescription, equals(ar.errorFieldRequiredMsg));
      expect(parsedAr.validationIssues[0].recommendation, equals(ar.errorFieldRequiredRec));
      expect(parsedAr.validationIssues[1].fieldName, equals(ar.errorFieldName('cargo_ready_date')));
      expect(parsedAr.validationIssues[1].issueDescription, equals(ar.errorValidDateMsg));

      // Parse with English
      final parsedEn = ErrorFormatter.parse(dioException, l10n: en);
      expect(parsedEn.summary, equals(en.errorValidationSummary));
      expect(parsedEn.validationIssues.length, equals(2));
      expect(parsedEn.validationIssues[0].fieldName, equals(en.errorFieldName('po_number')));
      expect(parsedEn.validationIssues[0].issueDescription, equals(en.errorFieldRequiredMsg));
      expect(parsedEn.validationIssues[0].recommendation, equals(en.errorFieldRequiredRec));
      expect(parsedEn.validationIssues[1].fieldName, equals(en.errorFieldName('cargo_ready_date')));
      expect(parsedEn.validationIssues[1].issueDescription, equals(en.errorValidDateMsg));
    });

    test('ErrorFormatter.parse correctly localizes connection and timeout errors', () {
      final connError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/test', baseUrl: 'http://localhost:8000'),
        type: DioExceptionType.connectionError,
        message: 'connection error',
      );

      final parsedArConn = ErrorFormatter.parse(connError, l10n: ar);
      expect(parsedArConn.isConnectionError, isTrue);
      expect(parsedArConn.summary, equals(ar.errorConnectionSummary));
      expect(parsedArConn.validationIssues.first.fieldName, equals(ar.errorConnectionFieldName));

      final parsedEnConn = ErrorFormatter.parse(connError, l10n: en);
      expect(parsedEnConn.isConnectionError, isTrue);
      expect(parsedEnConn.summary, equals(en.errorConnectionSummary));
      expect(parsedEnConn.validationIssues.first.fieldName, equals(en.errorConnectionFieldName));

      final timeoutError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final parsedArTimeout = ErrorFormatter.parse(timeoutError, l10n: ar);
      expect(parsedArTimeout.summary, equals(ar.errorTimeoutSummary));
      expect(parsedArTimeout.validationIssues.first.fieldName, equals(ar.errorTimeoutFieldName));

      final parsedEnTimeout = ErrorFormatter.parse(timeoutError, l10n: en);
      expect(parsedEnTimeout.summary, equals(en.errorTimeoutSummary));
      expect(parsedEnTimeout.validationIssues.first.fieldName, equals(en.errorTimeoutFieldName));
    });

    testWidgets('showErrorDetailsDialog renders pure Arabic without stacked text', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customIssues = [
        ValidationIssueItem(
          fieldName: ar.errorFieldName('po_number'),
          issueDescription: ar.errorFieldRequiredMsg,
          recommendation: ar.errorFieldRequiredRec,
          isBlocking: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showErrorDetailsDialog(
                        context,
                        title: ar.errorDefaultSummary,
                        error: 'Custom test error',
                        validationIssues: customIssues,
                        onRetry: () async {},
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify title & table headers in Arabic
      expect(find.text(ar.errorDefaultSummary), findsAtLeastNWidgets(1));
      expect(find.text(ar.errorColFieldCondition), findsOneWidget);
      expect(find.text(ar.errorColDescription), findsOneWidget);
      expect(find.text(ar.errorColAction), findsOneWidget);

      // Verify buttons in pure Arabic
      expect(find.text(ar.errorBtnRetryNow), findsOneWidget);
      expect(find.text(ar.errorBtnFixAndClose), findsOneWidget);
      expect(find.text(ar.errorBtnShowTechnicalLog), findsOneWidget);
      expect(find.text(ar.errorBtnCopyReport), findsOneWidget);

      // Verify absence of stacked text
      expect(find.textContaining('(Retry)'), findsNothing);
      expect(find.textContaining('(Fix & Retry)'), findsNothing);
      expect(find.textContaining('(Diagnostic Log)'), findsNothing);
      expect(find.textContaining('(PO)'), findsNothing);
    });

    testWidgets('showErrorDetailsDialog renders pure English without Arabic text', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customIssues = [
        ValidationIssueItem(
          fieldName: en.errorFieldName('po_number'),
          issueDescription: en.errorFieldRequiredMsg,
          recommendation: en.errorFieldRequiredRec,
          isBlocking: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('en'),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showErrorDetailsDialog(
                        context,
                        title: en.errorDefaultSummary,
                        error: 'Custom test error',
                        validationIssues: customIssues,
                        onRetry: () async {},
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify title & table headers in English
      expect(find.text(en.errorDefaultSummary), findsAtLeastNWidgets(1));
      expect(find.text(en.errorColFieldCondition), findsOneWidget);
      expect(find.text(en.errorColDescription), findsOneWidget);
      expect(find.text(en.errorColAction), findsOneWidget);

      // Verify buttons in pure English
      expect(find.text(en.errorBtnRetryNow), findsOneWidget);
      expect(find.text(en.errorBtnFixAndClose), findsOneWidget);
      expect(find.text(en.errorBtnShowTechnicalLog), findsOneWidget);
      expect(find.text(en.errorBtnCopyReport), findsOneWidget);

      // Verify absence of Arabic characters in the UI
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      for (final textWidget in tester.widgetList<Text>(find.byType(Text))) {
        final data = textWidget.data;
        if (data != null) {
          expect(arabicRegex.hasMatch(data), isFalse,
              reason: 'Found unexpected Arabic text in English dialog: "$data"');
        }
      }
    });
  });
}