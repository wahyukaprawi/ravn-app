import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/leave/data/models/leave_models.dart';

void main() {
  test('leave request parses the backend payload including workflow steps', () {
    final request = LeaveRequestResponse.fromJson({
      'data': {
        'id': 7,
        'status': 'pending',
        'employee': {
          'id': 2,
          'name': 'Employee',
          'email': 'employee@example.test',
        },
        'leave_type': {'id': 1, 'code': 'annual', 'name': 'Annual Leave'},
        'manager': {
          'id': 3,
          'name': 'Manager',
          'email': 'manager@example.test',
        },
        'start_date': '2026-10-26',
        'end_date': '2026-10-27',
        'days': 2,
        'reason': 'Family event',
        'submitted_at': '2026-10-23T08:00:00Z',
        'workflow': {
          'id': 4,
          'status': 'active',
          'current_step': {
            'key': 'manager',
            'position': 1,
            'status': 'active',
            'assignee_type': 'user',
            'assignee_id': 3,
            'assignee_name': 'Manager',
          },
          'steps': [
            {
              'key': 'manager',
              'position': 1,
              'status': 'active',
              'assignee_type': 'user',
              'assignee_id': 3,
              'assignee_name': 'Manager',
            },
            {
              'key': 'hr_admin',
              'position': 2,
              'status': 'pending',
              'assignee_type': 'role',
              'assignee_id': 2,
              'assignee_name': 'Hr admin',
            },
          ],
        },
      },
    }).data;

    expect(request.id, 7);
    expect(request.status, 'pending');
    expect(request.employee.name, 'Employee');
    expect(request.leaveType?.name, 'Annual Leave');
    expect(request.manager?.name, 'Manager');
    expect(request.days, 2);
    expect(request.workflow?.currentStep?.assigneeName, 'Manager');
    expect(request.workflow?.steps, hasLength(2));
    expect(request.workflow?.steps.last.assigneeName, 'Hr admin');
  });

  test('balance parser keeps the server-computed available amount', () {
    final balances = LeaveBalanceListResponse.fromJson({
      'data': [
        {
          'leave_type': {'id': 1, 'code': 'annual', 'name': 'Annual Leave'},
          'year': 2026,
          'entitled': 12,
          'used': 3,
          'reserved': 2,
          'adjusted': 0,
          'available': 7,
        },
      ],
      'meta': {'year': 2026},
    }).data;

    expect(balances, hasLength(1));
    expect(balances.single.leaveType.code, 'annual');
    expect(balances.single.available, 7);
  });

  test('cancellation parser reads the requester and workflow state', () {
    final cancellations = LeaveCancellationListResponse.fromJson({
      'data': [
        {
          'id': 3,
          'leave_request_id': 9,
          'status': 'pending',
          'reason': 'Plans changed',
          'requester': {
            'id': 2,
            'name': 'Employee',
            'email': 'employee@example.test',
          },
          'manager': {
            'id': 4,
            'name': 'Manager',
            'email': 'manager@example.test',
          },
          'decided_by': null,
          'decided_at': null,
          'workflow': {
            'id': 5,
            'status': 'in_progress',
            'current_step': {
              'key': 'manager',
              'position': 1,
              'status': 'active',
              'assignee_type': 'user',
              'assignee_id': 4,
              'assignee_name': 'Manager',
            },
            'steps': const [],
          },
          'created_at': '2026-10-23T08:00:00Z',
        },
      ],
      'meta': {'total': 1},
    }).data;

    expect(cancellations, hasLength(1));
    expect(cancellations.single.leaveRequestId, 9);
    expect(cancellations.single.requester.name, 'Employee');
    expect(cancellations.single.workflow?.currentStep?.assigneeName, 'Manager');
  });
}
