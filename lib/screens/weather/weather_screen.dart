// Путь: lib/screens/weather/weather_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather/weather_api_service.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';
import '../../services/fishing_forecast_service.dart';
import '../../widgets/bite_activity_chart.dart';
import 'pressure_detail_screen.dart';
import 'wind_detail_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  final WeatherApiService _weatherService = WeatherApiService();
  final FishingForecastService _fishingForecastService = FishingForecastService();
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();

  WeatherApiResponse? _currentWeather;
  Map<String, dynamic>? _fishingForecast;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = '';
  DateTime _lastUpdated = DateTime.now();

  // Анимации
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _biteController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _biteAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initWeatherSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Теперь контекст полностью инициализирован
    if (_isLoading && _currentWeather == null) {
      _loadWeather();
    }
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _biteController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _biteAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _biteController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initWeatherSettings() async {
    // Инициализируем настройки погоды, если еще не инициализированы
    debugPrint('🌤️ Инициализация настроек погоды в weather_screen');
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    _biteController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _rotationController.repeat();

    try {
      final position = await _getCurrentPosition();

      if (position != null && mounted) {
        final weather = await _weatherService.getForecast(
          latitude: position.latitude,
          longitude: position.longitude,
          days: 3,
        );

        final fishingForecast = await _fishingForecastService.getFishingForecast(
          weather: weather,
          latitude: position.latitude,
          longitude: position.longitude,
          context: context,
        );

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

          // Задержка для анимации клёвометра
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _biteController.forward();
          });
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

  Future<Position?> _getCurrentPosition() async {
    if (!mounted) return null;

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
      // Возвращаем координаты Павлодара как fallback
      return Position(
        longitude: 76.9574,
        latitude: 52.2962,
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

  @override
  Widget build(BuildContext context) {
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
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentWeather == null) {
      return _buildNoDataState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildCompactHeader(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildKeyMetricsGrid(),
                const SizedBox(height: 24),
                _buildBiteMeter(),
                const SizedBox(height: 24),
                _buildHourlyForecast(),
                const SizedBox(height: 24),
                _buildBestTimeSection(),
                const SizedBox(height: 24),
                _buildChartsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
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
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_sync,
                    size: 64,
                    color: AppConstants.primaryColor,
                  ),
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
          const SizedBox(height: 8),
          Text(
            localizations.translate('please_wait'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.translate('weather_error'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_queue,
            size: 64,
            color: AppConstants.textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_data_to_display'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Компактный заголовок (Header блок)
  Widget _buildCompactHeader() {
    final localizations = AppLocalizations.of(context);
    final current = _currentWeather!.current;

    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      actions: [

      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                current.isDay == 1
                    ? Colors.blue[400]!.withValues(alpha: 0.6)
                    : Colors.indigo[800]!.withValues(alpha: 0.6),
                AppConstants.backgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Локация и время обновления
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppConstants.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${localizations.translate('updated')}: ${DateFormat('HH:mm').format(_lastUpdated)}',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Температура и описание
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Температура с динамическими единицами
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherSettings.convertTemperature(current.tempC).round().toString(),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 48,
                              fontWeight: FontWeight.w200,
                              height: 1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _weatherSettings.getTemperatureUnitSymbol(),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Описание
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translateWeatherDescription(current.condition.text),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${localizations.translate('feels_like')} ${_weatherSettings.formatTemperature(current.feelslikeC, showUnit: false)}${_weatherSettings.getTemperatureUnitSymbol()}',
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Анимированная иконка
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_fadeController.value * 0.2),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppConstants.textColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getWeatherIcon(current.condition.code),
                                size: 36,
                                color: AppConstants.textColor,
                              ),
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

  // Ключевые показатели (4 карточки)
  Widget _buildKeyMetricsGrid() {
    final localizations = AppLocalizations.of(context);
    final current = _currentWeather!.current;
    final astro = _currentWeather!.forecast.first.astro;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('key_fishing_indicators'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
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
            childAspectRatio: 1.3,
            children: [
              _buildPressureCard(current.pressureMb),
              _buildWindCard(current.windKph, current.windDir),
              _buildMoonCard(astro.moonPhase),
              _buildHumidityCard(current.humidity, current.tempC),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureCard(double pressure) {
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PressureDetailScreen(
              weatherData: _currentWeather!,
              locationName: _locationName,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.speed,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.trending_flat,
                    color: Colors.green,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('pressure'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _weatherSettings.formatPressure(pressure, showUnit: false),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                _getPressureDescription(pressure),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindCard(double windKph, String windDir) {
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WindDetailScreen(
              weatherData: _currentWeather!,
              locationName: _locationName,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.air,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getWindImpactColor(windKph).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translateWindDirection(windDir),
                    style: TextStyle(
                      color: _getWindImpactColor(windKph),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('wind'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _weatherSettings.formatWindSpeed(windKph, showUnit: false),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  _getWindImpactOnFishing(windKph),
                  style: TextStyle(
                    color: _getWindImpactColor(windKph),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonCard(String moonPhase) {
    final localizations = AppLocalizations.of(context);
    final moonImpact = _getMoonImpactOnFishing(moonPhase);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.brightness_2,
                  color: AppConstants.primaryColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              _buildMoonIcon(moonPhase),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('moon_phase'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              _translateMoonPhase(moonPhase),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              moonImpact['description'],
              style: TextStyle(
                color: moonImpact['color'],
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard(int humidity, double temp) {
    final localizations = AppLocalizations.of(context);
    final dewPoint = _calculateDewPoint(temp, humidity);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: AppConstants.primaryColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getHumidityComfortColor(humidity).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getHumidityComfort(humidity),
                  style: TextStyle(
                    color: _getHumidityComfortColor(humidity),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('humidity'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$humidity%',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              '${localizations.translate('dew_point')}: ${_weatherSettings.formatTemperature(dewPoint, showUnit: false)}°',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Клёвометр (центральный блок)
  Widget _buildBiteMeter() {
    final localizations = AppLocalizations.of(context);
    if (_fishingForecast == null) return const SizedBox();

    final activity = _fishingForecast!['overallActivity'] as double;
    final recommendation = _fishingForecast!['recommendation'] as String;
    final tips = _fishingForecast!['tips'] as List<dynamic>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getBiteActivityColor(activity).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getBiteActivityColor(activity).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.set_meal,
                  color: AppConstants.textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('bite_forecast'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 24),

            // Анимированная круглая шкала клёвометра
            AnimatedBuilder(
              animation: _biteAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    children: [
                      // Фоновая окружность
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.textColor.withValues(alpha: 0.1),
                            width: 8,
                          ),
                        ),
                      ),
                      // Анимированный прогресс
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: BiteMeterPainter(
                          progress: activity * _biteAnimation.value,
                          color: _getBiteActivityColor(activity),
                        ),
                      ),
                      // Центральный текст
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(activity * 100 * _biteAnimation.value).round()}',
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 32,
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
                );
              },
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getBiteActivityColor(activity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getBiteActivityText(activity),
                style: TextStyle(
                  color: _getBiteActivityColor(activity),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _translateFishingRecommendation(recommendation),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            // Краткие советы
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: tips.take(2).map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip.toString(),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Временные блоки (горизонтальный скролл)
  Widget _buildHourlyForecast() {
    final localizations = AppLocalizations.of(context);

    if (_currentWeather!.forecast.isEmpty) return const SizedBox();

    final hours = _currentWeather!.forecast.first.hour;
    final now = DateTime.now();
    final upcomingHours = hours.where((hour) {
      final hourTime = DateTime.parse(hour.time);
      return hourTime.isAfter(now.subtract(const Duration(hours: 1)));
    }).take(12).toList();

    if (upcomingHours.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppConstants.textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('hourly_forecast'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcomingHours.length,
            itemBuilder: (context, index) {
              final hour = upcomingHours[index];
              final time = DateTime.parse(hour.time);
              final biteActivity = _calculateHourlyBiteActivity(hour);
              final isNow = time.difference(now).inHours.abs() < 1;

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isNow
                      ? AppConstants.primaryColor.withValues(alpha: 0.1)
                      : AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isNow
                      ? Border.all(color: AppConstants.primaryColor, width: 2)
                      : Border.all(
                    color: _getBiteActivityColor(biteActivity).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Время
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNow
                            ? AppConstants.primaryColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isNow ? localizations.translate('now') : DateFormat('HH:mm').format(time),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 12,
                          fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),

                    // Иконка погоды
                    Icon(
                      _getWeatherIcon(hour.condition.code),
                      color: AppConstants.textColor,
                      size: 36,
                    ),

                    // Температура с динамическими единицами
                    Text(
                      _weatherSettings.formatTemperature(hour.tempC, showUnit: false) + _weatherSettings.getTemperatureUnitSymbol(),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Ветер и осадки
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: Column(
                            children: [
                              Icon(
                                Icons.air,
                                color: AppConstants.textColor.withValues(alpha: 0.6),
                                size: 14,
                              ),
                              Text(
                                _weatherSettings.formatWindSpeed(hour.windKph, showUnit: false),
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            children: [
                              Icon(
                                Icons.grain,
                                color: Colors.blue.withValues(alpha: 0.6),
                                size: 14,
                              ),
                              Text(
                                '${hour.chanceOfRain.round()}%',
                                style: TextStyle(
                                  color: Colors.blue.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Индикатор активности клева
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getBiteActivityColor(biteActivity),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${(biteActivity * 10).round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  // Лучшее время для рыбалки
  Widget _buildBestTimeSection() {
    final localizations = AppLocalizations.of(context);
    final astro = _currentWeather!.forecast.first.astro;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.translate('best_fishing_time_today'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Лучшие периоды
            ..._getBestTimeWindows().map((window) => _buildTimeWindow(window)),

            const SizedBox(height: 20),

            // Восход и закат
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSunTimeCard(
                      localizations.translate('sunrise'),
                      astro.sunrise,
                      Icons.wb_twilight,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
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
            ),
          ],
        ),
      ),
    );
  }

  // Секция с графиками
  Widget _buildChartsSection() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppConstants.textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('bite_activity'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BiteActivityChart(
            fishingForecast: _fishingForecast,
            weatherData: _currentWeather,
            height: 220,
            showTitle: false,
            showLegend: true,
            isInteractive: true,
          ),
        ],
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
    final localizations = AppLocalizations.of(context);
    final cleanDescription = description.trim().toLowerCase();

    final Map<String, String> descriptionToKey = {
      'sunny': 'weather_sunny',
      'clear': 'weather_clear',
      'partly cloudy': 'weather_partly_cloudy',
      'cloudy': 'weather_cloudy',
      'overcast': 'weather_overcast',
      'mist': 'weather_mist',
      'light rain': 'weather_light_rain',
      'moderate rain': 'weather_moderate_rain',
      'heavy rain': 'weather_heavy_rain',
      'light snow': 'weather_light_snow',
      'thunderstorm': 'weather_thundery_outbreaks_possible',
    };

    final localizationKey = descriptionToKey[cleanDescription];
    if (localizationKey != null) {
      return localizations.translate(localizationKey);
    }

    return description;
  }

  String _translateWindDirection(String direction) {
    final localizations = AppLocalizations.of(context);
    final Map<String, String> translations = {
      'N': localizations.translate('wind_n'),
      'NNE': localizations.translate('wind_nne'),
      'NE': localizations.translate('wind_ne'),
      'ENE': localizations.translate('wind_ene'),
      'E': localizations.translate('wind_e'),
      'ESE': localizations.translate('wind_ese'),
      'SE': localizations.translate('wind_se'),
      'SSE': localizations.translate('wind_sse'),
      'S': localizations.translate('wind_s'),
      'SSW': localizations.translate('wind_ssw'),
      'SW': localizations.translate('wind_sw'),
      'WSW': localizations.translate('wind_wsw'),
      'W': localizations.translate('wind_w'),
      'WNW': localizations.translate('wind_wnw'),
      'NW': localizations.translate('wind_nw'),
      'NNW': localizations.translate('wind_nnw'),
    };
    return translations[direction] ?? direction;
  }

  String _translateMoonPhase(String phase) {
    final localizations = AppLocalizations.of(context);
    final cleanPhase = phase.trim().toLowerCase();

    final Map<String, String> phaseToKey = {
      'new moon': 'moon_new_moon',
      'waxing crescent': 'moon_waxing_crescent',
      'first quarter': 'moon_first_quarter',
      'waxing gibbous': 'moon_waxing_gibbous',
      'full moon': 'moon_full_moon',
      'waning gibbous': 'moon_waning_gibbous',
      'last quarter': 'moon_last_quarter',
      'third quarter': 'moon_third_quarter',
      'waning crescent': 'moon_waning_crescent',
    };

    final localizationKey = phaseToKey[cleanPhase];
    if (localizationKey != null) {
      return localizations.translate(localizationKey);
    }

    return phase;
  }

  String _translateFishingRecommendation(String recommendation) {
    return recommendation;
  }

  String _getPressureDescription(double pressure) {
    final localizations = AppLocalizations.of(context);
    // Учитываем калибровку барометра при проверке диапазонов
    final calibratedPressure = _weatherSettings.convertPressure(pressure);
    final originalPressure = pressure + _weatherSettings.barometerCalibration;

    if (originalPressure < 1000) return localizations.translate('low_pressure');
    if (originalPressure < 1020) return localizations.translate('normal_pressure');
    return localizations.translate('high_pressure');
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
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.brightness_2,
        color: Colors.amber,
        size: 14,
      ),
    );
  }

  Map<String, dynamic> _getMoonImpactOnFishing(String phase) {
    final localizations = AppLocalizations.of(context);
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
    double activity = 0.5;

    final hourOfDay = DateTime.parse(hour.time).hour;
    if (hourOfDay >= 5 && hourOfDay <= 8) activity += 0.2;
    if (hourOfDay >= 18 && hourOfDay <= 21) activity += 0.2;
    if (hourOfDay >= 22 || hourOfDay <= 4) activity -= 0.1;

    if (hour.tempC >= 15 && hour.tempC <= 25) activity += 0.1;

    if (hour.windKph < 15) activity += 0.1;
    else if (hour.windKph > 25) activity -= 0.2;

    if (hour.chanceOfRain > 50) activity -= 0.1;

    return activity.clamp(0.0, 1.0);
  }

  List<Map<String, dynamic>> _getBestTimeWindows() {
    final localizations = AppLocalizations.of(context);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBiteActivityColor(window['activity']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBiteActivityColor(window['activity']).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getBiteActivityColor(window['activity']),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  window['time'],
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  window['reason'],
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getBiteActivityColor(window['activity']).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${(window['activity'] * 100).round()}%',
              style: TextStyle(
                color: _getBiteActivityColor(window['activity']),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTimeCard(String title, String time, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 4;

    const double startAngle = -math.pi / 2;
    const double maxSweepAngle = 2 * math.pi;
    final double sweepAngle = maxSweepAngle * progress;

    // Рисуем фоновую окружность
    canvas.drawCircle(center, radius, backgroundPaint);

    // Рисуем прогресс
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}