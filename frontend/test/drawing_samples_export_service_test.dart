import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/customs_clearance/services/drawing_samples_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingSamplesExportService Tests', () {
    final mockSamples = [
      {
        'sample_id': 'SMP-001',
        'authority': 'الهيئة العامة للرقابة على الصادرات والواردات',
        'drawing_date': '2026-09-01',
        'receipt_no': 'RCP-9821',
        'test_type': 'فحص كيميائي ومطابقة مواصفات',
        'status': 'PASSED',
        'notes': 'مطابق تماماً للمواصفة القياسية المصرية',
      },
      {
        'sample_id': 'SMP-002',
        'authority': 'الهيئة القومية لسلامة الغذاء',
        'drawing_date': '2026-09-02',
        'receipt_no': 'RCP-9822',
        'test_type': 'تحليل ميكروبيولوجي',
        'status': 'PENDING',
        'notes': 'بانتظار ظهور نتيجة الزرع',
      },
    ];

    final mockShortages = [
      {
        'shortage_id': 'SHR-001',
        'container_no': 'MSCU-1234567',
        'item_desc': 'محركات كهربائية صناعية',
        'manifest_qty': '100',
        'landed_qty': '96',
        'shortage_qty': '4',
        'shortage_pct': '4.0',
        'action': 'DEDUCT_DUTY',
        'notes': 'تم إثبات كسر قفل الحاوية وسقوط 4 طرود بالميناء',
      },
      {
        'shortage_id': 'SHR-002',
        'container_no': 'TGHU-7654321',
        'item_desc': 'صمامات ضغط هيدروليكية',
        'manifest_qty': '50',
        'landed_qty': '48',
        'shortage_qty': '2',
        'shortage_pct': '4.0',
        'action': 'CARRIER_CLAIM',
        'notes': 'مطالبة التوكيل الملاحي',
      },
    ];

    testWidgets('exportSamplesToTsv outputs UTF-8 BOM and correct headers and rows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final tsv = DrawingSamplesExportService.exportSamplesToTsv(context, mockSamples);

      expect(tsv.startsWith('\uFEFF'), isTrue);
      expect(tsv.contains('SMP-001'), isTrue);
      expect(tsv.contains('RCP-9821'), isTrue);
      expect(tsv.contains('SMP-002'), isTrue);
      expect(tsv.contains('\t'), isTrue);
    });

    testWidgets('exportShortagesToTsv outputs UTF-8 BOM and shortage entries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final tsv = DrawingSamplesExportService.exportShortagesToTsv(context, mockShortages);

      expect(tsv.startsWith('\uFEFF'), isTrue);
      expect(tsv.contains('SHR-001'), isTrue);
      expect(tsv.contains('MSCU-1234567'), isTrue);
      expect(tsv.contains('4.0%'), isTrue);
      expect(tsv.contains('\t'), isTrue);
    });

    testWidgets('exportSamplesToCsv outputs UTF-8 BOM and CSV structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('en'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final csv = DrawingSamplesExportService.exportSamplesToCsv(context, mockSamples);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('Sample ID'), isTrue);
      expect(csv.contains('SMP-001'), isTrue);
      expect(csv.contains(','), isTrue);
    });

    testWidgets('exportShortagesToCsv outputs UTF-8 BOM and CSV structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('en'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final csv = DrawingSamplesExportService.exportShortagesToCsv(context, mockShortages);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('Protocol ID'), isTrue);
      expect(csv.contains('SHR-001'), isTrue);
      expect(csv.contains(','), isTrue);
    });

    testWidgets('buildDrawingSamplesDossier generates formatted comprehensive dossier', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final dossier = DrawingSamplesExportService.buildDrawingSamplesDossier(
        context: context,
        samples: mockSamples,
        shortages: mockShortages,
      );

      expect(dossier.contains('IMPORTFLOW ERP'), isTrue);
      expect(dossier.contains('SMP-001'), isTrue);
      expect(dossier.contains('SHR-001'), isTrue);
      expect(dossier.contains('MSCU-1234567'), isTrue);
    });
  });
}
