import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_consultation/models/customs_consultation_model.dart';

void main() {
  group('CustomsConsultationModel & ChecklistItem Unit Tests (BP-009 / BP-010)', () {
    test('Should parse CustomsChecklistItemModel from JSON correctly', () {
      final json = {
        'item_id': 1,
        'consultation_id': 10,
        'document_type': 'عرض وفحص هيئة الرقابة على الصادرات والواردات (GOEIC) - بند 8415820010',
        'hs_code': '8415820010',
        'is_required': true,
        'required_text': '✓',
        'is_blocking_shipment': true,
        'responsible_party': 'Customs Broker',
        'status': 'Pending',
        'regulatory_agency': 'GOEIC (هيئة الصادرات والواردات)',
        'remarks': 'يتطلب سحب عينات والفحص المعملي ومطابقة المواصفات القياسية المصرية.',
      };

      final item = CustomsChecklistItemModel.fromJson(json);

      expect(item.itemId, 1);
      expect(item.hsCode, '8415820010');
      expect(item.isBlockingShipment, isTrue);
      expect(item.responsibleParty, 'Customs Broker');
      expect(item.regulatoryAgency, 'GOEIC (هيئة الصادرات والواردات)');
    });

    test('Should serialize CustomsChecklistItemModel to JSON accurately', () {
      final item = CustomsChecklistItemModel(
        documentType: 'شهادة المنشأ COO',
        hsCode: '8415820010',
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        regulatoryAgency: 'Chamber of Commerce',
        remarks: 'موثقة أصولاً',
      );

      final json = item.toJson();

      expect(json['document_type'], 'شهادة المنشأ COO');
      expect(json['hs_code'], '8415820010');
      expect(json['is_blocking_shipment'], isTrue);
      expect(json['responsible_party'], 'Supplier / Exporter');
      expect(json['status'], 'Approved');
    });

    test('Should parse CustomsConsultationModel with checklist from JSON', () {
      final json = {
        'consultation_id': 5,
        'consultation_code': 'CST-2026-0005',
        'title': 'دراسة المراجعة الجمركية الأولية لخط الإنتاج',
        'broker_id': 12,
        'broker_name': 'مكتب الإخلاص للتخليص الجمركي',
        'broker_contact_person': 'م. عادل الشريف',
        'import_file_id': 101,
        'import_file_code': 'IMP-2026-0001',
        'po_id': 201,
        'po_number': 'PO-2026-0001',
        'estimated_duties_egp': 165801.50,
        'notes': 'تم التدقيق مع المستخلص',
        'overall_status': 'In Progress',
        'total_documents_count': 5,
        'approved_documents_count': 2,
        'blocking_issues_count': 1,
        'readiness_percentage': 40.0,
        'checklist_items': [
          {
            'item_id': 1,
            'document_type': 'Proforma Invoice',
            'is_required': true,
            'is_blocking_shipment': true,
            'status': 'Approved',
          },
          {
            'item_id': 2,
            'document_type': 'GOEIC Inspection',
            'hs_code': '8415820010',
            'is_required': true,
            'is_blocking_shipment': true,
            'status': 'Pending',
          }
        ],
      };

      final model = CustomsConsultationModel.fromJson(json);

      expect(model.consultationId, 5);
      expect(model.consultationCode, 'CST-2026-0005');
      expect(model.estimatedDutiesEgp, 165801.50);
      expect(model.readinessPercentage, 40.0);
      expect(model.checklistItems.length, 2);
      expect(model.checklistItems[1].hsCode, '8415820010');
    });
  });
}
