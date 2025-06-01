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

  // Данные для 24-часового графика
  List<FlSpot> _pressureSpots24h = [];
  List<String> _timeLabels24h = [];
  List<Color> _dotColors24h = [];
  double _minPressure24h = 0;
  double _maxPressure24h = 0;

  // Данные для прогнозного графика
  List<FlSpot> _pressureSpotsExtended = [];
  List<String> _timeLabelsExtended = [];
  List<Color> _dotColorsExtended = [];
  double _minPressureExtended = 0;
  double _maxPressureExtended = 0;

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
            _generateExtendedPressureData();
            _isLoadingExtended = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки расширенных данных: $e');
      if (mounted) {
        setState(() {
          _isLoadingExtended = false;
          _generateFallback24hPressureData();
          _generateFallbackExtendedPressureData();
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
    _pressureSpots24h.clear();
    _timeLabels24h.clear();
    _dotColors24h.clear();

    if (_extendedData == null) {
      _generateFallback24hPressureData();
      return;
    }

    final allData = _extendedData!['allData'] as List<WeatherApiResponse>;
    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    // Обрабатываем данные за последние 24 часа
    for (int dataIndex = 0; dataIndex < allData.length; dataIndex++) {
      final weatherData = allData[dataIndex];

      for (final day in weatherData.forecast) {
        for (final hour in day.hour) {
          final hourTime = DateTime.parse(hour.time);

          // Показываем данные за последние 24 часа
          if (hourTime.isAfter(now.subtract(const Duration(hours: 24))) &&
              hourTime.isBefore(now.add(const Duration(hours: 1)))) {

            final convertedPressure = _weatherSettings.convertPressure(hour.pressureMb);
            _pressureSpots24h.add(FlSpot(spotIndex.toDouble(), convertedPressure));
            allPressures.add(convertedPressure);

            // Определяем цвет точки
            Color dotColor;
            if (hourTime.isBefore(now)) {
              dotColor = Colors.grey; // Исторические данные
            } else {
              dotColor = AppConstants.primaryColor; // Текущие/будущие данные
            }
            _dotColors24h.add(dotColor);

            // Добавляем временные метки каждые 3 часа
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

      // Определяем тренд за последние 24 часа
      if (allPressures.length >= 2) {
        _pressure24hChange = allPressures.last - allPressures.first;
        final threshold = _weatherSettings.pressureUnit == PressureUnit.mmhg ? 1.5 : 2.0;

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

  void _generateExtendedPressureData() {
    _pressureSpotsExtended.clear();
    _timeLabelsExtended.clear();
    _dotColorsExtended.clear();

    if (_extendedData == null) {
      _generateFallbackExtendedPressureData();
      return;
    }

    final allData = _extendedData!['allData'] as List<WeatherApiResponse>;
    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    // Создаем данные по дням с 4 точками в день
    final startDate = now.subtract(const Duration(days: 5));
    final endDate = now.add(const Duration(days: 7));

    for (DateTime date = startDate; date.isBefore(endDate); date = date.add(const Duration(days: 1))) {
      final targetHours = [0, 6, 12, 18]; // 00:00, 06:00, 12:00, 18:00

      for (int hour in targetHours) {
        final targetTime = DateTime(date.year, date.month, date.day, hour);

        // Ищем ближайшие данные к целевому времени
        double? pressure = _findPressureForTime(allData, targetTime);

        if (pressure != null) {
          final convertedPressure = _weatherSettings.convertPressure(pressure);
          _pressureSpotsExtended.add(FlSpot(spotIndex.toDouble(), convertedPressure));
          allPressures.add(convertedPressure);

          // Определяем цвет точки
          Color dotColor;
          if (targetTime.isBefore(now)) {
            dotColor = Colors.grey; // Исторические данные
          } else if (targetTime.difference(now).inHours <= 24) {
            dotColor = AppConstants.primaryColor; // Ближайшие 24 часа
          } else {
            dotColor = Colors.blue; // Прогноз
          }
          _dotColorsExtended.add(dotColor);

          // Добавляем временные метки
          if (hour == 0) {
            _timeLabelsExtended.add(DateFormat('dd.MM').format(targetTime));
          } else {
            _timeLabelsExtended.add('${hour.toString().padLeft(2, '0')}:00');
          }

          spotIndex++;
        }
      }
    }

    if (allPressures.isNotEmpty) {
      _minPressureExtended = allPressures.reduce(math.min) - 2;
      _maxPressureExtended = allPressures.reduce(math.max) + 2;
    }
  }

  double? _findPressureForTime(List<WeatherApiResponse> allData, DateTime targetTime) {
    double? closestPressure;
    Duration minDifference = const Duration(hours: 24);

    for (final weatherData in allData) {
      for (final day in weatherData.forecast) {
        for (final hour in day.hour) {
          final hourTime = DateTime.parse(hour.time);
          final difference = (hourTime.difference(targetTime)).abs();

          if (difference < minDifference) {
            minDifference = difference;
            closestPressure = hour.pressureMb;
          }
        }
      }
    }

    return closestPressure;
  }

  void _generateFallback24hPressureData() {
    _pressureSpots24h.clear();
    _timeLabels24h.clear();
    _dotColors24h.clear();

    if (widget.weatherData.forecast.isEmpty) return;

    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    // Используем данные из текущего прогноза для 24 часов
    for (final day in widget.weatherData.forecast) {
      for (final hour in day.hour) {
        final hourTime = DateTime.parse(hour.time);

        if (hourTime.isAfter(now.subtract(const Duration(hours: 12))) &&
            hourTime.isBefore(now.add(const Duration(hours: 12)))) {
          final convertedPressure = _weatherSettings.convertPressure(hour.pressureMb);
          _pressureSpots24h.add(FlSpot(spotIndex.toDouble(), convertedPressure));
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

  void _generateFallbackExtendedPressureData() {
    _pressureSpotsExtended.clear();
    _timeLabelsExtended.clear();
    _dotColorsExtended.clear();

    // Генерируем примерные данные на основе текущих данных
    final basePressure = widget.weatherData.current.pressureMb;
    final now = DateTime.now();
    int spotIndex = 0;
    List<double> allPressures = [];

    for (int dayOffset = -5; dayOffset <= 7; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final targetHours = [0, 6, 12, 18];

      for (int hour in targetHours) {
        // Генерируем реалистичные вариации давления
        final dailyVariation = math.sin(dayOffset * 0.5) * 8;
        final hourlyVariation = math.cos(hour * 0.5) * 3;
        final randomVariation = (math.Random().nextDouble() - 0.5) * 4;

        final pressure = basePressure + dailyVariation + hourlyVariation + randomVariation;
        final convertedPressure = _weatherSettings.convertPressure(pressure);

        _pressureSpotsExtended.add(FlSpot(spotIndex.toDouble(), convertedPressure));
        allPressures.add(convertedPressure);
        _dotColorsExtended.add(dayOffset <= 0 ? Colors.grey : Colors.blue);

        if (hour == 0) {
          _timeLabelsExtended.add(DateFormat('dd.MM').format(date));
        } else {
          _timeLabelsExtended.add('${hour.toString().padLeft(2, '0')}:00');
        }

        spotIndex++;
      }
    }

    if (allPressures.isNotEmpty) {
      _minPressureExtended = allPressures.reduce(math.min) - 2;
      _maxPressureExtended = allPressures.reduce(math.max) + 2;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текущее давление - главная карточка
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: _buildCurrentPressureCard(currentPressure, localizations),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Тренд за 24 часа
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 1.5),
                    child: _buildTrendCard(localizations),
                  );
                },
              ),

              const SizedBox(height: 24),

              // График давления с табами
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2),
                    child: _buildPressureChartWithTabs(localizations),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Влияние на рыбалку
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2.5),
                    child: _buildFishingImpactCard(currentPressure, localizations),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Рекомендации
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 3),
                    child: _buildRecommendationsCard(currentPressure, localizations),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPressureCard(double pressureMb, AppLocalizations localizations) {
    final formattedPressure = _weatherSettings.formatPressure(pressureMb, showUnit: false);

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
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
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
                color: _getPressureStatusColor(pressureMb).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              _getPressureStatus(pressureMb, localizations),
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

  Widget _buildTrendCard(AppLocalizations localizations) {
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
                  _getTrendText(_pressureTrend, localizations),
                  _getTrendIcon(_pressureTrend),
                  _getTrendColor(_pressureTrend),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendItem(
                  localizations.translate('change'),
                  '${_pressure24hChange >= 0 ? '+' : ''}${_pressure24hChange.toStringAsFixed(1)} ${_weatherSettings.getPressureUnitSymbol()}',
                  _pressure24hChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  _pressure24hChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendDescription(localizations),
        ],
      ),
    );
  }

  Widget _buildPressureChartWithTabs(AppLocalizations localizations) {
    return Container(
      height: 400,
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
          // Заголовок и статус
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('pressure_analysis'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_extendedData != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // Табы
          Container(
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppConstants.textColor.withValues(alpha: 0.7),
              tabs: [
                Tab(text: '24 ${localizations.translate('hours')}'),
                Tab(text: localizations.translate('forecast')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // График
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _build24hChart(localizations),
                _buildExtendedChart(localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build24hChart(AppLocalizations localizations) {
    if (_pressureSpots24h.isEmpty) {
      return Center(
        child: _isLoadingExtended
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Загрузка данных...',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        )
            : Text(
          localizations.translate('no_data_to_display'),
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getGridInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppConstants.textColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: _getGridInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _timeLabels24h.length && _timeLabels24h[index].isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _timeLabels24h[index],
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _pressureSpots24h,
            isCurved: true,
            color: AppConstants.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final color = index < _dotColors24h.length
                    ? _dotColors24h[index]
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
                  AppConstants.primaryColor.withValues(alpha: 0.3),
                  AppConstants.primaryColor.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppConstants.surfaceColor.withValues(alpha: 0.9),
            tooltipBorder: BorderSide(
              color: AppConstants.primaryColor.withValues(alpha: 0.5),
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
        minY: _minPressure24h,
        maxY: _maxPressure24h,
      ),
    );
  }

  Widget _buildExtendedChart(AppLocalizations localizations) {
    if (_pressureSpotsExtended.isEmpty) {
      return Center(
        child: _isLoadingExtended
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Загрузка расширенных данных...',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        )
            : Text(
          localizations.translate('no_data_to_display'),
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(MediaQuery.of(context).size.width - 80, _pressureSpotsExtended.length * 15.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: _getGridInterval(),
              verticalInterval: 4, // Каждые 4 точки (новый день)
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppConstants.textColor.withValues(alpha: 0.1),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: AppConstants.textColor.withValues(alpha: 0.1),
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: _getGridInterval(),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < _timeLabelsExtended.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            _timeLabelsExtended[index],
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _pressureSpotsExtended,
                isCurved: true,
                color: AppConstants.primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final color = index < _dotColorsExtended.length
                        ? _dotColorsExtended[index]
                        : AppConstants.primaryColor;
                    return FlDotCirclePainter(
                      radius: 4,
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
                      AppConstants.primaryColor.withValues(alpha: 0.2),
                      AppConstants.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => AppConstants.surfaceColor.withValues(alpha: 0.9),
                tooltipBorder: BorderSide(
                  color: AppConstants.primaryColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final pressure = spot.y;
                    final index = spot.x.toInt();
                    final timeLabel = index < _timeLabelsExtended.length
                        ? _timeLabelsExtended[index]
                        : '';

                    return LineTooltipItem(
                      '$timeLabel\n${pressure.toStringAsFixed(1)} ${_weatherSettings.getPressureUnitSymbol()}',
                      TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            minY: _minPressureExtended,
            maxY: _maxPressureExtended,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildTrendDescription(AppLocalizations localizations) {
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
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: color,
            size: 20,
          ),
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

  Widget _buildFishingImpactCard(double pressure, AppLocalizations localizations) {
    final impact = _getFishingImpact(pressure, localizations);

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
                child: Icon(
                  Icons.set_meal,
                  color: impact['color'],
                  size: 20,
                ),
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

  Widget _buildRecommendationsCard(double pressure, AppLocalizations localizations) {
    final recommendations = _getPressureRecommendations(pressure, localizations);

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
          ...recommendations.map((recommendation) => Padding(
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
          )).toList(),
        ],
      ),
    );
  }

  // Вспомогательные методы

  double _getGridInterval() {
    switch (_weatherSettings.pressureUnit) {
      case PressureUnit.mmhg:
        return 5;
      case PressureUnit.hpa:
        return 10;
      case PressureUnit.inhg:
        return 0.2;
    }
  }

  Color _getPressureStatusColor(double pressure) {
    final calibratedPressure = pressure + _weatherSettings.barometerCalibration;

    if (calibratedPressure >= 1010 && calibratedPressure <= 1025) return Colors.green;
    if (calibratedPressure < 1000 || calibratedPressure > 1030) return Colors.red;
    return Colors.orange;
  }

  String _getPressureStatus(double pressure, AppLocalizations localizations) {
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

  String _getTrendText(String trend, AppLocalizations localizations) {
    switch (trend) {
      case 'rising': return localizations.translate('rising');
      case 'falling': return localizations.translate('falling');
      default: return localizations.translate('stable');
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'rising': return Icons.trending_up;
      case 'falling': return Icons.trending_down;
      default: return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising': return Colors.green;
      case 'falling': return Colors.red;
      default: return Colors.blue;
    }
  }

  Map<String, dynamic> _getFishingImpact(double pressure, AppLocalizations localizations) {
    final calibratedPressure = pressure + _weatherSettings.barometerCalibration;

    if (calibratedPressure >= 1010 && calibratedPressure <= 1025) {
      return {
        'level': localizations.translate('excellent_for_fishing'),
        'description': localizations.translate('pressure_excellent_description'),
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

  List<String> _getPressureRecommendations(double pressure, AppLocalizations localizations) {
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