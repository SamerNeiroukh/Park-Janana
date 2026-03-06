import 'package:flutter/foundation.dart';
import 'package:park_janana/core/services/weather_service.dart';

/// AppStateProvider manages app-wide state (weather data and global settings).
class AppStateProvider extends ChangeNotifier {
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = false;

  Map<String, dynamic>? get weatherData => _weatherData;
  bool get isLoadingWeather => _isLoadingWeather;

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

  Future<void> refreshAll() async {
    await loadWeather();
  }
}
