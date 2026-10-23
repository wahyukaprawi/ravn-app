import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool mocked;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.mocked,
  });
}

class AttendanceLocationException implements Exception {
  final String message;

  const AttendanceLocationException(this.message);

  @override
  String toString() => message;
}

abstract class AttendanceLocationService {
  Future<DeviceLocation> currentLocation();
}

class GeolocatorAttendanceLocationService implements AttendanceLocationService {
  @override
  Future<DeviceLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AttendanceLocationException(
        'Location services are disabled. Enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const AttendanceLocationException(
        'Location permission is required to validate attendance.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        mocked: position.isMocked,
      );
    } catch (_) {
      throw const AttendanceLocationException(
        'Could not obtain a GPS fix. Move to an open area and try again.',
      );
    }
  }
}
