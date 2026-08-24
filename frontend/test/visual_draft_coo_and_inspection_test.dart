import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_documentation/widgets/visual_draft_coo_sheet.dart';
import 'package:frontend/features/import_documentation/widgets/visual_draft_inspection_sheet.dart';

void main() {
  group('Visual Draft COO Sheet Tests', () {
    testWidgets('Renders Multi-Origin and Multi-HS Codes in VisualDraftCOOSheet', (tester) async {
      final templateData = {
        'certificate_number': '26C000001/00001',
        'box_1_exporter': 'UAB Narbutas International\nVilnius, Lithuania',
        'box_2_consignee': 'Archi Brands Egypt\nCairo, Egypt',
        'box_3_means_of_transport': 'FROM VILNIUS TO ALEXANDRIA BY SEA',
        'box_4_country_of_destination': 'EGYPT',
        'country_of_origin': 'Germany, Lithuania, Poland',
        'countries_of_origin_list': ['Germany', 'Lithuania', 'Poland'],
        'hs_codes': '940130, 940310',
        'hs_codes_list': ['940130', '940310'],
        'box_6_marks_and_numbers': 'Commercial Acoustic Panels',
        'box_9_quantity_and_weight': '141 PKGS / 1,774.50 KGS',
        'box_10_invoice_number_and_date': 'INV-2026-001\n2026-08-20',
        'box_7_remarks': 'REVISED RULES',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: SingleChildScrollView(
                child: VisualDraftCOOSheet(
                  templateData: templateData,
                  certificateType: 'EUR.1 Movement Certificate',
                  acidNumber: '7595528271020210099',
                  exemptionNotes: 'مؤهلة للإعفاء التفضيلى الكامل 0%',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('EUR.1'), findsWidgets);
      expect(find.textContaining('7595528271020210099'), findsOneWidget);
      expect(find.textContaining('Germany'), findsWidgets);
      expect(find.textContaining('Lithuania'), findsWidgets);
      expect(find.textContaining('Poland'), findsWidgets);
      expect(find.textContaining('940130'), findsWidgets);
      expect(find.textContaining('940310'), findsWidgets);
    });
  });

  group('Visual Draft Inspection Sheet Tests', () {
    testWidgets('Renders Inspection Details in VisualDraftInspectionSheet', (tester) async {
      final templateData = {
        'coc_number': 'DRAFT-COC-SGS-9901',
        'importer_name_and_address': 'Archi Brands Egypt\nCairo, Egypt',
        'exporter_name_and_address': 'Narbutas International\nVilnius, Lithuania',
        'country_of_origin': 'Germany, Lithuania',
        'countries_of_origin_list': ['Germany', 'Lithuania'],
        'hs_code': '940130, 940310',
        'hs_codes_list': ['940130', '940310'],
        'total_value': '82,450.00 EUR',
        'port_of_entry': 'Alexandria Port',
        'date_of_inspection': '2026-08-20',
        'place_of_inspection': 'Vilnius, Lithuania',
        'issuing_office': 'SGS Lithuania UAB',
      };

      const standards = [
        'ES 4029-1 / 2024 (Furniture Tables: Safety)',
        'ES 7321 / 2011 (Safety and Labeling)',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: SingleChildScrollView(
                child: VisualDraftInspectionSheet(
                  templateData: templateData,
                  agency: 'SGS',
                  certType: 'COC (Certificate of Conformity)',
                  acidNumber: '7595528271020210099',
                  standards: standards,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('SGS'), findsWidgets);
      expect(find.text('🌍 Germany'), findsOneWidget);
      expect(find.text('🌍 Lithuania'), findsOneWidget);
      expect(find.text('🔖 940130'), findsOneWidget);
      expect(find.text('🔖 940310'), findsOneWidget);
      expect(find.textContaining('ES 4029-1'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });
  });
}
