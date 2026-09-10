import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/cargo_insurance/models/cargo_insurance_model.dart';
import 'package:frontend/features/cargo_insurance/services/cargo_insurance_export_service.dart';

Widget _buildTestWidget({Locale locale = const Locale('en')}) {
  return MaterialApp(
    home: AppLocalizationsProvider(
      locale: locale,
      child: const Scaffold(body: SizedBox()),
    ),
  );
}

void main() {
  group('Screen 65: Cargo Insurance Export Service Tests', () {
    late List<CargoInsuranceModel> sampleCerts;

    setUp(() {
      sampleCerts = [
        CargoInsuranceModel(
          certificateId: 1,
          certificateCode: 'INS-2026-0001',
          policyNumber: 'POL-EGY-99120',
          policyType: 'SPECIFIC',
          importFileId: 101,
          insuranceCompanyId: 5,
          insuranceCompanyName: 'Misr Insurance Company',
          insuredEntityName: 'El-Nasr Import & Export',
          transportMode: 'OCEAN',
          carrierName: 'Maersk Line',
          vesselOrFlightNo: 'Maersk Mc-Kinney',
          voyageNumber: 'V-2026-A',
          trackingReference: 'MSK-BL-771829',
          portOfLoading: 'Shanghai Port, China',
          portOfDischarge: 'Alexandria Port, Egypt',
          currency: 'USD',
          exchangeRate: 48.5,
          invoiceValue: 100000.0,
          freightCost: 5000.0,
          cifValue: 105000.0,
          markupPercentage: 0.10,
          insuredValue: 115500.0,
          coverageClause: 'ICC_A',
          includeWarAndStrikes: true,
          baseRate: 0.0025,
          warRate: 0.0005,
          basePremium: 288.75,
          warStrikesPremium: 57.75,
          minimumPremium: 50.0,
          netPremium: 346.50,
          issuanceFee: 15.0,
          taxRate: 0.05,
          taxAmount: 18.08,
          totalPayablePremium: 379.58,
          goodsDescription: 'Industrial CNC Lathes & Tooling',
          packageCount: 14,
          grossWeightKg: 12500.0,
          status: 'ISSUED',
          issuedAt: '2026-03-01T10:00:00Z',
          createdAt: '2026-03-01T09:00:00Z',
          updatedAt: '2026-03-01T10:00:00Z',
          createdBy: 'admin',
          updatedBy: 'admin',
          isActive: true,
        ),
        CargoInsuranceModel(
          certificateId: 2,
          certificateCode: 'INS-2026-0002',
          policyNumber: null,
          policyType: 'OPEN_DECLARATION',
          importFileId: null,
          insuranceCompanyId: 6,
          insuranceCompanyName: 'Allianz Egypt',
          insuredEntityName: 'Cairo Electronics Co',
          transportMode: 'AIR',
          carrierName: 'EgyptAir Cargo',
          vesselOrFlightNo: 'MS-501',
          portOfLoading: 'Frankfurt Airport',
          portOfDischarge: 'Cairo International Airport',
          currency: 'EUR',
          exchangeRate: 52.0,
          invoiceValue: 20000.0,
          freightCost: 1500.0,
          cifValue: 21500.0,
          markupPercentage: 0.10,
          insuredValue: 23650.0,
          coverageClause: 'AIR_ALL_RISKS',
          includeWarAndStrikes: false,
          baseRate: 0.0020,
          warRate: 0.0,
          basePremium: 47.30,
          warStrikesPremium: 0.0,
          minimumPremium: 30.0,
          netPremium: 47.30,
          issuanceFee: 15.0,
          taxRate: 0.05,
          taxAmount: 3.12,
          totalPayablePremium: 65.42,
          goodsDescription: 'Microcontrollers & PCB Modules',
          packageCount: 5,
          grossWeightKg: 320.0,
          status: 'DRAFT',
          issuedAt: null,
          createdAt: '2026-03-05T14:30:00Z',
          updatedAt: '2026-03-05T14:30:00Z',
          createdBy: 'operator',
          updatedBy: 'operator',
          isActive: true,
        ),
      ];
    });

    testWidgets('toRowSummary generates valid single-line summary with localizations', (tester) async {
      await tester.pumpWidget(_buildTestWidget(locale: const Locale('ar')));
      final contextAr = tester.element(find.byType(SizedBox));
      final summaryAr = CargoInsuranceExportService.toRowSummary(sampleCerts.first, contextAr.l10n);
      expect(summaryAr, contains('INS-2026-0001'));
      expect(summaryAr, contains('POL-EGY-99120'));
      expect(summaryAr, contains('El-Nasr Import & Export'));
      expect(summaryAr, contains('115500.00 USD'));
      expect(summaryAr, contains('ISSUED'));
    });

    testWidgets('exportCertificatesToTsv includes UTF-8 BOM, tab separators, and all rows', (tester) async {
      await tester.pumpWidget(_buildTestWidget(locale: const Locale('en')));
      final contextEn = tester.element(find.byType(SizedBox));
      final tsv = CargoInsuranceExportService.exportCertificatesToTsv(contextEn, sampleCerts);
      expect(tsv.startsWith('\uFEFF'), isTrue, reason: 'TSV must start with UTF-8 BOM');
      expect(tsv, contains('\t'));
      expect(tsv, contains('INS-2026-0001'));
      expect(tsv, contains('INS-2026-0002'));
      expect(tsv, contains('Misr Insurance Company'));
      expect(tsv, contains('Allianz Egypt'));
      expect(tsv, contains('115500.00'));
      expect(tsv, contains('23650.00'));
    });

    testWidgets('exportCertificatesToCsv includes UTF-8 BOM, commas, and escapes', (tester) async {
      await tester.pumpWidget(_buildTestWidget(locale: const Locale('ar')));
      final contextAr = tester.element(find.byType(SizedBox));
      final csv = CargoInsuranceExportService.exportCertificatesToCsv(contextAr, sampleCerts);
      expect(csv.startsWith('\uFEFF'), isTrue, reason: 'CSV must start with UTF-8 BOM');
      expect(csv, contains(','));
      expect(csv, contains('INS-2026-0001'));
      expect(csv, contains('INS-2026-0002'));
      expect(csv, contains('El-Nasr Import & Export'));
      expect(csv, contains('Cairo Electronics Co'));
    });

    testWidgets('buildCertificatesDossier outputs structured dossier with KPIs and records', (tester) async {
      await tester.pumpWidget(_buildTestWidget(locale: const Locale('ar')));
      final contextAr = tester.element(find.byType(SizedBox));
      final dossier = CargoInsuranceExportService.buildCertificatesDossier(
        context: contextAr,
        certs: sampleCerts,
      );
      expect(dossier, contains('================================================================'));
      expect(dossier, contains('INS-2026-0001'));
      expect(dossier, contains('INS-2026-0002'));
      expect(dossier, contains('Misr Insurance Company'));
      expect(dossier, contains('Allianz Egypt'));
      expect(dossier, contains('Industrial CNC Lathes & Tooling'));
    });
  });
}
