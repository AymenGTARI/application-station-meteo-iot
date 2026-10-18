import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
// import 'package:mqtt5_client/mqtt_client.dart';
// import 'package:mqtt5_client/mqtt_server_client.dart';

// Note: À installer avec:
// flutter pub add mqtt5_client

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();

  factory MQTTService() {
    return _instance;
  }

  MQTTService._internal();

  // Configuration MQTT
  final String _brokerAddress =
      'mqtt.example.com'; // Remplacer par votre broker
  final int _brokerPort = 1883;
  final String _clientId =
      'flutter_app_${DateTime.now().millisecondsSinceEpoch}';

  // Topics MQTT
  static const String TOPIC_TEMPERATURE = 'station/bme280/temperature';
  static const String TOPIC_HUMIDITY = 'station/bme280/humidity';
  static const String TOPIC_PRESSURE = 'station/bme280/pressure';
  static const String TOPIC_LIGHT = 'station/bh1750/light';
  static const String TOPIC_WIND_SPEED = 'station/anemometer/speed';
  static const String TOPIC_WIND_DIRECTION = 'station/anemometer/direction';
  static const String TOPIC_RAIN = 'station/lm393/rain';
  static const String TOPIC_STATUS = 'station/status';

  // Stream controllers
  final StreamController<double> _temperatureStream =
      StreamController<double>.broadcast();
  final StreamController<double> _humidityStream =
      StreamController<double>.broadcast();
  final StreamController<double> _pressureStream =
      StreamController<double>.broadcast();
  final StreamController<double> _lightStream =
      StreamController<double>.broadcast();
  final StreamController<double> _windSpeedStream =
      StreamController<double>.broadcast();
  final StreamController<double> _windDirectionStream =
      StreamController<double>.broadcast();
  final StreamController<bool> _rainStream = StreamController<bool>.broadcast();
  final StreamController<bool> _connectionStream =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  // MqttServerClient? _client;

  // Getters pour les streams
  Stream<double> get temperatureStream => _temperatureStream.stream;
  Stream<double> get humidityStream => _humidityStream.stream;
  Stream<double> get pressureStream => _pressureStream.stream;
  Stream<double> get lightStream => _lightStream.stream;
  Stream<double> get windSpeedStream => _windSpeedStream.stream;
  Stream<double> get windDirectionStream => _windDirectionStream.stream;
  Stream<bool> get rainStream => _rainStream.stream;
  Stream<bool> get connectionStream => _connectionStream.stream;

  bool get isConnected => _isConnected;

  /// Initialiser la connexion MQTT
  Future<void> connect() async {
    try {
      debugPrint('Connexion au broker MQTT: $_brokerAddress:$_brokerPort');

      // Exemple avec mqtt5_client (décommenter après installation)
      /*
      _client = MqttServerClient(_brokerAddress, _clientId);
      _client!.port = _brokerPort;
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;

      try {
        await _client!.connect();
      } catch (e) {
        debugPrint('Erreur de connexion MQTT: $e');
        _client!.disconnect();
        rethrow;
      }

      // S'abonner aux topics
      _subscribeToTopics();
      */

      // POUR DÉVELOPPEMENT: Simulation avec des données
      _simulateSensorData();
      _setConnected(true);
    } catch (e) {
      debugPrint('Erreur MQTT: $e');
      _setConnected(false);
    }
  }

  /// S'abonner aux topics MQTT
  void _subscribeToTopics() {
    /*
    _client?.subscribe(TOPIC_TEMPERATURE, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_HUMIDITY, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_PRESSURE, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_LIGHT, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_WIND_SPEED, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_WIND_DIRECTION, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_RAIN, MqttQos.atLeastOnce);
    _client?.subscribe(TOPIC_STATUS, MqttQos.atLeastOnce);
    */
  }

  /// Simuler les données des capteurs (pour développement)
  void _simulateSensorData() {
    Timer.periodic(Duration(seconds: 5), (_) {
      if (!_isConnected) return;

      // Simulation avec valeurs qui varient légèrement
      _temperatureStream.add(25.0 + (DateTime.now().second % 5) * 0.5);
      _humidityStream.add(60.0 + (DateTime.now().second % 10) * 0.2);
      _pressureStream.add(1013.0 + (DateTime.now().second % 3) * 0.1);
      _lightStream.add(450.0 + (DateTime.now().second % 20) * 5);
      _windSpeedStream.add(18.4 + (DateTime.now().second % 5) * 0.3);
      _windDirectionStream.add(45.0 + (DateTime.now().second % 10) * 2);
      _rainStream.add(DateTime.now().second < 30 ? false : true);
    });
  }

  /// Callback de connexion
  void _onConnected() {
    debugPrint('Connecté au broker MQTT');
    _setConnected(true);
  }

  /// Callback de déconnexion
  void _onDisconnected() {
    debugPrint('Déconnecté du broker MQTT');
    _setConnected(false);
  }

  /// Callback de souscription
  void _onSubscribed(String topic) {
    debugPrint('Abonné au topic: $topic');
  }

  /// Définir l'état de connexion
  void _setConnected(bool connected) {
    _isConnected = connected;
    _connectionStream.add(connected);
  }

  /// Publier un message
  Future<void> publish(String topic, String message) async {
    try {
      /*
      if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttPayloadBuilder();
        builder.addString(message);
        _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      }
      */
      debugPrint('Message publié sur $topic: $message');
    } catch (e) {
      debugPrint('Erreur publication MQTT: $e');
    }
  }

  /// Déconnecter
  void disconnect() {
    try {
      // _client?.disconnect();
      _setConnected(false);
      debugPrint('Déconnexion MQTT effectuée');
    } catch (e) {
      debugPrint('Erreur déconnexion MQTT: $e');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _temperatureStream.close();
    _humidityStream.close();
    _pressureStream.close();
    _lightStream.close();
    _windSpeedStream.close();
    _windDirectionStream.close();
    _rainStream.close();
    _connectionStream.close();
    disconnect();
  }
}
