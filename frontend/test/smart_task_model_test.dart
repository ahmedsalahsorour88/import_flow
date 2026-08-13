import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/smart_tasks/models/smart_task_model.dart';

void main() {
  group('SmartTaskModel Unit Tests (Feature 2.4 & 2.5)', () {
    test('Should parse SmartTaskModel from JSON correctly', () {
      final json = {
        'task_id': 1,
        'task_code': 'TSK-2026-0001',
        'title': 'متابعة صدور نموذج 4 من بنك مصر',
        'description': 'متابعة قسم الاعتماد البنكي للمستندات',
        'task_type': 'Manual To-Do',
        'import_file_id': 5,
        'import_file_code': 'IMP-2026-005',
        'phase_name': 'Phase 3 - Import Documentation',
        'assigned_user': 'Kamal',
        'priority': 'High',
        'reminder_type': 'Bank Form 4',
        'due_date': '2026-08-20',
        'reminder_date': '2026-08-18',
        'status': 'Pending',
        'notes': 'ملاحظات هامة للبنك',
        'attachment_url': null,
        'is_auto_closed': false,
        'is_active': true,
        'created_at': '2026-08-13T12:00:00',
        'created_by': 'Kamal',
      };

      final model = SmartTaskModel.fromJson(json);

      expect(model.taskId, equals(1));
      expect(model.taskCode, equals('TSK-2026-0001'));
      expect(model.title, equals('متابعة صدور نموذج 4 من بنك مصر'));
      expect(model.taskType, equals('Manual To-Do'));
      expect(model.priority, equals('High'));
      expect(model.reminderType, equals('Bank Form 4'));
      expect(model.status, equals('Pending'));
    });

    test('Should parse SmartTaskSummaryMetricsModel from JSON correctly', () {
      final json = {
        'total_tasks': 15,
        'todays_tasks': 3,
        'pending_tasks': 8,
        'upcoming_shipments': 10,
        'arriving_this_week': 4,
        'eta_changes': 2,
        'waiting_for_payment': 3,
        'waiting_for_form4': 5,
        'pending_requirements': 4,
        'high_priority_alerts': 2,
      };

      final metrics = SmartTaskSummaryMetricsModel.fromJson(json);

      expect(metrics.totalTasks, equals(15));
      expect(metrics.todaysTasks, equals(3));
      expect(metrics.pendingTasks, equals(8));
      expect(metrics.upcomingShipments, equals(10));
      expect(metrics.arrivingThisWeek, equals(4));
      expect(metrics.etaChanges, equals(2));
      expect(metrics.waitingForPayment, equals(3));
      expect(metrics.waitingForForm4, equals(5));
      expect(metrics.pendingRequirements, equals(4));
      expect(metrics.highPriorityAlerts, equals(2));
    });
  });
}
