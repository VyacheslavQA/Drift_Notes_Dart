// Путь: lib/screens/weather/weather_screen.dart

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
import '../../widgets/weather/weather_header.dart';
import '../../widgets/weather/weather_metrics_grid.dart';
import '../../widgets/weather/ai_bite_meter.dart';
import '../../widgets/weather/hourly_forecast.dart';
import '../../widgets/weather/best_time_section.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
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

  // Анимации
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late AnimationController _pullHintController;
  late Animation<double> _pullHintAnimation;
  bool _showPullHint = true;

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

    _pullHintController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pullHintAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pullHintController,
        curve: Curves.easeInOut,
      ),
    );

    // Запускаем анимацию подсказки
    _pullHintController.repeat(reverse: true);

    // Скрываем подсказку через 10 секунд
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showPullHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    _pullHintController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showPullHint = false; // Скрываем подсказку при загрузке
    });

    _loadingController.repeat();

    try {
      final position = await _getCurrentPosition();

      if (position != null && mounted) {
        // Получаем погоду
        final weather = await _weatherService.getForecast(
          latitude: position.latitude,
          longitude: position.longitude,
          days: 3,
        );

        // Получаем ИИ прогноз для всех типов рыбалки
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
            _locationName = '${weather.location.name}, ${weather.location.region}';
            _isLoading = false;
            _lastUpdated = DateTime.now();
          });

          _loadingController.stop();
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки: $e';
          _isLoading = false;
        });
        _loadingController.stop();
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    if (!mounted) return null;

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

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('Ошибка геолокации: $e');
      // Fallback - координаты Павлодара
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

    return _buildTodayContent();
  }

  Widget _buildTodayContent() {
    return RefreshIndicator(
      onRefresh: _loadWeather,
      color: AppConstants.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Заголовок экрана
          SliverToBoxAdapter(
            child: _buildScreenHeader(),
          ),

          // Подсказка о pull-to-refresh
          if (_showPullHint)
            SliverToBoxAdapter(
              child: _buildPullToRefreshHint(),
            ),

          // Заголовок с температурой
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: WeatherHeader(
                weather: _currentWeather!,
                locationName: _locationName,
                lastUpdated: _lastUpdated,
                weatherSettings: _weatherSettings,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Ключевые показатели (4 карточки)
                  WeatherMetricsGrid(
                    weather: _currentWeather!,
                    weatherSettings: _weatherSettings,
                    onPressureCardTap: () => _navigateToPressureDetail(),
                    onWindCardTap: () => _navigateToWindDetail(),
                  ),

                  const SizedBox(height: 24),

                  // Умный клевометр с ИИ 🧠
                  AIBiteMeter(
                    aiPrediction: _aiPrediction,
                    onCompareTypes: () => _showCompareTypesDialog(),
                    onSelectType: (type) => _onFishingTypeSelected(type),
                  ),

                  const SizedBox(height: 24),

                  // Почасовой прогноз
                  HourlyForecast(
                    weather: _currentWeather!,
                    weatherSettings: _weatherSettings,
                    onHourTapped: (hour, activity) => _showHourDetails(hour, activity),
                  ),

                  const SizedBox(height: 24),

                  // Лучшее время для рыбалки
                  BestTimeSection(
                    weather: _currentWeather!,
                    aiPrediction: _aiPrediction,
                  ),

                  const SizedBox(height: 100), // Отступ для bottom navigation
                ],
              ),
            ),
          ),
        ],
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
            Icon(
              Icons.cloud,
              color: AppConstants.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              localizations.translate('weather'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Кнопка обновления
            Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _loadWeather,
                icon: Icon(
                  Icons.refresh,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                tooltip: 'Обновить',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPullToRefreshHint() {
    return AnimatedBuilder(
      animation: _pullHintAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: _pullHintAnimation.value,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Потяните для обновления',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: _pullHintAnimation.value,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
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
            'Загрузка умного прогноза...',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
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
                      'Ошибка загрузки погоды',
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
                      label: const Text('Попробовать снова'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.textColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    'Нет данных для отображения',
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

  // Обработчики событий
  void _navigateToPressureDetail() {
    debugPrint('🔍 Открываем детали давления');
  }

  void _navigateToWindDetail() {
    debugPrint('🔍 Открываем детали ветра');
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

  void _showHourDetails(int hour, double activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(color: AppConstants.textColor, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Активность клева: ${(activity * 100).round()}%',
              style: TextStyle(
                color: _getActivityColor(activity),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getActivityText(activity),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Закрыть',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareTypesDialog() {
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
              '🎣 Сравнение типов рыбалки',
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
                      'Закрыть',
                      style: TextStyle(color: AppConstants.textColor.withValues(alpha: 0.7)),
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
                    child: const Text('Выбрать лучший'),
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
        color: isBest
            ? AppConstants.primaryColor.withValues(alpha: 0.1)
            : AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isBest
            ? Border.all(color: AppConstants.primaryColor, width: 2)
            : Border.all(color: AppConstants.textColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Text(
            ranking.icon,
            style: const TextStyle(fontSize: 24),
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

  // Вспомогательные методы
  Color _getActivityColor(double activity) {
    if (activity >= 0.8) return const Color(0xFF4CAF50);
    if (activity >= 0.6) return const Color(0xFFFFC107);
    if (activity >= 0.4) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getActivityText(double activity) {
    if (activity >= 0.8) return 'Отличная активность';
    if (activity >= 0.6) return 'Хорошая активность';
    if (activity >= 0.4) return 'Умеренная активность';
    return 'Слабая активность';
  }
}

// Расширение для обратной совместимости с табами
extension MultiFishingTypePredictionExt on MultiFishingTypePrediction {
  Map<String, dynamic> toOldFormat() {
    return {
      'overallActivity': bestPrediction.overallScore / 100.0,
      'scorePoints': bestPrediction.overallScore,
      'recommendation': bestPrediction.recommendation,
      'tips': bestPrediction.tips,
      'bestTimeWindows': bestPrediction.bestTimeWindows.map((w) => {
        'startTime': w.startTime.toIso8601String(),
        'endTime': w.endTime.toIso8601String(),
        'activity': w.activity,
        'reason': w.reason,
      }).toList(),
    };
  }
}