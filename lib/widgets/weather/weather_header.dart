// Путь: lib/widgets/weather/weather_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

class WeatherHeader extends StatefulWidget {
  final WeatherApiResponse weather;
  final String locationName;
  final DateTime lastUpdated;
  final WeatherSettingsService weatherSettings;

  const WeatherHeader({
    super.key,
    required this.weather,
    required this.locationName,
    required this.lastUpdated,
    required this.weatherSettings,
  });

  @override
  State<WeatherHeader> createState() => _WeatherHeaderState();
}

class _WeatherHeaderState extends State<WeatherHeader>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _effectsController; // Отдельный контроллер для эффектов
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _effectsAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Отдельный контроллер для погодных эффектов
    _effectsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _effectsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _effectsController,
        curve: Curves.linear,
      ),
    );

    _animationController.forward();
    _effectsController.repeat(); // Запускаем эффекты в цикле
  }

  @override
  void dispose() {
    _animationController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final current = widget.weather.current;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getTimeBasedGradientStart(current.isDay == 1),
            _getTimeBasedGradientEnd(current.isDay == 1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getTimeBasedGradientStart(current.isDay == 1).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Локация и обновление
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: _buildLocationInfo(localizations),
                      ),

                      const SizedBox(height: 20),

                      // Основная информация о погоде
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.7),
                        child: _buildMainWeatherInfo(current, localizations),
                      ),

                      const SizedBox(height: 16),

                      // Дополнительная краткая информация
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.5),
                        child: _buildAdditionalInfo(current, localizations),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(AppLocalizations localizations) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.locationName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${localizations.translate('updated')}: ${DateFormat('HH:mm').format(widget.lastUpdated)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildSignalIndicator(),
      ],
    );
  }

  Widget _buildSignalIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            color: Colors.white.withValues(alpha: 0.9),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWeatherInfo(Current current, AppLocalizations localizations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Температура с анимацией
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Главная температура
              ScaleTransition(
                scale: _scaleAnimation,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.weatherSettings.convertTemperature(current.tempC).round().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        height: 0.9,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.weatherSettings.getTemperatureUnitSymbol(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ощущается как
              Text(
                '${localizations.translate('feels_like')} ${widget.weatherSettings.formatTemperature(current.feelslikeC)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 8),

              // Описание погоды
              Text(
                _translateWeatherDescription(current.condition.text, localizations),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Анимированная иконка погоды
        Expanded(
          flex: 2,
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildAnimatedWeatherIcon(current),
              ),
              const SizedBox(height: 12),
              _buildWeatherBadge(current, localizations),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedWeatherIcon(Current current) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: _buildWeatherIconWithEffects(current),
      ),
    );
  }

  Widget _buildWeatherIconWithEffects(Current current) {
    final icon = _getWeatherIcon(current.condition.code);
    final color = _getWeatherIconColor(current.condition.code);
    final conditionText = current.condition.text.toLowerCase();

    // Добавляем эффекты для разных типов погоды
    if (conditionText.contains('rain') || conditionText.contains('drizzle')) {
      return _buildRainyEffect(icon, color);
    } else if (conditionText.contains('snow') || conditionText.contains('blizzard')) {
      return _buildSnowyEffect(icon, color);
    } else if (conditionText.contains('thunder') || conditionText.contains('storm')) {
      return _buildThunderEffect(icon, color);
    } else {
      return Icon(
        icon,
        size: 60,
        color: color,
      );
    }
  }

  Widget _buildRainyEffect(IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _effectsController,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              // Основная иконка
              Center(
                child: Icon(icon, size: 50, color: color),
              ),
              // Анимированные капли дождя
              ...List.generate(5, (index) {
                final delay = index * 0.2;
                final animValue = (_effectsAnimation.value + delay) % 1.0;
                return Positioned(
                  left: 15 + (index * 12.0),
                  top: 10 + (animValue * 50),
                  child: Opacity(
                    opacity: (1.0 - animValue) * 0.8,
                    child: Container(
                      width: 3,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSnowyEffect(IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _effectsController,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              // Основная иконка
              Center(
                child: Icon(icon, size: 50, color: color),
              ),
              // Анимированные снежинки
              ...List.generate(8, (index) {
                final delay = index * 0.15;
                final animValue = (_effectsAnimation.value + delay) % 1.0;
                final horizontalOffset = math.sin(animValue * math.pi * 4) * 10;
                return Positioned(
                  left: 20 + (index * 8.0) + horizontalOffset,
                  top: 5 + (animValue * 60),
                  child: Opacity(
                    opacity: (1.0 - animValue) * 0.9,
                    child: Icon(
                      Icons.ac_unit,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThunderEffect(IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _effectsController,
      builder: (context, child) {
        // Создаём эффект вспышки каждые 0.5 секунды
        final flashPhase = (_effectsAnimation.value * 4) % 1.0;
        final isFlashing = flashPhase < 0.1; // Короткая вспышка

        return Container(
          decoration: isFlashing ? BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.8),
                blurRadius: 30,
                spreadRadius: 15,
              ),
            ],
          ) : null,
          child: Stack(
            children: [
              // Основная иконка
              Center(
                child: Icon(
                  icon,
                  size: 50,
                  color: isFlashing ? Colors.yellow[100] : color,
                ),
              ),
              // Дополнительные молнии
              if (isFlashing) ...[
                Positioned(
                  top: 15,
                  left: 35,
                  child: Icon(
                    Icons.flash_on,
                    size: 12,
                    color: Colors.yellow[300],
                  ),
                ),
                Positioned(
                  top: 45,
                  right: 25,
                  child: Icon(
                    Icons.flash_on,
                    size: 8,
                    color: Colors.yellow[400],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherBadge(Current current, AppLocalizations localizations) {
    String badgeText = '';
    Color badgeColor = Colors.white;

    if (current.tempC >= 25) {
      badgeText = '🔥 ${localizations.translate('hot')}';
      badgeColor = Colors.orange;
    } else if (current.tempC <= 0) {
      badgeText = '❄️ ${localizations.translate('cold')}';
      badgeColor = Colors.cyan;
    } else if (current.windKph > 20) {
      badgeText = '💨 ${localizations.translate('windy')}';
      badgeColor = Colors.blue;
    } else if (current.humidity > 80) {
      badgeText = '💧 ${localizations.translate('humid')}';
      badgeColor = Colors.blue;
    } else {
      badgeText = '✨ ${localizations.translate('comfortable')}';
      badgeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(Current current, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildQuickInfo(
            icon: Icons.remove_red_eye,
            label: localizations.translate('visibility'),
            value: '${current.visKm.round()} ${localizations.translate('km')}',
          ),
          const SizedBox(width: 20),
          _buildQuickInfo(
            icon: Icons.wb_sunny,
            label: localizations.translate('uv_index'),
            value: current.uv.round().toString(),
          ),
          const SizedBox(width: 20),
          _buildQuickInfo(
            icon: Icons.cloud,
            label: localizations.translate('clouds'),
            value: '${current.cloud}%',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
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
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы
  Color _getTimeBasedGradientStart(bool isDay) {
    if (isDay) {
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour < 10) {
        return Colors.orange[300]!.withValues(alpha: 0.8);
      } else if (hour >= 10 && hour < 16) {
        return Colors.blue[400]!.withValues(alpha: 0.8);
      } else if (hour >= 16 && hour < 20) {
        return Colors.orange[400]!.withValues(alpha: 0.8);
      }
    }
    return Colors.indigo[800]!.withValues(alpha: 0.8);
  }

  Color _getTimeBasedGradientEnd(bool isDay) {
    if (isDay) {
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour < 10) {
        return Colors.yellow[200]!.withValues(alpha: 0.6);
      } else if (hour >= 10 && hour < 16) {
        return Colors.lightBlue[200]!.withValues(alpha: 0.6);
      } else if (hour >= 16 && hour < 20) {
        return Colors.red[200]!.withValues(alpha: 0.6);
      }
    }
    return Colors.purple[900]!.withValues(alpha: 0.6);
  }

  IconData _getWeatherIcon(int code) {
    switch (code) {
      case 1000: return Icons.wb_sunny;
      case 1003: case 1006: case 1009: return Icons.cloud;
      case 1030: case 1135: case 1147: return Icons.cloud;
      case 1063: case 1180: case 1183: case 1186: case 1189: case 1192: case 1195:
      case 1198: case 1201: return Icons.grain;
      case 1066: case 1210: case 1213: case 1216: case 1219: case 1222: case 1225:
      case 1237: case 1255: case 1258: case 1261: case 1264: return Icons.ac_unit;
      case 1087: case 1273: case 1276: case 1279: case 1282: return Icons.flash_on;
      default: return Icons.wb_sunny;
    }
  }

  Color _getWeatherIconColor(int code) {
    switch (code) {
      case 1000: return Colors.yellow[300]!;
      case 1003: case 1006: case 1009: return Colors.grey[300]!;
      case 1030: case 1135: case 1147: return Colors.grey[400]!;
      case 1063: case 1180: case 1183: case 1186: case 1189: case 1192: case 1195:
      case 1198: case 1201: return Colors.blue[300]!;
      case 1066: case 1210: case 1213: case 1216: case 1219: case 1222: case 1225:
      case 1237: case 1255: case 1258: case 1261: case 1264: return Colors.white;
      case 1087: case 1273: case 1276: case 1279: case 1282: return Colors.yellow[400]!;
      default: return Colors.yellow[300]!;
    }
  }

  String _translateWeatherDescription(String description, AppLocalizations localizations) {
    final cleanDescription = description.trim().toLowerCase();

    final Map<String, String> descriptionToKey = {
      'sunny': 'weather_sunny',
      'clear': 'weather_clear',
      'partly cloudy': 'weather_partly_cloudy',
      'cloudy': 'weather_cloudy',
      'overcast': 'weather_overcast',
      'mist': 'weather_mist',
      'light rain': 'weather_light_rain',
      'moderate rain': 'weather_moderate_rain',
      'heavy rain': 'weather_heavy_rain',
      'light snow': 'weather_light_snow',
      'thunderstorm': 'weather_thundery_outbreaks_possible',
      'thundery outbreaks in nearby': 'weather_thundery_outbreaks_possible',
      'thundery outbreaks possible': 'weather_thundery_outbreaks_possible',
    };

    final localizationKey = descriptionToKey[cleanDescription];
    if (localizationKey != null) {
      return localizations.translate(localizationKey);
    }

    return description;
  }
}