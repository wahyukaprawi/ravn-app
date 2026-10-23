part of 'notification_cubit.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotificationModel> notifications;
  final bool unreadOnly;
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;
  final bool loadingMore;
  final String? loadMoreError;
  final String? actionError;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadOnly,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.unreadCount,
    this.loadingMore = false,
    this.loadMoreError,
    this.actionError,
  });

  NotificationLoaded copyWith({
    List<AppNotificationModel>? notifications,
    bool? unreadOnly,
    int? currentPage,
    int? lastPage,
    int? total,
    int? unreadCount,
    bool? loadingMore,
    String? loadMoreError,
    String? actionError,
    bool clearLoadMoreError = false,
    bool clearActionError = false,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    unreadOnly,
    currentPage,
    lastPage,
    total,
    unreadCount,
    loadingMore,
    loadMoreError,
    actionError,
  ];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
