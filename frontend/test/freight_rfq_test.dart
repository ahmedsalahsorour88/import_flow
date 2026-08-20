import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/widgets/freight_rfq_dialog.dart';
import 'package:frontend/core/services/freight_rfq_generator_service.dart';

void main() {
  group('Freight RFQ Data Model & Generator Tests', () {
    final sampleRfqJson = {
      'import_file_id': 101,
      'import_file_code': 'IMP-2026-0099',
      'custom_file_number': '6701068101',
      'company_name': 'SCAS FOR CONSTRUCTION AND FINISHING',
      'supplier_name': 'Suzhou Yuheng Textile Co., Ltd.',
      'incoterm_code': 'EXW',
      'commodity': 'Acoustic Panels',
      'shipment_mode': 'Sea FCL',
      'recommended_containers': '1 CTNR * 40HC + 1 CTNR * 20GP',
      'total_cbm': 64.86,
      'gross_weight_kg': 10511.0,
      'net_weight_kg': 9800.0,
      'total_packages': 350,
      'packages_breakdown': '350 boxes',
      'pickup_address': 'N0.16, Kangsheng Road, Zhitang Town, Changshu City, Jiangsu Province, China',
      'port_of_loading': 'Shanghai Port',
      'port_of_discharge': 'El Dekheila Port (non TMT)',
      'cargo_ready_date': '2026-08-26',
      'target_free_days': 21,
      'service_type': 'Direct',
      'special_requirements': 'Must be 21 days free time, direct service, avoid TMT terminal',
      'email_subject': 'RFQ: EXW Freight Rate Request - 6701068101 - Shanghai Port to El Dekheila Port (non TMT)',
      'email_body_template': 'Dear Marian,\n\nGood day.\nCould you please provide an EXW rate for Acoustic Panels...',
      'whatsapp_text_template': '🚢 *REQUEST FOR FREIGHT QUOTATION (RFQ)*\n📍 *Pickup Address:* N0.16, Kangsheng Road...',
    };

    test('FreightRfqDataModel parses accurately from json', () {
      final model = FreightRfqDataModel.fromJson(sampleRfqJson);

      expect(model.importFileId, 101);
      expect(model.customFileNumber, '6701068101');
      expect(model.incotermCode, 'EXW');
      expect(model.commodity, 'Acoustic Panels');
      expect(model.recommendedContainers, '1 CTNR * 40HC + 1 CTNR * 20GP');
      expect(model.totalCbm, 64.86);
      expect(model.grossWeightKg, 10511.0);
      expect(model.targetFreeDays, 21);
      expect(model.serviceType, 'Direct');
    });

    test('FreightRfqGeneratorService generates PDF byte document', () async {
      final model = FreightRfqDataModel.fromJson(sampleRfqJson);
      final pdfBytes = await FreightRfqGeneratorService.generateFreightRfqPdf(
        rfq: model,
        recipientName: 'Marian',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });

    testWidgets('FreightRfqDialog renders header and structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FreightRfqDialog(
                importFileId: 101,
                importFileCode: 'IMP-2026-0099',
                customFileNumber: '6701068101',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FreightRfqDialog), findsOneWidget);
      expect(find.textContaining('6701068101'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
