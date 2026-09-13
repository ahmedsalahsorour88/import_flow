import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/smart_tasks/models/email_settings_model.dart';
import 'package:frontend/features/smart_tasks/widgets/email_settings_dialog.dart';
import 'package:frontend/features/smart_tasks/widgets/email_sync_review_dialog.dart';

void main() {
  group('Email Settings Models Unit Tests (INT-EMAIL-010)', () {
    test('Should parse EmailSettingsModel from JSON correctly', () {
      final json = {
        'settings_id': 1,
        'provider_type': 'GMAIL',
        'email_address': 'operations@sorourlogistics.com',
        'username': 'operations@sorourlogistics.com',
        'imap_host': 'imap.gmail.com',
        'imap_port': 993,
        'imap_use_ssl': true,
        'smtp_host': 'smtp.gmail.com',
        'smtp_port': 587,
        'smtp_use_tls': true,
        'smtp_use_ssl': false,
        'sender_display_name': 'Sorour Logistics Operations',
        'auto_fetch_enabled': true,
        'fetch_interval_minutes': 15,
        'has_password': true,
        'last_sync_at': '2026-09-13T12:00:00Z',
        'last_sync_status': 'SUCCESS',
        'last_sync_message': 'Inbox checked successfully',
        'is_active': true,
      };

      final model = EmailSettingsModel.fromJson(json);

      expect(model.settingsId, equals(1));
      expect(model.providerType, equals('GMAIL'));
      expect(model.emailAddress, equals('operations@sorourlogistics.com'));
      expect(model.imapHost, equals('imap.gmail.com'));
      expect(model.imapPort, equals(993));
      expect(model.smtpPort, equals(587));
      expect(model.hasPassword, isTrue);
      expect(model.autoFetchEnabled, isTrue);
    });

    test('Should serialize EmailSettingsModel to JSON correctly', () {
      final model = EmailSettingsModel(
        providerType: 'OUTLOOK',
        emailAddress: 'shipping@outlook.com',
        username: 'shipping@outlook.com',
        imapHost: 'outlook.office365.com',
        imapPort: 993,
        smtpHost: 'smtp.office365.com',
        smtpPort: 587,
      );

      final json = model.toJson(newPassword: 'my-app-password');

      expect(json['provider_type'], equals('OUTLOOK'));
      expect(json['email_address'], equals('shipping@outlook.com'));
      expect(json['password'], equals('my-app-password'));
      expect(json['imap_host'], equals('outlook.office365.com'));
      expect(json['smtp_host'], equals('smtp.office365.com'));
    });

    test('Should parse EmailConnectionTestResultModel correctly', () {
      final json = {
        'imap_connected': true,
        'imap_message': 'IMAP Connected OK',
        'smtp_connected': true,
        'smtp_message': 'SMTP Connected OK',
        'overall_success': true,
        'details': 'All servers operational',
      };

      final res = EmailConnectionTestResultModel.fromJson(json);

      expect(res.overallSuccess, isTrue);
      expect(res.imapConnected, isTrue);
      expect(res.smtpConnected, isTrue);
      expect(res.details, equals('All servers operational'));
    });

    test('Should parse InboxFetchResultModel correctly', () {
      final json = {
        'total_fetched': 5,
        'matched_files_count': 2,
        'tasks_created_count': 2,
        'message': 'Matched 2 arrival notices',
        'results': [],
      };

      final res = InboxFetchResultModel.fromJson(json);

      expect(res.totalFetched, equals(5));
      expect(res.matchedFilesCount, equals(2));
      expect(res.tasksCreatedCount, equals(2));
      expect(res.message, equals('Matched 2 arrival notices'));
    });

    test('Should parse LocalOutlookStatusModel correctly', () {
      final json = {
        'available': true,
        'user_name': 'Ahmed Sorour',
        'email_address': 'a.sorour@scas-egypt.com',
        'inbox_count': 186,
      };

      final status = LocalOutlookStatusModel.fromJson(json);

      expect(status.available, isTrue);
      expect(status.userName, equals('Ahmed Sorour'));
      expect(status.emailAddress, equals('a.sorour@scas-egypt.com'));
      expect(status.inboxCount, equals(186));
    });
  });

  group('EmailSettingsDialog Widget Tests', () {
    testWidgets('Renders EmailSettingsDialog correctly with provider options and buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      final testDio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/smart-email/local-outlook-status')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'available': true,
                    'user_name': 'Ahmed Sorour',
                    'email_address': 'a.sorour@scas-egypt.com',
                    'inbox_count': 186,
                  },
                ),
              );
            } else if (options.path.contains('/smart-email/settings')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'settings_id': 1,
                    'provider_type': 'LOCAL_OUTLOOK',
                    'email_address': 'a.sorour@scas-egypt.com',
                    'username': 'Ahmed Sorour',
                    'imap_host': 'localhost',
                    'imap_port': 0,
                    'imap_use_ssl': false,
                    'smtp_host': 'localhost',
                    'smtp_port': 0,
                    'smtp_use_tls': false,
                    'smtp_use_ssl': false,
                    'sender_display_name': 'Sorour Logistics Operations',
                    'auto_fetch_enabled': false,
                    'fetch_interval_minutes': 15,
                    'has_password': false,
                    'is_active': true,
                    'created_at': '2026-09-13T12:00:00Z',
                    'updated_at': '2026-09-13T12:00:00Z',
                  },
                ),
              );
            } else {
              handler.next(options);
            }
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EmailSettingsDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title
      expect(find.textContaining('إعدادات ربط البريد الإلكتروني'), findsOneWidget);

      // Check Provider radios
      expect(find.textContaining('Outlook جهازك'), findsOneWidget);
      expect(find.textContaining('Google Gmail'), findsOneWidget);
      expect(find.textContaining('Office 365'), findsOneWidget);
      expect(find.textContaining('خادم مخصص'), findsOneWidget);

      // Check Action buttons
      expect(find.text('اختبار الاتصال'), findsOneWidget);
      expect(find.text('فحص الصندوق الآن'), findsOneWidget);
      expect(find.text('حفظ الإعدادات'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
    });

    test('Should parse and serialize TaskRouteApprovalItemModel correctly', () {
      final item = TaskRouteApprovalItemModel(
        importFileId: 10,
        importFileCode: 'IMP-2026-0002',
        title: 'سداد مصاريف إذن التسليم للشحنة (IMP-2026-0002)',
        assignedUser: 'Clearance Team',
        priority: 'Critical',
        dueDate: '2026-09-30',
        blNumber: 'MEDU123456789',
        taskId: 8,
      );

      final json = item.toJson();
      expect(json['import_file_id'], equals(10));
      expect(json['import_file_code'], equals('IMP-2026-0002'));
      expect(json['assigned_user'], equals('Clearance Team'));
      expect(json['priority'], equals('Critical'));
      expect(json['due_date'], equals('2026-09-30'));
      expect(json['bl_number'], equals('MEDU123456789'));
      expect(json['task_id'], equals(8));
    });

    testWidgets('Renders EmailSyncReviewDialog correctly with matched items and routing controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      final fetchResult = InboxFetchResultModel(
        totalFetched: 18,
        matchedFilesCount: 1,
        tasksCreatedCount: 1,
        message: 'تم فحص 18 إيميل ومطابقة 1 شحنة',
        results: [
          {
            'is_matched_file': true,
            'import_file_id': 2,
            'import_file_code': 'IMP-2026-0002',
            'shipment_title': 'Monorail Orascom Project',
            'match_reason': 'اسم المشروع "Monorail Orascom Project"',
            'task_code': 'TSK-ARV-00008',
            'task_title': 'سداد مصاريف إذن التسليم للشحنة (IMP-2026-0002)',
            'assigned_user': 'Finance Team',
            'priority': 'High',
            'due_date': '2026-09-28',
            'subject': 'ARRIVAL NOTICE - Monorail CRAC Units',
            'sender_email': 'ops@msc.com',
            'summary_message': 'تم مطابقة الإيميل بنجاح',
          }
        ],
        parsedResults: [
          ArrivalNoticeParseResultModel(
            isMatchedFile: true,
            importFileId: 2,
            importFileCode: 'IMP-2026-0002',
            shipmentTitle: 'Monorail Orascom Project',
            matchReason: 'اسم المشروع "Monorail Orascom Project"',
            taskCode: 'TSK-ARV-00008',
            taskTitle: 'سداد مصاريف إذن التسليم للشحنة (IMP-2026-0002)',
            assignedUser: 'Finance Team',
            priority: 'High',
            dueDate: '2026-09-28',
            subject: 'ARRIVAL NOTICE - Monorail CRAC Units',
            senderEmail: 'ops@msc.com',
            summaryMessage: 'تم مطابقة الإيميل بنجاح',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EmailSyncReviewDialog(result: fetchResult),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and description
      expect(find.text('نتائج فحص البريد وتوجيه المهام الذكية'), findsOneWidget);
      expect(find.textContaining('تم فحص 18 إيميل ومطابقة 1 شحنة بنجاح'), findsOneWidget);

      // Check statistics pills
      expect(find.text('إجمالي الإيميلات الممسوحة: '), findsOneWidget);
      expect(find.text('الشحنات المطابقة: '), findsOneWidget);

      // Check matched shipment card details
      expect(find.text('Monorail Orascom Project'), findsOneWidget);
      expect(find.text('IMP-2026-0002'), findsOneWidget);
      expect(find.text('مطابقة: اسم المشروع "Monorail Orascom Project"'), findsOneWidget);
      expect(find.text('TSK-ARV-00008'), findsOneWidget);

      // Check routing buttons
      expect(find.text('الانتقال إلى شاشة المهام الذكية'), findsOneWidget);
      expect(find.textContaining('اعتماد وتوجيه المهام المختارة'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
    });
  });
}
