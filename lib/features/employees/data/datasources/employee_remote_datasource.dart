import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/employee_models.dart';

class EmployeeRemoteDataSource {
  final Dio dio;

  EmployeeRemoteDataSource(this.dio);

  Future<EmployeeDirectoryPage> getEmployees({
    String? search,
    int? departmentId,
    int? positionId,
    int? workLocationId,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.employees,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (departmentId != null) 'department_id': departmentId,
        if (positionId != null) 'position_id': positionId,
        if (workLocationId != null) 'work_location_id': workLocationId,
      },
    );

    return EmployeeDirectoryPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<EmployeeProfile> getEmployee(int id) async {
    final response = await dio.get('${ApiConstants.employees}/$id');
    final data = Map<String, dynamic>.from(response.data as Map)['data'];

    return EmployeeProfile.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  Future<EmployeeProfile> getEmployeeHistory(int id) async {
    final response = await dio.get('${ApiConstants.employees}/$id/history');
    final data = Map<String, dynamic>.from(response.data as Map)['data'];

    return EmployeeProfile.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }
}
