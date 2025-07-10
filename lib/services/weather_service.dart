import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'd7a80dbfc9032688dbb189a2f7940e7e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>?> fetchWeather({double lat = 31.7683, double lon = 35.2137}) async {
    try {
      final response = await http.get(Uri.parse(
          '$_baseUrl?lat=$lat&lon=$lon&units=metric&appid=$_apiKey&lang=he'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'description': data['weather'][0]['description'],
          'temperature': data['main']['temp'].toDouble(),
          'icon': data['weather'][0]['icon'],
        };
      } else {
        return null;
      }
    } catch (e) {
      print('Weather fetch error: $e');
      return null;
    }
  }
}
