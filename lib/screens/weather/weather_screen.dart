// Путь: lib/screens/weather/weather_screen.dart
// ВАЖНО: Заменить весь существующий файл на этот код
// ОБНОВЛЕНО: Добавлена передача selectedDayIndex в WeatherMetricsGrid для синхронизации данных

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart'; // для kDebugMode
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/weather/weather_api_service.dart';
import '../../services/weather_settings_service.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/weather/forecast_period_selector.dart';
import '../../widgets/weather/weather_summary_card.dart';
import '../../widgets/weather/detailed_weather_forecast.dart';
import '../../widgets/weather/weather_metrics_grid.dart';
import '../../screens/weather/pressure_detail_screen.dart';
import '../../screens/weather/wind_detail_screen.dart';
import '../../screens/ai_fishing/ai_bite_screen.dart';
import '../debug/openai_test_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  // Сервисы
  final WeatherApiService _weatherService = WeatherApiService();
  final AIBitePredictionService _aiService = AIBitePredictionService();
  final WeatherSettingsService _weatherSettings = WeatherSettingsService();

  // Данные
  WeatherApiResponse? _currentWeather;
  MultiFishingTypePrediction? _aiPrediction;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = '';
  DateTime _lastUpdated = DateTime.now();

  // Выбираем по индексу дня
  int _selectedDayIndex = 0;

  // Анимации
  late AnimationController _loadingController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _currentWeather == null) {
      _loadWeather();
    }
  }

  void _initAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _loadingController.repeat();

    try {
      final position = await _getCurrentPosition();

      if (position != null && mounted) {
        final weather = await _weatherService.getForecast(
          latitude: position.latitude,
          longitude: position.longitude,
          days: 7,
        );

        final aiPrediction = await _aiService.getMultiFishingTypePrediction(
          weather: weather,
          latitude: position.latitude,
          longitude: position.longitude,
          targetDate: DateTime.now(),
          l10n: AppLocalizations.of(context),
        );

        if (mounted) {
          setState(() {
            _currentWeather = weather;
            _aiPrediction = aiPrediction;
            _locationName =
            '${weather.location.name}, ${weather.location.region}';
            _isLoading = false;
            _lastUpdated = DateTime.now();

            // Сбрасываем выбранный день если он превышает доступные
            if (_selectedDayIndex >= weather.forecast.length) {
              _selectedDayIndex = 0;
            }
          });

          _loadingController.stop();
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(
            context,
          ).translate('weather_error');
          _isLoading = false;
        });
        _loadingController.stop();
      }
    }
  }

  void _onDayChanged(int dayIndex) {
    if (_selectedDayIndex != dayIndex &&
        _currentWeather != null &&
        dayIndex < _currentWeather!.forecast.length) {
      setState(() {
        _selectedDayIndex = dayIndex;
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    if (!mounted) return null;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          AppLocalizations.of(context).translate('location_services_disabled'),
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            AppLocalizations.of(
              context,
            ).translate('location_permission_denied'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          AppLocalizations.of(
            context,
          ).translate('location_permission_denied_forever'),
        );
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Возвращаем координаты по умолчанию в случае ошибки
      return Position(
        longitude: 76.9574,
        latitude: 52.2962,
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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentWeather == null) {
      return _buildNoDataState();
    }

    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Заголовок экрана
        SliverToBoxAdapter(child: _buildScreenHeader()),

        // Селектор периодов с динамическими табами
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeController,
            child: ForecastPeriodSelector(
              weather: _currentWeather!,
              selectedDayIndex: _selectedDayIndex,
              onDayChanged: _onDayChanged,
            ),
          ),
        ),

        // Карточка сводки погоды (новая)
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeController,
            child: WeatherSummaryCard(
              weather: _currentWeather!,
              weatherSettings: _weatherSettings,
              selectedDayIndex: _selectedDayIndex,
              locationName: _locationName,
            ),
          ),
        ),

        // Детальный прогноз с выбранным днем
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeController,
            child: DetailedWeatherForecast(
              weather: _currentWeather!,
              weatherSettings: _weatherSettings,
              selectedDayIndex: _selectedDayIndex,
              locationName: _locationName,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Карточки метрик (ОБНОВЛЕНО: передается selectedDayIndex)
                _buildMetricsGrid(),

                const SizedBox(height: 24),

                // Простая кнопка перехода на AI-анализ
                _buildSimpleAIButton(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ОБНОВЛЕНО: Добавлена передача selectedDayIndex для синхронизации данных
  Widget _buildMetricsGrid() {
    return WeatherMetricsGrid(
      weather: _currentWeather!,
      weatherSettings: _weatherSettings,
      selectedDayIndex: _selectedDayIndex, // НОВЫЙ: Передаем выбранный день
      onPressureCardTap: _openPressureDetailScreen,
      onWindCardTap: _openWindDetailScreen,
    );
  }

  // Простая кнопка для перехода на AI-экран
  Widget _buildSimpleAIButton() {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openAIBiteScreen,
          icon: const Text('🧠', style: TextStyle(fontSize: 20)),
          label: Text(
            localizations.translate('ai_bite_forecast'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B3A36),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildScreenHeader() {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            // Debug кнопка слева (только в debug режиме)
            if (kDebugMode)
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OpenAITestScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.smart_toy,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Источник прогнозов ИИ',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),

            // Отступ после debug кнопки
            if (kDebugMode) const SizedBox(width: 12),

            // Иконка и заголовок
            Icon(Icons.cloud, color: AppConstants.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.translate('weather'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Кнопка обновления справа
            Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _loadWeather,
                icon: AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isLoading ? _loadingController.value * 2 * 3.14159 : 0,
                      child: Icon(
                        Icons.refresh,
                        color: _isLoading
                            ? AppConstants.primaryColor.withValues(alpha: 0.5)
                            : AppConstants.primaryColor,
                        size: 24,
                      ),
                    );
                  },
                ),
                tooltip: localizations.translate('refresh'),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2 * 3.14159,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cyclone, // Используем cyclone как вы хотели
                    size: 64,
                    color: const Color(0xFF4A90E2),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            localizations.translate('loading_weather'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('ai_analyzing_fishing') ??
                'ИИ анализирует лучший тип рыбалки',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.translate('weather_error'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadWeather,
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.translate('try_again')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataState() {
    final localizations = AppLocalizations.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_queue,
                  size: 64,
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('no_data_to_display'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Открытие AI-экрана
  void _openAIBiteScreen() {
    if (_currentWeather == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIBiteScreen(
          weatherData: _currentWeather!,
          weatherSettings: _weatherSettings,
          aiPrediction: _aiPrediction,
          locationName: _locationName,
          preferredTypes: null,
        ),
      ),
    );
  }

  // Методы для открытия детальных экранов
  void _openPressureDetailScreen() {
    if (_currentWeather != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PressureDetailScreen(
            weatherData: _currentWeather!,
            locationName: _locationName,
          ),
        ),
      );
    }
  }

  void _openWindDetailScreen() {
    if (_currentWeather != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WindDetailScreen(
            weatherData: _currentWeather!,
            locationName: _locationName,
          ),
        ),
      );
    }
  }
}