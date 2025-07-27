// Путь: lib/screens/weather/pressure_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../localization/app_localizations.dart';
import '../../services/weather_settings_service.dart';
import '../../services/weather/weather_api_service.dart';

class PressureDetailScreen extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final String locationName;

  const PressureDetailScreen({
    super.key,
    required this.weatherData,
    required this.locationName,
  });

  @override
  State<PressureDetailScreen> createState() => _PressureDetailScreenState();
}

class _PressureDetailScreenState extends State<PressureDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final WeatherSettingsService _weatherSettings = WeatherSettingsService();
  final WeatherApiService _weatherService = WeatherApiService();

  // Данные для графиков
  List<FlSpot> _pressure24hSpots = [];
  List<FlSpot> _pressureForecastSpots = [];
  List<String> _timeLabels24h = [];
  List<String> _timeLabelsForecast = [];
  List<Color> _dotColors24h = [];
  List<Color> _dotColorsForecast = [];

  double _minPressure24h = 0;
  double _maxPressure24h = 0;
  double _minPressureForecast = 0;
  double _maxPressureForecast = 0;

  String _pressureTrend = 'stable';
  double _pressure24hChange = 0;
  bool _isLoadingExtended = false;
  Map<String, dynamic>? _extendedData;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadExtendedPressureData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _tabController = TabController(length: 2, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExtendedPressureData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingExtended = true;
    });

    try {
      final position = _getLocationFromWeatherData();
      if (position != null) {
        final extendedData = await _weatherService.getExtendedPressureData(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (mounted) {
          setState(() {
            _extendedData = extendedData;
            _generate24hPressureData();
            _generateForecastPressureData();
            _isLoadingExtended = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки расширенных данных: $e');
      if (mounted) {
        setState(() {
          _isLoadingExtended = false;
          _generateFallbackPressureData();
        });
      }
    }
  }

  Position? _getLocationFromWeatherData() {
    return Position(
      latitude: widget.weatherData.location.lat,
      longitude: widget.weatherData.location.lon,
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

  void _generate24hPressureData() {
    _pressure24hSpots.clear();
    _timeLabels24h.clear();
    _dotColors24h.clear();

    if (_extendedData == null) {
      _generateFallback24hData();
      return;
    }

    final allData = _extendedData!['allData'] as List<WeatherApiResponse>;
    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    // Генерируем данные только за последние 24 часа
    for (int dataIndex = 0; dataIndex < allData.length; dataIndex++) {
      final weatherData = allData[dataIndex];

      for (final day in weatherData.forecast) {
        for (final hour in day.hour) {
          final hourTime = DateTime.parse(hour.time);

          // Только за последние 24 часа
          if (hourTime.isAfter(now.subtract(const Duration(hours: 24))) &&
              hourTime.isBefore(now.add(const Duration(hours: 1)))) {
            final convertedPressure = _weatherSettings.convertPressure(
              hour.pressureMb,
            );
            _pressure24hSpots.add(
              FlSpot(spotIndex.toDouble(), convertedPressure),
            );
            allPressures.add(convertedPressure);

            // Все точки синие для 24h
            _dotColors24h.add(AppConstants.primaryColor);

            // Временные метки каждые 3 часа
            if (spotIndex % 3 == 0) {
              _timeLabels24h.add(DateFormat('HH:mm').format(hourTime));
            } else {
              _timeLabels24h.add('');
            }

            spotIndex++;
          }
        }
      }
    }

    if (allPressures.isNotEmpty) {
      _minPressure24h = allPressures.reduce(math.min) - 2;
      _maxPressure24h = allPressures.reduce(math.max) + 2;

      // Тренд за 24 часа
      if (allPressures.length >= 2) {
        _pressure24hChange = allPressures.last - allPressures.first;
        final threshold =
            _weatherSettings.pressureUnit == PressureUnit.mmhg ? 1.5 : 2.0;

        if (_pressure24hChange > threshold) {
          _pressureTrend = 'rising';
        } else if (_pressure24hChange < -threshold) {
          _pressureTrend = 'falling';
        } else {
          _pressureTrend = 'stable';
        }
      }
    }
  }

  void _generateForecastPressureData() {
    _pressureForecastSpots.clear();
    _timeLabelsForecast.clear();
    _dotColorsForecast.clear();

    if (_extendedData == null) {
      _generateFallbackForecastData();
      return;
    }

    final allData = _extendedData!['allData'] as List<WeatherApiResponse>;
    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    // Генерируем данные: история + прогноз
    for (int dataIndex = 0; dataIndex < allData.length; dataIndex++) {
      final weatherData = allData[dataIndex];

      for (final day in weatherData.forecast) {
        for (final hour in day.hour) {
          final hourTime = DateTime.parse(hour.time);

          // Берем все данные из полученного массива (история + прогноз)
          final convertedPressure = _weatherSettings.convertPressure(
            hour.pressureMb,
          );
          _pressureForecastSpots.add(
            FlSpot(spotIndex.toDouble(), convertedPressure),
          );
          allPressures.add(convertedPressure);

          // Цвета: желтый (прошлое), зеленый (настоящее), синий (будущее)
          Color dotColor;
          if (hourTime.isBefore(now.subtract(const Duration(hours: 1)))) {
            dotColor = Colors.yellow; // История
          } else if (hourTime.difference(now).inHours.abs() <= 1) {
            dotColor = Colors.green; // Текущие данные
          } else {
            dotColor = Colors.blue; // Прогноз
          }
          _dotColorsForecast.add(dotColor);

          // ИСПРАВЛЕНО: Временные метки каждые 3 часа вместо 12
          if (spotIndex % 3 == 0) {
            if (hourTime.day == now.day && hourTime.month == now.month) {
              _timeLabelsForecast.add(
                '${DateFormat('HH:mm').format(hourTime)}\nСегодня',
              );
            } else if (hourTime.difference(now).inDays == 1) {
              _timeLabelsForecast.add(
                '${DateFormat('HH:mm').format(hourTime)}\nЗавтра',
              );
            } else if (hourTime.difference(now).inDays == -1) {
              _timeLabelsForecast.add(
                '${DateFormat('HH:mm').format(hourTime)}\nВчера',
              );
            } else {
              _timeLabelsForecast.add(
                DateFormat('dd.MM\nHH:mm').format(hourTime),
              );
            }
          } else {
            _timeLabelsForecast.add('');
          }

          spotIndex++;
        }
      }
    }

    if (allPressures.isNotEmpty) {
      _minPressureForecast = allPressures.reduce(math.min) - 2;
      _maxPressureForecast = allPressures.reduce(math.max) + 2;
    }
  }

  void _generateFallbackPressureData() {
    _generateFallback24hData();
    _generateFallbackForecastData();
  }

  void _generateFallback24hData() {
    _pressure24hSpots.clear();
    _timeLabels24h.clear();
    _dotColors24h.clear();

    if (widget.weatherData.forecast.isEmpty) return;

    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    for (final day in widget.weatherData.forecast) {
      for (final hour in day.hour) {
        final hourTime = DateTime.parse(hour.time);

        if (hourTime.isAfter(now.subtract(const Duration(hours: 24))) &&
            hourTime.isBefore(now.add(const Duration(hours: 1)))) {
          final convertedPressure = _weatherSettings.convertPressure(
            hour.pressureMb,
          );
          _pressure24hSpots.add(
            FlSpot(spotIndex.toDouble(), convertedPressure),
          );
          allPressures.add(convertedPressure);
          _dotColors24h.add(AppConstants.primaryColor);

          if (spotIndex % 3 == 0) {
            _timeLabels24h.add(DateFormat('HH:mm').format(hourTime));
          } else {
            _timeLabels24h.add('');
          }

          spotIndex++;
        }
      }
    }

    if (allPressures.isNotEmpty) {
      _minPressure24h = allPressures.reduce(math.min) - 2;
      _maxPressure24h = allPressures.reduce(math.max) + 2;
    }
  }

  void _generateFallbackForecastData() {
    _pressureForecastSpots.clear();
    _timeLabelsForecast.clear();
    _dotColorsForecast.clear();

    if (widget.weatherData.forecast.isEmpty) return;

    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    // УЛУЧШЕНО: Увеличили период fallback данных до 3 дней назад
    for (final day in widget.weatherData.forecast) {
      for (final hour in day.hour) {
        final hourTime = DateTime.parse(hour.time);

        if (hourTime.isAfter(now.subtract(const Duration(days: 3)))) {
          final convertedPressure = _weatherSettings.convertPressure(
            hour.pressureMb,
          );
          _pressureForecastSpots.add(
            FlSpot(spotIndex.toDouble(), convertedPressure),
          );
          allPressures.add(convertedPressure);

          // Цвета для fallback данных
          Color dotColor;
          if (hourTime.isBefore(now.subtract(const Duration(hours: 1)))) {
            dotColor = Colors.yellow; // История
          } else if (hourTime.difference(now).inHours.abs() <= 1) {
            dotColor = Colors.green; // Текущие данные
          } else {
            dotColor = Colors.blue; // Прогноз
          }
          _dotColorsForecast.add(dotColor);

          // Временные метки каждые 3 часа
          if (spotIndex % 3 == 0) {
            _timeLabelsForecast.add(
              DateFormat('dd.MM\nHH:mm').format(hourTime),
            );
          } else {
            _timeLabelsForecast.add('');
          }

          spotIndex++;
        }
      }
    }

    if (allPressures.isNotEmpty) {
      _minPressureForecast = allPressures.reduce(math.min) - 2;
      _maxPressureForecast = allPressures.reduce(math.max) + 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentPressure = widget.weatherData.current.pressureMb;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('pressure_analysis'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppConstants.textColor),
            onPressed: _loadExtendedPressureData,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Текущее давление - главная карточка
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCurrentPressureCard(currentPressure),
                  ),
                );
              },
            ),

            // Красивые табы
            _buildTabBar(localizations),

            // Контент табов
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _build24hTab(localizations),
                  _buildForecastTab(localizations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPressureCard(double pressureMb) {
    final localizations = AppLocalizations.of(context);
    final formattedPressure = _weatherSettings.formatPressure(
      pressureMb,
      showUnit: false,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withValues(alpha: 0.1),
            AppConstants.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.speed,
                  color: AppConstants.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('current_pressure'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.locationName,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isLoadingExtended)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Основное значение давления
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedPressure,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  _weatherSettings.getPressureUnitSymbol(),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Статус давления
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getPressureStatusColor(pressureMb).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getPressureStatusColor(
                  pressureMb,
                ).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              _getPressureStatus(pressureMb),
              style: TextStyle(
                color: _getPressureStatusColor(pressureMb),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(6),
        labelColor: Colors.white,
        unselectedLabelColor: AppConstants.textColor.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(localizations.translate('data_24_hours')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 18),
                const SizedBox(width: 8),
                Text(localizations.translate('forecast')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build24hTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Тренд за 24 часа
          _buildTrendCard(),
          const SizedBox(height: 24),
          // График 24 часа
          _buildPressureChart(
            spots: _pressure24hSpots,
            timeLabels: _timeLabels24h,
            dotColors: _dotColors24h,
            minY: _minPressure24h,
            maxY: _maxPressure24h,
            title: localizations.translate('data_24_hours'),
            chartWidth: MediaQuery.of(context).size.width * 3, // В 3 раза шире
          ),
          const SizedBox(height: 24),
          // Влияние на рыбалку
          _buildFishingImpactCard(widget.weatherData.current.pressureMb),
          const SizedBox(height: 24),
          // Рекомендации
          _buildRecommendationsCard(widget.weatherData.current.pressureMb),
          SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildForecastTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // График прогноза
          _buildPressureChart(
            spots: _pressureForecastSpots,
            timeLabels: _timeLabelsForecast,
            dotColors: _dotColorsForecast,
            minY: _minPressureForecast,
            maxY: _maxPressureForecast,
            title: localizations.translate('pressure_analysis'),
            chartWidth:
                MediaQuery.of(context).size.width *
                5, // В 5 раз шире для большего количества данных
            showLegend: true,
          ),
          const SizedBox(height: 24),
          // Влияние на рыбалку
          _buildFishingImpactCard(widget.weatherData.current.pressureMb),
          const SizedBox(height: 24),
          // Рекомендации
          _buildRecommendationsCard(widget.weatherData.current.pressureMb),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('pressure_trend_24h'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendItem(
                  localizations.translate('trend'),
                  _getTrendText(_pressureTrend),
                  _getTrendIcon(_pressureTrend),
                  _getTrendColor(_pressureTrend),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendItem(
                  localizations.translate('change'),
                  '${_pressure24hChange >= 0 ? '+' : ''}${_pressure24hChange.toStringAsFixed(1)} ${_weatherSettings.getPressureUnitSymbol()}',
                  _pressure24hChange >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  _pressure24hChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendDescription(),
        ],
      ),
    );
  }

  Widget _buildTrendItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendDescription() {
    final localizations = AppLocalizations.of(context);
    String description;
    Color color;

    switch (_pressureTrend) {
      case 'rising':
        description = localizations.translate('pressure_rising_description');
        color = Colors.green;
        break;
      case 'falling':
        description = localizations.translate('pressure_falling_description');
        color = Colors.red;
        break;
      default:
        description = localizations.translate('pressure_stable_description');
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureChart({
    required List<FlSpot> spots,
    required List<String> timeLabels,
    required List<Color> dotColors,
    required double minY,
    required double maxY,
    required String title,
    required double chartWidth,
    bool showLegend = false,
  }) {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 14, // Уменьшили с 16 до 14
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_extendedData != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LIVE DATA',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (spots.isEmpty)
            Expanded(
              child: Center(
                child:
                    _isLoadingExtended
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Загрузка данных...',
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        )
                        : Text(
                          localizations.translate('no_data_to_display'),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  // Зафиксированная левая шкала
                  SizedBox(width: 50, child: _buildFixedYAxis(minY, maxY)),
                  // Скроллируемая область графика
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: _getDetailedGridInterval(),
                              verticalInterval: math.max(
                                1,
                                spots.length / 24,
                              ), // Больше вертикальных линий
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: AppConstants.textColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: AppConstants.textColor.withValues(
                                    alpha: 0.05,
                                  ),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  interval: math.max(
                                    1,
                                    spots.length / 16,
                                  ), // Больше меток времени
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < timeLabels.length &&
                                        timeLabels[index].isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          timeLabels[index],
                                          style: TextStyle(
                                            color: AppConstants.textColor
                                                .withValues(alpha: 0.7),
                                            fontSize: 9,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppConstants.primaryColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (
                                    spot,
                                    percent,
                                    barData,
                                    index,
                                  ) {
                                    final color =
                                        index < dotColors.length
                                            ? dotColors[index]
                                            : AppConstants.primaryColor;
                                    return FlDotCirclePainter(
                                      radius: 3,
                                      color: color,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppConstants.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      AppConstants.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor:
                                    (touchedSpot) => AppConstants.surfaceColor
                                        .withValues(alpha: 0.9),
                                tooltipBorder: BorderSide(
                                  color: AppConstants.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                                tooltipRoundedRadius: 8,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final pressure = spot.y;
                                    return LineTooltipItem(
                                      '${pressure.toStringAsFixed(1)} ${_weatherSettings.getPressureUnitSymbol()}',
                                      TextStyle(
                                        color: AppConstants.textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            minY: minY,
                            maxY: maxY,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Легенда для прогноза
          if (showLegend) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.yellow, 'История'),
                _buildLegendItem(Colors.green, 'Сейчас'),
                _buildLegendItem(Colors.blue, 'Прогноз'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFixedYAxis(double minY, double maxY) {
    final interval = _getDetailedGridInterval();
    final steps = ((maxY - minY) / interval).ceil();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps + 1, (index) {
        final value = maxY - (index * interval);
        if (value >= minY && value <= maxY) {
          return Text(
            value.round().toString(),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFishingImpactCard(double pressure) {
    final localizations = AppLocalizations.of(context);
    final impact = _getFishingImpact(pressure);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: impact['color'].withValues(alpha: 0.3),
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
                  color: impact['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.set_meal, color: impact['color'], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizations.translate('fishing_impact'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: impact['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              impact['level'],
              style: TextStyle(
                color: impact['color'],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            impact['description'],
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(double pressure) {
    final localizations = AppLocalizations.of(context);
    final recommendations = _getPressureRecommendations(pressure);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
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
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('recommendations'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations
              .map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // Вспомогательные методы

  double _getDetailedGridInterval() {
    switch (_weatherSettings.pressureUnit) {
      case PressureUnit.mmhg:
        return 2; // Каждые 2 мм рт.ст.
      case PressureUnit.hpa:
        return 3; // Каждые 3 гПа
      case PressureUnit.inhg:
        return 0.1; // Каждые 0.1 дюйма
    }
  }

  Color _getPressureStatusColor(double pressure) {
    final calibratedPressure = pressure + _weatherSettings.barometerCalibration;

    if (calibratedPressure >= 1010 && calibratedPressure <= 1025)
      return Colors.green;
    if (calibratedPressure < 1000 || calibratedPressure > 1030)
      return Colors.red;
    return Colors.orange;
  }

  String _getPressureStatus(double pressure) {
    final localizations = AppLocalizations.of(context);
    final calibratedPressure = pressure + _weatherSettings.barometerCalibration;

    if (calibratedPressure >= 1010 && calibratedPressure <= 1025) {
      return localizations.translate('optimal_for_fishing');
    }
    if (calibratedPressure < 1000) {
      return localizations.translate('low_pressure');
    }
    if (calibratedPressure > 1030) {
      return localizations.translate('high_pressure');
    }
    return localizations.translate('moderate_pressure');
  }

  String _getTrendText(String trend) {
    final localizations = AppLocalizations.of(context);
    switch (trend) {
      case 'rising':
        return localizations.translate('rising');
      case 'falling':
        return localizations.translate('falling');
      default:
        return localizations.translate('stable');
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'rising':
        return Icons.trending_up;
      case 'falling':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising':
        return Colors.green;
      case 'falling':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Map<String, dynamic> _getFishingImpact(double pressure) {
    final localizations = AppLocalizations.of(context);
    final calibratedPressure = pressure + _weatherSettings.barometerCalibration;

    if (calibratedPressure >= 1010 && calibratedPressure <= 1025) {
      return {
        'level': localizations.translate('excellent_for_fishing'),
        'description': localizations.translate(
          'pressure_excellent_description',
        ),
        'color': Colors.green,
      };
    } else if (calibratedPressure < 1000) {
      return {
        'level': localizations.translate('poor_for_fishing'),
        'description': localizations.translate('pressure_low_description'),
        'color': Colors.red,
      };
    } else if (calibratedPressure > 1030) {
      return {
        'level': localizations.translate('poor_for_fishing'),
        'description': localizations.translate('pressure_high_description'),
        'color': Colors.red,
      };
    } else {
      return {
        'level': localizations.translate('moderate_for_fishing'),
        'description': localizations.translate('pressure_moderate_description'),
        'color': Colors.orange,
      };
    }
  }

  List<String> _getPressureRecommendations(double pressure) {
    final localizations = AppLocalizations.of(context);
    final calibratedPressure = pressure + _weatherSettings.barometerCalibration;

    if (calibratedPressure >= 1010 && calibratedPressure <= 1025) {
      return [
        localizations.translate('pressure_rec_optimal_1'),
        localizations.translate('pressure_rec_optimal_2'),
        localizations.translate('pressure_rec_optimal_3'),
      ];
    } else if (calibratedPressure < 1000) {
      return [
        localizations.translate('pressure_rec_low_1'),
        localizations.translate('pressure_rec_low_2'),
        localizations.translate('pressure_rec_low_3'),
      ];
    } else if (calibratedPressure > 1030) {
      return [
        localizations.translate('pressure_rec_high_1'),
        localizations.translate('pressure_rec_high_2'),
        localizations.translate('pressure_rec_high_3'),
      ];
    } else {
      return [
        localizations.translate('pressure_rec_moderate_1'),
        localizations.translate('pressure_rec_moderate_2'),
      ];
    }
  }
}
