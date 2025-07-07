import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static const double parkLatitude = 31.7683;
  static const double parkLongitude = 35.2137;
  static const double allowedRadiusMeters = 100;

  static Future<bool> isInsidePark() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    Position position = await Geolocator.getCurrentPosition();

    double distance = Geolocator.distanceBetween(
      parkLatitude,
      parkLongitude,
      position.latitude,
      position.longitude,
    );

    return distance <= allowedRadiusMeters;
  }
}
