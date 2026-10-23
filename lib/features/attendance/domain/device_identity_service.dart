import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

abstract class DeviceIdentityService {
  Future<String> getOrCreate();
}

class SecureDeviceIdentityService implements DeviceIdentityService {
  static const _key = 'attendance_device_id';

  final FlutterSecureStorage storage;
  final Uuid uuid;

  SecureDeviceIdentityService({
    this.storage = const FlutterSecureStorage(),
    this.uuid = const Uuid(),
  });

  @override
  Future<String> getOrCreate() async {
    final existing = await storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = uuid.v4();
    await storage.write(key: _key, value: created);
    return created;
  }
}
