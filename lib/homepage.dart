import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/mqtt_service.dart';
import '../services/weather_service.dart';

class MyHomePageDynamic extends StatefulWidget {
  const MyHomePageDynamic({super.key});

  @override
  State<MyHomePageDynamic> createState() => _MyHomePageDynamicState();
}

class _MyHomePageDynamicState extends State<MyHomePageDynamic> {
  int _selectedIndex = 0;

  late MQTTService _mqttService;
  late WeatherService _weatherService;

  // Données MQTT en temps réel
  double _temperature = 0.0;
  double _humidity = 0.0;
  double _pressure = 0.0;
  double _lightIntensity = 0.0;
  double _windSpeed = 0.0;
  double _windDirection = 0.0;
  bool _isRaining = false;
  bool _mqttConnected = false;

  // Données météo API
  WeatherData? _weatherData;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _mqttService = MQTTService();
    _weatherService = WeatherService();

    _initializeServices();
    _listenToMQTTStreams();
  }

  Future<void> _initializeServices() async {
    try {
      await _weatherService.initializeLocation();
      await _fetchWeatherData();
      await _mqttService.connect();
    } catch (e) {
      debugPrint('Erreur initialisation services: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      setState(() => _weatherLoading = true);
      final weatherJson = await _weatherService.getCurrentWeather();
      final weatherData = WeatherData.fromOpenWeatherMap(weatherJson);

      setState(() {
        _weatherData = weatherData;
        _weatherLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur récupération météo: $e');
      setState(() => _weatherLoading = false);
    }
  }

  void _listenToMQTTStreams() {
    _mqttService.temperatureStream.listen((temp) {
      setState(() => _temperature = temp);
    });

    _mqttService.humidityStream.listen((humid) {
      setState(() => _humidity = humid);
    });

    _mqttService.pressureStream.listen((press) {
      setState(() => _pressure = press);
    });

    _mqttService.lightStream.listen((light) {
      setState(() => _lightIntensity = light);
    });

    _mqttService.windSpeedStream.listen((wind) {
      setState(() => _windSpeed = wind);
    });

    _mqttService.windDirectionStream.listen((dir) {
      setState(() => _windDirection = dir);
    });

    _mqttService.rainStream.listen((rain) {
      setState(() => _isRaining = rain);
    });

    _mqttService.connectionStream.listen((connected) {
      setState(() => _mqttConnected = connected);
    });
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        'loginpage',
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur Firebase lors de la déconnexion : ${e.message}');
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion : $e');
    }
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomePage(),
            _buildSensorsPage(),
            _buildHistoryPage(),
            _buildSettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildWeatherCard(),
                const SizedBox(height: 28),
                _buildSectionTitle(
                  title: 'Station Sensors',
                  icon: Icons.hub_outlined,
                  action: 'View All',
                ),
                const SizedBox(height: 14),
                _buildSensorGrid(),
                const SizedBox(height: 28),
                _buildOverviewCard(),
                const SizedBox(height: 22),
                _buildStationStatus(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3977F6),
                Color(0xFF6C9EFF),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3977F6).withOpacity(0.20),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.wb_sunny_rounded,
            color: Colors.white,
            size: 31,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weather Station',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17213B),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 17,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _weatherService.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildHeaderButton(
          icon: Icons.refresh_rounded,
          onPressed: () {
            _fetchWeatherData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Données actualisées'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF45B8F5),
              ],
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE7EBF2),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF17213B),
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weatherLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3984F7),
              Color(0xFF58B9F4),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    final weather = _weatherData;
    if (weather == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3984F7),
            Color(0xFF58B9F4),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3984F7).withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    weather.getWeatherEmoji(),
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.temperature.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 58,
                            height: 0.9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weather.description,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${now.day} ${_getMonthName(now.month)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 17,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _weatherInfo(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidité',
                    value: '${weather.humidity}%',
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _weatherInfo(
                    icon: Icons.air_rounded,
                    label: 'Vent',
                    value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _weatherInfo(
                    icon: Icons.speed_rounded,
                    label: 'Pression',
                    value: '${weather.pressure.toStringAsFixed(0)} hPa',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 42,
      color: Colors.white.withOpacity(0.30),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    String? action,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF3977F6),
          size: 25,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17213B),
          ),
        ),
        const Spacer(),
        if (action != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF3977F6),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF3977F6),
                  size: 18,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSensorGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBME280Card()),
            const SizedBox(width: 12),
            Expanded(child: _buildBH1750Card()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildAnemometerCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildRainCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildBME280Card() {
    return _sensorCard(
      title: 'BME280',
      icon: Icons.thermostat_rounded,
      iconColor: const Color(0xFF3977F6),
      child: Column(
        children: [
          _sensorValueRow(
            icon: Icons.thermostat_outlined,
            label: 'Température',
            value: '${_temperature.toStringAsFixed(1)}°C',
          ),
          _sensorDivider(),
          _sensorValueRow(
            icon: Icons.water_drop_outlined,
            label: 'Humidité',
            value: '${_humidity.toStringAsFixed(0)}%',
          ),
          _sensorDivider(),
          _sensorValueRow(
            icon: Icons.speed_rounded,
            label: 'Pression',
            value: '${_pressure.toStringAsFixed(0)} hPa',
          ),
        ],
      ),
    );
  }

  Widget _buildBH1750Card() {
    return _sensorCard(
      title: 'BH1750',
      icon: Icons.lightbulb_rounded,
      iconColor: const Color(0xFFFF9D22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intensité Lumineuse',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_lightIntensity.toStringAsFixed(0)} Lux',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17213B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnemometerCard() {
    return _sensorCard(
      title: 'Anémomètre',
      icon: Icons.air_rounded,
      iconColor: const Color(0xFF27A95A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitesse du Vent',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_windSpeed.toStringAsFixed(1)} km/h',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17213B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Direction',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_getWindDirectionText()} (${_windDirection.toStringAsFixed(0)}°)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF27A95A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainCard() {
    return _sensorCard(
      title: 'LM393',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF7055D9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capteur de Pluie',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isRaining ? 'Pluie Détectée' : 'Pas de Pluie',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _isRaining ? Colors.red[700] : const Color(0xFF27A95A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: _isRaining
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFEFFAF3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  _isRaining
                      ? Icons.cloud_queue_rounded
                      : Icons.umbrella_rounded,
                  color: _isRaining ? Colors.red[700] : const Color(0xFF27A95A),
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _isRaining ? 'Pluie en cours' : 'Pas de pluie détectée',
                    style: TextStyle(
                      color: _isRaining
                          ? Colors.red[700]
                          : const Color(0xFF23964E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget _sensorValueRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF3977F6),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17213B),
          ),
        ),
      ],
    );
  }

  Widget _sensorDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF3977F6),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Aperçu d'aujourd'hui",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17213B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _timeButton('1H', false),
              _timeButton('6H', false),
              _timeButton('12H', false),
              _timeButton('24H', true),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text('Graphique (à implémenter)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeButton(String text, bool selected) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3977F6) : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF17213B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color:
            _mqttConnected ? const Color(0xFFF1FBF5) : const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _mqttConnected
              ? const Color(0xFFD9F2E2)
              : const Color(0xFFFFD9D9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _mqttConnected
                  ? const Color(0xFFDDF6E5)
                  : const Color(0xFFFFE7E7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_rounded,
              color: _mqttConnected ? const Color(0xFF27A95A) : Colors.red,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'État de la Station',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color:
                          _mqttConnected ? const Color(0xFF27A95A) : Colors.red,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _mqttConnected
                          ? 'Station En Ligne'
                          : 'Station Hors Ligne',
                      style: TextStyle(
                        fontSize: 17,
                        color: _mqttConnected
                            ? const Color(0xFF21964E)
                            : Colors.red[700],
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Dernier sync',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'À l\'instant',
                style: TextStyle(
                  fontSize: 14,
                  color: _mqttConnected
                      ? const Color(0xFF21964E)
                      : Colors.red[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavigationItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3977F6),
          unselectedItemColor: const Color(0xFF687386),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Capteurs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart_rounded),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsPage() {
    return const Center(
      child: Text(
        'Capteurs',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHistoryPage() {
    return const Center(
      child: Text(
        'Historique',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: logout,
        icon: const Icon(Icons.logout),
        label: const Text('Se déconnecter'),
      ),
    );
  }

  String _getWindDirectionText() {
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
    final index = ((_windDirection + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }
}
