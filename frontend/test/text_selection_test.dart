import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/services/coo_export_service.dart';
import 'package:frontend/features/import_documentation/services/draft_bl_export_service.dart';
import 'package:frontend/features/import_documentation/services/inspection_export_service.dart';

void main() {
  group('Universal Screen Text Selection Tests', () {
    testWidgets('SelectionArea wraps screen content and enables text selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionArea(
            child: Scaffold(
              body: Column(
                children: [
                  Text('ACID: 5281534391006810017'),
                  Text('SUPPLIER: SUZHOU GREENISH IMP&EXP CO.,LTD.'),
                  Text('HS CODE: 560229'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SelectionArea exists in tree
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.text('ACID: 5281534391006810017'), findsOneWidget);
      expect(find.text('SUPPLIER: SUZHOU GREENISH IMP&EXP CO.,LTD.'), findsOneWidget);
      expect(find.text('HS CODE: 560229'), findsOneWidget);

      // Verify Selectable text elements are inside SelectionArea
      final selectionArea = tester.widget<SelectionArea>(find.byType(SelectionArea));
      expect(selectionArea.child, isNotNull);
    });
  });

  group('PDF Vector Text and Export Generation Tests', () {
    test('Certificate of Origin PDF produces valid vector PDF bytes', () async {
      final templateData = {
        'certificate_type': 'China Certificate of Origin (CCPIT)',
        'certificate_number': '26C311120218/00004',
        'box_1_exporter': 'SUZHOU GREENISH IMP&EXP CO.,LTD.\nSUZHOU CHINA\n***',
        'box_2_consignee': 'SCAS FOR CONSTRUCTION\nCAIRO, EGYPT',
        'box_3_means_of_transport': 'FROM SHANGHAI CHINA TO ALEXANDRIA EGYPT BY SEA',
        'box_4_country_of_destination': 'EGYPT',
        'country_of_origin': 'China',
        'countries_of_origin_list': ['China'],
        'hs_codes': '560229',
        'box_6_marks_and_numbers': 'N/M',
        'box_7_description_and_acid': 'ACOUSTIC PANEL\n\nTOTAL PACKED IN EIGHTY TWO (82) CARTONS ONLY\n\n*** *** *** *** ***\n\nACID:5281534391006810017',
        'box_9_quantity_and_weight': '4756KGS G.W.',
        'box_10_invoice_number_and_date': 'GRS2026022610\nFEB. 26, 2026',
      };

      final pdfDoc = await CooExportService.generateCOOPdf(
        templateData: templateData,
        certificateType: 'China Certificate of Origin (CCPIT)',
        acidNumber: '5281534391006810017',
      );

      final bytes = await pdfDoc.save();
      expect(bytes.isNotEmpty, isTrue);
      // Valid PDF starts with %PDF-
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('Draft B/L PDF produces valid vector PDF bytes', () async {
      final draftData = {
        'draft_bl_number': 'BL-MAR-2026-9901',
        'booking_no': 'BKG-9901',
        'shipper': 'GLOBAL EXPORTER LTD',
        'consignee': 'ARCHI BRANDS EGYPT',
        'vessel_name': 'MSC ALEXANDRIA',
        'voyage_number': 'V2026',
        'pol': 'SHANGHAI',
        'pod': 'ALEXANDRIA',
        'acid_number': '5281534391006810017',
        'goods_description': 'ACOUSTIC PANELS',
        'total_gross_weight_kg': 4756.0,
      };

      final pdfDoc = await DraftBLExportService.generateDraftBLPdf(
        systemData: {},
        draftData: draftData,
        draftBlNumber: 'BL-MAR-2026-9901',
      );

      final bytes = await pdfDoc.save();
      expect(bytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('Inspection Certificate PDF produces valid vector PDF bytes', () async {
      final templateData = {
        'coc_number': 'DRAFT-COC-SGS-9901',
        'country_of_origin': 'China',
        'hs_code': '560229',
        'total_value': '43,704.00 USD',
        'port_of_entry': 'Alexandria',
      };

      final pdfDoc = await InspectionExportService.generateInspectionPdf(
        templateData: templateData,
        agency: 'SGS',
        certType: 'COC (Certificate of Conformity)',
        acidNumber: '5281534391006810017',
        standards: ['ES 4029-1 / 2024'],
      );

      final bytes = await pdfDoc.save();
      expect(bytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
