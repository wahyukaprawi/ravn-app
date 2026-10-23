part of 'attendance_cubit.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final AttendanceStatusModel status;
  final List<AttendanceSessionModel> history;
  final bool isPunching;
  final String? notice;
  final bool noticeIsError;

  const AttendanceLoaded({
    required this.status,
    required this.history,
    this.isPunching = false,
    this.notice,
    this.noticeIsError = false,
  });

  AttendanceLoaded copyWith({
    AttendanceStatusModel? status,
    List<AttendanceSessionModel>? history,
    bool? isPunching,
    String? notice,
    bool? noticeIsError,
    bool clearNotice = false,
  }) {
    return AttendanceLoaded(
      status: status ?? this.status,
      history: history ?? this.history,
      isPunching: isPunching ?? this.isPunching,
      notice: clearNotice ? null : (notice ?? this.notice),
      noticeIsError: clearNotice
          ? false
          : (noticeIsError ?? this.noticeIsError),
    );
  }

  @override
  List<Object?> get props => [
    status,
    history,
    isPunching,
    notice,
    noticeIsError,
  ];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
