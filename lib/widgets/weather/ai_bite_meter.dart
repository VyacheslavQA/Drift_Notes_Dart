// Путь: lib/widgets/weather/ai_bite_meter.dart
// ВАЖНО: Заменить весь существующий файл на этот код
// ИСПРАВЛЕНО: Единый источник данных - используем WeatherApiResponse + WeatherSettingsService

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';
import '../animated_border_widget.dart';
import '../../screens/weather/fishing_type_detail_screen.dart';

class AIBiteMeter extends StatefulWidget {
  // ОБНОВЛЕНО: Теперь принимаем оригинальные данные Weather API
  final WeatherApiResponse weatherData;
  final WeatherSettingsService weatherSettings;
  final MultiFishingTypePrediction? aiPrediction;
  final VoidCallback? onCompareTypes;
  final Function(String)? onSelectType;
  final List<String>? preferredTypes;

  const AIBiteMeter({
    super.key,
    required this.weatherData, // ДОБАВЛЕНО: оригинальные данные
    required this.weatherSettings, // ДОБАВЛЕНО: сервис форматирования
    this.aiPrediction,
    this.onCompareTypes,
    this.onSelectType,
    this.preferredTypes,
  });

  @override
  State<AIBiteMeter> createState() => _AIBiteMeterState();
}

