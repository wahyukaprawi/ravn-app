enum PushMessageSource { foreground, opened }

class PushMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final PushMessageSource source;

  const PushMessage({
    this.title,
    this.body,
    this.data = const {},
    this.source = PushMessageSource.opened,
  });
}

abstract class PushNotificationService {
  Future<void> initialize() async {}

  Future<String?> initializeAndGetToken();

  Future<PushMessage?> getInitialMessage() async => null;

  Stream<String> get tokenRefreshes => const Stream.empty();

  Stream<PushMessage> get messages;

  Future<void> dispose();
}

class NoopPushNotificationService implements PushNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> initializeAndGetToken() async => null;

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushMessage> get messages => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
