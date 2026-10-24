import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../data/models/notification_models.dart';
import '../cubit/notification_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationCubit, NotificationState>(
      listenWhen: (previous, current) =>
          current is NotificationLoaded && current.actionError != null,
      listener: (context, state) {
        final message = (state as NotificationLoaded).actionError;
        if (message == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<NotificationCubit>().clearActionError();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Notification settings',
              onPressed: () => context.push('/notification-settings'),
            ),
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final unread = state is NotificationLoaded
                    ? state.unreadCount
                    : 0;
                return TextButton(
                  onPressed: unread > 0
                      ? () => context.read<NotificationCubit>().markAllRead()
                      : null,
                  child: const Text('Mark all read'),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<NotificationCubit>().load(),
              );
            }

            if (state is NotificationLoaded) {
              return Column(
                children: [
                  _FilterBar(
                    unreadOnly: state.unreadOnly,
                    onChanged: (value) =>
                        context.read<NotificationCubit>().setUnreadOnly(value),
                  ),
                  Expanded(child: _buildList(state)),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildList(NotificationLoaded state) {
    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<NotificationCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(
              state.unreadOnly
                  ? HeroiconsOutline.checkCircle
                  : HeroiconsOutline.bell,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                state.unreadOnly
                    ? 'You are all caught up'
                    : 'No notifications yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<NotificationCubit>().load(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.notifications.length + 1,
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return _buildFooter(state);
          }

          final notification = state.notifications[index];
          return _NotificationCard(
            notification: notification,
            onTap: () => _openNotification(notification),
          );
        },
      ),
    );
  }

  Widget _buildFooter(NotificationLoaded state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<NotificationCubit>().loadMore(),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (state.currentPage < state.lastPage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: () => context.read<NotificationCubit>().loadMore(),
          child: const Text('Load more'),
        ),
      );
    }

    return const SizedBox(height: 8);
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    final announcementId = notification.announcementId;

    await context.read<NotificationCubit>().markRead(notification.id);

    if (!mounted) return;

    if (announcementId != null) {
      await context.push('/announcements/$announcementId');
      return;
    }

    if (notification.leaveRequestId != null) {
      await context.push('/home');
      return;
    }

    if (notification.attendanceSessionId != null) {
      await context.push('/attendance');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'Notification',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatDateTime(notification.createdAt),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              notification.body ?? 'No details available.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final bool unreadOnly;
  final ValueChanged<bool> onChanged;

  const _FilterBar({required this.unreadOnly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: !unreadOnly,
            onSelected: (_) => onChanged(false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Unread'),
            selected: unreadOnly,
            onSelected: (_) => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? AppColors.surface
              : AppColors.primaryContainer,
          child: Icon(
            notification.type == 'announcement.published'
                ? HeroiconsOutline.megaphone
                : HeroiconsOutline.bell,
            color: notification.isRead
                ? AppColors.textMuted
                : AppColors.primaryStrong,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title ?? 'Notification',
                style: TextStyle(
                  fontWeight: notification.isRead
                      ? FontWeight.w500
                      : FontWeight.w700,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryStrong,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.body != null)
                Text(
                  notification.body!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                formatDateTime(notification.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              HeroiconsOutline.exclamationTriangle,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
