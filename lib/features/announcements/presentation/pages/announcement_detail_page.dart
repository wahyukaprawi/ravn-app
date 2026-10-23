import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../data/models/announcement_models.dart';
import '../cubit/announcement_cubit.dart';
import '../cubit/announcement_detail_cubit.dart';

class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnnouncementDetailCubit, AnnouncementDetailState>(
      listener: (context, state) {
        if (state is AnnouncementDetailLoaded) {
          context.read<AnnouncementCubit>().markReadLocally(
            state.announcement.id,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Announcement')),
        body: BlocBuilder<AnnouncementDetailCubit, AnnouncementDetailState>(
          builder: (context, state) {
            if (state is AnnouncementDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AnnouncementDetailError) {
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
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<AnnouncementDetailCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is AnnouncementDetailLoaded) {
              return _AnnouncementBody(announcement: state.announcement);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AnnouncementBody extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementBody({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            formatDateTime(announcement.publishedAt ?? announcement.createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          SelectableText(
            announcement.body?.isNotEmpty == true
                ? announcement.body!
                : 'No content available.',
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}
