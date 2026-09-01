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
      expect(find.textContaining('7595528271020210099'), findsWidgets);
      expect(find.textContaining('Germany'), findsWidgets);
      expect(find.textContaining('Lithuania'), findsWidgets);
      expect(find.textContaining('Poland'), findsWidgets);
      expect(find.textContaining('940130'), findsWidgets);
      expect(find.textContaining('940310'), findsWidgets);
    });

    testWidgets('Renders Authentic China CCPIT COO Layout with Box 6 N/M and Box 7 Packed Line', (tester) async {
      final chinaTemplateData = {
        'certificate_type': 'China Certificate of Origin (CCPIT)',
        'certificate_number': '26C311120218/00004',
        'box_1_exporter': 'SUZHOU GREENISH IMP&EXP CO.,LTD.\nSUZHOU CHINA\n***',
        'box_2_consignee': 'SCAS FOR CONSTRUCTION\nCAIRO, EGYPT',
        'box_3_means_of_transport': 'FROM SHANGHAI CHINA TO ALEXANDRIA EGYPT BY SEA',
        'box_4_country_of_destination': 'EGYPT',
        'country_of_origin': 'China',
        'countries_of_origin_list': ['China'],
        'hs_codes': '560229',
        'hs_codes_list': ['560229'],
        'box_6_marks_and_numbers': 'N/M',
        'box_7_description_and_acid': 'ACOUSTIC PANEL\n\nTOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY\n\n*** *** *** *** ***\n\nACID:5281534391006810017',
        'box_9_quantity_and_weight': '4756KGS G.W.',
        'box_10_invoice_number_and_date': 'GRS2026022610\nFEB. 26, 2026',
        'table_rows': [
          {
            'item_no': 1,
            'marks_and_numbers': 'N/M',
            'description': 'ACOUSTIC PANEL',
            'description_and_acid': 'ACOUSTIC PANEL\n\nTOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY\n\n*** *** *** *** ***\n\nACID:5281534391006810017',
            'hs_code': '560229',
            'quantity': 810.0,
            'unit': 'SHEETS',
            'packages_count': 82,
            'gross_weight_kg': 4756.0,
            'quantity_and_weight_str': '4756KGS G.W.',
            'invoice_number': 'GRS2026022610',
            'invoice_date': '2026-02-26',
            'invoice_str': 'GRS2026022610\nFEB. 26, 2026',
          }
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: SingleChildScrollView(
                child: VisualDraftCOOSheet(
                  templateData: chinaTemplateData,
                  certificateType: 'China Certificate of Origin (CCPIT)',
                  acidNumber: '5281534391006810017',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header & Box 6 N/M
      expect(find.text("THE PEOPLE'S REPUBLIC OF CHINA"), findsOneWidget);
      expect(find.text('N/M'), findsWidgets);

      // Check Box 7 Content
      expect(find.textContaining('ACOUSTIC PANEL'), findsWidgets);
      expect(find.textContaining('TOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY'), findsWidgets);
      expect(find.textContaining('ACID:5281534391006810017'), findsWidgets);

      // Check Customs note with Chamber of Commerce
      expect(find.textContaining('ختم الجمارك وختم الغرفة التجارية'), findsOneWidget);
      expect(find.textContaining('Customs stamp and Chamber of Commerce stamp'), findsOneWidget);
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
      expect(find.textContaining('ES 4029-1'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });
  });

  group('Chinese COO Box 7 & Box 8 Helper Unit Tests', () {
    test('extractCleanMainDescription strips model numbers and material qualifiers like PET', () {
      expect(VisualDraftCOOSheet.extractCleanMainDescription('PET Acoustic Panels (YH-652)'), 'Acoustic Panels');
      expect(VisualDraftCOOSheet.extractCleanMainDescription('PET Acoustic Panels (YH-644)'), 'Acoustic Panels');
      expect(VisualDraftCOOSheet.extractCleanMainDescription('PET Acoustic Panels'), 'Acoustic Panels');
      expect(VisualDraftCOOSheet.extractCleanMainDescription('Acoustic Panel YH-652'), 'Acoustic Panel');
      expect(VisualDraftCOOSheet.extractCleanMainDescription('N/M Acoustic Panels'), 'Acoustic Panels');
    });

    test('formatCooHsCode formats 4-digit heading with dot for Chinese CCPIT COO', () {
      expect(VisualDraftCOOSheet.formatCooHsCode('5602290000', isChina: true), '56.02');
      expect(VisualDraftCOOSheet.formatCooHsCode('560229', isChina: true), '56.02');
      expect(VisualDraftCOOSheet.formatCooHsCode('5602', isChina: true), '56.02');
      expect(VisualDraftCOOSheet.formatCooHsCode('3921900000', isChina: true), '39.21');
      expect(VisualDraftCOOSheet.formatCooHsCode('5602290000', isChina: false), '5602290000');
    });
  });
}
