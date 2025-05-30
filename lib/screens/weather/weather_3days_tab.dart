// Путь: lib/screens/weather/weather_3days_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

class Weather3DaysTab extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final Map<String, dynamic>? fishingForecast;
  final String locationName;
  final VoidCallback onRefresh;

  const Weather3DaysTab({
    super.key,
    required this.weatherData,
    this.fishingForecast,
    required this.locationName,
    required this.onRefresh,
  });

  @override
  State<Weather3DaysTab> createState() => _Weather3DaysTabState();
}

class _Weather3DaysTabState extends State<Weather3DaysTab>
    with SingleTickerProviderStateMixin {
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppConstants.primaryColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildCompactHeader(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildAverageBiteMeter(),
                  const SizedBox(height: 24),
                  _buildThreeDaysCards(),
                  const SizedBox(height: 24),
                  _buildBestDaysSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final localizations = AppLocalizations.of(context);
    final current = widget.weatherData.current;

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                current.isDay == 1
                    ? Colors.blue[400]!.withValues(alpha: 0.4)
                    : Colors.indigo[800]!.withValues(alpha: 0.4),
                AppConstants.backgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Заголовок периода
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppConstants.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '3 ${localizations.translate('days_many')}',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.locationName,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Сегодняшняя температура (компактно)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${localizations.translate('today')}: ',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherSettings.convertTemperature(current.tempC).round().toString(),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w200,
                              height: 1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _weatherSettings.getTemperatureUnitSymbol(),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _translateWeatherDescription(current.condition.text),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _getWeatherIcon(current.condition.code),
                        size: 28,
                        color: AppConstants.textColor.withValues(alpha: 0.8),
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

  Widget _buildAverageBiteMeter() {
    final localizations = AppLocalizations.of(context);
    final averageActivity = _calculateAverageActivity();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBiteActivityColor(averageActivity).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppConstants.textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('bite_forecast')} (3 ${localizations.translate('days_many')})',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Мини клёвометр
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.textColor.withValues(alpha: 0.1),
                            width: 6,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(80, 80),
                        painter: BiteMeterPainter3Days(
                          progress: averageActivity,
                          color: _getBiteActivityColor(averageActivity),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(averageActivity * 100).round()}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getBiteActivityColor(averageActivity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getBiteActivityText(averageActivity),
                          style: TextStyle(
                            color: _getBiteActivityColor(averageActivity),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${localizations.translate('average')} ${localizations.translate('bite_activity').toLowerCase()} за 3 дня',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeDaysCards() {
    final localizations = AppLocalizations.of(context);
    final forecast = widget.weatherData.forecast.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.view_agenda,
                color: AppConstants.textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('forecast'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Карточки дней
          ...forecast.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isToday = index == 0;
            final isBestDay = _isDayGoodForFishing(day);

            return _buildDayCard(day, isToday, isBestDay, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDayCard(ForecastDay day, bool isToday, bool isBestDay, int dayIndex) {
    final localizations = AppLocalizations.of(context);
    final date = DateTime.parse(day.date);
    final dayActivity = _calculateDayActivity(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestDay
              ? Colors.green.withValues(alpha: 0.4)
              : isToday
              ? AppConstants.primaryColor.withValues(alpha: 0.4)
              : AppConstants.textColor.withValues(alpha: 0.1),
          width: isBestDay ? 2 : 1,
        ),
        boxShadow: isBestDay ? [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Заголовок дня
          Row(
            children: [
              // Дата и день недели
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? localizations.translate('today')
                          : _formatDayName(date),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM').format(date),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Значки состояния
              Row(
                children: [
                  if (isBestDay) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isToday) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localizations.translate('today').toUpperCase(),
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Иконка погоды
                  Icon(
                    _getWeatherIcon(day.day.condition.code),
                    size: 32,
                    color: AppConstants.textColor,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Основная информация
          Row(
            children: [
              // Температуры
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('temperature'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _weatherSettings.formatTemperature(day.day.mintempC, showUnit: false),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '°/${_weatherSettings.formatTemperature(day.day.maxtempC, showUnit: false)}°',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ветер
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('wind'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAverageWindForDay(day),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Клёвометр дня
              Column(
                children: [
                  Text(
                    localizations.translate('bite_activity'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getBiteActivityColor(dayActivity),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(dayActivity * 100).round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Описание погоды
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _translateWeatherDescription(day.day.condition.text),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDaysSection() {
    final localizations = AppLocalizations.of(context);
    final bestDays = _getBestDaysForFishing();

    if (bestDays.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
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
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${localizations.translate('best')} ${localizations.translate('days_many')}',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...bestDays.map((day) => _buildBestDayItem(day)).toList(),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Дни отмечены звездочкой ⭐ — идеальные условия для рыбалки',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
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

  Widget _buildBestDayItem(Map<String, dynamic> day) {
    final localizations = AppLocalizations.of(context);
    final date = day['date'] as DateTime;
    final activity = day['activity'] as double;
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday
                      ? localizations.translate('today')
                      : _formatDayName(date),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd.MM').format(date),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(activity * 100).round()}%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы

  double _calculateAverageActivity() {
    if (widget.fishingForecast == null) return 0.5;

    // Берем активность из основного прогноза или вычисляем среднюю за 3 дня
    final mainActivity = widget.fishingForecast!['overallActivity'] as double? ?? 0.5;

    // Для демонстрации - можно улучшить, добавив расчет по каждому дню
    return mainActivity;
  }

  double _calculateDayActivity(ForecastDay day) {
    // Простой алгоритм расчета активности клева на день
    double activity = 0.5;

    final avgTemp = (day.day.mintempC + day.day.maxtempC) / 2;

    // Оптимальная температура
    if (avgTemp >= 15 && avgTemp <= 25) {
      activity += 0.2;
    } else if (avgTemp < 5 || avgTemp > 35) {
      activity -= 0.2;
    }

    // Анализ фазы луны (упрощенно)
    final moonPhase = day.astro.moonPhase.toLowerCase();
    if (moonPhase.contains('full') || moonPhase.contains('new')) {
      activity += 0.1;
    }

    // Погодные условия
    final condition = day.day.condition.text.toLowerCase();
    if (condition.contains('sunny') || condition.contains('clear')) {
      activity += 0.1;
    } else if (condition.contains('storm') || condition.contains('heavy')) {
      activity -= 0.2;
    }

    return activity.clamp(0.0, 1.0);
  }

  bool _isDayGoodForFishing(ForecastDay day) {
    final activity = _calculateDayActivity(day);
    return activity >= 0.7; // Порог для "хорошего" дня
  }

  List<Map<String, dynamic>> _getBestDaysForFishing() {
    final forecast = widget.weatherData.forecast.take(3).toList();
    final bestDays = <Map<String, dynamic>>[];

    for (int i = 0; i < forecast.length; i++) {
      final day = forecast[i];
      final activity = _calculateDayActivity(day);

      if (activity >= 0.7) {
        bestDays.add({
          'date': DateTime.parse(day.date),
          'activity': activity,
          'dayIndex': i,
        });
      }
    }

    // Сортируем по активности (убывание)
    bestDays.sort((a, b) => (b['activity'] as double).compareTo(a['activity'] as double));

    return bestDays;
  }

  String _getAverageWindForDay(ForecastDay day) {
    // Вычисляем средний ветер за день на основе почасовых данных
    if (day.hour.isEmpty) return 'н/д';

    final avgWindKph = day.hour.map((h) => h.windKph).reduce((a, b) => a + b) / day.hour.length;
    return _weatherSettings.formatWindSpeed(avgWindKph);
  }

  String _formatDayName(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations.locale.languageCode;

    try {
      return DateFormat('EEEE', locale).format(date);
    } catch (e) {
      // Fallback
      final weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      return weekdays[date.weekday - 1];
    }
  }

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
}

// Кастомный painter для мини клёвометра
class BiteMeterPainter3Days extends CustomPainter {
  final double progress;
  final Color color;

  BiteMeterPainter3Days({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 3;

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