class PushMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const PushMessage({this.title, this.body, this.data = const {}});
}

abstract class PushNotificationService {
  Future<String?> initializeAndGetToken();

  Stream<PushMessage> get messages;

  Future<void> dispose();
}

class NoopPushNotificationService implements PushNotificationService {
  @override
  Future<String?> initializeAndGetToken() async => null;

  @override
  Stream<PushMessage> get messages => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
