import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:park_janana/core/services/weather_service.dart';

/// AppStateProvider manages app-wide state
/// Includes weather data, roles configuration, and global app settings
class AppStateProvider extends ChangeNotifier {
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _roleData;
  bool _isLoadingWeather = false;
  bool _isLoadingRoles = false;

  // Getters
  Map<String, dynamic>? get weatherData => _weatherData;
  Map<String, dynamic>? get roleData => _roleData;
  bool get isLoadingWeather => _isLoadingWeather;
  bool get isLoadingRoles => _isLoadingRoles;

  /// Load weather data
  Future<void> loadWeather() async {
    _isLoadingWeather = true;
    notifyListeners();

    try {
      _weatherData = await WeatherService().fetchWeather();
    } catch (e) {
      debugPrint('Error loading weather: $e');
      _weatherData = null;
    } finally {
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  /// Load roles configuration from JSON
  Future<void> loadRolesData() async {
    _isLoadingRoles = true;
    notifyListeners();

    try {
      final String rolesJson =
          await rootBundle.loadString('lib/config/roles.json');
      _roleData = json.decode(rolesJson);
    } catch (e) {
      debugPrint('Error loading roles data: $e');
      _roleData = null;
    } finally {
      _isLoadingRoles = false;
      notifyListeners();
    }
  }

  /// Get operations for a specific role
  List<Map<String, dynamic>> getOperationsForRole(String role) {
    if (_roleData == null || !_roleData!.containsKey(role)) {
      return [];
    }

    return List<Map<String, dynamic>>.from(_roleData![role] as List);
  }

  /// Refresh all app state
  Future<void> refreshAll() async {
    await Future.wait([
      loadWeather(),
      loadRolesData(),
    ]);
  }
}
