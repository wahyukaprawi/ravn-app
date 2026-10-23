import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_models.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationCubit(this.remoteDataSource) : super(NotificationInitial());

  Future<void> load({bool? unreadOnly}) async {
    final filter = unreadOnly ?? _currentFilter;

    try {
      emit(NotificationLoading());
      final page = await remoteDataSource.getNotifications(unreadOnly: filter);
      final unreadCount = filter
          ? page.total
          : await remoteDataSource.getUnreadCount();

      emit(
        NotificationLoaded(
          notifications: page.notifications,
          unreadOnly: filter,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError(apiErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationLoaded ||
        current.loadingMore ||
        current.currentPage >= current.lastPage) {
      return;
    }

    emit(current.copyWith(loadingMore: true, clearLoadMoreError: true));

    try {
      final page = await remoteDataSource.getNotifications(
        unreadOnly: current.unreadOnly,
        page: current.currentPage + 1,
      );
      final existingIds = current.notifications.map((item) => item.id).toSet();
      final additions = page.notifications
          .where((item) => !existingIds.contains(item.id))
          .toList();

      emit(
        current.copyWith(
          notifications: [...current.notifications, ...additions],
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

  void clear() => emit(NotificationInitial());

  Future<void> markRead(int id) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    final index = current.notifications.indexWhere((item) => item.id == id);
    if (index == -1 || current.notifications[index].isRead) return;

    try {
      final updated = await remoteDataSource.markRead(id);
      final notifications = [...current.notifications];

      if (current.unreadOnly) {
        notifications.removeAt(index);
      } else {
        notifications[index] = updated;
      }

      emit(
        current.copyWith(
          notifications: notifications,
          total: current.unreadOnly ? max(0, current.total - 1) : current.total,
          unreadCount: max(0, current.unreadCount - 1),
          clearActionError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(actionError: apiErrorMessage(e)));
    }
  }

  Future<void> markAllRead() async {
    final current = state;
    if (current is! NotificationLoaded) return;

    try {
      await remoteDataSource.markAllRead();
      final readAt = DateTime.now().toIso8601String();

      emit(
        current.copyWith(
          notifications: current.unreadOnly
              ? const []
              : current.notifications
                    .map(
                      (item) =>
                          item.isRead ? item : item.copyWith(readAt: readAt),
                    )
                    .toList(),
          total: current.unreadOnly ? 0 : current.total,
          unreadCount: 0,
          clearActionError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(actionError: apiErrorMessage(e)));
    }
  }

  void clearActionError() {
    final current = state;
    if (current is NotificationLoaded && current.actionError != null) {
      emit(current.copyWith(clearActionError: true));
    }
  }

  bool get _currentFilter {
    final current = state;
    return current is NotificationLoaded && current.unreadOnly;
  }
}
