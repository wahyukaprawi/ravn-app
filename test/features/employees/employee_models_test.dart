import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/employees/data/models/employee_models.dart';

void main() {
  test('employee directory page parses summaries and pagination', () {
    final page = EmployeeDirectoryPage.fromJson({
      'data': [
        {
          'id': 5,
          'employee_no': 'EMP-005',
          'full_name': 'Ravn Employee',
          'first_name': 'Ravn',
          'last_name': 'Employee',
          'work_email': 'employee@ravn.test',
          'hire_date': '2026-01-05',
          'current_assignment': {
            'id': 9,
            'department': {'id': 1, 'code': 'ENG', 'name': 'Engineering'},
            'position': {'id': 2, 'code': 'DEV', 'name': 'Developer'},
            'manager': {
              'id': 3,
              'name': 'Ravn Manager',
              'email': 'manager@ravn.test',
            },
            'work_location': {
              'id': 4,
              'code': 'HQ',
              'name': 'Head Office',
              'timezone': 'Asia/Manila',
            },
            'effective_from': '2026-01-05',
            'effective_to': null,
            'status': 'active',
          },
        },
      ],
      'meta': {'current_page': 1, 'per_page': 20, 'total': 1, 'last_page': 1},
    });

    expect(page.employees, hasLength(1));
    expect(page.total, 1);
    final employee = page.employees.single;
    expect(employee.fullName, 'Ravn Employee');
    expect(employee.initials, 'RE');
    expect(employee.roleLabel, 'Developer · Engineering');
    expect(employee.currentAssignment?.workLocation?.timezone, 'Asia/Manila');
  });

  test('employee profile parses history collections', () {
    final profile = EmployeeProfile.fromJson({
      'id': 5,
      'employee_no': 'EMP-005',
      'full_name': 'Ravn Employee',
      'phone': '+63 900 000 0000',
      'work_email': 'employee@ravn.test',
      'hire_date': '2026-01-05',
      'user': {
        'id': 8,
        'name': 'Ravn Employee',
        'email': 'employee@ravn.test',
        'status': 'active',
      },
      'current_employment': {
        'id': 10,
        'employment_type': 'regular',
        'effective_from': '2026-01-05',
        'effective_to': null,
        'status': 'active',
      },
      'current_assignment': {
        'id': 9,
        'department': {'id': 1, 'code': 'ENG', 'name': 'Engineering'},
        'position': {'id': 2, 'code': 'DEV', 'name': 'Developer'},
        'manager': {
          'id': 3,
          'name': 'Ravn Manager',
          'email': 'manager@ravn.test',
        },
        'work_location': {
          'id': 4,
          'code': 'HQ',
          'name': 'Head Office',
          'timezone': 'Asia/Manila',
        },
        'effective_from': '2026-01-05',
        'effective_to': null,
        'status': 'active',
      },
      'employments': [
        {
          'id': 10,
          'employment_type': 'regular',
          'effective_from': '2026-01-05',
          'effective_to': null,
          'status': 'active',
        },
      ],
      'assignments': [
        {
          'id': 9,
          'department': {'id': 1, 'code': 'ENG', 'name': 'Engineering'},
          'position': {'id': 2, 'code': 'DEV', 'name': 'Developer'},
          'effective_from': '2026-01-05',
          'effective_to': null,
          'status': 'active',
        },
      ],
    });

    expect(profile.fullName, 'Ravn Employee');
    expect(profile.user?.email, 'employee@ravn.test');
    expect(profile.currentEmployment?.employmentType, 'regular');
    expect(profile.employments, hasLength(1));
    expect(profile.assignments.single.position?.name, 'Developer');
  });
}
