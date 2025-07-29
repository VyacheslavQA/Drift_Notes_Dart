// Путь: lib/screens/ai_fishing/ai_bite_screen.dart
// ИСПРАВЛЕНО: Короткое название "ИИ Прогноз" в AppBar вместо полного
// ИСПРАВЛЕНО: Размещение местоположения в AppBar без перекрытия

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';
import '../weather/fishing_type_detail_screen.dart';

class AIBiteScreen extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final WeatherSettingsService weatherSettings;
  final MultiFishingTypePrediction? aiPrediction;
  final String locationName;
  final List<String>? preferredTypes;

  const AIBiteScreen({
    super.key,
    required this.weatherData,
    required this.weatherSettings,
    this.aiPrediction,
    required this.locationName,
    this.preferredTypes,
  });

  @override
  State<AIBiteScreen> createState() => _AIBiteScreenState();
}

class _AIBiteScreenState extends State<AIBiteScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _pulseController;
  late AnimationController _needleController;
  late AnimationController _fadeController;
  late Animation<double> _gaugeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _needleAnimation;
  late Animation<double> _fadeAnimation;

  // Конфигурация типов рыбалки
  static const Map<String, Map<String, String>> fishingTypes = {
    'carp_fishing': {
      'name': 'Карповая рыбалка',
      'icon': 'assets/images/fishing_types/carp_fishing.png',
      'nameKey': 'carp_fishing',
    },
    'feeder': {
      'name': 'Фидер',
      'icon': 'assets/images/fishing_types/feeder.png',
      'nameKey': 'feeder',
    },
    'float_fishing': {
      'name': 'Поплавочная',
      'icon': 'assets/images/fishing_types/float_fishing.png',
      'nameKey': 'float_fishing',
    },
    'fly_fishing': {
      'name': 'Нахлыст',
      'icon': 'assets/images/fishing_types/fly_fishing.png',
      'nameKey': 'fly_fishing',
    },
    'ice_fishing': {
      'name': 'Зимняя рыбалка',
      'icon': 'assets/images/fishing_types/ice_fishing.png',
      'nameKey': 'ice_fishing',
    },
    'spinning': {
      'name': 'Спиннинг',
      'icon': 'assets/images/fishing_types/spinning.png',
      'nameKey': 'spinning',
    },
    'trolling': {
      'name': 'Троллинг',
      'icon': 'assets/images/fishing_types/trolling.png',
      'nameKey': 'trolling',
    },
    'Обычная рыбалка': {
      'name': 'Обычная рыбалка',
      'icon': 'assets/images/fishing_types/general_fishing.png',
      'nameKey': 'general_fishing',
    },
    'general_fishing': {
      'name': 'Обычная рыбалка',
      'icon': 'assets/images/fishing_types/general_fishing.png',
      'nameKey': 'general_fishing',
    },
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context);
      widget.weatherSettings.setLocale(localizations.locale.languageCode);
    });
  }

  void _initAnimations() {
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _needleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gaugeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic),
    );

    _needleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _gaugeController.forward();
    _needleController.forward();
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _needleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<String> _getFilteredTypes() {
    if (widget.preferredTypes != null && widget.preferredTypes!.isNotEmpty) {
      return widget.preferredTypes!;
    }

    if (widget.aiPrediction != null) {
      final availableTypes = widget.aiPrediction!.allPredictions.keys.toList();
      if (availableTypes.isNotEmpty) {
        return availableTypes;
      }
    }

    return [];
  }

  String _getBestFilteredType() {
    final filteredTypes = _getFilteredTypes();

    if (filteredTypes.isEmpty) {
      return '';
    }

    if (widget.aiPrediction == null) {
      return filteredTypes.first;
    }

    final rankings = widget.aiPrediction!.comparison.rankings;

    for (final ranking in rankings) {
      if (filteredTypes.contains(ranking.fishingType)) {
        return ranking.fishingType;
      }
    }

    return filteredTypes.first;
  }

  int _getBestFilteredScore() {
    final bestType = _getBestFilteredType();

    if (bestType.isEmpty || widget.aiPrediction == null) {
      return 50;
    }

    final prediction = widget.aiPrediction!.allPredictions[bestType];
    return prediction?.overallScore ?? 50;
  }

  Map<String, String> _getTypeInfo(String type) {
    final typeInfo = fishingTypes[type];

    if (typeInfo != null) {
      return typeInfo;
    }

    return {
      'name': type,
      'icon': 'assets/images/fishing_types/general_fishing.png',
      'nameKey': 'general_fishing',
    };
  }

  String _translateMoonPhase(String englishPhase, AppLocalizations localizations) {
    final cleanPhase = englishPhase.trim().toLowerCase();

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

    return englishPhase;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // ИСПРАВЛЕНО: Кастомный AppBar с коротким названием
          _buildCustomAppBar(localizations),

          // Основной контент
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMainContent(localizations),
            ),
          ),
        ],
      ),
    );
  }

  // ИСПРАВЛЕНО: Простой AppBar без перекрытия
  Widget _buildCustomAppBar(AppLocalizations localizations) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1B3A36),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1B3A36),
              const Color(0xFF0F2A26),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            'ИИ Прогноз',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          titlePadding: const EdgeInsets.only(bottom: 16),
          // УБРАНО: background - убираем дублирующий контент
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations localizations) {
    if (widget.aiPrediction == null) {
      return _buildLoadingState(localizations);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ДОБАВЛЕНО: Отображение местоположения в основном контенте
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.locationName,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Главный спидометр
          _buildSpeedometerCard(localizations),

          const SizedBox(height: 24),

          // Анализ типов рыбалки
          _buildFishingTypesSection(localizations),

          const SizedBox(height: 24),

          // Детальная погодная информация
          _buildWeatherDetailsCard(localizations),

          const SizedBox(height: 24),

          // Рекомендации по времени
          _buildTimeRecommendationsCard(localizations),

          const SizedBox(height: 24),

          // Сравнение всех типов (если есть данные)
          if (_getFilteredTypes().length > 1)
            _buildFullComparisonCard(localizations),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations localizations) {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.translate('ai_analyzing_fishing'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerCard(AppLocalizations localizations) {
    final score = _getBestFilteredScore();
    final bestType = _getBestFilteredType();
    final typeInfo = _getTypeInfo(bestType);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1B3A36), const Color(0xFF0F2A26)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с лучшим типом
          if (bestType.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    typeInfo['icon']!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.sports, size: 32, color: Colors.white);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Спидометр
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _gaugeAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: SpeedometerPainter(
                    progress: _gaugeAnimation.value,
                    score: score,
                    needleProgress: _needleAnimation.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: score >= 80 ? _pulseAnimation.value : 1.0,
                              child: Text(
                                '${(_gaugeAnimation.value * score).round()}',
                                style: TextStyle(
                                  color: _getScoreTextColor(score),
                                  fontSize: 42,
                                  fontWeight: FontWeight.w200,
                                  height: 1.0,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${localizations.translate('bite_activity').toUpperCase()}: ${_getScoreText(score, localizations).toUpperCase()}',
                          style: TextStyle(
                            color: _getScoreTextColor(score),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Уверенность AI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${localizations.translate('confidence')}: ${widget.aiPrediction!.bestPrediction.confidencePercent}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingTypesSection(AppLocalizations localizations) {
    final selectedTypes = _getFilteredTypes();
    final bestType = _getBestFilteredType();

    if (selectedTypes.isEmpty) {
      return _buildNoTypesSelectedCard(localizations);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('fishing_types_comparison'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...selectedTypes.map((type) => _buildTypeCard(type, bestType, localizations)),
      ],
    );
  }

  Widget _buildNoTypesSelectedCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.settings, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            'Выберите типы рыбалки в профиле',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Для получения персонализированных рекомендаций настройте предпочтения в профиле',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String type, String bestType, AppLocalizations localizations) {
    final typeInfo = _getTypeInfo(type);
    final prediction = widget.aiPrediction?.allPredictions[type];
    final score = prediction?.overallScore ?? 0;
    final isBest = type == bestType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openFishingTypeDetail(type, localizations),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBest
                  ? _getScoreColor(score)
                  : AppConstants.textColor.withValues(alpha: 0.1),
              width: isBest ? 2 : 1,
            ),
            boxShadow: isBest ? [
              BoxShadow(
                color: _getScoreColor(score).withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Иконка
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    typeInfo['icon']!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.sports, size: 32, color: _getScoreColor(score));
                    },
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isBest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getScoreColor(score),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ЛУЧШИЙ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prediction?.recommendation ?? 'Рекомендации недоступны',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Скор
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreColor(score),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsCard(AppLocalizations localizations) {
    final current = widget.weatherData.current;
    final moonPhase = widget.weatherData.forecast.isNotEmpty
        ? widget.weatherData.forecast.first.astro.moonPhase
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌤️ ${localizations.translate('weather_conditions')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Основная рекомендация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              widget.aiPrediction!.bestPrediction.recommendation,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Погодные параметры
          _buildWeatherGrid(current, moonPhase, localizations),
        ],
      ),
    );
  }

  Widget _buildWeatherGrid(Current current, String moonPhase, AppLocalizations localizations) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildWeatherMetric('🌡️', widget.weatherSettings.formatPressure(current.pressureMb), localizations.translate('pressure'))),
            const SizedBox(width: 12),
            Expanded(child: _buildWeatherMetric('💨', widget.weatherSettings.formatWindSpeed(current.windKph), localizations.translate('wind'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildWeatherMetric('🌙', _translateMoonPhase(moonPhase, localizations), localizations.translate('moon_phase'))),
            const SizedBox(width: 12),
            Expanded(child: _buildWeatherMetric('💧', '${current.humidity}%', localizations.translate('humidity'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildWeatherMetric('🌡️', '${current.tempC.round()}°C', localizations.translate('temperature'))),
            const SizedBox(width: 12),
            Expanded(child: _buildWeatherMetric('☁️', '${current.cloud}%', localizations.translate('cloudiness'))),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherMetric(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRecommendationsCard(AppLocalizations localizations) {
    final prediction = widget.aiPrediction?.bestPrediction;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🕐 ${localizations.translate('best_fishing_times')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (prediction?.bestTimeWindows.isNotEmpty == true) ...[
            ...prediction!.bestTimeWindows.map((window) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          window.timeRange,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          window.reason,
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Рекомендации по времени недоступны',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullComparisonCard(AppLocalizations localizations) {
    final selectedTypes = _getFilteredTypes();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 ${localizations.translate('detailed_comparison')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...selectedTypes.map((type) {
            final typeInfo = _getTypeInfo(type);
            final prediction = widget.aiPrediction?.allPredictions[type];
            final score = prediction?.overallScore ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getScoreColor(score).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          typeInfo['icon']!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.sports, size: 24, color: _getScoreColor(score));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prediction?.recommendation ?? 'Рекомендации недоступны',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openFishingTypeDetail(String type, AppLocalizations localizations) {
    final prediction = widget.aiPrediction?.allPredictions[type];
    if (prediction == null) return;

    final typeInfo = _getTypeInfo(type);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FishingTypeDetailScreen(
          fishingType: type,
          prediction: prediction,
          typeInfo: typeInfo,
        ),
      ),
    );
  }

  // Вспомогательные методы для цветов и текста
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getScoreTextColor(int score) {
    if (score >= 80) return const Color(0xFF66BB6A);
    if (score >= 60) return const Color(0xFF9CCC65);
    if (score >= 40) return const Color(0xFFFFCA28);
    if (score >= 20) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  String _getScoreText(int score, AppLocalizations localizations) {
    if (score >= 80) return localizations.translate('excellent_activity');
    if (score >= 60) return localizations.translate('good_activity');
    if (score >= 40) return localizations.translate('moderate_activity');
    if (score >= 20) return localizations.translate('poor_activity');
    return localizations.translate('very_poor_activity');
  }
}

// Кастомный painter для спидометра
class SpeedometerPainter extends CustomPainter {
  final double progress;
  final int score;
  final double needleProgress;

  SpeedometerPainter({
    required this.progress,
    required this.score,
    required this.needleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final radius = size.width * 0.32;

    _drawBackgroundArc(canvas, center, radius);
    _drawColoredArc(canvas, center, radius);
    _drawTriangleOnArc(canvas, center, radius);
  }

  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi + 0.4;
    const sweepAngle = math.pi - 0.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawColoredArc(Canvas canvas, Offset center, double radius) {
    const startAngle = math.pi + 0.4;
    const totalSweepAngle = math.pi - 0.8;
    final currentSweepAngle = totalSweepAngle * progress;

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + totalSweepAngle,
      colors: const [
        Color(0xFFEF5350),
        Color(0xFFFF9800),
        Color(0xFFFFC107),
        Color(0xFF8BC34A),
        Color(0xFF4CAF50),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweepAngle,
      false,
      paint,
    );
  }

  void _drawTriangleOnArc(Canvas canvas, Offset center, double radius) {
    if (needleProgress == 0) return;

    const startAngle = math.pi + 0.4;
    const totalSweepAngle = math.pi - 0.8;
    final scoreProgress = score / 100.0;
    final triangleAngle = startAngle + (totalSweepAngle * scoreProgress * needleProgress);

    final innerRadius = radius - 8;
    final trianglePosition = Offset(
      center.dx + innerRadius * math.cos(triangleAngle),
      center.dy + innerRadius * math.sin(triangleAngle),
    );

    const triangleSize = 12.0;

    final path = Path();

    final tip = Offset(
      trianglePosition.dx + 12 * math.cos(triangleAngle),
      trianglePosition.dy + 12 * math.sin(triangleAngle),
    );

    final perpAngle1 = triangleAngle + math.pi / 2;
    final perpAngle2 = triangleAngle - math.pi / 2;

    final leftBase = Offset(
      trianglePosition.dx + triangleSize * 0.5 * math.cos(perpAngle1),
      trianglePosition.dy + triangleSize * 0.5 * math.sin(perpAngle1),
    );

    final rightBase = Offset(
      trianglePosition.dx + triangleSize * 0.5 * math.cos(perpAngle2),
      trianglePosition.dy + triangleSize * 0.5 * math.sin(perpAngle2),
    );

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(leftBase.dx, leftBase.dy);
    path.lineTo(rightBase.dx, rightBase.dy);
    path.close();

    final shadowPath = Path();
    final shadowOffset = const Offset(1.5, 1.5);

    shadowPath.moveTo(tip.dx + shadowOffset.dx, tip.dy + shadowOffset.dy);
    shadowPath.lineTo(leftBase.dx + shadowOffset.dx, leftBase.dy + shadowOffset.dy);
    shadowPath.lineTo(rightBase.dx + shadowOffset.dx, rightBase.dy + shadowOffset.dy);
    shadowPath.close();

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(shadowPath, shadowPaint);

    final trianglePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, trianglePaint);

    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}