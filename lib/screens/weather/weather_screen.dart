// Путь: lib/screens/weather/weather_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
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

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherApiService _weatherService = WeatherApiService();
  final FishingForecastService _fishingForecastService = FishingForecastService();

  WeatherApiResponse? _currentWeather;
  Map<String, dynamic>? _fishingForecast;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Получаем текущее местоположение
      final position = await _getCurrentPosition();

      if (position != null) {
        // Получаем прогноз погоды с часовыми данными
        final weather = await _weatherService.getForecast(
          latitude: position.latitude,
          longitude: position.longitude,
          days: 3,
        );

        // Получаем прогноз для рыбалки
        final fishingForecast = await _fishingForecastService.getFishingForecast(
          weather: weather,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (mounted) {
          setState(() {
            _currentWeather = weather;
            _fishingForecast = fishingForecast;
            _locationName = '${weather.location.name}, ${weather.location.region}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки погоды: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Службы геолокации отключены');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Разрешение на геолокацию отклонено');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Разрешение на геолокацию отклонено навсегда');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Если не удалось получить местоположение, используем координаты по умолчанию (Москва)
      debugPrint('Ошибка получения местоположения: $e');
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

  // Метод для перехода к детальной странице погоды
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
      appBar: AppBar(
        title: Text(
          localizations.translate('weather'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
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
            onPressed: _loadWeather,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadWeather,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_currentWeather == null) {
      return const Center(
        child: Text('Нет данных о погоде'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentWeather(),
          const SizedBox(height: 20),
          _buildFishingForecast(),
          const SizedBox(height: 20),
          _buildHourlyForecast(),
          const SizedBox(height: 20),
          _buildDailyForecast(),
          const SizedBox(height: 20),
          _buildWeatherDetails(),
          const SizedBox(height: 20),
          // Кнопка для перехода к детальной информации
          _buildDetailButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final current = _currentWeather!.current;

    return GestureDetector(
      onTap: _openWeatherDetails,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          children: [
            // Температура
            Text(
              '${current.tempC.round()}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w300,
              ),
            ),
            // Название локации
            Text(
              _locationName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Описание погоды с переводом
            Text(
              _translateWeatherDescription(current.condition.text),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Ощущается как ${current.feelslikeC.round()}°C',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            // Статистика погоды
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildWeatherStat(
                    Icons.air,
                    'Ветер',
                    '${current.windKph.round()} км/ч',
                  ),
                ),
                Expanded(
                  child: _buildWeatherStat(
                    Icons.water_drop,
                    'Влажность',
                    '${current.humidity}%',
                  ),
                ),
                Expanded(
                  child: _buildWeatherStat(
                    Icons.visibility,
                    'Видимость',
                    '${current.visKm.round()} км',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Подсказка о детальной информации
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Нажмите для подробностей',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildFishingForecast() {
    if (_fishingForecast == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Прогноз для рыбалки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              // Общая активность клёва
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.set_meal,
                    color: _getFishingActivityColor(_fishingForecast!['overallActivity']),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Активность клёва',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _getFishingActivityText(_fishingForecast!['overallActivity']),
                        style: TextStyle(
                          color: _getFishingActivityColor(_fishingForecast!['overallActivity']),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Детали прогноза
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFishingFactorItem(
                    'Давление',
                    _fishingForecast!['pressureFactor'],
                    Icons.speed,
                  ),
                  _buildFishingFactorItem(
                    'Ветер',
                    _fishingForecast!['windFactor'],
                    Icons.air,
                  ),
                  _buildFishingFactorItem(
                    'Луна',
                    _fishingForecast!['moonFactor'],
                    Icons.brightness_2,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Рекомендации
              if (_fishingForecast!['recommendation'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fishingForecast!['recommendation'],
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFishingFactorItem(String label, double factor, IconData icon) {
    Color color = Colors.grey;
    String text = 'Норма';

    if (factor > 0.7) {
      color = Colors.green;
      text = 'Отлично';
    } else if (factor > 0.4) {
      color = Colors.orange;
      text = 'Хорошо';
    } else {
      color = Colors.red;
      text = 'Плохо';
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
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
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getFishingActivityColor(double activity) {
    if (activity > 0.7) return Colors.green;
    if (activity > 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getFishingActivityText(double activity) {
    if (activity > 0.8) return 'Отличная';
    if (activity > 0.6) return 'Хорошая';
    if (activity > 0.4) return 'Средняя';
    if (activity > 0.2) return 'Слабая';
    return 'Очень слабая';
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    if (_currentWeather!.forecast.isEmpty) return const SizedBox();

    final todayHours = _currentWeather!.forecast.first.hour;
    final now = DateTime.now();

    // Фильтруем только будущие часы
    final upcomingHours = todayHours.where((hour) {
      final hourTime = DateTime.parse(hour.time);
      return hourTime.isAfter(now);
    }).take(12).toList();

    if (upcomingHours.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Почасовой прогноз',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingHours.length,
            itemBuilder: (context, index) {
              final hour = upcomingHours[index];
              final time = DateTime.parse(hour.time);

              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      _getWeatherIcon(hour.condition.code),
                      color: AppConstants.textColor,
                      size: 24,
                    ),
                    Text(
                      '${hour.tempC.round()}°',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${hour.chanceOfRain.round()}%',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
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

  Widget _buildDailyForecast() {
    if (_currentWeather!.forecast.length <= 1) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Прогноз на ${_currentWeather!.forecast.length} дня',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentWeather!.forecast.length,
          itemBuilder: (context, index) {
            final day = _currentWeather!.forecast[index];
            final date = DateTime.parse(day.date);
            final isToday = index == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // День недели
                  SizedBox(
                    width: 70,
                    child: Text(
                      isToday ? 'Сегодня' : _getDayOfWeek(date),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Иконка погоды
                  Icon(
                    _getWeatherIcon(day.day.condition.code),
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  // Описание погоды
                  Expanded(
                    child: Text(
                      _translateWeatherDescription(day.day.condition.text),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Температура
                  Text(
                    '${day.day.mintempC.round()}°/${day.day.maxtempC.round()}°',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getDayOfWeek(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final weekdays = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday'
    ];

    try {
      final weekdayIndex = date.weekday - 1;
      if (weekdayIndex >= 0 && weekdayIndex < weekdays.length) {
        return localizations.translate(weekdays[weekdayIndex]);
      }
    } catch (e) {
      debugPrint('Ошибка перевода дня недели: $e');
    }

    // Fallback на русский
    const russianWeekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final weekdayIndex = date.weekday - 1;
    if (weekdayIndex >= 0 && weekdayIndex < russianWeekdays.length) {
      return russianWeekdays[weekdayIndex];
    }

    return DateFormat('EEE', 'ru').format(date);
  }

  Widget _buildWeatherDetails() {
    final current = _currentWeather!.current;
    final astro = _currentWeather!.forecast.first.astro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Подробности',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildDetailCard('Давление', '${current.pressureMb.round()} мб', Icons.speed),
            _buildDetailCard('Видимость', '${current.visKm.round()} км', Icons.visibility),
            _buildDetailCard('УФ-индекс', current.uv.toString(), Icons.wb_sunny),
            _buildDetailCard('Восход', astro.sunrise, Icons.wb_twilight),
            _buildDetailCard('Закат', astro.sunset, Icons.nights_stay),
            _buildDetailCard('Фаза луны', _translateMoonPhase(astro.moonPhase), Icons.brightness_2),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.textColor.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openWeatherDetails,
        icon: const Icon(Icons.info_outline),
        label: const Text('Подробная информация о погоде'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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

  /// Перевод описания погоды с английского на русский
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

  /// Перевод фазы луны с английского на русский
  String _translateMoonPhase(String moonPhase) {
    final localizations = AppLocalizations.of(context);

    final cleanPhase = moonPhase.trim().toLowerCase();

    // Словарь соответствий английских фаз луны к ключам локализации
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
}