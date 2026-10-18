class SensorData {
  final double temperature; // BME280
  final double humidity; // BME280
  final double pressure; // BME280
  final double lightIntensity; // BH1750 (Lux)
  final double windSpeed; // Anemometer (km/h)
  final double windDirection; // Anemometer (degrees)
  final bool isRaining; // LM393
  final DateTime timestamp;
  final bool isOnline;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.lightIntensity,
    required this.windSpeed,
    required this.windDirection,
    required this.isRaining,
    required this.timestamp,
    this.isOnline = true,
  });

  // Convertir JSON depuis MQTT/API en SensorData
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      pressure: (json['pressure'] ?? 0.0).toDouble(),
      lightIntensity: (json['light_intensity'] ?? 0.0).toDouble(),
      windSpeed: (json['wind_speed'] ?? 0.0).toDouble(),
      windDirection: (json['wind_direction'] ?? 0.0).toDouble(),
      isRaining: json['is_raining'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isOnline: json['is_online'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'light_intensity': lightIntensity,
      'wind_speed': windSpeed,
      'wind_direction': windDirection,
      'is_raining': isRaining,
      'timestamp': timestamp.toIso8601String(),
      'is_online': isOnline,
    };
  }

  // Obtenir la direction du vent en texte (N, NE, E, SE, S, SW, W, NW)
  String getWindDirectionText() {
    final directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW'
    ];
    final index = ((windDirection + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }
}
