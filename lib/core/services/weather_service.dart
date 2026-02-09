import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'd7a80dbfc9032688dbb189a2f7940e7e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const Duration _cacheDuration = Duration(minutes: 30);

  static Map<String, dynamic>? _cachedWeather;
  static DateTime? _cacheTimestamp;

  Future<Map<String, dynamic>?> fetchWeather({double lat = 31.7683, double lon = 35.2137}) async {
    // Return cached data if still fresh
    if (_cachedWeather != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedWeather;
    }

    try {
      final response = await http.get(Uri.parse(
          '$_baseUrl?lat=$lat&lon=$lon&units=metric&appid=$_apiKey&lang=he'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedWeather = {
          'description': data['weather'][0]['description'],
          'temperature': data['main']['temp'].round(),
          'icon': data['weather'][0]['icon'],
        };
        _cacheTimestamp = DateTime.now();
        return _cachedWeather;
      } else {
        return _cachedWeather; // Return stale cache on failure
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      return _cachedWeather; // Return stale cache on error
    }
  }
}
