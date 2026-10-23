import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/announcement_remote_datasource.dart';
import '../../data/models/announcement_models.dart';

part 'announcement_detail_state.dart';

class AnnouncementDetailCubit extends Cubit<AnnouncementDetailState> {
  final AnnouncementRemoteDataSource remoteDataSource;
  final int announcementId;

  AnnouncementDetailCubit(this.remoteDataSource, this.announcementId)
    : super(AnnouncementDetailInitial());

  Future<void> load() async {
    try {
      emit(AnnouncementDetailLoading());
      var announcement = await remoteDataSource.getAnnouncement(announcementId);

      try {
        announcement = await remoteDataSource.markRead(announcementId);
      } catch (_) {}

      emit(AnnouncementDetailLoaded(announcement));
    } catch (e) {
      emit(AnnouncementDetailError(apiErrorMessage(e)));
    }
  }
}
