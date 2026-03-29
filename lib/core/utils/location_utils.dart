import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';

class LocationUtils {
  static const double parkLatitude = 31.7683;
  static const double parkLongitude = 35.2137;
  static const double allowedRadiusMeters = 100;

  /// Shows a rationale dialog explaining why location access is needed, then
  /// triggers the system permission request if the user agrees.
  ///
  /// Returns `true` if permission was granted after the rationale, `false`
  /// otherwise. Should be called before [isInsidePark] when permission has not
  /// yet been granted.
  static Future<bool> requestPermissionWithRationale(
      BuildContext context) async {
    final LocationPermission current = await Geolocator.checkPermission();
    if (current == LocationPermission.always ||
        current == LocationPermission.whileInUse) {
      return true;
    }
    if (current == LocationPermission.deniedForever) return false;

    // Show our custom rationale dialog before triggering the OS prompt.
    if (!context.mounted) return false;
    final agreed = await showAppDialog(
      context,
      title: 'גישה למיקום',
      message:
          'האפליקציה זקוקה לגישה למיקומך כדי לאפשר כניסה ויציאה מהעבודה בתחום הפארק.\n\nהמיקום משמש אך ורק לאימות נוכחות ואינו נשמר או משותף.',
      confirmText: 'אשר גישה',
      cancelText: 'לא עכשיו',
      icon: PhosphorIconsRegular.mapPin,
      isDestructive: false,
    );

    if (agreed != true) return false;

    // Trigger the OS permission prompt only after the user saw the rationale.
    final result = await Geolocator.requestPermission();
    return result == LocationPermission.whileInUse ||
        result == LocationPermission.always;
  }

  /// Returns:
  /// - `true`  → device is confirmed inside the park perimeter.
  /// - `false` → device is confirmed outside the park perimeter.
  /// - `null`  → location is unavailable (service disabled, permission denied,
  ///             GPS timeout, etc.) — the caller should skip the location check.
  ///
  /// Call [requestPermissionWithRationale] before this when permission may not
  /// have been granted yet.
  static Future<bool?> isInsidePark() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final LocationPermission permission = await Geolocator.checkPermission();
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
