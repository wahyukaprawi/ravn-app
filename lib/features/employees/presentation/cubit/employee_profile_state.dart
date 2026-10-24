part of 'employee_profile_cubit.dart';

abstract class EmployeeProfileState extends Equatable {
  const EmployeeProfileState();

  @override
  List<Object?> get props => [];
}

class EmployeeProfileInitial extends EmployeeProfileState {}

class EmployeeProfileLoading extends EmployeeProfileState {}

class EmployeeProfileLoaded extends EmployeeProfileState {
  final EmployeeProfile profile;
  final bool includeHistory;

  const EmployeeProfileLoaded(this.profile, {required this.includeHistory});

  @override
  List<Object?> get props => [profile, includeHistory];
}

class EmployeeProfileError extends EmployeeProfileState {
  final String message;

  const EmployeeProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
