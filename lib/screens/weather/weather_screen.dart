// Путь: lib/screens/weather/weather_screen.dart
// ВАЖНО: Заменить весь существующий файл на этот код

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/weather/weather_api_service.dart';
import '../../services/weather_settings_service.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/weather/forecast_period_selector.dart';
import '../../widgets/weather/detailed_weather_forecast.dart';
import '../../widgets/weather/weather_metrics_grid.dart';
import '../../widgets/weather/ai_bite_meter.dart';
import '../../screens/weather/pressure_detail_screen.dart';
import '../../screens/weather/wind_detail_screen.dart';
import 'package:flutter/foundation.dart';
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

  // ИЗМЕНЕНО: Теперь выбираем по индексу дня вместо enum
  int _selectedDayIndex = 0;

  // Анимации
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late AnimationController _pullHintController;
  late Animation<double> _pullHintAnimation;
  late Animation<Offset> _pullHintSlideAnimation;
  bool _showPullHint = true;
  bool _hasShownHintOnce = false;

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
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startPullHintIfNeeded();
      });
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

    _pullHintController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pullHintAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _pullHintController, curve: Curves.easeInOut),
    );

    _pullHintSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: const Offset(0, 0.2),
    ).animate(
      CurvedAnimation(parent: _pullHintController, curve: Curves.easeInOut),
    );

    _startPullHintIfNeeded();
  }

  void _startPullHintIfNeeded() {
    final shouldShow =
        !_hasShownHintOnce ||
            _errorMessage != null ||
            (_currentWeather != null &&
                DateTime.now().difference(_lastUpdated).inHours > 1);

    if (shouldShow && !_isLoading) {
      setState(() {
        _showPullHint = true;
      });

      _pullHintController.repeat(reverse: true);
      _hasShownHintOnce = true;

      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _showPullHint) {
          setState(() {
            _showPullHint = false;
          });
          _pullHintController.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    _pullHintController.dispose();
    super.dispose();
  }

  // ИСПРАВЛЕНО: Всегда запрашиваем 14 дней
  Future<void> _loadWeather() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showPullHint = false;
    });

    _pullHintController.stop();
    _loadingController.repeat();

    try {
      final position = await _getCurrentPosition();

      if (position != null && mounted) {
        // ИЗМЕНЕНО: Запрашиваем 7 дней согласно вашему плану
        final weather = await _weatherService.getForecast(
          latitude: position.latitude,
          longitude: position.longitude,
          days: 7, // Изменено с 14 на 7
        );

        final aiPrediction = await _aiService.getMultiFishingTypePrediction(
          weather: weather,
          latitude: position.latitude,
          longitude: position.longitude,
          targetDate: DateTime.now(),
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

          if (!_hasShownHintOnce) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _startPullHintIfNeeded();
            });
          }
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

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _startPullHintIfNeeded();
        });
      }
    }
  }

  // НОВЫЙ МЕТОД: Обработка смены дня
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
      debugPrint('Ошибка геолокации: $e');
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

  // ОБНОВЛЕННЫЙ МЕТОД: Новая структура с динамическими табами
  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadWeather,
      color: AppConstants.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Заголовок экрана
          SliverToBoxAdapter(child: _buildScreenHeader()),

          // Анимированная подсказка pull-to-refresh
          if (_showPullHint)
            SliverToBoxAdapter(child: _buildAnimatedPullHint()),

          // ОБНОВЛЕНО: Селектор периодов с динамическими табами
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

          // ОБНОВЛЕНО: Детальный прогноз с выбранным днем
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

                  // Карточки метрик (остаются как есть)
                  _buildMetricsGrid(),

                  const SizedBox(height: 24),

                  // ИИ прогноз клева (остается как есть)
                  AIBiteMeter(
                    aiPrediction: _aiPrediction,
                    onCompareTypes: () => _showCompareTypesDialog(),
                    onSelectType: (type) => _onFishingTypeSelected(type),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Возвращаем полную сетку с 4 карточками
  Widget _buildMetricsGrid() {
    return WeatherMetricsGrid(
      weather: _currentWeather!,
      weatherSettings: _weatherSettings,
      onPressureCardTap: _openPressureDetailScreen,
      onWindCardTap: _openWindDetailScreen,
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
            Icon(Icons.cloud, color: AppConstants.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('weather'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_locationName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _locationName,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
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
                    size: 24,
                  ),
                  tooltip: 'Источник прогнозов ИИ',
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

  Widget _buildAnimatedPullHint() {
    final localizations = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _pullHintController,
      builder: (context, child) {
        return Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: SlideTransition(
            position: _pullHintSlideAnimation,
            child: FadeTransition(
              opacity: _pullHintAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8 + (_pullHintAnimation.value * 0.4),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppConstants.primaryColor.withValues(
                        alpha: 0.3 + (_pullHintAnimation.value * 0.4),
                      ),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                      colors: [
                        AppConstants.primaryColor.withValues(alpha: 0.6),
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      localizations.translate('pull_to_refresh') ??
                          'Потяните для обновления',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8 + (_pullHintAnimation.value * 0.4),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppConstants.primaryColor.withValues(
                        alpha: 0.3 + (_pullHintAnimation.value * 0.4),
                      ),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_sync,
                    size: 64,
                    color: AppConstants.primaryColor,
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

    return RefreshIndicator(
      onRefresh: _loadWeather,
      color: AppConstants.primaryColor,
      child: CustomScrollView(
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
      ),
    );
  }

  Widget _buildNoDataState() {
    final localizations = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _loadWeather,
      color: AppConstants.primaryColor,
      child: CustomScrollView(
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

  void _showCompareTypesDialog() {
    if (_aiPrediction == null) return;

    showDialog(
      context: context,
      builder: (context) => _buildCompareTypesDialog(),
    );
  }

  void _onFishingTypeSelected(String fishingType) {
    debugPrint('🎣 Выбран тип рыбалки: $fishingType');
  }

  Widget _buildCompareTypesDialog() {
    final localizations = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎣 ${localizations.translate('fishing_types_comparison') ?? 'Сравнение типов рыбалки'}',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _aiPrediction!.comparison.rankings.length,
                itemBuilder: (context, index) {
                  final ranking = _aiPrediction!.comparison.rankings[index];
                  return _buildTypeComparisonCard(ranking, index == 0);
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      localizations.translate('close'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _onFishingTypeSelected(_aiPrediction!.bestFishingType);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.translate('select_best') ??
                          'Выбрать лучший',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeComparisonCard(FishingTypeRanking ranking, bool isBest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        isBest
            ? AppConstants.primaryColor.withValues(alpha: 0.1)
            : AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
        isBest
            ? Border.all(color: AppConstants.primaryColor, width: 2)
            : Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/fishing_types/${ranking.fishingType}.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(ranking.icon, style: const TextStyle(fontSize: 24));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.typeName,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ranking.shortRecommendation,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ranking.scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${ranking.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}