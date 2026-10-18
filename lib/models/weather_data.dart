class WeatherData {
  final double temperature;
  final String description;
  final double feelsLike;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final int cloudiness;
  final String iconCode;
  final String city;
  final String country;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.cloudiness,
    required this.iconCode,
    required this.city,
    required this.country,
    required this.timestamp,
  });

  // Parser depuis OpenWeatherMap API
  factory WeatherData.fromOpenWeatherMap(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] ?? 0.0).toDouble(),
      description: (json['weather'][0]['main'] ?? 'Unknown').toString(),
      feelsLike: (json['main']['feels_like'] ?? 0.0).toDouble(),
      humidity: (json['main']['humidity'] ?? 0).toInt(),
      pressure: (json['main']['pressure'] ?? 0.0).toDouble(),
      windSpeed: (json['wind']['speed'] ?? 0.0).toDouble(),
      cloudiness: (json['clouds']['all'] ?? 0).toInt(),
      iconCode: (json['weather'][0]['icon'] ?? '01d').toString(),
      city: (json['name'] ?? 'Unknown').toString(),
      country: (json['sys']['country'] ?? 'XX').toString(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'description': description,
      'feels_like': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'wind_speed': windSpeed,
      'cloudiness': cloudiness,
      'icon_code': iconCode,
      'city': city,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Obtenir l'emoji/icône basé sur le code OpenWeatherMap
  String getWeatherEmoji() {
    const emojiMap = {
      '01d': '☀️', // clear sky day
      '01n': '🌙', // clear sky night
      '02d': '⛅', // few clouds day
      '02n': '☁️', // few clouds night
      '03d': '☁️', // scattered clouds day
      '03n': '☁️', // scattered clouds night
      '04d': '☁️', // broken clouds day
      '04n': '☁️', // broken clouds night
      '09d': '🌧️', // shower rain day
      '09n': '🌧️', // shower rain night
      '10d': '🌧️', // rain day
      '10n': '🌧️', // rain night
      '11d': '⛈️', // thunderstorm day
      '11n': '⛈️', // thunderstorm night
      '13d': '❄️', // snow day
      '13n': '❄️', // snow night
      '50d': '🌫️', // mist day
      '50n': '🌫️', // mist night
    };
    return emojiMap[iconCode] ?? '🌤️';
  }
}
