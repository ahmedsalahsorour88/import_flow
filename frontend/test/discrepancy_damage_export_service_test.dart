import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/customs_clearance/services/discrepancy_and_damage_export_service.dart';

void main() {
  group('Screen 61: DiscrepancyAndDamageExportService Tests', () {
    final mockProtocols = [
      {
        'protocol_no': 'DMG-ALX-001',
        'declaration_no': '46-ALX-IMP-2026-001',
        'container_no': 'MSCU1234567',
        'damage_type': 'كسر أختام وبلل مياه بحر',
        'damaged_qty': '10 طرود',
        'estimated_loss_egp': 35000.0,
        'responsible_party': 'التوكيل الملاحي',
        'insurance_claim_status': 'APPROVED',
        'committee': 'ممثل الجمارك والتوكيل والتأمين',
        'date': '2026-09-08',
        'notes': 'تم فتح الحاوية بحضور اللجنة وإثبات التلف',
      },
      {
        'protocol_no': 'DMG-DKH-002',
        'declaration_no': '46-DKH-IMP-2026-099',
        'container_no': 'TGHU7654321',
        'damage_type': 'تهشم منصات وسقوط رافعة',
        'damaged_qty': '2 باليتة',
        'estimated_loss_egp': 18500.5,
        'responsible_party': 'شركة التفريغ بالميناء',
        'insurance_claim_status': 'CLAIM_SUBMITTED',
        'committee': 'مندوب التفريغ والمستودع',
        'date': '2026-09-09',
        'notes': 'سقطت المنصة أثناء مناولة ونش الرصيف',
      },
    ];

    Widget buildTestWidget({Locale locale = const Locale('ar')}) {
      return MaterialApp(
        home: AppLocalizationsProvider(
          locale: locale,
          child: const Scaffold(body: SizedBox()),
        ),
      );
    }

    testWidgets('TSV export starts with UTF-8 BOM and contains correct tabs and headers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final context = tester.element(find.byType(SizedBox));

      final tsv = DiscrepancyAndDamageExportService.exportDiscrepanciesToTsv(context, mockProtocols);

      expect(tsv.startsWith('\uFEFF'), isTrue, reason: 'TSV must start with UTF-8 BOM');
      expect(tsv.contains('\t'), isTrue);
      expect(tsv.contains('DMG-ALX-001'), isTrue);
      expect(tsv.contains('MSCU1234567'), isTrue);
      expect(tsv.contains('35000.00'), isTrue);
      expect(tsv.contains('DMG-DKH-002'), isTrue);
    });

    testWidgets('CSV export starts with UTF-8 BOM and handles comma quoting', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final context = tester.element(find.byType(SizedBox));

      final csv = DiscrepancyAndDamageExportService.exportDiscrepanciesToCsv(context, mockProtocols);

      expect(csv.startsWith('\uFEFF'), isTrue, reason: 'CSV must start with UTF-8 BOM');
      expect(csv.contains(','), isTrue);
      expect(csv.contains('DMG-ALX-001'), isTrue);
      expect(csv.contains('MSCU1234567'), isTrue);
      expect(csv.contains('35000.00'), isTrue);
      expect(csv.contains('DMG-DKH-002'), isTrue);
    });

    testWidgets('Dossier text contains header, KPI metrics, and protocol blocks', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final context = tester.element(find.byType(SizedBox));

      final dossier = DiscrepancyAndDamageExportService.buildDiscrepancyDossier(
        context: context,
        protocols: mockProtocols,
      );

      expect(dossier.contains('IMPORTFLOW ERP'), isTrue);
      expect(dossier.contains('SUMMARY KPI METRICS'), isTrue);
      expect(dossier.contains('DMG-ALX-001'), isTrue);
      expect(dossier.contains('DMG-DKH-002'), isTrue);
      expect(dossier.contains('35000.00'), isTrue);
      expect(dossier.contains('18500.50'), isTrue);
      expect(dossier.contains('End of Protocol Dossier'), isTrue);
    });

    testWidgets('Empty protocols list generates valid TSV, CSV and Dossier without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final context = tester.element(find.byType(SizedBox));

      final tsv = DiscrepancyAndDamageExportService.exportDiscrepanciesToTsv(context, []);
      expect(tsv.startsWith('\uFEFF'), isTrue);

      final csv = DiscrepancyAndDamageExportService.exportDiscrepanciesToCsv(context, []);
      expect(csv.startsWith('\uFEFF'), isTrue);

      final dossier = DiscrepancyAndDamageExportService.buildDiscrepancyDossier(
        context: context,
        protocols: [],
      );
      expect(dossier.contains('SUMMARY KPI METRICS'), isTrue);
      expect(dossier.contains(context.l10n.discrepancyDamageEmptyRecords), isTrue);
    });

    testWidgets('getClaimStatusLabel correctly maps status codes to localized strings', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final context = tester.element(find.byType(SizedBox));

      final l = context.l10n;
      expect(
        DiscrepancyAndDamageExportService.getClaimStatusLabel(context, 'APPROVED'),
        equals(l.discrepancyDamageClaimApproved),
      );
      expect(
        DiscrepancyAndDamageExportService.getClaimStatusLabel(context, 'UNDER_REVIEW'),
        equals(l.discrepancyDamageClaimUnderReview),
      );
      expect(
        DiscrepancyAndDamageExportService.getClaimStatusLabel(context, 'CLAIM_SUBMITTED'),
        equals(l.discrepancyDamageClaimSubmitted),
      );
      expect(
        DiscrepancyAndDamageExportService.getClaimStatusLabel(context, null),
        equals(l.discrepancyDamageClaimSubmitted),
      );
    });
  });
}
