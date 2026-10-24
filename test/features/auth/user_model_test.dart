import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/auth/data/models/user_model.dart';

void main() {
  test('user model parses the linked employee id', () {
    final user = UserModel.fromJson({
      'id': 8,
      'name': 'Ravn Employee',
      'email': 'employee@ravn.test',
      'status': 'active',
      'employee_id': 5,
      'roles': ['employee'],
      'permissions': ['employees.view'],
    });

    expect(user.employeeId, 5);
    expect(user.roles, ['employee']);
  });

  test('user model tolerates an account without an employee profile', () {
    final user = UserModel.fromJson({
      'id': 9,
      'name': 'Ravn Admin',
      'email': 'admin@ravn.test',
      'status': 'active',
      'employee_id': null,
      'roles': ['super_admin'],
      'permissions': ['users.view'],
    });

    expect(user.employeeId, isNull);
  });
}
