part of 'leave_cubit.dart';

abstract class LeaveState extends Equatable {
  const LeaveState();

  @override
  List<Object?> get props => [];
}

class LeaveInitial extends LeaveState {}

class LeaveLoading extends LeaveState {}

class LeaveSubmitting extends LeaveState {}

class LeaveSubmitSuccess extends LeaveState {}

class LeaveLoaded extends LeaveState {
  final List<LeaveTypeModel> types;
  final List<LeaveBalanceModel> balances;
  final List<LeaveRequestModel> requests;
  final List<LeaveRequestModel> approvals;
  final List<LeaveCancellationModel> cancellations;

  const LeaveLoaded({
    required this.types,
    required this.balances,
    required this.requests,
    required this.approvals,
    required this.cancellations,
  });

  @override
  List<Object?> get props => [
    types,
    balances,
    requests,
    approvals,
    cancellations,
  ];
}

class LeaveError extends LeaveState {
  final String message;

  const LeaveError(this.message);

  @override
  List<Object?> get props => [message];
}
