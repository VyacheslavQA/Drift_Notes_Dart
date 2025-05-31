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
                      _getWeatherIcon(hour.condition.code, time.hour >= 6 && time.hour < 20),
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
                    _getWeatherIcon(day.day.condition.code, true), // Для дневного прогноза используем дневную иконку
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

  // ИСПРАВЛЕННЫЙ МЕТОД - теперь учитывает время суток
  IconData _getWeatherIcon(int code, bool isDay) {
    switch (code) {
      case 1000: // Clear/Sunny
        return isDay ? Icons.wb_sunny : Icons.nights_stay;
      case 1003: // Partly cloudy
        return isDay ? Icons.wb_cloudy : Icons.cloud;
      case 1006: case 1009: // Cloudy/Overcast
      return Icons.cloud;
      case 1030: case 1135: case 1147: // Mist/Fog
      return Icons.cloud;
      case 1063: case 1180: case 1183: case 1186: case 1189: case 1192: case 1195:
      case 1198: case 1201: // Rain
      return Icons.grain;
      case 1066: case 1210: case 1213: case 1216: case 1219: case 1222: case 1225:
      case 1237: case 1255: case 1258: case 1261: case 1264: // Snow
      return Icons.ac_unit;
      case 1087: case 1273: case 1276: case 1279: case 1282: // Thunder
      return Icons.flash_on;
      default:
        return isDay ? Icons.wb_sunny : Icons.nights_stay;
    }
  }

  /// Перевод описания погоды с английского используя локализацию
  String _translateWeatherDescription(String englishDescription) {
    final localizations = AppLocalizations.of(context);

    // Очищаем описание от лишних пробелов
    final cleanDescription = englishDescription.trim().toLowerCase();

    // Словарь соответствий английских описаний к ключам локализации
    final Map<String, String> descriptionToKey = {
      'sunny': 'weather_sunny',
      'clear': 'weather_clear',
      'partly cloudy': 'weather_partly_cloudy',
      'cloudy': 'weather_cloudy',
      'overcast': 'weather_overcast',
      'mist': 'weather_mist',
      'patchy rain possible': 'weather_patchy_rain_possible',
      'patchy rain nearby': 'weather_patchy_rain_nearby',
      'patchy light drizzle': 'weather_patchy_light_drizzle',
      'light drizzle': 'weather_light_drizzle',
      'freezing drizzle': 'weather_freezing_drizzle',
      'heavy freezing drizzle': 'weather_heavy_freezing_drizzle',
      'patchy light rain': 'weather_patchy_light_rain',
      'light rain': 'weather_light_rain',
      'moderate rain at times': 'weather_moderate_rain_at_times',
      'moderate rain': 'weather_moderate_rain',
      'heavy rain at times': 'weather_heavy_rain_at_times',
      'heavy rain': 'weather_heavy_rain',
      'light freezing rain': 'weather_light_freezing_rain',
      'moderate or heavy freezing rain': 'weather_moderate_or_heavy_freezing_rain',
      'light showers of ice pellets': 'weather_light_showers_of_ice_pellets',
      'moderate or heavy showers of ice pellets': 'weather_moderate_or_heavy_showers_of_ice_pellets',
      'patchy snow possible': 'weather_patchy_snow_possible',
      'patchy snow nearby': 'weather_patchy_snow_nearby',
      'patchy light snow': 'weather_patchy_light_snow',
      'light snow': 'weather_light_snow',
      'patchy moderate snow': 'weather_patchy_moderate_snow',
      'moderate snow': 'weather_moderate_snow',
      'patchy heavy snow': 'weather_patchy_heavy_snow',
      'heavy snow': 'weather_heavy_snow',
      'ice pellets': 'weather_ice_pellets',
      'light snow showers': 'weather_light_snow_showers',
      'moderate or heavy snow showers': 'weather_moderate_or_heavy_snow_showers',
      'patchy light snow with thunder': 'weather_patchy_light_snow_with_thunder',
      'moderate or heavy snow with thunder': 'weather_moderate_or_heavy_snow_with_thunder',
      'light rain shower': 'weather_light_rain_shower',
      'moderate or heavy rain shower': 'weather_moderate_or_heavy_rain_shower',
      'torrential rain shower': 'weather_torrential_rain_shower',
      'thundery outbreaks possible': 'weather_thundery_outbreaks_possible',
      'patchy light rain with thunder': 'weather_patchy_light_rain_with_thunder',
      'moderate or heavy rain with thunder': 'weather_moderate_or_heavy_rain_with_thunder',
      'patchy sleet possible': 'weather_patchy_sleet_possible',
      'patchy sleet nearby': 'weather_patchy_sleet_nearby',
      'light sleet': 'weather_light_sleet',
      'moderate or heavy sleet': 'weather_moderate_or_heavy_sleet',
      'light sleet showers': 'weather_light_sleet_showers',
      'moderate or heavy sleet showers': 'weather_moderate_or_heavy_sleet_showers',
      'blowing snow': 'weather_blowing_snow',
      'blizzard': 'weather_blizzard',
      'fair': 'weather_fair',
      'hot': 'weather_hot',
      'cold': 'weather_cold',
      'windy': 'weather_windy',
    };

    // Ищем соответствующий ключ локализации
    final localizationKey = descriptionToKey[cleanDescription];
    if (localizationKey != null) {
      return localizations.translate(localizationKey);
    }

    // Если точного совпадения нет, возвращаем оригинальное описание
    return englishDescription;
  }

  /// Перевод направления ветра с английского используя локализацию
  String _translateWindDirection(String windDir) {
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

    return translations[windDir] ?? windDir;
  }

  /// Перевод фазы луны с английского используя локализацию
  String _translateMoonPhase(String moonPhase) {
    final localizations = AppLocalizations.of(context);

    final cleanPhase = moonPhase.trim().toLowerCase();

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

    return moonPhase;
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