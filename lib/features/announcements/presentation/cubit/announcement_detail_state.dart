part of 'announcement_detail_cubit.dart';

abstract class AnnouncementDetailState extends Equatable {
  const AnnouncementDetailState();

  @override
  List<Object?> get props => [];
}

class AnnouncementDetailInitial extends AnnouncementDetailState {}

class AnnouncementDetailLoading extends AnnouncementDetailState {}

class AnnouncementDetailLoaded extends AnnouncementDetailState {
  final AnnouncementModel announcement;

  const AnnouncementDetailLoaded(this.announcement);

  @override
  List<Object?> get props => [announcement.id, announcement.readAt];
}

class AnnouncementDetailError extends AnnouncementDetailState {
  final String message;

  const AnnouncementDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
