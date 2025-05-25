// Путь: lib/screens/weather/weather_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather/weather_api_service.dart';
import '../../localization/app_localizations.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherApiService _weatherService = WeatherApiService();

  WeatherApiResponse? _currentWeather;
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

        if (mounted) {
          setState(() {
            _currentWeather = weather;
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
          _buildHourlyForecast(),
          const SizedBox(height: 20),
          _buildDailyForecast(),
          const SizedBox(height: 20),
          _buildWeatherDetails(),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final current = _currentWeather!.current;

    return Container(
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
          // Название локации с ограничением по ширине
          SizedBox(
            width: double.infinity,
            child: Text(
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
          ),
          const SizedBox(height: 8),
          Text(
            '${current.tempC.round()}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w300,
            ),
          ),
          // Описание погоды с переводом
          SizedBox(
            width: double.infinity,
            child: Text(
              _translateWeatherDescription(current.condition.text),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
        ],
      ),
    );
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
    final translations = {
      // Ясная погода
      'Sunny': 'Солнечно',
      'Clear': 'Ясно',

      // Облачность (все варианты регистра)
      'Partly cloudy': 'Переменная облачность',
      'Partly Cloudy': 'Переменная облачность',
      'PARTLY CLOUDY': 'Переменная облачность',
      'Cloudy': 'Облачно',
      'cloudy': 'Облачно',
      'CLOUDY': 'Облачно',
      'Overcast': 'Пасмурно',
      'overcast': 'Пасмурно',
      'OVERCAST': 'Пасмурно',

      // Туман
      'Mist': 'Дымка',
      'mist': 'Дымка',
      'Fog': 'Туман',
      'fog': 'Туман',
      'Freezing fog': 'Ледяной туман',
      'freezing fog': 'Ледяной туман',

      // Дождь - все варианты
      'Patchy rain possible': 'Местами дождь',
      'patchy rain possible': 'Местами дождь',
      'Patchy rain nearby': 'Местами дождь поблизости',
      'patchy rain nearby': 'Местами дождь поблизости',
      'Patchy light drizzle': 'Местами легкая морось',
      'patchy light drizzle': 'Местами легкая морось',
      'Light drizzle': 'Легкая морось',
      'light drizzle': 'Легкая морось',
      'Freezing drizzle': 'Ледяная морось',
      'freezing drizzle': 'Ледяная морось',
      'Heavy freezing drizzle': 'Сильная ледяная морось',
      'heavy freezing drizzle': 'Сильная ледяная морось',
      'Patchy light rain': 'Местами легкий дождь',
      'patchy light rain': 'Местами легкий дождь',
      'Light rain': 'Легкий дождь',
      'light rain': 'Легкий дождь',
      'Moderate rain at times': 'Временами умеренный дождь',
      'moderate rain at times': 'Временами умеренный дождь',
      'Moderate rain': 'Умеренный дождь',
      'moderate rain': 'Умеренный дождь',
      'Heavy rain at times': 'Временами сильный дождь',
      'heavy rain at times': 'Временами сильный дождь',
      'Heavy rain': 'Сильный дождь',
      'heavy rain': 'Сильный дождь',
      'Light freezing rain': 'Легкий ледяной дождь',
      'light freezing rain': 'Легкий ледяной дождь',
      'Moderate or heavy freezing rain': 'Умеренный или сильный ледяной дождь',
      'moderate or heavy freezing rain': 'Умеренный или сильный ледяной дождь',
      'Light showers of ice pellets': 'Легкий ледяной дождь',
      'light showers of ice pellets': 'Легкий ледяной дождь',
      'Moderate or heavy showers of ice pellets': 'Умеренный или сильный ледяной дождь',
      'moderate or heavy showers of ice pellets': 'Умеренный или сильный ледяной дождь',

      // Снег - все варианты
      'Patchy snow possible': 'Местами снег',
      'patchy snow possible': 'Местами снег',
      'Patchy snow nearby': 'Местами снег поблизости',
      'patchy snow nearby': 'Местами снег поблизости',
      'Patchy light snow': 'Местами легкий снег',
      'patchy light snow': 'Местами легкий снег',
      'Light snow': 'Легкий снег',
      'light snow': 'Легкий снег',
      'Patchy moderate snow': 'Местами умеренный снег',
      'patchy moderate snow': 'Местами умеренный снег',
      'Moderate snow': 'Умеренный снег',
      'moderate snow': 'Умеренный снег',
      'Patchy heavy snow': 'Местами сильный снег',
      'patchy heavy snow': 'Местами сильный снег',
      'Heavy snow': 'Сильный снег',
      'heavy snow': 'Сильный снег',
      'Ice pellets': 'Ледяная крупа',
      'ice pellets': 'Ледяная крупа',
      'Light snow showers': 'Легкие снежные ливни',
      'light snow showers': 'Легкие снежные ливни',
      'Moderate or heavy snow showers': 'Умеренные или сильные снежные ливни',
      'moderate or heavy snow showers': 'Умеренные или сильные снежные ливни',
      'Patchy light snow with thunder': 'Местами легкий снег с грозой',
      'patchy light snow with thunder': 'Местами легкий снег с грозой',
      'Moderate or heavy snow with thunder': 'Умеренный или сильный снег с грозой',
      'moderate or heavy snow with thunder': 'Умеренный или сильный снег с грозой',

      // Дождь с ливнями
      'Light rain shower': 'Легкий ливень',
      'light rain shower': 'Легкий ливень',
      'Moderate or heavy rain shower': 'Умеренный или сильный ливень',
      'moderate or heavy rain shower': 'Умеренный или сильный ливень',
      'Torrential rain shower': 'Проливной ливень',
      'torrential rain shower': 'Проливной ливень',

      // Гроза
      'Thundery outbreaks possible': 'Возможны грозы',
      'thundery outbreaks possible': 'Возможны грозы',
      'Patchy light rain with thunder': 'Местами легкий дождь с грозой',
      'patchy light rain with thunder': 'Местами легкий дождь с грозой',
      'Moderate or heavy rain with thunder': 'Умеренный или сильный дождь с грозой',
      'moderate or heavy rain with thunder': 'Умеренный или сильный дождь с грозой',

      // Град и мокрый снег
      'Patchy sleet possible': 'Местами мокрый снег',
      'patchy sleet possible': 'Местами мокрый снег',
      'Patchy sleet nearby': 'Местами мокрый снег поблизости',
      'patchy sleet nearby': 'Местами мокрый снег поблизости',
      'Light sleet': 'Легкий мокрый снег',
      'light sleet': 'Легкий мокрый снег',
      'Moderate or heavy sleet': 'Умеренный или сильный мокрый снег',
      'moderate or heavy sleet': 'Умеренный или сильный мокрый снег',
      'Light sleet showers': 'Легкие ливни с мокрым снегом',
      'light sleet showers': 'Легкие ливни с мокрым снегом',
      'Moderate or heavy sleet showers': 'Умеренные или сильные ливни с мокрым снегом',
      'moderate or heavy sleet showers': 'Умеренные или сильные ливни с мокрым снегом',

      // Другие условия
      'Blowing snow': 'Метель',
      'blowing snow': 'Метель',
      'Blizzard': 'Буран',
      'blizzard': 'Буран',

      // Дополнительные варианты
      'Fair': 'Ясно',
      'fair': 'ясно',
      'Hot': 'Жарко',
      'hot': 'жарко',
      'Cold': 'Холодно',
      'cold': 'холодно',
      'Windy': 'Ветрено',
      'windy': 'ветрено',
    };

    return translations[englishDescription] ?? englishDescription;
  }

  /// Перевод фазы луны с английского на русский
  String _translateMoonPhase(String moonPhase) {
    final translations = {
      'New Moon': 'Новолуние',
      'new moon': 'Новолуние',
      'Waxing Crescent': 'Растущая луна',
      'waxing crescent': 'Растущая луна',
      'First Quarter': 'Первая четверть',
      'first quarter': 'Первая четверть',
      'Waxing Gibbous': 'Растущая луна',
      'waxing gibbous': 'Растущая луна',
      'Full Moon': 'Полнолуние',
      'full moon': 'Полнолуние',
      'Waning Gibbous': 'Убывающая луна',
      'waning gibbous': 'Убывающая луна',
      'Last Quarter': 'Последняя четверть',
      'last quarter': 'Последняя четверть',
      'Third Quarter': 'Третья четверть',
      'third quarter': 'Третья четверть',
      'Waning Crescent': 'Убывающая луна',
      'waning crescent': 'Убывающая луна',
    };

    return translations[moonPhase] ?? moonPhase;
  }
}