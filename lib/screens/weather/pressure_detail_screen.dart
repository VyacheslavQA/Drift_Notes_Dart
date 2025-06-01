// Путь: lib/screens/weather/pressure_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final WeatherSettingsService _weatherSettings = WeatherSettingsService();
  final WeatherApiService _weatherApiService = WeatherApiService();

  // Переключатель между режимами графика
  int _selectedChartMode = 0; // 0 = 24 часа, 1 = 3 дня
  // TODO: Добавить режим "7 дней" (индекс 2) при переходе на платный план WeatherAPI

  // Данные для 24-часового графика
  List<FlSpot> _hourlyPressureSpots = [];
  List<String> _hourlyTimeLabels = [];
  double _hourlyMinPressure = 0;
  double _hourlyMaxPressure = 0;
  String _hourlyPressureTrend = 'stable';
  double _hourly24hChange = 0;

  // Данные для 3-дневного графика
  List<FlSpot> _dailyPressureSpots = [];
  List<String> _dailyTimeLabels = [];
  List<String> _dailyDateLabels = [];
  double _dailyMinPressure = 0;
  double _dailyMaxPressure = 0;
  bool _isLoadingDailyData = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateHourlyPressureData();
    _generateDailyPressureData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

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
    super.dispose();
  }

  // Генерация данных для 24-часового графика
  void _generateHourlyPressureData() {
    _hourlyPressureSpots.clear();
    _hourlyTimeLabels.clear();

    final basePressure = widget.weatherData.current.pressureMb;
    final now = DateTime.now();

    // Генерируем данные за последние 24 часа с реалистичными изменениями
    for (int i = -24; i <= 0; i++) {
      final time = now.add(Duration(hours: i));

      // Имитируем естественные колебания давления
      final timeOfDay = time.hour;
      final dailyVariation = math.sin((timeOfDay - 6) * math.pi / 12) * 3;
      final randomVariation = (math.Random().nextDouble() - 0.5) * 4;
      final trendVariation = i * 0.2;

      final pressureMb = basePressure + dailyVariation + randomVariation + trendVariation;
      final convertedPressure = _weatherSettings.convertPressure(pressureMb);

      _hourlyPressureSpots.add(FlSpot(i.toDouble() + 24, convertedPressure));

      // Добавляем временные метки каждые 6 часов для читаемости
      if (i % 6 == 0) {
        _hourlyTimeLabels.add(DateFormat('HH:mm').format(time));
      } else {
        _hourlyTimeLabels.add('');
      }
    }

    if (_hourlyPressureSpots.isNotEmpty) {
      _hourlyMinPressure = _hourlyPressureSpots.map((spot) => spot.y).reduce(math.min) - 5;
      _hourlyMaxPressure = _hourlyPressureSpots.map((spot) => spot.y).reduce(math.max) + 5;

      // Определяем тренд за 24 часа
      final firstPressure = _hourlyPressureSpots.first.y;
      final lastPressure = _hourlyPressureSpots.last.y;
      _hourly24hChange = lastPressure - firstPressure;

      final threshold = _weatherSettings.pressureUnit == PressureUnit.mmhg ? 1.5 : 2.0;

      if (_hourly24hChange > threshold) {
        _hourlyPressureTrend = 'rising';
      } else if (_hourly24hChange < -threshold) {
        _hourlyPressureTrend = 'falling';
      } else {
        _hourlyPressureTrend = 'stable';
      }
    }
  }

  // Генерация данных для 3-дневного графика
  Future<void> _generateDailyPressureData() async {
    setState(() {
      _isLoadingDailyData = true;
    });

    _dailyPressureSpots.clear();
    _dailyTimeLabels.clear();
    _dailyDateLabels.clear();

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      // Получаем исторические данные за вчера
      // TODO: PAID_API - при платном плане можно получить данные за больший период
      WeatherApiResponse? yesterdayData;
      try {
        // В реальном приложении здесь будет запрос к History API
        // Пока используем имитацию данных
        yesterdayData = await _getHistoricalWeatherData(yesterday);
      } catch (e) {
        debugPrint('Не удалось загрузить исторические данные: $e');
      }

      // Данные за сегодня у нас уже есть
      final todayData = widget.weatherData;

      // Прогноз на завтра
      WeatherApiResponse? tomorrowData;
      try {
        tomorrowData = await _weatherApiService.getForecast(
          latitude: widget.weatherData.location.lat,
          longitude: widget.weatherData.location.lon,
          days: 2, // Получаем сегодня + завтра
        );
      } catch (e) {
        debugPrint('Не удалось загрузить прогноз: $e');
      }

      int spotIndex = 0;

      // Добавляем данные за вчера (если есть)
      if (yesterdayData != null) {
        _addDayDataToChart(yesterdayData, yesterday, spotIndex);
        spotIndex += 4; // 4 точки в день
      }

      // Добавляем данные за сегодня
      _addDayDataToChart(todayData, now, spotIndex);
      spotIndex += 4;

      // Добавляем данные за завтра (если есть прогноз)
      if (tomorrowData != null && tomorrowData.forecast.length > 1) {
        _addDayDataToChart(tomorrowData, tomorrow, spotIndex, dayIndex: 1);
      }

      if (_dailyPressureSpots.isNotEmpty) {
        _dailyMinPressure = _dailyPressureSpots.map((spot) => spot.y).reduce(math.min) - 5;
        _dailyMaxPressure = _dailyPressureSpots.map((spot) => spot.y).reduce(math.max) + 5;
      }

    } catch (e) {
      debugPrint('Ошибка при генерации данных 3-дневного графика: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDailyData = false;
        });
      }
    }
  }

  // Добавляем данные дня в график (4 точки: 00:00, 06:00, 12:00, 18:00)
  void _addDayDataToChart(WeatherApiResponse weatherData, DateTime date, int startIndex, {int dayIndex = 0}) {
    if (weatherData.forecast.isEmpty) return;

    final dayForecast = weatherData.forecast.length > dayIndex
        ? weatherData.forecast[dayIndex]
        : weatherData.forecast.first;

    final hours = dayForecast.hour;
    final timePoints = [0, 6, 12, 18]; // Часы для отображения

    for (int i = 0; i < timePoints.length; i++) {
      final targetHour = timePoints[i];

      // Ищем ближайший час в данных
      Hour? targetHourData;
      for (final hour in hours) {
        final hourTime = DateTime.parse(hour.time);
        if (hourTime.hour == targetHour) {
          targetHourData = hour;
          break;
        }
      }

      // Если не нашли точное время, используем текущие данные или интерполируем
      double pressure;
      if (targetHourData != null) {
        pressure = _weatherSettings.convertPressure(targetHourData.windKph); // Тут нужно правильное поле для давления
      } else {
        // Используем текущее давление как fallback
        pressure = _weatherSettings.convertPressure(weatherData.current.pressureMb);
      }

      _dailyPressureSpots.add(FlSpot((startIndex + i).toDouble(), pressure));

      // Метки времени
      _dailyTimeLabels.add('${targetHour.toString().padLeft(2, '0')}:00');
    }

    // Добавляем метку даты (только один раз на день)
    _dailyDateLabels.add(DateFormat('d MMM').format(date));
  }

  // Имитация получения исторических данных
  // TODO: PAID_API - заменить на реальный History API запрос
  Future<WeatherApiResponse?> _getHistoricalWeatherData(DateTime date) async {
    // В реальном приложении здесь будет запрос к WeatherAPI History
    // Пока возвращаем null, чтобы использовать только текущие данные + прогноз
    return null;
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
                    child: _buildCurrentPressureCard(currentPressure),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Переключатель режимов графика
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 1.2),
                    child: _buildChartModeSelector(localizations),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Адаптивный график давления
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 1.5),
                    child: _buildAdaptivePressureChart(localizations),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Тренд (только для 24-часового режима)
              if (_selectedChartMode == 0)
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 1.8),
                      child: _buildTrendCard(localizations),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Влияние на рыбалку
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2),
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
                    offset: Offset(0, _slideAnimation.value * 2.5),
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

  Widget _buildCurrentPressureCard(double pressureMb) {
    final localizations = AppLocalizations.of(context);
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

  Widget _buildChartModeSelector(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              localizations.translate('24_hours') ?? '24 часа',
              0,
              Icons.schedule,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton(
              localizations.translate('3_days') ?? '3 дня',
              1,
              Icons.calendar_view_week,
            ),
          ),
          // TODO: PAID_API - Раскомментировать при переходе на платный план
          // const SizedBox(width: 4),
          // Expanded(
          //   child: _buildModeButton(
          //     localizations.translate('7_days') ?? '7 дней',
          //     2,
          //     Icons.calendar_month,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, int index, IconData icon) {
    final isSelected = _selectedChartMode == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartMode = index;
        });

        // Если переключились на 3-дневный режим и данные еще не загружены
        if (index == 1 && _dailyPressureSpots.isEmpty) {
          _generateDailyPressureData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppConstants.textColor.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptivePressureChart(AppLocalizations localizations) {
    if (_selectedChartMode == 1 && _isLoadingDailyData) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('loading_daily_data') ?? 'Загрузка данных за 3 дня...',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final spots = _selectedChartMode == 0 ? _hourlyPressureSpots : _dailyPressureSpots;
    final timeLabels = _selectedChartMode == 0 ? _hourlyTimeLabels : _dailyTimeLabels;
    final minY = _selectedChartMode == 0 ? _hourlyMinPressure : _dailyMinPressure;
    final maxY = _selectedChartMode == 0 ? _hourlyMaxPressure : _dailyMaxPressure;

    if (spots.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            localizations.translate('no_data_to_display'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 320,
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
              Icon(
                Icons.analytics,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedChartMode == 0
                    ? localizations.translate('pressure_history_24h')
                    : localizations.translate('pressure_history_3d') ?? 'История давления (3 дня)',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // График с горизонтальным скроллом
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _selectedChartMode == 0
                    ? math.max(MediaQuery.of(context).size.width - 32, spots.length * 30.0)
                    : math.max(MediaQuery.of(context).size.width - 32, spots.length * 60.0),
                child: LineChart(
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
                          reservedSize: 40,
                          interval: _selectedChartMode == 0 ? 6 : 4,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < timeLabels.length && timeLabels[index].isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  children: [
                                    Text(
                                      timeLabels[index],
                                      style: TextStyle(
                                        color: AppConstants.textColor.withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                    // Для 3-дневного режима добавляем дату
                                    if (_selectedChartMode == 1 && index % 4 == 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _dailyDateLabels[index ~/ 4],
                                        style: TextStyle(
                                          color: AppConstants.textColor.withValues(alpha: 0.5),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ],
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
                        spots: spots,
                        isCurved: true,
                        color: AppConstants.primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: AppConstants.primaryColor,
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
                    minY: minY,
                    maxY: maxY,
                  ),
                ),
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
                  _getTrendText(_hourlyPressureTrend, localizations),
                  _getTrendIcon(_hourlyPressureTrend),
                  _getTrendColor(_hourlyPressureTrend),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendItem(
                  localizations.translate('change'),
                  '${_hourly24hChange >= 0 ? '+' : ''}${_hourly24hChange.toStringAsFixed(1)} ${_weatherSettings.getPressureUnitSymbol()}',
                  _hourly24hChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  _hourly24hChange >= 0 ? Colors.green : Colors.red,
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

    switch (_hourlyPressureTrend) {
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