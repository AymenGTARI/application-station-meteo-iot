import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:geolocator/geolocator.dart';

// À installer avec:
// flutter pub add http geolocator

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() {
    return _instance;
  }

  WeatherService._internal();

  // Configuration API
  final String _apiKey = 'e6686fb75b2e149d1796e22cabc46751'; // À remplacer
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Localisation par défaut (Sbeitla, Tunisia)
  double _latitude = 35.2167;
  double _longitude = 9.4167;
  String _city = 'Ariana, Tunisia';

  /// Initialiser la localisation
  Future<void> initializeLocation() async {
    try {
      // Décommenter après installation de geolocator
      /*
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          debugPrint('Permission de localisation refusée');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      
      // Obtenir le nom de la ville avec reverse geocoding
      await _getLocationName();
      */

      debugPrint('Localisation initialisée: $_city ($_latitude, $_longitude)');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la localisation: $e');
    }
  }

  /// Obtenir le nom de la ville via reverse geocoding
  Future<void> _getLocationName() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/geo/1.0/reverse?lat=$_latitude&lon=$_longitude&limit=1&appid=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final city = data[0]['name'] ?? 'Unknown';
          final country = data[0]['country'] ?? 'XX';
          _city = '$city, $country';
        }
      }
    } catch (e) {
      debugPrint('Erreur reverse geocoding: $e');
    }
  }

  /// Récupérer les données météo actuelles
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      debugPrint('Récupération météo pour: $_latitude, $_longitude');

      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/weather?lat=$_latitude&lon=$_longitude&units=metric&lang=fr&appid=$_apiKey',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Données météo reçues: ${data['main']['temp']}°C');
        return data;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur récupération météo: $e');
      // Retourner des données par défaut en cas d'erreur
      return _getDefaultWeatherData();
    }
  }

  /// Récupérer les données météo par heure (prévisions)
  Future<Map<String, dynamic>> getHourlyWeather() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/forecast?lat=$_latitude&lon=$_longitude&units=metric&lang=fr&appid=$_apiKey',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur récupération prévisions: $e');
      return {};
    }
  }

  /// Récupérer les données météo par jour (prévisions)
  Future<Map<String, dynamic>> getDailyWeather() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/forecast/daily?lat=$_latitude&lon=$_longitude&units=metric&lang=fr&appid=$_apiKey',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur récupération prévisions quotidiennes: $e');
      return {};
    }
  }

  /// Obtenir les données météo par ville
  Future<Map<String, dynamic>> getWeatherByCity(String city) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/weather?q=$city&units=metric&lang=fr&appid=$_apiKey',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _city = '${data['name']}, ${data['sys']['country']}';
        _latitude = data['coord']['lat'];
        _longitude = data['coord']['lon'];
        return data;
      } else {
        throw Exception('Ville non trouvée');
      }
    } catch (e) {
      debugPrint('Erreur récupération météo par ville: $e');
      return _getDefaultWeatherData();
    }
  }

  /// Données météo par défaut
  Map<String, dynamic> _getDefaultWeatherData() {
    return {
      'main': {
        'temp': 28.0,
        'feels_like': 27.0,
        'humidity': 65,
        'pressure': 1013,
      },
      'weather': [
        {
          'main': 'Clear',
          'description': 'ciel dégagé',
          'icon': '01d',
        }
      ],
      'wind': {
        'speed': 5.5,
      },
      'clouds': {
        'all': 10,
      },
      'name': _city,
      'sys': {
        'country': 'TN',
      },
    };
  }

  // Getters
  String get city => _city;
  double get latitude => _latitude;
  double get longitude => _longitude;

  // Setters pour changer la localisation
  void setLocation(double lat, double lon, {String? city}) {
    _latitude = lat;
    _longitude = lon;
    if (city != null) _city = city;
  }
}
