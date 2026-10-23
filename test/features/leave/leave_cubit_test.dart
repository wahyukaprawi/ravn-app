import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/leave/data/datasources/leave_remote_datasource.dart';
import 'package:ravn/features/leave/data/models/leave_models.dart';
import 'package:ravn/features/leave/presentation/cubit/leave_cubit.dart';

void main() {
  group('LeaveCubit', () {
    test(
      'loads balances and requests for an employee without approval permission',
      () async {
        final cubit = LeaveCubit(
          _FakeLeaveRemoteDataSource(
            approvalsError: DioException(
              requestOptions: RequestOptions(path: '/leave/approvals'),
              response: Response(
                requestOptions: RequestOptions(path: '/leave/approvals'),
                statusCode: 403,
              ),
            ),
          ),
        );

        final states = <LeaveState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.loadLeaveData();
        await Future<void>.delayed(Duration.zero);

        expect(states.first, isA<LeaveLoading>());
        final loaded = states.last;
        expect(loaded, isA<LeaveLoaded>());
        expect((loaded as LeaveLoaded).requests, hasLength(1));
        expect(loaded.balances, hasLength(1));
        expect(loaded.approvals, isEmpty);
        expect(loaded.cancellations, isEmpty);

        await subscription.cancel();
        await cubit.close();
      },
    );

    test('surfaces a failure of the essential leave endpoints', () async {
      final cubit = LeaveCubit(
        _FakeLeaveRemoteDataSource(typesError: StateError('network down')),
      );

      final states = <LeaveState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadLeaveData();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<LeaveError>());

      await subscription.cancel();
      await cubit.close();
    });
  });
}

class _FakeLeaveRemoteDataSource extends LeaveRemoteDataSource {
  _FakeLeaveRemoteDataSource({this.typesError, this.approvalsError})
    : super(Dio());

  final Object? typesError;
  final Object? approvalsError;

  static const _type = LeaveTypeModel(
    id: 1,
    code: 'annual',
    name: 'Annual Leave',
    requiresApproval: true,
    policies: [],
  );

  static const _employee = UserInfo(
    id: 2,
    name: 'Employee',
    email: 'employee@example.test',
  );

  @override
  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    if (typesError != null) throw typesError!;
    return const [_type];
  }

  @override
  Future<List<LeaveBalanceModel>> getBalances({int? year}) async {
    return [
      LeaveBalanceModel(
        leaveType: const LeaveTypeInfo(
          id: 1,
          code: 'annual',
          name: 'Annual Leave',
        ),
        year: year ?? 2026,
        entitled: 12,
        used: 2,
        reserved: 1,
        adjusted: 0,
        available: 9,
      ),
    ];
  }

  @override
  Future<List<LeaveRequestModel>> getRequests({
    String scope = 'mine',
    String? status,
  }) async {
    return const [
      LeaveRequestModel(
        id: 9,
        status: 'pending',
        employee: _employee,
        leaveType: LeaveTypeInfo(id: 1, code: 'annual', name: 'Annual Leave'),
        startDate: '2026-10-26',
        endDate: '2026-10-27',
        days: 2,
      ),
    ];
  }

  @override
  Future<List<LeaveRequestModel>> getApprovals() async {
    if (approvalsError != null) throw approvalsError!;
    return const [];
  }

  @override
  Future<List<LeaveCancellationModel>> getCancellations() async {
    if (approvalsError != null) throw approvalsError!;
    return const [];
  }
}
