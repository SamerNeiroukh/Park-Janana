import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static const double parkLatitude = 31.7683;
  static const double parkLongitude = 35.2137;
  static const double allowedRadiusMeters = 100;

  /// Returns:
  /// - `true`  → device is confirmed inside the park perimeter.
  /// - `false` → device is confirmed outside the park perimeter.
  /// - `null`  → location is unavailable (service disabled, permission denied,
  ///             GPS timeout, etc.) — the caller should skip the location check.
  static Future<bool?> isInsidePark() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 20),
      );

      final double distance = Geolocator.distanceBetween(
        parkLatitude,
        parkLongitude,
        position.latitude,
        position.longitude,
      );

      return distance <= allowedRadiusMeters;
    } catch (_) {
      // Timeout or any other GPS error — can't determine location
      return null;
    }
  }
}
