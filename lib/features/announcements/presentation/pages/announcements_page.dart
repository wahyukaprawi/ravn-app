import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../data/models/announcement_models.dart';
import '../cubit/announcement_cubit.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AnnouncementCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<AnnouncementCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<AnnouncementCubit, AnnouncementState>(
        builder: (context, state) {
          if (state is AnnouncementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnnouncementError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<AnnouncementCubit>().load(),
            );
          }

          if (state is AnnouncementLoaded) {
            return Column(
              children: [
                _FilterBar(
                  unreadOnly: state.unreadOnly,
                  onChanged: (value) =>
                      context.read<AnnouncementCubit>().setUnreadOnly(value),
                ),
                Expanded(child: _buildList(state)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(AnnouncementLoaded state) {
    if (state.announcements.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AnnouncementCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(
              state.unreadOnly
                  ? HeroiconsOutline.checkCircle
                  : HeroiconsOutline.megaphone,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                state.unreadOnly
                    ? 'No unread announcements'
                    : 'No announcements yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AnnouncementCubit>().load(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.announcements.length + 1,
        itemBuilder: (context, index) {
          if (index == state.announcements.length) {
            return _buildFooter(state);
          }

          final announcement = state.announcements[index];
          return _AnnouncementCard(
            announcement: announcement,
            onTap: () => _openDetail(announcement),
          );
        },
      ),
    );
  }

  Widget _buildFooter(AnnouncementLoaded state) {
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
              onPressed: () => context.read<AnnouncementCubit>().loadMore(),
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
          onPressed: () => context.read<AnnouncementCubit>().loadMore(),
          child: const Text('Load more'),
        ),
      );
    }

    return const SizedBox(height: 8);
  }

  Future<void> _openDetail(AnnouncementModel announcement) async {
    await context.push('/announcements/${announcement.id}');
    if (!mounted) return;
    await context.read<AnnouncementCubit>().load();
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

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Icon(
            HeroiconsOutline.megaphone,
            color: AppColors.primaryStrong,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (!announcement.isRead)
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
          child: Text(
            formatDateTime(announcement.publishedAt ?? announcement.createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
