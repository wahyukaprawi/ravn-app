import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:ravn/features/employees/data/models/employee_models.dart';
import 'package:ravn/features/employees/presentation/cubit/employee_directory_cubit.dart';
import 'package:ravn/features/employees/presentation/cubit/employee_profile_cubit.dart';

void main() {
  group('EmployeeDirectoryCubit', () {
    test('loads, searches and paginates without duplicates', () async {
      final remote = _FakeEmployeeRemoteDataSource(_employees);
      final cubit = EmployeeDirectoryCubit(remote);

      await cubit.load();

      final loaded = cubit.state as EmployeeDirectoryLoaded;
      expect(loaded.employees, hasLength(2));
      expect(loaded.total, 3);
      expect(loaded.currentPage, 1);
      expect(loaded.lastPage, 2);

      await cubit.loadMore();

      final paginated = cubit.state as EmployeeDirectoryLoaded;
      expect(paginated.employees, hasLength(3));
      expect(paginated.employees.last.id, 3);
      expect(paginated.currentPage, 2);

      await cubit.search('employee two');

      final searched = cubit.state as EmployeeDirectoryLoaded;
      expect(searched.query, 'employee two');
      expect(searched.employees, hasLength(1));
      expect(remote.lastSearch, 'employee two');

      await cubit.close();
    });

    test('surfaces a load failure', () async {
      final remote = _FakeEmployeeRemoteDataSource(_employees, failLoad: true);
      final cubit = EmployeeDirectoryCubit(remote);

      await cubit.load();

      expect(cubit.state, isA<EmployeeDirectoryError>());

      await cubit.close();
    });
  });

  group('EmployeeProfileCubit', () {
    test('loads current profile and toggles history', () async {
      final remote = _FakeEmployeeRemoteDataSource(_employees);
      final cubit = EmployeeProfileCubit(remote, 1);

      await cubit.load();

      final loaded = cubit.state as EmployeeProfileLoaded;
      expect(loaded.profile.fullName, 'Employee One');
      expect(loaded.includeHistory, isFalse);

      await cubit.toggleHistory();

      final history = cubit.state as EmployeeProfileLoaded;
      expect(history.includeHistory, isTrue);
      expect(history.profile.employments, hasLength(1));
      expect(remote.historyRequested, isTrue);

      await cubit.close();
    });
  });
}

const _employees = [
  EmployeeSummary(
    id: 1,
    employeeNo: 'EMP-001',
    fullName: 'Employee One',
    workEmail: 'one@ravn.test',
  ),
  EmployeeSummary(
    id: 2,
    employeeNo: 'EMP-002',
    fullName: 'Employee Two',
    workEmail: 'two@ravn.test',
  ),
  EmployeeSummary(
    id: 3,
    employeeNo: 'EMP-003',
    fullName: 'Employee Three',
    workEmail: 'three@ravn.test',
  ),
];

class _FakeEmployeeRemoteDataSource extends EmployeeRemoteDataSource {
  _FakeEmployeeRemoteDataSource(this.employees, {this.failLoad = false})
    : super(Dio());

  final List<EmployeeSummary> employees;
  final bool failLoad;
  String? lastSearch;
  bool historyRequested = false;

  @override
  Future<EmployeeDirectoryPage> getEmployees({
    String? search,
    int? departmentId,
    int? positionId,
    int? workLocationId,
    int page = 1,
    int perPage = 20,
  }) async {
    if (failLoad) throw StateError('network down');

    lastSearch = search;
    final filtered = search == null || search.trim().isEmpty
        ? employees
        : employees
              .where(
                (item) =>
                    item.fullName.toLowerCase().contains(search.toLowerCase()),
              )
              .toList();
    const pageSize = 2;
    final start = (page - 1) * pageSize;
    final items = start >= filtered.length
        ? <EmployeeSummary>[]
        : filtered.skip(start).take(pageSize).toList();

    return EmployeeDirectoryPage(
      employees: items,
      currentPage: page,
      perPage: pageSize,
      total: filtered.length,
      lastPage: (filtered.length / pageSize).ceil(),
    );
  }

  @override
  Future<EmployeeProfile> getEmployee(int id) async {
    return _profileFor(id, includeHistory: false);
  }

  @override
  Future<EmployeeProfile> getEmployeeHistory(int id) async {
    historyRequested = true;
    return _profileFor(id, includeHistory: true);
  }

  EmployeeProfile _profileFor(int id, {required bool includeHistory}) {
    final employee = employees.firstWhere((item) => item.id == id);

    return EmployeeProfile(
      id: employee.id,
      employeeNo: employee.employeeNo,
      fullName: employee.fullName,
      workEmail: employee.workEmail,
      employments: includeHistory
          ? const [
              EmployeeEmploymentInfo(
                id: 1,
                employmentType: 'regular',
                effectiveFrom: '2026-01-05',
                status: 'active',
              ),
            ]
          : const [],
      assignments: includeHistory
          ? const [
              EmployeeAssignmentInfo(
                id: 1,
                effectiveFrom: '2026-01-05',
                status: 'active',
              ),
            ]
          : const [],
    );
  }
}
