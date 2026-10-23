part of 'announcement_cubit.dart';

abstract class AnnouncementState extends Equatable {
  const AnnouncementState();

  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {}

class AnnouncementLoading extends AnnouncementState {}

class AnnouncementLoaded extends AnnouncementState {
  final List<AnnouncementModel> announcements;
  final bool unreadOnly;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool loadingMore;
  final String? loadMoreError;

  const AnnouncementLoaded({
    required this.announcements,
    required this.unreadOnly,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  AnnouncementLoaded copyWith({
    List<AnnouncementModel>? announcements,
    bool? unreadOnly,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? loadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return AnnouncementLoaded(
      announcements: announcements ?? this.announcements,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
    announcements,
    unreadOnly,
    currentPage,
    lastPage,
    total,
    loadingMore,
    loadMoreError,
  ];
}

class AnnouncementError extends AnnouncementState {
  final String message;

  const AnnouncementError(this.message);

  @override
  List<Object?> get props => [message];
}
