import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/leave_remote_datasource.dart';
import '../../data/models/leave_models.dart';

part 'leave_state.dart';

class LeaveCubit extends Cubit<LeaveState> {
  final LeaveRemoteDataSource remoteDataSource;

  LeaveCubit(this.remoteDataSource) : super(LeaveInitial());

  Future<void> loadLeaveData() async {
    try {
      emit(LeaveLoading());
      final types = await remoteDataSource.getLeaveTypes();
      final balances = await remoteDataSource.getBalances(
        year: DateTime.now().year,
      );
      final requests = await remoteDataSource.getRequests(scope: 'mine');

      List<LeaveRequestModel> approvals = const [];
      List<LeaveCancellationModel> cancellations = const [];
      try {
        approvals = await remoteDataSource.getApprovals();
        cancellations = await remoteDataSource.getCancellations();
      } on DioException catch (error) {
        if (error.response?.statusCode != 403) rethrow;
      }

      emit(
        LeaveLoaded(
          types: types,
          balances: balances,
          requests: requests,
          approvals: approvals,
          cancellations: cancellations,
        ),
      );
    } catch (e) {
      emit(LeaveError(apiErrorMessage(e)));
    }
  }

  Future<void> submitRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    try {
      emit(LeaveSubmitting());
      await remoteDataSource.submitRequest(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      emit(LeaveSubmitSuccess());
      await loadLeaveData();
    } catch (e) {
      emit(LeaveError(apiErrorMessage(e)));
    }
  }

  Future<bool?> cancelRequest(int requestId, String reason) async {
    try {
      final response = await remoteDataSource.cancelRequest(requestId, reason);
      final needsApproval = response['cancellation'] != null;
      await loadLeaveData();
      return needsApproval;
    } catch (e) {
      emit(LeaveError(apiErrorMessage(e)));
      return null;
    }
  }

  Future<void> decideApproval(
    int requestId,
    String action, {
    String? reason,
  }) async {
    try {
      await remoteDataSource.decideApproval(requestId, action, reason: reason);
      await loadLeaveData();
    } catch (e) {
      emit(LeaveError(apiErrorMessage(e)));
    }
  }

  Future<void> decideCancellation(
    int cancellationId,
    String action, {
    String? reason,
  }) async {
    try {
      await remoteDataSource.decideCancellation(
        cancellationId,
        action,
        reason: reason,
      );
      await loadLeaveData();
    } catch (e) {
      emit(LeaveError(apiErrorMessage(e)));
    }
  }
}
