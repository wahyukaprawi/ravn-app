import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/announcement_remote_datasource.dart';
import '../../data/models/announcement_models.dart';

part 'announcement_state.dart';

class AnnouncementCubit extends Cubit<AnnouncementState> {
  final AnnouncementRemoteDataSource remoteDataSource;

  AnnouncementCubit(this.remoteDataSource) : super(AnnouncementInitial());

  Future<void> load({bool? unreadOnly}) async {
    final filter = unreadOnly ?? _currentFilter;
    try {
      emit(AnnouncementLoading());
      final page = await remoteDataSource.getAnnouncements(unreadOnly: filter);
      emit(
        AnnouncementLoaded(
          announcements: page.announcements,
          unreadOnly: filter,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
        ),
      );
    } catch (e) {
      emit(AnnouncementError(apiErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! AnnouncementLoaded ||
        current.loadingMore ||
        current.currentPage >= current.lastPage) {
      return;
    }

    emit(current.copyWith(loadingMore: true, clearLoadMoreError: true));

    try {
      final page = await remoteDataSource.getAnnouncements(
        unreadOnly: current.unreadOnly,
        page: current.currentPage + 1,
      );
      final existingIds = current.announcements.map((item) => item.id).toSet();
      final additions = page.announcements
          .where((item) => !existingIds.contains(item.id))
          .toList();

      emit(
        current.copyWith(
          announcements: [...current.announcements, ...additions],
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          loadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(loadingMore: false, loadMoreError: apiErrorMessage(e)),
      );
    }
  }

  Future<void> setUnreadOnly(bool unreadOnly) => load(unreadOnly: unreadOnly);

  void clear() => emit(AnnouncementInitial());

  void markReadLocally(int id) {
    final current = state;
    if (current is! AnnouncementLoaded) return;

    final index = current.announcements.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final announcements = [...current.announcements];
    announcements[index] = announcements[index].copyWith(
      readAt: DateTime.now().toIso8601String(),
    );
    emit(current.copyWith(announcements: announcements));
  }

  bool get _currentFilter {
    final current = state;
    return current is AnnouncementLoaded && current.unreadOnly;
  }
}
