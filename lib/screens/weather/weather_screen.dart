// Путь: lib/screens/weather/weather_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather/weather_api_service.dart';
import '../../localization/app_localizations.dart';
import 'weather_detail_screen.dart';
import '../../services/fishing_forecast_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  final WeatherApiService _weatherService = WeatherApiService();
  final FishingForecastService _fishingForecastService = FishingForecastService();

  WeatherApiResponse? _currentWeather;
  Map<String, dynamic>? _fishingForecast;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = '';
  DateTime _lastUpdated = DateTime.now();

  // Анимации
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Данные для мини-графика давления
  List<FlSpot> _pressureData = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadWeather();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _rotationController.repeat();

    try {
      final position = await _getCurrentPosition();

      if (position != null) {
        final weather = await _weatherService.getForecast(
          latitude: position.latitude,
          longitude: position.longitude,
          days: 3,
        );

        final fishingForecast = await _fishingForecastService.getFishingForecast(
          weather: weather,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        _generatePressureData(weather);

        if (mounted) {
          setState(() {
            _currentWeather = weather;
            _fishingForecast = fishingForecast;
            _locationName = '${weather.location.name}, ${weather.location.region}';
            _isLoading = false;
            _lastUpdated = DateTime.now();
          });

          _rotationController.stop();
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${localizations.translate('error_loading')}: $e';
          _isLoading = false;
        });
        _rotationController.stop();
      }
    }
  }

  void _generatePressureData(WeatherApiResponse weather) {
    _pressureData.clear();
    if (weather.forecast.isNotEmpty) {
      final hours = weather.forecast.first.hour;
      for (int i = 0; i < hours.length; i++) {
        final hour = hours[i];
        final time = DateTime.parse(hour.time);
        if (time.isAfter(DateTime.now().subtract(const Duration(hours: 12)))) {
          _pressureData.add(FlSpot(i.toDouble(), hour.condition.code.toDouble()));
        }
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final localizations = AppLocalizations.of(context);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(localizations.translate('location_services_disabled'));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(localizations.translate('location_permission_denied'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(localizations.translate('location_permission_denied_forever'));
      }

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('${localizations.translate('location_error')}: $e');
      return Position(
        longitude: 37.6176,
        latitude: 55.7558,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  void _openWeatherDetails() {
    if (_currentWeather != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeatherDetailScreen(
            weatherData: _currentWeather!,
            locationName: _locationName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        color: AppConstants.primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentWeather == null) {
      return Center(
        child: Text(
          localizations.translate('no_data_to_display'),
          style: TextStyle(color: AppConstants.textColor),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        _buildHeaderSliver(),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildKeyMetricsSection(),
                const SizedBox(height: 20),
                _buildBiteMeter(),
                const SizedBox(height: 20),
                _buildHourlyForecast(),
                const SizedBox(height: 20),
                _buildBestTimeSection(),
                const SizedBox(height: 20),
                _buildDetailButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Icon(
                  Icons.cloud_sync,
                  size: 64,
                  color: AppConstants.primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            localizations.translate('loading_weather'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              localizations.translate('weather_error'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.translate('try_again')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSliver() {
    final localizations = AppLocalizations.of(context);
    final current = _currentWeather!.current;

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                current.isDay == 1
                    ? Colors.blue[400]!.withValues(alpha: 0.8)
                    : Colors.indigo[800]!.withValues(alpha: 0.8),
                AppConstants.backgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Локация и время обновления
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppConstants.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${localizations.translate('updated')}: ${DateFormat('HH:mm').format(_lastUpdated)}',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Температура и описание
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${current.tempC.round()}°',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              '${localizations.translate('feels_like')} ${current.feelslikeC.round()}°',
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _translateWeatherDescription(current.condition.text),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_fadeController.value * 0.2),
                            child: Icon(
                              _getWeatherIcon(current.condition.code),
                              size: 64,
                              color: AppConstants.textColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    final localizations = AppLocalizations.of(context);
    final current = _currentWeather!.current;
    final astro = _currentWeather!.forecast.first.astro;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('key_fishing_indicators'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildPressureCard(current.pressureMb),
              _buildWindCard(current.windKph, current.windDir),
              _buildMoonCard(astro.moonPhase),
              _buildHumidityCard(current.humidity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureCard(double pressure) {
    final localizations = AppLocalizations.of(context);
    final pressureMmHg = (pressure / 1.333).round();
    final trend = _getPressureTrend();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('pressure'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                trend > 0 ? Icons.trending_up : Icons.trending_down,
                color: trend > 0 ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$pressureMmHg мм',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getPressureDescription(pressure),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // Мини-график давления
          if (_pressureData.isNotEmpty)
            SizedBox(
              height: 30,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _pressureData.take(12).toList(),
                      isCurved: true,
                      color: AppConstants.primaryColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: _pressureData.map((e) => e.y).reduce(math.min) - 5,
                  maxY: _pressureData.map((e) => e.y).reduce(math.max) + 5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWindCard(double windKph, String windDir) {
    final localizations = AppLocalizations.of(context);
    final windMs = (windKph / 3.6).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.air,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('wind'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$windMs м/с',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildWindCompass(windDir),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateWindDirection(windDir),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getWindImpactOnFishing(windKph),
                      style: TextStyle(
                        color: _getWindImpactColor(windKph),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoonCard(String moonPhase) {
    final localizations = AppLocalizations.of(context);
    final moonImpact = _getMoonImpactOnFishing(moonPhase);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_2,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('moon_phase'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMoonIcon(moonPhase),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateMoonPhase(moonPhase),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moonImpact['description'],
                      style: TextStyle(
                        color: moonImpact['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard(int humidity) {
    final localizations = AppLocalizations.of(context);
    final dewPoint = _calculateDewPoint(_currentWeather!.current.tempC, humidity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('humidity'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$humidity%',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${localizations.translate('dew_point')}: ${dewPoint.round()}°',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getHumidityComfort(humidity),
            style: TextStyle(
              color: _getHumidityComfortColor(humidity),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiteMeter() {
    final localizations = AppLocalizations.of(context);
    if (_fishingForecast == null) return const SizedBox();

    final activity = _fishingForecast!['overallActivity'] as double;
    final recommendation = _fishingForecast!['recommendation'] as String;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBiteActivityColor(activity).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              localizations.translate('bite_forecast'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Круглая шкала клёвометра
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  // Фоновая окружность
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.textColor.withValues(alpha: 0.2),
                        width: 8,
                      ),
                    ),
                  ),
                  // Прогресс
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: BiteMeterPainter(
                      progress: activity,
                      color: _getBiteActivityColor(activity),
                    ),
                  ),
                  // Центральный текст
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(activity * 100).round()}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          localizations.translate('points'),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              _getBiteActivityText(activity),
              style: TextStyle(
                color: _getBiteActivityColor(activity),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _translateFishingRecommendation(recommendation),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final localizations = AppLocalizations.of(context);

    if (_currentWeather!.forecast.isEmpty) return const SizedBox();

    final hours = _currentWeather!.forecast.first.hour;
    final now = DateTime.now();
    final upcomingHours = hours.where((hour) {
      final hourTime = DateTime.parse(hour.time);
      return hourTime.isAfter(now);
    }).take(12).toList();

    if (upcomingHours.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            localizations.translate('hourly_forecast'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcomingHours.length,
            itemBuilder: (context, index) {
              final hour = upcomingHours[index];
              final time = DateTime.parse(hour.time);
              final biteActivity = _calculateHourlyBiteActivity(hour);

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getBiteActivityColor(biteActivity).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      index == 0 ? localizations.translate('now') : DateFormat('HH:mm').format(time),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _getWeatherIcon(hour.condition.code),
                      color: AppConstants.textColor,
                      size: 28,
                    ),
                    Text(
                      '${hour.tempC.round()}°',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.air,
                          color: AppConstants.textColor.withValues(alpha: 0.6),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${(hour.windKph / 3.6).round()}',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getBiteActivityColor(biteActivity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBestTimeSection() {
    final localizations = AppLocalizations.of(context);
    final astro = _currentWeather!.forecast.first.astro;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('best_fishing_time_today'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Лучшие периоды
            ..._getBestTimeWindows().map((window) => _buildTimeWindow(window)),

            const SizedBox(height: 16),

            // Восход и закат
            Row(
              children: [
                Expanded(
                  child: _buildSunTimeCard(
                    localizations.translate('sunrise'),
                    astro.sunrise,
                    Icons.wb_twilight,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSunTimeCard(
                    localizations.translate('sunset'),
                    astro.sunset,
                    Icons.nights_stay,
                    Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailButton() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openWeatherDetails,
          icon: const Icon(Icons.info_outline),
          label: Text(localizations.translate('detailed_weather_info')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.textColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // Вспомогательные методы

  IconData _getWeatherIcon(int code) {
    switch (code) {
      case 1000: return Icons.wb_sunny;
      case 1003: case 1006: case 1009: return Icons.cloud;
      case 1030: case 1135: case 1147: return Icons.cloud;
      case 1063: case 1180: case 1183: case 1186: case 1189: case 1192: case 1195: case 1198: case 1201: return Icons.grain;
      case 1066: case 1210: case 1213: case 1216: case 1219: case 1222: case 1225: return Icons.ac_unit;
      case 1087: case 1273: case 1276: case 1279: case 1282: return Icons.flash_on;
      default: return Icons.wb_sunny;
    }
  }

  String _translateWeatherDescription(String description) {
    // Базовая реализация - можно расширить
    return description;
  }

  String _translateWindDirection(String direction) {
    final localizations = AppLocalizations.of(context);
    final Map<String, String> translations = {
      'N': localizations.translate('wind_n'),
      'NE': localizations.translate('wind_ne'),
      'E': localizations.translate('wind_e'),
      'SE': localizations.translate('wind_se'),
      'S': localizations.translate('wind_s'),
      'SW': localizations.translate('wind_sw'),
      'W': localizations.translate('wind_w'),
      'NW': localizations.translate('wind_nw'),
    };
    return translations[direction] ?? direction;
  }

  String _translateMoonPhase(String phase) {
    // Базовая реализация - можно расширить
    return phase;
  }

  String _translateFishingRecommendation(String recommendation) {
    // Базовая реализация - можно расширить
    return recommendation;
  }

  double _getPressureTrend() {
    // Заглушка - нужно будет реализовать на основе исторических данных
    return 0.0;
  }

  String _getPressureDescription(double pressure) {
    final localizations = AppLocalizations.of(context);
    if (pressure < 1000) return localizations.translate('low_pressure');
    if (pressure < 1020) return localizations.translate('normal_pressure');
    return localizations.translate('high_pressure');
  }

  Widget _buildWindCompass(String direction) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          direction,
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getWindImpactOnFishing(double windKph) {
    final localizations = AppLocalizations.of(context);
    if (windKph < 10) return localizations.translate('excellent_for_fishing');
    if (windKph < 20) return localizations.translate('good_for_fishing');
    if (windKph < 30) return localizations.translate('moderate_for_fishing');
    return localizations.translate('difficult_for_fishing');
  }

  Color _getWindImpactColor(double windKph) {
    if (windKph < 10) return Colors.green;
    if (windKph < 20) return Colors.lightGreen;
    if (windKph < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMoonIcon(String phase) {
    // Упрощенная версия - можно сделать более детальной
    return Icon(
      Icons.brightness_2,
      color: Colors.amber,
      size: 24,
    );
  }

  Map<String, dynamic> _getMoonImpactOnFishing(String phase) {
    final localizations = AppLocalizations.of(context);
    // Упрощенная логика
    if (phase.toLowerCase().contains('full')) {
      return {
        'description': localizations.translate('excellent_activity'),
        'color': Colors.green,
      };
    } else if (phase.toLowerCase().contains('new')) {
      return {
        'description': localizations.translate('good_activity'),
        'color': Colors.lightGreen,
      };
    }
    return {
      'description': localizations.translate('moderate_activity'),
      'color': Colors.orange,
    };
  }

  double _calculateDewPoint(double tempC, int humidity) {
    final a = 17.27;
    final b = 237.7;
    final alpha = ((a * tempC) / (b + tempC)) + math.log(humidity / 100.0);
    return (b * alpha) / (a - alpha);
  }

  String _getHumidityComfort(int humidity) {
    final localizations = AppLocalizations.of(context);
    if (humidity < 40) return localizations.translate('dry_comfortable');
    if (humidity < 60) return localizations.translate('comfortable');
    if (humidity < 80) return localizations.translate('slightly_humid');
    return localizations.translate('very_humid');
  }

  Color _getHumidityComfortColor(int humidity) {
    if (humidity < 40) return Colors.orange;
    if (humidity < 60) return Colors.green;
    if (humidity < 80) return Colors.lightGreen;
    return Colors.red;
  }

  Color _getBiteActivityColor(double activity) {
    if (activity > 0.8) return const Color(0xFF4CAF50);
    if (activity > 0.6) return const Color(0xFFFFC107);
    if (activity > 0.4) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getBiteActivityText(double activity) {
    final localizations = AppLocalizations.of(context);
    if (activity > 0.8) return localizations.translate('excellent_activity');
    if (activity > 0.6) return localizations.translate('good_activity');
    if (activity > 0.4) return localizations.translate('moderate_activity');
    if (activity > 0.2) return localizations.translate('weak_activity');
    return localizations.translate('very_weak_activity');
  }

  double _calculateHourlyBiteActivity(Hour hour) {
    // Упрощенная логика расчета активности клева по часам
    double activity = 0.5;

    // Время суток
    final hourOfDay = DateTime.parse(hour.time).hour;
    if (hourOfDay >= 5 && hourOfDay <= 8) activity += 0.2; // Утро
    if (hourOfDay >= 18 && hourOfDay <= 21) activity += 0.2; // Вечер
    if (hourOfDay >= 22 || hourOfDay <= 4) activity -= 0.1; // Ночь

    // Температура
    if (hour.tempC >= 15 && hour.tempC <= 25) activity += 0.1;

    // Ветер
    if (hour.windKph < 15) activity += 0.1;
    else if (hour.windKph > 25) activity -= 0.2;

    // Вероятность дождя
    if (hour.chanceOfRain > 50) activity -= 0.1;

    return activity.clamp(0.0, 1.0);
  }

  List<Map<String, dynamic>> _getBestTimeWindows() {
    final localizations = AppLocalizations.of(context);
    // Упрощенная версия - можно сделать более умной
    return [
      {
        'time': '06:00 - 08:00',
        'reason': localizations.translate('morning_activity'),
        'activity': 0.85,
      },
      {
        'time': '18:00 - 20:00',
        'reason': localizations.translate('evening_activity'),
        'activity': 0.9,
      },
    ];
  }

  Widget _buildTimeWindow(Map<String, dynamic> window) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBiteActivityColor(window['activity']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBiteActivityColor(window['activity']).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getBiteActivityColor(window['activity']),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  window['time'],
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  window['reason'],
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(window['activity'] * 100).round()}%',
            style: TextStyle(
              color: _getBiteActivityColor(window['activity']),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTimeCard(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Кастомный painter для клёвометра
class BiteMeterPainter extends CustomPainter {
  final double progress;
  final Color color;

  BiteMeterPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 4;

    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}