class _AIBiteMeterState extends State<AIBiteMeter>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _pulseController;
  late AnimationController _needleController;
  late Animation<double> _gaugeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _needleAnimation;

  // ОБНОВЛЕНО: Конфигурация типов рыбалки с реальными иконками
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
    // ДОБАВЛЕНО: Fallback для "Обычная рыбалка"
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
    // ДОБАВЛЕНО: Устанавливаем локаль для WeatherSettingsService
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

    _gaugeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic),
    );

    _needleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _gaugeController.forward();
    _needleController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _needleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<String> _getFilteredTypes() {
    // Проверяем переданные предпочтения
    if (widget.preferredTypes != null && widget.preferredTypes!.isNotEmpty) {
      debugPrint('🎯 Используем переданные предпочтения: ${widget.preferredTypes}');
      return widget.preferredTypes!;
    }

    // Проверяем есть ли предпочтения в самом прогнозе
    if (widget.aiPrediction != null) {
      final availableTypes = widget.aiPrediction!.allPredictions.keys.toList();
      if (availableTypes.isNotEmpty) {
        debugPrint('🎯 Используем типы из прогноза: $availableTypes');
        return availableTypes;
      }
    }

    // Fallback - пустой список (покажем сообщение о настройке профиля)
    debugPrint('⚠️ Нет выбранных типов рыбалки');
    return [];
  }

  String _getBestFilteredType() {
    final filteredTypes = _getFilteredTypes();

    if (filteredTypes.isEmpty) {
      return ''; // Нет типов
    }

    if (widget.aiPrediction == null) {
      return filteredTypes.first; // Возвращаем первый доступный
    }

    final rankings = widget.aiPrediction!.comparison.rankings;

    // Ищем лучший тип среди доступных
    for (final ranking in rankings) {
      if (filteredTypes.contains(ranking.fishingType)) {
        return ranking.fishingType;
      }
    }

    return filteredTypes.first; // Fallback
  }

  int _getBestFilteredScore() {
    final bestType = _getBestFilteredType();

    if (bestType.isEmpty || widget.aiPrediction == null) {
      return 50; // Базовый скор
    }

    final prediction = widget.aiPrediction!.allPredictions[bestType];
    return prediction?.overallScore ?? 50;
  }

  // НОВЫЙ метод: безопасное получение информации о типе рыбалки
  Map<String, String> _getTypeInfo(String type) {
    final typeInfo = fishingTypes[type];

    if (typeInfo != null) {
      return typeInfo;
    }

    // Fallback для неизвестных типов
    debugPrint('⚠️ Неизвестный тип рыбалки: $type');
    return {
      'name': type,
      'icon': 'assets/images/fishing_types/general_fishing.png',
      'nameKey': 'general_fishing',
    };
  }

  /// Перевод фазы луны с английского на локализованный язык
  String _translateMoonPhase(
      String englishPhase,
      AppLocalizations localizations,
      ) {
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

    // Если перевод не найден, возвращаем оригинал
    return englishPhase;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (widget.aiPrediction == null) {
      return _buildLoadingState(localizations);
    }

    return _buildSpeedometerContent(localizations);
  }

  Widget _buildLoadingState(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🧠', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('ai_bite_forecast'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('ai_analyzing_fishing'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerContent(AppLocalizations localizations) {
    final score = _getBestFilteredScore();
    final bestType = _getBestFilteredType();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Заголовок
          _buildHeader(localizations),

          const SizedBox(height: 20),

          // Главный спидометр
          _buildSpeedometer(score, localizations),

          const SizedBox(height: 24),

          // Горизонтальный скролл типов рыбалки
          _buildFishingTypesScroll(localizations, bestType),

          const SizedBox(height: 24),

          // ИСПРАВЛЕНО: Информация о погоде теперь из оригинального API
          _buildWeatherInfo(localizations),

          const SizedBox(height: 20),

          // Кнопка подробнее
          _buildDetailsButton(localizations),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.3),
                Colors.cyan.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('🧠', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('ai_bite_forecast'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${localizations.translate('confidence')}: ${widget.aiPrediction!.bestPrediction.confidencePercent}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedometer(int score, AppLocalizations localizations) {
    return SizedBox(
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
                  // Размещаем цифры в верхней части круга
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
    );
  }

  Widget _buildFishingTypesScroll(
      AppLocalizations localizations,
      String bestType,
      ) {
    // ИЗМЕНЕНО: Показываем только выбранные пользователем типы
    final selectedTypes = _getFilteredTypes();

    // НОВОЕ: Если нет выбранных типов - показываем сообщение
    if (selectedTypes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              localizations.translate('fishing_types_comparison'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, color: Colors.orange, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'Выберите типы рыбалки в профиле',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                localizations.translate('fishing_types_comparison'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // НОВОЕ: Показываем количество выбранных типов
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedTypes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // НОВОЕ: Адаптивное отображение карточек
        _buildAdaptiveFishingCards(selectedTypes, bestType, localizations),
      ],
    );
  }

  // ИСПРАВЛЕНО: Информация о погоде теперь из ОРИГИНАЛЬНОГО API
  Widget _buildWeatherInfo(AppLocalizations localizations) {
    final current = widget.weatherData.current;

    // ИСПРАВЛЕНО: Получаем фазу луны из оригинальных данных
    final moonPhase = widget.weatherData.forecast.isNotEmpty
        ? widget.weatherData.forecast.first.astro.moonPhase
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Основная рекомендация - 2 строки максимум
          Text(
            widget.aiPrediction!.bestPrediction.recommendation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // ИСПРАВЛЕНО: Параметры в столбик с ОРИГИНАЛЬНЫМИ данными из API
          _buildWeatherMetricRow(
            '🌡️',
            widget.weatherSettings.formatPressure(current.pressureMb),
            localizations.translate('pressure'),
          ),
          const SizedBox(height: 8),
          _buildWeatherMetricRow(
            '💨',
            widget.weatherSettings.formatWindSpeed(current.windKph),
            localizations.translate('wind'),
          ),
          const SizedBox(height: 8),
          _buildWeatherMetricRow(
            '🌙',
            _translateMoonPhase(moonPhase, localizations),
            localizations.translate('moon_phase'),
          ),
          const SizedBox(height: 8),
          _buildWeatherMetricRow(
            '💧',
            '${current.humidity}%',
            localizations.translate('humidity'),
          ),
          const SizedBox(height: 8),
          _buildWeatherMetricRow(
            '🕐',
            _getBestTimeString(),
            localizations.translate('best_time'),
          ),
          const SizedBox(height: 8),
          _buildWeatherMetricRow(
            '⭐',
            '${_getBestFilteredScore()}/100',
            localizations.translate('bite_activity'),
          ),
        ],
      ),
    );
  }

  String _getBestTimeString() {
    final prediction = widget.aiPrediction?.bestPrediction;
    if (prediction?.bestTimeWindows.isNotEmpty == true) {
      final window = prediction!.bestTimeWindows.first;
      return window.timeRange;
    }
    return '05:00-06:30'; // Fallback
  }

  Widget _buildWeatherMetricRow(String icon, String value, String description) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onCompareTypes,
        icon: const Icon(Icons.analytics, size: 18),
        label: Text(
          localizations.translate('more_details'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  /// НОВЫЙ метод - адаптивные карточки рыбалки
  Widget _buildAdaptiveFishingCards(
      List<String> selectedTypes,
      String bestType,
      AppLocalizations localizations,
      ) {
    // Определяем как отображать карточки в зависимости от количества
    if (selectedTypes.length == 1) {
      // 1 тип - на всю ширину
      return _buildSingleCard(selectedTypes.first, bestType, localizations);
    } else if (selectedTypes.length == 2) {
      // 2 типа - по половине экрана
      return _buildTwoCards(selectedTypes, bestType, localizations);
    } else {
      // 3+ типов - скроллируемый список с фиксированной шириной
      return _buildScrollableCards(selectedTypes, bestType, localizations);
    }
  }

  /// Одна карточка на всю ширину
  Widget _buildSingleCard(
      String type,
      String bestType,
      AppLocalizations localizations,
      ) {
    // ИСПРАВЛЕНО: Используем безопасный метод получения информации о типе
    final typeInfo = _getTypeInfo(type);
    final prediction = widget.aiPrediction?.allPredictions[type];
    final score = prediction?.overallScore ?? 0;

    return GestureDetector( // ДОБАВЛЕНО: GestureDetector для обработки нажатий
      onTap: () => _openFishingTypeDetail(type, localizations),
      child: Container(
        height: 170, // УВЕЛИЧЕНО с 160 до 170
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getScoreColor(score).withValues(alpha: 0.6),
              _getScoreColor(score).withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getScoreColor(score),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _getScoreColor(score).withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Левая часть - иконка
              Container(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          typeInfo['icon']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.sports, size: 50, color: Colors.white);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Правая часть - информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Размещаем "Активность:" и скор в столбик для экономии места
                    Text(
                      '${localizations.translate('activity')}:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$score ${localizations.translate('points')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getScoreText(score, localizations),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Две карточки рядом
  Widget _buildTwoCards(
      List<String> selectedTypes,
      String bestType,
      AppLocalizations localizations,
      ) {
    return SizedBox(
      height: 150,
      child: Row(
        children: selectedTypes.map((type) {
          // ИСПРАВЛЕНО: Используем безопасный метод получения информации о типе
          final typeInfo = _getTypeInfo(type);
          final isBest = type == bestType;
          final prediction = widget.aiPrediction?.allPredictions[type];
          final score = prediction?.overallScore ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => _openFishingTypeDetail(type, localizations),
              child: Container(
                margin: EdgeInsets.only(
                  left: selectedTypes.indexOf(type) == 0 ? 4 : 2,
                  right: selectedTypes.indexOf(type) == selectedTypes.length - 1 ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  gradient: isBest
                      ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getScoreColor(score).withValues(alpha: 0.6),
                      _getScoreColor(score).withValues(alpha: 0.3),
                    ],
                  )
                      : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getScoreColor(score).withValues(alpha: 0.3),
                      _getScoreColor(score).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getScoreColor(score),
                    width: isBest ? 3 : 2,
                  ),
                  boxShadow: isBest
                      ? [
                    BoxShadow(
                      color: _getScoreColor(score).withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Иконка с рамкой для лучшего типа
                      Container(
                        padding: EdgeInsets.all(isBest ? 6 : 5),
                        decoration: isBest
                            ? BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        )
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            typeInfo['icon']!,
                            width: isBest ? 40 : 36,
                            height: isBest ? 40 : 36,
                            fit: BoxFit.contain,
                            color: Colors.white,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.sports,
                                size: isBest ? 40 : 36,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isBest ? 13 : 12,
                          fontWeight: isBest ? FontWeight.w600 : FontWeight.w500,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (score > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$score',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isBest ? 14 : 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Скроллируемые карточки для 3+ типов
  Widget _buildScrollableCards(
      List<String> selectedTypes,
      String bestType,
      AppLocalizations localizations,
      ) {
    // Вычисляем ширину карточки в зависимости от количества типов
    double cardWidth;
    if (selectedTypes.length == 3) {
      cardWidth = (MediaQuery.of(context).size.width - 64) / 3; // 3 карточки на экране
    } else if (selectedTypes.length == 4) {
      cardWidth = (MediaQuery.of(context).size.width - 80) / 3.5; // 3.5 карточки на экране
    } else {
      cardWidth = 120;
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: selectedTypes.length,
        itemBuilder: (context, index) {
          final type = selectedTypes[index];
          // ИСПРАВЛЕНО: Используем безопасный метод получения информации о типе
          final typeInfo = _getTypeInfo(type);
          final isBest = type == bestType;
          final prediction = widget.aiPrediction?.allPredictions[type];
          final score = prediction?.overallScore ?? 0;

          return GestureDetector(
            onTap: () => _openFishingTypeDetail(type, localizations),
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                gradient: isBest
                    ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getScoreColor(score).withValues(alpha: 0.6),
                    _getScoreColor(score).withValues(alpha: 0.3),
                  ],
                )
                    : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getScoreColor(score).withValues(alpha: 0.3),
                    _getScoreColor(score).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getScoreColor(score),
                  width: isBest ? 3 : 2,
                ),
                boxShadow: isBest
                    ? [
                  BoxShadow(
                    color: _getScoreColor(score).withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Иконка с рамкой для лучшего типа
                    Container(
                      padding: EdgeInsets.all(isBest ? 6 : 4),
                      decoration: isBest
                          ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      )
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          typeInfo['icon']!,
                          width: isBest ? 36 : 32,
                          height: isBest ? 36 : 32,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.sports,
                              size: isBest ? 36 : 32,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localizations.translate(typeInfo['nameKey']!) ?? typeInfo['name']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: cardWidth > 110 ? (isBest ? 12 : 11) : (isBest ? 11 : 10),
                        fontWeight: isBest ? FontWeight.w600 : FontWeight.w500,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (score > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: cardWidth > 110 ? 12 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFishingTypeDetail(String type, AppLocalizations localizations) {
    final prediction = widget.aiPrediction?.allPredictions[type];
    if (prediction == null) return;

    // ИСПРАВЛЕНО: Используем безопасный метод получения информации о типе
    final typeInfo = _getTypeInfo(type);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FishingTypeDetailScreen(
          fishingType: type,
          prediction: prediction,
          typeInfo: typeInfo,
        ),
      ),
    );
  }

  // Вспомогательные методы
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

// Кастомный painter для спидометра с треугольником ОСТРИЕМ НАРУЖУ
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

    // Рисуем фоновую дугу
    _drawBackgroundArc(canvas, center, radius);

    // Рисуем цветную дугу (градиент)
    _drawColoredArc(canvas, center, radius);

    // Рисуем треугольник НА ДУГЕ (острием НАРУЖУ)
    _drawTriangleOnArc(canvas, center, radius);
  }

  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final paint =
    Paint()
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

    // Создаем градиент
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + totalSweepAngle,
      colors: const [
        Color(0xFFEF5350), // Красный
        Color(0xFFFF9800), // Оранжевый
        Color(0xFFFFC107), // Желтый
        Color(0xFF8BC34A), // Светло-зеленый
        Color(0xFF4CAF50), // Зеленый
      ],
    );

    final paint =
    Paint()
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
    final triangleAngle =
        startAngle + (totalSweepAngle * scoreProgress * needleProgress);

    // Позиция треугольника НА ВНУТРЕННЕЙ СТОРОНЕ ДУГИ (ближе к центру)
    final innerRadius = radius - 8; // Сдвигаем треугольник ближе к центру
    final trianglePosition = Offset(
      center.dx + innerRadius * math.cos(triangleAngle),
      center.dy + innerRadius * math.sin(triangleAngle),
    );

    const triangleSize = 12.0;

    // Треугольник острием НАРУЖУ (к дуге)
    final path = Path();

    // Острие треугольника направлено К ДУГЕ (наружу от центра)
    final tip = Offset(
      trianglePosition.dx + 12 * math.cos(triangleAngle), // Острие к дуге
      trianglePosition.dy + 12 * math.sin(triangleAngle),
    );

    // Два угла основания треугольника (перпендикулярно к радиусу)
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

    // Тень треугольника
    final shadowPath = Path();
    final shadowOffset = const Offset(1.5, 1.5);

    shadowPath.moveTo(tip.dx + shadowOffset.dx, tip.dy + shadowOffset.dy);
    shadowPath.lineTo(
      leftBase.dx + shadowOffset.dx,
      leftBase.dy + shadowOffset.dy,
    );
    shadowPath.lineTo(
      rightBase.dx + shadowOffset.dx,
      rightBase.dy + shadowOffset.dy,
    );
    shadowPath.close();

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    canvas.drawPath(shadowPath, shadowPaint);

    // Основной треугольник - белый цвет
    final trianglePaint =
    Paint()
      ..color =
          Colors
              .white // Белый цвет
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, trianglePaint);

    // Обводка треугольника
    final strokePaint =
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}