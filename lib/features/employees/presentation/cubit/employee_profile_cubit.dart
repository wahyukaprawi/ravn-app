import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/employee_remote_datasource.dart';
import '../../data/models/employee_models.dart';

part 'employee_profile_state.dart';

class EmployeeProfileCubit extends Cubit<EmployeeProfileState> {
  final EmployeeRemoteDataSource remoteDataSource;
  final int employeeId;

  EmployeeProfileCubit(this.remoteDataSource, this.employeeId)
    : super(EmployeeProfileInitial());

  Future<void> load({bool includeHistory = false}) async {
    try {
      emit(EmployeeProfileLoading());
      final profile = includeHistory
          ? await remoteDataSource.getEmployeeHistory(employeeId)
          : await remoteDataSource.getEmployee(employeeId);

      emit(EmployeeProfileLoaded(profile, includeHistory: includeHistory));
    } catch (e) {
      emit(EmployeeProfileError(apiErrorMessage(e)));
    }
  }

  Future<void> toggleHistory() async {
    final current = state;
    final includeHistory = current is EmployeeProfileLoaded
        ? !current.includeHistory
        : true;
    await load(includeHistory: includeHistory);
  }
}
