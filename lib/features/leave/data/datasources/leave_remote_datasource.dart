import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/leave_models.dart';

class LeaveRemoteDataSource {
  final Dio dio;
  final _uuid = const Uuid();

  LeaveRemoteDataSource(this.dio);

  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    final response = await dio.get(ApiConstants.leaveTypes);
    final result = LeaveTypesResponse.fromJson(response.data);
    return result.data;
  }

  Future<List<LeaveBalanceModel>> getBalances({int? year}) async {
    final response = await dio.get(
      ApiConstants.leaveBalances,
      queryParameters: {if (year != null) 'year': year},
    );
    final result = LeaveBalanceListResponse.fromJson(response.data);
    return result.data;
  }

  Future<List<LeaveRequestModel>> getRequests({
    String scope = 'mine',
    String? status,
  }) async {
    final response = await dio.get(
      ApiConstants.leaveRequests,
      queryParameters: {'scope': scope, if (status != null) 'status': status},
    );
    final result = LeaveListResponse.fromJson(response.data);
    return result.data;
  }

  Future<LeaveRequestModel> getRequest(int id) async {
    final response = await dio.get('${ApiConstants.leaveRequests}/$id');
    final result = LeaveRequestResponse.fromJson(response.data);
    return result.data;
  }

  Future<LeaveRequestModel> submitRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final response = await dio.post(
      ApiConstants.leaveRequests,
      data: {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final result = LeaveRequestResponse.fromJson(response.data);
    return result.data;
  }

  Future<Map<String, dynamic>> cancelRequest(int id, String reason) async {
    final response = await dio.post(
      '${ApiConstants.leaveRequests}/$id/cancel',
      data: {'reason': reason},
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    return response.data;
  }

  Future<LeaveRequestModel> assignApprover(int requestId, int managerId) async {
    final response = await dio.post(
      '${ApiConstants.leaveRequests}/$requestId/assign-approver',
      data: {'manager_id': managerId},
    );
    final result = LeaveRequestResponse.fromJson(response.data);
    return result.data;
  }

  Future<List<LeaveRequestModel>> getApprovals() async {
    final response = await dio.get(ApiConstants.leaveApprovals);
    final result = LeaveListResponse.fromJson(response.data);
    return result.data;
  }

  Future<LeaveRequestModel> decideApproval(
    int requestId,
    String action, {
    String? reason,
  }) async {
    final response = await dio.post(
      '${ApiConstants.leaveApprovals}/$requestId/decision',
      data: {
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final result = LeaveRequestResponse.fromJson(response.data);
    return result.data;
  }

  Future<List<LeaveCancellationModel>> getCancellations() async {
    final response = await dio.get(ApiConstants.leaveCancellations);
    final result = LeaveCancellationListResponse.fromJson(response.data);
    return result.data;
  }

  Future<LeaveCancellationModel> decideCancellation(
    int cancellationId,
    String action, {
    String? reason,
  }) async {
    final response = await dio.post(
      '${ApiConstants.leaveCancellations}/$cancellationId/decision',
      data: {
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final result = LeaveCancellationResponse.fromJson(response.data);
    return result.data;
  }
}
