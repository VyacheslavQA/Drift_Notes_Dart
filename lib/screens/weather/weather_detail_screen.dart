// Путь: lib/screens/weather/weather_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../localization/app_localizations.dart';

class WeatherDetailScreen extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final String locationName;

  const WeatherDetailScreen({
    super.key,
    required this.weatherData,
    required this.locationName,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('detailed_weather'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.textColor,
          unselectedLabelColor: AppConstants.textColor.withValues(alpha: 0.6),
          tabs: [
            Tab(text: localizations.translate('now')),
            Tab(text: localizations.translate('today')),
            Tab(text: localizations.translate('forecast')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentWeatherTab(),
          _buildTodayTab(),
          _buildForecastTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherTab() {
    final localizations = AppLocalizations.of(context);
    final current = widget.weatherData.current;
    final astro = widget.weatherData.forecast.first.astro;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная карточка с текущей погодой
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  current.isDay == 1 ? Colors.blue[400]! : Colors.indigo[800]!,
                  current.isDay == 1 ? Colors.blue[600]! : Colors.indigo[900]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  '${current.tempC.round()}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _translateWeatherDescription(current.condition.text),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${localizations.translate('feels_like')} ${current.feelslikeC.round()}°C',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Основные показатели
          _buildSectionTitle(localizations.translate('main_indicators')),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildWeatherCard(
                localizations.translate('humidity'),
                '${current.humidity}%',
                Icons.water_drop,
                _getHumidityDescription(current.humidity),
              ),
              _buildWeatherCard(
                localizations.translate('pressure'),
                '${current.pressureMb.round()} ${localizations.translate('mb')}',
                Icons.speed,
                _getPressureDescription(current.pressureMb),
              ),
              _buildWeatherCard(
                localizations.translate('visibility'),
                '${current.visKm} ${localizations.translate('km')}',
                Icons.visibility,
                _getVisibilityDescription(current.visKm),
              ),
              _buildWeatherCard(
                localizations.translate('uv_index'),
                current.uv.toString(),
                Icons.wb_sunny,
                _getUVDescription(current.uv),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Ветер
          _buildSectionTitle(localizations.translate('wind')),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.air, color: AppConstants.textColor, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          localizations.translate('speed'),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${current.windKph.round()} ${localizations.translate('km_h')}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.explore, color: AppConstants.textColor, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          localizations.translate('direction'),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _translateWindDirection(current.windDir),
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
                const SizedBox(height: 12),
                Text(
                  _getWindDescription(current.windKph),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Астрономия
          _buildSectionTitle(localizations.translate('sun_and_moon')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAstroCard(
                  localizations.translate('sunrise'),
                  astro.sunrise,
                  Icons.wb_twilight,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAstroCard(
                  localizations.translate('sunset'),
                  astro.sunset,
                  Icons.nights_stay,
                  Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.brightness_2, color: AppConstants.textColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  localizations.translate('moon_phase'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _translateMoonPhase(astro.moonPhase),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Комфорт
          _buildSectionTitle(localizations.translate('comfort_and_sensations')),
          const SizedBox(height: 12),
          _buildComfortCard(current),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final localizations = AppLocalizations.of(context);

    if (widget.weatherData.forecast.isEmpty) {
      return Center(
        child: Text(
          localizations.translate('no_hourly_data'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
          ),
        ),
      );
    }

    final todayForecast = widget.weatherData.forecast.first;
    final hours = todayForecast.hour;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.schedule, color: AppConstants.textColor),
              const SizedBox(width: 8),
              Text(
                localizations.translate('hourly_forecast_today'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hours.length,
            itemBuilder: (context, index) {
              final hour = hours[index];
              final time = DateTime.parse(hour.time);
              final isCurrentHour = DateTime.now().hour == time.hour;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrentHour
                      ? AppConstants.primaryColor.withValues(alpha: 0.2)
                      : AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrentHour
                      ? Border.all(color: AppConstants.primaryColor, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        DateFormat('HH:mm').format(time),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      _getWeatherIcon(hour.condition.code),
                      color: AppConstants.textColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hour.tempC.round()}°C',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _translateWeatherDescription(hour.condition.text),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${hour.chanceOfRain.round()}%',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hour.windKph.round()} ${AppLocalizations.of(context).translate('km_h')}',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildForecastTab() {
    final localizations = AppLocalizations.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.weatherData.forecast.length,
      itemBuilder: (context, index) {
        final day = widget.weatherData.forecast[index];
        final date = DateTime.parse(day.date);
        final isToday = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday ? localizations.translate('today') : _formatDateForLocale(date),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${day.day.mintempC.round()}°',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const Text(' / '),
                      Text(
                        '${day.day.maxtempC.round()}°',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getWeatherIcon(day.day.condition.code),
                    color: AppConstants.textColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _translateWeatherDescription(day.day.condition.text),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayStatItem(Icons.wb_twilight, localizations.translate('sunrise'), day.astro.sunrise),
                  _buildDayStatItem(Icons.nights_stay, localizations.translate('sunset'), day.astro.sunset),
                  _buildDayStatItem(
                    Icons.brightness_2,
                    localizations.translate('moon_phase'),
                    _translateMoonPhase(day.astro.moonPhase),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Новый метод для форматирования даты с учетом локали
  String _formatDateForLocale(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations.locale.languageCode;

    try {
      return DateFormat('EEEE, d MMMM', locale).format(date);
    } catch (e) {
      // Fallback если локаль не поддерживается
      if (locale == 'en') {
        return DateFormat('EEEE, MMMM d').format(date);
      } else {
        return DateFormat('EEEE, d MMMM', 'ru').format(date);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppConstants.textColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWeatherCard(String title, String value, IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppConstants.textColor, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAstroCard(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
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
      ),
    );
  }

  Widget _buildComfortCard(Current current) {
    final localizations = AppLocalizations.of(context);
    final heatIndex = _calculateHeatIndex(current.tempC, current.humidity);
    final dewPoint = _calculateDewPoint(current.tempC, current.humidity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(Icons.thermostat, color: AppConstants.textColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('heat_index'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${heatIndex.round()}°C',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.opacity, color: AppConstants.textColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('dew_point'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${dewPoint.round()}°C',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getComfortDescription(current.tempC, current.humidity, current.windKph),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.textColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Расчёт индекса жары
  double _calculateHeatIndex(double tempC, int humidity) {
    if (tempC < 27) return tempC;

    final t = tempC;
    final h = humidity.toDouble();

    final hi = -8.78469475556 +
        1.61139411 * t +
        2.33854883889 * h +
        -0.14611605 * t * h +
        -0.012308094 * t * t +
        -0.0164248277778 * h * h +
        0.002211732 * t * t * h +
        0.00072546 * t * h * h +
        -0.000003582 * t * t * h * h;

    return hi;
  }

  // Расчёт точки росы
  double _calculateDewPoint(double tempC, int humidity) {
    final a = 17.27;
    final b = 237.7;
    final alpha = ((a * tempC) / (b + tempC)) + math.log(humidity / 100.0);
    return (b * alpha) / (a - alpha);
  }

  IconData _getWeatherIcon(int code) {
    switch (code) {
      case 1000: // Clear
        return Icons.wb_sunny;
      case 1003: // Partly cloudy
      case 1006: // Cloudy
      case 1009: // Overcast
        return Icons.cloud;
      case 1030: // Mist
      case 1135: // Fog
      case 1147: // Freezing fog
        return Icons.cloud;
      case 1063: // Patchy rain possible
      case 1180: // Patchy light rain
      case 1183: // Light rain
      case 1186: // Moderate rain at times
      case 1189: // Moderate rain
      case 1192: // Heavy rain at times
      case 1195: // Heavy rain
      case 1198: // Light freezing rain
      case 1201: // Moderate or heavy freezing rain
        return Icons.grain;
      case 1066: // Patchy snow possible
      case 1210: // Patchy light snow
      case 1213: // Light snow
      case 1216: // Patchy moderate snow
      case 1219: // Moderate snow
      case 1222: // Patchy heavy snow
      case 1225: // Heavy snow
        return Icons.ac_unit;
      case 1087: // Thundery outbreaks possible
      case 1273: // Patchy light rain with thunder
      case 1276: // Moderate or heavy rain with thunder
      case 1279: // Patchy light snow with thunder
      case 1282: // Moderate or heavy snow with thunder
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }

  String _translateWeatherDescription(String englishDescription) {
    final translations = {
      'Sunny': 'Солнечно',
      'Clear ': 'Ясно',
      'Partly cloudy ': 'Переменная облачность',
      'Partly Cloudy ': 'Переменная облачность',
      'Cloudy': 'Облачно',
      'Overcast': 'Пасмурно',
      'Mist': 'Дымка',
      'Fog': 'Туман',
      'Patchy rain possible ': 'Местами дождь',
      'Light rain': 'Легкий дождь',
      'Moderate rain': 'Умеренный дождь',
      'Heavy rain': 'Сильный дождь',
      'Light snow': 'Легкий снег',
      'Moderate snow': 'Умеренный снег',
      'Heavy snow': 'Сильный снег',
      'Thundery outbreaks possible': 'Возможны грозы',
      'Patchy light drizzle': 'Местами легкая морось',
      'Patchy rain nearby': 'Местами дождь поблизости',
    };
    return translations[englishDescription] ?? englishDescription;
  }

  String _translateWindDirection(String windDir) {
    final translations = {
      'N': 'С', 'NNE': 'ССВ', 'NE': 'СВ', 'ENE': 'ВСВ',
      'E': 'В', 'ESE': 'ВЮВ', 'SE': 'ЮВ', 'SSE': 'ЮЮВ',
      'S': 'Ю', 'SSW': 'ЮЮЗ', 'SW': 'ЮЗ', 'WSW': 'ЗЮЗ',
      'W': 'З', 'WNW': 'ЗСЗ', 'NW': 'СЗ', 'NNW': 'ССЗ',
    };
    return translations[windDir] ?? windDir;
  }

  String _translateMoonPhase(String moonPhase) {
    final translations = {
      'New Moon': 'Новолуние',
      'Waxing Crescent': 'Растущая луна',
      'First Quarter': 'Первая четверть',
      'Waxing Gibbous': 'Растущая луна',
      'Full Moon': 'Полнолуние',
      'Waning Gibbous': 'Убывающая луна',
      'Last Quarter': 'Последняя четверть',
      'Third Quarter': 'Третья четверть',
      'Waning Crescent': 'Убывающая луна',
    };
    return translations[moonPhase] ?? moonPhase;
  }

  String _getHumidityDescription(int humidity) {
    final localizations = AppLocalizations.of(context);

    if (humidity < 30) return localizations.translate('dry');
    if (humidity < 50) return localizations.translate('comfortable');
    if (humidity < 70) return localizations.translate('moderate');
    if (humidity < 85) return localizations.translate('humid');
    return localizations.translate('very_humid');
  }

  String _getPressureDescription(double pressure) {
    final localizations = AppLocalizations.of(context);

    if (pressure < 1000) return localizations.translate('low_pressure');
    if (pressure < 1020) return localizations.translate('normal_pressure');
    return localizations.translate('high_pressure');
  }

  String _getVisibilityDescription(double visibility) {
    final localizations = AppLocalizations.of(context);

    if (visibility < 1) return localizations.translate('very_poor_visibility');
    if (visibility < 5) return localizations.translate('poor_visibility');
    if (visibility < 10) return localizations.translate('moderate_visibility');
    return localizations.translate('excellent_visibility');
  }

  String _getUVDescription(double uv) {
    final localizations = AppLocalizations.of(context);

    if (uv < 3) return localizations.translate('low_uv');
    if (uv < 6) return localizations.translate('moderate_uv');
    if (uv < 8) return localizations.translate('high_uv');
    if (uv < 11) return localizations.translate('very_high_uv');
    return localizations.translate('extreme_uv');
  }

  String _getWindDescription(double windKph) {
    final localizations = AppLocalizations.of(context);

    if (windKph < 12) return localizations.translate('light_breeze');
    if (windKph < 28) return localizations.translate('weak_wind');
    if (windKph < 50) return localizations.translate('moderate_wind');
    if (windKph < 75) return localizations.translate('strong_wind');
    return localizations.translate('very_strong_wind');
  }

  String _getComfortDescription(double temp, int humidity, double windKph) {
    final localizations = AppLocalizations.of(context);

    if (temp < 10) {
      return localizations.translate('cold_weather');
    } else if (temp < 20) {
      return localizations.translate('cool_weather');
    } else if (temp < 25) {
      return localizations.translate('comfortable_weather');
    } else if (temp < 30) {
      if (humidity > 70) {
        return localizations.translate('warm_humid_weather');
      }
      return localizations.translate('pleasant_warm_weather');
    } else {
      if (humidity > 60) {
        return localizations.translate('hot_stuffy_weather');
      }
      return localizations.translate('hot_tolerable_weather');
    }
  }
}