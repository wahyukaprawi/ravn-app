import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/models/attendance_models.dart';
import '../../domain/attendance_location_service.dart';
import '../../domain/device_identity_service.dart';
import '../../domain/face_verification_service.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRemoteDataSource remoteDataSource;
  final AttendanceLocationService locationService;
  final FaceVerificationService faceVerificationService;
  final DeviceIdentityService deviceIdentityService;

  AttendanceCubit(
    this.remoteDataSource,
    this.locationService,
    this.faceVerificationService,
    this.deviceIdentityService,
  ) : super(AttendanceInitial());

  Future<void> load() async {
    try {
      emit(AttendanceLoading());
      final status = await remoteDataSource.getStatus();
      final history = await remoteDataSource.getHistory();
      emit(AttendanceLoaded(status: status, history: history));
    } catch (error) {
      emit(AttendanceError(apiErrorMessage(error)));
    }
  }

  void clearNotice() {
    final current = state;
    if (current is AttendanceLoaded && current.notice != null) {
      emit(current.copyWith(clearNotice: true));
    }
  }

  Future<void> punch({required bool checkIn}) async {
    final current = state;
    if (current is! AttendanceLoaded || current.isPunching) return;

    emit(current.copyWith(isPunching: true, clearNotice: true));

    var recorded = false;

    try {
      final location = await locationService.currentLocation();
      final deviceId = await deviceIdentityService.getOrCreate();
      final challengeId = await remoteDataSource.createChallenge(
        deviceId: deviceId,
      );

      if (challengeId.isEmpty) {
        throw StateError('The server did not return a face challenge.');
      }

      final verified = await faceVerificationService.verify(challengeId);
      if (!verified) {
        emit(
          current.copyWith(
            isPunching: false,
            notice:
                'Face verification is not configured in this build. Check-in is disabled until the on-device engine is integrated.',
            noticeIsError: true,
          ),
        );
        return;
      }

      if (checkIn) {
        await remoteDataSource.checkIn(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyMeters: location.accuracyMeters,
          mocked: location.mocked,
          deviceId: deviceId,
          challengeId: challengeId,
          faceVerified: true,
        );
      } else {
        await remoteDataSource.checkOut(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyMeters: location.accuracyMeters,
          mocked: location.mocked,
          deviceId: deviceId,
          challengeId: challengeId,
          faceVerified: true,
        );
      }

      recorded = true;

      final status = await remoteDataSource.getStatus();
      final history = await remoteDataSource.getHistory();

      emit(
        AttendanceLoaded(
          status: status,
          history: history,
          notice: checkIn ? 'Checked in.' : 'Checked out.',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isPunching: false,
          notice: recorded
              ? 'Attendance was recorded, but the latest status could not be loaded. Pull to refresh.'
              : apiErrorMessage(error),
          noticeIsError: true,
        ),
      );
    }
  }
}
