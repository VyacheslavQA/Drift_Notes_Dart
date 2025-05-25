// Путь: lib/screens/weather/weather_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather/weather_api_service.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/loading_overlay.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherApiService _weatherService = WeatherApiService();

  WeatherApiResponse? _currentWeather;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Получаем текущее местоположение
      Position position = await _getCurrentPosition();

      // Получаем прогноз погоды на 3 дня
      final weather = await _weatherService.getForecast(
        latitude: position.latitude,
        longitude: position.longitude,
        days: 3,
      );

      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _getCurrentPosition() async {
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

    return await Geolocator.getCurrentPosition();
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
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('loading'),
        child: RefreshIndicator(
          onRefresh: _loadWeatherData,
          color: AppConstants.primaryColor,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final localizations = AppLocalizations.of(context);

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentWeather == null) {
      return Center(
        child: Text(
          localizations.translate('no_data_to_display'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWeatherCard(),
            const SizedBox(height: 20),
            _buildHourlyForecast(),
            const SizedBox(height: 20),
            _buildDailyForecast(),
            const SizedBox(height: 20),
            _buildWeatherDetails(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('error_loading'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadWeatherData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(localizations.translate('try_again')),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    final current = _currentWeather!.current;
    final location = _currentWeather!.location;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: current.isDay == 1
              ? [const Color(0xFF4FC3F7), const Color(0xFF29B6F6)]
              : [const Color(0xFF1A237E), const Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${location.name}, ${location.region}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка погоды
              Image.network(
                'https:${current.condition.icon}',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    current.isDay == 1 ? Icons.wb_sunny : Icons.nights_stay,
                    color: Colors.white,
                    size: 80,
                  );
                },
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.tempC.round()}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    current.condition.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ощущается как ${current.feelslikeC.round()}°C',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    if (_currentWeather!.forecast.isEmpty) return const SizedBox();

    final todayHours = _currentWeather!.forecast.first.hour;
    final now = DateTime.now();

    // Показываем следующие 12 часов
    final filteredHours = todayHours.where((hour) {
      final hourDateTime = DateTime.parse(hour.time);
      return hourDateTime.isAfter(now);
    }).take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Почасовой прогноз',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredHours.length,
            itemBuilder: (context, index) {
              final hour = filteredHours[index];
              final time = DateTime.parse(hour.time);

              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${time.hour}:00',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      'https:${hour.condition.icon}',
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          hour.isDay == 1 ? Icons.wb_sunny : Icons.nights_stay,
                          color: AppConstants.textColor,
                          size: 32,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${hour.tempC.round()}°',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Прогноз на 3 дня',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_currentWeather!.forecast.map((day) => _buildDayForecastCard(day)).toList()),
      ],
    );
  }

  Widget _buildDayForecastCard(ForecastDay day) {
    final date = DateTime.parse(day.date);
    final isToday = date.day == DateTime.now().day;

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
              isToday ? 'Сегодня' : _getDayName(date.weekday),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Image.network(
            'https:${day.day.condition.icon}',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.wb_cloudy,
                color: AppConstants.textColor,
                size: 40,
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              day.day.condition.text,
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${day.day.mintempC.round()}°/${day.day.maxtempC.round()}°',
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

  Widget _buildWeatherDetails() {
    final current = _currentWeather!.current;
    final astro = _currentWeather!.forecast.isNotEmpty
        ? _currentWeather!.forecast.first.astro
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Подробности',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildDetailCard('Ветер', '${current.windKph.round()} км/ч', Icons.air),
            _buildDetailCard('Влажность', '${current.humidity}%', Icons.water_drop),
            _buildDetailCard('Давление', '${current.pressureMb.round()} мб', Icons.speed),
            _buildDetailCard('Видимость', '${current.visKm.round()} км', Icons.visibility),
            _buildDetailCard('УФ-индекс', current.uv.toString(), Icons.wb_sunny),
            _buildDetailCard('Облачность', '${current.cloud}%', Icons.cloud),
            if (astro != null) ...[
              _buildDetailCard('Восход', astro.sunrise, Icons.wb_twilight),
              _buildDetailCard('Закат', astro.sunset, Icons.nights_stay),
            ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppConstants.primaryColor,
            size: 32,
          ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return days[weekday - 1];
  }
}