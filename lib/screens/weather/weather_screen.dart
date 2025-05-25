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
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
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
          Text(
            _locationName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
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
          Text(
            current.condition.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherStat(
                Icons.air,
                'Ветер',
                '${current.windKph.round()} км/ч',
              ),
              _buildWeatherStat(
                Icons.water_drop,
                'Влажность',
                '${current.humidity}%',
              ),
              _buildWeatherStat(
                Icons.visibility,
                'Видимость',
                '${current.visKm.round()} км',
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
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
                  children: [
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _getWeatherIcon(hour.condition.code),
                      color: AppConstants.textColor,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
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
                      style: TextStyle(
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      isToday ? 'Сегодня' : DateFormat('EEE', 'ru').format(date),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _getWeatherIcon(day.day.condition.code),
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    day.day.condition.text,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
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
            _buildDetailCard('Фаза луны', astro.moonPhase, Icons.brightness_2),
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
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.textColor.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
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
}