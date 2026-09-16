import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/recalculation/models/recalculation_model.dart';

void main() {
  group('Centralized Recalculation Engine Models (CRE-001)', () {
    test('RecalculationPreviewItem deserialization and properties', () {
      final json = {
        'field_name': 'customs_duties_egp',
        'label_ar': 'الرسوم الجمركية',
        'label_en': 'Customs Duties',
        'old_value': 10000.0,
        'new_value': 12000.0,
        'variance_amount': 2000.0,
        'variance_percentage': 20.0,
        'is_hard_block': true,
        'threshold_percentage': 5.0,
        'source_entity_type': 'customs_consultation',
        'dependency_id': 1,
      };

      final item = RecalculationPreviewItem.fromJson(json);

      expect(item.fieldName, 'customs_duties_egp');
      expect(item.labelAr, 'الرسوم الجمركية');
      expect(item.labelEn, 'Customs Duties');
      expect(item.oldValue, 10000.0);
      expect(item.newValue, 12000.0);
      expect(item.varianceAmount, 2000.0);
      expect(item.variancePercentage, 20.0);
      expect(item.isHardBlock, isTrue);
      expect(item.thresholdPercentage, 5.0);
      expect(item.sourceEntityType, 'customs_consultation');
      expect(item.dependencyId, 1);
      expect(item.formattedVariancePct, '20.0%');
      expect(item.hasChange, isTrue);
    });

    test('RecalculationPreviewResponse deserialization and changedItems filter', () {
      final json = {
        'target_entity_type': 'import_budget',
        'target_entity_id': 42,
        'items': [
          {
            'field_name': 'freight_cost_egp',
            'label_ar': 'النولون',
            'label_en': 'Freight',
            'old_value': 5000.0,
            'new_value': 5000.0,
            'variance_amount': 0.0,
            'variance_percentage': 0.0,
            'is_hard_block': false,
            'threshold_percentage': 5.0,
            'source_entity_type': 'shipping_scenarios',
            'dependency_id': 2,
          },
          {
            'field_name': 'clearance_inland_egp',
            'label_ar': 'مصاريف التخليص',
            'label_en': 'Clearance Fees',
            'old_value': 3000.0,
            'new_value': 3500.0,
            'variance_amount': 500.0,
            'variance_percentage': 16.67,
            'is_hard_block': true,
            'threshold_percentage': 5.0,
            'source_entity_type': 'customs_consultation',
            'dependency_id': 3,
          },
        ],
        'has_any_variance': true,
        'has_hard_block': true,
        'max_variance_pct': 16.67,
        'blocked_by_status': false,
        'current_entity_status': 'Draft',
        'can_apply': true,
        'message_ar': 'يوجد فارق',
      };

      final response = RecalculationPreviewResponse.fromJson(json);

      expect(response.targetEntityType, 'import_budget');
      expect(response.targetEntityId, 42);
      expect(response.items.length, 2);
      expect(response.hasAnyVariance, isTrue);
      expect(response.hasHardBlock, isTrue);
      expect(response.maxVariancePct, 16.67);
      expect(response.blockedByStatus, isFalse);
      expect(response.currentEntityStatus, 'Draft');
      expect(response.canApply, isTrue);
      expect(response.messageAr, 'يوجد فارق');

      final changed = response.changedItems;
      expect(changed.length, 1);
      expect(changed.first.fieldName, 'clearance_inland_egp');
    });

    test('RecalculationApplyResult deserialization', () {
      final json = {
        'target_entity_type': 'import_budget',
        'target_entity_id': 10,
        'action_taken': 'revision_created',
        'revision_created': true,
        'new_entity_id': 11,
        'new_entity_code': 'BDG-000011',
        'log_id': 99,
        'message_ar': 'تم إنشاء مراجعة جديدة',
      };

      final result = RecalculationApplyResult.fromJson(json);

      expect(result.targetEntityType, 'import_budget');
      expect(result.targetEntityId, 10);
      expect(result.actionTaken, 'revision_created');
      expect(result.revisionCreated, isTrue);
      expect(result.newEntityId, 11);
      expect(result.newEntityCode, 'BDG-000011');
      expect(result.logId, 99);
      expect(result.messageAr, 'تم إنشاء مراجعة جديدة');
    });

    test('RecalculationDependency deserialization', () {
      final json = {
        'id': 1,
        'target_entity_type': 'import_budget',
        'target_field': 'customs_duties_egp',
        'source_entity_type': 'customs_consultation',
        'source_field': 'estimated_duties_egp',
        'join_key': 'import_file_id',
        'blocked_statuses': ['Budget Approved', 'Superseded'],
        'required_permission': 'budget.sync_variance',
        'label_ar': 'الرسوم الجمركية',
        'label_en': 'Customs Duties',
        'is_active': true,
      };

      final dep = RecalculationDependency.fromJson(json);

      expect(dep.id, 1);
      expect(dep.targetEntityType, 'import_budget');
      expect(dep.targetField, 'customs_duties_egp');
      expect(dep.sourceEntityType, 'customs_consultation');
      expect(dep.sourceField, 'estimated_duties_egp');
      expect(dep.joinKey, 'import_file_id');
      expect(dep.blockedStatuses, ['Budget Approved', 'Superseded']);
      expect(dep.requiredPermission, 'budget.sync_variance');
      expect(dep.labelAr, 'الرسوم الجمركية');
      expect(dep.labelEn, 'Customs Duties');
      expect(dep.isActive, isTrue);
    });
  });
}
