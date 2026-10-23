import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/announcements/data/datasources/announcement_remote_datasource.dart';
import 'package:ravn/features/announcements/data/models/announcement_models.dart';
import 'package:ravn/features/announcements/presentation/cubit/announcement_cubit.dart';
import 'package:ravn/features/announcements/presentation/cubit/announcement_detail_cubit.dart';

void main() {
  group('AnnouncementCubit', () {
    test('loads the first page and paginates without duplicates', () async {
      final remote = _FakeAnnouncementRemoteDataSource(_announcements);
      final cubit = AnnouncementCubit(remote);

      await cubit.load();

      final loaded = cubit.state as AnnouncementLoaded;
      expect(loaded.announcements, hasLength(2));
      expect(loaded.total, 3);
      expect(loaded.currentPage, 1);
      expect(loaded.lastPage, 2);

      await cubit.loadMore();

      final paginated = cubit.state as AnnouncementLoaded;
      expect(paginated.announcements, hasLength(3));
      expect(paginated.announcements.last.id, 3);
      expect(paginated.currentPage, 2);

      await cubit.close();
    });

    test('filters unread announcements and marks a row read locally', () async {
      final remote = _FakeAnnouncementRemoteDataSource(_announcements);
      final cubit = AnnouncementCubit(remote);

      await cubit.setUnreadOnly(true);

      final filtered = cubit.state as AnnouncementLoaded;
      expect(filtered.unreadOnly, isTrue);
      expect(remote.lastUnreadOnly, isTrue);
      expect(filtered.announcements, hasLength(2));

      cubit.markReadLocally(1);

      final updated = cubit.state as AnnouncementLoaded;
      expect(updated.announcements.first.isRead, isTrue);

      await cubit.close();
    });

    test('surfaces a load failure', () async {
      final remote = _FakeAnnouncementRemoteDataSource(
        _announcements,
        failLoad: true,
      );
      final cubit = AnnouncementCubit(remote);

      await cubit.load();

      expect(cubit.state, isA<AnnouncementError>());

      await cubit.close();
    });
  });

  group('AnnouncementDetailCubit', () {
    test('loads the body and marks the announcement read', () async {
      final remote = _FakeAnnouncementRemoteDataSource(_announcements);
      final cubit = AnnouncementDetailCubit(remote, 1);

      await cubit.load();

      final loaded = cubit.state as AnnouncementDetailLoaded;
      expect(loaded.announcement.body, 'Body for one');
      expect(loaded.announcement.isRead, isTrue);
      expect(remote.markedReadIds, [1]);

      await cubit.close();
    });
  });
}

final _announcements = [
  const AnnouncementModel(
    id: 1,
    title: 'One',
    status: 'published',
    publishedAt: '2026-10-23T09:00:00+00:00',
  ),
  const AnnouncementModel(
    id: 2,
    title: 'Two',
    status: 'published',
    publishedAt: '2026-10-23T08:00:00+00:00',
    readAt: '2026-10-23T10:00:00+00:00',
  ),
  const AnnouncementModel(
    id: 3,
    title: 'Three',
    status: 'published',
    publishedAt: '2026-10-23T07:00:00+00:00',
  ),
];

class _FakeAnnouncementRemoteDataSource extends AnnouncementRemoteDataSource {
  _FakeAnnouncementRemoteDataSource(this.announcements, {this.failLoad = false})
    : super(Dio());

  final List<AnnouncementModel> announcements;
  final bool failLoad;
  bool? lastUnreadOnly;
  final List<int> markedReadIds = [];

  @override
  Future<AnnouncementPage> getAnnouncements({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    if (failLoad) throw StateError('network down');

    lastUnreadOnly = unreadOnly;
    final filtered = unreadOnly
        ? announcements.where((item) => !item.isRead).toList()
        : announcements;
    const pageSize = 2;
    final start = (page - 1) * pageSize;
    final items = start >= filtered.length
        ? <AnnouncementModel>[]
        : filtered.skip(start).take(pageSize).toList();

    return AnnouncementPage(
      announcements: items,
      currentPage: page,
      perPage: pageSize,
      total: filtered.length,
      lastPage: (filtered.length / pageSize).ceil(),
    );
  }

  @override
  Future<AnnouncementModel> getAnnouncement(int id) async {
    final announcement = announcements.firstWhere((item) => item.id == id);
    return AnnouncementModel(
      id: announcement.id,
      title: announcement.title,
      status: announcement.status,
      publishedAt: announcement.publishedAt,
      readAt: announcement.readAt,
      createdAt: announcement.createdAt,
      body: 'Body for ${announcement.title.toLowerCase()}',
    );
  }

  @override
  Future<AnnouncementModel> markRead(int id) async {
    markedReadIds.add(id);
    final announcement = await getAnnouncement(id);
    return announcement.copyWith(readAt: '2026-10-23T10:30:00+00:00');
  }
}
